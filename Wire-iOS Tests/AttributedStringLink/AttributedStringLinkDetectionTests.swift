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
    func testThatLinkBetweenSymbolsInMarkDownIsDetected() {
        // GIVEN
        let plainText = "*#[www.google.de](www.evil.com)**"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 1, length: 13)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssert(result)
        
        // compare with Down checker result
        XCTAssertFalse(sut.ranges(containing: .link, inRange: range) == [range])
    }

    func testThatNormalLinkInMarkDownIsDetected() {
        // GIVEN
        let plainText = "[www.google.de](www.evil.com)"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 0, length: 13)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssert(result)

        // compare with Down checker result
        XCTAssert(sut.ranges(containing: .link, inRange: range) == [range])
    }

    func testThatInvalidRangeReturnsFalse() {
        // GIVEN
        let plainText = "[www.google.de](www.evil.com)"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 1, length: 13)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssertFalse(result)
    }
    
    func testThatTextMatchesMarkDownLinkIsAllowed() {
        // GIVEN
        let plainText = "[www.google.de](www.google.de)"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 0, length: 13)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssertFalse(result)
    }

    func testThatURLStringIsNotDetected() {
        // GIVEN
        let plainText = "www.google.de"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 0, length: 13)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssertFalse(result)
    }

    func testThatNonLinkInMarkDownIsNotDetected() {
        // GIVEN
        let plainText = "abcd"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        let range = NSRange(location: 0, length: 4)
        let result = sut.containsMismatchLink(in: range)

        // THEN
        XCTAssertFalse(result)
    }
}
