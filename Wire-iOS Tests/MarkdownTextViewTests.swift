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
@testable import Down

final class MarkdownTextViewTests: XCTestCase {
    
    var sut: MarkdownTextView!
    let bar = MarkdownBarView()
    var style: DownStyle!
    
    override func setUp() {
        super.setUp()
        style = DownStyle()
        style.baseFont = FontSpec(.normal, .regular).font!
        style.baseFontColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = UIColor.red
        style.baseParagraphStyle = NSParagraphStyle.default
        style.listIndentation = 0
        style.h1Size = 28
        style.h2Size = 24
        style.h3Size = 20
        sut = MarkdownTextView(with: style)
    }
    
    override func tearDown() {
        style = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    // Insert the text, but AFTER giving sut a chance to respond.
    func insertText(_ str: String) {
        sut.respondToChange(str, inRange: NSMakeRange(str.length, 0))
        sut.insertText(str)
    }
    
    func button(for markdown: Markdown) -> IconButton? {
        switch markdown {
        case .h1, .h2, .h3: return bar.headerButton
        case .bold:         return bar.boldButton
        case .italic:       return bar.italicButton
        case .code:         return bar.codeButton
        default:            return nil
        }
    }
    
    func select(_ markdown: Markdown...) {
        markdown.forEach(select)
    }
    
    func select(_ markdown: Markdown) {
        guard let button = button(for: markdown) else {
            XCTFail()
            return
        }
        sut.markdownBarView(bar, didSelectMarkdown: markdown, with: button)
    }
    
    func deselect(_ markdown: Markdown...) {
        markdown.forEach(deselect)
    }
    
    func deselect(_ markdown: Markdown) {
        guard let button = button(for: markdown) else {
            XCTFail()
            return
        }
        sut.markdownBarView(bar, didDeselectMarkdown: markdown, with: button)
    }
    
    // Attributes that we expect for certain markdown combinations.
    func attrs(for markdown: Markdown) -> [String: Any] {
        switch markdown {
        // atomic
        case .none:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case .h1, .h2, .h3,
             [.h1, .bold],
             [.h2, .bold],
             [.h3, .bold]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case [.h1, .italic], [.h1, .bold, .italic],
             [.h2, .italic], [.h2, .bold, .italic],
             [.h3, .italic], [.h3, .bold, .italic]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold.italic,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case [.h1, .code],
             [.h2, .code],
             [.h3, .code]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.codeFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold,
                NSForegroundColorAttributeName: style.codeColor!,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case .bold:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.bold,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case .italic:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.italic,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case .code:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.codeFont,
                NSForegroundColorAttributeName: style.codeColor!,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case [.bold, .italic]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.bold.italic,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        default:
            break
        }
        return [:]
    }
    
    // A way to check that two attribute dictionaries are equal
    func equal(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        if lhs[MarkdownIDAttributeName] as? Markdown != rhs[MarkdownIDAttributeName] as? Markdown {
            return false
        }
        if lhs[NSFontAttributeName] as? UIFont != rhs[NSFontAttributeName] as? UIFont {
            return false
        }
        if lhs[NSForegroundColorAttributeName] as? UIColor != rhs[NSForegroundColorAttributeName] as? UIColor {
            return false
        }
        if lhs[NSParagraphStyleAttributeName] as? NSParagraphStyle != rhs[NSParagraphStyleAttributeName] as? NSParagraphStyle {
            return false
        }
        return true
    }
    
    // Passes the test if the attributes starting at the given range match the expected
    // attributes and they extend all the way to the end of this range.
    func checkAttributes(for markdown: Markdown, inRange range: NSRange) {
        var attrRange = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: range.location, effectiveRange: &attrRange)
        XCTAssertTrue(equal(attrs(for: markdown), result))
        XCTAssertEqual(range, attrRange)
    }
    
    // MARK: - Attributes (Inserting)
    
    func selectAndCheck(_ md: Markdown...) {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: select each MD
        md.forEach(select)
        insertText(text)
        // THEN: it renders correct attributes
        checkAttributes(for: Markdown(md), inRange: NSMakeRange(0, text.length))
    }
    
    // MARK: Atomic ☺️
    
    func testThatItCreatesCorrectAttributes_H1() {
        selectAndCheck(.h1)
    }
    
    func testThatItCreatesCorrectAttributes_H2() {
        selectAndCheck(.h2)
    }
    
    func testThatItCreatesCorrectAttributes_H3() {
        selectAndCheck(.h3)
    }
    
    func testThatItCreatesCorrectAttributes_Bold() {
        selectAndCheck(.bold)
    }
    
    func testThatItCreatesCorrectAttributes_Italic() {
        selectAndCheck(.italic)
    }

    func testThatItCreatesCorrectAttributes_Code() {
        selectAndCheck(.code)
    }
    
    // MARK: Combinations 😬
    
    func testThatItCreatesCorrectAttributes_HeaderItalic() {
        selectAndCheck(.h1, .italic)
    }
    
    func testThatItCreatesCorrectAttributes_HeaderBold() {
        selectAndCheck(.h1, .bold)
    }
    
    func testThatItCreatesCorrectAttributes_HeaderBoldItalic() {
        selectAndCheck(.h1, .bold, .italic)
    }
    
    func testThatItCreatesCorrectAttributes_HeaderCode() {
        selectAndCheck(.h1, .code)
    }
    
    func testThatItCreatesCorrectAttributes_BoldItalic() {
        selectAndCheck(.bold, .italic)
    }

    // MARK: - Attributes (Removing)
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Header() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.h1, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        deselect(.h1)
        insertText(text)
        // THEN: it renders italic on the whole line
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length * 2))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Bold() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.bold, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        deselect(.bold)
        insertText(text)
        // THEN: it only renders italic
        checkAttributes(for: .italic, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Italic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.bold, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        deselect(.italic)
        insertText(text)
        // THEN
        checkAttributes(for: .bold, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Code() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.h1, .code)
        insertText(text)
        // THEN
        checkAttributes(for: [.h1, .code], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        deselect(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .h1, inRange: NSMakeRange(text.length, text.length))
    }
    
    // MARK: - Switching Markdown
    
    func testThatDeselectingHeaderRemovesAttributesFromWholeLine() {
        // GIVEN
        let line1 = "Oh Hai!"
        let line2 = "\nOh Bai!"
        // WHEN
        select(.h1, .italic)
        insertText(line1)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, line1.length))
        // AND WHEN
        deselect(.h1, .italic)
        insertText(line2)
        // THEN
        checkAttributes(for: .italic, inRange: NSMakeRange(0, line1.length))
        checkAttributes(for: .none, inRange: NSMakeRange(line1.length, line2.length))
    }

    func testThatChangingHeadersUpdatesAttributesForWholeLine() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.h1, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.h2)
        // THEN
        checkAttributes(for: [.h2, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.h3)
        // THEN
        checkAttributes(for: [.h3, .italic], inRange: NSMakeRange(0, text.length))
    }
    
    func testThatInsertingNewLineAfterHeaderResetsActiveMarkdown() {
        // GIVEN
        let line1 = "Oh Hai!"
        let line2 = "Ok Bai!"
        // WHEN
        select(.h1, .italic)
        insertText(line1)
        insertText("\n")
        insertText(line2)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, line1.length))
        checkAttributes(for: .none, inRange: NSMakeRange(line1.length, line2.length + 1))
    }
    
    func testThatSelectingCodeClearsBoldAndItalic() {
        XCTFail()
    }
    
    func testThatSelectingBoldOrItalicClearsCode() {
        XCTFail()
    }
    
    func testThatSelectingListOnHeaderRemovesHeaderAttributes() {
        XCTFail()
    }
    
    func testThatSelectingHeaderOnListRemovesListPrefixAndUpdatesAttributes() {
        XCTFail()
    }

    // MARK: - Selections
    
    func testThatSelectingMarkdownOnRangeUpdatesAttributes() {
        XCTFail()
    }
    
    func testThatDeselectingMarkdownOnRangeUpdatesAttributes() {
        XCTFail()
    }
    
    func testThatSelectingMarkdownOnRangeContainingSingleMarkdownUpdatesAttributes() {
        XCTFail()
    }
    
    func testThatSelectingMarkdownOnRangeContainingMultipleMarkdownUpdatesAttributes() {
        XCTFail()
    }
    
    // MARK: - Lists
    
    func testThatSelectingListInsertsNewItemPrefix() {
        XCTFail()
    }
    
    func testThatDeselectingListRemovesItemPrefix() {
        XCTFail()
    }
    
    func testThatSelectingListBelowExistingItemInsertsNewItemWithCorrectPrefix() {
        XCTFail()
    }
    
    func testThatChangingListTypeConvertsPrefix() {
        XCTFail()
    }
    
    func testThatInsertingNewLineAfterItemCreatesNewEmptyItem() {
        XCTFail()
    }
    
    func testThatInsertingNewLineAfterEmptyItemDeletesTheItem() {
        XCTFail()
    }
    
    func testThatInsertingNewLineInMiddleOfItemSplitsItemIntoTwoItems() {
        XCTFail()
    }
    
    // MARK: - Simulate User Formatting Message
    
}

private extension String {
    var length: Int {
        return (self as NSString).length
    }
}
