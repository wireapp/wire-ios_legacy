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

        weak var viewController: UIViewController?

    }

}


// MARK: - API for presenter

extension AppLockModule.Router: AppLockRouterPresenterInterface {

    func present(_ module: AppLockModule.Module, then completion: @escaping () -> Void) {
        switch module {
        case let .createPasscode(shouldInform):
            presentCreatePasscodeModule(shouldInform: shouldInform, completion: completion)

        case .inputPasscode:
            presentInputPasscodeModule(onGranted: completion)

        case .informUserOfConfigChange:
            presentWarningModule(then: completion)
        }
    }

    private func presentCreatePasscodeModule(shouldInform: Bool, completion: @escaping () -> Void) {
        let passcodeSetupViewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(
            variant: .dark,
            context: shouldInform ? .forcedForTeam : .createPasscode,
            callback: { _ in completion() })

        viewController?.present(passcodeSetupViewController, animated: true)
    }

    private func presentInputPasscodeModule(onGranted: @escaping () -> Void) {
        // TODO: [John] Clean this up.
        // TODO: [John] Inject these arguments.
        let unlockViewController = UnlockViewController(selfUser: ZMUser.selfUser(), userSession: ZMUserSession.shared())
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: unlockViewController)
        let navigationController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
        navigationController.modalPresentationStyle = .fullScreen
        unlockViewController.onGranted = onGranted
        viewController?.present(navigationController, animated: false)
    }

    private func presentWarningModule(then completion: @escaping () -> Void) {
        let warningViewController = AppLockChangeWarningViewController(isAppLockActive: true, completion: completion)
        warningViewController.modalPresentationStyle = .fullScreen
        viewController?.present(warningViewController, animated: false)
    }

}
