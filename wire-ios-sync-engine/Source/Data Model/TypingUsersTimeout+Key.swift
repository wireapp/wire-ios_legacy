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

private let log = ZMSLog(tag: "Core Data")

extension TypingUsersTimeout {

    struct Key: Hashable {

        var userObjectId: NSManagedObjectID
        var conversationObjectId: NSManagedObjectID

        init(user: ZMUser, conversation: ZMConversation) {
            // We need the ids to be permanent.
            if user.objectID.isTemporaryID || conversation.objectID.isTemporaryID {
                do {
                    try user.managedObjectContext?.obtainPermanentIDs(for: [user, conversation])
                } catch let error {
                    log.error("Failed to obtain permanent object ids: \(error.localizedDescription)")
                }
            }

            userObjectId = user.objectID
            conversationObjectId = conversation.objectID
            require(!userObjectId.isTemporaryID && !conversationObjectId.isTemporaryID)
        }
    }
}
