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

final class MigrateSenderClient {
    
    
    /// Populate senderClientID for `.decryptionFailed` system messages.
    ///
    /// For `.decryptionFailed` system messages we need to copy the `remoteIdentifier` of
    /// the user client in the `clients` property into `senderClientID` in order identify
    /// which session we should reset when initiated directly from the decryption error.
    static func migrateSenderClientID(in moc: NSManagedObjectContext) {
        let request = NSFetchRequest<ZMSystemMessage>(entityName: ZMSystemMessage.entityName())
        request.predicate = NSPredicate(format: "%K = %d", ZMMessageSystemMessageTypeKey, ZMSystemMessageType.decryptionFailed.rawValue)
        
        let systemMessages = moc.fetchOrAssert(request: request)

        for systemMessage in systemMessages {
            let userClient = systemMessage.clients.first as? UserClient
            systemMessage.senderClientID = userClient?.remoteIdentifier
        }
    }
}
