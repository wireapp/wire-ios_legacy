//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireRequestStrategy
import XCTest

extension AssetRequestFactory {
    func profileImageAssetRequest(with data: Data, apiVersion: APIVersion) -> ZMTransportRequest? {
        return upstreamRequestForAsset(withData: data, shareable: true, retention: .eternal, apiVersion: apiVersion)
    }
}

final class SlowSyncTests_Swift: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func testThatItDoesASlowSyncAfterTheWebSocketWentDownAndNotificationsReturnsAnError() {
        // given
        XCTAssertTrue(login())

        mockTransportSession.resetReceivedRequests()

        // make /notifications fail
        var hasNotificationsRequest = false
        var hasConversationsRequest = false
        var hasConnectionsRequest = false
        var hasUserRequest = false

        mockTransportSession.responseGeneratorBlock = { request in
            if request.path.hasPrefix("/notifications") {
                if !(hasConnectionsRequest && hasConversationsRequest && hasUserRequest) {
                    return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
                }
                hasNotificationsRequest = true
            }
            if request.path.hasPrefix("/users") {
                hasUserRequest = true
            }
            if request.path.hasPrefix("/conversations?ids=") {
                hasConversationsRequest = true
            }
            if request.path.hasPrefix("/connections?size=") {
                hasConnectionsRequest = true
            }
            return nil
        }

        // when
        mockTransportSession.performRemoteChanges({ session in
            session.simulatePushChannelClosed()
            session.simulatePushChannelOpened()
        })
        if !waitForAllGroupsToBeEmpty(withTimeout: 0.5) {
            XCTFail("Timed out waiting for groups to empty.")
        }

        // then

        XCTAssert(hasNotificationsRequest)
        XCTAssert(hasUserRequest)
        XCTAssert(hasConversationsRequest)
        XCTAssert(hasConnectionsRequest)
    }

    func testThatItDoesAQuickSyncOnStarTupIfItHasReceivedNotificationsEarlier() {
        // GIVEN
        XCTAssertTrue(login())

        mockTransportSession.performRemoteChanges { _ in
            let message = GenericMessage(content: Text(content: "Hello, Test!"), nonce: .create())
            guard
                let client = self.user1.clients.anyObject() as? MockUserClient,
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: client, to: selfClient, data: data)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        mockTransportSession.resetReceivedRequests()

        // WHEN
        recreateSessionManager()

        // THEN
        var hasNotificationsRequest = false
        for request in mockTransportSession.receivedRequests() {
            if request.path.hasPrefix("/notifications") {
                hasNotificationsRequest = true
            }

            XCTAssertFalse(request.path.hasPrefix("/conversations"))
            XCTAssertFalse(request.path.hasPrefix("/connections"))
        }

        XCTAssertTrue(hasNotificationsRequest)
    }

    func testThatItDoesAQuickSyncAfterTheWebSocketWentDown() {
        // GIVEN
        XCTAssertTrue(login())

        mockTransportSession.performRemoteChanges { _ in
            let message = GenericMessage(content: Text(content: "Hello, Test!"), nonce: .create())
            guard
                let client = self.user1.clients.anyObject() as? MockUserClient,
                let selfClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? message.serializedData() else {
                    return XCTFail()
            }
            self.groupConversation.encryptAndInsertData(from: client, to: selfClient, data: data)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        mockTransportSession.resetReceivedRequests()

        // WHEN
        mockTransportSession.performRemoteChanges { session in
            session.simulatePushChannelClosed()
            session.simulatePushChannelOpened()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        var hasNotificationsRequest = false
        for request in mockTransportSession.receivedRequests() {
            if request.path.hasPrefix("/notifications") {
                hasNotificationsRequest = true
            }

            XCTAssertFalse(request.path.hasPrefix("/conversations"))
            XCTAssertFalse(request.path.hasPrefix("/connections"))
        }

        XCTAssertTrue(hasNotificationsRequest)
    }
}
