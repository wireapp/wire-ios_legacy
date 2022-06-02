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

import Foundation

@objc class TypingUsers: NSObject {

    // MARK: - Properties

    private var conversationIdToUserIds = [NSManagedObjectID: [NSManagedObjectID]]()

    // MARK: - Internal Methods

    @objc (updateTypingUsers:inConversation:)
    func update(typingUsers: Set<ZMUser>, in conversation: ZMConversation) {
        let conversationId = conversation.objectID
        require(!conversationId.isTemporaryID)

        let userIds = typingUsers.lazy.map(\.objectID)
        require(userIds.allSatisfy({ !$0.isTemporaryID }))

        guard !userIds.isEmpty else {
            conversationIdToUserIds.removeValue(forKey: conversationId)
            return
        }

        conversationIdToUserIds[conversationId] = userIds
    }

    func typingUsers(in conversation: ZMConversation) -> Set<ZMUser> {
        let conversationId = conversation.objectID

        guard
            let moc = conversation.managedObjectContext,
            !conversationId.isTemporaryID,
            let userIds = conversationIdToUserIds[conversationId]
        else {
            return Set()
        }

        let users = userIds.compactMap { moc.object(with: $0) as? ZMUser }
        return Set(users)
    }

}
