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

import UIKit

extension UIViewController {
    func add(_ child: UIViewController) {
        self.add(child, to: view)
    }
    
    func add(_ child: UIViewController, to view: UIView, pinToSuperview: Bool = true) {
        child.willMove(toParent: self)
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
        if pinToSuperview {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            child.view.pin(to: view)
        }
    }

    func removeChild(_ viewController: UIViewController?) {
        viewController?.willMove(toParent: nil)
        viewController?.view.removeFromSuperview()
        viewController?.removeFromParent()
    }

    func childViewController<T: UIViewController>(with type: T.Type) -> T? {
        return children.compactMap { $0 as? T }.first
            ?? children.compactMap { $0.childViewController(with: type).flatMap { $0 } }.first
    }
}
