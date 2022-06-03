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
import WireUtilities


class OrderedSetTests : XCTestCase {

    func testThatItAddsValuesFromAnNSOrderedSet(){
        // given
        let set1 = NSOrderedSet(array:["a", "b"])
        let set2 = NSOrderedSet(array:["b", "c"])
        
        // when
        let joined = set1.adding(orderedSet: set2)
        
        // then
        XCTAssertEqual(joined, NSOrderedSet(array:["a", "b", "c"]))
    }
    
    func testThatItRemovesValuesFromAnNSOrderedSet(){
        // given
        let set1 = NSOrderedSet(array:["a", "b"])
        let set2 = NSOrderedSet(array:["b", "c"])
        
        // when
        let subtracted = set1.subtracting(orderedSet: set2)
        
        // then
        XCTAssertEqual(subtracted, NSOrderedSet(array:["a"]))
    }
}
