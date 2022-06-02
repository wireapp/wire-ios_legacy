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

import WireTesting
@testable import WireSyncEngine

class PermissionsDownloadRequestStrategyTests: MessagingTest {

    var sut: PermissionsDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        sut = PermissionsDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotGenerateARequestInitially() {
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItDoesNotCreateARequestIfThereIsNoMemberToBeRedownloaded() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .online
            let member = Member.insertNewObject(in: self.syncMOC)
            member.remoteIdentifier = .create()

            // when
            member.needsToBeUpdatedFromBackend = false
            self.boostrapChangeTrackers(with: member)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItCreatesAReuqestForAMemberThatNeedsToBeRedownloadItsMembersFromTheBackend() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let teamId = UUID.create(), userId = UUID.create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamId
            self.mockApplicationStatus.mockSynchronizationState = .online
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)

            // when
            member.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: member)

            // then
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            XCTAssertEqual(request.method, .methodGET)
            XCTAssertEqual(request.path, "/teams/\(teamId.transportString())/members/\(userId.transportString())")
        }
    }

    func testThatItDoesNotCreateARequestDuringSync() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let member = Member.insertNewObject(in: self.syncMOC)
            member.remoteIdentifier = .create()
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing

            // when
            member.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: member)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItUpdatesAMembersPermissionsWithTheResponse() {
        var member: Member!
        var user: ZMUser!

        syncMOC.performGroupedBlock {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .online
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = .create()
            member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)

            member.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: member)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let payload: [String: Any] = [
                "user": user.remoteIdentifier!.transportString(),
                "permissions": ["self": 17, "copy": 0]
            ]

            let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(member.needsToBeUpdatedFromBackend)
            XCTAssertEqual(member.permissions, [.createConversation, .addRemoveConversationMember])
            XCTAssertEqual(member.user, user)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            self.boostrapChangeTrackers(with: member)
            XCTAssertNil(self.sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItDeletesALocalMemberWhenReceivingA404() {
        let userid = UUID.create()

        syncMOC.performGroupedBlock {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userid
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            member.needsToBeUpdatedFromBackend = true

            self.boostrapChangeTrackers(with: member)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertNil(Member.fetch(with: userid, in: self.syncMOC))
        }
    }

    // MARK: - Payload decoding

    func testMembershipPayloadDecoding_AllFields() {
        // given
        let userID = UUID()
        let creatorID = UUID()
        let createdAt = "2020-04-01T09:05:48.200Z"

        let payload: [String: Any] = [
            "user": userID.transportString(),
            "created_by": creatorID.transportString(),
            "created_at": createdAt,
            "permissions": [
                "copy": 1587,
                "self": 1587
            ]
        ]

        // when
        let membershipPayload = WireSyncEngine.MembershipPayload(payload.rawJSON)

        // then
        XCTAssertNotNil(membershipPayload)
        XCTAssertEqual(membershipPayload?.userID, userID)
        XCTAssertEqual(membershipPayload?.createdBy, creatorID)
        XCTAssertEqual(membershipPayload?.createdAt?.transportString(), createdAt)
        XCTAssertEqual(membershipPayload?.permissions?.copyPermissions, 1587)
        XCTAssertEqual(membershipPayload?.permissions?.selfPermissions, 1587)
    }

    func testMembershipPayloadDecoding_OnlyNonOptionalFields() {
        // given
        let userID = UUID()

        let payload: [String: Any] = [
            "user": userID.transportString()
        ]

        // when
        let membershipPayload = WireSyncEngine.MembershipPayload(payload.rawJSON)

        // then
        XCTAssertNotNil(membershipPayload)
        XCTAssertEqual(membershipPayload?.userID, userID)
    }

    // MARK: - Helper

    private func boostrapChangeTrackers(with objects: ZMManagedObject...) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange(Set(objects))
        }

    }

}

extension Dictionary {

    var rawJSON: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }

}
