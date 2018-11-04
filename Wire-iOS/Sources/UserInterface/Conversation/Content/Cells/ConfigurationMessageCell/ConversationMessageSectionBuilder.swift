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

    static func buildSection(for message: ZMConversationMessage, context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) -> ConversationMessageSectionController {
        let section = ConversationMessageSectionController()
        configure(section: section, for: message, context: context, layoutProperties: layoutProperties)
        return section
    }

    static func configure(section: ConversationMessageSectionController, for message: ZMConversationMessage, context: ConversationMessageContext, layoutProperties: ConversationCellLayoutProperties) {
        // Fallback to old type
        if addLegacyContentIfNeeded(in: section, for: message, layoutProperties: layoutProperties) {
            return
        }

        // Burst timestamp
        addBurstTimestampIfNeeded(in: section, for: message, context: context)

        // Sender
        addSenderIfNeeded(in: section, for: message, context: context)

        // Reply
        addReplyQuoteIfNeeded(in: section, for: message)

        // Content
        addContent(in: section, for: message, context: context, layoutProperties: layoutProperties)

        // Toolbox
        addToolbox(in: section, for: message)
    }

    private static func addLegacyContentIfNeeded(in section: ConversationMessageSectionController,
                                                 for message: ZMConversationMessage,
                                                 layoutProperties: ConversationCellLayoutProperties) -> Bool {

        if message.isVideo {
            let videoCell = ConversationLegacyCellDescription<VideoMessageCell>(message: message, layoutProperties: layoutProperties)
            section.add(description: videoCell)

        } else if message.isAudio {
            let audioCell = ConversationLegacyCellDescription<AudioMessageCell>(message: message, layoutProperties: layoutProperties)
            section.add(description: audioCell)

        } else if message.isFile {
            let fileCell = ConversationLegacyCellDescription<FileTransferCell>(message: message, layoutProperties: layoutProperties)
            section.add(description: fileCell)

        } else if message.isImage {
            let imageCell = ConversationLegacyCellDescription<ImageMessageCell>(message: message, layoutProperties: layoutProperties)
            section.add(description: imageCell)

        } else if message.isSystem, let systemMessageType = message.systemMessageData?.systemMessageType {
            switch systemMessageType {
            case .newClient, .usingNewDevice:
                let newClientCell = ConversationLegacyCellDescription<ConversationNewDeviceCell>(message: message, layoutProperties: layoutProperties)
                section.add(description: newClientCell)

            case .ignoredClient:
                let ignoredClientCell = ConversationLegacyCellDescription<ConversationIgnoredDeviceCell>(message: message, layoutProperties: layoutProperties)
                section.add(description: ignoredClientCell)

            case .potentialGap, .reactivatedDevice:
                let missingMessagesCell = ConversationLegacyCellDescription<MissingMessagesCell>(message: message, layoutProperties: layoutProperties)
                section.add(description: missingMessagesCell)

            case .participantsAdded, .participantsRemoved, .newConversation, .teamMemberLeave:
                let participantsCell = ConversationLegacyCellDescription<ParticipantsCell>(message: message, layoutProperties: layoutProperties)
                section.add(description: participantsCell)

            default:
                return false
            }
        } else {
            return false
        }

        return true
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

        let senderCell = ConversationSenderMessageCellDescription(sender: sender, message: message)
        section.add(description: senderCell)
    }

    private static func addContent(in section: ConversationMessageSectionController,
                                   for message: ZMConversationMessage,
                                   context: ConversationMessageContext,
                                   layoutProperties: ConversationCellLayoutProperties) {

        if message.isKnock {
            addPing(in: section, for: message)
        } else if message.isText {
            addTextMessageAndAttachments(in: section, for: message)
        } else if message.isLocation {
            addLocationMessage(in: section, for: message)
        } else if message.isSystem {
            addSystemMessage(in: section, for: message, layoutProperties: layoutProperties)
        } else {
            section.add(description: UnknownMessageCellDescription())
        }
    }

    // MARK: - Replies

    private static func addReplyQuoteIfNeeded(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard message.textMessageData?.hasQuote == true else {
            return
        }

        let quotedMessage = message.textMessageData?.quote
        let quoteCell = ConversationReplyCellDescription(quotedMessage: quotedMessage)
        section.add(description: quoteCell)
    }

    // MARK: - Content Cells

    private static func addPing(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard let sender = message.sender else {
            return
        }

        let pingCell = ConversationPingCellDescription(message: message, sender: sender)
        section.add(description: pingCell)
    }

    private static func addSystemMessage(in section: ConversationMessageSectionController, for message: ZMConversationMessage, layoutProperties: ConversationCellLayoutProperties) {
        let cells = ConversationSystemMessageCellDescription.cells(for: message, layoutProperties: layoutProperties)
        section.cellDescriptions.append(contentsOf: cells)
    }

    private static func addTextMessageAndAttachments(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        let cells = ConversationTextMessageCellDescription.cells(for: message)
        section.cellDescriptions.append(contentsOf: cells)
    }

    private static func addLocationMessage(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        guard let locationMessageData = message.locationMessageData else {
            return
        }

        let locationCell = ConversationLocationMessageCellDescription(message: message, location: locationMessageData)
        section.add(description: locationCell)
    }

    // MARK: - Toolbox

    private static func addToolbox(in section: ConversationMessageSectionController, for message: ZMConversationMessage) {
        let toolboxCell = ConversationMessageToolboxCellDescription(message: message)
        section.add(description: toolboxCell)
    }

}
