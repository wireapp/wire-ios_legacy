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

final class FlipTests: XCTestCase {

    func testThatItFlips_1ParameterFunction() {
        // Given
        let foo: (String) -> String = { $0 }
        
        // When
        let flipped = flip(foo)
        
        // Then
        XCTAssertEqual(flipped("1"), "1")
    }
    
    func testThatItFlips_2ParameterFunction() {
        // Given
        let foo: (String, String) -> String = { $0 + $1 }
        
        // When
        let flipped = flip(foo)
        
        // Then
        XCTAssertEqual(flipped("2", "1"), "12")
    }
    
    func testThatItFlips_3ParameterFunction() {
        // Given
        let foo: (String, String, String) -> String = { $0 + $1 + $2 }
        
        // When
        let flipped = flip(foo)
        
        // Then
        XCTAssertEqual(flipped("3", "2", "1"), "123")
    }
    
    func testThatItFlips_4ParameterFunction() {
        // Given
        let foo: (String, String, String, String) -> String = { $0 + $1 + $2 + $3 }
        
        // When
        let flipped = flip(foo)
        
        // Then
        XCTAssertEqual(flipped("4", "3", "2", "1"), "1234")
    }
    
}
