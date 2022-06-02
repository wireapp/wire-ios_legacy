//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class ClientMessageRequestStrategyTests: MessagingTestBase {

    var localNotificationDispatcher: MockPushMessageHandler!
    var sut: ClientMessageRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockAttachmentsDetector: MockAttachmentDetector!

    var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        syncMOC.performAndWait { [self] in
            localNotificationDispatcher = MockPushMessageHandler()
            mockApplicationStatus = MockApplicationStatus()
            mockApplicationStatus.mockSynchronizationState = .online
            mockAttachmentsDetector = MockAttachmentDetector()
            LinkAttachmentDetectorHelper.setTest_debug_linkAttachmentDetector(mockAttachmentsDetector)
            sut = ClientMessageRequestStrategy(withManagedObjectContext: syncMOC,
                                               localNotificationDispatcher: localNotificationDispatcher,
                                               applicationStatus: mockApplicationStatus)
        }

        apiVersion = .v0

    }

    override func tearDown() {
        self.localNotificationDispatcher = nil
        self.mockApplicationStatus = nil
        self.mockAttachmentsDetector = nil
        LinkAttachmentDetectorHelper.tearDown()
        self.sut = nil
        apiVersion = nil

        super.tearDown()
    }

    /// Makes a conversation secure
    func set(conversation: ZMConversation, securityLevel: ZMConversationSecurityLevel) {
        conversation.setValue(NSNumber(value: securityLevel.rawValue), forKey: #keyPath(ZMConversation.securityLevel))
        if conversation.securityLevel != securityLevel {
            fatalError()
        }
    }

}

// MARK: - Request generation

extension ClientMessageRequestStrategyTests {

    func testThatItDoesNotGenerateARequestIfSenderIsNotSelfUser() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            message.sender = self.otherUser
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            // THEN
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItUpdatesExpectsReadConfirmationFlagWhenSendingMessageInOneToOne() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = true
            let text = "Lorem ipsum"
            let message = try! self.oneToOneConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            if self.sut.nextRequest(for: self.apiVersion) == nil {
                XCTFail("Next request is nil")
                return
            }

            // THEN
            switch message.underlyingMessage?.content {
            case .text(let data)?:
                XCTAssertTrue(data.expectsReadConfirmation)
            default:
                XCTFail("Unexpected message content")
            }
        }
    }

    func testThatItDoesntUpdateExpectsReadConfirmationFlagWhenSendingMessageInGroup() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = true
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            if self.sut.nextRequest(for: self.apiVersion) == nil {
                XCTFail("Next request is nil")
                return
            }

            // THEN
            switch message.underlyingMessage?.content {
            case .text(let data)?:
                XCTAssertFalse(data.expectsReadConfirmation)
            default:
                XCTFail("Unexpected message content")
            }
        }
    }

    func testThatItUpdateExpectsReadConfirmationFlagWhenReadReceiptsAreDisabled() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).readReceiptsEnabled = false
            let text = "Lorem ipsum"
            let message = try! self.oneToOneConversation.appendText(content: text) as! ZMClientMessage
            var genericMessage = message.underlyingMessage!
            genericMessage.setExpectsReadConfirmation(true)
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            if self.sut.nextRequest(for: self.apiVersion) == nil {
                XCTFail("Next request is nil")
                return
            }

            // THEN
            XCTAssertFalse(message.underlyingMessage!.text.expectsReadConfirmation)
        }
    }

    func testThatItUpdatesLegalHoldStatusFlagWhenLegalHoldIsEnabled() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let legalHoldClient = UserClient.insertNewObject(in: self.syncMOC)
            legalHoldClient.deviceClass = .legalHold
            legalHoldClient.type = .legalHold
            legalHoldClient.user = self.otherUser

            let conversation = self.groupConversation!
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [self.otherUser])
            XCTAssertTrue(conversation.isUnderLegalHold)

            let text = "Lorem ipsum"
            let message = try! conversation.appendText(content: text) as! ZMClientMessage
            var genericMessage = message.underlyingMessage!
            genericMessage.setLegalHoldStatus(.disabled)
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            if self.sut.nextRequest(for: self.apiVersion) == nil {
                XCTFail("Next request is nil")
                return
            }

            // THEN
            XCTAssertEqual(message.underlyingMessage!.text.legalHoldStatus, .enabled)
        }
    }

    func testThatItUpdatesLegalHoldStatusFlagWhenLegalHoldIsDisabled() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let conversation = self.groupConversation!
            XCTAssertFalse(conversation.isUnderLegalHold)

            let text = "Lorem ipsum"
            let message = try! conversation.appendText(content: text) as! ZMClientMessage
            var genericMessage = message.underlyingMessage!
            genericMessage.setLegalHoldStatus(.enabled)
            do {
                try message.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            if self.sut.nextRequest(for: self.apiVersion) == nil {
                XCTFail("Next request is nil")
                return
            }

            // THEN
           XCTAssertEqual(message.underlyingMessage!.text.legalHoldStatus, .disabled)
        }
    }

    func testThatItGeneratesARequestToSendAClientMessage() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest(for: self.apiVersion) else {
                XCTFail("Request is nil")
                return
            }

            // THEN
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertNotNil(request.binaryData)
            XCTAssertEqual(request.binaryDataType, "application/x-protobuf")

            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertEqual(receivedMessage.textData?.content, text)
        }
    }

    func testThatItGeneratesARequestToSendAClientMessage_WithFederationEndpointEnabled() {
        apiVersion = .v1

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Lorem ipsum"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            let conversationID = self.groupConversation.remoteIdentifier!.transportString()
            let conversationDomain = self.groupConversation.domain!
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest(for: self.apiVersion) else {
                XCTFail("Request is nil")
                return
            }

            // THEN
            XCTAssertEqual(request.path, "/v1/conversations/\(conversationDomain)/\(conversationID)/proteus/messages")
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertNotNil(request.binaryData)
            XCTAssertEqual(request.binaryDataType, "application/x-protobuf")
        }
    }

    func testThatItGeneratesARequestToSendAClientMessageExternalWithExternalBlob() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = String(repeating: "Hi", count: 100000)
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            self.syncMOC.saveOrRollback()

            // WHEN
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest(for: self.apiVersion) else {
                XCTFail("Request is nil")
                return
            }

            // THEN
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertNotNil(request.binaryData)
            XCTAssertEqual(request.binaryDataType, "application/x-protobuf")

            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertTrue(receivedMessage.hasExternal)

            let key = receivedMessage.external.otrKey
            let sha = receivedMessage.external.sha256

            guard let protobuf = self.outgoingMessageWrapper(from: request) else {
                return XCTFail("protobuf is invalid")
            }
            XCTAssertTrue(protobuf.hasBlob)
            XCTAssertEqual(protobuf.blob.zmSHA256Digest(), sha)
            guard let decryptedBlob = protobuf.blob.zmDecryptPrefixedPlainTextIV(key: key) else { return XCTFail("Failed to decrypt blob") }
            let externalMessage = try? GenericMessage.init(serializedData: decryptedBlob)
            XCTAssertTrue(externalMessage?.textData?.content == text) // here I use == instead of XCTAssertEqual because the
            // warning generated by a failed comparison of a 200000-chars string almost freezes XCode
        }
    }

    func testThatItNotifiesAttachmentPrepocessorOfChanges() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = String(repeating: "Hi", count: 100000)
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage

            // WHEN
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }

            // THEN
            XCTAssertEqual(self.mockAttachmentsDetector.downloadCount, 1)
        }
    }

    func testThatItDeletesTheConfirmationMessageWhenSentSuccessfully() {

        // GIVEN
        var confirmationMessage: ZMMessage!
        self.syncMOC.performGroupedBlockAndWait {

            confirmationMessage = try! self.oneToOneConversation.appendClientMessage(with: GenericMessage(content: Confirmation(messageId: UUID(), type: .delivered)))
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }

            // WHEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { return XCTFail("Request is nil") }
            request.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(confirmationMessage.isZombieObject)
        }
    }

    func testThatItNotifiesWhenMessageCannotBeSent_MissingLegalholdConsent() {

        // GIVEN
        var confirmationMessage: ZMMessage!
        var token: Any?
        self.syncMOC.performGroupedBlockAndWait {

            confirmationMessage = try! self.oneToOneConversation.appendClientMessage(with: GenericMessage(content: Confirmation(messageId: UUID(), type: .delivered)))
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }

            let expectation = self.expectation(description: "Notification fired")
            token = NotificationInContext.addObserver(name: ZMConversation.failedToSendMessageNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: nil) {_ in
                expectation.fulfill()
            }

            // WHEN
            guard let request = self.sut.nextRequest(for: self.apiVersion) else { return XCTFail("Request is nil") }
            let payload = ["label": "missing-legalhold-consent", "code": 403, "message": ""] as NSDictionary
            request.complete(with: ZMTransportResponse(payload: payload, httpStatus: 403, transportSessionError: nil, apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        withExtendedLifetime(token) { () -> Void in
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

// MARK: - Processing events

extension ClientMessageRequestStrategyTests {

    func testThatANewOtrMessageIsCreatedFromAnEvent() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Everything"
            let base64Text = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
            let payload = [
                "recipient": self.selfClient.remoteIdentifier,
                "sender": self.otherClient.remoteIdentifier,
                "text": base64Text
            ]
            let eventPayload = [
                "type": "conversation.otr-message-add",
                "data": payload,
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
                "from": self.otherUser.remoteIdentifier.transportString()
                ] as NSDictionary
            guard let event = ZMUpdateEvent.decryptedUpdateEvent(fromEventStreamPayload: eventPayload, uuid: nil, transient: false, source: .webSocket) else {
                XCTFail("Failed to create event")
                return
            }

            // WHEN
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)

            // THEN
            XCTAssertEqual(self.groupConversation.lastMessage?.textMessageData?.messageText, text)
        }
    }

    func testThatANewOtrMessageIsCreatedFromADecryptedAPNSEvent() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Everything"
            let event = self.decryptedUpdateEventFromOtherClient(text: text)

            // WHEN
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)

            // THEN
            XCTAssertEqual((self.groupConversation.lastMessage as? ZMClientMessage)?.textMessageData?.messageText, text)
        }
    }

}
