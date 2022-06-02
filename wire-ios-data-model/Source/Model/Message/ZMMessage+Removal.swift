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

private let zmLog = ZMSLog(tag: "ZMMessage")

extension ZMMessage {

    func removePendingDeliveryReceipts() {
        // Pending receipt can exist only in new inserted messages since it is deleted locally after it is sent to the backend
        guard let predicate = ZMClientMessage.predicateForObjectsThatNeedToBeInsertedUpstream() else {
            return
        }

        let requestForInsertedMessages = ZMClientMessage.sortedFetchRequest(with: predicate)

        let possibleMatches = self.managedObjectContext?.executeFetchRequestOrAssert(requestForInsertedMessages) as? [ZMClientMessage]
        let confirmationReceipts = possibleMatches?.filter { candidateConfirmationReceipt in
            guard let genericMessage = candidateConfirmationReceipt.underlyingMessage else {
                return false
            }
            if genericMessage.hasConfirmation &&
                genericMessage.confirmation.hasFirstMessageID &&
                genericMessage.confirmation.firstMessageID == self.nonce?.transportString() {
                return true
            }
            return false
        }
        // TODO: Re-enable
        //            NSAssert(confirmationReceipts.count <= 1, @"More than one confirmation receipt");

        confirmationReceipts?.map { $0 as ZMClientMessage }.forEach {
            $0.managedObjectContext?.delete($0)
        }
    }

    static func remove(remotelyHiddenMessage hiddenMessage: MessageHide, inContext moc: NSManagedObjectContext) {
        guard
            let conversationID = UUID(uuidString: hiddenMessage.conversationID),
            let messageID = UUID(uuidString: hiddenMessage.messageID),
            let conversation = ZMConversation.fetch(with: conversationID, in: moc),
            let message = ZMMessage.fetch(withNonce: messageID, for: conversation, in: moc)
        else {
            return
        }

        // To avoid reinserting when receiving an edit we delete the message locally
        message.removeClearingSender(true)
        moc.delete(message)
    }

    static func remove(remotelyDeletedMessage deletedMessage: MessageDelete,
                       inConversation conversation: ZMConversation,
                       senderID: UUID,
                       inContext moc: NSManagedObjectContext) {
        guard
            let messageID = UUID(uuidString: deletedMessage.messageID),
            let message = ZMMessage.fetch(withNonce: messageID, for: conversation, in: moc)
        else {
            return
        }

        // We need to cascade delete the pending delivery confirmation messages for the message being deleted
        message.removePendingDeliveryReceipts()

        guard !message.hasBeenDeleted else {
            zmLog.error("Attempt to delete the deleted message: \(deletedMessage), existing: \(message)")
            return
        }

        // Only the sender of the original message can delete it
        if senderID != message.sender?.remoteIdentifier && !message.isEphemeral {
            return
        }

        let selfUser = ZMUser.selfUser(in: moc)

        // Only clients other than self should see the system message
        if senderID != selfUser.remoteIdentifier && !message.isEphemeral, let sender = message.sender {
            let timestamp = message.serverTimestamp ?? Date()
            conversation.appendDeletedForEveryoneSystemMessage(at: timestamp, sender: sender)
        }

        // If we receive a delete for an ephemeral message that was not originally sent by the selfUser, we need to stop the deletion timer
        if message.isEphemeral && message.sender?.remoteIdentifier != selfUser.remoteIdentifier {
            message.removeClearingSender(true)
            stopDeletionTimer(for: message)
        } else {
            message.removeClearingSender(true)
            message.updateCategoryCache()
        }

        conversation.updateTimestampsAfterDeletingMessage()
    }
}
