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

class PayloadProcessing_MessageSendingStatusTests: MessagingTestBase {

    let domain =  "example.com"

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            self.otherUser.domain = self.domain
        }
    }

    // MARK: - Client Updates

    func testThatClientsAreDeleted_WhenDeletedClientsArePresent() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let deleted: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: [:],
                                                       deleted: deleted,
                                                       failedToSend: [:])

            // when
            _ = payload.updateClientsChanges(for: message)

            // then
            XCTAssertTrue(self.otherClient.isDeleted)
        }
    }

    func testThatClientsAreMarkedAsMissing_WhenMissingClientsArePresent() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let clientID = UUID().transportString()
            let missing: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [clientID]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])

            // when
            _ = payload.updateClientsChanges(for: message)

            // then
            XCTAssertEqual(self.selfClient.missingClients!.count, 1)
            XCTAssertEqual(self.selfClient.missingClients!.first!.remoteIdentifier, clientID)
        }
    }

    func testThatClientsAreNotMarkedAsMissing_WhenMissingClientsAlreadyHaveASession() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let clientID = UUID().transportString()
            let userClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                        forUser: self.otherUser,
                                                        createIfNeeded: true)!
            self.establishSessionFromSelf(to: userClient)
            let missing: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [clientID]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])

            // when
            _ = payload.updateClientsChanges(for: message)

            // then
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatUserIsMarkedToBeRefetched_WhenReduntantUsersArePresent() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let redundant: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: redundant,
                                                       deleted: [:],
                                                       failedToSend: [:])

            // when
            _ = payload.updateClientsChanges(for: message)

            // then
            XCTAssertTrue(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatTheConversationIsMarkedToBeRefetched_WhenReduntantUsersArePresent() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let redundant: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: redundant,
                                                       deleted: [:],
                                                       failedToSend: [:])

            // when
            _ = payload.updateClientsChanges(for: message)

            // then
            XCTAssertTrue(message.conversation!.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Payload mapping

    func testThatItReturnsMissingClientListByUser() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let expectedThirdUserClientList = [UUID().transportString(), UUID().transportString()]
            let thirdDomain = "third.domain.com"

            self.syncMOC.saveOrRollback()

            let missing: Payload.ClientListByQualifiedUserID = [
                self.domain: [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]],
                thirdDomain: [self.thirdUser.remoteIdentifier.transportString(): expectedThirdUserClientList]
            ]

            let payload = Payload.MessageSendingStatus(time: Date(), missing: missing, redundant: [:], deleted: [:], failedToSend: [:])

            // when
            let clientListByUser = payload.missingClientListByUser(context: self.syncMOC)

            // then
            let otherUserClientList = clientListByUser[self.otherUser]
            XCTAssertNotNil(otherUserClientList)
            XCTAssertEqual(otherUserClientList, [self.otherClient.remoteIdentifier!])
            let thirdUserClientList = clientListByUser[self.thirdUser]
            XCTAssertNotNil(thirdUserClientList)
            XCTAssertEqual(thirdUserClientList, expectedThirdUserClientList)
        }
    }

    func testThatMissingClientListByUser_CreatesNewUserIfNeeded() {
        // given
        let userID = UUID()
        let clientID = UUID().transportString()

        let missing: Payload.ClientListByQualifiedUserID = [
            domain: [userID.transportString(): [clientID]]
        ]

        let payload = Payload.MessageSendingStatus(time: Date(), missing: missing, redundant: [:], deleted: [:], failedToSend: [:])

        // when
        var clientListByUser = Payload.ClientListByUser()
        syncMOC.performGroupedBlockAndWait {
            clientListByUser = payload.missingClientListByUser(context: self.syncMOC)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        syncMOC.performGroupedBlockAndWait {
            guard let user = ZMUser.fetch(with: userID, domain: self.domain, in: self.syncMOC) else {
                return XCTFail("user was not created")
            }

            let userClientList = clientListByUser[user]
            XCTAssertEqual(userClientList, [clientID])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

}
