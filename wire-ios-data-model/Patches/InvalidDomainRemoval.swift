//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

enum InvalidDomainRemoval {

    /// We had a situation where we were creating duplicate users and conversations where the UUID would
    /// be duplicated but the domain would be different.
    ///
    /// We need to delete all duplicated users and converations which doesn't have a domain equal to the
    /// self user domain.
    static func removeDuplicatedEntitiesWithInvalidDomain(in moc: NSManagedObjectContext) {
        guard let selfDomain = ZMUser.selfUser(in: moc).domain else {
            return
        }

        let duplicatedUsers: [Data: [ZMUser]] = moc.findDuplicated(by: ZMManagedObject.remoteIdentifierDataKey()!)

        let duplicatedConversations: [Data: [ZMConversation]] = moc.findDuplicated(by: ZMManagedObject.remoteIdentifierDataKey()!)

        duplicatedUsers.forEach { (_, users) in
            for user in users {
                if user.domain != selfDomain {
                    moc.delete(user)
                }
            }
        }

        duplicatedConversations.forEach { (_, conversations) in
            for conversation in conversations {
                if conversation.domain != selfDomain {
                    moc.delete(conversation)
                }
            }
        }
    }
}
