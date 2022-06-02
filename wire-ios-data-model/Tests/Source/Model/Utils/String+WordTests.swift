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
@testable import WireDataModel

final class StringWordsTests: XCTestCase {

    func testThatSentenceIsSplitted() {
        // given
        let sut = "once upon a time"

        // when
        let words = sut.words

        // then
        XCTAssertEqual(words, ["once", "upon", "a", "time"])
    }

    func testThatSingleSymbolIsSplittedAsAWord() {
        // given
        let sut = "@"

        // when
        let words = sut.words

        // then
        XCTAssertEqual(words, ["@"])
    }
}
