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

/**
 * Manages the flow of authentication for the user. Decides which steps to take for login, registration
 * and team creation.
 */

class AuthenticationCoordinator: NSObject, AuthenticationEventResponderChainDelegate {

    /// The handle to the OS log for authentication events.
    let log = ZMSLog(tag: "Authentication")

    /// The navigation controller that presents the authentication interface.
    weak var presenter: NavigationController?

    /// The object receiving updates from the authentication state and providing state.
    weak var delegate: AuthenticationCoordinatorDelegate?

    // MARK: - Event Handling Properties

    /**
     * The object responsible for handling events.
     *
     * You use this object to tag events as they happen. It then iterates over the internal
     * event handlers in the chain, to decide what actions to take.
     *
     * The authentication coordinator is the delegate of the event responder chain, as it is
     * responsible for executing the actions provided by the selected event handler.
     */

    let eventResponderChain = AuthenticationEventResponderChain()

    /// Shortcut for accessing the authentication status provider (returns the delegate).
    var statusProvider: AuthenticationStatusProvider? {
        return delegate
    }

    // MARK: - State

    var currentViewController: AuthenticationStepViewController?

    let stateController: AuthenticationStateController
    let registrationStatus: RegistrationStatus

    let sessionManager: ObservableSessionManager
    let unauthenticatedSession: UnauthenticatedSession
    let interfaceBuilder = AuthenticationInterfaceBuilder()
    let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())

    private var loginObservers: [Any] = []
    private var postLoginObservers: [Any] = []
    private var initialSyncObserver: Any?

    private(set) lazy var popTransition = PopTransition()
    private(set) lazy var pushTransition = PushTransition()
    private var pendingAlert: AuthenticationCoordinatorAlert?

    // MARK: - Initialization

    init(presenter: NavigationController, unauthenticatedSession: UnauthenticatedSession, sessionManager: ObservableSessionManager) {
        self.presenter = presenter
        self.sessionManager = sessionManager
        self.unauthenticatedSession = unauthenticatedSession
        self.registrationStatus = unauthenticatedSession.registrationStatus
        self.stateController = AuthenticationStateController()
        super.init()

        registrationStatus.delegate = self
        companyLoginController?.delegate = self

        loginObservers = [
            PreLoginAuthenticationNotification.register(self, for: unauthenticatedSession),
            PostLoginAuthenticationNotification.addObserver(self),
            sessionManager.addSessionManagerCreatedSessionObserver(self)
        ]

        presenter.delegate = self
        stateController.delegate = self
        eventResponderChain.configure(delegate: self)
    }

}

// MARK: - State Management

extension AuthenticationCoordinator: AuthenticationStateControllerDelegate {

    func stateDidChange(_ newState: AuthenticationFlowStep, withReset resetStack: Bool) {
        guard newState.needsInterface else {
            return
        }

        guard let stepViewController = interfaceBuilder.makeViewController(for: newState) else {
            fatalError("Step \(newState) requires user interface, but the interface builder does not support it.")
        }

        stepViewController.authenticationCoordinator = self
        currentViewController = stepViewController

        if resetStack {
            presenter?.backButtonEnabled = false
            presenter?.setViewControllers([stepViewController], animated: true)
        } else {
            presenter?.backButtonEnabled = newState.allowsUnwind
            presenter?.pushViewController(stepViewController, animated: true)
        }
    }

}

// MARK: - Event Handling

extension AuthenticationCoordinator: AuthenticationActioner, SessionManagerCreatedSessionObserver {

    func sessionManagerCreated(userSession: ZMUserSession) {
        log.info("Session manager created session: \(userSession)")
        currentPostRegistrationFields().apply(sendPostRegistrationFields)
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
                stateController.transition(to: nextStep, resetStack: resetStack)

            case .performPhoneLoginFromRegistration(let phoneNumber):
                sendLoginCode(phoneNumber: phoneNumber, isResend: false)

            case .configureNotifications:
                sessionManager.configureUserNotifications()

            case .startIncrementalUserCreation(let unregisteredUser):
                stateController.transition(to: .incrementalUserCreation(unregisteredUser, .start))
                eventResponderChain.handleEvent(ofType: .registrationStepSuccess)

            case .setMarketingConsent(let consentValue):
                setMarketingConsent(consentValue)

            case .completeUserRegistration:
                finishRegisteringUser()

            case .unwindState(let popController):
                if popController {
                    presenter?.popViewController(animated: true)
                } else {
                    stateController.unwindState()
                }

            case .openURL(let url):
                let browser = BrowserViewController(url: url)
                browser.onDismiss = {
                    if let alertModel = self.pendingAlert {
                        self.presenter?.showLoadingView = false
                        self.presentAlert(for: alertModel)
                        self.pendingAlert = nil
                    }
                }

                self.presenter?.present(browser, animated: true, completion: nil)

            case .repeatAction:
                repeatAction()

            case .advanceTeamCreation(let newValue):
                advanceTeamCreation(value: newValue)

            case .displayInlineError(let error):
                currentViewController?.displayError?(error)

            case .assignRandomProfileImage:
                assignRandomProfileImage()
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
                if actionModel.coordinatorActions.contains(where: { $0.retainsModal }) {
                    self.pendingAlert = alertModel
                }

                self.executeActions(actionModel.coordinatorActions)
            }

            alert.addAction(action)
        }

        presenter?.present(alert, animated: true)
    }

    /// Repeats the current action.
    func repeatAction() {
        switch stateController.currentStep {
        case .teamCreation(.verifyEmail):
            resendTeamEmailCode()
        case .enterLoginCode, .enterActivationCode:
            resendVerificationCode()
        default:
            return
        }
    }

}

// MARK: - Actions

extension AuthenticationCoordinator {

    // MARK: Starting the Flow

    /**
     * Call this method when the application becomes unauthenticated and that the user
     * needs to authenticate.
     *
     * - parameter error: The error that caused the unauthenticated state, if any.
     * - parameter numberOfAccounts: The number of accounts that are signed in with the app.
     */

    func startAuthentication(with error: NSError?, numberOfAccounts: Int) {
        eventResponderChain.handleEvent(ofType: .flowStart(error, numberOfAccounts))
    }

    /**
     * Creates a new unregistered user for starting a registration flow.
     */

    func makeUnregisteredUser() -> UnregisteredUser {
        let user = UnregisteredUser()
        user.accentColorValue = UIColor.indexedAccentColor()
        return user
    }

    /**
     * Attempts to switch the from login to registration or registration to login.
     * - note: This only works if the flow is on the `provideCredentials` or `createCredentials` step.
     */

    @objc func permuteCredentialProvidingFlowType() {
        switch stateController.currentStep {
        case .provideCredentials:
            let unregisteredUser = makeUnregisteredUser()
            stateController.replaceCurrentStep(with: .createCredentials(unregisteredUser))

        case .createCredentials:
            stateController.replaceCurrentStep(with: .provideCredentials)

        default:
            log.error("Cannot permute credential providing flow from step \(stateController.currentStep).")
        }
    }

    // MARK: Registration Code

    /**
     * Starts the registration flow with the specified phone number.
     *
     * This step will ask the registration status to send the activation code
     * by text message. It will advance the state to `.sendActivationCode`.
     *
     * - parameter phoneNumber: The phone number to activate and register with.
     */

    @objc(startRegistrationWithPhoneNumber:)
    func startRegistration(phoneNumber: String) {
        guard case let .createCredentials(unregisteredUser) = stateController.currentStep, let presenter = self.presenter else {
            log.error("Cannot start phone registration outside of registration flow.")
            return
        }

        UIAlertController.requestTOSApproval(over: presenter, forTeamAccount: false) { approved in
            if approved {
                unregisteredUser.credentials = .phone(number: phoneNumber)
                unregisteredUser.acceptedTermsOfService = true
                self.sendActivationCode(.phone(phoneNumber), unregisteredUser, isResend: false)
            }
        }
    }

    /**
     * Starts the registration flow with the specified e-mail and password.
     *
     * This step will ask the registration status to send the activation code
     * by e-mail. It will advance the state to `.sendActivationCode`.
     *
     * - parameter name: The display name of the user.
     * - parameter email: The email address to activate and register with.
     * - parameter password: The password to link with the e-mail.
     */

    @objc(startRegistrationWithName:email:password:)
    func startRegistration(name: String, email: String, password: String) {
        guard case let .createCredentials(unregisteredUser) = stateController.currentStep, let presenter = self.presenter else {
            log.error("Cannot start email registration outside of registration flow.")
            return
        }

        UIAlertController.requestTOSApproval(over: presenter, forTeamAccount: false) { approved in
            if approved {
                unregisteredUser.credentials = .email(address: email, password: password)
                unregisteredUser.name = name
                unregisteredUser.acceptedTermsOfService = true

                self.sendActivationCode(.email(email), unregisteredUser, isResend: false)
            }
        }
    }

    /// Sends the registration activation code.
    private func sendActivationCode(_ credential: UnverifiedCredential, _ user: UnregisteredUser, isResend: Bool) {
        presenter?.showLoadingView = true
        stateController.transition(to: .sendActivationCode(credential, user: user, isResend: isResend))
        registrationStatus.sendActivationCode(to: credential)
    }

    /// Asks the registration
    private func activateCredentials(credential: UnverifiedCredential, user: UnregisteredUser, code: String) {
        presenter?.showLoadingView = true
        stateController.transition(to: .activateCredentials(credential, user: user, code: code))
        registrationStatus.checkActivationCode(credential: credential, code: code)
    }

    // MARK: Linear Registration

    /**
     * Notifies the registration state observers that the user set a display name.
     */

    @objc(setUserName:)
    func setUserName(_ userName: String) {
        updateUnregisteredUser {
            $0.name = userName
        }
    }

    func setMarketingConsent(_ consentValue: Bool) {
        switch stateController.currentStep {
        case .incrementalUserCreation:
            updateUnregisteredUser {
                $0.marketingConsent = consentValue
            }
        case .teamCreation(TeamCreationState.provideMarketingConsent(let teamName, let email, let activationCode)):
            let nextState: TeamCreationState = .setFullName(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: consentValue)
            stateController.transition(to: .teamCreation(nextState), resetStack: true)
        default:
            log.error("Cannot set marketing consent in current state \(stateController.currentStep)")
            return
        }
    }

    /// Updates the fields of the unregistered user, and advances the state.
    private func updateUnregisteredUser(_ updateBlock: (UnregisteredUser) -> Void) {
        guard case let .incrementalUserCreation(unregisteredUser, _) = stateController.currentStep else {
            log.error("Cannot update unregistered user outide of the incremental user creation flow")
            return
        }

        updateBlock(unregisteredUser)
        eventResponderChain.handleEvent(ofType: .registrationStepSuccess)
    }

    /// Creates the user on the backend and advances the state.
    private func finishRegisteringUser() {
        guard case let .incrementalUserCreation(unregisteredUser, _) = stateController.currentStep else {
            return
        }

        stateController.transition(to: .createUser(unregisteredUser))
        registrationStatus.create(user: unregisteredUser)
    }

    private func currentPostRegistrationFields() -> AuthenticationPostRegistrationFields? {
        switch stateController.currentStep {
        case .createUser(let unregisteredUser):
            guard let marketingConsent = unregisteredUser.marketingConsent else {
                return nil
            }

            return AuthenticationPostRegistrationFields(marketingConsent: marketingConsent)

        case let .teamCreation(.createTeam(_, _, _, marketingConsent, _, _)):
            return AuthenticationPostRegistrationFields(marketingConsent: marketingConsent)

        default:
            return nil
        }
    }

    /// Sends the fields provided during registration that requires a registered user session.
    private func sendPostRegistrationFields(_ fields: AuthenticationPostRegistrationFields) {
        guard let userSession = statusProvider?.sharedUserSession else {
            log.error("Could not save the marketing consent as there is no user session for the user.")
            return
        }

        // Marketing consent
        UIAlertController.newsletterSubscriptionDialogWasDisplayed = true
        userSession.submitMarketingConsent(with: fields.marketingConsent)
    }

    /// Auto-assigns a random profile image to the user.
    func assignRandomProfileImage() {
        guard let userSession = statusProvider?.sharedUserSession else {
            log.error("Not assigning a random profile picture, because the user session does not exist.")
            return
        }

        URLSession.shared.dataTask(with: .wr_randomProfilePictureSource) { (data, _, error) in
            if let data = data, error == nil {
                DispatchQueue.main.async {
                    userSession.profileUpdate.updateImage(imageData: data)
                }
            }
            }.resume()
    }

    // MARK: Login

    /**
     * Starts the phone number login flow for the given phone number.
     * - parameter phoneNumber: The phone number to validate for login.
     */

    @objc(startLoginWithPhoneNumber:)
    func startLogin(phoneNumber: String) {
        sendLoginCode(phoneNumber: phoneNumber, isResend: false)
    }

    /**
     * Requests an e-mail login for the specified credentials.
     * - parameter credentials: The e-mail credentials to sign in with.
     */

    @objc(requestEmailLoginWithCredentials:)
    func requestEmailLogin(with credentials: ZMEmailCredentials) {
        presenter?.showLoadingView = true
        stateController.transition(to: .authenticateEmailCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    /// Sends the login verification code to the phone number.
    private func sendLoginCode(phoneNumber: String, isResend: Bool) {
        presenter?.showLoadingView = true
        let nextStep = AuthenticationFlowStep.sendLoginCode(phoneNumber: phoneNumber, isResend: isResend)
        stateController.transition(to: nextStep)
        unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
    }

    /// Requests a phone login for the specified credentials.
    private func requestPhoneLogin(with credentials: ZMPhoneCredentials) {
        presenter?.showLoadingView = true
        stateController.transition(to: .authenticatePhoneCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    // MARK: Generic Verification

    /**
     * Resends the verification code to the user, if allowed by the current state.
     */

    @objc func resendVerificationCode() {
        switch stateController.currentStep {
        case .enterLoginCode(let phoneNumber):
            sendLoginCode(phoneNumber: phoneNumber, isResend: true)
        case .enterActivationCode(let credential, let user):
            sendActivationCode(credential, user, isResend: true)
        default:
            log.error("Cannot send verification code in the current state (\(stateController.currentStep)")
        }
    }

    /**
     * Checks the verification code provided by the user, and continues to the next appropriate step.
     * - parameter code: The verification code provided by the user.
     */

    @objc(continueFlowWithVerificationCode:)
    func continueFlow(withVerificationCode code: String) {
        switch stateController.currentStep {
        case .enterLoginCode(let phoneNumber):
            let credentials = ZMPhoneCredentials(phoneNumber: phoneNumber, verificationCode: code)
            requestPhoneLogin(with: credentials)
        case .enterActivationCode(let unverifiedCredential, let user):
            activateCredentials(credential: unverifiedCredential, user: user, code: code)
        default:
            log.error("Cannot continue flow with user code in the current state (\(stateController.currentStep)")
        }
    }

    // MARK: - Add Email And Password

    /**
     * Sets th e-mail and password credentials for the current user.
     */

    @objc func setEmailCredentialsForCurrentUser(_ credentials: ZMEmailCredentials) {
        guard case let .addEmailAndPassword(_, profile, _) = stateController.currentStep else {
            log.error("Cannot save e-mail and password outside of designated step.")
            return
        }

        stateController.transition(to: .registerEmailCredentials(credentials, isResend: false))
        presenter?.showLoadingView = true

        let result = setCredentialsWithProfile(profile, credentials: credentials) && sessionManager.update(credentials: credentials) == true

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
        guard case let .pendingEmailLinkVerification(credentials) = stateController.currentStep else {
            return
        }

        guard let userProfile = delegate?.selfUserProfile else {
            return
        }

        presenter?.showLoadingView = true
        stateController.transition(to: .registerEmailCredentials(credentials, isResend: true))
        setCredentialsWithProfile(userProfile, credentials: credentials)
    }

    // MARK: - Backup

    /**
     * Call this method to mark the backup step as completed.
     */

    @objc func completeBackupStep() {
        presenter?.showLoadingView = true
        unauthenticatedSession.continueAfterBackupImportStep()
    }

    // MARK: UI Events

    /**
     * Manually display the company login flow.
     */

    @objc var canStartCompanyLoginFlow: Bool {
        switch stateController.currentStep {
        case .provideCredentials, .createCredentials, .reauthenticate:
            return true
        default:
            return false
        }
    }
    
    @objc func startCompanyLoginFlowIfPossible() {
        switch stateController.currentStep {
        case .provideCredentials, .createCredentials, .reauthenticate:
            companyLoginController?.displayLoginCodePrompt()
        default:
            return
        }
    }

    /**
     * Call this method when the corrdinated view controller appears, to detect the login code and display it if needed.
     */

    func detectLoginCodeIfPossible() {
        switch stateController.currentStep {
        case .landingScreen, .provideCredentials, .createCredentials:
            companyLoginController?.isAutoDetectionEnabled = true
            companyLoginController?.detectLoginCode()

        default:
            companyLoginController?.isAutoDetectionEnabled = false
        }
    }

    /**
     * Call this method when company login fails.
     */

    func cancelCompanyLogin() {
        guard case .companyLogin = stateController.currentStep else {
            log.error("Cannot cancel company login outside of the dedicated flow.")
            return
        }

        stateController.unwindState()
    }

    // MARK: - Team Input

    /**
     * Advances the team creation state with the user input.
     * - parameter value: The value provided by the user.
     */

    func advanceTeamCreation(value: String) {
        guard case .teamCreation(let state) = stateController.currentStep else {
            log.error("Cannot advance team creation outside of the dedicated flow.")
            return
        }

        guard let nextState = state.nextState(with: value) else {
            log.error("The state \(state) cannot be advanced.")
            return
        }

        stateController.transition(to: .teamCreation(nextState))

        switch nextState {
        case let .sendEmailCode(_, emailAddress, _):
            guard let presenter = self.presenter else {
                break
            }

            UIAlertController.requestTOSApproval(over: presenter, forTeamAccount: true) { approved in
                if approved {
                    presenter.showLoadingView = true
                    self.registrationStatus.sendActivationCode(to: .email(emailAddress))
                } else {
                    presenter.showLoadingView = false
                    self.stateController.unwindState()
                }
            }

        case let .verifyActivationCode(_, emailAddress, activationCode):
            presenter?.showLoadingView = true
            registrationStatus.checkActivationCode(credential: .email(emailAddress), code: activationCode)

        case .provideMarketingConsent:
            presenter?.showLoadingView = false
            let marketingConsentAlertModel = AuthenticationCoordinatorAlert.makeMarketingConsentAlert()
            presentAlert(for: marketingConsentAlertModel)

        case let .createTeam(teamName, email, activationCode, _, fullName, password):
            let unregisteredTeam = UnregisteredTeam(teamName: teamName, email: email, emailCode: activationCode, fullName: fullName, password: password, accentColor: UIColor.indexedAccentColor())
            registrationStatus.create(team: unregisteredTeam)

        default:
            break
        }

    }

    func resendTeamEmailCode() {
        guard case let .teamCreation(teamState) = stateController.currentStep else {
            return
        }

        guard case let .verifyEmail(teamName, emailAddress) = teamState else {
            return
        }

        presenter?.showLoadingView = true
        let nextTeamState: TeamCreationState = .sendEmailCode(teamName: teamName, email: emailAddress, isResend: true)
        stateController.transition(to: .teamCreation(nextTeamState))

        registrationStatus.sendActivationCode(to: .email(emailAddress))
    }

}
