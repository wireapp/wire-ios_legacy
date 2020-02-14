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
@testable import Wire

private let IgnoreTime: TimeInterval = 1 * 60

final class SoundEventRulesWatchDogTests: XCTestCase {
    var watchDog: SoundEventRulesWatchDog?

    func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        watchDog = SoundEventRulesWatchDog(ignoreTime: IgnoreTime)
    }

    func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        watchDog = nil
    }

    func testThatWatchDogStaysMuted() {
        // given
        // when
        watchDog?.muted = true

        // then
        XCTAssertFalse(watchDog?.outputAllowed)
    }

    func testThatWatchDogAllowesOutputForAfterPassedIgnoreTime() {
        // given
        // when
        watchDog?.muted = false
        watchDog?.startIgnoreDate = Date(timeIntervalSinceNow: TimeInterval(-2 * IgnoreTime))

        // then
        XCTAssertTrue(watchDog?.outputAllowed)
    }

    func testThatWatchDogDisallowesOutputForNotYetPassedIgnoreTime() {
        // given
        // when
        watchDog?.muted = false
        watchDog?.startIgnoreDate = Date()

        // then
        XCTAssertFalse(watchDog?.outputAllowed)
    }
}
