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

    func presentCreatePasscodeModule(completion: @escaping () -> Void) {
        // TODO: Build from module, when we have one.
        // TODO: Does it need to be dark?
        // TODO: Not always forced for team.
        let passcodeSetupViewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(
            variant: .dark,
            context: .forcedForTeam,
            callback: { _ in completion() })

        viewController?.present(passcodeSetupViewController, animated: true)
    }

    func presentInputPasscodeModule(onGranted: @escaping () -> Void) {
        // TODO: Clean this up.
        // TODO: Inject these arguments.
        let unlockViewController = UnlockViewController(selfUser: ZMUser.selfUser(), userSession: ZMUserSession.shared())
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: unlockViewController)
        let navigationController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
        navigationController.modalPresentationStyle = .fullScreen
        unlockViewController.onGranted = onGranted
        viewController?.present(navigationController, animated: false)
    }

    func presentWarningModule(then completion: @escaping () -> Void) {
        let warningViewController = AppLockChangeWarningViewController(isAppLockActive: true, completion: completion)
        warningViewController.modalPresentationStyle = .fullScreen
        viewController?.present(warningViewController, animated: false)
    }

}
