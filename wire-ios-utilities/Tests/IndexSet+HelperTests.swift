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

class IndexSet_HelperTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThatItExcludesARange() {
        // given
        let range = 0..<10
        let excluded = [0..<5]
        
        // when
        let sut = IndexSet(integersIn: range, excluding: excluded)
        
        // then
        XCTAssertTrue(sut.contains(integersIn: IndexSet(arrayLiteral: 5, 6, 7, 8, 9)))
        XCTAssertFalse(sut.contains(integersIn: IndexSet(arrayLiteral: 0, 10)))
    }
    
    func testThatItExcludesMultipleRanges() {
        // given
        let range = 0..<10
        let excluded = [0..<5, 6..<10]
        
        // when
        let sut = IndexSet(integersIn: range, excluding: excluded)
        
        // then
        XCTAssertTrue(sut.contains(integersIn: IndexSet(arrayLiteral: 5)))
    }
    
    func testThatItDiscardsRangesOutsideMainRange() {
        // given
        let range = 0..<10
        let excluded = [6..<15]
        
        // when
        let sut = IndexSet(integersIn: range, excluding: excluded)
        
        // then
        XCTAssert(sut.count == 6)

        XCTAssert(sut.contains(integersIn: IndexSet(arrayLiteral: 0, 1, 2, 3, 4, 5)))

        XCTAssertFalse(sut.contains(integersIn: IndexSet(arrayLiteral: 9)))
        XCTAssertFalse(sut.contains(integersIn: IndexSet(arrayLiteral: 10)))
    }

}
