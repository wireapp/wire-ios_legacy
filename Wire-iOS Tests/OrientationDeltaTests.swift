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

@testable import Wire

class OrientationDeltaTests: XCTestCase {
    var sut: OrientationDelta!

    func testDeltaRotatedLeft() {
        // GIVEN / WHEN
        sut = OrientationDelta(interfaceOrientation: .portrait, deviceOrientation: .landscapeLeft)

        // THEN
        XCTAssert(sut == .rotatedLeft)
        XCTAssert(sut.radians == OrientationAngle.right.radians)
        XCTAssert(sut.edgeInsetsShiftAmount == 1)
    }

    func testDeltaRotatedRight() {
        // GIVEN / WHEN
        sut = OrientationDelta(interfaceOrientation: .portrait, deviceOrientation: .landscapeRight)

        // THEN
        XCTAssert(sut == .rotatedRight)
        XCTAssert(sut.radians == -OrientationAngle.right.radians)
        XCTAssert(sut.edgeInsetsShiftAmount == -1)
    }

    func testDeltaUpsideDown() {
        // GIVEN / WHEN
        sut = OrientationDelta(interfaceOrientation: .portrait, deviceOrientation: .portraitUpsideDown)

        // THEN
        XCTAssert(sut == .upsideDown)
        XCTAssert(sut.radians == OrientationAngle.straight.radians)
        XCTAssert(sut.edgeInsetsShiftAmount == 2)
    }

    func testDeltaEqual() {
        // GIVEN / WHEN
        sut = OrientationDelta(interfaceOrientation: .portrait, deviceOrientation: .portrait)

        // THEN
        XCTAssert(sut == .equal)
        XCTAssert(sut.radians == OrientationAngle.none.radians)
        XCTAssert(sut.edgeInsetsShiftAmount == 0)
    }
}
