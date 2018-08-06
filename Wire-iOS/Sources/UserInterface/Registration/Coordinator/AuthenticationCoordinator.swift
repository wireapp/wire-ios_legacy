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

class AuthenticationCoordinator: NSObject, PreLoginAuthenticationObserver, PostLoginAuthenticationObserver, ZMInitialSyncCompletionObserver, CompanyLoginControllerDelegate, RegistrationViewControllerDelegate, ClientUnregisterViewControllerDelegate, SessionManagerCreatedSessionObserver {

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
    }

    // MARK: - Authentication

    func transition(to step: AuthenticationFlowStep, resetStack: Bool = false) {
        currentStep = step

        guard step.needsInterface else {
            return
        }

        guard let stepViewController = makeViewController(for: step) else {
            fatalError("Step \(step) requires user interface but the view controller could not be created.")
        }

        currentViewController = stepViewController

        if resetStack {
            presenter?.setViewControllers([stepViewController], animated: true)
        } else {
            presenter?.backButtonEnabled = step.allowsUnwind
            presenter?.pushViewController(stepViewController, animated: true)
        }
    }

    @objc(startPhoneNumberValidationWithPhoneNumber:)
    func startPhoneNumberValidation(_ phoneNumber: String) {
        presenter?.showLoadingView = true
        askVerificationCode(for: phoneNumber)
        transition(to: .verifyPhoneNumber(phoneNumber: phoneNumber, accountExists: false))
    }

    @objc func askVerificationCode(for phoneNumber: String) {
        unauthenticatedSession.requestPhoneVerificationCodeForLogin(phoneNumber: phoneNumber)
    }

    @objc(requestPhoneLoginWithCredentials:)
    func requestPhoneLogin(with credentials: ZMPhoneCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticatePhoneCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    @objc(requestEmailLoginWithCredentials:)
    func requestEmailLogin(with credentials: ZMEmailCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticateEmailCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
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
            verificationController.authenticationCoordinator = self
            verificationController.isLoggingIn = true
            return verificationController

        default:
            return nil
        }

    }

    /*

     - (void)authenticationDidFail:(NSError *)error
     {
     ZMLogDebug(@"authenticationDidFail: error.code = %li", (long)error.code);

     self.navigationController.showLoadingView = NO;

     if (error.code == ZMUserSessionNeedsToRegisterEmailToRegisterClient) {
     //        [self presentAddEmailPasswordViewController];
     }
     else if (error.code == ZMUserSessionNeedsPasswordToRegisterClient) {
     [self.navigationController popToRootViewControllerAnimated:YES];
     [self.delegate phoneSignInViewControllerNeedsPasswordFor:[[LoginCredentials alloc] initWithError:error]];
     }
     else {
     [self showAlertForError:error];
     }
     }

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

    func currentViewControllerDidDisappear() {
        companyLoginController?.isAutoDetectionEnabled = false
    }

    // MARK: - Events

    func unwind() {
        // [self presentViewController:[[CheckmarkViewController alloc] init] animated:YES completion:nil];
        //     if (error.code != ZMUserSessionCodeRequestIsAlreadyPending) {
//        [self showAlertForError:error];
//    }
//    else {
//    if (! [self.navigationController.topViewController.registrationFormUnwrappedController isKindOfClass:[PhoneVerificationStepViewController class]]) {
//    [self proceedToCodeVerification];
//    } else {
//    [self showAlertForError:error];
//    }
//    }

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

    func completeBackupStep() {
        unauthenticatedSession.continueAfterBackupImportStep()
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
        presenter?.showLoadingView = false

        switch error.userSessionErrorCode {
        case .canNotRegisterMoreClients:
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
            fatalError("unimplemented")

        case .needsPasswordToRegisterClient:
            let numberOfAccounts = delegate?.authenticationCoordinatorRequestedNumberOfAccounts() ?? 0
            transition(to: .reauthenticate(error: error, numberOfAccounts: numberOfAccounts), resetStack: true)

        default:
            fatalError("Unhandled error: \(error)")
        }
    }

    func accountDeleted(accountId: UUID) {
        // no-op
    }

    // MARK: - Slow Sync

    func initialSyncCompleted() {
        guard !hasAutomationFastLoginCredentials else {
            delegate?.userAuthenticationDidComplete(registered: false)
            return
        }

        let registered = delegate?.authenticatedUserWasRegisteredOnThisDevice() ?? false
        let needsEmail = delegate?.authenticatedUserNeedsEmailCredentials() ?? false

        guard registered && needsEmail else {
            delegate?.userAuthenticationDidComplete(registered: registered)
            return
        }

        guard !hasPushedPostRegistrationStep else {
            return
        }

        hasPushedPostRegistrationStep = true
        presenter?.logoEnabled = false
        presenter?.backButtonEnabled = false

        let addEmailPasswordViewController = AddEmailPasswordViewController()
        addEmailPasswordViewController.skipButtonType = .none
        presenter?.pushViewController(addEmailPasswordViewController, animated: true)

    }

    // MARK: - Helpers

    private var hasAutomationFastLoginCredentials: Bool {
        return AutomationHelper.sharedHelper.automationEmailCredentials != nil
    }

    // MARK: --

    func startAuthentication(with error: NSError?, numberOfAccounts: Int) {
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

    // MARK: - CompanyLoginControllerDelegate

    func controller(_ controller: CompanyLoginController, presentAlert alert: UIAlertController) {
        presenter?.present(alert, animated: true)
    }

    func controller(_ controller: CompanyLoginController, showLoadingView: Bool) {
        presenter?.showLoadingView = showLoadingView
    }

    func registrationViewControllerDidSignIn() {
        delegate?.userAuthenticationDidComplete(registered: false)
    }

    func registrationViewControllerDidCompleteRegistration() {
        delegate?.userAuthenticationDidComplete(registered: true)
    }

}

extension AuthenticationCoordinator: LandingViewControllerDelegate {

    func landingViewControllerDidChooseLogin() {
        self.transition(to: .provideCredentials)
    }

    func landingViewControllerDidChooseCreateAccount() {
        // no-op
    }

    func landingViewControllerDidChooseCreateTeam() {
        // no-op
    }

    func landingViewControllerNeedsToPresentNoHistoryFlow(with context: Wire.ContextType) {
        // no-op
    }

//    func landingViewControllerDidChooseCreateTeam() {
//        flowController.startFlow()
//    }
//
//    func landingViewControllerDidChooseCreateAccount() {
//        if let navigationController = self.visibleViewController as? NavigationController {
//            let registrationViewController = RegistrationViewController(authenticationFlow: .onlyRegistration)
//            registrationViewController.delegate = appStateController
//            registrationViewController.shouldHideCancelButton = true
//            navigationController.pushViewController(registrationViewController, animated: true)
//        }
//    }
//
//    func landingViewControllerNeedsToPresentNoHistoryFlow(with context: ContextType) {
//        if let navigationController = self.visibleViewController as? NavigationController {
//            let registrationViewController = RegistrationViewController(authenticationFlow: .regular)
//            registrationViewController.delegate = appStateController
//            registrationViewController.shouldHideCancelButton = true
//            registrationViewController.loadViewIfNeeded()
//            registrationViewController.presentNoHistoryViewController(context, animated: false)
//            navigationController.pushViewController(registrationViewController, animated: true)
//        }
//    }

}
