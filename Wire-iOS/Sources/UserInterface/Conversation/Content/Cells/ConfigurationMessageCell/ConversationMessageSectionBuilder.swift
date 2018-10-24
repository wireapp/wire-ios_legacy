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

        guard !message.isKnock else {
            return
        }

        let senderCell = ConversationSenderMessageCellDescription(sender: sender)
        section.add(description: senderCell)
    }

    private static func addContent(in section: ConversationMessageSectionController,
                                   for message: ZMConversationMessage,
                                   context: ConversationMessageContext) {

        if message.isKnock {
            addPing(in: section, for: message)
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

}
