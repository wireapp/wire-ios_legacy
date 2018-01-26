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

class ConversationStatusTests: CoreDataSnapshotTestCase {
    
    override var needsCaches: Bool {
        return true
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 1)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 1)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 1)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 1)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock], .none)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 3)
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
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 3)
    }
    
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
