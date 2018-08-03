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

class AuthenticationCoordinator: NSObject, PreLoginAuthenticationObserver, PostLoginAuthenticationObserver, ZMInitialSyncCompletionObserver {

    weak var presenter: NavigationController?
    weak var delegate: AuthenticationCoordinatorDelegate?

    private var currentStep: AuthenticationFlowStep?

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

    func push(step: AuthenticationFlowStep) {
        currentStep = step
        currentStep?.activeCoordinator = self

        let viewController = step.makeViewController()
        presenter?.pushViewController(viewController, animated: true)
    }

    func requestLogin(with credentials: ZMCredentials) {
        presenter?.showLoadingView = true
        session.login(with: credentials)
    }

    // MARK: - Events

    func authenticationDidFail(_ error: NSError) {
        presenter?.showLoadingView = false

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

}
