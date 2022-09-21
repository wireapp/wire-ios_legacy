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

    func testParseResponseSuccess() {
        // given
        let JSON = """
        {
            "access_token": "testToken",
            "token_type": "type",
            "expires_in": 3600
        }
        """
        let successResponse = SuccessResponse(status: 200, data: JSON.data(using: .utf8)!)
        // when
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.success(successResponse))
        // then
        guard case .success(let token) = result else {
            XCTFail("endpoint failed")
            return
        }
        XCTAssertEqual(token.expirationDate.timeIntervalSince1970, (Date().timeIntervalSince1970 + 3600), accuracy: 1.0)
        XCTAssertEqual(token.token, "testToken")
    }

    func testParsingErrorFailure() {
        // given
        let successResponse = SuccessResponse(status: 200, data: "".data(using: .utf8)!)
        // when
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.success(successResponse))
        // then
        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func testInvalidCredentialsFailure() {
        // given
        let failureResponse = ErrorResponse(code: 403, label: "invalid-credentials", message: "error")
        // when
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.failure(failureResponse))
        // then
        XCTAssertEqual(result, .failure(.authenticationError))
    }

    func testUnknownErrorFailure() {
        // given
        let failureResponse = ErrorResponse(code: 500, label: "server-error", message: "error")
        // when
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.failure(failureResponse))
        // then
        XCTAssertEqual(result, .failure(.unknownError(failureResponse)))
    }
}
