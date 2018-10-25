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

extension UIViewController {
    /// add a child view controller to self and add its view as view paramenter's subview
    ///
    /// - Parameters:
    ///   - viewController: the view controller to add
    ///   - view: the viewController parameter's view will be added to this view
    @objc(addViewController:toView:)
    func add(_ viewController: UIViewController?, to view: UIView) {
        guard let viewController = viewController else { return }

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    /// Add a view controller as self's child viewController and add its view as self's subview
    ///
    /// - Parameter viewController: viewController to add
    func addToSelf(_ viewController: UIViewController) {
        add(viewController, to: self.view)
    }
}

