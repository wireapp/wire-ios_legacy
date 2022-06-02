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

class ConversationTests_DeliveryConfirmation: ConversationTestsBase {

    func testThatItSendsADeliveryConfirmationWhenReceivingAMessageInAOneOnOneConversation() {
        // given
        XCTAssert(login())

        let fromClient = user1?.clients.anyObject() as! MockUserClient
        let toClient = selfUser?.clients.anyObject() as! MockUserClient
        let textMessage = GenericMessage(content: Text(content: "Hello"))
        let conversation = self.conversation(for: selfToUser1Conversation!)

        let requestPath = "/conversations/\(conversation!.remoteIdentifier!.transportString())/otr/messages"

        // expect
        mockTransportSession?.responseGeneratorBlock = { request in
            if request.path == requestPath {
                guard
                    let data = request.binaryData,
                    let otrMessage = try? Proteus_NewOtrMessage(serializedData: data)
                    else {
                        XCTFail("Expected OTR message")
                        return nil
                }

                XCTAssertEqual(otrMessage.recipients.count, 1)
                let recipient = try! XCTUnwrap(otrMessage.recipients.first)
                XCTAssertEqual(recipient.user, self.user(for: self.user1)!.userId)

                let encryptedData = recipient.clients.first!.text
                let decryptedData = MockUserClient.decryptMessage(data: encryptedData, from: toClient, to: fromClient)
                let genericMessage = try! GenericMessage(serializedData: decryptedData)
                XCTAssertEqual(genericMessage.confirmation.firstMessageID, textMessage.messageID)
            }
            return nil
        }

        // when
        mockTransportSession?.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation?.encryptAndInsertData(from: fromClient, to: toClient, data: try textMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(conversation?.allMessages.count, 1) // inserted message

        guard let request = mockTransportSession?.receivedRequests().last else {return XCTFail()}
        XCTAssertEqual((request as AnyObject).path, requestPath)

        XCTAssertEqual(conversation?.lastModifiedDate, conversation?.lastMessage?.serverTimestamp)
    }

    func testThatItSetsAMessageToDeliveredWhenReceivingADeliveryConfirmationMessageInAOneOnOneConversation() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: selfToUser1Conversation!)
        var message: ZMClientMessage!
        self.userSession?.perform {
            message = try! conversation?.appendText(content: "Hello") as? ZMClientMessage
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        let fromClient = user1?.clients.anyObject() as! MockUserClient
        let toClient = selfUser?.clients.anyObject() as! MockUserClient
        let confirmationMessage = GenericMessage(content: Confirmation(messageId: message.nonce!))

        // when
        mockTransportSession?.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation?.encryptAndInsertData(from: fromClient, to: toClient, data: try confirmationMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        // The confirmation message is not inserted
        XCTAssertEqual(conversation?.hiddenMessages.count, 0)
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.delivered)

        XCTAssertEqual(conversation?.lastModifiedDate, message.serverTimestamp)
    }

    func testThatItSendsANotificationWhenUpdatingTheDeliveryState() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: selfToUser1Conversation!)
        var message: ZMClientMessage!
        self.userSession?.perform {
            message = try! conversation?.appendText(content: "Hello") as? ZMClientMessage
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation?.hiddenMessages.count, 0)
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        let fromClient = user1!.clients.anyObject() as! MockUserClient
        let toClient = selfUser!.clients.anyObject() as! MockUserClient
        let confirmationMessage = GenericMessage(content: Confirmation(messageId: message.nonce!, type: .init()))

        let convObserver = ConversationChangeObserver(conversation: conversation)

        let messageObserver = MessageChangeObserver(message: message)

        // when
        mockTransportSession?.performRemoteChanges { _ in
            do {
                self.selfToUser1Conversation?.encryptAndInsertData(from: fromClient, to: toClient, data: try confirmationMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        if convObserver!.notifications.count > 0 {
            return XCTFail()
        }
        guard let messageChangeInfo = messageObserver?.notifications.firstObject  as? MessageChangeInfo else {
            return XCTFail()
        }
        XCTAssertTrue(messageChangeInfo.deliveryStateChanged)
    }
}
