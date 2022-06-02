//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class RegisterPushTokenActionHandlerTests: MessagingTestBase {

    // MARK: - Helpers

    let pushToken = PushToken(
        deviceToken: "deviceToken".data(using: .utf8)!,
        appIdentifier: "appIdentifier",
        transportType: "APNS",
        tokenType: .standard
    )

    func responseWithStatus(_ status: Int) -> ZMTransportResponse {
        return ZMTransportResponse(
            payload: nil,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
    }

    // MARK: - Request generation

    func test_itGeneratesARequest() throws {
        // Given
        let sut = RegisterPushTokenActionHandler(context: syncMOC)
        let action = RegisterPushTokenAction(token: pushToken, clientID: "clientID")

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(request.path, "/push/tokens")
        XCTAssertEqual(request.method, .methodPOST)

        let actualPayload = request.payload?.asDictionary() as? [String: String]
        let expectedPayload: [String: String] = [
            "app": pushToken.appIdentifier,
            "token": pushToken.deviceTokenString,
            "transport": pushToken.transportType,
            "client": "clientID"
        ]

        XCTAssertEqual(actualPayload, expectedPayload)
    }

    // MARK: - Response handling

    func test_itHandlesResponse_201() throws {
        // Given
        let sut = RegisterPushTokenActionHandler(context: syncMOC)
        var action = RegisterPushTokenAction(token: pushToken, clientID: "clientID")

        // Expectation
        let didSucceed = expectation(description: "didSucceed")

        action.onResult { result in
            guard case .success = result else { return }
            didSucceed.fulfill()
        }

        // When
        sut.handleResponse(responseWithStatus(201), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itHandlesResponse_404() throws {
        // Given
        let sut = RegisterPushTokenActionHandler(context: syncMOC)
        var action = RegisterPushTokenAction(token: pushToken, clientID: "clientID")

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.appDoesNotExist) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(responseWithStatus(404), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itHandlesResponse_UnknownError() throws {
        // Given
        let sut = RegisterPushTokenActionHandler(context: syncMOC)
        var action = RegisterPushTokenAction(token: pushToken, clientID: "clientID")

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.unknown(999)) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(responseWithStatus(999), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
