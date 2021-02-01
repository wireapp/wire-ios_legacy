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

import UIKit
@testable import Wire
import XCTest

///TODO: no need subclass after DM protocol update
private final class MockConversation: MockConversationAvatarViewConversation, MutedMessageTypesProvider, ConversationStatusProvider {
    var status: ConversationStatus
    
    var mutedMessageTypes: MutedMessageTypes = .none
    
    override init() {
        status = ConversationStatus(isGroup: false, hasMessages: false, hasUnsentMessages: false, messagesRequiringAttention: [], messagesRequiringAttentionByType: [:], isTyping: false, mutedMessageTypes: .none, isOngoingCall: false, isBlocked: false, isSelfAnActiveMember: true, hasSelfMention: false, hasSelfReply: false)
    }
    
    static func createOneOnOneConversation() -> MockConversation {
        SelfUser.setupMockSelfUser()
        let otherUser = MockUserType.createDefaultOtherUser()
        let otherUserConversation = MockConversation()

        // avatar
        otherUserConversation.stableRandomParticipants = [otherUser]
        otherUserConversation.conversationType = .oneOnOne

        //title
        otherUserConversation.displayName = otherUser.name!

        //subtitle
        otherUserConversation.connectedUserType = otherUser
        
        return otherUserConversation
    }
}

final class ConversationListCellTests: XCTestCase {

    // MARK: - Setup
    
    var sut: ConversationListCell!
    fileprivate var otherUserConversation: MockConversation!
    var otherUser: MockUserType!
    
    override func setUp() {
        super.setUp()
        
        otherUserConversation = MockConversation.createOneOnOneConversation()
        
        accentColor = .strongBlue
        ///The cell must higher than 64, otherwise it breaks the constraints.
        sut = ConversationListCell(frame: CGRect(x: 0, y: 0, width: 375, height: ConversationListItemView.minHeight))

    }
    
    override func tearDown() {
        sut = nil
        SelfUser.provider = nil
        otherUserConversation = nil
        otherUser = nil
        
        super.tearDown()
    }
    
    // MARK: - Helper
    
    private func verify(
        _ conversation: MockConversation,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
        ) {
        sut.conversation = conversation
        sut.backgroundColor = .darkGray
        verify(matching: sut, file: file, testName: testName, line: line)
    }
    
    // MARK: - Tests
    
    func testThatItRendersWithoutStatus() {
        // when & then
        verify(otherUserConversation)
    }
    
    func testThatItRendersMutedConversation() {
        // when
        otherUserConversation.mutedMessageTypes = [.all]
        
        // then
        verify(otherUserConversation)
    }
///TODO: @property (nonatomic, readonly, nullable) ZMUser *connectedUser;
    /*
    func testThatItRendersBlockedConversation() {
        // when
        otherUserConversation.connectedUser?.toggleBlocked()
        
        // then
        verify(otherUserConversation)
    }
        
    func testThatItRendersConversationWithNewMessage() {
        // when
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithNewMessages() {
        // when
        (0..<8).forEach {_ in 
            let message = try! otherUserConversation.appendText(content: "Hey there!")
            (message as! ZMClientMessage).sender = otherUser
        }
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversation_TextMessagesThenMention() {
        // when
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! otherUserConversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        
        // then
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_TextMessagesThenMentionThenReply() {
        // when
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser

        let selfMessage = try! otherUserConversation.appendText(content: "Ping!")
        (message as! ZMClientMessage).sender = selfUser

        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! otherUserConversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser

        let replyMessage = try! otherUserConversation.appendText(content: "Pong!", replyingTo: selfMessage)
        (replyMessage as! ZMMessage).sender = otherUser

        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)

        // then
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_ReplySelfMessage() {
        // when
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = selfUser

        let replyMessage = try! otherUserConversation.appendText(content: "reply test", replyingTo: message)
        (replyMessage as! ZMMessage).sender = otherUser

        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)

        // then
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_MentionThenTextMessages() {
        // when
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! otherUserConversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersMutedConversation_TextMessagesThenMention() {
        // when
        otherUserConversation.mutedMessageTypes = [.all]
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! otherUserConversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersMutedConversation_MentionThenTextMessages() {
        // when
        otherUserConversation.mutedMessageTypes = [.all]
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
        (try! otherUserConversation.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
        let message = try! otherUserConversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithKnock() {
        // when
        let knock = try! otherUserConversation.appendKnock()
        (knock as! ZMClientMessage).sender = otherUser
        otherUserConversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithTypingOtherUser() {
        // when
        otherUserConversation.setTypingUsers([otherUser])

        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithTypingSelfUser() {
        // when
        otherUserConversation.setIsTyping(true)
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersGroupConversation() {
        // when
        let conversation = createGroupConversation()
        conversation.add(participants:[createUser(name: "Ana")])

        // then
        verify(conversation)
    }
    
    func testThatItRendersGroupConversationThatWasLeft() {
        // when
        let conversation = createGroupConversation()
        conversation.removeParticipantsAndUpdateConversationState(users: [selfUser], initiatingUser: otherUser)
        
        // then
        verify(conversation)
    }

    func testThatItRendersGroupConversationWithIncomingCall() {
        let conversation = createGroupConversation()
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithIncomingCall_SilencedExceptMentions() {
        let conversation = createGroupConversation()
        conversation.mutedMessageTypes = .mentionsAndReplies
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }
    
    func testThatItRendersGroupConversationWithIncomingCall_SilencedAll() {
        let conversation = createGroupConversation()
        conversation.mutedMessageTypes = .all
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }
    
    func testThatItRendersGroupConversationWithOngoingCall() {
        let conversation = createGroupConversation()
        let icon = CallingMatcher.icon(for: .outgoing(degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithTextMessages() {
        // when
        let conversation = createGroupConversation()
        let message = try! conversation.appendText(content: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
        
        // then
        verify(conversation)
    }
    
    func testThatItRendersOneOnOneConversationWithIncomingCall() {
        let conversation = otherUserConversation
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }
    
    func testThatItRendersOneOnOneConversationWithIncomingCall_SilencedExceptMentions() {
        let conversation = otherUserConversation
        conversation?.mutedMessageTypes = .mentionsAndReplies
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }
    
    func testThatItRendersOneOnOneConversationWithIncomingCall_SilencedAll() {
        let conversation = otherUserConversation
        conversation?.mutedMessageTypes = .all
        let icon = CallingMatcher.icon(for: .incoming(video: false, shouldRing: true, degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }
    
    func testThatItRendersOneOnOneConversationWithOngoingCall() {
        let conversation = otherUserConversation
        let icon = CallingMatcher.icon(for: .outgoing(degraded: false), conversation: conversation)
        verify(conversation: conversation, icon: icon)
    }*/

    
    /*func verify(conversation: ZMConversation?, icon: ConversationStatusIcon?) {
        guard let conversation = conversation else { XCTFail(); return }
        sut.conversation = conversation
        sut.itemView.rightAccessory.icon = icon

        verify(view: sut)
    }*/
    
}
