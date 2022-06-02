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

class TeamMembersDownloadRequestStrategyTests: MessagingTest {

    var sut: TeamMembersDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncStatus: MockSyncStatus!
    var mockSyncStateDelegate: MockSyncStateDelegate!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockSyncStateDelegate = MockSyncStateDelegate()
        mockSyncStatus = MockSyncStatus(managedObjectContext: syncMOC, syncStateDelegate: mockSyncStateDelegate)
        sut = TeamMembersDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus, syncStatus: mockSyncStatus)

        syncMOC.performGroupedBlockAndWait {
            let user = ZMUser.selfUser(in: self.syncMOC)
            user.remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        mockApplicationStatus = nil
        mockSyncStateDelegate = nil
        mockSyncStatus = nil
        sut = nil
        super.tearDown()
    }

    let sampleResponseForSmallTeam: [String: Any] = [
        "hasMore": false,
        "members": [
            [
                "user": UUID().transportString(),
                "permissions": [
                    "copy": 1587,
                    "self": 1587
                ]
            ]
        ]
    ]

    let sampleResponseForLargeTeam: [String: Any] = [
        "hasMore": true,
        "members": [
            [
                "user": UUID().transportString(),
                "permissions": [
                    "copy": 1587,
                    "self": 1587
                ]
            ]
        ]
    ]

    func createTeam() -> Team {
        let selfUser = ZMUser.selfUser(in: syncMOC)
        let teamID = UUID()
        selfUser.teamIdentifier = teamID
        let team = Team.insertNewObject(in: syncMOC)
        team.remoteIdentifier = teamID
        _ = Member.getOrCreateMember(for: selfUser, in: team, context: syncMOC)

        return team
    }

    func testThatItDoesNotGenerateARequestInitially() {
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItCreatesRequestToFetchTeamMembers() {

        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let teamID = UUID()
            selfUser.teamIdentifier = teamID

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.path, "/teams/\(teamID.transportString())/members")
        }
    }

    func testThatItFinishSyncStep_IfSelfUserDoesntBelongToTeam() {

        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItFinishSyncStep_OnSuccessfulResponse() {
//        var team: Team!

        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            _ = self.createTeam()

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(payload: self.sampleResponseForSmallTeam as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItCreatesTeamMembers_WhenHasMoreIsFalse() {
        var team: Team!

        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            team = self.createTeam()

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(payload: self.sampleResponseForSmallTeam as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(team.members.count, 2)
        }
    }

    func testThatItDoesNotCreateTeamMembers_WhenHasMoreIsTrue() {
        var team: Team!

        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            team = self.createTeam()

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(payload: self.sampleResponseForLargeTeam as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(team.members.count, 1)
        }
    }

}
