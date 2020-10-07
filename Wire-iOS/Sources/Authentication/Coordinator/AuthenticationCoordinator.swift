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
import UIKit

/**
 * Provides and asks for context when registering users.
 */

protocol AuthenticationCoordinatorDelegate: class {

    /**
     * The coordinator finished authenticating the user.
     * - parameter addedAccount: Whether the authentication action added a new account
     * to this device.
     */

    func userAuthenticationDidComplete(addedAccount: Bool)

}

/**
 * Manages the flow of authentication for the user. Decides which steps to take for login, registration
 * and team creation.
 *
 * Interaction with the different components is abstracted away in the *actions*. You can execute actions
 * yourself, in response to user interaction. However, most of the time, actions are passed by the responder
 * chain, which is composed of objects that compute the actions to execute in response to a notification
 * or delegate call from one of the abstracted components.
 */

class AuthenticationCoordinator: NSObject, AuthenticationEventResponderChainDelegate {
    
    /// The handle to the OS log for authentication events.
    let log = ZMSLog(tag: "Authentication")

    /// The navigation controller that presents the authentication interface.
    weak var presenter: (UINavigationController & SpinnerCapable)?

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

    let eventResponderChain: AuthenticationEventResponderChain

    // MARK: - State

    /// The displayed view controller.
    var currentViewController: AuthenticationStepViewController?

    /// The object controlling the state of authentication.
    let stateController: AuthenticationStateController
    
    /// The object hepls accessing to some authentication information.
    let statusProvider: AuthenticationStatusProvider

    /// The object that manages active user sessions.
    let sessionManager: ObservableSessionManager

    /// The object that determines what features are available.
    let featureProvider: AuthenticationFeatureProvider

    /// The object to use to create the UI for authentication steps.
    let interfaceBuilder: AuthenticationInterfaceBuilder

    /// The object to use to start and control the company login flow.
    let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())

    /// The object to use to restore backups.
    let backupRestoreController: BackupRestoreController

    // MARK: - Internal State

    private var loginObservers: [Any] = []
    private var unauthenticatedSessionObserver: Any?
    private var postLoginObservers: [Any] = []
    private var initialSyncObserver: Any?
    private var pendingAlert: AuthenticationCoordinatorAlert?
    var pendingModal: UIViewController?

    /// Whether an account was added.
    var addedAccount: Bool = false

    /// The object to use to register users and teams.
    var registrationStatus: RegistrationStatus {
        return unauthenticatedSession.registrationStatus
    }

    /// The user session to use before authentication has finished.
    var unauthenticatedSession: UnauthenticatedSession {
        return sessionManager.activeUnauthenticatedSession
    }

    // MARK: - Initialization

    /// Creates a new authentication coordinator with the required supporting objects.
    init(presenter: UINavigationController & SpinnerCapable,
         sessionManager: ObservableSessionManager,
         featureProvider: AuthenticationFeatureProvider,
         statusProvider: AuthenticationStatusProvider) {
        self.presenter = presenter
        self.sessionManager = sessionManager
        self.statusProvider = statusProvider
        self.featureProvider = featureProvider
        self.stateController = AuthenticationStateController()
        self.interfaceBuilder = AuthenticationInterfaceBuilder(featureProvider: featureProvider)
        self.eventResponderChain = AuthenticationEventResponderChain(featureProvider: featureProvider)
        self.backupRestoreController = BackupRestoreController(target: presenter)
        super.init()

        updateLoginObservers()
        unauthenticatedSessionObserver = sessionManager.addUnauthenticatedSessionManagerCreatedSessionObserver(self)
        companyLoginController?.delegate = self
        backupRestoreController.delegate = self
        presenter.delegate = self
        stateController.delegate = self
        eventResponderChain.configure(delegate: self)
    }

}

// MARK: - State Management

extension AuthenticationCoordinator: AuthenticationStateControllerDelegate {

    /// Call this when the presented finished presenting.
    func completePresentation() {
        if let pendingModal = pendingModal {
            presenter?.present(pendingModal, animated: true)
            self.pendingModal = nil
        }
    }

    func stateDidChange(_ newState: AuthenticationFlowStep,
                        mode: AuthenticationStateController.StateChangeMode) {
        guard let presenter = self.presenter, newState.needsInterface else {
            return
        }

        guard var stepViewController = interfaceBuilder.makeViewController(for: newState) else {
            fatalError("Step \(newState) requires user interface, but the interface builder does not support it.")
        }

        stepViewController.authenticationCoordinator = self
        currentViewController = stepViewController

        switch mode {
        case .normal:
            presenter.pushViewController(stepViewController, animated: true)

        case .reset:
            presenter.setViewControllers([stepViewController], animated: true)

        case .replace:
            var viewControllers = presenter.viewControllers
            viewControllers[viewControllers.count - 1] = stepViewController
            presenter.setViewControllers(viewControllers, animated: true)
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

    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) {
        updateLoginObservers()
    }

    func updateLoginObservers() {
        loginObservers = [
            PreLoginAuthenticationNotification.register(self, for: unauthenticatedSession),
            PostLoginAuthenticationNotification.addObserver(self),
            sessionManager.addSessionManagerCreatedSessionObserver(self)
        ]

        if let userSession = SessionManager.shared?.activeUserSession {
            initialSyncObserver = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }

        registrationStatus.delegate = self
    }

    /**
     * Registers the post-login observation tokens if they were not already registered.
     */

    fileprivate func registerPostLoginObserversIfNeeded() {
        guard postLoginObservers.isEmpty else {
            log.warn("Post login observers are already registered.")
            return
        }

        guard let selfUser = statusProvider.selfUser else {
            log.error("Post login observers were not registered because there is no self user.")
            return
        }

        guard let sharedSession = statusProvider.sharedUserSession else {
            log.error("Post login observers were not registered because there is no user session.")
            return
        }

        guard let userProfile = statusProvider.selfUserProfile else {
            log.error("Post login observers were not registered because there is no user profile.")
            return
        }

        postLoginObservers = [
            userProfile.add(observer: self),
            UserChangeInfo.add(observer: self, for: selfUser, in: sharedSession)!
        ]
    }

    /**
     * Executes the actions in response to an event.
     * - parameter actions: The actions to execute.
     */

    func executeActions(_ actions: [AuthenticationCoordinatorAction]) {
        for action in actions {
            switch action {
            case .showLoadingView:
                presenter?.isLoadingViewVisible = true

            case .hideLoadingView:
                presenter?.isLoadingViewVisible = false

            case .completeBackupStep:
                unauthenticatedSession.continueAfterBackupImportStep()

            case .executeFeedbackAction(let action):
                currentViewController?.executeErrorFeedbackAction(action)

            case .presentAlert(let alertModel):
                presentAlert(for: alertModel)

            case .presentErrorAlert(let alertModel):
                presentErrorAlert(for: alertModel)

            case .completeLoginFlow:
                delegate?.userAuthenticationDidComplete(addedAccount: addedAccount)

            case .completeRegistrationFlow:
                delegate?.userAuthenticationDidComplete(addedAccount: true)

            case .startPostLoginFlow:
                registerPostLoginObserversIfNeeded()

            case .transition(let nextStep, let mode):
                stateController.transition(to: nextStep, mode: mode)

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
                unwindState(popController: popController)

            case .openURL(let url):
                openURL(url)

            case .repeatAction:
                repeatAction()

            case .advanceTeamCreation(let newValue):
                advanceTeamCreation(value: newValue)

            case .displayInlineError(let error):
                currentViewController?.displayError(error)

            case .assignRandomProfileImage:
                assignRandomProfileImage()

            case .continueFlowWithLoginCode(let code):
                continueFlow(withVerificationCode: code)

            case .switchCredentialsType(let newType):
                switchCredentialsType(newType)

            case .startRegistrationFlow(let unverifiedCredential):
                startRegistration(unverifiedCredential)

            case .setUserName(let userName):
                updateUnregisteredUser(\.name, userName)

            case .setUserPassword(let password):
                updateUnregisteredUser(\.password, password)

            case .updateBackendEnvironment(let url):
                companyLoginController?.updateBackendEnvironment(with: url)

            case .startCompanyLogin(let code):
                startCompanyLoginFlowIfPossible(linkCode: code)
            case .startSSOFlow:
                startAutomaticSSOFlow()

            case .startLoginFlow(let request):
                startLoginFlow(request: request)

            case .startBackupFlow:
                backupRestoreController.startBackupFlow()

            case .signOut(let warn):
                signOut(warn: warn)

            case .addEmailAndPassword(let newCredentials):
                setEmailCredentialsForCurrentUser(newCredentials)
            }
        }
    }

}

// MARK: - External Input

extension AuthenticationCoordinator {

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
        user.accentColor = .random
        return user
    }

    /**
     * Notifies the event responder chain that user input was provided.
     *
     * The responder chain will then go through all the input event handlers and
     * pick the first that accepts the input.
     *
     * - parameter input: The input provided by the user.
     */

    func handleUserInput(_ input: Any) {
        eventResponderChain.handleEvent(ofType: .userInput(input))
    }

}

// MARK: - Actions

extension AuthenticationCoordinator {

    // MARK: - State

    /// Unwinds the state.
    private func unwindState(popController: Bool) {
        if popController {
            _ = presenter?.popViewController(animated: true)
        } else {
            stateController.unwindState()
        }
    }

    /// Signs the current user out with a warning.
    private func signOut(warn: Bool) {
        if warn {
            let signOutAction = AuthenticationCoordinatorAlertAction(title: "general.ok".localized, coordinatorActions: [.showLoadingView, .signOut(warn: false)], style: .destructive)

            let alertModel = AuthenticationCoordinatorAlert(title: "self.settings.account_details.log_out.alert.title".localized,
                                                            message: "self.settings.account_details.log_out.alert.message".localized,
                                                            actions: [.cancel, signOutAction])

            presentAlert(for: alertModel)
        } else {
            guard let accountId = unauthenticatedSession.accountId,
                  let unauthenticatedAccount = sessionManager.accountManager.account(with: accountId) else {
                fatal("No unauthenticated account to log out from")
            }

            sessionManager.delete(account: unauthenticatedAccount)
        }
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

    // MARK: - Modals

    /// Opens the browser and reopens the current alert upon dismissal if needed.
    private func openURL(_ url: URL) {
        let browser = BrowserViewController(url: url)
        browser.onDismiss = {
            if let alertModel = self.pendingAlert {
                self.presenter?.isLoadingViewVisible = false
                self.presentAlert(for: alertModel)
                self.pendingAlert = nil
            }
        }

        self.presenter?.present(browser, animated: true, completion: nil)
    }

    /// Presents an error alert.
    private func presentErrorAlert(for alertModel: AuthenticationCoordinatorErrorAlert) {
        presenter?.showAlert(for: alertModel.error) { _ in
            self.executeActions(alertModel.completionActions)
        }
    }

    /// Presents an alert.
    private func presentAlert(for alertModel: AuthenticationCoordinatorAlert) {
        let alert = UIAlertController(title: alertModel.title, message: alertModel.message, preferredStyle: .alert)

        for actionModel in alertModel.actions {
            let action = UIAlertAction(title: actionModel.title, style: actionModel.style) { _ in
                if actionModel.coordinatorActions.contains(where: { $0.retainsModal }) {
                    self.pendingAlert = alertModel
                }

                self.executeActions(actionModel.coordinatorActions)
            }

            alert.addAction(action)
        }

        presenter?.present(alert, animated: true)
    }

    // MARK: - Registration Code

    /// Switches the type of credentials in the current step.
    private func switchCredentialsType(_ newType: AuthenticationCredentialsType) {
        switch stateController.currentStep {
        case .createCredentials(let unregisteredUser, _):
            let newStep = AuthenticationFlowStep.createCredentials(unregisteredUser, newType)
            stateController.transition(to: newStep, mode: .replace)
        case .provideCredentials:
            let newStep = AuthenticationFlowStep.provideCredentials(newType, nil)
            stateController.transition(to: newStep, mode: .replace)
        default:
            log.warn("The current step does not support credential type switching")
        }
    }

    /**
     * Starts the registration flow with the specified credentials.
     *
     * This step will ask the registration status to send the activation code
     * by text message or email. It will advance the state to `.sendActivationCode`.
     *
     * - parameter credentials: The unverified credentials to register with.
     */

    private func startRegistration(_ credentials: UnverifiedCredentials) {
        guard case let .createCredentials(unregisteredUser, _) = stateController.currentStep, let presenter = self.presenter else {
            log.error("Cannot start phone registration outside of registration flow.")
            return
        }

        UIAlertController.requestTOSApproval(over: presenter, forTeamAccount: false) { approved in
            if approved {
                unregisteredUser.acceptedTermsOfService = true
                unregisteredUser.credentials = credentials
                self.sendActivationCode(credentials, unregisteredUser, isResend: false)
            }
        }
    }

    /// Sends the registration activation code.
    private func sendActivationCode(_ credentials: UnverifiedCredentials, _ user: UnregisteredUser, isResend: Bool) {
        presenter?.isLoadingViewVisible = true
        stateController.transition(to: .sendActivationCode(credentials, user: user, isResend: isResend))
        registrationStatus.sendActivationCode(to: credentials)
    }

    /// Asks the registration status to activate the credentials with the code provided by the user.
    private func activateCredentials(credentials: UnverifiedCredentials, user: UnregisteredUser, code: String) {
        presenter?.isLoadingViewVisible = true
        stateController.transition(to: .activateCredentials(credentials, user: user, code: code))
        registrationStatus.checkActivationCode(credentials: credentials, code: code)
    }

    // MARK: - Linear Registration

    /// Sets the marketing consent value for the user to be registered.
    private func setMarketingConsent(_ consentValue: Bool) {
        switch stateController.currentStep {
        case .incrementalUserCreation:
            updateUnregisteredUser(\.marketingConsent, consentValue)

        case .teamCreation(TeamCreationState.provideMarketingConsent(let teamName, let email, let activationCode)):
            let nextState: TeamCreationState = .setFullName(teamName: teamName, email: email, activationCode: activationCode, marketingConsent: consentValue)
            stateController.transition(to: .teamCreation(nextState), mode: .reset)
        default:
            log.error("Cannot set marketing consent in current state \(stateController.currentStep)")
            return
        }
    }

    /// Updates a value of the unregistered user and notifies the responder chain of the success.
    private func updateUnregisteredUser<T>(_ keyPath: ReferenceWritableKeyPath<UnregisteredUser, T?>, _ newValue: T) {
        guard case let .incrementalUserCreation(unregisteredUser, _) = stateController.currentStep else {
            log.error("Cannot update unregistered user outide of the incremental user creation flow")
            return
        }

        unregisteredUser[keyPath: keyPath] = newValue
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

    // MARK: - Post Registration

    /// Computes the post registration fields, if any.
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
        guard let userSession = statusProvider.sharedUserSession else {
            log.error("Could not save the marketing consent as there is no user session for the user.")
            return
        }

        // Marketing consent
        UIAlertController.newsletterSubscriptionDialogWasDisplayed = true
        userSession.submitMarketingConsent(with: fields.marketingConsent)
    }

    /// Auto-assigns a random profile image to the user.
    private func assignRandomProfileImage() {
        guard let userSession = statusProvider.sharedUserSession else {
            log.error("Not assigning a random profile picture, because the user session does not exist.")
            return
        }

        URLSession.shared.dataTask(with: .wr_randomProfilePictureSource) { (data, _, error) in
            if let data = data, error == nil {
                DispatchQueue.main.async {
                    userSession.userProfileImage?.updateImage(imageData: data)
                }
            }
        }.resume()
    }

    // MARK: - Login

    /// Starts the login flow with the specified request.
    private func startLoginFlow(request: AuthenticationLoginRequest) {
        switch request {
        case .email(let address, let password):
            let credentials = ZMEmailCredentials(email: address, password: password)
            presenter?.isLoadingViewVisible = true
            stateController.transition(to: .authenticateEmailCredentials(credentials))
            unauthenticatedSession.login(with: credentials)

        case .phoneNumber(let phoneNumber):
            presenter?.isLoadingViewVisible = true
            let nextStep = AuthenticationFlowStep.sendLoginCode(phoneNumber: phoneNumber, isResend: false)
            stateController.transition(to: nextStep)
            unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
        }
    }

    /// Sends the login verification code to the phone number.
    private func sendLoginCode(phoneNumber: String, isResend: Bool) {
        presenter?.isLoadingViewVisible = true
        let nextStep = AuthenticationFlowStep.sendLoginCode(phoneNumber: phoneNumber, isResend: isResend)
        stateController.transition(to: nextStep)
        unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
    }

    /// Requests a phone login for the specified credentials.
    private func requestPhoneLogin(with credentials: ZMPhoneCredentials) {
        presenter?.isLoadingViewVisible = true
        stateController.transition(to: .authenticatePhoneCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    // MARK: - Generic Verification

    /// Resends the verification code to the user, if allowed by the current state.
    private func resendVerificationCode() {
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

    private func continueFlow(withVerificationCode code: String) {
        switch stateController.currentStep {
        case .enterLoginCode(let phoneNumber):
            let credentials = ZMPhoneCredentials(phoneNumber: phoneNumber, verificationCode: code)
            requestPhoneLogin(with: credentials)
        case .enterActivationCode(let unverifiedCredentials, let user):
            activateCredentials(credentials: unverifiedCredentials, user: user, code: code)
        default:
            log.error("Cannot continue flow with user code in the current state (\(stateController.currentStep)")
        }
    }

    // MARK: - Add Email And Password

    /// Sets th e-mail and password credentials for the current user.
     private func setEmailCredentialsForCurrentUser(_ credentials: ZMEmailCredentials) {
        guard case .addEmailAndPassword = stateController.currentStep else {
            log.error("Cannot save e-mail and password outside of designated step.")
            return
        }

        guard let profile = statusProvider.selfUserProfile else {
            log.error("Cannot save e-mail and password outside of designated step.")
            return
        }

        stateController.transition(to: .registerEmailCredentials(credentials, isResend: false))
        presenter?.isLoadingViewVisible = true

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

    // MARK: - Company Login

    var canStartCompanyLogin: Bool {
        switch stateController.currentStep {
        case .landingScreen, .provideCredentials, .createCredentials, .reauthenticate, .teamCreation(.setTeamName):
            return true
        default:
            log.warn("Cannot start company login in step: \(stateController.currentStep)")
            return false
        }
    }

    /// Manually start the company login flow.
    private func startCompanyLoginFlowIfPossible(linkCode: UUID?) {
        if let linkCode = linkCode {
            companyLoginController?.attemptLoginWithSSOCode(linkCode)
        } else {
            companyLoginController?.displayCompanyLoginPrompt()
        }
    }

    /// Automatically start the SSO flow if possible
    private func startAutomaticSSOFlow() {
        companyLoginController?.startAutomaticSSOFlow()
    }

    /// Call this method when the corrdinated view controller appears, to detect the sso code and display it if needed.
    func detectSSOCodeIfPossible() {
        if canStartCompanyLogin {
            companyLoginController?.isAutoDetectionEnabled = true
            companyLoginController?.detectSSOCode()
        } else {
            companyLoginController?.isAutoDetectionEnabled = false
        }
    }

    /// Call this method when company login fails or is cancelled by the user.
    func cancelCompanyLogin() {
        guard case .companyLogin = stateController.currentStep else {
            log.error("Cannot cancel company login outside of the dedicated flow.")
            return
        }

        stateController.unwindState()
    }

    // MARK: - User Input

    /**
     * Advances the team creation state with the user input.
     * - parameter value: The value provided by the user.
     */

    private func advanceTeamCreation(value: String) {
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
                    presenter.isLoadingViewVisible = true
                    self.registrationStatus.sendActivationCode(to: .email(emailAddress))
                } else {
                    presenter.isLoadingViewVisible = false
                    self.stateController.unwindState()
                }
            }

        case let .verifyActivationCode(_, emailAddress, activationCode):
            presenter?.isLoadingViewVisible = true
            registrationStatus.checkActivationCode(credentials: .email(emailAddress), code: activationCode)

        case .provideMarketingConsent:
            presenter?.isLoadingViewVisible = false
            let marketingConsentAlertModel = AuthenticationCoordinatorAlert.makeMarketingConsentAlert()
            presentAlert(for: marketingConsentAlertModel)

        case let .createTeam(teamName, email, activationCode, _, fullName, password):
            presenter?.isLoadingViewVisible = true
            let unregisteredTeam = UnregisteredTeam(teamName: teamName, email: email, emailCode: activationCode, fullName: fullName, password: password, accentColor: UIColor.indexedAccentColor())
            registrationStatus.create(team: unregisteredTeam)

        default:
            break
        }

    }

    /// Resend the team activation code.
    private func resendTeamEmailCode() {
        guard case let .teamCreation(teamState) = stateController.currentStep else {
            return
        }

        guard case let .verifyEmail(teamName, emailAddress) = teamState else {
            return
        }

        presenter?.isLoadingViewVisible = true
        let nextTeamState: TeamCreationState = .sendEmailCode(teamName: teamName, email: emailAddress, isResend: true)
        stateController.transition(to: .teamCreation(nextTeamState))

        registrationStatus.sendActivationCode(to: .email(emailAddress))
    }

}
