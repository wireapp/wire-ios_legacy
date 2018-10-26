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

struct ConversationMessageContext {
    let isSameSenderAsPrevious: Bool
    let isLastMessageSentBySelfUser: Bool
    let isTimeIntervalSinceLastMessageSignificant: Bool
    let isFirstMessageOfTheDay: Bool
    let isFirstUnreadMessage: Bool
}


class ConversationMessageSectionBuilder {

    static func buildSection(for message: ZMConversationMessage, context: ConversationMessageContext) -> ConversationMessageSectionController {
        let section = ConversationMessageSectionController()

        // Burst timestamp
        addBurstTimestampIfNeeded(in: section, for: message, context: context)

        // Sender
        addSenderIfNeeded(in: section, for: message, context: context)

        // TODO: Reply

        // Content
        addContent(in: section, for: message, context: context)

        return section
    }

    private static func addBurstTimestampIfNeeded(in section: ConversationMessageSectionController,
                                                  for message: ZMConversationMessage,
                                                  context: ConversationMessageContext) {

        guard context.isTimeIntervalSinceLastMessageSignificant else {
            return
        }

        let timestampCell = BurstTimestampSenderMessageCellDescription(message: message, context: context)
        section.add(description: timestampCell)
    }

    private static func addSenderIfNeeded(in section: ConversationMessageSectionController,
                                          for message: ZMConversationMessage,
                                          context: ConversationMessageContext) {

        guard !context.isSameSenderAsPrevious, let sender = message.sender else {
            return
        }

        guard !message.isKnock, !message.isSystem else {
            return
        }

        let senderCell = ConversationSenderMessageCellDescription(sender: sender, showTrash: false)
        section.add(description: senderCell)
    }

    private static func addContent(in section: ConversationMessageSectionController,
                                   for message: ZMConversationMessage,
                                   context: ConversationMessageContext) {

        if message.isKnock {
            addPing(in: section, for: message)
        } else if message.isText {
            addTextMessageAndAttachments(in: section, for: message)
        } else if message.isSystem {
            addSystemMessage(in: section, for: message)
        } else {
            section.add(description: UnknownMessageCellDescription())
        }

        //        if message.isText {
        //            return TextMessageCellDescription(message: message, context: context)
        //        } else if message.isImage {
        //            return DefaultMessageCellDescription<NewImageMessageCell>(message: message, context: context)
        //        } else if message.isVideo {
        //            return DefaultMessageCellDescription<NewVideoMessageCell>(message: message, context: context)
        //        } else if (message.isAudio) {
        //            return DefaultMessageCellDescription<NewAudioMessageCell>(message: message, context: context)
        //        } else if (message.isFile) {
        //            return DefaultMessageCellDescription<NewFileMessageCell>(message: message, context: context)

    }

    // MARK: - Content Cells

    private static func addPing(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard let sender = message.sender else {
            return
        }

        let pingCell = ConversationPingCellDescription(message: message, sender: sender)
        section.add(description: pingCell)
    }

    private static func addSystemMessage(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard let systemMessageData = message.systemMessageData, let sender = message.sender else {
            return
        }

        switch systemMessageData.systemMessageType {
        case .conversationNameChanged:
            guard let newName = systemMessageData.text else {
                fallthrough
            }

            let renamedCell = ConversationRenamedSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, newName: newName)
            section.add(description: renamedCell)

        case .missedCall:
            let missedCallCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: true)
            section.add(description: missedCallCell)

        case .performedCall:
            let callCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: false)
            section.add(description: callCell)

        case .messageDeletedForEveryone:
            let senderCell = ConversationSenderMessageCellDescription(sender: sender, showTrash: true)
            section.add(description: senderCell)

        case .messageTimerUpdate:
            guard let timer = systemMessageData.messageTimer else {
                fallthrough
            }

            let timerCell = ConversationMessageTimerCellDescription(message: message, data: systemMessageData, timer: timer, sender: sender)
            section.add(description: timerCell)

        case .conversationIsSecure:
            let shieldCell = ConversationVeritfiedSystemMessageSectionDescription()
            section.add(description: shieldCell)

        default:
            section.add(description: UnknownMessageCellDescription())
        }
    }

    private static func addTextMessageAndAttachments(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard let textMessageData = message.textMessageData else {
            return
        }

        var lastKnownLinkAttachment: LinkAttachment?
        let messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated, linkAttachment: &lastKnownLinkAttachment)

        // Text
        let textCell = ConversationTextMessageCellDescription(attributedString: messageText)
        section.add(description: textCell)

        // Link Attachment
        if let attachment = lastKnownLinkAttachment, attachment.type != .none {
            if let viewController = LinkAttachmentViewControllerFactory.sharedInstance().viewController(for: attachment, message: message) {
                let attachmentCell = ConversationLinkAttachmentCellDescription(contentViewController: viewController, linkAttachmentType: attachment.type)
                section.add(description: attachmentCell)
            }
        }

        // Link Preview
        if textMessageData.linkPreview != nil {
           let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(message: message, data: textMessageData)
            section.add(description: linkPreviewCell)
        }
    }

}
