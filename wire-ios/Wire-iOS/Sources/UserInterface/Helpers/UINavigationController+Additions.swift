//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension UINavigationController {
    func popToPrevious(of controller: UIViewController) -> [UIViewController]? {
        if let currentIdx = viewControllers.firstIndex(of: controller) {
            let previousIdx = currentIdx - 1
            if viewControllers.count > previousIdx {
                let previousController = viewControllers[previousIdx]
                return popToViewController(previousController, animated: true)
            }
        }
        return nil
    }

    open func pushViewController(_ viewController: UIViewController,
                                 animated: Bool,
                                 completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }

    @discardableResult
    func popViewController(animated: Bool, completion: (() -> Void)?) -> UIViewController? {
        let controller = popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
        return controller
    }

    @discardableResult open func popToRootViewController(animated: Bool,
                                                         completion: (() -> Void)?) -> [UIViewController]? {
        let controllers = popToRootViewController(animated: true)
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
        return controllers
    }

}
