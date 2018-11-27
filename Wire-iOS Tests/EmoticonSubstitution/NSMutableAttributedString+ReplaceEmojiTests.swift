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
@testable import Wire

final class NSMutableAttributedStringReplaceEmojiTests: XCTestCase {

    func testThatReplaceEmojiAtTheEndWithoutExcludedRange() {
        // GIVEN
        // length = 2
        let plainText = "<3"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        sut.replaceEmoticons(excluding: [])


        // THEN
        XCTAssertEqual(sut.string, "❤")
    }

    func testThatReplaceEmojiCorrectlyWhenTheRangeIsOutOfBound() {
        // GIVEN
        // length = 32
        let plainText = "<3 Lorem Ipsum Dolor Sit Amed. :)"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        sut.replaceEmoticons(excluding: [5..<999])


        // THEN
        XCTAssertEqual(sut.string, "❤ Lorem Ipsum Dolor Sit Amed. :)")
    }

    func testThatReplaceEmojiCorrectlyWhenTheRangeIsWithinTheStringLength() {
        // GIVEN
        // length = 32, index 20 is the "r" of "Dolor".
        let plainText = "<3 Lorem Ipsum Dolor }:-)Amed. :)"

        let sut = NSMutableAttributedString.markdown(from: plainText, style: NSAttributedString.style)

        // WHEN
        sut.replaceEmoticons(excluding: [5..<20])


        // THEN
        XCTAssertEqual(sut.string, "❤ Lorem Ipsum Dolor 😈Amed. 😊")
    }

}
