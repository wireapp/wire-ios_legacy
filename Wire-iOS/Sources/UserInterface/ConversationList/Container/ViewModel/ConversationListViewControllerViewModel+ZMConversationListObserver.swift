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

extension ConversationListViewController.ViewModel: ZMConversationListObserver {
    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateNoConversationVisibility()
        updateArchiveButtonVisibility()
    }
}

extension ConversationListViewController.ViewModel {
    func updateNoConversationVisibility(animated: Bool = true) {
        if !ZMConversationList.hasConversations {
            viewController?.showNoContactLabel(animated: animated)
        } else {
            viewController?.hideNoContactLabel(animated: animated)
        }
    }

    func updateObserverTokensForActiveTeam() {
        if let userSession = ZMUserSession.shared() {
            allConversationsObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversationsIncludingArchived(inUserSession: userSession), userSession: userSession)
            
            connectionRequestsObserverToken = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: userSession), userSession: userSession)
        }
    }

    func updateArchiveButtonVisibility() {
        viewController?.updateArchiveButtonVisibilityIfNeeded(showArchived: ZMConversationList.hasArchivedConversations)
    }

    var hasArchivedConversations: Bool {
        return conversationListType.hasArchivedConversations
    }
}
