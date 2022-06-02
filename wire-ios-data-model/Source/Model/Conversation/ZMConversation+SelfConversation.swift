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

extension ZMConversation {

    public enum UpdateSelfConversationError: Error {

        case invalidConversation
        case missingLastReadTimestamp
        case missingClearedTimestamp

    }

    /// Append a `LastRead` message derived from a given conversation to the self conversation.
    ///
    /// - Parameters:
    ///     - conversation: The conversation from which the last read message is derived.
    ///
    /// - Throws:
    ///     - `UpdateSelfConversationError` if last read can't or shouldn't be derived from `conversation`.
    ///     - `AppendMessageError` if the last read message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public static func updateSelfConversation(withLastReadOf conversation: ZMConversation) throws -> ZMClientMessage {
        guard let lastReadTimeStamp = conversation.lastReadServerTimeStamp else {
            throw UpdateSelfConversationError.missingLastReadTimestamp
        }

        guard
            let moc = conversation.managedObjectContext,
            let convID = conversation.remoteIdentifier,
            convID != ZMConversation.selfConversationIdentifier(in: moc)
        else {
            throw UpdateSelfConversationError.invalidConversation
        }

        let lastRead = LastRead(conversationID: convID, lastReadTimestamp: lastReadTimeStamp)
        let message = GenericMessage(content: lastRead, nonce: .init())
        return try appendMessageToSelfConversation(message, in: moc)
    }

    /// Append a `Cleared` message derived from a given conversation to the self conversation.
    ///
    /// - Parameters:
    ///     - conversation: The conversation from which the cleared message is derived.
    ///
    /// - Throws:
    ///     - `UpdateSelfConversationError` if cleared message can't or shouldn't be derived from `conversation`.
    ///     - `AppendMessageError` if the cleared message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public static func updateSelfConversation(withClearedOf conversation: ZMConversation) throws -> ZMClientMessage {
        guard let clearedTimestamp = conversation.clearedTimeStamp else {
            throw UpdateSelfConversationError.missingClearedTimestamp
        }

        guard
            let moc = conversation.managedObjectContext,
            let convId = conversation.remoteIdentifier,
            convId != ZMConversation.selfConversationIdentifier(in: moc)
        else {
            throw UpdateSelfConversationError.invalidConversation
        }

        let cleared = Cleared(timestamp: clearedTimestamp, conversationID: convId)
        let message = GenericMessage(content: cleared, nonce: UUID())
        return try appendMessageToSelfConversation(message, in: moc)
    }

    /// Append a generic message to the self conversation.
    ///
    /// - Parameters:
    ///     - message: The generic message to append.
    ///     - moc: The managed object context in which the self conversatino should be fetched.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    public static func appendMessageToSelfConversation(_ message: GenericMessage, in moc: NSManagedObjectContext) throws -> ZMClientMessage {
        let selfConversation = ZMConversation.selfConversation(in: moc)
        return try selfConversation.appendClientMessage(with: message, expires: false, hidden: false)
    }

    static func updateConversation(withLastReadFromSelfConversation lastRead: LastRead, inContext moc: NSManagedObjectContext) {
        let newTimeStamp = Double(integerLiteral: lastRead.lastReadTimestamp)
        let timestamp = Date(timeIntervalSince1970: newTimeStamp/1000)
        guard let conversationID = UUID(uuidString: lastRead.conversationID) else {
            return
        }
        let conversation = ZMConversation.fetchOrCreate(with: conversationID, domain: lastRead.qualifiedConversationID.domain, in: moc)
        conversation.updateLastRead(timestamp, synchronize: false)
    }

    static func updateConversation(withClearedFromSelfConversation cleared: Cleared, inContext moc: NSManagedObjectContext) {
        let newTimeStamp = Double(integerLiteral: cleared.clearedTimestamp)
        let timestamp = Date(timeIntervalSince1970: newTimeStamp/1000)
        guard let conversationID = UUID(uuidString: cleared.conversationID) else {
            return
        }
        let conversation = ZMConversation.fetchOrCreate(with: conversationID, domain: cleared.qualifiedConversationID.domain, in: moc)
        conversation.updateCleared(timestamp, synchronize: false)

    }

}
