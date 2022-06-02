//
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

import XCTest
@testable import WireDataModel

final class PushTokenTests: XCTestCase {

    // MARK: - Set up

    var sut: PushToken!

    override func setUp() {
        sut = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "some",
            transportType: "some",
            tokenType: .standard
        )

        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testThatTokenIsEncodedProperly() {
        XCTAssertEqual(sut.deviceTokenString, "010203")
    }

    func testThatItDecodesAPushTokenWithEmptyTokenType() throws {
        // given
        let mockPushToken = MockOldPushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS_VOIP"
        )

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS_VOIP",
            tokenType: .voip
        )

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }

    func testThatItDecodesPushTokenWithVoipTokenType() throws {
        // given
        let mockPushToken = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS_VOIP",
            tokenType: .voip
        )

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS_VOIP",
            tokenType: .voip
        )

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }

    func testThatItDecodesPushTokenWithStandardTokenType() throws {
        // given
        let mockPushToken = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS",
            tokenType: .standard
        )

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(
            deviceToken: Data([0x01, 0x02, 0x03]),
            appIdentifier: "com.wire.zclient",
            transportType: "APNS",
            tokenType: .standard
        )

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }
}

struct MockOldPushToken: Encodable {

    public let deviceToken: Data
    public let appIdentifier: String
    public let transportType: String

}
