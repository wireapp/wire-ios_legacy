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
@testable import WireSystem

class CircularArrayTests : XCTestCase {
    
    func testThatItReturnsContentWhenNotWrapping() {
        
        // GIVEN
        var sut = CircularArray<String>(size: 5)
        
        // WHEN
        sut.add("A")
        sut.add("B")
        
        // THEN
        XCTAssertEqual(sut.content, ["A", "B"])
    }
    
    func testThatItReturnsContentWhenWrapping() {
        
        // GIVEN
        var sut = CircularArray<Int>(size: 3)
        
        // WHEN
        sut.add(1)
        sut.add(2)
        sut.add(3)
        sut.add(4)
        sut.add(5)
        sut.add(6)
        
        // THEN
        XCTAssertEqual(sut.content, [4,5,6])
    }
}
