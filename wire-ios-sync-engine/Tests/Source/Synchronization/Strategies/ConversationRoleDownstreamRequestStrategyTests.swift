//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@testable import WireSyncEngine

final class ConversationRoleDownstreamRequestStrategyTests: MessagingTest {
    var sut: ConversationRoleDownstreamRequestStrategy!
    var mockSyncStatus: MockSyncStatus!
    var mockSyncStateDelegate: MockSyncStateDelegate!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockSyncStateDelegate = MockSyncStateDelegate()
        mockSyncStatus = MockSyncStatus(managedObjectContext: syncMOC, syncStateDelegate: mockSyncStateDelegate)
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
        sut = ConversationRoleDownstreamRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)
    }

    override func tearDown() {
        sut = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil
        mockSyncStateDelegate = nil
        super.tearDown()
    }

    private func createConversationToDownload() -> ZMConversation {
        let convoToDownload: ZMConversation = ZMConversation.insertNewObject(in: self.syncMOC)
        convoToDownload.conversationType = .group
        convoToDownload.remoteIdentifier = .create()
        convoToDownload.needsToDownloadRoles = true
        convoToDownload.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: self.syncMOC), role: nil)
        return convoToDownload
    }

    func testThatPredicateIsCorrect() {
        // given
        let convoToDownload = self.createConversationToDownload()

        let convoNoNeed = self.createConversationToDownload()
        convoNoNeed.needsToDownloadRoles = false

        let convoNoIdentifier = self.createConversationToDownload()
        convoNoIdentifier.remoteIdentifier = nil

        // then
        XCTAssert(sut.downstreamSync.predicateForObjectsToDownload.evaluate(with: convoToDownload))
        XCTAssertFalse(sut.downstreamSync.predicateForObjectsToDownload.evaluate(with: convoNoNeed))
        XCTAssertFalse(sut.downstreamSync.predicateForObjectsToDownload.evaluate(with: convoNoIdentifier))
    }

    func testThatItCreatesARequestForConversation() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let convo1 = self.createConversationToDownload()
            self.mockApplicationStatus.mockSynchronizationState = .online

            // when
            self.boostrapChangeTrackers(with: convo1)

            // then
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            XCTAssertEqual(request.method, .methodGET)
            XCTAssertEqual(request.path, "/conversations/\(convo1.remoteIdentifier!.transportString())/roles")
        }
    }

    func testThatItFetchInitialObjectsFromTracker() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let convo1 = self.createConversationToDownload()
            self.mockApplicationStatus.mockSynchronizationState = .online

            // when
            let objs: [ZMConversation] = self.sut.contextChangeTrackers.compactMap({$0.fetchRequestForTrackedObjects()}).flatMap({self.syncMOC.executeFetchRequestOrAssert($0) as! [ZMConversation] })

            // then            
            XCTAssertEqual(objs, [convo1])
        }
    }

    func testItDoesNotGenerateARequestIfTheConversationShouldNotDownloadRoles() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let convo1 = self.createConversationToDownload()
            self.mockApplicationStatus.mockSynchronizationState = .online
            convo1.needsToDownloadRoles = false
            self.boostrapChangeTrackers(with: convo1)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItParsesRolesFromResponse() {
        var convo1: ZMConversation?
        syncMOC.performGroupedBlockAndWait {
            // given
            convo1 = self.createConversationToDownload()
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.boostrapChangeTrackers(with: convo1!)

            // when
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            request.complete(with: ZMTransportResponse(payload: self.sampleRolesPayload as ZMTransportData,
                                                       httpStatus: 200,
                                                       transportSessionError: nil,
                                                       apiVersion: APIVersion.v0.rawValue))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(convo1!.nonTeamRoles.count, 2)
            guard let admin = convo1!.nonTeamRoles.first(where: {$0.name == "wire_admin"}),
                let member = convo1!.nonTeamRoles.first(where: {$0.name == "wire_member" }) else {
                    return XCTFail()
            }
            XCTAssertEqual(Set(admin.actions.map { $0.name }), Set(["leave_conversation", "delete_conversation"]))
            XCTAssertEqual(Set(member.actions.map { $0.name }), Set(["leave_conversation"]))

        }
    }

    func testThatItSetsNeedsToDownloadRolesToFalse_WhenTheResponseIs404() {
        var convo1: ZMConversation?
        syncMOC.performGroupedBlockAndWait {
            // given
            convo1 = self.createConversationToDownload()
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.boostrapChangeTrackers(with: convo1!)

            // when
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            request.complete(with: ZMTransportResponse(payload: nil,
                                                       httpStatus: 404,
                                                       transportSessionError: nil,
                                                       apiVersion: APIVersion.v0.rawValue))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(convo1!.needsToDownloadRoles)

        }
    }

    private let sampleRolesPayload: [String: Any] = [
        "conversation_roles": [
            [
                "actions": [
                    "leave_conversation",
                    "delete_conversation"
                ],
                "conversation_role": "wire_admin"
            ],
            [
                "actions": [
                    "leave_conversation"
                ],
                "conversation_role": "wire_member"
            ]
        ]
    ]

    private func boostrapChangeTrackers(with objects: ZMManagedObject...) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange(Set(objects))
        }

    }
}
