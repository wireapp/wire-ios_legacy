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
    func testStatusForNotActiveConversationWithHandle() {
        // GIVEN
        let sut = self.otherUserConversation!
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "@" + otherUser.handle)
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
        let message = sut.appendMessage(withText: "text") as! ZMMessage
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
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.sender = self.otherUser
        otherMessage.systemMessageType = .missedCall
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "Missed call")
    }
    
    func testStatusForMultipleTextMessagesInConversation_silenced() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.isSilenced = true
        for index in 1...5 {
            (sut.appendMessage(withText: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        sut.lastReadServerTimeStamp = Date.distantPast

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "5 new text messages")
    }
    
    func testStatusForMultipleTextMessagesInConversation() {
        // GIVEN
        let sut = self.otherUserConversation!
        for index in 1...5 {
            (sut.appendMessage(withText: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        sut.lastReadServerTimeStamp = Date.distantPast

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "test 5")
    }
    
    func testStatusForMultipleTextMessagesInConversation_LastRename() {
        // GIVEN
        let sut = self.otherUserConversation!
        for index in 1...5 {
            (sut.appendMessage(withText: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.sender = self.otherUser
        otherMessage.systemMessageType = .conversationNameChanged
        sut.sortedAppendMessage(otherMessage)
        
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "test 5")
    }
    
    func testStatusForMultipleVariousMessagesInConversation_silenced() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.isSilenced = true
        for index in 1...5 {
            (sut.appendMessage(withText: "test \(index)") as! ZMMessage).sender = self.otherUser
        }
        for _ in 1...5 {
            (sut.appendMessage(withImageData: UIImagePNGRepresentation(self.image(inTestBundleNamed: "unsplash_burger.jpg"))!) as! ZMMessage).sender = self.otherUser
        }
        sut.lastReadServerTimeStamp = Date.distantPast

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "5 new text messages, 5 new images")
    }
    
    func testStatusForSystemMessageILeft() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.removeParticipant(selfUser)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "You left")
    }
    
    func testStatusForSystemMessageIWasAdded() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.selfUser])
        otherMessage.addedUsers = Set([self.selfUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "\(self.otherUser.displayName!) added you")
    }
    
    func testNoStatusForSystemMessageIAddedSomeone() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.addedUsers = Set([self.otherUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testNoStatusForSystemMessageIRemovedSomeone() {
        // GIVEN
        let sut = createGroupConversation()
        sut.internalAddParticipants([createUser(name: "Vanessa")], isAuthoritative: true)
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.removedUsers = Set([self.otherUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testEveryoneLeftStatusAfterLastPersonLeft() {
        // Given
        let sut = ZMConversation.insertNewObject(in: moc)
        sut.conversationType = .group

        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = selfUser
        otherMessage.users = [otherUser]
        otherMessage.removedUsers = [otherUser]
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = .distantPast

        // When
        let status = sut.status.description(for: sut)

        // Then
        XCTAssertEqual(status.string, "Everyone left")
    }
    
    func testStatusForSystemMessageSomeoneWasAdded() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.addedUsers = Set([self.otherUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "\(self.otherUser.displayName!) added \(self.otherUser.displayName!)")
    }
    
    func testStatusForSystemMessageIWasRemoved() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.selfUser])
        otherMessage.removedUsers = Set([self.selfUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "You were removed")
    }
    
    func testStatusForSystemMessageSomeoneWasRemoved() {
        // GIVEN
        let sut = createGroupConversation()
        sut.internalAddParticipants([createUser(name: "Lilly")], isAuthoritative: true)
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.otherUser])
        otherMessage.removedUsers = Set([self.otherUser])
        sut.sortedAppendMessage(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
    
    func testStatusForConversationStarted() {
        // GIVEN
        let sut = self.createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = self.otherUser
        otherMessage.users = Set([self.otherUser, self.selfUser])
        otherMessage.addedUsers = Set([self.otherUser, self.selfUser])
        sut.sortedAppendMessage(otherMessage)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "\(self.otherUser.displayName!) started a conversation")
    }
    
    func testNoStatusForSelfConversationStarted() {
        // GIVEN
        let sut = self.createGroupConversation()
        let otherMessage = ZMSystemMessage.insertNewObject(in: moc)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = self.selfUser
        otherMessage.users = Set([self.otherUser, self.selfUser])
        otherMessage.addedUsers = Set([self.otherUser, self.selfUser])
        sut.sortedAppendMessage(otherMessage)
        
        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }
}
