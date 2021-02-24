//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import XCTest
@testable import Wire

class ConversationStatusLineTests: CoreDataSnapshotTestCase {

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
    }
    
    override var needsCaches: Bool {
        return true
    }
    
    func testStatusForNotActiveConversationWithHandle() {
        // GIVEN
        let sut = self.otherUserConversation!
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "@" + otherUser.handle!)
    }
    
    func testStatusForNotActiveConversationGroup() {
        // GIVEN
        let sut = self.createGroupConversation()
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testStatusFailedToSend() {
        // GIVEN
        let sut = self.otherUserConversation!
        let message = try! sut.appendText(content: "text") as! ZMMessage
        message.expire()
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "⚠️ Unsent message")
    }
    
    func testStatusBlocked() {
        // GIVEN
        let sut = self.otherUserConversation!
        self.otherUser.block()
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "Blocked")
    }
    
    func testStatusMissedCall() {
        // GIVEN
        let sut = self.otherUserConversation!
        appendMissedCall(to: sut)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "Missed call")
    }

    func testStatusMissedCallInGroup() {
        // GIVEN
        let sut = createGroupConversation()
        appendMissedCall(to: sut)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "Missed call from Bruno")
    }
    
    func testStatusRejectedCall() {
        // GIVEN
        let sut = self.otherUserConversation!
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.sender = self.otherUser
        otherMessage.systemMessageType = .missedCall
        otherMessage.relevantForConversationStatus = false
        sut.append(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
        
    func testStatusForMultipleTextMessagesInConversation() {
        // GIVEN
        let sut = self.otherUserConversation!
        for index in 1...5 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "test 5")
    }

    func testStatusSecondReplyDoesNotSummarize() {
        // GIVEN
        let sut = self.otherUserConversation!

        let selfMessage = appendSelfMessage(to: sut)

        for index in 1...2 {
            appendReply(to: sut, selfMessage: selfMessage, text: "reply test \(index)")
        }
        
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "reply test 2")
    }


    func testStatusMissedCallAndUnreadMessagesAndReplies() {
        // GIVEN
        let sut = self.otherUserConversation!

        let selfMessage = try! sut.appendText(content: "I am a programmer") as! ZMMessage
        selfMessage.sender = selfUser
        
        for index in 1...3 {
            (try! sut.appendText(content: "Yes, it is true \(index)", replyingTo: selfMessage) as! ZMMessage).sender = self.otherUser
        }
        sut.setPrimitiveValue(3, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)

        appendMissedCall(to: sut)

        // insert messages from other
        for index in 1...2 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = self.otherUser
        }

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "3 replies, 1 missed call, 2 messages")
    }

    func testStatusForMultipleTextMessagesInConversationIncludingMention() {
        // GIVEN
        let sut = self.otherUserConversation!
        for index in 1...5 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! sut.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        sut.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "1 mention, 5 messages")
    }
    
    func testStatusForMultipleTextMessagesInConversation_LastRename() {
        // GIVEN
        let sut = self.otherUserConversation!
        for index in 1...5 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.sender = self.otherUser
        otherMessage.systemMessageType = .conversationNameChanged
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "test 5")
    }
    
    func testStatusForSystemMessageILeft() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.removeParticipantsAndUpdateConversationState(users: [selfUser], initiatingUser: selfUser)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "You left")
    }
    
    func testStatusForSystemMessageIWasAdded() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.selfUser])
        otherMessage.addedUsers = Set([self.selfUser])
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "\(self.otherUser.name ?? "") added you")
    }
    
    func testNoStatusForSystemMessageIAddedSomeone() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.addedUsers = Set([self.otherUser])
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testNoStatusForSystemMessageIRemovedSomeone() {
        // GIVEN
        let sut = createGroupConversation()
        sut.add(participants: [createUser(name: "Vanessa")])
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.removedUsers = Set([self.otherUser])
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testStatusForSystemMessageIWasRemoved() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.selfUser])
        otherMessage.removedUsers = Set([self.selfUser])
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "You were removed")
    }
    
    func testStatusForSystemMessageSomeoneWasRemoved() {
        // GIVEN
        let sut = createGroupConversation()
        sut.add(participants: createUser(name: "Lilly"))
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.removedUsers = Set([self.otherUser])
        sut.append(otherMessage)
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testStatusForConversationStarted() {
        // GIVEN
        let sut = self.createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.otherUser, self.selfUser])
        otherMessage.addedUsers = Set([self.otherUser, self.selfUser])
        sut.lastServerTimeStamp = Date()
        sut.append(otherMessage)
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "\(self.otherUser.name ?? "") started a conversation")
    }
    
    func testNoStatusForSelfConversationStarted() {
        // GIVEN
        let sut = self.createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser, self.selfUser])
        otherMessage.addedUsers = Set([self.otherUser, self.selfUser])
        sut.append(otherMessage)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testThatTypingHasHigherPrioThanMentions() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.managedObjectContext?.saveOrRollback()
        sut.setTypingUsers([otherUser])
        
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! sut.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        
        markAllMessagesAsUnread(in: sut)
        
        // WHEN
        let status = sut.status
        
        // THEN
        XCTAssertEqual(status.isTyping, true)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.mention]!, 1)
        XCTAssertEqual(status.description(for: sut).string, "Bruno: typing a message…")
    }
}
