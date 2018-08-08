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

class AuthenticationCoordinator: NSObject, PreLoginAuthenticationObserver, PostLoginAuthenticationObserver, ZMInitialSyncCompletionObserver, ClientUnregisterViewControllerDelegate, SessionManagerCreatedSessionObserver {

    weak var presenter: NavigationController?
    weak var delegate: AuthenticationCoordinatorDelegate?

    private var currentStep: AuthenticationFlowStep = .landingScreen
    private var currentViewController: AuthenticationStepViewController?
    private let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())

    private var flowStack: [AuthenticationFlowStep] = []

    // MARK: - Initialization

    private let unauthenticatedSession: UnauthenticatedSession
    private var hasPushedPostRegistrationStep: Bool = false
    private var loginObservers: [Any] = []
    private var postLoginObservers: [Any] = []

    init(presenter: NavigationController, unauthenticatedSession: UnauthenticatedSession, sessionManager: ObservableSessionManager) {
        self.presenter = presenter
        self.unauthenticatedSession = unauthenticatedSession
        super.init()

        companyLoginController?.delegate = self
        flowStack = [.landingScreen]

        loginObservers = [
            PreLoginAuthenticationNotification.register(self, for: unauthenticatedSession),
            PostLoginAuthenticationNotification.addObserver(self),
            sessionManager.addSessionManagerCreatedSessionObserver(self),
        ]
    }

    /**
     * Registers the post-login observation tokens if they were not already registered.
     */

    fileprivate func registerPostLoginObserversIfNeeded() {
        guard postLoginObservers.isEmpty else {
            return
        }

        guard
            let selfUser = delegate?.authenticationCoordinatorRequestedSelfUser(),
            let session = delegate?.authenticationCoordinatorRequestedSharedUserSession(),
            let userProfile = delegate?.authenticationCoordinatorRequestedSelfUserProfile()
        else {
            return 
        }

        postLoginObservers = [
            userProfile.add(observer: self),
            UserChangeInfo.add(observer: self, for: selfUser, userSession: session)!
        ]
    }

}

    // MARK: - State Management

extension AuthenticationCoordinator {

    func transition(to step: AuthenticationFlowStep, resetStack: Bool = false) {
        currentStep = step

        guard step.needsInterface else {
            flowStack.append(step)
            return
        }

        guard let stepViewController = makeViewController(for: step) else {
            fatalError("Step \(step) requires user interface but the view controller could not be created.")
        }

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

    private func makeViewController(for step: AuthenticationFlowStep) -> AuthenticationStepViewController? {
        switch step {
        case .landingScreen:
            let controller = LandingViewController()
            controller.delegate = self
            controller.authenticationCoordinator = self
            return controller

        case .reauthenticate(let error, let numberOfAccounts):
            let registrationViewController = RegistrationViewController()
            registrationViewController.authenticationCoordinator = self
            registrationViewController.shouldHideCancelButton = numberOfAccounts <= 1
            registrationViewController.signInError = error
            return registrationViewController

        case .provideCredentials:
            let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
            loginViewController.authenticationCoordinator = self
            loginViewController.shouldHideCancelButton = true
            return loginViewController

        case .clientManagement(let clients, let credentials):
            let emailCredentials = ZMEmailCredentials(email: credentials.email!, password: credentials.password!)
            return ClientUnregisterFlowViewController(clientsList: clients, credentials: emailCredentials)

        case .noHistory(_, let type):
            let noHistoryViewController = NoHistoryViewController(contextType: type)
            noHistoryViewController.authenticationCoordinator = self
            return noHistoryViewController

        case .verifyPhoneNumber(let phoneNumber, _):
            let verificationController = PhoneVerificationStepViewController()
            verificationController.phoneNumber = phoneNumber
            verificationController.isLoggingIn = true
            verificationController.authenticationCoordinator = self
            return verificationController

        case .addEmailAndPassword(_, _, let canSkip):
            let addEmailPasswordViewController = AddEmailPasswordViewController()
            addEmailPasswordViewController.canSkipStep = canSkip
            addEmailPasswordViewController.authenticationCoordinator = self
            return addEmailPasswordViewController

        case .verifyEmailCredentials(let credentials):
            let verificationController = EmailVerificationViewController(credentials: credentials)
            verificationController.authenticationCoordinator = self
            return verificationController

        default:
            return nil
        }
    }

    func unwind() {
        guard flowStack.count >= 2 else {
            return
        }

        flowStack.removeLast()
        currentStep = flowStack.last!
    }

}

// MARK: - Actions

extension AuthenticationCoordinator {

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

    /**
     * Requests an e-mail login for the specified credentials.
     */

    @objc(requestEmailLoginWithCredentials:)
    func requestEmailLogin(with credentials: ZMEmailCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticateEmailCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

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

    /**
     * Call this method to mark the backup step as completed.
     */

    @objc func completeBackupStep() {
        unauthenticatedSession.continueAfterBackupImportStep()
    }

    @objc func skipAddEmailAndPassword() {
        // no-op
    }

    @objc func setEmailCredentialsForCurrentUser(_ credentials: ZMEmailCredentials) {
        guard case let .addEmailAndPassword(_, profile, _) = currentStep else {
            return
        }

        transition(to: AuthenticationFlowStep.registerEmailCredentials(credentials))

        func fail() {
            presenter?.showLoadingView = false
            presenter?.showAlert(forMessage: "", title: "") { _ in
                self.unwind()
            }
        }

        do {
            presenter?.showLoadingView = true
            try profile.requestSettingEmailAndPassword(credentials: credentials)

            guard SessionManager.shared?.update(credentials: credentials) == true else {
                fail()
                return
            }
        } catch {
            fail()
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

    @objc func resendEmailVerificationCode() {
        guard case let .verifyEmailCredentials(credentials) = currentStep else {
            return
        }

        guard let userProfile = delegate?.authenticationCoordinatorRequestedSelfUserProfile() else {
            return
        }

        presenter?.showLoadingView = true

        // We can assume that the validation will succeed, as it only fails when there is no
        // email and/or password in the email credentials, which we already checked before.
        setCredentialsWithProfile(userProfile, credentials: credentials)
    }

    @objc func cancelWaitForEmailVerification() {
        unauthenticatedSession.cancelWaitForEmailVerification()
    }

}

// MARK: - User Session Events

extension AuthenticationCoordinator: UserProfileUpdateObserver, ZMUserObserver {

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
            guard let selfUser = delegate?.authenticationCoordinatorRequestedSelfUser() else {
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

    func authenticationReadyToImportBackup(existingAccount: Bool) {
        presenter?.showLoadingView = false
        let currentCredentials: ZMCredentials

        switch self.currentStep {
        case .authenticateEmailCredentials(let credentials):
            currentCredentials = credentials
        case .authenticatePhoneCredentials(let credentials):
            currentCredentials = credentials
        case .noHistory:
            return
        default:
            fatalError("Cannot present history view controller without credentials.")
        }

        guard !self.hasAutomationFastLoginCredentials else {
            unauthenticatedSession.continueAfterBackupImportStep()
            return
        }

        let type = existingAccount ? ContextType.loggedOut : .newDevice
        let flow = AuthenticationFlowStep.noHistory(credentials: currentCredentials, type: type)
        self.transition(to: flow)
    }

    func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        authenticationDidFail(error)
    }

    func clientRegistrationDidSucceed(accountId: UUID) {
        guard let sharedSession = delegate?.authenticationCoordinatorRequestedSharedUserSession() else {
            return
        }

        let sessionObservationToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: sharedSession)
        loginObservers.append(sessionObservationToken)
    }

    func sessionManagerCreated(userSession: ZMUserSession) {
        guard let sharedSession = delegate?.authenticationCoordinatorRequestedSharedUserSession() else {
            return
        }

        let sessionObservationToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: sharedSession)
        loginObservers.append(sessionObservationToken)
    }

    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        switch error.userSessionErrorCode {
        case .canNotRegisterMoreClients:
            presenter?.showLoadingView = false
            let authenticationCredentials: ZMCredentials

            switch self.currentStep {
            case .noHistory(let credentials, _):
                authenticationCredentials = credentials

            case .authenticateEmailCredentials(let credentials):
                authenticationCredentials = credentials

            default:
                fatalError("Cannot delete clients without credentials")
            }

            guard let nextStep = self.makeClientManagementStep(from: error, credentials: authenticationCredentials) else {
                fatalError("Invalid error")
            }

            transition(to: nextStep)

        case .needsToRegisterEmailToRegisterClient:
            // If we are already registerinf
            switch currentStep {
            case .addEmailAndPassword, .registerEmailCredentials, .verifyEmailCredentials:
                return
            default:
                presenter?.showLoadingView = false
            }

            guard let user = ZMUser.selfUser() else {
                return
            }

            guard let profile = ZMUserSession.shared()?.userProfile else {
                return
            }

            registerPostLoginObserversIfNeeded()

            transition(to: .addEmailAndPassword(user: user, profile: profile,
                                                canSkip: user.usesCompanyLogin))

        case .needsPasswordToRegisterClient:
            presenter?.showLoadingView = false
            let numberOfAccounts = delegate?.authenticationCoordinatorRequestedNumberOfAccounts() ?? 0
            transition(to: .reauthenticate(error: error, numberOfAccounts: numberOfAccounts), resetStack: true)

        default:
            fatalError("Unhandled error: \(error)")
        }
    }

    func accountDeleted(accountId: UUID) {
        // no-op
    }



    // MARK: - Helpers

    private var hasAutomationFastLoginCredentials: Bool {
        return AutomationHelper.sharedHelper.automationEmailCredentials != nil
    }

    // MARK: --

    func startAuthentication(with error: NSError?, numberOfAccounts: Int) {
        if error?.userSessionErrorCode == .needsToRegisterEmailToRegisterClient {
            let user = ZMUser.selfUser()!
            let profile = ZMUserSession.shared()!.userProfile!
            registerPostLoginObserversIfNeeded()
            transition(to: .addEmailAndPassword(user: user, profile: profile, canSkip: false))
            return
        }

        var needsToReauthenticate = false
        var needsToDeleteClients = false

        if let error = error {
            let errorCode = (error as NSError).userSessionErrorCode
            needsToReauthenticate = [ZMUserSessionErrorCode.clientDeletedRemotely,
                                     .accessTokenExpired,
                                     .needsPasswordToRegisterClient,
                                     .needsToRegisterEmailToRegisterClient,
                                     ].contains(errorCode)

            needsToDeleteClients = errorCode == .canNotRegisterMoreClients
        }

        let flowStep: AuthenticationFlowStep

        switch currentStep {
        case .landingScreen:
            if needsToReauthenticate {
                flowStep = .reauthenticate(error: error, numberOfAccounts: numberOfAccounts)
            } else {
                flowStep = .landingScreen
            }

        case .authenticateEmailCredentials(let credentials):
            if needsToDeleteClients {
                presenter?.showLoadingView = false
                flowStep = makeClientManagementStep(from: error, credentials: credentials)!
            } else {
                fallthrough
            }

        default:
            return
        }

        self.transition(to: flowStep)
    }

    /// Called when the initial sync for the new user has completed.
    func initialSyncCompleted() {
        // Skip email/password prompt for @fastLogin automation
        guard !hasAutomationFastLoginCredentials else {
            delegate?.userAuthenticationDidComplete(registered: false)
            return
        }

        // Do not ask for credentials again (slow sync can be called multiple times)
        if case .addEmailAndPassword = currentStep {
            return
        }

        // Check if the user needs email and password
        let registered = delegate?.authenticatedUserWasRegisteredOnThisDevice() ?? false
        let needsEmail = delegate?.authenticatedUserNeedsEmailCredentials() ?? false

        guard registered && needsEmail else {
            delegate?.userAuthenticationDidComplete(registered: registered)
            return
        }

        presenter?.logoEnabled = false
        // transition(to: .addEmailAndPassword(canSkip: false), resetStack: true)
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
