//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireCryptobox

/// This object holds information about a message draft that has not yet been sent
/// by the user but was put into the input field.
@objcMembers public final class DraftMessage: NSObject {

    /// The text of the message.
    public let text: String
    /// The mentiones contained in the text.
    public let mentions: [Mention]
    /// The quoted message, if available.
    public let quote: ZMMessage?

    public init(text: String, mentions: [Mention], quote: ZMMessage?) {
        self.text = text
        self.mentions = mentions
        self.quote = quote
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? DraftMessage else { return false }
        return (text, mentions, quote) == (other.text, other.mentions, other.quote)
    }

}

/// A serializable version of `DraftMessage` that conforms to `Codable` and
/// holds on to a `StorableMention` values instead `Mention`.
fileprivate final class StorableDraftMessage: NSObject, Codable {

    /// The text of the message to be stored.
    let text: String
    /// The mentiones contained in the text.
    let mentions: [StorableMention]
    /// The quoted message, if available.
    let quote: StorableQuote?

    init(text: String, mentions: [StorableMention], quote: StorableQuote?) {
        self.text = text
        self.mentions = mentions
        self.quote = quote
        super.init()
    }

    /// Converts this storable version into a regular `DraftMessage`.
    /// The passed in `context` is needed to fetch the user objects.
    fileprivate func draftMessage(in context: NSManagedObjectContext, for conversation: ZMConversation) -> DraftMessage {
        return .init(text: text,
                     mentions: mentions.compactMap { $0.mention(in: context) },
                     quote: quote?.quote(in: context, for: conversation))
    }
}

/// A serializable version of `Mention` that conforms to `Codable` and
/// stores a user identifier instead of a whole `UserType` value.
private struct StorableMention: Codable {

    /// The range of the mention.
    let range: NSRange
    /// The user identifier of the user being mentioned.
    let userIdentifier: UUID

    /// Converts the storable mention into a regular `Mention` object.
    /// The passed in `context` is needed to fetch the user object.
    func mention(in context: NSManagedObjectContext) -> Mention? {
        return ZMUser.fetch(with: userIdentifier, domain: nil, in: context).map(papply(Mention.init, range))
    }

}

/// A serializable version of `ZMMessage` that conforms to `Codable` and
/// stores the message identifier instead of a whole `ZMMessage` value.
private struct StorableQuote: Codable {

    /// The identifier for the message being quoted.
    let nonce: UUID?

    /// Converts the storable mention into a regular `Mention` object.
    /// The passed in `context` is needed to fetch the user object.
    func quote(in context: NSManagedObjectContext, for conversation: ZMConversation) -> ZMMessage? {
        guard let nonce = nonce else { return nil }
        return ZMMessage.fetch(withNonce: nonce, for: conversation, in: context)
    }

}

// MARK: - Conversation Accessors

@objc extension ZMConversation {

    private static let log = ZMSLog(tag: "EAR")

    /// Internal storage of the serialized `draftMessage`.
    @NSManaged var draftMessageData: Data?

    /// Nonce of the encrypted `draftMessage`, this is nil if draft is not encrypted.
    @NSManaged var draftMessageNonce: Data?

    /// The draft message of the conversation.
    public var draftMessage: DraftMessage? {
        get {
            guard
                let data = draftMessageData,
                let context = managedObjectContext,
                let decryptedData = try? decryptDataIfNeeded(data: data, in: context)
            else { return nil }
            do {
                let storable = try JSONDecoder().decode(StorableDraftMessage.self, from: decryptedData)
                return storable.draftMessage(in: context, for: self)
            } catch {
                draftMessageData = nil
                return nil
            }
        }

        set {
            if let value = newValue {
                guard
                    let encodedData = try? JSONEncoder().encode(value.storable),
                    let context = managedObjectContext
                else { return }

                do {
                    let (data, nonce) = try encryptDataIfNeeded(data: encodedData, in: context)

                    draftMessageData = data
                    draftMessageNonce = nonce
                } catch {
                    Self.log.warn("Could not encrypt draft message data: \(error.localizedDescription)")
                }
            } else {
                draftMessageData = nil
                draftMessageNonce = nil
            }
        }

    }

    @nonobjc
    private func encryptDataIfNeeded(data: Data, in moc: NSManagedObjectContext) throws -> (data: Data, nonce: Data?) {
        guard moc.encryptMessagesAtRest else { return (data, nonce: nil) }
        return try moc.encryptData(data: data)
    }

    private func decryptDataIfNeeded(data: Data, in moc: NSManagedObjectContext) throws -> Data {
        guard let nonce = draftMessageNonce else { return data }
        return try moc.decryptData(data: data, nonce: nonce)
    }

}

// MARK: - Storable Helper

fileprivate extension UserType {

    // Private helper to get the user identifier for a `UserType`.
    var userIdentifier: UUID? {
        if let user = self as? ZMUser {
            return user.remoteIdentifier
        } else if let user = self as? ServiceUser {
            return user.userIdentifier
        }

        return nil
    }

}

fileprivate extension Mention {

    /// The storable version of the object.
    var storable: StorableMention? {
        return user.userIdentifier.map {
            StorableMention(range: range, userIdentifier: $0)
        }
    }

}

fileprivate extension DraftMessage {

    /// The storable version of the object.
    var storable: StorableDraftMessage {
        return .init(text: text,
                     mentions: mentions.compactMap(\.storable),
                     quote: StorableQuote(nonce: quote?.nonce))
    }

}
