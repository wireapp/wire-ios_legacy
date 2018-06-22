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
@testable import Wire

final class MessageDestructionTimeoutValueTests: XCTestCase {
    
    func testThatItReturnsTheCorrectFormattedString(){
        XCTAssertEqual(MessageDestructionTimeoutValue.none.displayString, "Off")
        XCTAssertEqual(MessageDestructionTimeoutValue.tenSeconds.displayString, "10 seconds")
        XCTAssertEqual(MessageDestructionTimeoutValue.fiveMinutes.displayString, "5 minutes")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneDay.displayString, "1 day")
        XCTAssertEqual(MessageDestructionTimeoutValue.oneWeek.displayString, "1 week")
        XCTAssertEqual(MessageDestructionTimeoutValue.fourWeeks.displayString, "4 weeks")
    }

    func testThatItReturnsTheCorrectFormattedStringForCustomTimeOut(){
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(1 + 0.1).displayString, "1 second")

        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(60 + 31).displayString, "2 minutes")

        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(3601).displayString, "1 hour")
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(3600 + 1799).displayString, "1 hour")
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(3600 + 1800).displayString, "2 hours")
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(3600 + 1801).displayString, "2 hours")

        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(86400 + 86400 - 1).displayString, "2 days")

        XCTAssertEqual(ZMConversationMessageDestructionTimeout.custom(ZMConversationMessageDestructionTimeout.oneWeek.rawValue * 1.5 + 1).displayString, "2 weeks")
    }
}
