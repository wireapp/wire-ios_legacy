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

import XCTest
@testable import WireSyncEngine

final class ZMLocalNotificationTests_Event: ZMLocalNotificationTests {

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
            note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.uiMOC)
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
        let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)

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
        let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: uiMOC)

        return note
    }

    // MARK: - Group Conversation Created

    func testThatItCreatesConversationCreateNotification() {

        // "push.notification.conversation.create" = "%1$@ created a group conversation with you"

        // when
        let note = noteWithPayload(nil, from: sender, in: groupConversation, type: EventConversationCreate)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.body, "Super User created a group")
    }

    func testThatItCreatesConversationCreateNotification_NoUsername() {

        // "push.notification.conversation.create.nousername" = "Someone created a group conversation with you"

        // when
        let note = noteWithPayload(nil, fromUserID: nil, in: groupConversation, type: EventConversationCreate)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.body, "Someone created a group")
    }

    func testThatItDoesntCreateConversationCreateNotification_OneToOne() {

        // We don't want to create a notification for fake team one-to-one conversations

        // when
        let note = noteWithPayload(nil, fromUserID: nil, in: oneOnOneConversation, type: EventConversationCreate)

        // then
        XCTAssertNil(note)
    }

    // MARK: - Group conversation deleted

    func testThatItCreatesConversationDeletedNotification() {

        // "push.notification.conversation.delete" = "%1$@ deleted the group"

        // when
        let note = noteWithPayload(nil, from: sender, in: groupConversation, type: EventConversationDelete)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.body, "Super User deleted the group")
    }

    func testThatItCreatesConversationDeletedNotification_NoUsername() {

        // "push.notification.conversation.delete.nousername" = "Someone deleted the group"

        // when
        let note = noteWithPayload(nil, fromUserID: nil, in: groupConversation, type: EventConversationDelete)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.body, "Someone deleted the group")
    }

    // MARK: - User Connections

    func testThatItCreatesNewConnectionNotification() {

        // given
        let senderID = UUID.create()
        let payload = [
            "user": ["id": senderID.transportString(), "name": "Stimpy"],
            "type": EventNewConnection,
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

    func testThatItCreatesConnectionRequestNotificationsCorrectly() {
        //    "push.notification.connection.request" = "%@ wants to connect"
        //    "push.notification.connection.request.nousername" = "Someone wants to connect"
        //
        //    "push.notification.connection.accepted" = "%@ accepted your connection request"
        //    "push.notification.connection.accepted.nousername" = "Your connection request was accepted"

        // given
        let accepted = "accepted"
        let pending = "pending"

        let cases = [
            "You and Super User are now connected": [sender!, accepted],
            "You and Special User are now connected": [accepted],
            "Super User wants to connect": [sender!, pending],
            "Special User wants to connect": [pending]
        ]

        for (expectedBody, arguments) in cases {
            // when
            var note: ZMLocalNotification?
            if arguments.count == 2 {
                note = noteForConnectionRequestEvent(to: arguments[0] as? ZMUser, status: arguments[1] as! String)
            } else {
                note = noteForConnectionRequestEvent(to: nil, status: arguments[0] as! String)
            }

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, expectedBody)
        }
    }

    func testThatItDoesNotCreateAConnectionAcceptedNotificationForAWrongStatus() {

        // given
        let status = "blablabla"

        // when
        let note = noteForConnectionRequestEvent(to: nil, status: status)

        // then
        XCTAssertNil(note)
    }

    // MARK: - Reactions

    func testThatItCreatesANotifcationForAReaction_SelfUserIsSenderOfOriginalMessage_OtherUserSendsLike() {

        // given
        let event = reactionEventInOneOnOneConversation()

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.body, "❤️ your message")
    }

    func testThatItDoesNotCreateANotifcationWhenTheConversationIsSilenced() {

        // given
        oneOnOneConversation.mutedMessageTypes = .all
        let event = reactionEventInOneOnOneConversation()

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNil(note)
    }

    func testThatItSavesTheSenderOfANotification() {

        // given
        let event = reactionEventInOneOnOneConversation()

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.senderID, sender.remoteIdentifier)
    }

    func testThatItSavesTheConversationOfANotification() {

        // given
        let event = reactionEventInOneOnOneConversation()

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.conversationID, oneOnOneConversation.remoteIdentifier)
    }

    func testThatItSavesTheMessageNonce() {

        // given
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "liked", messageID: message.nonce!) as! MessageCapable)
        let eventNonce = UUID.create()
        let event = createUpdateEvent(eventNonce, conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: sender.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.messageNonce, message.nonce)
    }

    func testThatItCreatesTheCorrectAlertBody_ConvWithoutName() {
        guard let alertBody = alertBody(groupConversationWithoutName, aSender: otherUser1) else { return XCTFail()}
        XCTAssertEqual(alertBody, "Other User1 ❤️ your message in a conversation")
    }

    func testThatItCreatesTheCorrectAlertBody() {
        guard let alertBody = alertBody(groupConversation, aSender: otherUser1) else { return XCTFail()}
        XCTAssertEqual(alertBody, "Other User1 ❤️ your message")
    }

    func testThatItCreatesTheCorrectAlertBody_UnknownUser() {
        otherUser1.name = ""
        guard let alertBody = alertBody(groupConversation, aSender: otherUser1) else { return XCTFail()}
        XCTAssertEqual(alertBody, "Someone ❤️ your message")
    }

    func testThatItCreatesTheCorrectAlertBody_UnknownUser_UnknownConversationName() {
        otherUser1.name = ""
        guard let alertBody = alertBody(groupConversationWithoutName, aSender: otherUser1) else { return XCTFail()}
        XCTAssertEqual(alertBody, "Someone ❤️ your message in a conversation")
    }

    func testThatItCreatesTheCorrectAlertBody_UnknownUser_OneOnOneConv() {
        otherUser1.name = ""
        guard let alertBody = alertBody(oneOnOneConversation, aSender: otherUser1) else { return XCTFail()}
        XCTAssertEqual(alertBody, "Someone ❤️ your message")
    }

    func testThatItDoesNotCreateANotifcationForAnUnlikeReaction() {

        // given
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: sender.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNil(note)
    }

    func testThatItDoesNotCreateANotificationForAReaction_SelfUserIsSenderOfOriginalMessage_SelfUserSendsLike() {

        // given
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: selfUser.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNil(note)
    }

    func testThatItDoesNotCreateANotificationForAReaction_OtherUserIsSenderOfOriginalMessage_OtherUserSendsLike() {

        // given
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        message.sender = otherUser1

        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(emoji: "❤️", messageID: message.nonce!) as! MessageCapable)
        let event = createUpdateEvent(UUID.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: reaction, senderID: sender.remoteIdentifier!)

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNil(note)
    }

    // MARK: - Message Timer System Message

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages() {
        // given
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversation.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Other User1 set the message timer to 1 day")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName() {
        // given
        otherUser1.name = nil
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversation.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Someone set the message timer to 1 day")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName() {
        // given
         let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversationWithoutName.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversationWithoutName, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Other User1 set the message timer to 1 day in a conversation")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName() {
        // given
        otherUser1.name = nil
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversationWithoutName.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 86400, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversationWithoutName, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Someone set the message timer to 1 day in a conversation")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_Off() {
        // given
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversation.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Other User1 turned off the message timer")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_Off() {
        // given
        otherUser1.name = nil
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversation.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Someone turned off the message timer")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName_Off() {
        // given
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversationWithoutName.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversationWithoutName, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Other User1 turned off the message timer in a conversation")
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName_Off() {
        // given
        otherUser1.name = nil
        let event = createMessageTimerUpdateEvent(otherUser1.remoteIdentifier, conversationID: groupConversationWithoutName.remoteIdentifier!, senderID: otherUser1.remoteIdentifier!, timer: 0, timestamp: Date())

        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversationWithoutName, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Someone turned off the message timer in a conversation")
    }

    // MARK: - Notification title

    func testThatItAddsATitleIfTheUserIsPartOfATeam() {

        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        team.name = "Wire Amazing Team"
        let user = ZMUser.selfUser(in: self.uiMOC)
        self.performPretendingUiMocIsSyncMoc {
            _ = Member.getOrCreateMember(for: user, in: team, context: self.uiMOC)
        }
        self.uiMOC.saveOrRollback()
        XCTAssertNotNil(user.team)

        // when
        let note = self.note(self.oneOnOneConversation, aSender: self.sender)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.title, "Super User in \(team.name!)")
    }

    func testThatItDoesNotAddATitleIfTheUserIsNotPartOfATeam() {

        // when
        let note = self.note(oneOnOneConversation, aSender: sender)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.title, "Super User")
    }

    // MARK: - Create text local notifications from update events

    func testThatItCreatesATextNotification() {
        // given
        let event = createUpdateEvent(UUID.create(), conversationID: UUID.create(), genericMessage: GenericMessage(content: Text(content: "Stimpy just joined Wire")))
        var note: ZMLocalNotification?

        // when
        note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.uiMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note!.title, "Super User")
        XCTAssertEqual(note!.body, "New message: Stimpy just joined Wire")
    }

    func testThatItDoesNotCreateANotificationForConfirmationEvents() {
        // given
        let confirmation = GenericMessage(content: Confirmation(messageId: .create()))
        let event = createUpdateEvent(.create(), conversationID: oneOnOneConversation.remoteIdentifier!, genericMessage: confirmation)

        // when
        let note = ZMLocalNotification(event: event, conversation: oneOnOneConversation, managedObjectContext: uiMOC)

        // then
        XCTAssertNil(note)
    }

    // MARK: - Create system local notifications from update events

    func testThatItCreatesASystemLocalNotificationForRemovingTheSelfUserEvent() {
        // given
        let event = createMemberLeaveUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, users: [selfUser])
        var note: ZMLocalNotification?

        // when
        note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.title, "Super User")
        XCTAssertEqual(note?.body, "%1$@ removed you")

    }

    func testThatItCreatesASystemLocalNotificationForAddingTheSelfUserEvent() {
        // given
        let event = createMemberJoinUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!, users: [selfUser])
        var note: ZMLocalNotification?

        // when
        note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.title, "Super User")
        XCTAssertEqual(note?.body, "%1$@ added you")

    }

    func testThatItCreatesASystemLocalNotificationForMessageTimerUpdateEvent() {
        // given
        let event = createMessageTimerUpdateEvent(UUID.create(), conversationID: self.oneOnOneConversation.remoteIdentifier!)
        var note: ZMLocalNotification?

        // when
        note = ZMLocalNotification(event: event, conversation: self.oneOnOneConversation, managedObjectContext: self.syncMOC)

        // then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.body, "Someone set the message timer to 1 year")

    }
}
