//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@testable import WireSyncEngine

class LoginFlowTests_PushToken: IntegrationTest {
    override func setUp() {
        super.setUp()
        self.createSelfUserAndConversation()
    }

    override func tearDown() {
        DebugLoginFailureTimerOverride = 0
        super.tearDown()
    }

    func testThatItRegistersThePushTokenWithTheBackend() {
        // given
        let deviceToken = "asdfasdf".data(using: .utf8)!
        let deviceTokenAsHex = "6173646661736466"
        XCTAssertTrue(self.login())

        // when
        let pushToken = PushToken.createAPNSToken(from: deviceToken)
        self.userSession?.setPushToken(pushToken)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let registeredTokens = self.mockTransportSession.pushTokens
        XCTAssertEqual(registeredTokens.count, 1)
        let registeredToken = registeredTokens[deviceTokenAsHex]
        XCTAssertEqual(registeredToken!["token"] as! String, deviceTokenAsHex)
        XCTAssertNotNil(registeredToken!["app"])
        XCTAssertTrue((registeredToken!["app"]as! String).hasPrefix("com.wire."))
    }
}
