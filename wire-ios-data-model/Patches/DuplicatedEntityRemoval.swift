//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "DuplicateEntity")

enum DuplicatedEntityRemoval {
    
    static func removeDuplicated(in moc: NSManagedObjectContext) {
        // will skip this during test unless on disk
        guard moc.persistentStoreCoordinator!.persistentStores.first!.type != NSInMemoryStoreType else { return }
        deleteDuplicatedClients(in: moc)
        moc.saveOrRollback()
    }
    
    static func deleteDuplicatedClients(in context: NSManagedObjectContext) {
        // Fetch clients having the same remote identifiers
        context.findDuplicated(by: #keyPath(UserClient.remoteIdentifier)).forEach { (remoteId: String?, clients: [UserClient]) in
            // Group clients having the same remote identifiers by user
            clients.filter { !($0.user?.isSelfUser ?? true) }.group(by: ZMUserClientUserKey).forEach { (user: ZMUser, clients: [UserClient]) in
                UserClient.merge(clients)
            }
        }
    }

}

extension UserClient {

    static func merge(_ clients: [UserClient]) {
        guard let firstClient = clients.first, let context = firstClient.managedObjectContext, clients.count > 1 else {
            return
        }
        let tail = clients.dropFirst()
        // Merge clients having the same remote identifier and same user

        tail.forEach {
            firstClient.merge(with: $0)
            context.delete($0)
        }
    }

    // Migration method for merging two duplicated @c UserClient entities
    func merge(with client: UserClient) {
        precondition(!(self.user?.isSelfUser ?? false), "Cannot merge self user's clients")
        precondition(client.remoteIdentifier == self.remoteIdentifier, "UserClient's remoteIdentifier should be equal to merge")
        precondition(client.user == self.user, "UserClient's Users should be equal to merge")
        
        let addedOrRemovedInSystemMessages = client.addedOrRemovedInSystemMessages
        let ignoredByClients = client.ignoredByClients
        let messagesMissingRecipient = client.messagesMissingRecipient
        let trustedByClients = client.trustedByClients
        
        self.addedOrRemovedInSystemMessages.formUnion(addedOrRemovedInSystemMessages)
        self.ignoredByClients.formUnion(ignoredByClients)
        self.messagesMissingRecipient.formUnion(messagesMissingRecipient)
        self.trustedByClients.formUnion(trustedByClients)
        
        if let missedByClient = client.missedByClient {
            self.missedByClient = missedByClient
        }
    }
}

extension ZMManagedObject {
    
    /// Returns the first of two objects that is not null. If both are
    /// not null, deletes the second one
    fileprivate static func firstNonNullAndDeleteSecond<Object: ZMManagedObject>(
        _ obj1: Object?,
        _ obj2: Object?) -> Object?
    {
        if let obj1 = obj1 {
            if let obj2 = obj2 {
                obj2.managedObjectContext?.delete(obj2)
            }
            return obj1
        }
        return obj2
    }
}
