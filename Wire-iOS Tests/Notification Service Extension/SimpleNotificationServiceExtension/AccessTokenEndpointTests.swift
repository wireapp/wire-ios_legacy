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

import XCTest
@testable import Wire_Notification_Service_Extension

class AccessTokenEndpointTests: XCTestCase {

    // MARK: - Request generation

    func test_RequestGeneration() {
        // Given
        let sut = AccessTokenEndpoint()

        // When
        let request = sut.request

        // Then
        XCTAssertEqual(request.path, "/access")
        XCTAssertEqual(request.httpMethod, .post)
        XCTAssertEqual(request.contentType, .json)
        XCTAssertEqual(request.acceptType, .json)
    }

    // MARK: - Response parsing

    let validPayload = """
        {
            "access_token": "testToken",
            "token_type": "type",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

    let invalidPayload = """
        {
            "foo": "bar"
        }
        """.data(using: .utf8)!

    func test_ParseSuccessResponse() {
        // Given
        let sut = AccessTokenEndpoint()
        let response = SuccessResponse(status: 200, data: validPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        guard case .success(let token) = result else {
            XCTFail("expected success result")
            return
        }

        XCTAssertEqual(token.token, "testToken")
        XCTAssertEqual(token.type, "type")
        XCTAssertEqual(token.expirationDate.timeIntervalSinceNow, 3600, accuracy: 0.1)
    }

    func test_ParseSuccess_FailedToDecodeError() {
        // Given
        let sut = AccessTokenEndpoint()
        let response = SuccessResponse(status: 200, data: invalidPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func test_ParseSuccess_InvalidResponse() {
        // Given
        let sut = AccessTokenEndpoint()
        let response = SuccessResponse(status: 222, data: validPayload)

        // When
        let result = sut.parseResponse(.success(response))

        // Then
        XCTAssertEqual(result, .failure(.invalidResponse))
    }

    func test_ParseError_AuthenticationError() {
        // Given
        let sut = AccessTokenEndpoint()
        let response = ErrorResponse(code: 403, label: "invalid-credentials", message: "error")

        // When
        let result = sut.parseResponse(.failure(response))

        // Then
        XCTAssertEqual(result, .failure(.authenticationError))
    }

    func test_ParseError_UnknownError() {
        // Given
        let sut = AccessTokenEndpoint()
        let response = ErrorResponse(code: 500, label: "server-error", message: "error")

        // When
        let result = sut.parseResponse(.failure(response))

        // Then
        XCTAssertEqual(result, .failure(.unknownError(response)))
    }

}
