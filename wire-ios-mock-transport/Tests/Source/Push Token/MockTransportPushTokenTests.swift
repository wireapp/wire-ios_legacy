////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class MockTransportPushTokenTests_Swift: MockTransportSessionTests {

    func payload(token: String) -> NSDictionary {
        return [
            "app" : "some.app",
            "token" : token,
            "transport" : "APNS"
            ] as NSDictionary
    }

    func testThatWeCanDeletePushToken() {
        // given
        let token = "abcdef"
        _ = response(forPayload: payload(token: token), path: "/push/tokens", method: .methodPOST, apiVersion: .v0)

        // when
        let result = response(forPayload: nil, path:"/push/tokens/\(token)", method: .methodDELETE, apiVersion: .v0)

        // then
        XCTAssertEqual(result?.httpStatus, 204)
    }

    func testThatWeCannotDeleteUnregisteredPushToken() {
        // given
        let token = "abcdef"

        // when
        let result = response(forPayload: nil, path:"/push/tokens/\(token)", method: .methodDELETE, apiVersion: .v0)

        // then
        XCTAssertEqual(result?.httpStatus, 404)
    }

    func testThatWeCanDeleteMultiplePushTokens() {
        // given
        let token1 = "abcdef"
        _ = response(forPayload: payload(token: token1), path: "/push/tokens", method: .methodPOST, apiVersion: .v0)
        let token2 = "bcdes"
        _ = response(forPayload: payload(token: token2), path: "/push/tokens", method: .methodPOST, apiVersion: .v0)

        // when
        let result1 = response(forPayload: nil, path:"/push/tokens/\(token1)", method: .methodDELETE, apiVersion: .v0)
        let result2 = response(forPayload: nil, path:"/push/tokens/\(token2)", method: .methodDELETE, apiVersion: .v0)

        // then
        XCTAssertEqual(result1?.httpStatus, 204)
        XCTAssertEqual(result2?.httpStatus, 204)
    }

    func testThatWeGetRegisteredTokens() {
        // given
        let payload1 = payload(token: "some token")
        let payload2 = payload(token: "other token")
        _ = response(forPayload: payload1, path: "/push/tokens", method: .methodPOST, apiVersion: .v0)
        _ = response(forPayload: payload2, path: "/push/tokens", method: .methodPOST, apiVersion: .v0)

        // when
        let result = response(forPayload: nil, path: "/push/tokens", method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertEqual(result?.httpStatus, 200)
        guard let payload = result?.payload?.asDictionary() as? [String : NSArray] else { XCTFail(); return }
        XCTAssertFalse(payload.isEmpty)
        guard let results = payload["tokens"] else { XCTFail(); return }
        XCTAssertTrue(results.contains(payload1))
        XCTAssertTrue(results.contains(payload2))
    }
}
