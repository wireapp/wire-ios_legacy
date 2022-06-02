//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class SessionManagerConfigurationTests: XCTestCase {

    func testItDecodesConfiguration() throws {
        // Given
        let json = """
        {
            "wipeOnCookieInvalid": false,
            "blacklistDownloadInterval": 21600,
            "blockOnJailbreakOrRoot": false,
            "wipeOnJailbreakOrRoot": true,
            "authenticateAfterReboot": false,
            "messageRetentionInterval": 3600,
            "encryptionAtRestEnabledByDefault": false,
            "legacyAppLockConfig": {
                "isForced": true,
                "timeout": 60,
                "requireCustomPasscode": true
            }
        }
        """

        let decoder = JSONDecoder()
        let data = json.data(using: .utf8)!

        // When
        let result = try decoder.decode(SessionManagerConfiguration.self, from: data)

        // Then
        XCTAssertEqual(result.wipeOnCookieInvalid, false)
        XCTAssertEqual(result.blacklistDownloadInterval, 21600)
        XCTAssertEqual(result.blockOnJailbreakOrRoot, false)
        XCTAssertEqual(result.wipeOnJailbreakOrRoot, true)
        XCTAssertEqual(result.messageRetentionInterval, 3600)
        XCTAssertEqual(result.authenticateAfterReboot, false)
        XCTAssertEqual(result.failedPasswordThresholdBeforeWipe, nil)
        XCTAssertEqual(result.encryptionAtRestEnabledByDefault, false)
        XCTAssertEqual(result.legacyAppLockConfig?.isForced, true)
        XCTAssertEqual(result.legacyAppLockConfig?.timeout, 60)
        XCTAssertEqual(result.legacyAppLockConfig?.requireCustomPasscode, true)
    }
}
