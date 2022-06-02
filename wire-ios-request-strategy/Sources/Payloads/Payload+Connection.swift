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

extension Payload {

    enum ConnectionStatus: String, Codable, CaseIterable {
        case accepted = "accepted"
        case blocked = "blocked"
        case pending = "pending"
        case ignored = "ignored"
        case sent = "sent"
        case cancelled = "cancelled"
        case missingLegalholdConsent = "missing-legalhold-consent"
    }

    struct Connection: Codable, EventData {

        enum CodingKeys: String, CodingKey {
            case from
            case to
            case qualifiedTo = "qualified_to"
            case conversationID = "conversation"
            case qualifiedConversationID = "qualified_conversation"
            case lastUpdate = "last_update"
            case status
        }

        static var eventType: ZMUpdateEventType {
            return .userConnection
        }

        let from: UUID?
        let to: UUID?
        let qualifiedTo: QualifiedID?
        let conversationID: UUID?
        let qualifiedConversationID: QualifiedID?
        let lastUpdate: Date
        let status: ConnectionStatus

    }

    struct ConnectionUpdate: Codable {
        let status: ConnectionStatus
    }

    struct ConnectionRequest: Codable {

        enum CodingKeys: String, CodingKey {
            case userID = "user"
            case name
        }

        let userID: UUID
        let name: String
    }

    struct PaginatedLocalConnectionList: Codable, Paginatable {

        enum CodingKeys: String, CodingKey {
            case connections
            case hasMore = "has_more"
        }

        var nextStartReference: String? {
            return connections.last?.to?.transportString()
        }

        let connections: [Connection]
        let hasMore: Bool
    }

    struct PaginatedConnectionList: Codable, Paginatable {

        enum CodingKeys: String, CodingKey {
            case connections
            case pagingState = "paging_state"
            case hasMore = "has_more"
        }

        var nextStartReference: String? {
            return pagingState
        }

        let connections: [Connection]
        let pagingState: String
        let hasMore: Bool
    }

    struct UserConnectionEvent: Codable {
        enum CodingKeys: String, CodingKey {
            case connection
            case type
        }

        let connection: Connection
        let type: String
    }

}
