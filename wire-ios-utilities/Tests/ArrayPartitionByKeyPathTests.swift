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

class ArrayPartitionByKeyPathTests: XCTestCase {

    func testPartitionByOptionalValue() {
        // given
        let string1 = "hejsan"
        let string2 = "hus"
        let string3 = "bus"
        let string4 = "snus"
        let string5 = "fasan"
        let strings = [string1, string2, string3, string4, string5]
        
        // when
        let partitions = strings.partition(by: \String.last)
                
        // then
        XCTAssertEqual(partitions.count, 2)
        XCTAssertEqual(partitions["n"], [string1, string5])
        XCTAssertEqual(partitions["s"], [string2, string3, string4])
    }
    
    func testPartitionByValue() {
        // given
        let string1 = "hejsan"
        let string2 = "hus"
        let string3 = "bus"
        let string4 = "snus"
        let string5 = "fasan"
        let strings = [string1, string2, string3, string4, string5]
        
        // when
        let partitions = strings.partition(by: \String.count)
        
        // then
        XCTAssertEqual(partitions.count, 4)
        XCTAssertEqual(partitions[3], [string2, string3])
        XCTAssertEqual(partitions[4], [string4])
        XCTAssertEqual(partitions[5], [string5])
        XCTAssertEqual(partitions[6], [string1])
    }
    
}
