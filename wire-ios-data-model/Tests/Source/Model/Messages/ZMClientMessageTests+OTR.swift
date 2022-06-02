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

import XCTest
@testable import WireDataModel

final class ClientMessageTests_OTR: BaseZMClientMessageTests {}

// MARK: - Payload creation
extension ClientMessageTests_OTR {

    func testThatCreatesEncryptedDataAndAddsItToGenericMessageAsBlob() {
        self.syncMOC.performGroupedBlockAndWait {
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            let firstClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let secondClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let selfClients = ZMUser.selfUser(in: self.syncMOC).clients
            let selfClient = ZMUser.selfUser(in: self.syncMOC).selfClient()
            let notSelfClients = selfClients.filter { $0 != selfClient }

            let nonce = UUID.create()
            let textMessage = GenericMessage(content: Text(content: self.textMessageRequiringExternalMessage(2)), nonce: nonce)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            // when
            guard let dataAndStrategy = textMessage.encryptForTransport(for: conversation)
            else { return XCTFail() }

            // then
            let createdMessage = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: dataAndStrategy.data)
            }

            XCTAssertEqual(createdMessage.hasBlob, true)
            let clientIds = createdMessage.recipients.flatMap { userEntry -> [Proteus_ClientId] in
                return (userEntry.clients).map { clientEntry -> Proteus_ClientId in
                    return clientEntry.client
                }
            }
            let clientSet = Set(clientIds)
            XCTAssertEqual(clientSet.count, 2 + notSelfClients.count)
            XCTAssertTrue(clientSet.contains(firstClient.clientId))
            XCTAssertTrue(clientSet.contains(secondClient.clientId))
            notSelfClients.forEach {
                XCTAssertTrue(clientSet.contains($0.clientId))
            }

            XCTAssertEqual(createdMessage.reportMissing.count, createdMessage.recipients.count)
        }
    }

    func testThatCorruptedClientsReceiveBogusPayload() {
        self.syncMOC.performGroupedBlockAndWait {

            // given
            let message = try! self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as! ZMClientMessage
            self.syncUser3Client1.failedToEstablishSession = true

            // when
            guard let dataAndStrategy = message.encryptForTransport() else {
                XCTFail()
                return
            }

            // then
            let createdMessage = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: dataAndStrategy.data)
            }
            guard let userEntry = createdMessage.recipients.first(where: { self.syncUser3.userId == $0.user }) else { return XCTFail() }

            XCTAssertEqual(userEntry.clients.count, 1)
            XCTAssertEqual(userEntry.clients.first?.text, ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8))
            XCTAssertFalse(self.syncUser3Client1.failedToEstablishSession)
            }
    }

    func testThatCorruptedClientsReceiveBogusPayloadWhenSentAsExternal() {
        self.syncMOC.performGroupedBlockAndWait {

            // given
            let messageRequiringExternal = self.textMessageRequiringExternalMessage(6)
            let message = try! self.syncConversation.appendText(content: messageRequiringExternal) as! ZMClientMessage
            self.syncUser3Client1.failedToEstablishSession = true

            // when
            guard let dataAndStrategy = message.encryptForTransport() else {
                XCTFail()
                return
            }

            // then
            let createdMessage = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: dataAndStrategy.data)
            }
            guard let userEntry = createdMessage.recipients.first(where: { self.syncUser3.userId == $0.user }) else { return XCTFail() }

            XCTAssertEqual(userEntry.clients.count, 1)
            XCTAssertEqual(userEntry.clients.first?.text, ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8))
            XCTAssertFalse(self.syncUser3Client1.failedToEstablishSession)
        }
    }

    func testThatItCreatesPayloadDataForTextMessage() {
        self.syncMOC.performGroupedBlockAndWait {

            // given
            let message = try! self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as! ZMClientMessage

            // when
            guard let payloadAndStrategy = message.encryptForTransport() else {
                XCTFail()
                return
            }

            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadDataForEphemeralTextMessage_Group() {
        self.syncMOC.performGroupedBlockAndWait {

            // given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let message = try! self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as! ZMClientMessage
            XCTAssertTrue(message.isEphemeral)

            // when
            guard let payloadAndStrategy = message.encryptForTransport() else { return XCTFail() }

            // then
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers, .ignoreAllMissingClients:
                XCTFail()
            default:
                break
            }
        }
    }

    func testThatItCreatesPayloadDataForDeletionOfEphemeralTextMessage_Group() {

        var syncMessage: ZMClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            syncMessage = try! self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            syncMessage.sender = self.syncUser1
            XCTAssertTrue(syncMessage.isEphemeral)
            self.syncMOC.saveOrRollback()
        }

        let uiMessage = self.uiMOC.object(with: syncMessage.objectID) as! ZMMessage
        uiMessage.startDestructionIfNeeded()
        XCTAssertNotNil(uiMessage.destructionDate)
        self.uiMOC.zm_teardownMessageDeletionTimer()
        self.uiMOC.saveOrRollback()

        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.refresh(syncMessage, mergeChanges: true)
            XCTAssertNotNil(syncMessage.destructionDate)

            let sut = syncMessage.deleteForEveryone()

            // when
            guard let payloadAndStrategy = sut?.encryptForTransport() else { return XCTFail() }

            // then
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(users: let users):
                XCTAssertEqual(users, Set(arrayLiteral: self.syncSelfUser, self.syncUser1))
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForDeletionOfEphemeralTextMessage_Group_SenderWasDeleted() {
        // This can happen due to a race condition where we receive a delete for an ephemeral after deleting the same message locally, but before creating the payload
        var syncMessage: ZMClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            syncMessage = try! self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            syncMessage.sender = self.syncUser1
            XCTAssertTrue(syncMessage.isEphemeral)
            self.syncMOC.saveOrRollback()
        }

        let uiMessage = self.uiMOC.object(with: syncMessage.objectID) as! ZMMessage
        uiMessage.startDestructionIfNeeded()
        XCTAssertNotNil(uiMessage.destructionDate)
        self.uiMOC.zm_teardownMessageDeletionTimer()
        self.uiMOC.saveOrRollback()

        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.refresh(syncMessage, mergeChanges: true)
            XCTAssertNotNil(syncMessage.destructionDate)

            let sut = syncMessage.deleteForEveryone()

            // when
            syncMessage.sender = nil
            var payload : (data: Data, strategy: MissingClientsStrategy)?
            self.performIgnoringZMLogError {
                 payload = sut?.encryptForTransport()
            }

            // then
            guard let payloadAndStrategy = payload else { return XCTFail() }
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(users: let users):
                XCTAssertEqual(users, Set(arrayLiteral: self.syncSelfUser))
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForZMLastReadMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.lastReadServerTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            guard let message = try? ZMConversation.updateSelfConversation(withLastReadOf: self.syncConversation) else { return XCTFail() }

            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]

            // when
            guard let payloadAndStrategy = message.encryptForTransport() else { return XCTFail() }

            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForZMClearedMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.clearedTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            guard let message = try? ZMConversation.updateSelfConversation(withClearedOf: self.syncConversation) else { return XCTFail() }

            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]

            // when
            guard let payloadAndStrategy = message.encryptForTransport() else { return XCTFail() }

            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
}

// MARK: - Delivery
extension ClientMessageTests_OTR {

    func testThatItCreatesPayloadDataForConfirmationMessage() {
        self.syncMOC.performGroupedBlockAndWait {

            // given
            let senderID = self.syncUser1.clients.first!.remoteIdentifier
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            conversation.connection = connection
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            self.syncMOC.saveOrRollback()

            let textMessage = try! conversation.appendText(content: self.stringLargeEnoughToRequireExternal, fetchLinkPreview: true, nonce: UUID.create()) as! ZMClientMessage

            textMessage.sender = self.syncUser1
            textMessage.senderClientID = senderID

            let genericMessage = GenericMessage(content: Confirmation(messageId: textMessage.nonce!, type: .delivered))
            let confirmationMessage = try? conversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)

            // when
            guard let payloadAndStrategy = confirmationMessage?.encryptForTransport()
            else { return XCTFail()}

            // then
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(let users):
                XCTAssertEqual(users, Set(arrayLiteral: self.syncUser1))
            default:
                XCTFail()
            }
            let messageMetadata = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: payloadAndStrategy.data)
            }

            let payloadClients = messageMetadata.recipients.compactMap { user -> [String] in
                return user.clients.map({ String(format: "%llx", $0.client.client) })
            }.flatMap { $0 }
            XCTAssertEqual(payloadClients.sorted(), self.syncUser1.clients.map { $0.remoteIdentifier! }.sorted())
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasSender() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let senderID = self.syncUser1.clients.first!.remoteIdentifier
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            conversation.connection = connection
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            self.syncMOC.saveOrRollback()

            let textMessage = try! conversation.appendText(content: self.stringLargeEnoughToRequireExternal, fetchLinkPreview: true, nonce: UUID.create()) as! ZMClientMessage

            textMessage.sender = self.syncUser1
            textMessage.senderClientID = senderID

            let confirmation = GenericMessage(content: Confirmation(messageId: textMessage.nonce!, type: .delivered))
            let confirmationMessage = try? conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)

            // when
            guard confirmationMessage?.encryptForTransport() != nil
                else { return XCTFail()}
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasNoSenderButInferSenderWithConnection() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            conversation.connection = connection

            let genericMessage = GenericMessage(content: Text(content: "yo"), nonce: UUID.create())
            let clientmessage = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            do {
                try clientmessage.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail()
            }
            clientmessage.visibleInConversation = conversation

            self.syncMOC.saveOrRollback()

            let confirmation = GenericMessage(content: Confirmation(messageId: clientmessage.nonce!, type: .delivered))
            let confirmationMessage = try? conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)

            // when
            guard confirmationMessage?.encryptForTransport() != nil
                else { return XCTFail()}
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasNoSenderAndConnectionButInferSenderOtherActiveParticipants() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            let genericMessage = GenericMessage(content: Text(content: "yo"), nonce: UUID.create())
            let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            do {
                try clientMessage.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail()
            }
            clientMessage.visibleInConversation = conversation

            self.syncMOC.saveOrRollback()

            let confirmation = GenericMessage(content: Confirmation(messageId: clientMessage.nonce!, type: .delivered))
            let confirmationMessage = try? conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)

            // when
            guard confirmationMessage?.encryptForTransport() != nil
                else { return XCTFail()}
        }
    }

}

// MARK: - Session identifier
extension ClientMessageTests_OTR {

    func testThatItUsesTheProperSessionIdentifier() {

        // GIVEN
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.remoteIdentifier = UUID.create()
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = user
        client.remoteIdentifier = UUID.create().transportString()

        // WHEN
        let identifier = client.sessionIdentifier

        // THEN
        XCTAssertEqual(identifier, EncryptionSessionIdentifier(userId: user.remoteIdentifier.uuidString, clientId: client.remoteIdentifier!))
    }
}

// MARK: - Helper
extension ClientMessageTests_OTR {

    /// Returns a string large enough to have to be encoded in an external message
    fileprivate var stringLargeEnoughToRequireExternal: String {
        var text = "Hello"
        while text.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessage.byteSizeExternalThreshold) {
            text.append(text)
        }
        return text
    }

    /// Asserts that the message metadata is as expected
    fileprivate func assertMessageMetadata(_ payload: Data!, file: StaticString = #file, line: UInt = #line) {
        let messageMetadata = Proteus_NewOtrMessage.with {
            try? $0.merge(serializedData: payload)
        }

        XCTAssertEqual(messageMetadata.sender.client, self.selfClient1.clientId.client, file: file, line: line)
        assertRecipients(messageMetadata.recipients, file: file, line: line)
    }

    /// Returns a string that is big enough to require external message payload
    fileprivate func textMessageRequiringExternalMessage(_ numberOfClients: UInt) -> String {
        var string = "Exponential growth!"
        while string.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessage.byteSizeExternalThreshold / numberOfClients) {
            string += string
        }
        return string
    }
}

extension DatabaseBaseTest {

    func createSelfUser(in moc: NSManagedObjectContext) -> (ZMUser, ZMConversation) {
        let selfUser = ZMUser.selfUser(in: moc)
        selfUser.remoteIdentifier = UUID()
        let conversation = ZMConversation.fetchOrCreate(with: selfUser.remoteIdentifier,
                                                        domain: nil,
                                                        in: moc)
        moc.saveOrRollback()
        return (selfUser, conversation)
    }

    func createSelfClient(on moc: NSManagedObjectContext) -> UserClient {
        let selfUser = ZMUser.selfUser(in: moc)

        let selfClient = UserClient.insertNewObject(in: moc)
        selfClient.remoteIdentifier = NSString.createAlphanumerical()
        selfClient.user = selfUser

        moc.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)

        let payload = ["id": selfClient.remoteIdentifier!,
                       "type": "permanent",
                       "time": Date().transportString()] as [String: AnyObject]
        _ = UserClient.createOrUpdateSelfUserClient(payload, context: moc)

        moc.saveOrRollback()
        return selfClient
    }
}
