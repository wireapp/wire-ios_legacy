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

extension ZMClientMessage: ZMTextMessageData {

    @NSManaged public var quote: ZMMessage?

    public var quoteMessage: ZMConversationMessage? {
        return quote
    }

    public override var textMessageData: ZMTextMessageData? {
        guard underlyingMessage?.textData != nil else {
            return nil
        }
        return self
    }

    public var isQuotingSelf: Bool {
        return quote?.sender?.isSelfUser ?? false
    }

    public var hasQuote: Bool {
        return underlyingMessage?.textData?.hasQuote ?? false
    }

    public var messageText: String? {
        return underlyingMessage?.textData?.content.removingExtremeCombiningCharacters
    }

    public var mentions: [Mention] {
        return Mention.mentions(from: underlyingMessage?.textData?.mentions, messageText: messageText, moc: managedObjectContext)
    }

    public func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        guard let nonce = nonce, isEditableMessage else { return }

        // Quotes are ignored in edits but keep it to mark that the message has quote for us locally
        let editedText = Text(content: text, mentions: mentions, linkPreviews: [], replyingTo: self.quote as? ZMOTRMessage)
        let editNonce = UUID()
        let content = MessageEdit(replacingMessageID: nonce, text: editedText)
        let updatedMessage = GenericMessage(content: content, nonce: editNonce)

        do {
            try setUnderlyingMessage(updatedMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to edit text message. Reason: \(error.localizedDescription)")
            return
        }

        updateNormalizedText()

        self.nonce = editNonce
        self.updatedTimestamp = Date()
        self.reactions.removeAll()
        self.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        self.linkAttachments = nil
        self.delivered = false
    }

}
