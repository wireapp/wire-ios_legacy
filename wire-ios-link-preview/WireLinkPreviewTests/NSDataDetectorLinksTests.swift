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
import WireLinkPreview

class NSDataDetectorLinksTests: XCTestCase {

    var detector: NSDataDetector!

    override func setUp() {
        super.setUp()
        detector = NSDataDetector.linkDetector
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    func testThatItReturnsTheDetectedLinkAndOffsetInAText() {
        // given
        let text = "This is a sample containing a link: www.example.com"

        // when
        let links = detector.detectLinksAndRanges(in: text)

        // then
        XCTAssertEqual(links.count, 1)
        let linkWithOffset = links.first
        XCTAssertEqual(linkWithOffset?.URL, URL(string: "http://www.example.com")!)
        XCTAssertEqual(linkWithOffset?.range.location, 36)
    }

    func testThatItReturnsTheDetectedLinkAndOffsetInATextContainingWideEmojis() {
        // given
        let text = "This is a sample 👩🏻‍🚀👨‍👩‍👧‍👧😣 containing a link: www.example.com"

        // when
        let links = detector.detectLinksAndRanges(in: text)

        // then
        XCTAssertEqual(links.count, 1)
        let linkWithOffset = links.first
        XCTAssertEqual(linkWithOffset?.URL, URL(string: "http://www.example.com")!)
        XCTAssertEqual(linkWithOffset?.range.location, 36 + ("👩🏻‍🚀👨‍👩‍👧‍👧😣 " as NSString).length)
    }

    func testThatItReturnsTheURLsAndOffsetsOfMultipleLinksInAText() {
        // given
        let text = "First: www.example.com/first and second: www.example.com/second"

        // when
        let links = detector.detectLinksAndRanges(in: text)

        // then
        XCTAssertEqual(links.count, 2)
        let (first, second) = (links.first, links.last)
        XCTAssertEqual(first?.URL, URL(string: "http://www.example.com/first")!)
        XCTAssertEqual(first?.range.location, 7)
        XCTAssertEqual(second?.URL, URL(string: "http://www.example.com/second")!)
        XCTAssertEqual(second?.range.location, 41)
    }

    func testThatItDoesNotReturnALinkIfThereIsNoneInAText() {
        // given
        let text = "This is a sample containing no link"

        // when
        let links = detector.detectLinksAndRanges(in: text)

        // then
        XCTAssertTrue(links.isEmpty)
    }

    func testThatItDoesReturnALinkIfItsNotInsideAnExcludedRange() {
        // given
        let text = "First: www.example.com/first and second: www.example.com/second"

        // when
        let links = detector.detectLinksAndRanges(in: text, excluding: [(text as NSString).range(of: "and")])

        // then
        XCTAssertEqual(links.count, 2)
    }

    func testThatItDoesNotReturnALinkIfItsInsideAnExcludedRange() {
        // given
        let text = "First: www.example.com/first and second: www.example.com/second"

        // when
        let links = detector.detectLinksAndRanges(in: text, excluding: [NSRange(location: 42, length: 22)])

        // then
        XCTAssertEqual(links.count, 1)
    }

    func testThatItDoesNotReturnALinkIfItsPartiallyInsideAnExcludedRange() {
        // given
        let text = "First: www.example.com/first and second: www.example.com/second"

        // when
        let links = detector.detectLinksAndRanges(in: text, excluding: [NSRange(location: 40, length: 42)])

        // then
        XCTAssertEqual(links.count, 1)
    }

}
