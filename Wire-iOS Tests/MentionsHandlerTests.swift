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

import Foundation
import WireTesting
@testable import Wire

class MentionsHandlerTests: XCTestCase {

    func testThereIsNoMentionWithNilString() {
        let sut = MentionsHandler(text: nil, cursorPosition: 0)

        XCTAssertNil(sut)
    }

    func testThereIsNoMentionWithCursorOutsideString() {
        let sut = MentionsHandler(text: "A", cursorPosition: 5)

        XCTAssertNil(sut)
    }

    func testThereIsNoMentionWithNoMentionsString() {
        let sut = MentionsHandler(text: "Some text", cursorPosition: 5)

        XCTAssertNil(sut)
    }

    func testThereIsNoMentionNilSearchString() {
        let handler = MentionsHandler(text: "@", cursorPosition: 1)
        guard let sut = handler else { XCTFail(); return }

        XCTAssertNil(sut.searchString(in: nil))
    }

    func testThereIsNoMentionWithWrongSearchString() {
        let handler = MentionsHandler(text: "hey @mention", cursorPosition: 5)
        guard let sut = handler else { XCTFail(); return }

        XCTAssertNil(sut.searchString(in: "my"))
    }

    func testThereIsMentionWithOnlyAtSymbol() {
        let handler = MentionsHandler(text: "@", cursorPosition: 1)

        guard let sut = handler else { XCTFail(); return }

        XCTAssertEqual(sut.searchString(in: "@"), "")
    }

    func testThereIsMentionAtBeginningOfString() {
        let handler = MentionsHandler(text: "@bill", cursorPosition: 1)

        guard let sut = handler else { XCTFail(); return }

        XCTAssertEqual(sut.searchString(in: "@bill"), "bill")
    }


    func testThereIsNoMentionToTheLeftOfAtSymbol() {
        let query = "Hi @bill how are you?"
        let handler = MentionsHandler(text: query, cursorPosition: 3)

        XCTAssertNil(handler)
    }

    func testThereIsNoMentionWithoutSpaces() {
        let query = "Hi@bill how are you?"
        let handler = MentionsHandler(text: query, cursorPosition: 3)

        XCTAssertNil(handler)
    }

    func testThereIsMentionAtTheMiddleOfString() {
        let query = "Hi @bill how are you?"
        let handler = MentionsHandler(text: query, cursorPosition: 4)

        guard let sut = handler else { XCTFail(); return }

        XCTAssertEqual(sut.searchString(in: query), "bill")
    }

    func testThatItReplacesMention() {
        let mockUser = MockUser.mockUsers()[0]
        let query = "Hi @bill how are you?"
        let handler = MentionsHandler(text: query, cursorPosition: 4)
        guard let sut = handler else { XCTFail(); return }

        let replaced = sut.replace(mention: mockUser, in: query.attributedString)
        let attachments = replaced.allAttachments
        XCTAssertEqual(attachments.count, 1)
        guard let mention = attachments.first else { XCTFail(); return}

        let expected = "Hi ".attributedString + NSAttributedString(attachment: mention) + " how are you?".attributedString
        XCTAssertEqual(replaced, expected)
    }

    func testThatItAppendsSpaceAfterMention() {
        let mockUser = MockUser.mockUsers()[0]
        let query = "Hi @bill"
        let handler = MentionsHandler(text: query, cursorPosition: 4)
        guard let sut = handler else { XCTFail(); return }

        let replaced = sut.replace(mention: mockUser, in: query.attributedString)
        let attachments = replaced.allAttachments
        XCTAssertEqual(attachments.count, 1)
        guard let mention = attachments.first else { XCTFail(); return}

        let expected = NSMutableAttributedString(string: query)
        let rangeOfMention = (query as NSString).range(of: "@bill")
        expected.replaceCharacters(in: rangeOfMention, with: NSAttributedString(attachment: mention) + " ")

        XCTAssertEqual(replaced, expected)
    }

}

extension NSAttributedString {
    var allAttachments: [NSTextAttachment] {
        var attachments = [NSTextAttachment]()
        enumerateAttributes(in: wholeRange, options: []) { (attributes, range, _) in
            if let attachment = attributes[NSAttributedString.Key.attachment] as? NSTextAttachment {
                attachments.append(attachment)
            }
        }
        return attachments
    }
}
