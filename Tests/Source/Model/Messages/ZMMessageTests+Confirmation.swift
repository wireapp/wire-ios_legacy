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

import ZMTesting

class ZMMessageTests_Confirmation: BaseZMClientMessageTests {

    override func setUp() {
        super.setUp()
        XCTAssertNotNil(self.uiMOC.globalManagedObjectContextObserver)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    override func tearDown() {
        self.uiMOC.globalManagedObjectContextObserver.tearDown()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        super.tearDown()
    }
}

// MARK: - Adding confirmation locally
extension ZMMessageTests_Confirmation {
    
    func checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(_ conversationType: ZMConversationType, shouldSendConfirmation: Bool){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = conversationType
        
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // other user sends confirmation
        let sut = insertMessage(conversation)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.firstObject as? ZMClientMessage, sut.message)
        
        if shouldSendConfirmation {
            XCTAssertTrue(sut.needsConfirmation)
        }
        else {
            XCTAssertFalse(sut.needsConfirmation)
        }
    }
    
    func testThatIt_Inserts_AConfirmationMessageWhenItReceivesAMessageInA_OneOnOne_Conversation(){
        checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(.oneOnOne, shouldSendConfirmation:true)
    }
    
    func testThatIt_DoesNotInsert_AConfirmationMessageWhenItReceivesAMessageInA_Group_Conversation(){
        checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(.group, shouldSendConfirmation:false)
    }
    
    func testThatItDoesNotRequiresAConfirmationMessageIfTheMessageWasSentByTheSelfUser(){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // selfuser sends confirmation
        let sut = insertMessage(conversation, fromSender: selfUser)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.firstObject as? ZMClientMessage, sut.message)
        XCTAssertFalse(sut.needsConfirmation)
    }
}

// MARK: - Deletion
extension ZMMessageTests_Confirmation {
    
    func testThatItCanDeleteAMessageThatWasConfirmed() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        message.markAsSent()
        let confirmationUpdate = createMessageConfirmationUpdateEvent(message.nonce, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: confirmationUpdate, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(uiMOC.saveOrRollback())
        
        guard let confirmation = message.confirmations?.first else {
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
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        let remoteUser = ZMUser.insertNewObject(in: self.uiMOC)
        remoteUser.remoteIdentifier = .create()
        
        // when
        let sut = insertMessage(conversation, fromSender: remoteUser)
        let _ = sut.message?.confirmReception()
        // then
        XCTAssertTrue(sut.needsConfirmation)
        guard let hiddenMessage = conversation.hiddenMessages.lastObject as? ZMClientMessage else {
            XCTFail("Did not insert confirmation message.")
            return
        }
        
        XCTAssertTrue(hiddenMessage.genericMessage!.hasConfirmation())
        // when
        
        sut.message!.removePendingDeliveryReceipts()
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversation.hiddenMessages.count, 0)
    }

}

// MARK: - Receiving confirmation remotely
extension ZMMessageTests_Confirmation {

    func testThatItUpdatesTheConfirmationStatusWhenItRecievesAConfirmationMessage(){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
    
        let sut = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier!)
        var messageUpdateResult : MessageUpdateResult?
        performPretendingUiMocIsSyncMoc {
            messageUpdateResult = ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(sut.confirmations.count, 1)
        XCTAssertNil(messageUpdateResult);
        guard let sender = ZMUser.fetch(withRemoteIdentifier: updateEvent.senderUUID()!, in: uiMOC),
              let confirmation = sut.confirmations.first
        else { return XCTFail() }
        
        XCTAssertEqual(confirmation.user, sender)
        XCTAssertNotEqual(confirmation.user, sut.sender)
        XCTAssertEqual(confirmation.message, sut)
        XCTAssertEqual(confirmation.type, MessageConfirmationType.delivered)

        // A confirmation should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }
    
    func testThatItUpdatesTheDeliveryStatusOfAMessage(){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        
        let sut = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.sent)

        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.delivered)
    }
    
     func testThatItDoesNotUpdateTheDeliveryStatusOfAMessageIfTheSenderIsNotTheSelfUser(){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        
        let sut = insertMessage(conversation)
        
        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.message!.nonce, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotEqual(sut.message!.deliveryState, ZMDeliveryState.delivered)
    }
    
    func testThatItSendsOutNotificationsForTheDeliveryStatusChange(){
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        let sut = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let convObserver = ConversationChangeObserver(conversation: conversation)
        let messageObserver = MessageChangeObserver(message: sut)
        defer {
            convObserver.tearDown()
            messageObserver.tearDown()
        }
        
        // when
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        if convObserver.notifications.count > 0 {
            return XCTFail()
        }
        guard let messageChangeInfo = messageObserver.notifications.firstObject  as? MessageChangeInfo else {
            return XCTFail()
        }
        XCTAssertTrue(messageChangeInfo.deliveryStateChanged)
    }
    
    func testThatAMessageConfirmationDoesNotExpire() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage

        // when
        let sut = message.confirmReception()!
        
        // then
        XCTAssertNil(sut.expirationDate)
    }
}

// MARK: - Helpers
extension ZMMessageTests_Confirmation {
    
    func insertMessage(_ conversation: ZMConversation, fromSender: ZMUser? = nil, moc: NSManagedObjectContext? = nil, eventSource: ZMUpdateEventSource = .download) -> MessageUpdateResult {
        let nonce = UUID.create()
        let genericMessage = ZMGenericMessage(text: "foo", nonce: nonce.transportString())
        let messageEvent = createUpdateEvent(nonce, conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: fromSender?.remoteIdentifier ?? UUID.create(), eventSource: eventSource)
        
        var messageUpdateResult : MessageUpdateResult!
        let MOC = moc ?? uiMOC

        if MOC.zm_isUserInterfaceContext {
            performPretendingUiMocIsSyncMoc {
                messageUpdateResult = ZMClientMessage.messageUpdateResult(from: messageEvent, in: MOC, prefetchResult: nil)
            }
        }
        else {
            messageUpdateResult = ZMClientMessage.messageUpdateResult(from: messageEvent, in: MOC, prefetchResult: nil)

        }
        XCTAssertTrue(MOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        return messageUpdateResult
    }
    
    func createMessageConfirmationUpdateEvent(_ nonce: UUID, conversationID: UUID, senderID: UUID = .create()) -> ZMUpdateEvent {
        let genericMessage = ZMGenericMessage(confirmation: nonce.transportString(), type: .DELIVERED, nonce: UUID.create().transportString())
        return createUpdateEvent(nonce, conversationID: conversationID, genericMessage: genericMessage, senderID: senderID)
    }
    
}
