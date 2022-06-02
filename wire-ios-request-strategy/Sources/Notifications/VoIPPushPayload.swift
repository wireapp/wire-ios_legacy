//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// The payload of a push for call events.

public struct VoIPPushPayload: Codable {

    // MARK: - Properties

    /// The id of the account that triggered this push.

    public let accountID: UUID

    /// The id of the conversation in which the call event originated.

    public let conversationID: UUID

    /// The domain of the conversation in whcih the call event originated.

    public let conversationDomain: String?

    /// The user id of the sender who triggerd the call event.

    public let senderID: UUID

    /// The user domain of the sender who triggered the call event.

    public let senderDomain: String?

    /// The client id of the sender who triggered the call event.

    public let senderClientID: String

    /// The event timestamp.

    public let timestamp: Date

    /// The age of the event since it left the server.

    public let serverTimeDelta: TimeInterval

    /// The call event data.

    public let data: Data

    // MARK: - Life cycle

    /// Create a new instance from an update event.
    ///
    /// - Parameters:
    ///     - event: An update event, expected to be for a calling message.
    ///     - accountID: The account ID that triggered the event.
    ///     - serverTimeDelta: The time since the event was fetched from the server.

    public init?(from event: ZMUpdateEvent, accountID: UUID, serverTimeDelta: TimeInterval) {
        guard
            let message = GenericMessage(from: event),
            let data = message.calling.content.data(using: .utf8, allowLossyConversion: false),
            let conversationID = event.conversationUUID,
            let senderID = event.senderUUID,
            let senderClientID = event.senderClientID,
            let timestamp = event.timestamp
        else {
            return nil
        }

        self.accountID = accountID
        self.conversationID = conversationID
        self.conversationDomain = event.conversationDomain
        self.senderID = senderID
        self.senderDomain = event.senderDomain
        self.senderClientID = senderClientID
        self.timestamp = timestamp
        self.serverTimeDelta = serverTimeDelta
        self.data = data
    }

    /// Create a new instance from a dictionary
    ///
    /// - Parameters:
    ///     - dict: A dictionary representation of the push payload.

    public init?(from dict: [String: Any]) {
        guard
            let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
            let value = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }

        self = value
    }

    // MARK: - Methods

    /// The dictionary representation of this push payload.

    public var asDictionary: [String: Any]? {
        guard
            let data = try? JSONEncoder().encode(self),
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let dict = json as? [String: Any]
        else {
            return nil
        }

        return dict
    }

}
