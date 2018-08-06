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

class AuthenticationCoordinator: NSObject, PreLoginAuthenticationObserver, PostLoginAuthenticationObserver, ZMInitialSyncCompletionObserver, CompanyLoginControllerDelegate, RegistrationViewControllerDelegate {

    weak var presenter: NavigationController?
    weak var delegate: AuthenticationCoordinatorDelegate?

    private var currentStep: AuthenticationFlowStep = .landingScreen
    private var currentViewController: AuthenticationStepViewController?
    private let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())

    // MARK: - Initialization

    private let session: UnauthenticatedSession
    private var hasPushedPostRegistrationStep: Bool = false
    private var loginObservers: [Any] = []

    init(presenter: NavigationController, session: UnauthenticatedSession) {
        self.presenter = presenter
        self.session = session
        super.init()

        loginObservers = [
            PreLoginAuthenticationNotification.register(self, for: session),
            PostLoginAuthenticationNotification.addObserver(self)
        ]
    }

    // MARK: - Authentication

    func startFlow() {
        transition(to: .landingScreen)
    }

    func transition(to step: AuthenticationFlowStep) {
        currentStep = step

        guard step.needsInterface else {
            return
        }

        guard let stepViewController = makeViewController(for: step) else {
            fatalError("Step \(step) requires user interface but the view controller could not be created.")
        }

        currentViewController = stepViewController
        presenter?.pushViewController(stepViewController, animated: true)
    }

    @objc(requestLoginWithCredentials:)
    func requestLogin(with credentials: ZMCredentials) {
        presenter?.showLoadingView = true
        transition(to: .authenticateEmailCredentials(credentials))
        session.login(with: credentials)
    }

    private func makeViewController(for step: AuthenticationFlowStep) -> AuthenticationStepViewController? {
        switch step {
        case .landingScreen:
            let controller = LandingViewController()
            controller.delegate = self
            controller.coordinator = self
            return controller

        case .provideEmailCredentials:
            let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
            loginViewController.delegate = self
            loginViewController.shouldHideCancelButton = true
            return (loginViewController as! AuthenticationStepViewController)

        default:
            return nil
        }

    }

    func currentViewControllerDidAppear() {
        switch currentStep {
        case .landingScreen:
            companyLoginController?.isAutoDetectionEnabled = true
            companyLoginController?.detectLoginCode()

        default:
            break //
        }
    }

    func currentViewControllerDidDisappear() {
        companyLoginController?.isAutoDetectionEnabled = false
    }

    // MARK: - Events

    func unwind() {

    }

    func authenticationDidFail(_ error: NSError) {
        presenter?.showLoadingView = false

        switch currentStep {
        case .authenticateEmailCredentials(let credentials):
            // Show a guidance dot if the user caused the failure
            if error.code != ZMUserSessionErrorCode.networkError.rawValue {
                currentViewController?.displayErrorFeedback(.showGuidanceDot)
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
                guard let userClientIDs = error.userInfo[ZMClientsKey] as? [NSManagedObjectID] else {
                    fallthrough
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

                let clientManagementStep = AuthenticationFlowStep.clientManagement(clients: clients, credentials: credentials)
                transition(to: clientManagementStep)

            default:
                presenter?.showAlert(forError: error, handler: errorAlertHandler)
            }

        default:
            break
        }

    }


    func authenticationDidSucceed() {
        presenter?.showLoadingView = false
    }

    func loginCodeRequestDidSucceed() {

    }

    func loginCodeRequestDidFail(_ error: NSError) {

    }

    func authenticationReadyToImportBackup(existingAccount: Bool) {
        presenter?.showLoadingView = false

        guard !self.hasAutomationFastLoginCredentials else {
            session.continueAfterBackupImportStep()
            return
        }

        let type = existingAccount ? ContextType.loggedOut : .newDevice

        guard !(self.presenter?.topViewController is NoHistoryViewController) else {
            return
        }

        let noHistoryViewController = NoHistoryViewController(contextType: type)
        self.presenter?.backButtonEnabled = false
        self.presenter?.pushViewController(noHistoryViewController, animated: true)
    }

    func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        authenticationDidFail(error)
    }

    func clientRegistrationDidSucceed(accountId: UUID) {
        
    }

    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {

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

    func startAuthentication(with error: Error?, numberOfAccounts: Int) {
        var needsToReauthenticate = false

        if let error = error {
            let errorCode = (error as NSError).userSessionErrorCode
            needsToReauthenticate = [ZMUserSessionErrorCode.clientDeletedRemotely,
                                     .accessTokenExpired,
                                     .needsPasswordToRegisterClient,
                                     .needsToRegisterEmailToRegisterClient,
                                     ].contains(errorCode)
        }

        let flowStep: AuthenticationFlowStep

        if needsToReauthenticate {
            flowStep = .reauthenticate(error: error, numberOfAccounts: numberOfAccounts)
        } else {
            flowStep = .landingScreen
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
        self.transition(to: .provideEmailCredentials)
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
//    func landingViewControllerDidChooseLogin() {
//        if let navigationController = self.visibleViewController as? NavigationController {
//            let loginViewController = RegistrationViewController(authenticationFlow: .onlyLogin)
//            loginViewController.delegate = appStateController
//            loginViewController.shouldHideCancelButton = true
//            navigationController.pushViewController(loginViewController, animated: true)
//        }
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
