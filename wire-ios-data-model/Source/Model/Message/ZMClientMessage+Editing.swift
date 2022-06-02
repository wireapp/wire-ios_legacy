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

extension ZMClientMessage {
    static func editMessage(withEdit messageEdit: MessageEdit,
                            forConversation conversation: ZMConversation,
                            updateEvent: ZMUpdateEvent,
                            inContext moc: NSManagedObjectContext,
                            prefetchResult: ZMFetchRequestBatchResult) -> ZMClientMessage? {
        guard
            let editedMessageId = UUID(uuidString: messageEdit.replacingMessageID),
            let editedMessage = ZMClientMessage.fetch(withNonce: editedMessageId, for: conversation, in: moc, prefetchResult: prefetchResult),
            editedMessage.processMessageEdit(messageEdit, from: updateEvent)
        else {
            return nil
        }
        editedMessage.updateCategoryCache()
        return editedMessage
    }

    /// Apply a message edit update
    ///
    /// - parameter messageEdit: Message edit update
    /// - parameter updateEvent: Update event which delivered the message edit update
    /// - Returns: true if edit was succesfully applied

    func processMessageEdit(_ messageEdit: MessageEdit, from updateEvent: ZMUpdateEvent) -> Bool {
        guard
            let nonce = updateEvent.messageNonce,
            let senderUUID = updateEvent.senderUUID,
            let originalText = underlyingMessage?.textData,
            case .text? = messageEdit.content,
            senderUUID == sender?.remoteIdentifier
        else {
            return false
        }

        do {
            let genericMessage = GenericMessage(content: originalText.applyEdit(from: messageEdit.text), nonce: nonce)
            try setUnderlyingMessage(genericMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to process message edit. Reason: \(error.localizedDescription)")
            return false
        }

        updateNormalizedText()
        self.nonce = nonce
        updatedTimestamp = updateEvent.timestamp
        reactions.removeAll()
        linkAttachments = nil

        return true
    }

}
