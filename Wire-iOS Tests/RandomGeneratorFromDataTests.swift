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

import Foundation
import XCTest
@testable import Wire

class RandomGeneratorFromDataTests: ZMSnapshotTestCase {
    func testThatItGeneratesAPseudorandom() {
        // GIVEN
        let uuid = NSUUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")! as UUID
        // WHEN
        let random: Int = RandomGeneratorFromData(uuid: uuid).rand()
        // THEN
        XCTAssertEqual(6505850725663318502, random)
    }
    
    func testThatItGeneratesAStablePseudorandom() {
        // GIVEN
        let uuid = NSUUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")! as UUID
        // WHEN
        let random1: Int = RandomGeneratorFromData(uuid: uuid).rand()
        let random2: Int = RandomGeneratorFromData(uuid: uuid).rand()

        // THEN
        XCTAssertEqual(random1, random2)
    }
    
    func testThatItGeneratesSeriesOfAStablePseudorandom() {
        // GIVEN
        let uuid = NSUUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")! as UUID
        // WHEN
        let seed1 = RandomGeneratorFromData(uuid: uuid)
        let seed2 = RandomGeneratorFromData(uuid: uuid)
        let random1: [Int] = (0...100).map { _ in seed1.rand() }
        let random2: [Int] = (0...100).map { _ in seed2.rand() }
        
        // THEN
        XCTAssertEqual(random1, random2)
    }
    
    func testThatItGeneratesAStableRandomArray() {
        // GIVEN
        let uuid = NSUUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")! as UUID
        let array = ["Alice", "Bob", "Mike", "Pinky", "Tim", "Unnamed conversation", "Alice, Bob, Mike"]
        // WHEN
        let random1 = RandomGeneratorFromData(uuid: uuid)
        let random2 = RandomGeneratorFromData(uuid: uuid)
        
        // THEN
        XCTAssertEqual(array.shuffled(with: random1), array.shuffled(with: random2))
    }
}
