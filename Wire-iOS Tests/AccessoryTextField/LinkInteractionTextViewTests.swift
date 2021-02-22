////
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
import Down

final class LinkInteractionTextViewTests: XCTestCase {
    
    var sut: LinkInteractionTextView!
    
    override func setUp() {
        super.setUp()
        sut = LinkInteractionTextView(frame: .zero, textContainer: nil)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItOpensNormalLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"].forEach {
            // GIVEN
            let str = $0
            let url = URL(string: str)!
            sut.attributedText = NSAttributedString(string: str, attributes: [.link: url])
            // WHEN
            let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.count), interaction: .invokeDefaultAction)
            // THEN
            XCTAssertTrue(shouldOpenURL)
        }
    }
    
    func testThatItDoesNotPreviewNormalLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"].forEach {
            // GIVEN
            let str = $0
            let url = URL(string: str)!
            sut.attributedText = NSAttributedString(string: str, attributes: [.link: url])
            // WHEN
            let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.count), interaction: .preview)
            // THEN
            XCTAssertFalse(shouldOpenURL)
        }
    }
    
    // Note: Markdown links should not be opened directly, but only after
    // confirmation from the user.
    
    func testThatItDoesNotOpenMarkdownLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"].forEach {
            // GIVEN
            let str = "I'm a markdown link!"
            let url = URL(string: $0)!
            let attrs: [NSAttributedString.Key: Any] = [.markdownID: Markdown.link, .link: url]
            sut.attributedText = NSAttributedString(string: str, attributes: attrs)
            // WHEN
            let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.count), interaction: .invokeDefaultAction)
            // THEN
            XCTAssertFalse(shouldOpenURL)
        }
    }

    func testThatItDoesNotOpenStylizedMarkdownLinks() {
        // GIVEN
        let str = "I'm a markdown link!"
        let url = URL(string: "http://www.wire.com")!

        let markdownId: Markdown = [.bold, .italic, .link]
        let attrs: [NSAttributedString.Key: Any] = [.markdownID: markdownId, .link: url]
        sut.attributedText = NSAttributedString(string: str, attributes: attrs)

        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.count), interaction: .invokeDefaultAction)

        // THEN
        XCTAssertFalse(shouldOpenURL)
    }
    
    func testThatItDoesNotPreviewMarkdownLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"].forEach {
            // GIVEN
            let str = "I'm a markdown link!"
            let url = URL(string: $0)!
            let attrs: [NSAttributedString.Key: Any] = [.markdownID: Markdown.link, .link: url]
            sut.attributedText = NSAttributedString(string: str, attributes: attrs)
            // WHEN
            let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.count), interaction: .preview)
            // THEN
            XCTAssertFalse(shouldOpenURL)
        }
    }
}
