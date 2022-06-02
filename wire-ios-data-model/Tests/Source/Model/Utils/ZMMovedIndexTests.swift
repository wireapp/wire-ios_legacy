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
@testable import WireDataModel

class ZMMovedIndexTests: XCTestCase {
    func testThatItGeneratesAHash() {
        // GIVEN
        let index = ZMMovedIndex(from: 0, to: 0)
        // WHEN
        let hash = index.hash
        // THEN
        XCTAssertEqual(hash, 0)
    }

    func testThatItGeneratesSameHashForSameObject() {
        // GIVEN
        let index = ZMMovedIndex(from: 10, to: 7)
        let index2 = ZMMovedIndex(from: 10, to: 7)
        // WHEN & THEN
        XCTAssertEqual(index.hash, index2.hash)
    }

    func testThatItGeneratesDistinctHash() {
        // GIVEN
        let index = ZMMovedIndex(from: 10, to: 7)
        let index2 = ZMMovedIndex(from: 7, to: 10)
        // WHEN & THEN
        XCTAssertNotEqual(index.hash, index2.hash)
    }
}
