//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@testable import WireDataModel

class ZMMessageTests_Confirmation: BaseZMClientMessageTests {
}

// MARK: - Sending confirmation messages

extension ZMMessageTests_Confirmation {

    // MARK: Read receipts

    func testThatMessageExpectsReadConfirmation_InAGroup_WhenConversationHasReadReceiptsEnabled() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.hasReadReceiptsEnabled = true

        // when
        let message = insertMessage(conversation, fromSender: user, timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertTrue(message.expectsReadConfirmation)
        XCTAssertTrue(message.needsReadConfirmation)
    }

    func testThatMessageDoesntExpectReadConfirmation_InAGroup_WhenConversationHasReadReceiptsDisabled() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.hasReadReceiptsEnabled = false

        // when
        let message = insertMessage(conversation, fromSender: user, timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertFalse(message.expectsReadConfirmation)
        XCTAssertFalse(message.needsReadConfirmation)
    }

    func testThatMessageDoesntExpectReadConfirmation_InAGroup_ForMessagesSentBySelfUser() {
        // given
        let conversation = createConversation(in: uiMOC)
        conversation.hasReadReceiptsEnabled = true

        // when
        let message = insertMessage(conversation, fromSender: ZMUser.selfUser(in: uiMOC), timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertFalse(message.expectsReadConfirmation)
        XCTAssertFalse(message.needsReadConfirmation)
    }

    func testThatMessageDoesntExpectReadConfirmation_InAOneToOne__WhenConversationHasReadReceiptsEnabled() {
        // given
        let conversation = createConversation(in: uiMOC)
        conversation.hasReadReceiptsEnabled = true
        conversation.conversationType = .oneOnOne

        // when
        let message = insertMessage(conversation, fromSender: ZMUser.selfUser(in: uiMOC), timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertFalse(message.expectsReadConfirmation)
    }

    func testThatMessageNeedsReadConfirmation_InAOneToOne_WhenSelfUserHasReadReceiptsEnabled() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.conversationType = .oneOnOne

        // insert message which expects read confirmation
        let message = insertMessage(conversation, fromSender: user, timestamp: Date()) as! ZMClientMessage
        var genericMessage = message.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)

        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        // when
        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true

        // then
        XCTAssertTrue(message.needsReadConfirmation)
    }

    func testThatMessageDoesntNeedsReadConfirmation_InAOneToOne_WhenSelfUserHasReadReceiptsDisabled() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.conversationType = .oneOnOne

        // insert message which expects read confirmation
        let message = insertMessage(conversation, fromSender: user, timestamp: Date()) as! ZMClientMessage
        var genericMessage = message.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)

        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        // when
        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = false

        // then
        XCTAssertFalse(message.needsReadConfirmation)
    }

    func testThatMessageDoesntNeedsReadConfirmation_InAOneToOne_WhenSelfUserHasReadReceiptsEnabledButMessageDoesntExpectReadConfirmation() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.conversationType = .oneOnOne

        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true

        // insert message which doesn't expect read confirmation
        let message = insertMessage(conversation, fromSender: user, timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertFalse(message.needsReadConfirmation)
    }

    func testThatCompositeMessage_NeedsReadConfirmation_WhenItExpectsAReadConfirmation() {
        // given
        let user = createUser(in: uiMOC)
        let conversation = createConversation(in: uiMOC)
        conversation.conversationType = .oneOnOne

        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true

        let content = Composite.with {
            $0.expectsReadConfirmation = true
        }

        let message = insertMessage(conversation, content: content, fromSender: user, timestamp: Date()) as! ZMClientMessage

        // then
        XCTAssertTrue(message.needsReadConfirmation)
    }

}

// MARK: - Deletion
extension ZMMessageTests_Confirmation {

    func testThatItCanDeleteAMessageThatWasConfirmed() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let message = try! conversation.appendText(content: "foo") as! ZMClientMessage
        message.markAsSent()
        let confirmationUpdate = createMessageDeliveryConfirmationUpdateEvent(message.nonce!, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: confirmationUpdate, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(uiMOC.saveOrRollback())

        guard let confirmation = message.confirmations.first else {
            XCTFail()
            return
        }

        // when
        self.uiMOC.delete(message)
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertNil(confirmation.managedObjectContext) // this will detect if it was deleted
    }

    func testThatItDeletesConfirmationsPendingForDeletedMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne

        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified

        let remoteUser = ZMUser.insertNewObject(in: self.uiMOC)
        remoteUser.remoteIdentifier = .create()

        // when
        let sut = insertMessage(conversation, fromSender: remoteUser)
        let confirmation = GenericMessage(content: Confirmation(messageId: sut.nonce!, type: .delivered))
        _ = try? conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)

        // then
        guard let hiddenMessage = conversation.hiddenMessages.first as? ZMClientMessage else {
            XCTFail("Did not insert confirmation message.")
            return
        }

        XCTAssertTrue(hiddenMessage.underlyingMessage?.hasConfirmation == true)
        // when

        sut.removePendingDeliveryReceipts()
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversation.hiddenMessages.count, 0)
    }

    func testThatItDeletesConfirmationsForDeletedMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.hasReadReceiptsEnabled = true

        let remoteUser = ZMUser.insertNewObject(in: self.uiMOC)
        remoteUser.remoteIdentifier = .create()

        let textMessage = insertMessage(conversation, fromSender: selfUser)
        let confirmation = ZMMessageConfirmation(type: .read, message: textMessage, sender: remoteUser, serverTimestamp: Date(), managedObjectContext: uiMOC)
        textMessage.mutableSetValue(forKey: "confirmations").add(confirmation)

        XCTAssertEqual(textMessage.confirmations.count, 1)
        // when
        textMessage.hideForSelfUser()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(textMessage.confirmations.count, 0)
        XCTAssertNil(confirmation.managedObjectContext)
    }

    func testThatItDeletesConfirmationsForDeletedForEveryoneMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.hasReadReceiptsEnabled = true

        let remoteUser = ZMUser.insertNewObject(in: self.uiMOC)
        remoteUser.remoteIdentifier = .create()

        let textMessage = insertMessage(conversation, fromSender: selfUser)
        let confirmation = ZMMessageConfirmation(type: .read, message: textMessage, sender: remoteUser, serverTimestamp: Date(), managedObjectContext: uiMOC)
        textMessage.mutableSetValue(forKey: "confirmations").add(confirmation)

        XCTAssertEqual(textMessage.confirmations.count, 1)
        // when
        textMessage.deleteForEveryone()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(textMessage.confirmations.count, 0)
        XCTAssertNil(confirmation.managedObjectContext)
    }

    func testThatItKeepsConfirmationsForObfuscatedMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.hasReadReceiptsEnabled = true

        let remoteUser = ZMUser.insertNewObject(in: self.uiMOC)
        remoteUser.remoteIdentifier = .create()

        let textMessage = insertMessage(conversation, fromSender: selfUser)
        let confirmation = ZMMessageConfirmation(type: .read, message: textMessage, sender: remoteUser, serverTimestamp: Date(), managedObjectContext: uiMOC)
        textMessage.mutableSetValue(forKey: "confirmations").add(confirmation)

        XCTAssertEqual(textMessage.confirmations.count, 1)
        // when
        textMessage.obfuscate()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(textMessage.confirmations.count, 1)
        XCTAssertNotNil(confirmation.managedObjectContext)
    }
}

// MARK: - Receiving confirmation messages

extension ZMMessageTests_Confirmation {

    // MARK: Read receipts

    func testThatItUpdatesTheDeliveryStatus_WhenItReceivesReadConfirmation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends confirmation
        let updateEvent = createMessageReadConfirmationUpdateEvent([sut.nonce!], conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.read)
    }

    func testThatItAddsDeliveryReceipt_WhenItReceivesReadConfirmation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends read confirmation
        let updateEvent = createMessageReadConfirmationUpdateEvent([sut.nonce!], conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.readReceipts.count, 1)
        XCTAssertEqual(sut.readReceipts.first?.user.remoteIdentifier, updateEvent.senderUUID)
    }

    func testThatItAddsDeliveryReceipt_WhenItReceivesMultipleReadConfirmations() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let messsage1 = try! conversation.appendText(content: "foo") as! ZMClientMessage
        messsage1.markAsSent()
        let messsage2 = try! conversation.appendText(content: "foo") as! ZMClientMessage
        messsage2.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(messsage1.deliveryState, ZMDeliveryState.sent)
        XCTAssertEqual(messsage2.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends read confirmation
        let updateEvent = createMessageReadConfirmationUpdateEvent([messsage1.nonce!, messsage2.nonce!], conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(messsage1.readReceipts.count, 1)
        XCTAssertEqual(messsage1.readReceipts.first?.user.remoteIdentifier, updateEvent.senderUUID)
        XCTAssertEqual(messsage2.readReceipts.count, 1)
        XCTAssertEqual(messsage2.readReceipts.first?.user.remoteIdentifier, updateEvent.senderUUID)
    }

    func testThatItDeliveryReceiptsAreOrdedByTimestamp_WhenItReceivesReadConfirmation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends read confirmation
        let timestamp1 = Date(timeIntervalSince1970: 0)
        let timestamp2 = Date(timeIntervalSince1970: 1)
        let timestamp3 = Date(timeIntervalSince1970: 2)

        let updateEvent1 = createMessageReadConfirmationUpdateEvent([sut.nonce!], conversationID: conversation.remoteIdentifier!, timestamp: timestamp2)
        let updateEvent2 = createMessageReadConfirmationUpdateEvent([sut.nonce!], conversationID: conversation.remoteIdentifier!, timestamp: timestamp1)
        let updateEvent3 = createMessageReadConfirmationUpdateEvent([sut.nonce!], conversationID: conversation.remoteIdentifier!, timestamp: timestamp3)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent1, in: self.uiMOC, prefetchResult: nil)
            ZMOTRMessage.createOrUpdate(from: updateEvent2, in: self.uiMOC, prefetchResult: nil)
            ZMOTRMessage.createOrUpdate(from: updateEvent3, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.readReceipts.count, 3)
        XCTAssertEqual(sut.readReceipts.map(\.serverTimestamp), [timestamp1, timestamp2, timestamp3])
    }

    // MARK: Delivery receipts

    func testThatItUpdatesTheDeliveryStatus_WhenItReceivesDeliveryConfirmation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends confirmation
        let updateEvent = createMessageDeliveryConfirmationUpdateEvent(sut.nonce!, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.delivered)
    }

}

// MARK: - Change notifications

extension ZMMessageTests_Confirmation {

    func testThatItDoesNotUpdateTheDeliveryStatus_WhenTheSenderIsNotTheSelfUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let sut = insertMessage(conversation)

        // when
        // other user sends confirmation
        let updateEvent = createMessageDeliveryConfirmationUpdateEvent(sut.nonce!, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotEqual(sut.deliveryState, ZMDeliveryState.delivered)
    }

    func testThatItSendsOutNotificationsForTheDeliveryStatusChange() {
        // given
        let dispatcher = NotificationDispatcher(managedObjectContext: uiMOC)

        defer {
            dispatcher.tearDown()
        }

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        conversation.addParticipantAndUpdateConversationState(user: sender, role: nil)
        conversation.remoteIdentifier = .create()
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified

        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let convObserver = ConversationObserver(conversation: conversation)
        var messageObserver: MessageObserver!
        self.performIgnoringZMLogError {
            messageObserver = MessageObserver(message: sut)
        }

        // when
        let updateEvent = createMessageDeliveryConfirmationUpdateEvent(
            sut.nonce!,
            conversationID: conversation.remoteIdentifier!, senderID: sender.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        if convObserver.notifications.count > 0 {
            return XCTFail()
        }
        guard let messageChangeInfo = messageObserver.notifications.first else {
            return XCTFail()
        }
        XCTAssertTrue(messageChangeInfo.deliveryStateChanged)
    }

}

// MARK: - Helpers
extension ZMMessageTests_Confirmation {

    func insertMessage(_ conversation: ZMConversation,
                       content: MessageCapable = Text(content: "foo"),
                       fromSender: ZMUser? = nil,
                       timestamp: Date = .init(),
                       moc: NSManagedObjectContext? = nil,
                       eventSource: ZMUpdateEventSource = .download) -> ZMMessage {

        let nonce = UUID.create()
        let genericMessage = GenericMessage(content: content, nonce: nonce)
        let messageEvent = createUpdateEvent(
            nonce,
            conversationID: conversation.remoteIdentifier!,
            timestamp: timestamp,
            genericMessage: genericMessage,
            senderID: fromSender?.remoteIdentifier ?? UUID.create(),
            eventSource: eventSource
        )

        var message: ZMMessage!
        let MOC = moc ?? uiMOC

        if MOC.zm_isUserInterfaceContext {
            performPretendingUiMocIsSyncMoc {
                message = ZMOTRMessage.createOrUpdate(from: messageEvent, in: self.uiMOC, prefetchResult: nil)
            }
        }
        else {
            message = ZMOTRMessage.createOrUpdate(from: messageEvent, in: MOC, prefetchResult: nil)

        }
        XCTAssertTrue(MOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        return message
    }

    func createMessageDeliveryConfirmationUpdateEvent(_ nonce: UUID, conversationID: UUID, senderID: UUID = .create(), timestamp: Date = .init()) -> ZMUpdateEvent {
        let genericMessage = GenericMessage(content: Confirmation(messageId: nonce, type: .delivered))
        return createUpdateEvent(UUID(), conversationID: conversationID, timestamp: timestamp, genericMessage: genericMessage, senderID: senderID)
    }

    func createMessageReadConfirmationUpdateEvent(_ nonces: [UUID], conversationID: UUID, senderID: UUID = .create(), timestamp: Date = .init()) -> ZMUpdateEvent {
        let genericMessage = GenericMessage(content: Confirmation(messageIds: nonces, type: .read)!)
        return createUpdateEvent(UUID(), conversationID: conversationID, timestamp: timestamp, genericMessage: genericMessage, senderID: senderID)
    }

}
