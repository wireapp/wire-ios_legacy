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

final class String_ReplaceMentionsTestsTestsTests: XCTestCase {

    var sut: String!
    var selfUser: ZMUser!

    override func setUp() {
        super.setUp()

        selfUser = MockZMEditableUser() as Any as? ZMUser
    }

    override func tearDown() {
        sut = nil
        selfUser = nil

        super.tearDown()
    }

    func testThatMentionWithEmojiIsReplaced() {
        // GIVEN
        sut = "Hello @Bill 🎅🏾👨‍👩‍👧‍👦🧟‍♀️🧟‍♂️😞🤟🏿! I had some questions about your program. I think I found the bug 🐛."
        let mention = Mention(range: NSRange(location: 6, length: 12), user: selfUser)

        // WHEN
        sut.replaceMentions([mention])

        // THEN
        XCTAssertFalse(sut.contains("@Bill 🎅🏾👨‍👩‍👧‍👦🧟‍♀️🧟‍♂️😞🤟🏿"))
    }

    func testThatMultipleMentionsArereplaced() {
        // GIVEN
        sut = "Hello @Dancers👯👯🏻‍♂️ & @測試者! I had some questions about your program. I think I found the bug 🐛."
        let mention1 = Mention(range: NSRange(location: 6, length: 10), user: selfUser)
        let mention2 = Mention(range: NSRange(location: 19, length: 4), user: selfUser)

        // WHEN
        sut.replaceMentions([mention1, mention2])

        // THEN
        XCTAssertFalse(sut.contains("@Dancers👯👯🏻‍♂️"))
        XCTAssertFalse(sut.contains("@測試者"))
    }
}
