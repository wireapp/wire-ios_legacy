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

extension ContactsViewController: ContactsDataSourceDelegate {

    func actionButtonHidden(user: ZMSearchUser) -> Bool {
        if let shouldDisplayActionButtonForUser = contentDelegate?.contactsViewController?(self, shouldDisplayActionButtonFor: user) {
            return !shouldDisplayActionButtonForUser
        } else {
            return true
        }
    }

    public func dataSource(_ dataSource: ContactsDataSource, cellFor user: ZMSearchUser, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView?.dequeueReusableCell(withIdentifier: ContactsViewControllerCellID, for: indexPath) as? ContactsCell else {
            fatal("Cannot create cell")
        }
        cell.contentBackgroundColor = .clear
        cell.colorSchemeVariant = .dark

        cell.user = user

        cell.actionButtonHandler = {[weak self, weak cell] user in
            guard let `self` = self,
                let cell = cell,
                let user = user else { return }

            self.contentDelegate?.contactsViewController!(self, actionButton: cell.actionButton, pressedFor: user)

            cell.actionButton.isHidden = self.actionButtonHidden(user: user)
        }

        cell.actionButton.isHidden = actionButtonHidden(user: user)

        if !cell.actionButton.isHidden,
            let index = contentDelegate?.contactsViewController?(self, actionButtonTitleIndexFor: user),
            let actionButtonTitles = actionButtonTitles as? [String] {

                let titleString = actionButtonTitles[Int(index)]

                cell.allActionButtonTitles = actionButtonTitles
                cell.actionButton.setTitle(titleString, for: .normal)
        }

        if dataSource.selection.contains(user) {
            tableView?.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }

        return cell

    }

    
}
