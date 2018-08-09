//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireSyncEngine

typealias AuthenticationStepViewController = UIViewController & AuthenticationCoordinatedViewController

protocol ObservableSessionManager {
    func addSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any
}

extension SessionManager: ObservableSessionManager {}

/**
 * Manages the flow of authentication for the user. Decides which steps to take for login, registration
 * and team creation.
 */

class AuthenticationCoordinator: NSObject, AuthenticationEventHandlingManagerDelegate {

    weak var presenter: NavigationController?
    weak var delegate: AuthenticationCoordinatorDelegate?

    // MARK: - Event Handling Properties

    let eventHandlingManager = AuthenticationEventHandlingManager()

    var statusProvider: AuthenticationStatusProvider? {
        return delegate
    }

    // MARK: - State

    public fileprivate(set) var currentStep: AuthenticationFlowStep = .landingScreen
    private var currentViewController: AuthenticationStepViewController?
    private let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())
    private let interfaceBuilder = AuthenticationInterfaceBuilder()

    private let unauthenticatedSession: UnauthenticatedSession
    private var hasPushedPostRegistrationStep: Bool = false
    private var loginObservers: [Any] = []
    private var postLoginObservers: [Any] = []

    private var flowStack: [AuthenticationFlowStep] = []

    // MARK: - Initialization

    init(presenter: NavigationController, unauthenticatedSession: UnauthenticatedSession, sessionManager: ObservableSessionManager) {
        self.presenter = presenter
        self.unauthenticatedSession = unauthenticatedSession
        super.init()

        companyLoginController?.delegate = self
        flowStack = [.landingScreen]

        loginObservers = [
            PreLoginAuthenticationNotification.register(self, for: unauthenticatedSession),
            PostLoginAuthenticationNotification.addObserver(self),
            sessionManager.addSessionManagerCreatedSessionObserver(self)
        ]

        eventHandlingManager.configure(delegate: self)
    }

}

// MARK: - State Management

extension AuthenticationCoordinator {

    /**
     * Transitions to the next step in the stack.
     *
     * This method changes the current step, generates a new interface if needed,
     * and changes the stack (either appends the new step to the list of previous steps,
     * or resets the stack if you request it).
     *
     * - parameter step: The step to transition to.
     * - parameter resetStack: Whether transitioning to this step resets the previous stack
     * of view controllers in the navigation controller. You should pass `true` if your step
     * is at the beginning of a new "logical flow" (ex: deleting clients).
     */

    func transition(to step: AuthenticationFlowStep, resetStack: Bool = false) {
        currentStep = step

        guard step.needsInterface else {
            flowStack.append(step)
            return
        }

        guard let stepViewController = interfaceBuilder.makeViewController(for: step) else {
            fatalError("Step \(step) requires user interface, but the interface builder does not support it.")
        }

        stepViewController.authenticationCoordinator = self
        currentViewController = stepViewController

        if resetStack {
            flowStack = [step]
            presenter?.setViewControllers([stepViewController], animated: true)
        } else {
            flowStack.append(step)
            presenter?.backButtonEnabled = step.allowsUnwind
            presenter?.pushViewController(stepViewController, animated: true)
        }
    }

    /**
     * Unwind the state to the previous state if possible.
     *
     * This sets the current step back to the previous state, if we recorded it.
     *
     * You should call this method:
     * - when a non-visual step fails and you need to go back to step that started it
     * - when the navigation controller pops the current view controller
     */

    func unwind() {
        guard flowStack.count >= 2 else {
            return
        }

        flowStack.removeLast()
        currentStep = flowStack.last!
    }

}

// MARK: - Event Handling

extension AuthenticationCoordinator {

    /**
     * Registers the post-login observation tokens if they were not already registered.
     */

    fileprivate func registerPostLoginObserversIfNeeded() {
        guard postLoginObservers.isEmpty else {
            return
        }

        guard
            let selfUser = delegate?.selfUser,
            let session = delegate?.sharedUserSession,
            let userProfile = delegate?.selfUserProfile,
            let sharedSession = delegate?.sharedUserSession
        else {
            return
        }

        postLoginObservers = [
            userProfile.add(observer: self),
            UserChangeInfo.add(observer: self, for: selfUser, userSession: session)!,
            ZMUserSession.addInitialSyncCompletionObserver(self, userSession: sharedSession)
        ]
    }

    /**
     * Executes the actions in response to an event.
     */

    func executeActions(_ actions: [AuthenticationCoordinatorAction]) {
        for action in actions {
            switch action {
            case .showLoadingView:
                presenter?.showLoadingView = true

            case .hideLoadingView:
                presenter?.showLoadingView = false

            case .completeBackupStep:
                unauthenticatedSession.continueAfterBackupImportStep()

            case .completeLoginFlow:
                delegate?.userAuthenticationDidComplete(registered: false)

            case .completeRegistrationFlow:
                delegate?.userAuthenticationDidComplete(registered: true)

            case .startPostLoginFlow:
                registerPostLoginObserversIfNeeded()

            case .transition(let nextStep, let resetStack):
                transition(to: nextStep, resetStack: resetStack)
            }
        }
    }

}

// MARK: - Actions

extension AuthenticationCoordinator {

    // MARK: Phone Number

    /**
     * Starts the phone number validation flow for the given phone number.
     * - parameter phoneNumber: The phone number to validate for login.
     * - parameter isSigningIn: Whether the user is signing in (`true`), or registering (`false`).
     */

    @objc(startPhoneNumberValidationWithPhoneNumber:isSigningIn:)
    func startPhoneNumberValidation(_ phoneNumber: String, isSigningIn: Bool) {
        presenter?.showLoadingView = true
        askVerificationCode(for: phoneNumber, isSigningIn: isSigningIn)
        transition(to: .verifyPhoneNumber(phoneNumber: phoneNumber, accountExists: false))
    }

    /**
     * Asks the unauthenticated session for a new phone number verification code.
     * - parameter phoneNumber: The phone number to authenticate.
     * - parameter isSigningIn: Whether the user is signing in (`true`), or registering (`false`).
     */

    @objc(askVerificationCodeForPhoneNumber:isSigningIn:)
    func askVerificationCode(for phoneNumber: String, isSigningIn: Bool) {
        if isSigningIn {
            unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
        } else {
            unauthenticatedSession.requestPhoneVerificationCodeForRegistration(phoneNumber)
        }
    }

    /**
     * Requests a phone login for the specified credentials.
     */

    @objc(requestPhoneLoginWithCredentials:)
    func requestPhoneLogin(with credentials: ZMPhoneCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticatePhoneCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    // MARK: E-Mail Login

    /**
     * Requests an e-mail login for the specified credentials.
     */

    @objc(requestEmailLoginWithCredentials:)
    func requestEmailLogin(with credentials: ZMEmailCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticateEmailCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    // MARK: - E-Mail Registration

    /**
     * Skips the add e-mail and password step, if possible.
     */

    @objc func skipAddEmailAndPassword() {
        // no-op
    }

    /**
     * Sets th e-mail and password credentials for the current user.
     */

    @objc func setEmailCredentialsForCurrentUser(_ credentials: ZMEmailCredentials) {
        guard case let .addEmailAndPassword(_, profile, _) = currentStep else {
            return
        }

        transition(to: AuthenticationFlowStep.registerEmailCredentials(credentials))
        presenter?.showLoadingView = true

        let result = setCredentialsWithProfile(profile, credentials: credentials) && SessionManager.shared?.update(credentials: credentials) == true

        if !result {
            let error = NSError(code: .invalidEmail, userInfo: nil)
            emailUpdateDidFail(error)
        }
    }

    @discardableResult
    private func setCredentialsWithProfile(_ profile: UserProfile, credentials: ZMEmailCredentials) -> Bool {
        do {
            try profile.requestSettingEmailAndPassword(credentials: credentials)
            return true
        } catch {
            return false
        }
    }

    // MARK: - E-Mail Verification

    /**
     * This method re-sends the e-mail verification code if possible.
     */

    @objc func resendEmailVerificationCode() {
        guard case let .verifyEmailCredentials(credentials) = currentStep else {
            return
        }

        guard let userProfile = delegate?.selfUserProfile else {
            return
        }

        presenter?.showLoadingView = true

        // We can assume that the validation will succeed, as it only fails when there is no
        // email and/or password in the email credentials, which we already checked before.
        setCredentialsWithProfile(userProfile, credentials: credentials)
    }

    /**
     * This method cancels the wait for the e-mail verification, when the view disappears.
     */

    @objc func cancelWaitForEmailVerification() {
        unauthenticatedSession.cancelWaitForEmailVerification()
    }

    // MARK: - Backup

    /**
     * Call this method to mark the backup step as completed.
     */

    @objc func completeBackupStep() {
        unauthenticatedSession.continueAfterBackupImportStep()
    }

    // MARK: UI Events

    /**
     * Call this method when the corrdinated view controller appears.
     */

    @objc func currentViewControllerDidAppear() {
        switch currentStep {
        case .landingScreen, .provideCredentials:
            companyLoginController?.isAutoDetectionEnabled = true
            companyLoginController?.detectLoginCode()

        default:
            companyLoginController?.isAutoDetectionEnabled = false
        }
    }

    /**
     * Call this method when the corrdinated view controller disappears.
     */

    @objc func currentViewControllerDidDisappear() {
        companyLoginController?.isAutoDetectionEnabled = false
    }

}

// MARK: - User Session Events

extension AuthenticationCoordinator: UserProfileUpdateObserver, ZMUserObserver, PreLoginAuthenticationObserver, SessionManagerCreatedSessionObserver {

    // MARK: Email Update

    func emailUpdateDidFail(_ error: Error!) {
        presenter?.showLoadingView = false

        guard case .registerEmailCredentials = currentStep else {
            return
        }

        if (error as NSError).userSessionErrorCode == .emailIsAlreadyRegistered {
            currentViewController?.executeErrorFeedbackAction?(.clearInputFields)
        }

        presenter?.showAlert(forError: error) { _ in
            self.unwind()
        }
    }

    func passwordUpdateRequestDidFail() {
        presenter?.showLoadingView = false

        guard case .registerEmailCredentials = currentStep else {
            return
        }

        presenter?.showAlert(forMessage: "error.updating_password".localized, title: nil) { _ in
            self.unwind()
        }
    }

    func didSentVerificationEmail() {
        presenter?.showLoadingView = false

        guard case .registerEmailCredentials(let credentials) = currentStep else {
            return
        }

        transition(to: .verifyEmailCredentials(credentials))
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.profileInformationChanged else {
            return
        }

        switch currentStep {
        case .registerEmailCredentials:
            guard let selfUser = delegate?.selfUser else {
                return
            }

            guard selfUser.emailAddress?.isEmpty == false else {
                return
            }

            // TODO: GDPR consent
            delegate?.userAuthenticationDidComplete(registered: false)

        default:
            break
        }
    }

    // MARK: Phone Verification Code

    func loginCodeRequestDidSucceed() {
        self.presenter?.showLoadingView = false

        guard case let .verifyPhoneNumber(phoneNumber, accountExists) = currentStep else {
            return
        }

        if accountExists {
            return
        }

        self.transition(to: .verifyPhoneNumber(phoneNumber: phoneNumber, accountExists: true))
    }

    func loginCodeRequestDidFail(_ error: NSError) {
        self.presenter?.showLoadingView = false
        self.presenter?.showAlert(forError: error) { _ in
            self.unwind()
        }
    }

    func authenticationDidFail(_ error: NSError) {
        presenter?.showLoadingView = false

        switch currentStep {
        case .authenticateEmailCredentials(let credentials):
            // Show a guidance dot if the user caused the failure
            if error.code != ZMUserSessionErrorCode.networkError.rawValue {
                currentViewController?.executeErrorFeedbackAction?(.showGuidanceDot)
            }

            let errorAlertHandler: (UIAlertAction?) -> Void = { _ in
                self.unwind()
            }

            switch ZMUserSessionErrorCode(rawValue: UInt(error.code)) {
            case .unknownError?:
                // If the error is not known, we try to validate the fields

                if !ZMUser.isValidEmailAddress(credentials.email) {
                    let validationError = NSError(domain: NSError.ZMUserSessionErrorDomain, code: Int(ZMUserSessionErrorCode.invalidEmail.rawValue), userInfo: nil)
                    presenter?.showAlert(forError: validationError, handler: errorAlertHandler)
                } else if !ZMUser.isValidPassword(credentials.password) {
                    let validationError = NSError(domain: NSError.ZMUserSessionErrorDomain, code: Int(ZMUserSessionErrorCode.invalidCredentials.rawValue), userInfo: nil)
                    presenter?.showAlert(forError: validationError, handler: errorAlertHandler)
                } else {
                    fallthrough
                }

            case .canNotRegisterMoreClients?:
                guard let step = makeClientManagementStep(from: error, credentials: credentials) else {
                    fallthrough
                }

                transition(to: step)

            default:
                presenter?.showAlert(forError: error, handler: errorAlertHandler)
            }

        case .authenticatePhoneCredentials:
            presenter?.showAlert(forError: error) { _ in
                self.unwind()
            }

        case .reauthenticate:
            break

        default:
            break
        }

    }

    func makeClientManagementStep(from error: NSError?, credentials: ZMCredentials) -> AuthenticationFlowStep? {
        guard let error = error else {
            return nil
        }

        guard let userClientIDs = error.userInfo[ZMClientsKey] as? [NSManagedObjectID] else {
            return nil
        }

        let clients: [UserClient] = userClientIDs.compactMap {
            guard let session = ZMUserSession.shared() else {
                return nil
            }

            guard let object = try? session.managedObjectContext.existingObject(with: $0) else {
                return nil
            }

            return object as? UserClient
        }

        return .clientManagement(clients: clients, credentials: credentials)
    }

    @objc func startCompanyLoginFlowIfPossible() {
        switch currentStep {
        case .provideCredentials:
            companyLoginController?.displayLoginCodePrompt()
        default:
            return
        }
    }

    func authenticationDidSucceed() {
        presenter?.showLoadingView = false
    }

    func sessionManagerCreated(userSession: ZMUserSession) {
        guard let sharedSession = delegate?.sharedUserSession else {
            return
        }

        let sessionObservationToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: sharedSession)
        loginObservers.append(sessionObservationToken)
    }

    // MARK: - Helpers

    private var hasAutomationFastLoginCredentials: Bool {
        return AutomationHelper.sharedHelper.automationEmailCredentials != nil
    }

}

// MARK: - Starting the Flow

extension AuthenticationCoordinator {

    /**
     * Call this method when the application becomes unauthenticated and that the user
     * needs to authenticate.
     *
     * - parameter error: The error that caused the unauthenticated state, if any.
     * - parameter numberOfAccounts: The number of accounts that are signed in with the app.
     */

    func startAuthentication(with error: NSError?, numberOfAccounts: Int) {
        eventHandlingManager.handleEvent(ofType: .flowStart(error, numberOfAccounts))
    }

}

// MARK: - CompanyLoginControllerDelegate

extension AuthenticationCoordinator: CompanyLoginControllerDelegate {

    func controller(_ controller: CompanyLoginController, presentAlert alert: UIAlertController) {
        presenter?.present(alert, animated: true)
    }

    func controller(_ controller: CompanyLoginController, showLoadingView: Bool) {
        presenter?.showLoadingView = showLoadingView
    }

}

// MARK: - LandingViewControllerDelegate

extension AuthenticationCoordinator: LandingViewControllerDelegate {

    func landingViewControllerDidChooseLogin() {
        self.transition(to: .provideCredentials)
    }

    func landingViewControllerDidChooseCreateAccount() {
//        if let navigationController = self.visibleViewController as? NavigationController {
//            let registrationViewController = RegistrationViewController(authenticationFlow: .onlyRegistration)
//            registrationViewController.delegate = appStateController
//            registrationViewController.shouldHideCancelButton = true
//            navigationController.pushViewController(registrationViewController, animated: true)
//        }
    }

    func landingViewControllerDidChooseCreateTeam() {
        // flowController.startFlow()
    }

    func landingViewControllerNeedsToPresentNoHistoryFlow(with context: Wire.ContextType) {
        // no-op
    }

}
