//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import XCTest
import SnapshotTesting

@testable import Wire

class NotificationLabelTests: XCTestCase {
    var sut: NotificationLabel!
    let message = "Double Tap on a tile for fullscreen"

    override func setUp() {
        super.setUp()
        sut = NotificationLabel(shouldAnimate: false)
        sut.frame = CGRect(x: 0, y: 0, width: 220, height: 24)
        sut.backgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Appearence

    func testMessageAppearence() {
        // given / when
        sut.show(message: message)

        // then
        verify(matching: sut)
    }

    // MARK: - show(message:hideAfter:)

    func testThat_ItDoesNotCreateTimer_When_NoTimeIntervalIsGiven() {
        // given / when
        sut.show(message: message)

        // then
        XCTAssertNil(sut.timer)
    }

    func testThat_ItCreatesTimer_When_TimeIntervalIsGiven() {
        // given / when
        sut.show(message: message, hideAfter: 5)

        // then
        XCTAssertNotNil(sut.timer)
        XCTAssert(sut.timer?.isValid == true)
    }

    // MARK: - hideAndStopTimer()

    func testThat_ItHidesMessageAndStopsTimer() {
        // given
        sut.show(message: message, hideAfter: 5)

        // when
        sut.hideAndStopTimer()

        // then
        XCTAssertTrue(sut.isHidden)
        XCTAssertEqual(sut.alpha, 0)
        XCTAssert(sut.timer?.isValid == false)
    }

    // MARK: - setMessage(hidden:)

    func testThat_ItHidesMessage() {
        // given
        sut.show(message: message)

        // when
        sut.setMessageHidden(true)

        // then
        XCTAssertEqual(sut.alpha, 0)
        XCTAssertTrue(sut.isHidden)
    }

    func testThat_ItShowsMessage() {
        // given
        sut.alpha = 0
        sut.isHidden = true

        // when
        sut.setMessageHidden(false)

        // then
        XCTAssertEqual(sut.alpha, 1)
        XCTAssertFalse(sut.isHidden)
    }

    func testThat_ItDoesNotShow_IfTimerIsNotValid() {
        // given
        sut.show(message: message, hideAfter: 5)

        sut.timer?.fire()
        sut.timer?.invalidate()

        // when
        sut.setMessageHidden(false)

        // then
        XCTAssertEqual(sut.alpha, 0)
        XCTAssertTrue(sut.isHidden)
    }
}
