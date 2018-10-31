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

        // TODO: Reply

        // Content
        addContent(in: section, for: message, context: context)

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
                                   context: ConversationMessageContext) {

        if message.isKnock {
            addPing(in: section, for: message)
        } else if message.isText {
            addTextMessageAndAttachments(in: section, for: message)
        } else if message.isLocation {
            addLocationMessage(in: section, for: message)
        } else if message.isSystem {
            addSystemMessage(in: section, for: message)
        } else {
            section.add(description: UnknownMessageCellDescription())
        }
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
        case .connectionRequest, .connectionUpdate:
            break // Deprecated

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
            let senderCell = ConversationSenderMessageCellDescription(sender: sender, message: message)
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

        case .decryptionFailed:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, remoteIdentityChanged: false)
            section.add(description: decryptionCell)

        case .decryptionFailed_RemoteIdentityChanged:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, remoteIdentityChanged: true)
            section.add(description: decryptionCell)

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

        guard !message.isObfuscated else {
            return
        }

        // Link Attachment
        if let attachment = lastKnownLinkAttachment, attachment.type != .none {
            switch attachment.type {
            case .youtubeVideo:
                let youtubeCell = ConversationYouTubeAttachmentCellDescription(attachment: attachment)
                section.add(description: youtubeCell)
            case .soundcloudTrack:
                let trackCell = ConversationSoundCloudCellDescription<AudioTrackViewController>(message: message, attachment: attachment)
                section.add(description: trackCell)
            case .soundcloudSet:
                let playlistCell = ConversationSoundCloudCellDescription<AudioPlaylistViewController>(message: message, attachment: attachment)
                section.add(description: playlistCell)
            default:
                break
            }
        }

        // Link Preview
        if textMessageData.linkPreview != nil {
           let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(message: message, data: textMessageData)
            section.add(description: linkPreviewCell)
        }
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
