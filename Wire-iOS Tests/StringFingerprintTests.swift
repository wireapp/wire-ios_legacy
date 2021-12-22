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
@testable import Wire

final class StringFingerprintTests: XCTestCase {
    func testThatFingerprintSplitsProperlyFor2() {
        // given
        let testStrings = ["abc", "mfngsdnfgljsfgjdns", "!!@#!@#!@#AASDF", ""]
        let resultStrings = ["ab c", "mf ng sd nf gl js fg jd ns", "!! @# !@ #! @# AA SD F", ""]

        for i in 0..<testStrings.count {
            // when

            let splitString = testStrings[i].fingerprintStringWithSpaces

            // then
            XCTAssertEqual(splitString, resultStrings[i])
        }
    }

    func testThatFingerprintSplitsProperlyFor4() {
        // given
        let testStrings = ["abc", "mfngsdnfgljsfgjdns", "!!@#!@#!@#AASDF", ""]
        let resultStrings = ["abc", "mfng sdnf gljs fgjd ns", "!!@# !@#! @#AA SDF", ""]

        for i in 0..<testStrings.count {
            // when

            let splitString = testStrings[i].split(every: 4).joined(separator: " ")

            // then
            XCTAssertEqual(splitString, resultStrings[i])
        }
    }
}
