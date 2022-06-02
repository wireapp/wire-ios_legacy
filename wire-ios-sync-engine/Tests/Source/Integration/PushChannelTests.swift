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
import WireDataModel
import WireMockTransport
@testable import WireSyncEngine

class PushChannelTests: IntegrationTest {

    override func setUp() {
        super.setUp()
        self.createSelfUserAndConversation()
        self.createExtraUsersAndConversations()
    }

    func testThatWeReceiveRemoteMessagesWhenThePushChannelIsUp() {
        // GIVEN
        let testMessage1 = "\(name) message 1"
        let testMessage2 = "\(name) message 2"

        XCTAssertTrue(login())
        let sender = user(for: user1)

        // WHEN
        mockTransportSession.performRemoteChanges { _ in
            let message = GenericMessage(content: Text(content: testMessage1), nonce: .create())

            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data1 = try? message.serializedData() else {
                    return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: fromClient, to: toClient, data: data1)
            self.spinMainQueue(withTimeout: 0.2)

            let secondMessage = GenericMessage(content: Text(content: testMessage2), nonce: .create())
            guard let data2 = try? secondMessage.serializedData() else {
                return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: fromClient, to: toClient, data: data2)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let conversation = self.conversation(for: groupConversation)
        let message1 = conversation?.lastMessages(limit: 50)[1]
        let message2 = conversation?.lastMessages(limit: 50)[0]

        XCTAssertEqual(message1?.textMessageData?.messageText, testMessage1)
        XCTAssertEqual(message2?.textMessageData?.messageText, testMessage2)
        XCTAssertEqual(message1?.sender, sender)
        XCTAssertEqual(message2?.sender, sender)
    }

    func testThatItFetchesLastNotificationsFromBackendIgnoringTransientNotificationsID() {
        // GIVEN
        XCTAssertTrue(login())

        mockTransportSession.performRemoteChanges { _ in
            // will create a transient notification
            self.mockTransportSession.sendIsTypingEvent(for: self.groupConversation, user: self.user1, started: true)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        mockTransportSession.performRemoteChanges { _ in
            // will create a notification that is not transient
            let message = GenericMessage(content: Text(content: "Foo"), nonce: .create())

            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }

            self.groupConversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        var messageAddLastNotificationID: UUID?
        mockTransportSession.performRemoteChanges { _ in
            // save previous notification ID
            let messageEvent = self.mockTransportSession.updateEvents.last as? MockPushEvent
            messageAddLastNotificationID = messageEvent?.uuid
            XCTAssertEqual(messageEvent?.payload.asDictionary()?["type"] as? String, "conversation.otr-message-add")

            // will create a transient notificaiton
            self.mockTransportSession.sendIsTypingEvent(for: self.groupConversation, user: self.user1, started: false)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        mockTransportSession.resetReceivedRequests()

        // WHEN
        mockTransportSession.performRemoteChanges { session in
            session.simulatePushChannelClosed()
            session.simulatePushChannelOpened()
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        let expectedRequest = "/notifications?size=\(ZMMissingUpdateEventsTranscoderListPageSize)&since=\(messageAddLastNotificationID?.transportString() ?? "")&client=\(userSession?.selfUserClient?.remoteIdentifier ?? "")"

        let targetRequests = mockTransportSession.receivedRequests().filter { $0.path == expectedRequest }
        XCTAssertEqual(targetRequests.count, 1)
    }

}
