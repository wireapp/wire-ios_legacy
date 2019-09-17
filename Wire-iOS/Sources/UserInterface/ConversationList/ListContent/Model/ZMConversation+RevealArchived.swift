
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

extension ZMConversation {
    @objc
    func revealClearedOrArchived(completionHandler: Completion?) -> Bool {
        var containedInOtherLists = false

        guard let userSession = ZMUserSession.shared() else { return containedInOtherLists }

        if ZMConversationList.archivedConversations(inUserSession: userSession).contains(self) {
            // Check if it's archived, this would mean that the archive is closed but we want to unarchive
            // and select the item
            containedInOtherLists = true
            userSession.enqueueChanges({
                self.isArchived = false
            }, completionHandler: completionHandler)
        } else if ZMConversationList.clearedConversations(inUserSession: userSession).contains(self) {
            containedInOtherLists = true
            userSession.enqueueChanges({
                self.revealClearedConversation()
            }, completionHandler: completionHandler)
        }

        return containedInOtherLists
    }
}
