//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class AttributedStringLinkDetectionTests: XCTestCase {
    private struct TestSet {
        var plainText: String
        var range: NSRange
        var expectedResult: Bool
    }

    func testThatContainsMismatchLinkForDifferentCases() {
        let testSets = [
            // MARK: true cases
            TestSet(plainText: "*#[www.google.de](www.evil.com)**", range: NSRange(location: 1, length: 13), expectedResult: true),
            TestSet(plainText: "[www.google.de](www.evil.com)", range: NSRange(location: 0, length: 13), expectedResult: true),
            // MARK: false cases
            // MARK: invalid range
            TestSet(plainText: "[www.google.de](www.evil.com)", range: NSRange(location: 1, length: 13), expectedResult: false),
            TestSet(plainText: "[www.google.de](www.google.de)", range: NSRange(location: 0, length: 13), expectedResult: false),
            TestSet(plainText: "[http://www.google.de](http://www.google.de)", range: NSRange(location: 0, length: 20), expectedResult: false),
            TestSet(plainText: "[www.google.de](http://www.google.de)", range: NSRange(location: 0, length: 13), expectedResult: false),
            TestSet(plainText: "[http://www.google.de](http://www.google.de)", range: NSRange(location: 0, length: 20), expectedResult: false),
            TestSet(plainText: "www.google.de", range: NSRange(location: 0, length: 13), expectedResult: false),
            TestSet(plainText: "abcd", range: NSRange(location: 0, length: 4), expectedResult: false)
        ]

        testSets.forEach { testSet in
            // GIVEN
            let sut = NSMutableAttributedString.markdown(from: testSet.plainText, style: NSAttributedString.style)

            // WHEN
            let result = sut.containsMismatchedLink(in: testSet.range)

            // THEN
            XCTAssertEqual(result, testSet.expectedResult, "failed SUT: \(testSet)")

        }
    }

}
