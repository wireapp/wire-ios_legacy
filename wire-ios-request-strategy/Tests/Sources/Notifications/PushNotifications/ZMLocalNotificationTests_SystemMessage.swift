//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireTesting
@testable import WireRequestStrategy

class ZMLocalNotificationTests_SystemMessage: ZMLocalNotificationTests {

    // MARK: - Helpers

    func noteForParticipantAdded(_ conversation: ZMConversation, aSender: ZMUser, otherUsers: Set<ZMUser>) -> ZMLocalNotification? {
        let event = createMemberJoinUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, users: Array(otherUsers), senderID: aSender.remoteIdentifier)

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func noteForParticipantsRemoved(_ conversation: ZMConversation, aSender: ZMUser, otherUsers: Set<ZMUser>) -> ZMLocalNotification? {
        let event = createMemberLeaveUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, users: Array(otherUsers), senderID: aSender.remoteIdentifier)

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    // MARK: - Tests

    func testThatItDoesNotCreateANotificationForConversationRename() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let payload = [
                "from": self.sender.remoteIdentifier!.transportString(),
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": NSDate().transportString(),
                "data": [
                    "name": "New Name"
                ],
                "type": "conversation.rename"
            ] as [String: Any]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesANotificationForParticipantAdd_Self() {

        //    "push.notification.member.join.self" = "%1$@ added you";
        //    "push.notification.member.join.self.noconversationname" = "%1$@ added you to a conversation";

        // given, when
        syncMOC.performGroupedBlockAndWait {
            let note1 = self.noteForParticipantAdded(self.groupConversation, aSender: self.sender, otherUsers: [self.selfUser])
            let note2 = self.noteForParticipantAdded(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.selfUser])
            let note3 = self.noteForParticipantAdded(self.groupConversation, aSender: self.sender, otherUsers: [self.selfUser, self.otherUser1])

            // then
            XCTAssertNotNil(note1)
            XCTAssertNotNil(note2)
            XCTAssertNotNil(note3)
            XCTAssertEqual(note1!.body, "Super User added you")
            XCTAssertEqual(note2!.body, "Super User added you to a conversation")
            XCTAssertEqual(note3!.body, "Super User added you")
        }
    }

    func testThatItDoesNotCreateANotificationForParticipantAdd_Other() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.noteForParticipantAdded(self.groupConversation, aSender: self.sender, otherUsers: [self.otherUser1]))
            XCTAssertNil(self.noteForParticipantAdded(self.groupConversation, aSender: self.sender, otherUsers: [self.otherUser1, self.otherUser2]))
            XCTAssertNil(self.noteForParticipantAdded(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.otherUser1]))
            XCTAssertNil(self.noteForParticipantAdded(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.otherUser1, self.otherUser2]))
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheUserLeaves() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMemberLeaveUpdateEvent(UUID.create(), conversationID: self.groupConversation.remoteIdentifier!, users: [self.otherUser1], senderID: self.otherUser1.remoteIdentifier)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesANotificationForParticipantRemove_Self() {

        //    "push.notification.member.leave.self" = "%1$@ removed you from %2$@";
        //    "push.notification.member.leave.self.noconversationname" = "%1$@ removed you from a conversation";

        // given, when
        syncMOC.performGroupedBlockAndWait {
            let note1 = self.noteForParticipantsRemoved(self.groupConversation, aSender: self.sender, otherUsers: [self.selfUser])
            let note2 = self.noteForParticipantsRemoved(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.selfUser])

            // then
            XCTAssertNotNil(note1)
            XCTAssertNotNil(note2)
            XCTAssertEqual(note1!.body, "Super User removed you")
            XCTAssertEqual(note2!.body, "Super User removed you from a conversation")
        }
    }

    func testThatItDoesNotCreateNotificationsForParticipantRemoved_Other() {
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.noteForParticipantsRemoved(self.groupConversation, aSender: self.sender, otherUsers: [self.otherUser1]))
            XCTAssertNil(self.noteForParticipantsRemoved(self.groupConversation, aSender: self.sender, otherUsers: [self.otherUser1, self.otherUser2]))
            XCTAssertNil(self.noteForParticipantsRemoved(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.otherUser1]))
            XCTAssertNil(self.noteForParticipantsRemoved(self.groupConversationWithoutName, aSender: self.sender, otherUsers: [self.otherUser1, self.otherUser2]))
        }
    }
}
