//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

class OptionalComparisonTests: XCTestCase {
    
    func testThatItComparesTwoOptionalsGreaterThanAndLessThan() {
        // given
        let operands: [(Int?, Int?, Bool)] = [
            (1, 2, false),
            (2, 1, true),
            (nil, 0, false),
            (nil, 1, false),
            (0, nil, true),
            (2, nil, true)
        ]
        
        // then
        operands.forEach { (lhs, rhs, expected) in
            XCTAssertEqual(lhs > rhs, expected, "Comparison failed, expected \(String(describing: lhs)) to be greater than \(String(describing: rhs))")
            XCTAssertEqual(lhs < rhs, !expected, "Comparison failed, expected \(String(describing: lhs)) to be less than \(String(describing: rhs))")
        }
    }
    
    func testOptionalComparisonWhenBothOperandsAreNil() {
        let lhs: Int? = nil
        let rhs: Int? = nil
        
        XCTAssertFalse(lhs > rhs)
        XCTAssertFalse(lhs < rhs)
    }
}
