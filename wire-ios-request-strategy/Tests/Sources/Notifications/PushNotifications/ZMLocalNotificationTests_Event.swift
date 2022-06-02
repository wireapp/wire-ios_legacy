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

import XCTest
@testable import WireRequestStrategy

final class ZMLocalNotificationTests_Event: ZMLocalNotificationTests {

    let EventConversationDelete = "conversation.delete"
    let EventConversationCreate = "conversation.create"
    let EventNewConnection = "user.contact-join"
    let EventaAddOTRMessage = "conversation.otr-message-add"

    // MARK: Helpers

    func payloadForConnectionRequest(to remoteID: UUID, status: String) -> [AnyHashable: Any] {
        return [
            "connection": [
                "conversation": oneOnOneConversation.remoteIdentifier!.transportString(),
                "message": "Please add me",
                "from": UUID.create().transportString(),
                "status": status,
                "to": remoteID.transportString()
            ],
            "type": "user.connection",
            "user": ["name": "Special User"]
        ]
    }

    func noteForConnectionRequestEvent(to user: ZMUser?, status: String) -> ZMLocalNotification? {
        let remoteID = user?.remoteIdentifier ?? UUID.create()
        var note: ZMLocalNotification?
        let payload = payloadForConnectionRequest(to: remoteID, status: status)

        if let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil) {
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)
        }
        return note
    }

    func reactionEventInOneOnOneConversation() -> ZMUpdateEvent {
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: sender.remoteIdentifier!)
        return event
    }

    func alertBody(_ conversation: ZMConversation, aSender: ZMUser) -> String? {

        // given
        let message = try! conversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, genericMessage: reaction, senderID: aSender.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)

        // then
        XCTAssertNotNil(note)
        return note!.body
    }

    func note(_ conversation: ZMConversation, aSender: ZMUser) -> ZMLocalNotification? {

        // given
        let message = try! conversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, genericMessage: reaction, senderID: aSender.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)

        return note
    }

    // MARK: - Group Conversation Created

    func testThatItCreatesConversationCreateNotification() {
        syncMOC.performGroupedBlockAndWait {
            // "push.notification.conversation.create" = "%1$@ created a group conversation with you"

            // when
            let note = self.noteWithPayload(nil, from: self.sender, in: self.groupConversation, type: self.EventConversationCreate)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User created a conversation")
        }
    }

    func testThatItCreatesConversationCreateNotification_NoUsername() {
        syncMOC.performGroupedBlockAndWait {
            // "push.notification.conversation.create.nousername" = "Someone created a group conversation with you"

            // when
            let note = self.noteWithPayload(nil, fromUserID: nil, in: self.groupConversation, type: self.EventConversationCreate)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Someone created a conversation")
        }
    }

    func testThatItDoesntCreateConversationCreateNotification_OneToOne() {
        syncMOC.performGroupedBlockAndWait {
            // We don't want to create a notification for fake team one-to-one conversations

            // when
            let note = self.noteWithPayload(nil, fromUserID: nil, in: self.oneOnOneConversation, type: self.EventConversationCreate)

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: - Group conversation deleted

    func testThatItCreatesConversationDeletedNotification() {
        syncMOC.performGroupedBlockAndWait {
            // "push.notification.conversation.delete" = "%1$@ deleted the group"

            // when
            let note = self.noteWithPayload(nil, from: self.sender, in: self.groupConversation, type: self.EventConversationDelete)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User deleted the group")
        }
    }

    func testThatItCreatesConversationDeletedNotification_NoUsername() {
        syncMOC.performGroupedBlockAndWait {
            // "push.notification.conversation.delete.nousername" = "Someone deleted the group"

            // when
            let note = self.noteWithPayload(nil, fromUserID: nil, in: self.groupConversation, type: self.EventConversationDelete)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Someone deleted the group")
        }
    }

    // MARK: - User Connections

    func testThatItCreatesNewConnectionNotification() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let senderID = UUID.create()
            let payload = [
                "user": ["id": senderID.transportString(), "name": "Stimpy"],
                "type": self.EventNewConnection,
                "time": Date().transportString()
            ] as ZMTransportData

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            var note: ZMLocalNotification?

            // when
            if let event = event {
                note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.uiMOC)
            }

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Stimpy just joined Wire")
            XCTAssertEqual(note!.senderID, senderID)
        }
    }

    func testThatItCreatesConnectionRequestNotificationsCorrectly() {
        //    "push.notification.connection.request" = "%@ wants to connect"
        //    "push.notification.connection.request.nousername" = "Someone wants to connect"
        //
        //    "push.notification.connection.accepted" = "%@ accepted your connection request"
        //    "push.notification.connection.accepted.nousername" = "Your connection request was accepted"

        // given
        syncMOC.performGroupedBlockAndWait {
            let accepted = "accepted"
            let pending = "pending"

            let cases = [
                "You and Super User are now connected": [self.sender!, accepted],
                "You and Special User are now connected": [accepted],
                "Super User wants to connect": [self.sender!, pending],
                "Special User wants to connect": [pending]
            ]

            for (expectedBody, arguments) in cases {
                // when
                var note: ZMLocalNotification?
                if arguments.count == 2 {
                    note = self.noteForConnectionRequestEvent(to: arguments[0] as? ZMUser, status: arguments[1] as! String)
                } else {
                    note = self.noteForConnectionRequestEvent(to: nil, status: arguments[0] as! String)
                }

                // then
                XCTAssertNotNil(note)
                XCTAssertEqual(note!.body, expectedBody)
            }
        }
    }

    func testThatItDoesNotCreateAConnectionAcceptedNotificationForAWrongStatus() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let status = "blablabla"

            // when
            let note = self.noteForConnectionRequestEvent(to: nil, status: status)

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: - Reactions

    func testThatItCreatesANotifcationForAReaction_SelfUserIsSenderOfOriginalMessage_OtherUserSendsLike() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.reactionEventInOneOnOneConversation()

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "❤️ your message")
        }
    }

    func testThatItDoesNotCreateANotifcationWhenTheConversationIsSilenced() {

        // given
        syncMOC.performGroupedBlockAndWait {
            self.oneOnOneConversation.mutedMessageTypes = .all
            let event = self.reactionEventInOneOnOneConversation()

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItSavesTheSenderOfANotification() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.reactionEventInOneOnOneConversation()

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.senderID, self.sender.remoteIdentifier)
        }
    }

    func testThatItSavesTheConversationOfANotification() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.reactionEventInOneOnOneConversation()

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.conversationID, self.oneOnOneConversation.remoteIdentifier)
        }
    }

    func testThatItSavesTheMessageNonce() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let message = try! self.oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
            let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "liked", messageID: message.nonce!) as! MessageCapable)
            let eventNonce = UUID.create()
            let event = self.createUpdateEvent(eventNonce, conversationID: self.oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: self.sender.remoteIdentifier!)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.messageNonce, message.nonce)
        }
    }

    func testThatItCreatesTheCorrectAlertBody_ConvWithoutName() {
        syncMOC.performGroupedBlockAndWait {
            guard let alertBody = self.alertBody(self.groupConversationWithoutName, aSender: self.otherUser1) else {
                return XCTFail("Alert body is missing")
            }
            XCTAssertEqual(alertBody, "Other User1 ❤️ your message in a conversation")
        }
    }

    func testThatItCreatesTheCorrectAlertBody() {
        syncMOC.performGroupedBlockAndWait {
            guard let alertBody = self.alertBody(self.groupConversation, aSender: self.otherUser1) else {
                return XCTFail("Alert body is missing")
            }
            XCTAssertEqual(alertBody, "Other User1 ❤️ your message")
        }
    }

    func testThatItCreatesTheCorrectAlertBody_UnknownUser() {
        syncMOC.performGroupedBlockAndWait {
            self.otherUser1.name = ""
            guard let alertBody = self.alertBody(self.groupConversation, aSender: self.otherUser1) else {
                return XCTFail("Alert body is missing")
            }
            XCTAssertEqual(alertBody, "Someone ❤️ your message")
        }
    }

        func testThatItCreatesTheCorrectAlertBody_UnknownUser_UnknownConversationName() {
            syncMOC.performGroupedBlockAndWait {
                self.otherUser1.name = ""
                guard let alertBody = self.alertBody(self.groupConversationWithoutName, aSender: self.otherUser1) else {
                    return XCTFail("Alert body is missing")
                }
                XCTAssertEqual(alertBody, "Someone ❤️ your message in a conversation")
            }
        }

        func testThatItCreatesTheCorrectAlertBody_UnknownUser_OneOnOneConv() {
            syncMOC.performGroupedBlockAndWait {
                self.otherUser1.name = ""
                guard let alertBody = self.alertBody(self.oneOnOneConversation, aSender: self.otherUser1) else {
                    return XCTFail("Alert body is missing")
                }
                XCTAssertEqual(alertBody, "Someone ❤️ your message")
            }
        }

    func testThatItDoesNotCreateANotifcationForAnUnlikeReaction() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let message = try! self.oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
            let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "", messageID: message.nonce!) as! MessageCapable)
            let event = self.createUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: self.sender.remoteIdentifier!)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesNotCreateANotificationForAReaction_SelfUserIsSenderOfOriginalMessage_SelfUserSendsLike() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let message = try! self.oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
            let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
            let event = self.createUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: self.selfUser.remoteIdentifier!)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesNotCreateANotificationForAReaction_OtherUserIsSenderOfOriginalMessage_OtherUserSendsLike() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let message = try! self.oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
            message.sender = self.otherUser1

            let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
            let event = self.createUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: self.sender.remoteIdentifier!)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: - Message Timer System Message

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversation.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 set the message timer to 1 day")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversation.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 1 day")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversationWithoutName.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversationWithoutName, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 set the message timer to 1 day in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversationWithoutName.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversationWithoutName, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 1 day in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_Off() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversation.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 turned off the message timer")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_Off() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversation.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone turned off the message timer")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName_Off() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversationWithoutName.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversationWithoutName, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 turned off the message timer in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName_Off() {
        // given
        syncMOC.performGroupedBlockAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(self.otherUser1.remoteIdentifier, conversationID: self.groupConversationWithoutName.remoteIdentifier!, senderID: self.otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

            // when
            let note = ZMLocalNotification(event: event, conversation: self.groupConversationWithoutName, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone turned off the message timer in a conversation")
        }
    }

    // MARK: - Notification title

    func testThatItAddsATitleIfTheUserIsPartOfATeam() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let team = Team.insertNewObject(in: self.syncMOC)
            team.name = "Wire Amazing Team"
            let user = ZMUser.selfUser(in: self.syncMOC)
            _ = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            XCTAssertNotNil(user.team)

            // when
            let note = self.note(self.oneOnOneConversation, aSender: self.sender)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User in \(team.name!)")
        }
    }

    func testThatItDoesNotAddATitleIfTheUserIsNotPartOfATeam() {
        syncMOC.performGroupedBlockAndWait {
            // when
            let note = self.note(self.oneOnOneConversation, aSender: self.sender)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User")
        }
    }

    // MARK: - Create text local notifications from update events

    func testThatItCreatesATextNotification() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: GenericMessage(content: Text(content: "Stimpy just joined Wire")))
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User")
            XCTAssertEqual(note!.body, "New message: Stimpy just joined Wire")
        }
    }

    func testThatItDoesNotCreateANotificationForConfirmationEvents() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let confirmation = GenericMessage(content: Confirmation(messageId: .create()))
            let event = self.createUpdateEvent(.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, genericMessage: confirmation)

            // when
            let note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesATextNotification_NoConversation() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let genericMessage = GenericMessage(content: Text(content: "123"))

            // when
            let note = self.noteWithPayload(["text": try? genericMessage.serializedData().base64EncodedString()], from: self.sender, in: nil, type: self.EventaAddOTRMessage)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User in a conversation: 123")
        }
    }

    // MARK: - Create system local notifications from update events

    func testThatItCreatesASystemLocalNotificationForRemovingTheSelfUserEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMemberLeaveUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, users: [self.selfUser])
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.title, "Super User")
            XCTAssertEqual(note?.body, "%1$@ removed you")
        }
    }

    func testThatItCreatesASystemLocalNotificationForAddingTheSelfUserEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMemberJoinUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, users: [self.selfUser])
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.title, "Super User")
            XCTAssertEqual(note?.body, "%1$@ added you")
        }
    }

    func testThatItCreatesASystemLocalNotificationForMessageTimerUpdateEvent() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let event = self.createMessageTimerUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!)
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 1 year")
        }
    }
}
