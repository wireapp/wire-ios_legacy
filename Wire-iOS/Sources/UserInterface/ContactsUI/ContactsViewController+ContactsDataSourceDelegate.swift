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

    func dataSource(_ dataSource: ContactsDataSource, cellFor user: UserType, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ContactsCell.self, for: indexPath)
        cell.contentBackgroundColor = .clear
        cell.colorSchemeVariant = .dark
        cell.user = user

        cell.actionButtonHandler = {[weak self, weak cell] user in
            guard
                let `self` = self,
                let user = user,
                let cell = cell
                else { return }

            self.invite(user: user, from: cell.actionButton)
        }

        if !cell.actionButton.isHidden {
            let zmUser = (user as? ZMSearchUser)?.user
            let action: ContactsCell.Action

            // TODO: Add this to UserType
            if user.isConnected || user.isPendingApproval && zmUser?.isIgnored == true {
                action = .open
            } else if zmUser?.isIgnored == false && !user.isPendingApprovalByOtherUser {
                action = .connect
            } else {
                action = .invite
            }

            cell.action = action
        }

        return cell
    }

    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType]) {
        tableView.reloadData()
        updateEmptyResults(hasResults: !newUser.isEmpty)
    }

}
