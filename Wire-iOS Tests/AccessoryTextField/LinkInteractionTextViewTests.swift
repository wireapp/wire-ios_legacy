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

class LinkInteractionTextViewTests: XCTestCase {
    
    var sut: LinkInteractionTextView!
    
    override func setUp() {
        super.setUp()
        sut = LinkInteractionTextView(frame: .zero, textContainer: nil)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testThatItDoesOpenLinkWithoutHiddenURL_iOS9() {
        // GIVEN
        let str = "http://www.wire.com"
        let url = URL(string: str)!
        sut.attributedText = NSAttributedString(string: str, attributes: [NSLinkAttributeName: url])
        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.characters.count))
        // THEN
        XCTAssertTrue(shouldOpenURL)
    }
    
    func testThatItDoesNotOpenLinkWithHiddenURL_iOS9() {
        // GIVEN
        let str = "tap me!"
        let url = URL(string: "www.wire.com")!
        sut.attributedText = NSAttributedString(string: str, attributes: [NSLinkAttributeName: url])
        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.characters.count))
        // THEN
        XCTAssertFalse(shouldOpenURL)
    }
    
    @available(iOS 10.0, *)
    func testThatItDoesOpenLinkWithoutHiddenURL_iOS10() {
        // GIVEN
        let str = "http://www.wire.com"
        let url = URL(string: str)!
        sut.attributedText = NSAttributedString(string: str, attributes: [NSLinkAttributeName: url])
        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.characters.count), interaction: .invokeDefaultAction)
        // THEN
        XCTAssertTrue(shouldOpenURL)
    }
    
    @available(iOS 10.0, *)
    func testThatItDoesNotOpenLinkWithHiddenURL_iOS10() {
        // GIVEN
        let str = "tap me!"
        let url = URL(string: "www.wire.com")!
        sut.attributedText = NSAttributedString(string: str, attributes: [NSLinkAttributeName: url])
        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(sut, shouldInteractWith: url, in: NSMakeRange(0, str.characters.count), interaction: .invokeDefaultAction)
        // THEN
        XCTAssertFalse(shouldOpenURL)
    }
}
