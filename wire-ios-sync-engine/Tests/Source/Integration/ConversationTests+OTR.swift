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

import Foundation

class ConversationTestsOTR_Swift: ConversationTestsBase {
    func testThatItSendsFailedOTRMessageAfterMisingClientsAreFetchedButSessionIsNotCreated() {
        // GIVEN
        XCTAssertTrue(self.login())

        let conv = conversation(for: selfToUser1Conversation)

        mockTransportSession.responseGeneratorBlock = { [weak self] request -> ZMTransportResponse? in
            guard let `self` = self,
                let path = (request.path as NSString?),
                path.pathComponents.contains("prekeys") else { return nil }

            let payload: NSDictionary = [
                self.user1.identifier: [
                    (self.user1.clients.anyObject() as? MockUserClient)?.identifier: [
                        "id": 0,
                        "key": "invalid key".data(using: .utf8)!.base64String()
                    ]
                ]
            ]
           return ZMTransportResponse(payload: payload, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        // WHEN
        var message: ZMConversationMessage?
        mockTransportSession.resetReceivedRequests()
        performIgnoringZMLogError {
            self.userSession?.perform {
                message = try! conv?.appendText(content: "Hello World")
            }
            _ = self.waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        }

        // THEN
        let expectedPath = "/conversations/\(conv!.remoteIdentifier!.transportString())/otr"

        // then we expect it to receive a bomb message
        // when resending after fetching the (faulty) prekeys
        var messagesReceived = 0
        for request in mockTransportSession.receivedRequests() {
            guard request.path.hasPrefix(expectedPath), let data = request.binaryData else { continue }
            guard let otrMessage = try? Proteus_NewOtrMessage(serializedData: data) else { return XCTFail("otrMessage was nil") }

            let userEntries = otrMessage.recipients
            let clientEntry = userEntries.first?.clients.first
            if clientEntry?.text == "💣".data(using: .utf8) {
                messagesReceived += 1
            }
        }
        XCTAssertEqual(messagesReceived, 1)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)
    }

    func testThatItSendsFailedSessionOTRMessageAfterMissingClientsAreFetchedButSessionIsNotCreated() {
        // GIVEN
        XCTAssertTrue(self.login())

        let conv = conversation(for: selfToUser1Conversation)

        var message: ZMAssetClientMessage?

        mockTransportSession.responseGeneratorBlock = { [weak self] request -> ZMTransportResponse? in
            guard let `self` = self,
                let path = request.path as NSString?,
                path.pathComponents.contains("prekeys") else { return nil }
            let payload: NSDictionary = [
                self.user1.identifier: [
                    (self.user1.clients.anyObject() as? MockUserClient)?.identifier: [
                        "id": 0,
                        "key": "invalid key".data(using: .utf8)!.base64String()
                    ]
                ]
            ]
            return ZMTransportResponse(payload: payload, httpStatus: 201, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        }

        // WHEN
        mockTransportSession.resetReceivedRequests()
        performIgnoringZMLogError {
            self.userSession?.perform {
                message = try! conv?.appendImage(from: self.verySmallJPEGData(), nonce: NSUUID.create()) as? ZMAssetClientMessage
            }
            _ = self.waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        }

        // THEN
        let expectedPath = "/conversations/\(conv!.remoteIdentifier!.transportString())/otr/messages"

        // then we expect it to receive a bomb medium
        // when resending after fetching the (faulty) prekeys
        var bombsReceived = 0

        for request in mockTransportSession.receivedRequests() {
            guard request.path.hasPrefix(expectedPath), let data = request.binaryData else { continue }
            guard let otrMessage = try? Proteus_NewOtrMessage(serializedData: data) else { return XCTFail() }

            let userEntries = otrMessage.recipients
            let clientEntry = userEntries.first?.clients.first

            if clientEntry?.text == "💣".data(using: .utf8) {
                bombsReceived += 1
            }
        }

        XCTAssertEqual(bombsReceived, 1)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)
    }

    func testThatItAppendsOTRMessages() {
        // GIVEN

        let expectedText1 = "The sky above the port was the color of "
        let expectedText2 = "television, tuned to a dead channel."

        let nonce1 = UUID.create()
        let nonce2 = UUID.create()

        let genericMessage1 = GenericMessage(content: Text(content: expectedText1), nonce: nonce1)
        let genericMessage2 = GenericMessage(content: Text(content: expectedText2), nonce: nonce2)

        // WHEN
        testThatItAppendsMessage(
            to: groupConversation,
            with: { _ in
                guard
                    let user2Client = self.user2.clients.anyObject() as? MockUserClient,
                    let user3Client = self.user3.clients.anyObject() as? MockUserClient,
                    let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                    let data1 = try? genericMessage1.serializedData(),
                    let data2 = try? genericMessage2.serializedData() else {
                        XCTFail()
                        return []
                }

                self.groupConversation.encryptAndInsertData(from: user2Client, to: selfClient, data: data1)
                self.groupConversation.encryptAndInsertData(from: user3Client, to: selfClient, data: data2)

                return [nonce1, nonce2]
            }, verify: { conversation in

                // THEN
                // check that we successfully decrypted messages

                XCTAssert(conversation?.allMessages.count > 0)

                if conversation?.allMessages.count < 2 {
                    XCTFail("message count is too low")
                } else {
                    let lastMessages = conversation?.lastMessages(limit: 2) as? [ZMClientMessage]

                    let message1 = lastMessages?[1]
                    XCTAssertEqual(message1?.nonce, nonce1)
                    XCTAssertEqual(message1?.underlyingMessage?.text.content, expectedText1)

                    let message2 = lastMessages?[0]
                    XCTAssertEqual(message2?.nonce, nonce2)
                    XCTAssertEqual(message2?.underlyingMessage?.text.content, expectedText2)
                }
            }
        )
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
    }

    func testThatItDeliversOTRMessageIfNoMissingClients() {
        // GIVEN
        XCTAssertTrue(login())

        let messageText = "Hey!"
        var message: ZMClientMessage?
        let conversation = self.conversation(for: selfToUser1Conversation)

        userSession?.perform {
            message = try! conversation?.appendText(content: "Bonsoir, je voudrais un croissant", mentions: [], fetchLinkPreview: true, nonce: .create()) as? ZMClientMessage
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // WHEN
        userSession?.perform {
            message = try! conversation?.appendText(content: messageText, mentions: [], fetchLinkPreview: true, nonce: .create()) as? ZMClientMessage
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let lastEvent = selfToUser1Conversation.events.lastObject as? MockEvent
        XCTAssertEqual(lastEvent?.eventType, ZMUpdateEventType.conversationOtrMessageAdd)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)

        guard let data = lastEvent?.decryptedOTRData else {
            return XCTFail()
        }
        let genericMessage = try? GenericMessage(serializedData: data)
        XCTAssertEqual(genericMessage?.text.content, messageText)
    }

    func testThatItDeliversOTRMessageAfterMissingClientsAreFetched() {
        // GIVEN
        let messageText = "Hey!"
        var message: ZMClientMessage?

        XCTAssertTrue(login())

        let conversation = self.conversation(for: selfToUser1Conversation)

        // WHEN
        userSession?.perform {
            message = try! conversation?.appendText(content: messageText, mentions: [], fetchLinkPreview: true, nonce: .create()) as? ZMClientMessage
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let lastEvent = selfToUser1Conversation.events.lastObject as? MockEvent
        XCTAssertEqual(lastEvent?.eventType, ZMUpdateEventType.conversationOtrMessageAdd)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)

        guard let data = lastEvent?.decryptedOTRData else {
            return XCTFail()
        }
        let genericMessage = try? GenericMessage(serializedData: data)
        XCTAssertEqual(genericMessage?.text.content, messageText)
    }

    func testThatItOTRMessagesCanBeResentAndItIsMovedToTheEndOfTheConversation() {
        // GIVEN
        XCTAssertTrue(login())

        let defaultExpirationTime = ZMMessage.defaultExpirationTime()
        ZMMessage.setDefaultExpirationTime(0.3)

        mockTransportSession.doNotRespondToRequests = true

        let conversation = self.conversation(for: selfToUser1Conversation)

        var message: ZMClientMessage?

        // fail to send
        userSession?.perform {
            message = try! conversation?.appendText(content: "Where's everyone", mentions: [], fetchLinkPreview: true, nonce: .create()) as? ZMClientMessage
        }

        XCTAssertTrue(waitOnMainLoop(until: {
            return message?.isExpired ?? false
        }, timeout: 0.5))

        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.failedToSend)
        ZMMessage.setDefaultExpirationTime(defaultExpirationTime)
        mockTransportSession.doNotRespondToRequests = false
        Thread.sleep(forTimeInterval: 0.1) // advance timestamp

        // WHEN receiving a new message
        let otherUserMessageText = "Are you still there?"
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: Text(content: otherUserMessageText), nonce: .create())
            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? genericMessage.serializedData() else {
                    return XCTFail()
            }

            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let lastMessage = conversation?.lastMessage
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, otherUserMessageText)

        // WHEN resending
        userSession?.perform {
            message?.resend()
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        XCTAssertEqual(conversation?.lastMessage as? ZMMessage, message)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)
    }

    func testThatItSendsANotificationWhenRecievingAOtrMessageThroughThePushChannel() {
        // GIVEN
        XCTAssertTrue(login())

        let expectedText = "The sky above the port was the color of "
        let message = GenericMessage(content: Text(content: expectedText), nonce: .create())
        let conversation = self.conversation(for: groupConversation)

        // WHEN
        let observer = ConversationChangeObserver(conversation: conversation)
        observer?.clearNotifications()

        mockTransportSession.performRemoteChanges { _ in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let senderClient = self.user1.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: senderClient, to: selfClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let changes: [ConversationChangeInfo]? = observer?.notifications.compactMap({ $0 as? ConversationChangeInfo})
        let note = changes?.first(where: { $0.messagesChanged == true})

        XCTAssertNotNil(note)
        XCTAssertTrue(note?.messagesChanged ?? false)
        XCTAssertTrue(note?.lastModifiedDateChanged ?? false)

        let msg = conversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(msg?.underlyingMessage?.text.content, expectedText)
    }

    func testThatItSendsANotificationWhenReceivingAnOtrAssetMessageThroughThePushChannel(_ format: ZMImageFormat) {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)

        // WHEN
        let observer = ConversationChangeObserver(conversation: conversation)
        observer?.clearNotifications()
        remotelyInsertOTRImage(into: groupConversation, imageFormat: format)

        // THEN
        let changes: [ConversationChangeInfo]? = observer?.notifications.compactMap({ $0 as? ConversationChangeInfo})
        let note = changes?.first(where: { $0.messagesChanged == true})

        XCTAssertTrue(note?.messagesChanged ?? false)
        XCTAssertTrue(note?.lastModifiedDateChanged ?? false)
    }

    func testThatItSendsANotificationWhenReceivingAnOtrMediumAssetMessageThroughThePushChannel() {
        testThatItSendsANotificationWhenReceivingAnOtrAssetMessageThroughThePushChannel(.medium)
    }

    func testThatItSendsANotificationWhenReceivingAnOtrPreviewAssetMessageThroughThePushChannel() {
        testThatItSendsANotificationWhenReceivingAnOtrAssetMessageThroughThePushChannel(.preview)
    }

    func testThatItUnarchivesAnArchivedConversationWhenReceivingAnEncryptedMessage() {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)
        userSession?.perform {
            conversation?.isArchived = true
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        XCTAssertNotNil(conversation)
        XCTAssertTrue(conversation!.isArchived)

        // WHEN
        let message = GenericMessage(content: Text(content: "Foo"), nonce: .create())
        mockTransportSession.performRemoteChanges { _ in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let senderClient = self.user1.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: senderClient, to: selfClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        XCTAssertNotNil(conversation)
        XCTAssertFalse(conversation!.isArchived)
    }

    func testThatItCreatesAnExternalMessageIfThePayloadIsTooLargeAndAddsTheGenericMessageAsDataBlob() {
        // GIVEN
        var text = "Very Long Text!"

        while UInt(text.data(using: .utf8)!.count) < ZMClientMessage.byteSizeExternalThreshold {
            text.append(text)
        }

        XCTAssertTrue(login())

        // register other users clients
        let conversation = self.conversation(for: selfToUser1Conversation)
        var message: ZMClientMessage?

        // WHEN
        userSession?.perform {
            message = try! conversation?.appendText(content: text, mentions: [], fetchLinkPreview: true, nonce: .create()) as? ZMClientMessage
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let lastEvent = selfToUser1Conversation.events.lastObject as? MockEvent
        XCTAssertEqual(lastEvent?.eventType, ZMUpdateEventType.conversationOtrMessageAdd)
        XCTAssertEqual(message?.deliveryState, ZMDeliveryState.sent)

        guard let data = lastEvent?.decryptedOTRData else {
            return XCTFail()
        }
        let genericMessage = try? GenericMessage(serializedData: data)
        XCTAssertNotNil(genericMessage)
    }

    func testThatAssetMediumIsRedownloadedIfNothingIsStored(for useCase: AssetMediumTestUseCase) {
        // GIVEN
        XCTAssertTrue(login())

        var encryptedImageData = Data()
        let imagedata = verySmallJPEGData()
        let genericMessage = otrAssetGenericMessage(format: .medium, imageData: imagedata, encryptedData: &encryptedImageData)
        let assetId = UUID.create()

        mockTransportSession.performRemoteChanges { session in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let senderClient = self.user1.clients.anyObject() as? MockUserClient,
                let data = try? genericMessage.serializedData() else {
                    return XCTFail()
            }
            let messageData = MockUserClient.encrypted(data: data, from: senderClient, to: selfClient)
            self.groupConversation.insertOTRAsset(from: senderClient, to: selfClient, metaData: messageData, imageData: encryptedImageData, assetId: assetId, isInline: false)
            session.createAsset(with: encryptedImageData, identifier: assetId.transportString(), contentType: "", forConversation: self.groupConversation.identifier)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        let conversation = self.conversation(for: groupConversation)
        guard let assetMessage = conversation?.lastMessage as? ZMAssetClientMessage else {
            return XCTFail()
        }

        // WHEN
        switch useCase {
        case .cacheCleared:
            // remove all stored data, like cache is cleared
            userSession?.managedObjectContext.zm_fileAssetCache.deleteAssetData(assetMessage, format: .medium, encrypted: true)
        case .decryptionCrash:
            // remove decrypted data, but keep encrypted, like we crashed during decryption
           userSession?.managedObjectContext.zm_fileAssetCache.storeAssetData(assetMessage, format: .medium, encrypted: true, data: encryptedImageData)
        }
        userSession?.managedObjectContext.zm_fileAssetCache.deleteAssetData(assetMessage, format: .medium, encrypted: false)

        // We no longer process incoming V2 assets so we need to manually set some properties to simulate having received the asset
        userSession?.perform {
            assetMessage.version = 2
            assetMessage.assetId = assetId
        }

        // THEN
        XCTAssertNil(assetMessage.imageMessageData?.imageData)

        userSession?.perform {
            assetMessage.imageMessageData?.requestFileDownload()
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        XCTAssertNotNil(assetMessage.imageMessageData?.imageData)
    }

    func testThatAssetMediumIsRedownloadedIfNoDecryptedMessageDataIsStored() {
        testThatAssetMediumIsRedownloadedIfNothingIsStored(for: .decryptionCrash)
    }

    func testThatAssetMediumIsRedownloadedIfNoMessageDataIsStored() {
        testThatAssetMediumIsRedownloadedIfNothingIsStored(for: .cacheCleared)
    }

    // MARK: ConversationTestsOTR (Trust)
    func testThatItChangesTheSecurityLevelIfMessageArrivesFromPreviouslyUnknownUntrustedParticipant() {
        // GIVEN
        XCTAssertTrue(login())

        // register other users clients
        establishSession(with: user1)
        establishSession(with: user2)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // make conversation secure
        let conversation = self.conversation(for: groupConversationWithOnlyConnected)
        makeConversationSecured(conversation)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        XCTAssertEqual(conversation?.securityLevel, ZMConversationSecurityLevel.secure)

        // WHEN

        // silently add user to conversation
        performRemoteChangesExludedFromNotificationStream { _ in
            self.groupConversationWithOnlyConnected.addUsers(by: self.user1, addedUsers: [self.user5!])
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // send a message from silently added user
        mockTransportSession.performRemoteChanges { _ in
            let message = GenericMessage(content: Text(content: "Test 123"), nonce: .create())
            guard
                let mockSelfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let mockUser5Client = self.user5.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            let messageData = MockUserClient.encrypted(data: data, from: mockUser5Client, to: mockSelfClient)
            self.groupConversationWithOnlyConnected.insertOTRMessage(from: mockUser5Client, to: mockSelfClient, data: messageData)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        var containsParticipantAddedMessage = false
        var containsNewClientMessage = true
        for message in conversation!.lastMessages(limit: 50) {
            guard let systemMessageType = (message as? ZMSystemMessage)?.systemMessageData?.systemMessageType else {
                    continue
            }
            switch systemMessageType {
            case .participantsAdded:
                containsParticipantAddedMessage = true
            case .newClient:
                containsNewClientMessage = true
            default:
                break
            }
        }

        XCTAssertEqual(conversation?.securityLevel, ZMConversationSecurityLevel.secureWithIgnored)
        XCTAssertTrue(containsParticipantAddedMessage)
        XCTAssertTrue(containsNewClientMessage)
    }

    func testThatItChangesSecurityLevelToSecureWithIgnoredWhenOtherClientTriesToSendMessageAndDegradesConversation() {
        // GIVEN
        XCTAssertTrue(login())
        establishSession(with: user1)
        let conversation = self.conversation(for: selfToUser1Conversation)
        makeConversationSecured(conversation)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // WHEN
        let message = GenericMessage(content: Text(content: "Test"), nonce: .create())
        mockTransportSession.performRemoteChanges { session in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            let newClient = session.registerClient(for: self.user1)
            self.selfToUser1Conversation.encryptAndInsertData(from: newClient, to: selfClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let lastMessage = conversation?.lastMessages(limit: 10)[1] as? ZMSystemMessage
        XCTAssertEqual(conversation?.securityLevel, ZMConversationSecurityLevel.secureWithIgnored)
        XCTAssertEqual(conversation?.allMessages.count, 3) // 2x system message (secured & new client) + appended client message
        XCTAssertEqual(lastMessage?.systemMessageData?.systemMessageType, ZMSystemMessageType.newClient)
    }

    func checkThatItShouldInsertSecurityLevelSystemMessageAfterSendingMessage(
        shouldInsert: Bool,
        shouldChangeSecurityLevel: Bool,
        initialSecurityLevel: ZMConversationSecurityLevel,
        expectedSecurityLevel: ZMConversationSecurityLevel) {

        // GIVEN
        let expectedText = "The sky above the port was the color of "
        let message = GenericMessage(content: Text(content: expectedText), nonce: .create())

        XCTAssertTrue(login())

        establishSession(with: user1)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        let conversation = self.conversation(for: selfToUser1Conversation)

        setupInitialSecurityLevel(initialSecurityLevel, in: conversation)

        // WHEN        
        let previousMessageCount = conversation?.allMessages.count

        mockTransportSession.performRemoteChanges { session in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            let newUser1Client = session.registerClient(for: self.user1)
            self.selfToUser1Conversation.encryptAndInsertData(from: newUser1Client, to: selfClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN        
        XCTAssertEqual(conversation?.securityLevel, expectedSecurityLevel)

        let messageAddedCount = conversation!.allMessages.count - previousMessageCount!

        if shouldInsert {
            XCTAssertEqual(messageAddedCount, 2)
            let lastMessage = conversation?.lastMessages(limit: 10)[1] // second to last
            XCTAssertNotNil(lastMessage)

            guard let lastSystemMessage = lastMessage as? ZMSystemMessage else {
                return XCTFail()
            }

            let expectedUsers = [user(for: user1)]
            let users = Array(lastSystemMessage.users)

            assertArray(users, hasSameElementsAs: expectedUsers as [Any], name1: "users", name2: "expectedUsers", failureRecorder: ZMTFailureRecorder())
            XCTAssertEqual(lastSystemMessage.systemMessageType, ZMSystemMessageType.newClient)
        } else {
            XCTAssertEqual(messageAddedCount, 1) // only the added client message
        }
    }

    func testThatItInsertsNewClientSystemMessageWhenReceivingMessageFromNewClientInSecuredConversation() {
        checkThatItShouldInsertSecurityLevelSystemMessageAfterSendingMessage(
            shouldInsert: true,
            shouldChangeSecurityLevel: true,
            initialSecurityLevel: .secure,
            expectedSecurityLevel: .secureWithIgnored)
    }

    func testThatItInsertsNewClientSystemMessageWhenReceivingMessageFromNewClientInPartialSecureConversation() {
        checkThatItShouldInsertSecurityLevelSystemMessageAfterSendingMessage(
            shouldInsert: false,
            shouldChangeSecurityLevel: false,
            initialSecurityLevel: .secureWithIgnored,
            expectedSecurityLevel: .secureWithIgnored)
    }

    func testThatItDoesNotInsertNewClientSystemMessageWhenReceivingMessageFromNewClientInNotSecuredConversation() {
        checkThatItShouldInsertSecurityLevelSystemMessageAfterSendingMessage(
            shouldInsert: false,
            shouldChangeSecurityLevel: false,
            initialSecurityLevel: .notSecure,
            expectedSecurityLevel: .notSecure)
    }

    // MARK: - Unable to decrypt message
    func testThatItDoesNotInsertASystemMessageWhenItDecryptsADuplicatedMessage() {
        // GIVEN
        XCTAssertTrue(login())
        var conversation = self.conversation(for: selfToUser1Conversation)
        var firstMessageData = Data()
        let firstMessageText = "Testing duplication"

        // WHEN sending the first message
        let firstMessage = GenericMessage(content: Text(content: firstMessageText), nonce: .create())

        guard
            let mockSelfClient = selfUser.clients.anyObject() as? MockUserClient,
            let mockUser1Client = user1.clients.anyObject() as? MockUserClient,
            let data = try? firstMessage.serializedData() else {
                return XCTFail()
        }

        mockTransportSession.performRemoteChanges { _ in
            firstMessageData = MockUserClient.encrypted(data: data, from: mockUser1Client, to: mockSelfClient)
            self.selfToUser1Conversation.insertOTRMessage(from: mockUser1Client, to: mockSelfClient, data: firstMessageData)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let previousNumberOfMessages = conversation?.allMessages.count
        var lastMessage = conversation?.lastMessage
        XCTAssertNil(lastMessage?.systemMessageData)
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, firstMessageText)

        // Log out
        recreateSessionManager()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        performIgnoringZMLogError {
            // and when resending the same data (CBox should return DUPLICATED error)
            self.mockTransportSession.performRemoteChanges { _ in
                self.selfToUser1Conversation.insertOTRMessage(from: mockUser1Client, to: mockSelfClient, data: firstMessageData)
            }
            _ = self.waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        }

        // THEN
        conversation = self.conversation(for: selfToUser1Conversation)
        let newNumberOfMessages = conversation?.allMessages.count

        lastMessage = conversation?.lastMessage
        XCTAssertNil(lastMessage?.systemMessageData)
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, firstMessageText)
        XCTAssertEqual(newNumberOfMessages!, previousNumberOfMessages!)
    }

    enum AssetMediumTestUseCase {
        case cacheCleared
        case decryptionCrash
    }

    @discardableResult
    func remotelyInsertOTRImage(into conversation: MockConversation, imageFormat format: ZMImageFormat) -> GenericMessage {
        var encryptedImageData = Data()
        let imageData = self.verySmallJPEGData()
        let message = otrAssetGenericMessage(format: format, imageData: imageData, encryptedData: &encryptedImageData)

        mockTransportSession.performRemoteChanges { session in
            guard
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let senderClient = self.user1.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            let messageData = MockUserClient.encrypted(data: data, from: senderClient, to: selfClient)
            let assetId = UUID.create()
            session.createAsset(with: encryptedImageData, identifier: assetId.transportString(), contentType: "", forConversation: conversation.identifier)
            conversation.insertOTRAsset(from: senderClient, to: selfClient, metaData: messageData, imageData: encryptedImageData, assetId: assetId, isInline: format == .preview)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        return message
    }

    func otrAssetGenericMessage(format: ZMImageFormat, imageData: Data, encryptedData: inout Data) -> GenericMessage {
        let properties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")

        let otrKey = Data.randomEncryptionKey()
        encryptedData = imageData.zmEncryptPrefixingPlainTextIV(key: otrKey)

        let sha = encryptedData.zmSHA256Digest()

        let keys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha)
        let imageAsset = ImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: format)
        let message = GenericMessage(content: imageAsset, nonce: .create())
        return message
    }
}
