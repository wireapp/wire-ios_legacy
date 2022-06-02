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

import UIKit

extension AuthenticationCoordinator: UINavigationControllerDelegate {

    /**
     * Called when the navigation stack changes.
     *
     * There are three scenarios where this method can be called: pushing, popping and setting view controllers.
     *
     * When a new view controller is **pushed** or the stack is set, the state has already been updated, and the `currentViewController`
     * is equal to the view controller being pushed. We don't need to change the state.
     *
     * When the current view controller is **popped**, the state hasn't been updated (because it comes from user interaction),
     * so we need to unwind the state and update the current view controller to the one that is currently visible. In this case,
     * the view controller passed by the navigation controller is not equal to the `currentViewController`.
     */

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        defer {
            detectSSOCodeIfPossible()
        }

        // Detect if we are popping the durrent view controller

        guard
            let currentViewController = self.currentViewController,
            let authenticationViewController = viewController as? AuthenticationStepViewController else {
            return
        }

        // If we are popping, the new view controller won't be equal to the current view controller
        guard authenticationViewController.isEqual(currentViewController) == false else {
            return
        }

        self.currentViewController = authenticationViewController
        stateController.unwindState()
    }

}
