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

import Foundation
import XCTest
import WireCommonComponents
@testable import Wire

private class MockPulsingIconImageView: PulsingIconImageView {
    var didStartPulsing: Bool = false
    override func startPulsing() {
        didStartPulsing = true
    }

    var didStopPulsing: Bool = false
    override func stopPulsing() {
        didStopPulsing = true
    }
}

private class MockPulsingIconImageStyle: PulsingIconImageStyle, IconImageStyle {
    var _shouldPulse = false
    var shouldPulse: Bool {
        return _shouldPulse
    }

    var icon: StyleKitIcon? { return .cake }
    var accessibilitySuffix: String { return "" }
    var accessibilityLabel: String { return "" }
}

class PulsingIconImageViewTests: XCTestCase {
    private var sut: MockPulsingIconImageView!
    private var style: MockPulsingIconImageStyle!

    override func setUp() {
        super.setUp()
        sut = MockPulsingIconImageView(frame: .zero)
        style = MockPulsingIconImageStyle()
    }

    func testThatItStopsPulsing_WhenStyleIsUpdated_AndShouldNotPulse() {
        // GIVEN
        style._shouldPulse = false

        // WHEN
        sut.set(style: style)

        // THEN
        XCTAssertTrue(sut.didStopPulsing)
    }

    func testThatItStartsPulsing_WhenStyleIsUpdated_AndShouldPulse() {
        // GIVEN
        style._shouldPulse = true

        // WHEN
        sut.set(style: style)

        // THEN
        XCTAssertTrue(sut.didStartPulsing)
    }
}
