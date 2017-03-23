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
        super.setUp()
        selfUser.accentColorValue = .violet
        accentColor = .violet
    }

    func testThatItReturnsStatusForEmptyConversation() {
        // GIVEN
        let sut = self.otherUserConversation!
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertFalse(status.hasMessages)
    }
    
    func testThatItReturnsStatusForEmptyConversation_group() {
        // GIVEN
        let sut = self.createGroupConversation()
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertFalse(status.hasMessages)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadOneMessage() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendMessage(withText: "test") as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 1)
        XCTAssertEqual(status.unreadMessagesByType[.text]!, 1)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadOnePing() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendKnock() as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 1)
        XCTAssertEqual(status.unreadMessagesByType[.text], .none)
        XCTAssertEqual(status.unreadMessagesByType[.knock]!, 1)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadOneImage() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 1)
        XCTAssertEqual(status.unreadMessagesByType[.text], .none)
        XCTAssertEqual(status.unreadMessagesByType[.image]!, 1)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadManyMessages() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendKnock() as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withText: "test") as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 3)
        XCTAssertEqual(status.unreadMessagesByType[.text]!, 1)
        XCTAssertEqual(status.unreadMessagesByType[.image]!, 1)
        XCTAssertEqual(status.unreadMessagesByType[.knock]!, 1)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadManyTexts() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendMessage(withText: "test 1") as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withText: "test 2") as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withText: "test 3") as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 3)
        XCTAssertEqual(status.unreadMessagesByType[.text]!, 3)
        XCTAssertEqual(status.unreadMessagesByType[.image], .none)
        XCTAssertEqual(status.unreadMessagesByType[.knock], .none)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadManyPings() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendKnock() as! ZMMessage).sender = self.otherUser
        (sut.appendKnock() as! ZMMessage).sender = self.otherUser
        (sut.appendKnock() as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 3)
        XCTAssertEqual(status.unreadMessagesByType[.text], .none)
        XCTAssertEqual(status.unreadMessagesByType[.image], .none)
        XCTAssertEqual(status.unreadMessagesByType[.knock]!, 3)
    }
    
    func testThatItReturnsStatusForConversationWithUnreadManyImages() {
        // GIVEN
        let sut = self.otherUserConversation!
        (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        sut.lastReadServerTimeStamp = Date.distantPast
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.unreadMessages.count, 3)
        XCTAssertEqual(status.unreadMessagesByType[.text], .none)
        XCTAssertEqual(status.unreadMessagesByType[.image]!, 3)
    }
    
//    Temporarily disabled, need to figure out a better way to mock typing state.
//    func testThatItReturnsStatusForConversationWithTyping() {
//        // GIVEN
//        let sut = self.createGroupConversation()
//        sut.remoteIdentifier = UUID()
//        let change = ZMTypingChangeNotification(conversation: sut, typingUser: Set([self.otherUser]))
//        self.uiMOC.typingUsers.update(with: change)
//        // WHEN
//        let status = sut.status
//        // THEN
//        XCTAssertFalse(status.hasMessages)
//        XCTAssertEqual(status.unreadMessages.count, 0)
//        XCTAssertTrue(status.isTyping)
//    }
    
    func testThatItReturnsStatusForBlocked() {
        // GIVEN
        let sut = self.otherUserConversation!
        otherUser.connection?.status = .blocked
        // WHEN
        let status = sut.status
        // THEN
        XCTAssertFalse(status.hasMessages)
        XCTAssertTrue(status.isBlocked)
    }
}
