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

extension CoreDataSnapshotTestCase {
    func appendTextMessage(to conversation: ZMConversation) {
        let message = try! conversation.appendText(content: "test \(conversation.allMessages.count + 1)") as! ZMMessage
        (message).sender = self.otherUser

        conversation.lastReadServerTimeStamp = Date.distantPast
    }

    func appendImage(to conversation: ZMConversation) {
        (try! conversation.appendImage(from: self.image(inTestBundleNamed: "unsplash_burger.jpg").jpegData(compressionQuality: 1.0)!) as! ZMMessage).sender = self.otherUser
        conversation.lastReadServerTimeStamp = Date.distantPast
    }

    func appendMention(to conversation: ZMConversation) {
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! conversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        conversation.lastReadServerTimeStamp = Date.distantPast
    }

    func appendReply(to conversation: ZMConversation, selfMessage: ZMMessage, text: String = "reply test") {
        (try! conversation.appendText(content: text, replyingTo: selfMessage) as! ZMMessage).sender = self.otherUser
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)
        conversation.lastReadServerTimeStamp = Date.distantPast
    }

    func appendSelfMessage(to conversation: ZMConversation) -> ZMMessage {
        let selfMessage = try! conversation.appendText(content: "I am a programmer") as! ZMMessage
        selfMessage.sender = selfUser

        return selfMessage
    }

    func appendMissedCall(to conversation: ZMConversation) {
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.sender = self.otherUser
        otherMessage.systemMessageType = .missedCall

        conversation.append(otherMessage)
        conversation.lastReadServerTimeStamp = Date.distantPast
    }

}
