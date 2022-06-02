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

extension Payload.ConnectionStatus {

    var internalStatus: ZMConnectionStatus {
        switch self {
        case .sent:
            return .sent
        case .accepted:
            return .accepted
        case .pending:
            return .pending
        case .blocked:
            return .blocked
        case .cancelled:
            return .cancelled
        case .ignored:
            return .ignored
        case .missingLegalholdConsent:
            return .blockedMissingLegalholdConsent
        }
    }

    init?(_ status: ZMConnectionStatus) {
        switch status {
        case .invalid:
            return nil
        case .accepted:
            self = .accepted
        case .pending:
            self = .pending
        case .ignored:
            self = .ignored
        case .blocked:
            self = .blocked
        case .sent:
            self = .sent
        case .cancelled:
            self = .cancelled
        case .blockedMissingLegalholdConsent:
            self = .missingLegalholdConsent
        @unknown default:
            return nil
        }
    }
}

extension Payload.Connection {

    func updateOrCreate(in context: NSManagedObjectContext) {
        guard let userID = to ?? qualifiedTo?.uuid else {
            Logging.eventProcessing.error("Missing to field in connection payload, aborting...")
            return
        }

        let connection = ZMConnection.fetchOrCreate(userID: userID, domain: qualifiedTo?.domain, in: context)
        update(connection, in: context)
    }

    func update(_ connection: ZMConnection, in context: NSManagedObjectContext) {
        guard
            let conversationID = conversationID ?? qualifiedConversationID?.uuid
        else {
            Logging.eventProcessing.error("Missing conversation field in connection payload, aborting...")
            return
        }

        let conversation = ZMConversation.fetchOrCreate(with: conversationID,
                                                        domain: qualifiedConversationID?.domain,
                                                        in: context)

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = self.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: connection.to, role: nil)

        connection.conversation = conversation
        connection.status = self.status.internalStatus
        connection.lastUpdateDateInGMT = self.lastUpdate
    }

}

// MARK: - Connection events

extension Payload.UserConnectionEvent {

    func process(in context: NSManagedObjectContext) {
        connection.updateOrCreate(in: context)
    }

}
