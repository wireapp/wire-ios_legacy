//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMConversation {
    static func appendHideMessageToSelfConversation(_ message: ZMMessage) throws {
        guard
            let messageId = message.nonce,
            let conversation = message.conversation,
            let conversationId = conversation.remoteIdentifier
        else {
            return
        }

        let genericMessage = GenericMessage(content: MessageHide(conversationId: conversationId, messageId: messageId))
        _ = try ZMConversation.appendMessageToSelfConversation(genericMessage, in: message.managedObjectContext!)
    }
}

extension ZMMessage {

    // NOTE: This is a free function meant to be called from Obj-C because you can't call protocol extension from it
    @objc public static func hideMessage(_ message: ZMConversationMessage) {
        // when deleting ephemeral, we must delete for everyone (only self & sender will receive delete message)
        // b/c deleting locally will void the destruction timer completion.
        guard !message.isEphemeral else { deleteForEveryone(message); return }
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.hideForSelfUser()
    }

    @objc public func hideForSelfUser() {
        guard !isZombieObject else { return }

        do {
            try ZMConversation.appendHideMessageToSelfConversation(self)
        } catch {
            Logging.messageProcessing.warn("Failed to append hide message. Reason: \(error.localizedDescription)")
            return
        }

        // To avoid reinserting when receiving an edit we delete the message locally
        removeClearingSender(true)
        managedObjectContext?.delete(self)
    }

    @discardableResult @objc public static func deleteForEveryone(_ message: ZMConversationMessage) -> ZMClientMessage? {
        guard let castedMessage = message as? ZMMessage else { return nil }
        return castedMessage.deleteForEveryone()
    }

    @discardableResult @objc func deleteForEveryone() -> ZMClientMessage? {
        guard !isZombieObject, let sender = sender, (sender.isSelfUser || isEphemeral) else { return nil }
        guard let conversation = conversation, let messageNonce = nonce else { return nil}

        do {
            let genericMessage = GenericMessage(content: MessageDelete(messageId: messageNonce))
            let message = try conversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)
            removeClearingSender(false)
            updateCategoryCache()
            return message
        } catch {
            Logging.messageProcessing.warn("Failed delete message for everyone. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    @objc var isEditableMessage: Bool {
        return false
    }
}

extension ZMClientMessage {
    override var isEditableMessage: Bool {
        guard
            let genericMessage = underlyingMessage,
            let sender = sender, sender.isSelfUser,
            let content = genericMessage.content else {
                return false
        }
        switch content {
        case .edited:
            return true
        case .text:
            return !isEphemeral && isSent
        default:
            return false
        }
    }
}
