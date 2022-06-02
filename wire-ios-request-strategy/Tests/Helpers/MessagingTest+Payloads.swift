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
@testable import WireRequestStrategy

extension QualifiedID {
    static func randomID() -> QualifiedID {
        return QualifiedID(uuid: UUID(), domain: "example.com")
    }
}

extension MessagingTestBase {

    func createConnectionPayload(_ connection: ZMConnection,
                                 status: ZMConnectionStatus = .accepted,
                                 lastUpdate: Date = Date()) -> Payload.Connection {
        return Payload.Connection(
            from: nil,
            to: connection.to.remoteIdentifier,
            qualifiedTo: connection.to.qualifiedID,
            conversationID: connection.conversation.remoteIdentifier,
            qualifiedConversationID: connection.conversation.qualifiedID,
            lastUpdate: lastUpdate,
            status: Payload.ConnectionStatus(status)!)
    }

    func createConnectionPayload(to qualifiedTo: QualifiedID = .randomID(),
                                 conversation qualifiedConversation: QualifiedID = .randomID()) -> Payload.Connection {
        let fromID = UUID()
        let toID = qualifiedTo.uuid
        let qualifiedTo = qualifiedTo

        return Payload.Connection(
            from: fromID,
            to: toID,
            qualifiedTo: qualifiedTo,
            conversationID: qualifiedConversation.uuid,
            qualifiedConversationID: qualifiedConversation,
            lastUpdate: Date(),
            status: .accepted)
    }

    func responseFailure(code: Int, label: Payload.ResponseFailure.Label, message: String = "", apiVersion: APIVersion) -> ZMTransportResponse {
        let responseFailure = Payload.ResponseFailure(code: code, label: label, message: message)
        let payloadData = responseFailure.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(payload: payloadString as ZMTransportData,
                                           httpStatus: code,
                                           transportSessionError: nil,
                                           apiVersion: apiVersion.rawValue)

        return response

    }

    func updateEvent(from data: Data) -> ZMUpdateEvent {
        let payload = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return ZMUpdateEvent(fromEventStreamPayload: payload! as ZMTransportData, uuid: UUID())!
    }

    func updateEvent<Event: EventData>(from data: Event,
                                       conversationID: QualifiedID? = nil,
                                       senderID: QualifiedID? = nil,
                                       timestamp: Date? = nil) -> ZMUpdateEvent {

        let event  = conversationEventPayload(from: data,
                                              conversationID: conversationID,
                                              senderID: senderID,
                                              timestamp: timestamp)

        return updateEvent(from: event.payloadData()!)
    }

    func conversationEventPayload<Event: EventData>(from data: Event,
                                                    conversationID: QualifiedID? = nil,
                                                    senderID: QualifiedID? = nil,
                                                    timestamp: Date? = nil) -> Payload.ConversationEvent<Event> {

        let event = Payload.ConversationEvent<Event>(id: conversationID?.uuid,
                                                     qualifiedID: conversationID,
                                                     from: senderID?.uuid,
                                                     qualifiedFrom: senderID,
                                                     timestamp: timestamp,
                                                     type: ZMUpdateEvent.eventTypeString(for: Event.eventType),
                                                     data: data)
        return event
    }

}
