//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class MarklightTextViewTests: XCTestCase {
    
    let sut = MarklightTextView()
    let text = "example"
    
    override func setUp() {
        super.setUp()
        sut.text = text
    }
    
    override func tearDown() {
        sut.text = ""
        super.tearDown()
    }
    
    // MARK: Syntax Insertions
    
    func testThatItInsertsH1HeaderSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .header(.h1))
        
        // then
        XCTAssertEqual(sut.text, "# example")
    }
    
    func testThatItInsertsH2HeaderSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .header(.h2))
        
        // then
        XCTAssertEqual(sut.text, "## example")
    }
    
    func testThatItInsertsH3HeaderSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .header(.h3))
        
        // then
        XCTAssertEqual(sut.text, "### example")
    }
    
    func testThatItInsertsItalicSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .italic)
        
        // then
        XCTAssertEqual(sut.text, "_example_")
    }
    
    func testThatItInsertsBoldSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .bold)
        
        // then
        XCTAssertEqual(sut.text, "**example**")
    }
    
    func testThatItInsertsCodeSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .code)
        
        // then
        XCTAssertEqual(sut.text, "`example`")
    }
    
    func testThatItInsertsNumberedListSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .numberList)
        
        // then
        XCTAssertEqual(sut.text, "1. example")
    }
    
    func testThatItInsertsBulletListSyntax() {
        // given
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.insertSyntaxForMarkdownElement(type: .bulletList)
        
        // then
        XCTAssertEqual(sut.text, "- example")
    }
    
    // MARK: Syntax Deletions
    
    func testThatItDeletesH1HeaderSyntax() {
        // given
        let text = "# example"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .header(.h1))
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesH2HeaderSyntax() {
        // given
        let text = "## example"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .header(.h2))
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesH3HeaderSyntax() {
        // given
        let text = "### example"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .header(.h3))
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesItalicSyntax() {
        // given
        let text = "_example_"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .italic)
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesBoldSyntax() {
        // given
        let text = "**example**"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .bold)
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesCodeSyntax() {
        // given
        let text = "`example`"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .code)
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesNumberListSyntax() {
        // given
        let text = "1. example"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .numberList)
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItDeletesBulletListSyntax() {
        // given
        let text = "- example"
        sut.text = text
        sut.selectedRange = NSMakeRange(0, text.characters.count)
        
        // when
        sut.deleteSyntaxForMarkdownElement(type: .bulletList)
        
        // then
        XCTAssertEqual(sut.text, "example")
    }
    
    func testThatItStripsEmptyListItems() {
        // given
        let text = ["1. example", "2. example", "3.  ", "- example", "-  "].joined(separator: "\n")
        sut.text = text
        
        // when
        let result = sut.stripEmptyMarkdown()
        
        // then
        let expectation = ["1. example", "2. example", "", "- example", ""].joined(separator: "\n")
        XCTAssertEqual(result, expectation)
        
    }
    
    func testThatItStripsEmptyMarkdownInMessageContainingOnlyEmptyMarkdown() {
        // given
        let text = [
            "#    ", "##   ", "### ",                   // empty headers
            "****", "**   **", "____", "__      __",    // empty bold
            " **", " *    *", " __ ", " _   _",         // empty italics
            "``", "`    `",                             // empty code
            ].joined(separator: "\n")
        
        // insert so markdown is applied
        sut.text = ""
        sut.insertText(text)
        
        // when
        let result = sut.stripEmptyMarkdown().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // then
        XCTAssertEqual(result, "")
    }
    
    func testThatItStripsEmptyMarkdownInMessageContainingNonEmptyMarkdown() {
        // given
        let text = [
            "#    ",
            "# header",
            "**bold** _  _ `code`"
            ].joined(separator: "\n")
        
        // insert so markdown is applied
        sut.text = ""
        sut.insertText(text)
        
        // when
        let result = sut.stripEmptyMarkdown().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let expectation = ["# header", "**bold**  `code`"].joined(separator: "\n")
        
        // then
        XCTAssertEqual(result, expectation)
    }
    
    func testThatItStripsNestedEmptyMarkdown() {
        // given
        let text = "#  **  _    _ **"
        
        // insert so markdown is applied
        sut.text = ""
        sut.insertText(text)
        
        // when
        let result = sut.stripEmptyMarkdown()
        
        // then
        XCTAssertEqual(result, "")
    }
}
