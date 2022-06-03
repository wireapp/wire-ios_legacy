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
import WireUtilities

class AtomicIntegerTests: XCTestCase {

    func testThatItIncrementsNumber() {
        // GIVEN
        let atomicNumber = ZMAtomicInteger(integer: 10)

        // WHEN
        let incrementedValue = atomicNumber.increment()

        // THEN
        XCTAssertEqual(incrementedValue, 11)
        XCTAssertEqual(atomicNumber.rawValue, 11)
    }

    func testThatItDecrementsNumber() {
        // GIVEN
        let atomicNumber = ZMAtomicInteger(integer: 10)

        // WHEN
        let incrementedValue = atomicNumber.decrement()

        // THEN
        XCTAssertEqual(incrementedValue, 9)
        XCTAssertEqual(atomicNumber.rawValue, 9)
    }

    func testThatItSwapsValueWhenCurrentValueIsEqualToExpected() {
        // GIVEN
        let atomicNumber = ZMAtomicInteger(integer: 0)

        // WHEN
        let swapped = atomicNumber.setValueWithEqualityCondition(0, newValue: 1)

        // THEN
        XCTAssertTrue(swapped)
        XCTAssertEqual(atomicNumber.rawValue, 1)
    }

    func testThatItDoesNotSwapValueWhenCurrentValueIsNotEqualToExpected() {
        // GIVEN
        let atomicNumber = ZMAtomicInteger(integer: 1)

        // WHEN
        let swapped = atomicNumber.setValueWithEqualityCondition(0, newValue: 1)

        // THEN
        XCTAssertFalse(swapped)
        XCTAssertEqual(atomicNumber.rawValue, 1)
    }

}
