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

extension ContactsViewController {
    func actionButtonHidden() -> Bool {
        return false
    }
}

extension ContactsViewController: ContactsDataSourceDelegate {

    func dataSource(_ dataSource: ContactsDataSource,
                           cellFor user: UserType,
                           at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactsViewControllerCellID, for: indexPath) as? ContactsCell else {
            fatal("Cannot create cell")
        }
        cell.contentBackgroundColor = .clear
        cell.colorSchemeVariant = .dark

        cell.user = user

        cell.actionButtonHandler = {[weak self, weak cell] user in
            guard let `self` = self,
                let cell = cell,
                let user = user else { return }

            self.invite(user: user, from: cell.actionButton)
            cell.actionButton.isHidden = self.actionButtonHidden()
        }

        cell.actionButton.isHidden = actionButtonHidden()

        if !cell.actionButton.isHidden {
            let index: Int
            // TODO: Add this to UserType
            let isIgnored = (user as? ZMSearchUser)?.user?.isIgnored ?? false
            if user.isConnected || user.isPendingApproval && isIgnored {
                index = 0
            } else if !isIgnored && !user.isPendingApprovalByOtherUser {
                index = 2
            } else {
                index = 1
            }

            // This is dangerous
            let titleString = actionButtonTitles[Int(index)]

            cell.allActionButtonTitles = actionButtonTitles
            cell.actionButton.setTitle(titleString, for: .normal)
        }

        return cell
    }

    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType]) {
        searchResultsReceived = true
        tableView.reloadData()
        updateEmptyResults()
    }

    func dataSource(_ dataSource: ContactsDataSource, didSelect user: UserType) {
        searchHeaderViewController.tokenField.addToken(Token(title: user.displayName, representedObject: user))
        reloadVisibleRows()
    }

    func dataSource(_ dataSource: ContactsDataSource, didDeselect user: UserType) {
        if let token = searchHeaderViewController.tokenField.token(forRepresentedObject: user) {
            searchHeaderViewController.tokenField.removeToken(token)
        }

        reloadVisibleRows()
    }

    private func reloadVisibleRows() {
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }

        UIView.performWithoutAnimation {
            tableView.reloadRows(at: visibleRows, with: .none)
        }
    }
}
