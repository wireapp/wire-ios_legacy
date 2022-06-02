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
import WireDataModel

public enum LocalNotificationEventType {
    case connectionRequestAccepted, connectionRequestPending, newConnection, conversationCreated, conversationDeleted
}

public enum LocalNotificationContentType: Equatable {

    case text(String, isMention: Bool, isReply: Bool)
    case image
    case video
    case audio
    case location
    case fileUpload
    case knock
    case reaction(emoji: String)
    case hidden
    case ephemeral(isMention: Bool, isReply: Bool)
    case participantsRemoved(reason: ZMParticipantsRemovedReason)
    case participantsAdded
    case messageTimerUpdate(String?)

    public init?(event: ZMUpdateEvent, conversation: ZMConversation?, in moc: NSManagedObjectContext) {
        switch event.type {
        case .conversationMemberJoin:
            self = .participantsAdded

        case .conversationMemberLeave:
            self = .participantsRemoved(reason: event.participantsRemovedReason)

        case .conversationMessageTimerUpdate:
            guard let payload = event.payload["data"] as? [String: AnyHashable] else { return nil }
            let timeoutIntegerValue = (payload["message_timer"] as? Int64) ?? 0
            let timeoutValue = MessageDestructionTimeoutValue(rawValue: TimeInterval(timeoutIntegerValue))
            self = timeoutValue == .none ? .messageTimerUpdate(nil) : .messageTimerUpdate(timeoutValue.displayString)

        case .conversationOtrMessageAdd:
            guard let message = GenericMessage(from: event) else { return nil }
            self.init(message: message, conversation: conversation, in: moc)

        default:
            return nil
        }
    }

    public init?(message: GenericMessage, conversation: ZMConversation?, in moc: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: moc)

        func getQuotedMessage(_ textMessageData: Text, conversation: ZMConversation?, in moc: NSManagedObjectContext) -> ZMOTRMessage? {
            guard let conversation = conversation else { return nil }
            let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
            return ZMOTRMessage.fetch(withNonce: quotedMessageId, for: conversation, in: moc)
        }

        switch message.content {
        case .location:
            self =  .location

        case .knock:
            self =  .knock

        case .image:
            self = .image

        case .ephemeral:
            if message.ephemeral.hasText {
                let textMessageData = message.ephemeral.text
                let quotedMessage = getQuotedMessage(textMessageData, conversation: conversation, in: moc)
                self = .ephemeral(isMention: textMessageData.isMentioningSelf(selfUser), isReply: textMessageData.isQuotingSelf(quotedMessage))
            } else {
                self = .ephemeral(isMention: false, isReply: false)
            }

        case .text:
            guard
                let textMessageData = message.textData,
                let text = message.textData?.content.removingExtremeCombiningCharacters, !text.isEmpty
            else {
                return nil
            }

            let quotedMessage = getQuotedMessage(textMessageData, conversation: conversation, in: moc)
            self = .text(text, isMention: textMessageData.isMentioningSelf(selfUser), isReply: textMessageData.isQuotingSelf(quotedMessage))

        case .composite:
            guard let textData = message.composite.items.compactMap({ $0.text }).first else { return nil }
            self = .text(textData.content, isMention: textData.isMentioningSelf(selfUser), isReply: false)

        case .asset(let assetData):
            switch assetData.original.metaData {
            case .audio?:
                self = .audio
            case .video?:
                self = .video
            case .image:
                self = .image
            default:
                self = .fileUpload
            }

        default:
            return nil
        }
    }

}
