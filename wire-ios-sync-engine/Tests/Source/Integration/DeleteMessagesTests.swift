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
import WireTesting

class DeleteMessagesTests: ConversationTestsBase {

    func testThatItCreatesARequestToSendADeletedMessageAndDeletesItLocallencrypty() {
        // given
        XCTAssertTrue(login())
        var message: ZMConversationMessage! = nil

        userSession?.perform {
            guard let conversation = self.conversation(for: self.selfToUser1Conversation) else {return XCTFail()}
            message = try! conversation.appendText(content: "Hello")
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(message)

        // when
        mockTransportSession.resetReceivedRequests()
        userSession?.perform {
            ZMMessage.deleteForEveryone(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 1)
        guard let request = requests.first else { return XCTFail() }
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
        XCTAssertEqual(request.path, "/conversations/\(selfToUser1Conversation.identifier)/otr/messages")
        XCTAssertTrue(message.hasBeenDeleted)
    }

    func testThatItDeletesAMessageIfItIsDeletedRemotelyByTheSender() {
        // given
        XCTAssertTrue(login())

        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient
        let textMessage = GenericMessage(content: Text(content: "Hello"))

        // when
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: try textMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let conversation = self.conversation(for: selfToUser1Conversation) else {return XCTFail()}
        XCTAssertEqual(conversation.allMessages.count, 1) // inserted message

        guard let message = conversation.lastMessage as? ZMClientMessage, message.textMessageData?.messageText == "Hello" else { return XCTFail() }
        let genericMessage = GenericMessage(content: MessageDelete(messageId: message.nonce!))

        // when
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(message.hasBeenDeleted)
        XCTAssertEqual(conversation.allMessages.count, 1) // System message
        XCTAssertNotEqual(conversation.lastMessages().last as? ZMClientMessage, message)
        guard let systemMessage = conversation.lastMessage as? ZMSystemMessage else { return XCTFail() }
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageType.messageDeletedForEveryone)
    }

    func testThatItDoesNotDeleteAMessageIfItIsDeletedRemotelyBySomeoneElse() {
        // given
        XCTAssertTrue(login())

        let firstClient = user1.clients.anyObject() as! MockUserClient
        let secondClient = user2.clients.anyObject() as! MockUserClient
        let selfClient = selfUser.clients.anyObject() as! MockUserClient
        let textMessage = GenericMessage(content: Text(content: "Hello"))

        // when
        self.mockTransportSession.performRemoteChanges { _ in
            do {
                self.groupConversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try textMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let conversation = self.conversation(for: self.groupConversation) else {return XCTFail()}
        XCTAssertEqual(conversation.allMessages.count, 2) // system message & inserted message
        guard let message = conversation.lastMessage, message.textMessageData?.messageText == "Hello" else { return XCTFail() }

        let genericMessage = GenericMessage(content: MessageDelete(messageId: message.nonce!))

        self.mockTransportSession.performRemoteChanges { _ in
            do {
                self.groupConversation.encryptAndInsertData(from: secondClient, to: selfClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(message.hasBeenDeleted)
        XCTAssertEqual(conversation.allMessages.count, 2) // system message & inserted message
        XCTAssertEqual(conversation.lastMessage as? ZMMessage, message as? ZMMessage)
    }

    func testThatItRetriesToSendADeletedMessageIfItCouldNotBeSentBefore() {
        // given
        XCTAssertTrue(login())
        var message: ZMConversationMessage! = nil

        userSession?.perform {
            guard let conversation = self.conversation(for: self.selfToUser1Conversation) else {return XCTFail()}
            message = try! conversation.appendText(content: "Hello")
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(message)

        // when
        mockTransportSession.resetReceivedRequests()
        var requestCount = 0

        mockTransportSession.responseGeneratorBlock = { request in
            guard request.path == "/conversations/\(self.selfToUser1Conversation.identifier)/otr/messages" else { return nil }
            if requestCount < 4 {
                requestCount += 1
                return ZMTransportResponse(transportSessionError: NSError.tryAgainLaterError() as Error, apiVersion: APIVersion.v0.rawValue)
            }

            return nil
        }

        userSession?.perform {
            ZMMessage.deleteForEveryone(message)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let requests = mockTransportSession.receivedRequests()
        XCTAssertEqual(requests.count, 5)
        XCTAssertEqual(requestCount, 4)
        guard let request = requests.last else { return XCTFail() }
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
        XCTAssertEqual(request.path, "/conversations/\(selfToUser1Conversation.identifier)/otr/messages")
        XCTAssertTrue(message.hasBeenDeleted)
    }

    func testThatItNotifiesTheObserverIfAMessageGetsDeletedRemotely() {
        // given
        XCTAssertTrue(login())

        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient
        let textMessage = GenericMessage(content: Text(content: "Hello"))

        // when
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: try textMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        guard let conversation = self.conversation(for: selfToUser1Conversation) else {return XCTFail()}

        // then
        XCTAssertEqual(conversation.allMessages.count, 1) // inserted message

        guard let message = conversation.lastMessage as? ZMClientMessage, message.textMessageData?.messageText == "Hello" else { return XCTFail() }
        let genericMessage = GenericMessage(content: MessageDelete(messageId: message.nonce!))

        // when
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(message.hasBeenDeleted)
        XCTAssertEqual(conversation.allMessages.count, 1) // system message
    }

}
