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
import WireTesting

@testable import WireSyncEngine

class TestAVSLogger: AVSLogger {

    var messages: [String] = []

    func log(message: String) {
        messages.append(message)
    }

}

class SessionManagerAVSTests: ZMTBaseTest {

    func testLoggersReceiveLogMessages() {
        // given
        let logMessage = "123"
        let logger = TestAVSLogger()
        var token: Any? = SessionManager.addLogger(logger)
        XCTAssertNotNil(token)

        // when
        SessionManager.logAVS(message: logMessage)

        // then
        XCTAssertEqual(logger.messages, [logMessage])

        // cleanup
        token = nil
    }

    func testThatLogAVSMessagePostsNotification() {
        // given
        let logMessage = "123"

        // expect
        expectation(forNotification: NSNotification.Name("AVSLogMessageNotification"), object: nil) { (note) -> Bool in
            let message = note.userInfo?["message"] as? String
            return message == logMessage
        }

        // when
        SessionManager.logAVS(message: logMessage)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
