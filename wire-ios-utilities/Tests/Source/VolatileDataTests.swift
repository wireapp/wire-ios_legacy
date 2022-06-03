//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireUtilities

class VolatileDataTests: XCTestCase {

    typealias Byte = UInt8

    func testThatItCanStoreBytes() {
        // Given
        let bytes: [Byte] = [0, 1, 2, 3, 4, 5]
        let sut = VolatileData(from: Data(bytes))

        // When
        let storedBytes = [Byte](sut._storage)

        // Then
        XCTAssertEqual(storedBytes, bytes)
    }

    func testThatItResetsBytes() {
        // Given
        let bytes: [Byte] = [0, 1, 2, 3, 4, 5]
        let sut = VolatileData(from: Data(bytes))

        // When
        sut.resetBytes()

        // Then
        let storedBytes = [Byte](sut._storage)
        XCTAssertEqual(storedBytes, [0, 0, 0, 0, 0, 0])
    }

}
