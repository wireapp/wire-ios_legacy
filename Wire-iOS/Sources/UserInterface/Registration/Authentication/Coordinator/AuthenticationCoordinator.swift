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

    let log = ZMSLog(tag: "Auth")

    // MARK: - Event Handling Properties

    let eventHandlingManager = AuthenticationEventHandlingManager()

    var statusProvider: AuthenticationStatusProvider? {
        return delegate
    }

    // MARK: - State

    public fileprivate(set) var currentStep: AuthenticationFlowStep = .landingScreen
    private var flowStack: [AuthenticationFlowStep] = []
    private var currentViewController: AuthenticationStepViewController?

    private let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())
    private let interfaceBuilder = AuthenticationInterfaceBuilder()

    private let unauthenticatedSession: UnauthenticatedSession
    private var loginObservers: [Any] = []
    private var postLoginObservers: [Any] = []
    private var initialSyncObserver: Any?

    // MARK: - Initialization

    init(presenter: NavigationController, unauthenticatedSession: UnauthenticatedSession, sessionManager: ObservableSessionManager) {
        self.presenter = presenter
        self.unauthenticatedSession = unauthenticatedSession
        super.init()

        companyLoginController?.delegate = self
        flowStack = [.landingScreen]

        loginObservers = [
            unauthenticatedSession.addRegistrationObserver(self),
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

extension AuthenticationCoordinator: SessionManagerCreatedSessionObserver {

    func sessionManagerCreated(userSession: ZMUserSession) {
        log.info("Session manager created session: \(userSession)")
        initialSyncObserver = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
    }

    /**
     * Registers the post-login observation tokens if they were not already registered.
     */

    fileprivate func registerPostLoginObserversIfNeeded() {
        guard postLoginObservers.isEmpty else {
            log.warn("Post login observers are already registered.")
            return
        }

        guard let selfUser = delegate?.selfUser else {
            log.warn("Post login observers were not registered because there is no self user.")
            return
        }

        guard let sharedSession = delegate?.sharedUserSession else {
            log.warn("Post login observers were not registered because there is no user session.")
            return
        }

        guard let userProfile = delegate?.selfUserProfile else {
            log.warn("Post login observers were not registered because there is no user profile.")
            return
        }

        postLoginObservers = [
            userProfile.add(observer: self),
            UserChangeInfo.add(observer: self, for: selfUser, userSession: sharedSession)!
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

            case .executeFeedbackAction(let action):
                currentViewController?.executeErrorFeedbackAction?(action)

            case .presentAlert(let alertModel):
                presentAlert(for: alertModel)

            case .presentErrorAlert(let alertModel):
                presentErrorAlert(for: alertModel)

            case .completeLoginFlow:
                delegate?.userAuthenticationDidComplete(registered: false)

            case .completeRegistrationFlow:
                delegate?.userAuthenticationDidComplete(registered: true)

            case .startPostLoginFlow:
                registerPostLoginObserversIfNeeded()

            case .transition(let nextStep, let resetStack):
                transition(to: nextStep, resetStack: resetStack)

            case .performPhoneLoginFromRegistration(let phoneNumber):
                askVerificationCode(for: phoneNumber, isSigningIn: true)

            case .unwindState:
                unwind()
            }
        }
    }

    private func presentErrorAlert(for alertModel: AuthenticationCoordinatorErrorAlert) {
        presenter?.showAlert(forError: alertModel.error) { _ in
            self.executeActions(alertModel.completionActions)
        }
    }

    private func presentAlert(for alertModel: AuthenticationCoordinatorAlert) {
        let alert = UIAlertController(title: alertModel.title, message: alertModel.message, preferredStyle: .alert)

        for actionModel in alertModel.actions {
            let action = UIAlertAction(title: actionModel.title, style: .default) { _ in
                self.executeActions(actionModel.coordinatorActions)
            }

            alert.addAction(action)
        }

        presenter?.present(alert, animated: true)
    }

}

// MARK: - Actions

extension AuthenticationCoordinator {

    // MARK: Phone Number

    /**
     * Starts the phone number validation flow for the given phone number.
     * - parameter phoneNumber: The phone number to validate for login.
     */

    @objc(startPhoneNumberValidationWithPhoneNumber:)
    func startPhoneNumberValidation(_ phoneNumber: String) {
        let user: ZMIncompleteRegistrationUser?

        switch currentStep {
        case .createCredentials(let incompleteUser):
            user = incompleteUser
        case .provideCredentials:
            user = nil
        default:
            log.warn("Cannot start phone number validation from step: \(currentStep)")
            return
        }

        presenter?.showLoadingView = true
        askVerificationCode(for: phoneNumber, isSigningIn: user == nil)

        let nextStep = AuthenticationFlowStep.verifyPhoneNumber(phoneNumber: phoneNumber, user: user, credentialsValidated: false)
        transition(to: nextStep)
    }

    @objc func resendPhoneValidationCode() {
        guard case let .verifyPhoneNumber(phoneNumber, user, _) = currentStep else {
            log.info("Ignoring request to resend phone code with step = \(currentStep).")
            return
        }

        presenter?.showLoadingView = true
        askVerificationCode(for: phoneNumber, isSigningIn: user == nil)

        let nextStep = AuthenticationFlowStep.verifyPhoneNumber(phoneNumber: phoneNumber, user: user, credentialsValidated: true)
        transition(to: nextStep)
    }

    private func askVerificationCode(for phoneNumber: String, isSigningIn: Bool) {
        if isSigningIn {
            unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
        } else {
            unauthenticatedSession.requestPhoneVerificationCodeForRegistration(phoneNumber)
        }
    }

    @objc(validatePhoneNumberWithCode:)
    func validatePhoneNumber(with code: String) {
        guard case let .verifyPhoneNumber(phoneNumber, user, _) = currentStep else {
            log.info("Ignoring request to resend phone code with step = \(currentStep).")
            return
        }

        if let unauthenticatedUser = user {
            presenter?.showLoadingView = true
            unauthenticatedUser.phoneVerificationCode = code
            unauthenticatedSession.verifyPhoneNumberForRegistration(phoneNumber, verificationCode: code)
        } else {
            let credentials = ZMPhoneCredentials(phoneNumber: phoneNumber, verificationCode: code)
            requestPhoneLogin(with: credentials)
        }
    }

    // MARK: - Login

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

    @objc func submitMarketingConsent(_ consentValue: Bool) {
        guard let userSession = statusProvider?.sharedUserSession else {
            return
        }

        userSession.submitMarketingConsent(with: consentValue)
    }

    @objc func registerUser(user: ZMIncompleteRegistrationUser) {
        unauthenticatedSession.register(user: user.complete())
    }

    // MARK: UI Events

    /**
     * Manually display the company login flow.
     */

    @objc func startCompanyLoginFlowIfPossible() {
        switch currentStep {
        case .provideCredentials:
            companyLoginController?.displayLoginCodePrompt()
        default:
            return
        }
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

}

// MARK: - User Session Events

extension AuthenticationCoordinator: UserProfileUpdateObserver, ZMUserObserver, ZMRegistrationObserver {

    // MARK: - Phone Registration

    /// Called when the phone number verification succeeds.
    func phoneVerificationDidSucceed() {
        // no-op
    }

    /// Called when the phone verification fails.
    func phoneVerificationDidFail(_ error: Error!) {
        // no-op
    }

    /// Called when the validation code for the registered phone number was sent.
    func phoneVerificationCodeRequestDidFail(_ error: Error!) {
        eventHandlingManager.handleEvent(ofType: .registrationError(error as NSError))
    }

    /// Called when the validation code for the registered phone number was sent.
    func phoneVerificationCodeRequestDidSucceed() {
        eventHandlingManager.handleEvent(ofType: .phoneLoginCodeAvailable)
    }

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

//    - (void)registrationDidFail:(NSError *)error
//    {
//    self.navigationController.showLoadingView = NO;
//    [self showAlertForError:error];
//    }
//
//    - (void)proceedToCodeVerificationForLogin:(BOOL)login
//    {
//    self.navigationController.showLoadingView = NO;
//
//    PhoneVerificationStepViewController *phoneVerificationStepViewController = [[PhoneVerificationStepViewController alloc] initWithUnregisteredUser:self.unregisteredUser];
//    phoneVerificationStepViewController.formStepDelegate = self;
//    phoneVerificationStepViewController.delegate = self;
//    phoneVerificationStepViewController.isLoggingIn = login;
//
//    [self.navigationController pushViewController:phoneVerificationStepViewController.registrationFormViewController animated:YES];
//    }
//
//    - (void)phoneVerificationCodeRequestDidSucceed
//    {
//
//    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
//    [self proceedToCodeVerificationForLogin:NO];
//    } else {
//    [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
//    }
//    }
//
//    - (void)phoneVerificationCodeRequestDidFail:(NSError *)error
//    {
//    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
//    }
//
//    self.navigationController.showLoadingView = NO;
//
//    if(error.code == ZMUserSessionPhoneNumberIsAlreadyRegistered) {
//    LoginCredentials *credentials = [[LoginCredentials alloc] initWithEmailAddress:nil phoneNumber:self.unregisteredUser.phoneNumber password:nil usesCompanyLogin:NO];
//    [self.phoneNumberStepViewController reset];
//    //        [self.registrationDelegate registrationFlowViewController:self needsToSignInWith:credentials];
//    }
//
//    [self showAlertForError:error];
//    }
//
//    - (void)phoneVerificationDidSucceed
//    {
//    self.navigationController.showLoadingView = NO;
//
//    [UIAlertController showNewsletterSubscriptionDialogWithOver: self
//    completionHandler: ^(BOOL marketingConsent) {
//    self.marketingConsent = marketingConsent;
//
//    //        [self presentTermsOfUseStepController];
//    }];
//    }
//
//    - (void)phoneVerificationDidFail:(NSError *)error
//    {
//    self.navigationController.showLoadingView = NO;
//    [self showAlertForError:error];
//    }

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
        transition(to: .provideCredentials)
    }

    func landingViewControllerDidChooseCreateAccount() {
        let unregisteredUser = ZMIncompleteRegistrationUser()
        unregisteredUser.accentColorValue = UIColor.indexedAccentColor()

        transition(to: .createCredentials(unregisteredUser))
    }

    func landingViewControllerDidChooseCreateTeam() {
        // flowController.startFlow()
    }

}
