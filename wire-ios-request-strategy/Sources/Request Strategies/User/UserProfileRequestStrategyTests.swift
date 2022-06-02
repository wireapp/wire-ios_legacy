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

import Foundation
import XCTest
@testable import WireRequestStrategy

class UserProfileRequestStrategyTests: MessagingTestBase {

    var sut: UserProfileRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncProgress: MockSyncProgress!

    var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        mockSyncProgress = MockSyncProgress()

        sut = UserProfileRequestStrategy(managedObjectContext: syncMOC,
                                         applicationStatus: mockApplicationStatus,
                                         syncProgress: mockSyncProgress)

        apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockSyncProgress = nil
        mockApplicationStatus = nil
        apiVersion = nil

        super.tearDown()
    }

    // MARK: - Request generation

    func testThatRequestToFetchUserIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payloadData = (request.payload as? String)?.data(using: .utf8) else {
                return XCTFail("Payload data is invalid")
            }
            guard let payload = Payload.QualifiedUserIDList(payloadData) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    // MARK: - Slow Sync

    func testThatRequestToFetchConnectedUsersIsGenerated_DuringFetchingUsersSyncPhase() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    func testThatRequestToFetchConnectedUsersIsGenerated_WhenSlowSyncIsRestarted() {
        // given
        apiVersion = .v1

        syncMOC.performGroupedBlockAndWait {
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: self.successfulResponse(for: Payload.QualifiedUserIDList(request)!, apiVersion: self.apiVersion))

        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    func testThatRequestToFetchConnectedUsersIsNotGenerated_WhenFetchIsAlreadyInProgress() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            _ = self.sut.nextRequest(for: self.apiVersion)!

            // when
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatFetchingUsersSyncPhaseIsFinished_WhenFetchIsCompleted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.successfulResponse(for: Payload.QualifiedUserIDList(request)!, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(self.mockSyncProgress.didFinishCurrentSyncPhase, .fetchingUsers)
        }
    }

    func testThatFetchingUsersSyncPhaseIsFinished_WhenThereIsNoUsersToFetch() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            self.syncMOC.delete(self.otherUser.connection!)

            // when
            _ = self.sut.nextRequest(for: self.apiVersion)

            // then
            XCTAssertEqual(self.mockSyncProgress.didFinishCurrentSyncPhase, .fetchingUsers)
        }
    }

    // MARK: - Response processing

    func testThatUsesLegacyEndpoint_WhenFederatedEndpointIsDisabled() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/users?ids=\(self.otherUser.remoteIdentifier.transportString())")
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenSuccessfullyProcessingResponse() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.successfulResponse(for: Payload.QualifiedUserIDList(request)!, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenSuccessfullyProcessingResponseFromLegacyEndpoint() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedID = QualifiedID(uuid: self.otherUser.remoteIdentifier, domain: "example.com")
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [qualifiedID])
            request.complete(with: self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenUserProfileIsNotIncludedInResponse() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [])
            request.complete(with: self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenUserProfileIsNotIncludedInResponseFromLegacyEndpoint() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [])
            request.complete(with: self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenResponseIndicateAPermanentError() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.responseFailure(code: 404, label: .notFound, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenResponseIndicateAPermanentErrorFromLegacyEndpoint() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.responseFailure(code: 404, label: .notFound, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Event processing

    func testThatUserUpdateEventsAreProcessed() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let updatedName = "123"
            let event = self.userUpdateEvent(userProfile: Payload.UserProfile(
                                                id: self.otherUser.remoteIdentifier,
                                                qualifiedID: nil,
                                                teamID: nil,
                                                serviceID: nil,
                                                SSOID: nil,
                                                name: updatedName,
                                                handle: nil,
                                                phone: nil, email: nil,
                                                assets: [],
                                                managedBy: nil, accentColor: nil,
                                                isDeleted: nil,
                                                expiresAt: nil,
                                                legalholdStatus: nil))

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertEqual(self.otherUser.name, updatedName)
        }
    }

    func testThatUserDeleteEventsAreProcessed_WhenOtherUserIsDeleted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let event = self.userDeleteEvent(userID: self.otherUser.remoteIdentifier)

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertTrue(self.otherUser.isAccountDeleted)
        }
    }

    func testThatUserDeleteEventsAreProcessed_WhenSelfUserIsDeleted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let event = self.userDeleteEvent(userID: ZMUser.selfUser(in: self.syncMOC).remoteIdentifier)

            // expect
            self.expectation(forNotification: AccountDeletedNotification.notificationName,
                             object: nil,
                             handler: nil)

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    // MARK: - Helpers

    func userDeleteEvent(userID: UUID) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "type": "user.delete",
            "id": userID.transportString(),
            "time": Date()
        ]

        return ZMUpdateEvent(uuid: UUID(),
                             payload: payload,
                             transient: false,
                             decrypted: true,
                             source: .webSocket)!
    }

    func userUpdateEvent(userProfile: Payload.UserProfile) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "type": "user.update",
            "user": try! JSONSerialization.jsonObject(with: userProfile.payloadData()!, options: [])
        ]

        return ZMUpdateEvent(uuid: UUID(),
                             payload: payload,
                             transient: false,
                             decrypted: true,
                             source: .webSocket)!
    }

    func successfulResponse(for request: Payload.QualifiedUserIDList, apiVersion: APIVersion) -> ZMTransportResponse {
        let userProfiles = request.qualifiedIDs.map({
            return userProfile(for: $0.uuid, domain: $0.domain)
        })

        let payloadData = userProfiles.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(payload: payloadString as ZMTransportData,
                                           httpStatus: 200,
                                           transportSessionError: nil,
                                           apiVersion: apiVersion.rawValue)

        return response
    }

    func userProfile(for uuid: UUID, domain: String?) -> Payload.UserProfile {
        return Payload.UserProfile(id: uuid,
                                   qualifiedID: nil,
                                   teamID: nil,
                                   serviceID: nil,
                                   SSOID: nil,
                                   name: "John Doe",
                                   handle: nil,
                                   phone: nil,
                                   email: nil,
                                   assets: [],
                                   managedBy: nil,
                                   accentColor: nil,
                                   isDeleted: nil,
                                   expiresAt: nil,
                                   legalholdStatus: nil)
    }

}

extension Decodable {

    init?(_ request: ZMTransportRequest) {
        guard let payloadData = (request.payload as? String)?.data(using: .utf8) else {
            return nil
        }

        self.init(payloadData)
    }

}
