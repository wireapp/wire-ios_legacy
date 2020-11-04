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
@testable import WireCommonComponents

final class AppLockTimerTests: XCTestCase {
    var sut: AppLockTimer!
    
    override func setUp() {
        super.setUp()
        sut = AppLockTimer()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatScreenShouldBeLockedIfAppLockIsActiveAndTimeoutIsReached() {
        //given
        set(appLockActive: true, timeoutReached: true)
        
        //when / then
        XCTAssertTrue(sut.shouldLockScreen)
    }
    
    func testThatShouldLockScreenReturnsFalseIfTimeoutNotReached() {
        //given
        set(appLockActive: true, timeoutReached: false)
        
        //when / then
        XCTAssertFalse(sut.shouldLockScreen)
    }
    
    func testThatShouldLockScreenReturnsFalseIfAppLockNotActive() {
        //given - appLock not active
        set(appLockActive: false, timeoutReached: false)
        
        //when / then
        XCTAssertFalse(sut.shouldLockScreen)
    }
}

extension AppLockTimerTests {
    func set(appLockActive: Bool, timeoutReached: Bool) {
        AppLock.isActive = appLockActive
        if !timeoutReached {
            sut.appDidBecomeUnlocked()
        }
        sut.appDidEnterForeground()
    }
}
