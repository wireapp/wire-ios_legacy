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
import UIKit

extension UIViewController {
    /// add a child view controller to self and add its view as view paramenter's subview
    ///
    /// - Parameters:
    ///   - viewController: the view controller to add
    ///   - view: the viewController parameter's view will be added to this view
    func add(_ viewController: UIViewController?, to view: UIView) {
        guard let viewController = viewController else { return }
        viewController.willMove(toParent: self)
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    /// Add a view controller as self's child viewController and add its view as self's subview
    ///
    /// - Parameter viewController: viewController to add
    func addToSelf(_ viewController: UIViewController) {
        add(viewController, to: view)
    }

    /// remove a child view controller to self and add its view from the paramenter's view
    ///
    /// - Parameters:
    ///   - viewController: the view controller to remove
    func removeChild(_ viewController: UIViewController?) {
        viewController?.willMove(toParent: nil)
        viewController?.view.removeFromSuperview()
        viewController?.removeFromParent()
    }

    /// Return the first child of class T in the hierarchy of the children of the view controller
    ///
    /// - Parameters:
    ///   - type: type of the view controller to find
    func firstChild<T: UIViewController>(ofType type: T.Type) -> T? {
        // Check all the children first.
        for child in children {
            if let result = child as? T {
                return result
            }
        }

        // Then check next layer down.
        for child in children {
            if let result = child.firstChild(ofType: type) {
                return result
            }
        }
        return nil
    }
}

