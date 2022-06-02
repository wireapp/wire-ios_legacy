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
@testable import WireDataModel

class ZMClientMessageTests_Editing: BaseZMClientMessageTests {

    func testThatItEditsTheMessage() throws {
        // GIVEN
        let conversationID = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = conversationID

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        let message = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        message.sender = user

        try message.setUnderlyingMessage(GenericMessage(content: Text(content: "text")))

        conversation.append(message)

        let edited = MessageEdit.with {
            $0.replacingMessageID = nonce.transportString()
            $0.text = Text(content: "editedText")
        }

        let genericMessage = GenericMessage(content: edited)

        let updateEvent = createUpdateEvent(nonce, conversationID: conversationID, genericMessage: genericMessage, senderID: message.sender!.remoteIdentifier)

        // WHEN
        var editedMessage: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            editedMessage = ZMClientMessage.editMessage(withEdit: edited, forConversation: conversation, updateEvent: updateEvent, inContext: self.uiMOC, prefetchResult: ZMFetchRequestBatchResult())
        }

        // THEN
        XCTAssertEqual(editedMessage?.messageText, "editedText")
    }
}

class ZMClientMessageTests_TextMessageData: BaseZMClientMessageTests {

    func testThatItUpdatesTheMesssageText_WhenEditing() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: "hello") as! ZMClientMessage
        message.delivered = true

        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)

        // then
        XCTAssertEqual(message.textMessageData?.messageText, "good bye")
    }

    func testThatItClearReactions_WhenEditing() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: "hello") as! ZMClientMessage
        message.delivered = true
        message.addReaction("🤠", forUser: selfUser)
        XCTAssertFalse(message.reactions.isEmpty)

        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)

        // then
        XCTAssertTrue(message.reactions.isEmpty)
    }

    func testThatItKeepsQuote_WhenEditing() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let quotedMessage = try! conversation.appendText(content: "Let's grab some lunch") as! ZMClientMessage
        let message = try! conversation.appendText(content: "Yes!", replyingTo: quotedMessage) as! ZMClientMessage
        message.delivered = true
        XCTAssertTrue(message.hasQuote)

        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)

        // then
        XCTAssertTrue(message.hasQuote)
    }

}

// MARK: - Payload creation
extension ZMClientMessageTests_Editing {

    private func checkThatItCanEditAMessageFrom(sameSender: Bool, shouldEdit: Bool) {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let sender = sameSender
            ? self.selfUser
            : ZMUser.insertNewObject(in: self.uiMOC)

        if !sameSender {
            sender?.remoteIdentifier = UUID.create()
        }

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMClientMessage
        message.sender = sender
        message.markAsSent()
        message.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
        let originalNonce = message.nonce

        XCTAssertEqual(message.visibleInConversation, conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertEqual(conversation.hiddenMessages.count, 0)

        // when
        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: true)

        // then

        XCTAssertEqual(conversation.allMessages.count, 1)

        if shouldEdit {
            XCTAssertEqual(message.textMessageData?.messageText, newText)
            XCTAssertEqual(message.normalizedText, newText.lowercased())
            XCTAssertEqual(message.underlyingMessage?.edited.replacingMessageID, originalNonce!.transportString())
            XCTAssertNotEqual(message.nonce, originalNonce)
        } else {
            XCTAssertEqual(message.textMessageData?.messageText, oldText)
        }
    }

    func testThatItCanEditAMessage_SameSender() {
        checkThatItCanEditAMessageFrom(sameSender: true, shouldEdit: true)
    }

    func testThatItCanNotEditAMessage_DifferentSender() {
        checkThatItCanEditAMessageFrom(sameSender: false, shouldEdit: false)
    }

    func testThatExtremeCombiningCharactersAreRemovedFromTheMessage() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()

        // WHEN
        let message: ZMMessage = try! conversation.appendText(content: "ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂") as! ZMMessage

        // THEN
        XCTAssertEqual(message.textMessageData?.messageText, "test̻̟̙")
    }

    func testThatItResetsTheLinkPreviewState() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMClientMessage
        message.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
        message.linkPreviewState = ZMLinkPreviewState.done
        message.markAsSent()

        XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.done)

        // when
        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: true)

        // then
        XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.waitingToBeProcessed)
    }

    func testThatItDoesNotFetchLinkPreviewIfExplicitlyToldNotTo() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"

        let fetchLinkPreview = false
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText, mentions: [], fetchLinkPreview: fetchLinkPreview, nonce: UUID.create()) as! ZMClientMessage
        message.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
        message.markAsSent()

        XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.done)

        // when
        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: fetchLinkPreview)

        // then
        XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewState.done)
    }

    func testThatItDoesNotEditAMessageThatFailedToSend() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message: ZMMessage = try! conversation.appendText(content: oldText) as! ZMMessage
        message.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
        message.expire()
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)

        // when
        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: true)

        // then
        XCTAssertEqual(message.textMessageData?.messageText, oldText)
    }

    func testThatItUpdatesTheUpdatedTimestampAfterSuccessfulUpdate() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let originalDate = Date.init(timeIntervalSinceNow: -50)
        let updateDate: Date = Date.init(timeIntervalSinceNow: -20)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMMessage
        message.serverTimestamp = originalDate
        message.markAsSent()

        conversation.lastModifiedDate = originalDate
        conversation.lastServerTimeStamp = originalDate

        XCTAssertEqual(message.visibleInConversation, conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertEqual(conversation.hiddenMessages.count, 0)

        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: false)

        // when
        message.update(withPostPayload: ["time": updateDate], updatedKeys: nil)

        // then
        XCTAssertEqual(message.serverTimestamp, originalDate)
        XCTAssertEqual(message.updatedAt, updateDate)
        XCTAssertEqual(message.textMessageData?.messageText, newText)
    }

    func testThatItDoesNotOverwritesEditedTextWhenMessageExpiresButReplacesNonce() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let originalDate = Date.init(timeIntervalSinceNow: -50)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMMessage
        message.serverTimestamp = originalDate
        message.markAsSent()

        conversation.lastModifiedDate = originalDate
        conversation.lastServerTimeStamp = originalDate
        let originalNonce = message.nonce

        XCTAssertEqual(message.visibleInConversation, conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertEqual(conversation.hiddenMessages.count, 0)

        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: false)

        // when
        message.expire()

        // then
        XCTAssertEqual(message.nonce, originalNonce)
    }

    func testThatWhenResendingAFailedEditItReappliesTheEdit() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let originalDate = Date.init(timeIntervalSinceNow: -50)

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message: ZMClientMessage = try! conversation.appendText(content: oldText) as! ZMClientMessage
        message.serverTimestamp = originalDate
        message.markAsSent()

        conversation.lastModifiedDate = originalDate
        conversation.lastServerTimeStamp = originalDate
        let originalNonce = message.nonce

        XCTAssertEqual(message.visibleInConversation, conversation)
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertEqual(conversation.hiddenMessages.count, 0)

        message.textMessageData?.editText(newText, mentions: [], fetchLinkPreview: false)
        let editNonce1 = message.nonce

        message.expire()

        // when
        message.resend()
        let editNonce2 = message.nonce

        // then
        XCTAssertFalse(message.isExpired)
        XCTAssertNotEqual(editNonce2, editNonce1)
        XCTAssertEqual(message.underlyingMessage?.edited.replacingMessageID, originalNonce?.transportString())
    }

    private func createMessageEditUpdateEvent(oldNonce: UUID, newNonce: UUID, conversationID: UUID, senderID: UUID, newText: String) -> ZMUpdateEvent? {
        let genericMessage: GenericMessage = GenericMessage(content: MessageEdit(replacingMessageID: oldNonce, text: Text(content: newText, mentions: [], linkPreviews: [], replyingTo: nil)), nonce: newNonce)

        let data = try? genericMessage.serializedData().base64String()
        let payload: NSMutableDictionary = [
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": Date().transportString(),
            "data": [
                "text": data ?? ""
            ],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: UUID.create())
    }

    private func createTextAddedEvent(nonce: UUID, conversationID: UUID, senderID: UUID) -> ZMUpdateEvent? {
        let genericMessage: GenericMessage = GenericMessage(content: Text(content: "Yeah!", mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce)

        let data = try? genericMessage.serializedData().base64String()
        let payload: NSMutableDictionary = [
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": Date().transportString(),
            "data": [
                "text": data ?? ""
            ],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: UUID.create())
    }

    func testThatItEditsMessageWithQuote() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let senderID = self.selfUser.remoteIdentifier

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let quotedMessage = try! conversation.appendText(content: "Quote") as! ZMMessage
        let message = try! conversation.appendText(content: oldText,
                                          mentions: [],
                                          replyingTo: quotedMessage,
                                          fetchLinkPreview: false,
                                          nonce: UUID.create()) as! ZMMessage
        self.uiMOC.saveOrRollback()

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!, newNonce: UUID.create(), conversationID: conversation.remoteIdentifier!, senderID: senderID!, newText: newText)

        let oldNonce = message.nonce

        // when
        self.performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertEqual(message.textMessageData?.messageText, newText)
        XCTAssertTrue(message.textMessageData!.hasQuote)
        XCTAssertNotEqual(message.nonce, oldNonce)
        XCTAssertEqual(message.textMessageData?.quoteMessage as! ZMMessage, quotedMessage)
    }

    func testThatReadExpectationIsKeptAfterEdit() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let senderID = self.selfUser.remoteIdentifier

        self.selfUser.readReceiptsEnabled = true

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = ZMConversationType.oneOnOne

        let message = try! conversation.appendText(content: oldText, mentions: [], fetchLinkPreview: false, nonce: UUID.create()) as! ZMClientMessage
        var genericMessage = message.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)

        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail()
        }

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!, newNonce: UUID.create(), conversationID: conversation.remoteIdentifier!, senderID: senderID!, newText: newText)
        let oldNonce = message.nonce

        // when
        self.performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertEqual(message.textMessageData?.messageText, newText)
        XCTAssertNotEqual(message.nonce, oldNonce)
        XCTAssertTrue(message.needsReadConfirmation)
    }

    func checkThatItEditsMessageFor(sameSender: Bool, shouldEdit: Bool) {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let senderID = sameSender
            ? self.selfUser.remoteIdentifier
            : UUID.create()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMMessage

        message.addReaction("👻", forUser: self.selfUser)
        self.uiMOC.saveOrRollback()

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!, newNonce: UUID.create(), conversationID: conversation.remoteIdentifier!, senderID: senderID!, newText: newText)
        let oldNonce = message.nonce

        // when
        self.performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        if shouldEdit {
            XCTAssertEqual(message.textMessageData?.messageText, newText)
            XCTAssertNotEqual(message.nonce, oldNonce)
            XCTAssertTrue(message.reactions.isEmpty)
            XCTAssertEqual(message.visibleInConversation, conversation)
            XCTAssertNil(message.hiddenInConversation)
        } else {
            XCTAssertEqual(message.textMessageData?.messageText, oldText)
            XCTAssertEqual(message.nonce, oldNonce)
            XCTAssertEqual(message.visibleInConversation, conversation)
            XCTAssertNil(message.hiddenInConversation)
        }
    }

    func testThatEditsMessageWhenSameSender() {
        checkThatItEditsMessageFor(sameSender: true, shouldEdit: true)
    }

    func testThatDoesntEditMessageWhenSenderIsDifferent() {
        checkThatItEditsMessageFor(sameSender: false, shouldEdit: false)
    }

    func testThatItDoesNotInsertAMessageWithANonceBelongingToAHiddenMessage() {
        // given
        let oldText = "Hallo"
        let senderID = self.selfUser.remoteIdentifier

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMMessage
        message.visibleInConversation = nil
        message.hiddenInConversation = conversation

        let updateEvent = createTextAddedEvent(nonce: message.nonce!, conversationID: conversation.remoteIdentifier!, senderID: senderID!)

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(newMessage)
    }

    func testThatItSetsTheTimestampsOfTheOriginalMessage() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let oldDate = Date.init(timeIntervalSinceNow: -20)
        let sender = ZMUser.insertNewObject(in: self.uiMOC)
        sender.remoteIdentifier = UUID.create()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: oldText) as! ZMMessage
        message.sender = sender
        message.serverTimestamp = oldDate

        conversation.lastModifiedDate = oldDate
        conversation.lastServerTimeStamp = oldDate
        conversation.lastReadServerTimeStamp = oldDate
        XCTAssertEqual(conversation.estimatedUnreadCount, 0)

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!, newNonce: UUID.create(), conversationID: conversation.remoteIdentifier!, senderID: sender.remoteIdentifier, newText: newText)

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertEqual(conversation.lastModifiedDate, oldDate)
        XCTAssertEqual(conversation.lastServerTimeStamp, oldDate)
        XCTAssertEqual(newMessage?.serverTimestamp, oldDate)
        XCTAssertEqual(newMessage?.updatedAt, updateEvent!.timestamp)

        XCTAssertEqual(conversation.estimatedUnreadCount, 0)
    }

    func testThatItDoesNotReinsertAMessageThatHasBeenPreviouslyHiddenLocally() {
        // given
        let oldText = "Hallo"
        let newText = "Hello"
        let oldDate = Date.init(timeIntervalSinceNow: -20)
        let sender = ZMUser.insertNewObject(in: self.uiMOC)
        sender.remoteIdentifier = UUID.create()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()

        // insert message locally
        let message: ZMMessage = try! conversation.appendText(content: oldText) as! ZMMessage
        message.sender = sender
        message.serverTimestamp = oldDate

        // hide message locally
        ZMMessage.hideMessage(message)
        XCTAssertTrue(message.isZombieObject)

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!, newNonce: UUID.create(), conversationID: conversation.remoteIdentifier!, senderID: sender.remoteIdentifier, newText: newText)

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(newMessage)
        XCTAssertNil(message.visibleInConversation)
        XCTAssertTrue(message.isZombieObject)
        XCTAssertTrue(message.hasBeenDeleted)
        XCTAssertNil(message.textMessageData)
        XCTAssertNil(message.sender)
        XCTAssertNil(message.senderClientID)

        let clientMessage = message as! ZMClientMessage
        XCTAssertNil(clientMessage.underlyingMessage)
        XCTAssertEqual(clientMessage.dataSet.count, 0)
    }

    func testThatItClearsReactionsWhenAMessageIsEdited() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message: ZMMessage = try! conversation.appendText(content: "Hallo") as! ZMMessage

        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.remoteIdentifier = UUID.create()

        message.addReaction("😱", forUser: self.selfUser)
        message.addReaction("🤗", forUser: otherUser)

        XCTAssertFalse(message.reactions.isEmpty)

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!,
                                                       newNonce: UUID.create(),
                                                       conversationID: conversation.remoteIdentifier!,
                                                       senderID: message.sender!.remoteIdentifier!,
                                                       newText: "Hello")

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertTrue(message.reactions.isEmpty)
        XCTAssertEqual(conversation.allMessages.count, 1)

        let editedMessage = conversation.lastMessage as! ZMMessage
        XCTAssertTrue(editedMessage.reactions.isEmpty)
        XCTAssertEqual(editedMessage.textMessageData?.messageText, "Hello")
    }

    func testThatItClearsReactionsWhenAMessageIsEditedRemotely() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message: ZMMessage = try! conversation.appendText(content: "Hallo") as! ZMMessage

        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.remoteIdentifier = UUID.create()

        message.addReaction("😱", forUser: self.selfUser)
        message.addReaction("🤗", forUser: otherUser)

        XCTAssertFalse(message.reactions.isEmpty)

        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!,
                                                       newNonce: UUID.create(),
                                                       conversationID: conversation.remoteIdentifier!,
                                                       senderID: message.sender!.remoteIdentifier,
                                                       newText: "Hello")

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertTrue(message.reactions.isEmpty)
        let editedMessage = conversation.lastMessage as! ZMMessage
        XCTAssertTrue(editedMessage.reactions.isEmpty)
        XCTAssertEqual(editedMessage.textMessageData?.messageText, "Hello")
    }

    func testThatMessageNonPersistedIdentifierDoesNotChangeAfterEdit() {
        // given
        let oldText = "Mamma mia"
        let newText = "here we go again"
        let oldNonce = UUID.create()

        let sender = ZMUser.insertNewObject(in: self.uiMOC)
        sender.remoteIdentifier = UUID.create()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let message: ZMMessage = try! conversation.appendText(content: oldText) as! ZMMessage
        message.sender = sender
        message.nonce = oldNonce

        let oldIdentifier = message.nonpersistedObjectIdentifer
        let updateEvent = createMessageEditUpdateEvent(oldNonce: message.nonce!,
                                                       newNonce: UUID.create(),
                                                       conversationID: conversation.remoteIdentifier!,
                                                       senderID: message.sender!.remoteIdentifier!,
                                                       newText: newText)

        // when
        var newMessage: ZMClientMessage?
        self.performPretendingUiMocIsSyncMoc {
            newMessage = ZMClientMessage.createOrUpdate(from: updateEvent!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotEqual(oldNonce, newMessage!.nonce)
        XCTAssertEqual(oldIdentifier, newMessage!.nonpersistedObjectIdentifer)
    }
}
