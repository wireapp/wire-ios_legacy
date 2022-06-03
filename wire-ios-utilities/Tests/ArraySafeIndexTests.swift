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

import XCTest
import WireUtilities

class ArraySafeIndexTests: XCTestCase {

    var array: [Int]!

    override func setUp() {
        super.setUp()
        array = [1, 2, 3, 4, 5]
    }

    override func tearDown() {
        array = nil
        super.tearDown()
    }

    func testThatItReturnsFirstValue() {
        XCTAssertEqual(array.element(atIndex: 0), 1)
    }

    func testThatItReturnsInsideValue() {
        XCTAssertEqual(array.element(atIndex: 2), 3)
    }

    func testThatItReturnsLastValue() {
        XCTAssertEqual(array.element(atIndex: 4), 5)
    }

    func testThatItFailsWithLowerOutOfBoundsIndex() {
        XCTAssertNil(array.element(atIndex: -1))
    }

    func testThatItFailsWithHigherOutOfBoundsIndex() {
        XCTAssertNil(array.element(atIndex: 5))
    }

}
