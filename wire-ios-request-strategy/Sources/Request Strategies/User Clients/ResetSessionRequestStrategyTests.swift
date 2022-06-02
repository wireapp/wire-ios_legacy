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
@testable import WireRequestStrategy

class ResetSessionRequestStrategyTests: MessagingTestBase {

    var sut: ResetSessionRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override var useInMemoryStore: Bool {
        return false
    }

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = ResetSessionRequestStrategy(managedObjectContext: self.syncMOC,
                                    applicationStatus: mockApplicationStatus,
                                    clientRegistrationDelegate: mockApplicationStatus.clientRegistrationDelegate)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatItCreatesARequest_WhenUserClientNeedsToNotifyOtherUserAboutSessionReset() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = self.createUser()
            let otherClient = self.createClient(user: otherUser)
            let conversation = self.setupOneToOneConversation(with: otherUser)
            let conversationID = conversation.remoteIdentifier!.transportString()
            let conversationDomain = conversation.domain!
            otherClient.needsToNotifyOtherUserAboutSessionReset = true

            // WHEN
            self.sut.contextChangeTrackers.forEach {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                $0.objectsDidChange(otherClientSet)
            }

            // THEN
            XCTAssertEqual(self.sut.nextRequest(for: .v1)?.path, "/v1/conversations/\(conversationDomain)/\(conversationID)/proteus/messages")
        }
    }

    // MARK: Response handling

    func testThatItResetsNeedsToNotifyOtherUserAboutSessionReset_WhenReceivingTheResponse() {
        var otherClient: UserClient!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let otherUser = self.createUser()
            _ = self.setupOneToOneConversation(with: otherUser)
            otherClient = self.createClient(user: otherUser)
            otherClient.needsToNotifyOtherUserAboutSessionReset = true

            self.sut.contextChangeTrackers.forEach {
                let otherClientSet: Set<NSManagedObject> = [otherClient]
                $0.objectsDidChange(otherClientSet)
            }
            let request = self.sut.nextRequest(for: .v0)

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: [:] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: 0))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

}
