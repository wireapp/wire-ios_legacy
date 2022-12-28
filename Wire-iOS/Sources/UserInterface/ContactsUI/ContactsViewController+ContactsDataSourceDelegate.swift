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
import WireDataModel
import UIKit

extension ContactsViewController: ContactsDataSourceDelegate {

    func dataSource(_ dataSource: ContactsDataSource, cellFor user: UserType, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ContactsCell.self, for: indexPath)
        cell.user = user

        cell.actionButtonHandler = { [weak self] user, action in
            switch action {
            case .open:
                self?.openConversation(for: user)
            case .invite:
                self?.invite(user: user)
            }
        }

        if !cell.actionButton.isHidden {
            cell.action = user.isConnected ? .open : .invite
        }

        return cell
    }

    func dataSource(_ dataSource: ContactsDataSource, didReceiveSearchResult newUser: [UserType]) {
        tableView.reloadData()
        updateEmptyResults(hasResults: !newUser.isEmpty)
    }

}
