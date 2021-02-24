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
@testable import Wire

final class Data_FingerprintStringTestsTests: XCTestCase {

    func testThatFingerPrintDataIsConvertedToSpacedString(){
        // GIVEN
        let fingerprintString = "102030405060708090a0b0c0d0e0f0708090102030405060708090"
        let sut: Data? = fingerprintString.data(using: .utf8)

        // WHEN & THEN

        XCTAssertEqual(sut?.fingerprintString, "10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0 70 80 90 10 20 30 40 50 60 70 80 90")
    }
}
