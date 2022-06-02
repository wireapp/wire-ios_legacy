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

class TypingUsersTimeout: NSObject {

    private var timeouts = [Key: Date]()

    var firstTimeout: Date? {
        return timeouts.values.min()
    }

    func add(_ user: ZMUser, for conversation: ZMConversation, withTimeout timeout: Date) {
        let key = Key(user: user, conversation: conversation)
        timeouts[key] = timeout
    }

    func remove(_ user: ZMUser, for conversation: ZMConversation) {
        let key = Key(user: user, conversation: conversation)
        timeouts.removeValue(forKey: key)
    }

    func contains(_ user: ZMUser, for conversation: ZMConversation) -> Bool {
        let key = Key(user: user, conversation: conversation)
        return timeouts[key] != nil
    }

    func userIds(in conversation: ZMConversation) -> Set<NSManagedObjectID> {
        let userIds = timeouts.keys
            .filter { $0.conversationObjectId == conversation.objectID }
            .map(\.userObjectId)

        return Set(userIds)
    }

    func pruneConversationsThatHaveTimoutBefore(date pruneDate: Date) -> Set<NSManagedObjectID> {
        let keysToRemove = timeouts
            .filter { $0.value < pruneDate }
            .keys

        keysToRemove.forEach { self.timeouts.removeValue(forKey: $0) }
        return Set(keysToRemove.map(\.conversationObjectId))
    }
}
