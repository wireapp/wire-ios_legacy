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

class ConnectionRequestStrategyTests: MessagingTestBase {

    var sut: ConnectionRequestStrategy!
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

        sut = ConnectionRequestStrategy(withManagedObjectContext: syncMOC,
                                        applicationStatus: mockApplicationStatus,
                                        syncProgress: mockSyncProgress)

        apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockSyncProgress = nil
        mockApplicationStatus = nil
        APIVersion.current = nil

        super.tearDown()
    }

    // MARK: Request generation

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue_Federated() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/connections/\(self.otherUser.domain!)/\(self.otherUser.remoteIdentifier!.transportString())")
            XCTAssertEqual(request.method, .methodGET)
        }
    }

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue_NonFederated() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/connections/\(self.otherUser.remoteIdentifier!.transportString())")
            XCTAssertEqual(request.method, .methodGET)
        }
    }

    // MARK: Slow sync

    func testThatRequestToFetchAllConnectionsIsGenerated_DuringFetchingConnectionsSyncPhase_Federated() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1

            self.mockSyncProgress.currentSyncPhase = .fetchingConnections

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-connections")
            XCTAssertEqual(request.method, .methodPOST)
        }
    }

    func testThatRequestToFetchAllConnectionsIsGenerated_DuringFetchingConnectionsSyncPhase_NonFederated() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/connections?size=200")
            XCTAssertEqual(request.method, .methodGET)
        }
    }

    func testThatRequestToFetchAllConnectionsIsNotGenerated_WhenFetchIsAlreadyInProgress() {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections
            XCTAssertNotNil(self.sut.nextRequest(for: self.apiVersion))

            // then
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatFetchingConnectionsSyncPhaseIsFinished_WhenFetchIsCompleted() {
        // given
        self.apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSync(connections: [createConnectionPayload()])

        // then
        XCTAssertEqual(mockSyncProgress.didFinishCurrentSyncPhase, .fetchingConnections)
    }

    func testThatFetchingConnectionsSyncPhaseIsFinished_WhenThereIsNoConnectionsToFetch() {
        // given
        self.apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSync(connections: [])

        // then
        XCTAssertEqual(mockSyncProgress.didFinishCurrentSyncPhase, .fetchingConnections)
    }

    func testThatFetchingConnectionsSyncPhaseIsFailed_WhenReceivingAPermanentError() {
        // given
        self.apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSyncWithPermanentError()

        // then
        XCTAssertEqual(mockSyncProgress.didFailCurrentSyncPhase, .fetchingConnections)
    }

    // MARK: Response processing

    func testThatConnectionResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors_Federated() {
        // given
        self.apiVersion = .v1
        var connection: ZMConnection!
        self.syncMOC.performGroupedBlockAndWait {
            connection = self.oneToOneConversation.connection!
        }

        // when
        fetchConnection(connection, response: responseFailure(code: 403, label: .unknown, apiVersion: self.apiVersion))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(connection.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConnectionResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors_NonFederated() {
        // given
        var connection: ZMConnection!
        self.syncMOC.performGroupedBlockAndWait {
            connection = self.oneToOneConversation.connection!
        }

        // when
        fetchConnection(connection, response: responseFailure(code: 403, label: .unknown, apiVersion: self.apiVersion))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(connection.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConnectionPayloadIsProcessed_OnSuccessfulResponse_Federated() {
        // given
        self.apiVersion = .v1
        var connection: ZMConnection!
        var payload: Payload.Connection!
        self.syncMOC.performGroupedBlockAndWait {
            connection = self.oneToOneConversation.connection!
            payload = self.createConnectionPayload(connection, status: .cancelled)
        }

        // when
        fetchConnection(connection, response: successfulResponse(connection: payload))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(connection.status, .cancelled)
        }
    }

    func testThatConnectionPayloadIsProcessed_OnSuccessfulResponse_NonFederated() {
        // given
        var connection: ZMConnection!
        var payload: Payload.Connection!
        self.syncMOC.performGroupedBlockAndWait {
            connection = self.oneToOneConversation.connection!
            payload = self.createConnectionPayload(connection, status: .cancelled)
        }

        // when
        fetchConnection(connection, response: successfulResponse(connection: payload))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(connection.status, .cancelled)
        }
    }

    // MARK: Event processing

    func testThatItProcessConnectionEvents() {
        syncMOC.performAndWait {
            // given
            let connection = createConnectionPayload(oneToOneConversation.connection!, status: .blocked)
            let eventType = ZMUpdateEvent.eventTypeString(for: Payload.Connection.eventType)!
            let eventPayload = Payload.UserConnectionEvent(connection: connection, type: eventType)
            let event = updateEvent(from: eventPayload.payloadData()!)

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertEqual(self.oneToOneConversation.connection?.status, .blocked)
        }
    }

    // MARK: Helpers

    func startSlowSync() {
        syncMOC.performGroupedBlockAndWait {
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections
        }
    }

    func fetchConnection(_ connection: ZMConnection, response: ZMTransportResponse) {
        syncMOC.performGroupedBlockAndWait {
            // given
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSync(connections: [Payload.Connection]) {
        syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            guard let payload = Payload.PaginationStatus(request) else {
                return XCTFail("Invalid Payload")
            }

            request.complete(with: self.successfulResponse(request: payload, connections: connections))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSyncWithPermanentError() {
        syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: self.responseFailure(code: 404, label: .noEndpoint, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func successfulResponse(request: Payload.PaginationStatus,
                            connections: [Payload.Connection]) -> ZMTransportResponse {

        let payload = Payload.PaginatedConnectionList(connections: connections,
                                        pagingState: "",
                                        hasMore: false)

        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(payload: payloadString as ZMTransportData,
                                           httpStatus: 200,
                                           transportSessionError: nil,
                                           apiVersion: apiVersion.rawValue)

        return response
    }

    func successfulResponse(connection: Payload.Connection) -> ZMTransportResponse {
        let payloadData = connection.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(payload: payloadString as ZMTransportData,
                                           httpStatus: 200,
                                           transportSessionError: nil,
                                           apiVersion: apiVersion.rawValue)

        return response
    }

}
