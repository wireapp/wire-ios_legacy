// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation
extension ContactsViewController: ShareContactsViewControllerDelegate {
    func shareDidFinish(_ viewController: UIViewController) {
        // Reload data source
        dataSource.search(withQuery: "", searchDirectory: dataSource.searchDirectory)
        dismissChildViewController(viewController)
    }
    
    func shareDidSkip(_ viewController: UIViewController) {
        delegate?.contactsViewControllerDidNotShareContacts(self)
    }
}

//MARK: - ShareContacts

extension ContactsViewController {
    func dismissChildViewController(_ viewController: UIViewController?) {
        if let view = viewController?.view {
            UIView.transition(with: view, duration: 0.35, options: .transitionCrossDissolve, animations: {
                viewController?.view.alpha = 0
            }) { finished in
                viewController?.willMove(toParent: nil)
                viewController?.view.removeFromSuperview()
                viewController?.removeFromParent()
            }
        }
    }
}
