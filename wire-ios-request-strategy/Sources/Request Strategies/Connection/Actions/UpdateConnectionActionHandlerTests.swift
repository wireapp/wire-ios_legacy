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

class UpdateConnectionActionHandlerTests: MessagingTestBase {

    var sut: UpdateConnectionActionHandler!

    override func setUp() {
        super.setUp()

        sut = UpdateConnectionActionHandler(context: syncMOC)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    // MARK: - Request Generation

    func testThatItCreatesARequestForUpdatingConnection_NonFederated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = self.oneToOneConversation.connection!.to.remoteIdentifier!
            let action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!,
                                                newStatus: .cancelled)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/connections/\(userID.transportString())")
            XCTAssertEqual(request.method, .methodPUT)
            let payload = Payload.ConnectionUpdate(request)
            XCTAssertEqual(payload?.status, .cancelled)
        }
    }

    func testThatItCreatesARequestForUpdatingConnection_Federated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = self.oneToOneConversation.connection!.to.qualifiedID!
            let action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!,
                                                newStatus: .cancelled)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v1))

            // then
            XCTAssertEqual(request.path, "/v1/connections/\(userID.domain)/\(userID.uuid.transportString())")
            XCTAssertEqual(request.method, .methodPUT)
            let payload = Payload.ConnectionUpdate(request)
            XCTAssertEqual(payload?.status, .cancelled)
        }
    }

    // MARK: - Request Processing

    func testThatItParsesAllKnownConnectionUpdateErrorResponses() {

        let errorResponses: [(UpdateConnectionError, ZMTransportResponse)] = [
            (.connectionLimitReached, responseFailure(code: 403, label: .connectionLimit, apiVersion: .v0)),
            (.noIdentity, responseFailure(code: 403, label: .noIdentity, apiVersion: .v0)),
            (.missingLegalholdConsent, responseFailure(code: 403, label: .missingLegalholdConsent, apiVersion: .v0)),
            (.notConnected, responseFailure(code: 403, label: .notConnected, apiVersion: .v0))
        ]

        for (expectedError, response) in errorResponses {
            assertFailure(expectedError, on: response)
        }
    }

    func testThatItProcessConnectionEventInTheResponse() throws {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            let newStatus: ZMConnectionStatus = .blocked
            let action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!,
                                                newStatus: newStatus)
            let connection = createConnectionPayload(self.oneToOneConversation.connection!,
                                                     status: .blocked)
            let payloadAsString = String(bytes: connection.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertEqual(self.oneToOneConversation.connection?.status, newStatus)
        }
    }

    func testThatItCallsResultHandler_On200() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!,
                                                newStatus: .blocked)
            let connection = createConnectionPayload(self.oneToOneConversation.connection!,
                                                     status: .blocked)
            let payloadAsString = String(bytes: connection.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .success = result {
                    expectation.fulfill()
                }
            }

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnError() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!,
                                                newStatus: .blocked)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .failure = result {
                    expectation.fulfill()
                }
            }

            let response = ZMTransportResponse(payload: nil,
                                               httpStatus: 404,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    // MARK: - Helpers

    func assertFailure(_ expectedError: UpdateConnectionAction.Failure, on response: ZMTransportResponse) {
        syncMOC.performGroupedBlockAndWait {
            // given
            var action = UpdateConnectionAction(connection: self.oneToOneConversation.connection!, newStatus: .accepted)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .failure(let error) = result {
                    if expectedError == error {
                        expectation.fulfill()
                    }
                }
            }

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

}
