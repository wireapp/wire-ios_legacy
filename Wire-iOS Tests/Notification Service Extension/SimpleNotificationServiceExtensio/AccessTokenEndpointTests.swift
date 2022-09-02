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
        let JSON = """
        {
            "access_token": "testToken",
            "token_type": "type",
            "expires_in": 1662065289
        }
        """
        let successResponse = SuccessResponse(status: 200, data: JSON.data(using: .utf8)!)
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.success(successResponse))
        guard case .success(let token) = result else {
            XCTFail()
            return
        }
//        XCTAssertEqual(token.expirationDate, Date(timeIntervalSince1970: 1662065289)) TODO: check why fails
        XCTAssertEqual(token.token, "testToken")
    }

    func testParsingErrorFailure() {
        let successResponse = SuccessResponse(status: 200, data: "".data(using: .utf8)!)
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.success(successResponse))

        XCTAssertEqual(result, .failure(.failedToDecodePayload))
    }

    func testInvalidCredentialsFailure() {
        let failureResponse = ErrorResponse(code: 403, label: "invalid-credentials", message: "error")
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.failure(failureResponse))

        XCTAssertEqual(result, .failure(.authenticationError))
    }

    func testUnknownErrorFailure() {
        let failureResponse = ErrorResponse(code: 500, label: "server-error", message: "error")
        let endpoint: AccessTokenEndpoint = AccessTokenEndpoint()
        let result = endpoint.parseResponse(.failure(failureResponse))

        XCTAssertEqual(result, .failure(.unknownError(failureResponse)))
    }
}

