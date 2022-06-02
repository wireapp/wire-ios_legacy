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

// MARK: - Message sending

extension Payload {
    typealias ClientListByUser = [ZMUser: ClientList]
}

extension Payload.MessageSendingStatus {

    /// Updates the reported client changes after an attempt to send the message
    ///
    /// - Parameter message: message for which the message sending status was created
    /// - Returns *True* if the message was missing clients in the original payload.
    ///
    /// If a message was missing clients we should attempt to send the message again
    /// after establishing sessions with the missing clients.
    ///
    func updateClientsChanges(for message: OTREntity) -> Bool {

        let deletedClients = deleted.fetchClients(in: message.context)
        for (_, deletedClients) in deletedClients {
            deletedClients.forEach { $0.deleteClientAndEndSession() }
        }

        let redundantUsers = redundant.fetchUsers(in: message.context)
        if !redundantUsers.isEmpty {
            // if the BE tells us that these users are not in the
            // conversation anymore, it means that we are out of sync
            // with the list of participants
            message.conversation?.needsToBeUpdatedFromBackend = true

            // The missing users might have been deleted so we need re-fetch their profiles
            // to verify if that's the case.
            redundantUsers.forEach { $0.needsToBeUpdatedFromBackend = true }

            message.detectedRedundantUsers(redundantUsers)
        }

        let missingClients = missing.fetchOrCreateClients(in: message.context)
        for (user, userClients) in missingClients {
            userClients.forEach({ $0.discoveredByMessage = message as? ZMOTRMessage })
            message.registersNewMissingClients(Set(userClients))
            message.conversation?.addParticipantAndSystemMessageIfMissing(user, date: nil)
        }

        return !missingClients.isEmpty
    }

    func missingClientListByUser(context: NSManagedObjectContext) -> Payload.ClientListByUser {

        let clientIDsByUser = missing.flatMap { (domain, clientIDsByUserID) in
            clientIDsByUserID.materializingUsers(withDomain: domain, in: context)
        }

        return Payload.ClientListByUser(clientIDsByUser, uniquingKeysWith: +)
    }

}

extension Payload.ClientListByUserID {

    func materializingUsers(withDomain domain: String?, in context: NSManagedObjectContext)  -> Payload.ClientListByUser {

        return reduce(into: Payload.ClientListByUser()) { (result, tuple: (userID: String, clientIDs: [String])) in
            guard let userID = UUID(uuidString: tuple.userID) else { return }
            let user = ZMUser.fetchOrCreate(with: userID, domain: domain, in: context)
            result[user] = tuple.clientIDs
        }
    }

}
