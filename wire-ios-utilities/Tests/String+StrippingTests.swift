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

class String_StrippingTests: XCTestCase {
    
    // MARK: - Mutating method
    
    func testThatItStripsSingleCharacter() {
        // given
        var sut = "abc"
        
        // when
        sut.stripPrefix("a")
        
        // then
        XCTAssertEqual(sut, "bc")
    }
    
    func testThatItStripsMultipleCharacters() {
        // given
        var sut = "abc"
        
        // when
        sut.stripPrefix("ab")
        
        XCTAssertEqual(sut, "c")
    }
    
    func testThatItStripsTheCompleteString() {
        // given
        var sut = "abc"
        
        // when
        sut.stripPrefix("abc")
        
        // then
        XCTAssertEqual(sut, "")
    }
    
    func testThatItReturnOriginalStringIfItDoesNotHavePrefix() {
        // given
        var sut = "abc"
        
        // when
        sut.stripPrefix("b")
        
        // then
        XCTAssertEqual(sut, "abc")
    }
    
    func testThatItReturnOriginalStringIfItDoesNotHaveCompletePrefix() {
        // given
        var sut = "abc"
        
        // when
        sut.stripPrefix("abcd")
        
        // then
        XCTAssertEqual(sut, "abc")
    }
    
    // MARK: - Non mutating methods
    
    func testThatItStripsLeadingAtSign() {
        XCTAssertEqual("@abc".strippingLeadingAtSign(), "abc")
    }
    
    func testThatItStripsPrefixNonMutating() {
        XCTAssertEqual("abc".strippingPrefix("a"), "bc")
    }
    
}
