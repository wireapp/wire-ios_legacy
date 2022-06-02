//
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

class UITextView_ReplaceTests: XCTestCase {

    var sut: UITextView!

    override func setUp() {
        super.setUp()
        sut = UITextView()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRangeIsOutsideTheReplacementString() {
        // GIVEN
        let text = "12345678"
        sut.text = text
        let attributedText = sut.attributedText
        let range = NSRange(location: 0, length: 24)

        // WHEN
        sut.replace(range, withAttributedText: attributedText!)

        // THEN
        XCTAssertEqual(sut.text, text)
    }

    func testRangeIsInsideTheReplacementString() {
        // GIVEN
        let text = "12345678🐶"
        sut.text = text
        let attributedText = sut.attributedText
        let range = NSRange(location: 0, length: 4)

        // WHEN
        sut.replace(range, withAttributedText: attributedText!)

        // THEN
        XCTAssertEqual(sut.text, "12345678🐶5678🐶")
    }

    func testGivenRangeIsOutsideTheWholeRange() {
        // GIVEN
        let text = "12345678"
        sut.text = text
        let attributedText = sut.attributedText
        let range = NSRange(location: 4, length: 6)

        // WHEN
        sut.replace(range, withAttributedText: attributedText!)

        // THEN
        XCTAssertEqual(sut.text, text)
    }
}
