//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension AppLockModule {

    final class Router: RouterInterface {

        // MARK: - Properties

        weak var view: View!

    }

}

// MARK: - Perform action

extension AppLockModule.Router: AppLockRouterPresenterInterface {

    func performAction(_ action: AppLockModule.Action) {
        switch action {
        case let .createPasscode(shouldInform):
            presentCreatePasscodeModule(shouldInform: shouldInform)

        case .inputPasscode:
            presentInputPasscodeModule()

        case .informUserOfConfigChange:
            presentWarningModule()
        }
    }

    private func presentCreatePasscodeModule(shouldInform: Bool) {
        let passcodeSetupViewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(
            variant: .dark,
            context: shouldInform ? .forcedForTeam : .createPasscode,
            delegate: view)

        view.present(passcodeSetupViewController, animated: true)
    }

    private func presentInputPasscodeModule() {
        // TODO: [John] Clean this up.
        // TODO: [John] Inject these arguments.
        let unlockViewController = UnlockViewController(selfUser: ZMUser.selfUser(), userSession: ZMUserSession.shared())
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: unlockViewController)
        let navigationController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
        navigationController.modalPresentationStyle = .fullScreen
        unlockViewController.delegate = view
        view.present(navigationController, animated: false)
    }

    private func presentWarningModule() {
        let warningViewController = AppLockChangeWarningViewController(isAppLockActive: true)
        warningViewController.modalPresentationStyle = .fullScreen
        warningViewController.delegate = view
        view.present(warningViewController, animated: false)
    }

}
