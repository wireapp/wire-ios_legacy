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

class ConversationListCellTests: CoreDataSnapshotTestCase {

    // MARK: - Setup
    
    var sut: ConversationListCell!
    
    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .darkGray
        accentColor = .strongBlue
        sut = ConversationListCell(frame: CGRect(x: 0, y: 0, width: 375, height: 60))
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    // MARK: - Helper
    
    private func verify(
        _ conversation: ZMConversation,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        sut.conversation = conversation
        
        sut.prepareForSnapshot()
        verify(view: sut, file: file, line: line)
    }
    
    // MARK: - Tests
    
    func testThatItRendersWithoutStatus() {
        // when & then
        verify(otherUserConversation)
    }
    
    func testThatItRendersMutedConversation() {
        // when
        otherUserConversation.isSilenced = true
        
        // then
        verify(otherUserConversation)
    }

    func testThatItRendersBlockedConversation() {
        // when
        otherUserConversation.connectedUser?.toggleBlocked()
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithMessagesFromSelf() {
        // when
        otherUserConversation.appendMessage(withText: "Hey there!")
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithNewMessage() {
        // when
        let message = otherUserConversation.appendMessage(withText: "Hey there!")
        (message as! ZMClientMessage).sender = otherUser
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithNewMessages() {
        // when
        (0..<8).forEach {_ in 
            let message = otherUserConversation.appendMessage(withText: "Hey there!")
            (message as! ZMClientMessage).sender = otherUser
        }
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithKnockFromSelf() {
        // when
        otherUserConversation.appendKnock()
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithKnock() {
        // when
        let knock = otherUserConversation.appendKnock()
        (knock as! ZMClientMessage).sender = otherUser
        
        // then
        verify(otherUserConversation)
    }
    
    func testThatItRendersConversationWithTypingOtherUser() {
        // when
        otherUserConversation.managedObjectContext?.typingUsers.update([otherUser], in: otherUserConversation)
        
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
        conversation.internalAddParticipants([createUser(name: "Ana")])

        // then
        verify(conversation)
    }
    
    func testThatItRendersGroupConversationThatWasLeft() {
        // when
        let conversation = createGroupConversation()
        conversation.internalRemoveParticipants([selfUser], sender: otherUser)
        
        // then
        verify(conversation)
    }

}
