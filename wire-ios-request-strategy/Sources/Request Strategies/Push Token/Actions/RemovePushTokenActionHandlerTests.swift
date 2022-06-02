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

class RemovePushTokenActionHandlerTests: MessagingTestBase {

    // MARK: - Helpers

    let deviceToken = "deviceToken"

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
        let sut = RemovePushTokenActionHandler(context: syncMOC)
        let action = RemovePushTokenAction(deviceToken: deviceToken)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(request.path, "/push/tokens/\(deviceToken)")
        XCTAssertEqual(request.method, .methodDELETE)
    }

    // MARK: - Response handling

    func test_itHandlesResponse_201() throws {
        // Given
        let sut = RemovePushTokenActionHandler(context: syncMOC)
        var action = RemovePushTokenAction(deviceToken: deviceToken)

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

    func test_itHandlesResponse_204() throws {
        // Given
        let sut = RemovePushTokenActionHandler(context: syncMOC)
        var action = RemovePushTokenAction(deviceToken: deviceToken)

        // Expectation
        let didSucceed = expectation(description: "didSucceed")

        action.onResult { result in
            guard case .success = result else { return }
            didSucceed.fulfill()
        }

        // When
        sut.handleResponse(responseWithStatus(204), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itHandlesResponse_404() throws {
        // Given
        let sut = RemovePushTokenActionHandler(context: syncMOC)
        var action = RemovePushTokenAction(deviceToken: deviceToken)

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.tokenDoesNotExist) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(responseWithStatus(404), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itHandlesResponse_UnknownError() throws {
        // Given
        let sut = RemovePushTokenActionHandler(context: syncMOC)
        var action = RemovePushTokenAction(deviceToken: deviceToken)

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
