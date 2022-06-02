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
import WireMockTransport

class APNSTests_Swift: APNSTestsBase {

    func testThatItUpdatesApplicationBadgeCount_WhenReceivingATextMessage() {
        // GIVEN
        XCTAssertTrue(login())

        let textMessage = GenericMessage(content: Text(content: "Hello"), nonce: .create())

        closePushChannelAndWaitUntilClosed() // do not use websocket

        mockTransportSession.performRemoteChanges { session in
            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? textMessage.serializedData() else {
                    return XCTFail()
            }
            // insert message on backend
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)

            // register new client
            session.registerClient(for: self.user1)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        application?.setBackground()
        application?.simulateApplicationDidEnterBackground()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        XCTAssertEqual(self.application?.applicationIconBadgeNumber, 0)

        // WHEN
        userSession?.receivedPushNotification(with: noticePayloadForLastEvent(), completion: {})
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(self.application?.applicationIconBadgeNumber, 1)
    }

    func testThatItSendsAConfirmationMessage_WhenReceivingATextMessage() {
        // GIVEN
        XCTAssertTrue(login())

        let textMessage = GenericMessage(content: Text(content: "Hello"), nonce: .create())

        closePushChannelAndWaitUntilClosed() // do not use websocket

        mockTransportSession.performRemoteChanges { session in
            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? textMessage.serializedData() else {
                    return XCTFail()
            }
            // insert message on backend
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)

            // register new client
            session.registerClient(for: self.user1)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        application?.setBackground()
        application?.simulateApplicationDidEnterBackground()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        let confirmationExpectation = expectation(description: "Did send confirmation")
        let missingClientsExpectation = expectation(description: "Did fetch missing client")
        var requestCount = 0

        mockTransportSession.responseGeneratorBlock = { (request: ZMTransportRequest) in
            let confirmationPath = "/conversations/\(self.selfToUser1Conversation.identifier)/otr/messages"
            if request.path.hasPrefix(confirmationPath) && request.method == .methodPOST {
                requestCount += 1
                if requestCount == 2 {
                    confirmationExpectation.fulfill()
                }
            }
            let clientsPath = "/users/prekeys"
            if request.path == clientsPath {
                XCTAssertEqual(requestCount, 1)
                missingClientsExpectation.fulfill()
            }
            return nil
        }

        // WHEN
        userSession?.receivedPushNotification(with: noticePayloadForLastEvent(), completion: {})

        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.2)
    }
}
