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

class TransformTextViewTests: XCTestCase {

    // MARK: TextTransformNone

    func testThatItSetsCorrectInitialValue_Text() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.text = "Hello"

        // THEN
        XCTAssertEqual(sut.text, "Hello")
        XCTAssertEqual(sut.attributedText?.string, "Hello")
    }

    func testThatItSetsCorrectInitialValue_AttributedText() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.attributedText = NSAttributedString(string: "Hello")

        // THEN
        XCTAssertEqual(sut.text, "Hello")
        XCTAssertEqual(sut.attributedText?.string, "Hello")
    }

    // MARK: - TextTransformUpper

    func testThatItUppercases_Text() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.text = "Hello"
        sut.textTransform = .upper

        // THEN
        XCTAssertEqual(sut.text, "HELLO")
        XCTAssertEqual(sut.attributedText?.string, "HELLO")
    }

    func testThatItUppercases_AttributedText() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.attributedText = NSAttributedString(string: "Hello")
        sut.textTransform = .upper

        // THEN
        XCTAssertEqual(sut.text, "HELLO")
        XCTAssertEqual(sut.attributedText?.string, "HELLO")
    }

    // MARK: - TextTransformLower

    func testThatItLowercases_Text() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.text = "sPonGeBob"
        sut.textTransform = .lower

        // THEN
        XCTAssertEqual(sut.text, "spongebob")
        XCTAssertEqual(sut.attributedText?.string, "spongebob")
    }

    func testThatItLowercases_AttributedText() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.attributedText = NSAttributedString(string: "sPonGeBob")
        sut.textTransform = .lower

        // THEN
        XCTAssertEqual(sut.text, "spongebob")
        XCTAssertEqual(sut.attributedText?.string, "spongebob")
    }

    // MARK: - TextTransformCapitalize

    func testThatItCapitalizes_Text() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.text = "i like capital letters"
        sut.textTransform = .capitalize

        // THEN
        XCTAssertEqual(sut.text, "I Like Capital Letters")
        XCTAssertEqual(sut.attributedText?.string, "I Like Capital Letters")
    }

    func testThatItCapitalizes_AttributedText() {
        // GIVEN
        let sut = TransformLabel()

        // WHEN
        sut.attributedText = NSAttributedString(string: "i like capital letters")
        sut.textTransform = .capitalize

        // THEN
        XCTAssertEqual(sut.text, "I Like Capital Letters")
        XCTAssertEqual(sut.attributedText?.string, "I Like Capital Letters")
    }

}
