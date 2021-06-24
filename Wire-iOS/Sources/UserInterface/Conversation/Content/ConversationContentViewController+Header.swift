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
import WireSyncEngine

extension ConversationContentViewController {
    func updateTableViewHeaderView() {
        guard let userSession = ZMUserSession.shared(),
            (dataSource.hasOlderMessagesToLoad == false ||
              conversation.conversationType == .connection) else {
                // Don't display the conversation header if the message window doesn't include the first message and it is not a connection
            return
        }

        var headerView: UIView?

        let otherParticipant: ZMUser?
        if conversation.conversationType == .connection {
            otherParticipant = conversation.firstActiveParticipantOtherThanSelf ?? conversation.connectedUser
        } else {
            otherParticipant = conversation.firstActiveParticipantOtherThanSelf
        }

        let connectionOrOneOnOne = conversation.conversationType == .connection || conversation.conversationType == .oneOnOne

        if connectionOrOneOnOne, let otherParticipant = otherParticipant {
            connectionViewController = UserConnectionViewController(userSession: userSession, user: otherParticipant)
            headerView = connectionViewController?.view
        }

        if let headerView = headerView {
            headerView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            setConversationHeaderView(headerView)
        } else {
            tableView.tableHeaderView = nil
        }
    }

}
