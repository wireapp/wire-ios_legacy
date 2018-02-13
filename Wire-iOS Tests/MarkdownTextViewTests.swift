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
        case .h1, .h2, .h3:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: markdown)!).bold,
                NSForegroundColorAttributeName: style.baseFontColor,
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
        // combined
        case [.h1, .bold]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: .h1)!).bold,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case [.h1, .italic], [.h1, .bold, .italic]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: .h1)!).bold.italic,
                NSForegroundColorAttributeName: style.baseFontColor,
                NSParagraphStyleAttributeName: style.baseParagraphStyle
            ]
        case [.h1, .code]:
            return [
                MarkdownIDAttributeName: markdown,
                NSFontAttributeName: style.codeFont.withSize(style.headerSize(for: .h1)!).bold,
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
    
    func checkAttributes(for markdown: Markdown, inRange range: NSRange) {
        var attrRange = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: range.location, effectiveRange: &attrRange)
        XCTAssertTrue(equal(attrs(for: markdown), result))
        XCTAssertEqual(range, attrRange)
    }
    
    // MARK: - Attributes (Inserting)
    
    // MARK: Headers
    
    func checkHeader(_ md: Markdown) {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header
        sut.markdownBarView(bar, didSelectMarkdown: md, with: bar.headerButton)
        sut.insertText(text)
        // THEN: it renders header
        checkAttributes(for: md, inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_H1() {
        checkHeader(.h1)
    }
    
    func testThatItCreatesCorrectAttributes_H2() {
        checkHeader(.h2)
    }
    
    func testThatItCreatesCorrectAttributes_H3() {
        checkHeader(.h3)
    }
    
    // MARK: Bold, Italic, Code
    
    func testThatItCreatesCorrectAttributes_Bold() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select bold
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.insertText(text)
        // THEN: it renders bold
        checkAttributes(for: .bold, inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_Italic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select italic
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders italic
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length))
    }

    func testThatItCreatesCorrectAttributes_Code() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select code
        sut.markdownBarView(bar, didSelectMarkdown: .code, with: bar.codeButton)
        sut.insertText(text)
        // THEN: it renders code
        checkAttributes(for: .code, inRange: NSMakeRange(0, text.length))
    }
    
    // MARK: Combinations 😬
    
    func testThatItCreatesCorrectAttributes_HeaderItalic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header & italic
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_HeaderBold() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header & bold
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.h1, .bold], inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_HeaderBoldItalic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header, bold & italic
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders all three
        checkAttributes(for: [.h1, .bold, .italic], inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_HeaderCode() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header & code
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .code, with: bar.codeButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.h1, .code], inRange: NSMakeRange(0, text.length))
    }
    
    func testThatItCreatesCorrectAttributes_BoldItalic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select bold & italic
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
    }

    // MARK: - Attributes (Removing)
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Header() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header & italic
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN: I deselect header & insert more text
        sut.markdownBarView(bar, didDeselectMarkdown: .h1, with: bar.headerButton)
        sut.insertText(text)
        // THEN: it renders italic on the whole line
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length * 2))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Bold() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select bold & italic
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN: I deselect bold & insert more text
        sut.markdownBarView(bar, didDeselectMarkdown: .bold, with: bar.boldButton)
        sut.insertText(text)
        // THEN: it only renders italic
        checkAttributes(for: .italic, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Italic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select bold & italic
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN: I deselect italic & insert more text
        sut.markdownBarView(bar, didDeselectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // THEN: it only renders bold
        checkAttributes(for: .bold, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatItCreatesCorrectAttributesWhenRemoving_Code() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN: I select header & code
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .code, with: bar.codeButton)
        sut.insertText(text)
        // THEN: it renders both
        checkAttributes(for: [.h1, .code], inRange: NSMakeRange(0, text.length))
        // AND WHEN: I deselect code & insert more text
        sut.markdownBarView(bar, didDeselectMarkdown: .code, with: bar.codeButton)
        sut.insertText(text)
        // THEN: it only renders header
        checkAttributes(for: .h1, inRange: NSMakeRange(text.length, text.length))
    }
    
    // MARK: - Switching Markdown
    
    func testThatDeselectingHeaderRemovesAttributesFromWholeLine() {
        // GIVEN
        let line1 = "Oh Hai!"
        let line2 = "\nOh Bai!"
        // WHEN: I select header & italic
        sut.markdownBarView(bar, didSelectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(line1)
        // THEN: it renders both
        checkAttributes(for: [.h1, .italic], inRange: NSMakeRange(0, line1.length))
        // AND WHEN: I deselect header & italic & insert new text on next line
        sut.markdownBarView(bar, didDeselectMarkdown: .h1, with: bar.headerButton)
        sut.markdownBarView(bar, didDeselectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(line2)
        // THEN: it renders italic on the whole line first line & nothing on next line
        checkAttributes(for: .italic, inRange: NSMakeRange(0, line1.length))
        checkAttributes(for: .none, inRange: NSMakeRange(line1.length, line2.length))
    }

    func testThatChangingHeadersUpdatesAttributesForWholeLine() {
        XCTFail()
    }
    
    func testThatInsertingNewLineAfterHeaderResetsActiveMarkdown() {
        XCTFail()
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
