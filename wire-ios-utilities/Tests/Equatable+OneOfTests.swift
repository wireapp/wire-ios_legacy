//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class EquatableOneOfTests : XCTestCase {

    func testThatItReportsContainmentVariadicFunction() {
        // Given
        let sut = 42
        
        // Then
        XCTAssert(sut.isOne(of: 42, 43))
    }
    
    func testThatItReportsContainmentVariadicFunction_Negative() {
        // Given
        let sut = 42
        
        // Then
        XCTAssertFalse(sut.isOne(of: 43))
    }
    
    func testThatItReportsContainmentCollectionFunction() {
        // Given
        let sut = 42
        
        // Then
        XCTAssert(sut.isOne(of: [42, 43]))
    }
    
    func testThatItReportsContainmentCollectionFunction_Empty() {
        // Given
        let sut = 42
        
        // Then
        XCTAssertFalse(sut.isOne(of: []))
    }
    
    func testThatItReportsContainmentCollectionFunction_Negative() {
        // Given
        let sut = 42
        
        // Then
        XCTAssertFalse(sut.isOne(of: [43]))
    }
    
    func testThatItReportsContainmentCollectionFunction_Set() {
        // Given
        let sut = 42
        
        // Then
        XCTAssert(sut.isOne(of: Set([42, 43, 45, 0])))
    }
}
