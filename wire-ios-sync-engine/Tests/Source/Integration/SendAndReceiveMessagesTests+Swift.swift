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
@testable import WireSyncEngine

class SendAndReceiveMessagesTests_Swift: ConversationTestsBase {

    private func uniqueText() -> String {
        return "This is a test for \(self.name): \(UUID.create())"
    }

    func testThatWeReceiveAMessageSentRemotely() {
        // given
        let messageText = self.uniqueText()
        XCTAssertTrue(self.login())
        let conversation = self.conversation(for: self.groupConversation)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            let message = GenericMessage(content: Text(content: messageText, mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.groupConversation.encryptAndInsertData(from: self.user1.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastMessage = conversation!.lastMessage!
        XCTAssertEqual(lastMessage.textMessageData?.messageText, messageText)
    }

    func testThatItDoesNotSyncTheLastReadOfMessagesThatHaveNotBeenDeliveredYet() {
        // given
        XCTAssertTrue(self.login())

        let count = 0
        let insertMessage = {
            let text = "text \(count)"
            let message = GenericMessage(content: Text(content: text, mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.groupConversation.encryptAndInsertData(from: self.user1.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }

        self.mockTransportSession.performRemoteChanges { (_) in
            (0..<4).forEach { _ in
                insertMessage()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        let conversation = self.conversation(for: self.groupConversation)
        let convIDString = conversation?.remoteIdentifier?.transportString()

        self.mockTransportSession.responseGeneratorBlock = { request in
            if request.path.contains("messages") && request.method == ZMTransportRequestMethod.methodPOST {
                if request.path.contains(convIDString!) {
                    return ZMTransportResponse.init(transportSessionError: NSError.requestExpiredError(), apiVersion: APIVersion.v0.rawValue)
                }
            }
            return nil
        }

        // when
        let previousMessage = conversation?.lastMessage!

        var failedToSendMessage: ZMMessage?
        self.userSession?.perform {
            failedToSendMessage = try! conversation?.appendText(content: "test") as? ZMMessage
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        XCTAssertEqual(failedToSendMessage!.deliveryState, ZMDeliveryState.failedToSend)

        conversation?.markMessagesAsRead(until: failedToSendMessage!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertNotNil(conversation!.lastReadServerTimeStamp)
        XCTAssertNotEqual(conversation!.lastReadServerTimeStamp!.timeIntervalSince1970, failedToSendMessage!.serverTimestamp!.timeIntervalSince1970, accuracy: 0.01)
        XCTAssertEqual(conversation!.lastReadServerTimeStamp!.timeIntervalSince1970, previousMessage!.serverTimestamp!.timeIntervalSince1970, accuracy: 0.01)
    }

    func testThatItAppendsClientMessages() {
        let expectedText1 = "The sky above the port was the color of "
        let expectedText2 = "television, tuned to a dead channel."

        let nonce1 = UUID.create()
        let nonce2 = UUID.create()

        let genericMessage1 = GenericMessage(content: Text(content: expectedText1, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce1)
        let genericMessage2 = GenericMessage(content: Text(content: expectedText2, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce2)

        self.testThatItAppendsMessage(to: self.groupConversation, with: { (_) -> [UUID]? in
            self.groupConversation.insertClientMessage(from: self.user2, data: try! genericMessage1.serializedData())
            self.spinMainQueue(withTimeout: 0.2)
            self.groupConversation.insertClientMessage(from: self.user3, data: try! genericMessage2.serializedData())
            return [nonce1, nonce2]
        }, verify: { (conversation) in
            let msg1 = conversation?.lastMessages(limit: 50)[1] as! ZMClientMessage
            XCTAssertEqual(msg1.nonce, nonce1, "msg1 timestamp \(String(describing: msg1.serverTimestamp?.timeIntervalSince1970))")
            XCTAssertEqual(msg1.underlyingMessage?.text.content, expectedText1)

            let msg2 = conversation?.lastMessages(limit: 50)[0] as! ZMClientMessage
            XCTAssertEqual(msg2.nonce, nonce2, "msg2 timestamp \(String(describing: msg2.serverTimestamp?.timeIntervalSince1970))")
            XCTAssertEqual(msg2.underlyingMessage?.text.content, expectedText2)

        })
    }

    func testThatItSendsANotificationWhenReceivingATextMessageThroughThePushChannel() {
        let expectedText = "The sky above the port was the color of "
        let nonce = UUID.create()

        self.testThatItSendsANotification(in: self.groupConversation, ignoreLastRead: false, onRemoteMessageCreatedWith: {
            let message = GenericMessage(content: Text(content: expectedText, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce)
            self.groupConversation.encryptAndInsertData(from: self.user2.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }, verify: { (conversation) in
            let msg = conversation?.lastMessage
            XCTAssertEqual(msg?.textMessageData?.messageText, expectedText)
        })
    }

    func testThatItSendsANotificationWhenRecievingAClientMessageThroughThePushChannel() {
        let expectedText = "The sky above the port was the color of "
        let message = GenericMessage(content: Text(content: expectedText, mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())

        self.testThatItSendsANotification(in: self.groupConversation, ignoreLastRead: false, onRemoteMessageCreatedWith: {
            self.groupConversation.insertClientMessage(from: self.user2, data: try! message.serializedData())
        }, verify: { (conversation) in
            let msg = conversation?.lastMessage as! ZMClientMessage
            XCTAssertEqual(msg.underlyingMessage?.text.content, expectedText)
        })
    }

    func testThatSystemMessageIsAddedIfClientWasInactiveAndCantFetchAnyNotifications() {
        // given
        XCTAssertTrue(self.login())
        let groupConversation = self.conversation(for: self.groupConversation)

        // when
        simulateNotificationStreamInterruption()

        // then
        XCTAssertEqual(groupConversation?.lastMessage?.systemMessageData?.systemMessageType, .potentialGap)
    }

    func testThatSystemMessageIsAddedIfClientWasInactiveAndCantFetchAllNotifications() {
        // given
        XCTAssertTrue(self.login())

        let groupConversation = self.conversation(for: self.groupConversation)
        let messageText = UUID().uuidString
        let fromClient = self.user2.clients.anyObject() as! MockUserClient

        // when
        simulateNotificationStreamInterruption(changesAfterInterruption: { (_) in
            self.remotelyInsert(text: messageText, from: fromClient, into: self.groupConversation)
        })

        // then
        let lastMessages = groupConversation!.lastMessages(limit: 50)
        XCTAssertEqual(lastMessages[1].systemMessageData?.systemMessageType, .potentialGap)
        XCTAssertEqual(lastMessages[0].textMessageData?.messageText, messageText)
    }

    func testThatPotentialGapSystemMessageContainsAddedAndRemovedUsers() {
        // given
        XCTAssertTrue(self.login())

        // when
        simulateNotificationStreamInterruption(changesBeforeInterruption: { _ in
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.user1)
            self.groupConversation.addUsers(by: self.user2, addedUsers: [self.user4!])
        })

        // then
        let conversation = self.conversation(for: self.groupConversation)
        let systemMessage = conversation?.lastMessage as! ZMSystemMessage

        let addedUser = self.user(for: self.user4)
        let removedUser = self.user(for: self.user1)

        XCTAssertEqual(conversation!.localParticipants.count, 4)
        XCTAssertEqual(systemMessage.users.count, 4)
        XCTAssertEqual(systemMessage.addedUsers.count, 1)
        XCTAssertEqual(systemMessage.removedUsers.count, 1)
        XCTAssertEqual(systemMessage.addedUsers.first?.objectID, addedUser?.objectID)
        XCTAssertEqual(systemMessage.removedUsers.first?.objectID, removedUser?.objectID)
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageType.potentialGap)
        XCTAssertFalse(systemMessage.needsUpdatingUsers)
    }

    func testThatPreviousPotentialGapSystemMessageGetsDeletedAndNewOneUpdatesWithOldUsers() {
        // given
        XCTAssertTrue(self.login())
        let conversation = self.conversation(for: self.groupConversation)
        XCTAssertNotNil(conversation)

        // when
        simulateNotificationStreamInterruption(changesBeforeInterruption: { _ in
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.user1)
            self.groupConversation.addUsers(by: self.user2, addedUsers: [self.user4!])
        })

        // then
        let systemMessage = conversation?.lastMessage as! ZMSystemMessage
        XCTAssertEqual(systemMessage.users.count, 4)
        XCTAssertFalse(systemMessage.needsUpdatingUsers)

        // when
        simulateNotificationStreamInterruption(changesBeforeInterruption: { _ in
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.user3)
            self.groupConversation.addUsers(by: self.user2, addedUsers: [self.user1!, self.user5!])
        })

        // then
        let secondSystemMessage = conversation?.lastMessage as! ZMSystemMessage
        XCTAssertNotEqual(systemMessage, secondSystemMessage)

        let addedUsers = [self.user(for: self.user4), self.user(for: self.user5)]
        let initialUsers = [self.user(for: self.selfUser),
                            self.user(for: self.user3),
                            self.user(for: self.user2),
                            self.user(for: self.user1)]
        let removedUser = self.user(for: self.user3)

        XCTAssertEqual(conversation!.localParticipants.count, 5)
        XCTAssertEqual(secondSystemMessage.users, Set(initialUsers))
        XCTAssertEqual(secondSystemMessage.addedUsers.count, 2)
        XCTAssertEqual(secondSystemMessage.removedUsers.count, 1)
        XCTAssertEqual(secondSystemMessage.addedUsers, Set(addedUsers))
        XCTAssertEqual(secondSystemMessage.removedUsers.first?.objectID, removedUser!.objectID)
        XCTAssertEqual(secondSystemMessage.systemMessageType, ZMSystemMessageType.potentialGap)
        XCTAssertFalse(secondSystemMessage.needsUpdatingUsers)
    }

    func testThatPotentialGapSystemMessageGetsUpdatedWithAddedUserWhenUserNameIsFetched() {
        // given
        XCTAssertTrue(self.login())
        var conversation = self.conversation(for: self.groupConversation)

        // when
        // adding new user to conversation
        var newMockUser: MockUser?
        simulateNotificationStreamInterruption(changesBeforeInterruption: { (session) in
            newMockUser = session.insertUser(withName: "Bruno")
            self.groupConversation.addUsers(by: self.user2, addedUsers: [newMockUser!])
        })

        conversation = self.conversation(for: self.groupConversation)
        let systemMessage = conversation?.lastMessage as! ZMSystemMessage

        let addedUser = systemMessage.addedUsers.first

        // then
        // after fetching it should contain the full users
        XCTAssertEqual(systemMessage.users.count, 4)
        XCTAssertEqual(systemMessage.removedUsers.count, 0)
        XCTAssertEqual(systemMessage.addedUsers.count, 1)
        XCTAssertNotNil(addedUser)
        XCTAssertEqual(addedUser!.name, "Bruno")
        XCTAssertFalse(systemMessage.needsUpdatingUsers)
    }
}

// MARK: Hiding messages

extension SendAndReceiveMessagesTests_Swift {
    func testThatItSyncsWhenAMessageHideIsRemotelyAppended() {
        // given
        XCTAssertTrue(self.login())

        let groupConversation = self.conversation(for: self.groupConversation)
        XCTAssertNotNil(groupConversation)

        var message: ZMMessage?
        var messageNonce: UUID?
        self.userSession?.perform {
            message = try! groupConversation?.appendText(content: "lalala") as! ZMMessage
            messageNonce = message!.nonce
        }
        XCTAssertTrue(groupConversation!.managedObjectContext!.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertNotNil(message)

        // when
        let genericMessage = GenericMessage(content: MessageHide(conversationId: (groupConversation?.remoteIdentifier)!, messageId: messageNonce!), nonce: UUID.create())

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            self.selfConversation.insertClientMessage(from: self.selfUser, data: try! genericMessage.serializedData())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        message = ZMMessage.fetch(withNonce: messageNonce,
                                  for: groupConversation!,
                                  in: self.userSession!.managedObjectContext)
        XCTAssertNil(message)
    }
}
