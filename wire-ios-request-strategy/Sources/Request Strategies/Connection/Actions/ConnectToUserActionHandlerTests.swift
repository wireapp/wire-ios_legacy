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

class ConnectToUserActionHandlerTests: MessagingTestBase {

    var sut: ConnectToUserActionHandler!

    override func setUp() {
        super.setUp()

        sut = ConnectToUserActionHandler(context: syncMOC)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    // MARK: - Request Generation

    func testThatItCreatesARequestForConnectingToUser_NonFederated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = UUID()
            let domain = self.owningDomain
            let action = ConnectToUserAction(userID: userID, domain: domain)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/connections")
            XCTAssertEqual(request.method, .methodPOST)
            let payload = Payload.ConnectionRequest(request)
            XCTAssertEqual(payload?.userID, userID)
        }
    }

    func testThatItCreatesARequestForConnectingToUser_Federated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = UUID()
            let domain = self.owningDomain
            let action = ConnectToUserAction(userID: userID, domain: domain)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v1))

            // then
            XCTAssertEqual(request.path, "/v1/connections/\(domain)/\(userID.transportString())")
            XCTAssertEqual(request.method, .methodPOST)
        }
    }

    // MARK: - Request Processing

    func testThatItParsesAllKnownConnectionToUserErrorResponses() {

        let errorResponses: [(ConnectToUserError, ZMTransportResponse)] = [
            (.connectionLimitReached, responseFailure(code: 403, label: .connectionLimit, apiVersion: .v0)),
            (.noIdentity, responseFailure(code: 403, label: .noIdentity, apiVersion: .v0)),
            (.missingLegalholdConsent, responseFailure(code: 403, label: .missingLegalholdConsent, apiVersion: .v0))
        ]

        for (expectedError, response) in errorResponses {
            assertFailure(expectedError, on: response)
        }
    }

    func testThatItProcessConnectionEventInTheResponse() throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // given
            let userID = UUID()
            let domain = self.owningDomain
            let action = ConnectToUserAction(userID: userID, domain: domain)
            let connection = createConnectionPayload(to: QualifiedID(uuid: userID, domain: domain))
            let payloadAsString = String(bytes: connection.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertNotNil(ZMConnection.fetch(userID: userID, domain: domain, in: self.syncMOC))
        }
    }

    func testThatItCallsResultHandler_On200() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            let userID = UUID()
            let domain = self.owningDomain
            var action = ConnectToUserAction(userID: userID, domain: domain)
            let connection = createConnectionPayload(to: QualifiedID(uuid: userID, domain: domain))
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
            let userID = UUID()
            let domain = self.owningDomain
            var action = ConnectToUserAction(userID: userID, domain: domain)

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

    // MARK: - Helper

    func assertFailure(_ expectedError: ConnectToUserAction.Failure, on response: ZMTransportResponse) {
        syncMOC.performGroupedBlockAndWait {
            // given
            let userID = UUID()
            let domain = self.owningDomain
            var action = ConnectToUserAction(userID: userID, domain: domain)

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
