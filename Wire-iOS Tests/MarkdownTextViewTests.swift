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
import Down

final class MarkdownTextViewTests: XCTestCase {
    
    var sut: MarkdownTextView!
    var bar: MarkdownBarView!
    var style: DownStyle!
    
    override func setUp() {
        super.setUp()
        style = DownStyle()
        style.baseFont = FontSpec(.normal, .regular).font!
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.codeFont = UIFont(name: "Menlo", size: style.baseFont.pointSize) ?? style.baseFont
        style.codeColor = UIColor.red
        style.baseParagraphStyle = NSParagraphStyle.default
        style.h1Size = 28
        style.h2Size = 24
        style.h3Size = 20
        sut = MarkdownTextView(with: style)
        bar = MarkdownBarView()
    }
    
    override func tearDown() {
        style = nil
        sut = nil
        bar = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    func button(for markdown: Markdown) -> IconButton? {
        switch markdown {
        case .h1, .h2, .h3: return bar.headerButton
        case .bold:         return bar.boldButton
        case .italic:       return bar.italicButton
        case .code:         return bar.codeButton
        case .oList:        return bar.numberListButton
        case .uList:        return bar.bulletListButton
        default:            return nil
        }
    }
    
    // Insert the text, but AFTER giving sut a chance to respond.
    func insertText(_ str: String) {
        sut.respondToChange(str, inRange: NSMakeRange(str.length, 0))
        sut.insertText(str)
    }
    
    // Delete the text in the range, but AFTER giving sut a chance to respond.
    func deleteText(in range: NSRange) {
        sut.respondToChange("", inRange: range)
        sut.selectedRange = range
        sut.deleteBackward()
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
    func attrs(for markdown: Markdown) -> [NSAttributedString.Key: Any] {
        switch markdown {
        case .none, .oList, .uList:
            return [
                .markdownID: markdown,
                .font: style.baseFont,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case .h1, .h2, .h3,
             [.h1, .bold],
             [.h2, .bold],
             [.h3, .bold]:
            return [
                .markdownID: markdown,
                .font: style.baseFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case [.h1, .italic], [.h1, .bold, .italic],
             [.h2, .italic], [.h2, .bold, .italic],
             [.h3, .italic], [.h3, .bold, .italic]:
            return [
                .markdownID: markdown,
                .font: style.baseFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold.italic,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case [.h1, .code],
             [.h2, .code],
             [.h3, .code]:
            return [
                .markdownID: markdown,
                .font: style.codeFont.withSize(style.headerSize(for: markdown.headerValue!)!).bold,
                .foregroundColor: style.codeColor!,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case .bold:
            return [
                .markdownID: markdown,
                .font: style.baseFont.bold,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case .italic:
            return [
                .markdownID: markdown,
                .font: style.baseFont.italic,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case .code:
            return [
                .markdownID: markdown,
                .font: style.codeFont,
                .foregroundColor: style.codeColor!,
                .paragraphStyle: style.baseParagraphStyle
            ]
        case [.bold, .italic]:
            return [
                .markdownID: markdown,
                .font: style.baseFont.bold.italic,
                .foregroundColor: style.baseFontColor,
                .paragraphStyle: style.baseParagraphStyle
            ]
        default:
            break
        }
        return [:]
    }
    
    // A way to check that two attribute dictionaries are equal
    func equal(_ lhs: [NSAttributedString.Key: Any], _ rhs: [NSAttributedString.Key: Any]) -> Bool {
        if lhs[.markdownID] as? Markdown != rhs[.markdownID] as? Markdown {
            return false
        }
        if lhs[.font] as? UIFont != rhs[.font] as? UIFont {
            return false
        }
        if lhs[.foregroundColor] as? UIColor != rhs[.foregroundColor] as? UIColor {
            return false
        }
        if lhs[.paragraphStyle] as? NSParagraphStyle != rhs[.paragraphStyle] as? NSParagraphStyle {
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

    func testThatItUpdatesTextColor() {
        // GIVEN: we're currently using the default color
        sut.updateTextColor(base: nil)
        insertText("Hieeee")

        // WHEN: we update the colors
        sut.updateTextColor(base: .red)

        // THEN: the color of the text changes in the attributes
        var attributedRange: NSRange = NSMakeRange(0, 0)
        let attributedColor = sut.attributedText.attribute(.foregroundColor, at: 0, effectiveRange: &attributedRange) as? UIColor
        XCTAssertEqual(attributedColor, .red)
        XCTAssertEqual(attributedRange, NSMakeRange(0, 6))

        XCTAssertEqual(style.baseFontColor, .red)
        XCTAssertEqual(sut.textColor, .red)
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
    
    func testThatSelectingCodeClearsBold() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.bold)
        insertText(text)
        // THEN
        checkAttributes(for: .bold, inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatSelectingCodeClearsItalic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.italic)
        insertText(text)
        // THEN
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatSelectingCodeClearsBoldItalic() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.bold, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatSelectingBoldClearsCode() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.bold)
        insertText(text)
        // THEN
        checkAttributes(for: .bold, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatSelectingItalicClearsCode() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.italic)
        insertText(text)
        // THEN
        checkAttributes(for: .italic, inRange: NSMakeRange(text.length, text.length))
    }
    
    func testThatSelectingBoldItalicClearsCode() {
        // GIVEN
        let text = "Oh Hai!"
        // WHEN
        select(.code)
        insertText(text)
        // THEN
        checkAttributes(for: .code, inRange: NSMakeRange(0, text.length))
        // AND WHEN
        select(.bold, .italic)
        insertText(text)
        // THEN
        checkAttributes(for: [.bold, .italic], inRange: NSMakeRange(text.length, text.length))
    }

    // MARK: - Selections
    
    var wholeTextRange: UITextRange {
        return sut.textRange(from: sut.beginningOfDocument, to: sut.endOfDocument)!
    }
    
    func testThatSelectingMarkdownOnRangeContainingSingleMarkdownUpdatesAttributes() {
        // GIVEN
        let text = "Oh Hai!"
        let wholeRange = NSMakeRange(0, text.length)
        
        insertText(text)
        checkAttributes(for: .none, inRange: wholeRange)
        sut.selectedTextRange = wholeTextRange
        
        // WHEN
        select(.bold)
        // THEN
        checkAttributes(for: .bold, inRange: wholeRange)
        // AND WHEN
        select(.italic)
        // THEN
        checkAttributes(for: [.bold, .italic], inRange: wholeRange)
        // AND WHEN
        select(.code)
        // THEN
        checkAttributes(for: .code, inRange: wholeRange)
        // AND WHEN
        select(.h1)
        // THEN
        checkAttributes(for: [.h1, .code], inRange: wholeRange)
        // AND WHEN
        select(.italic)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: wholeRange)
    }
    
    func testThatWhenTheSelectedRangeContainsMultipleMarkdownTheActiveMarkdownIsNone() {
        // GIVEN
        let text = "Oh Hai!"
        
        select(.italic)
        insertText(text)
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length))
        
        select(.code)
        insertText(text)
        checkAttributes(for: .code, inRange: NSMakeRange(text.length, text.length))
        
        // WHEN
        sut.selectedTextRange = wholeTextRange
        // THEN
        XCTAssertEqual(sut.activeMarkdown, .none)
    }
    
    func testThatSelectingMarkdownOnRangeContainingMultipleMarkdownReplacesAttributes() {
        // GIVEN
        let text = "Oh Hai!"
        let wholeRange = NSMakeRange(0, text.length * 2)
        
        select(.italic)
        insertText(text)
        checkAttributes(for: .italic, inRange: NSMakeRange(0, text.length))
        
        select(.code)
        insertText(text)
        checkAttributes(for: .code, inRange: NSMakeRange(text.length, text.length))
        
        // WHEN
        sut.selectedTextRange = wholeTextRange
        select(.bold)
        // THEN
        checkAttributes(for: .bold, inRange: wholeRange)
    }
    
    func testThatDeselectingMarkdownOnRangeUpdatesAttributes() {
        // GIVEN
        let text = "Oh Hai!"
        let wholeRange = NSMakeRange(0, text.length)
        
        select(.h1, .bold, .italic)
        insertText(text)
        checkAttributes(for: [.h1, .bold, .italic], inRange: wholeRange)
        sut.selectedTextRange = wholeTextRange
        
        // WHEN
        deselect(.bold)
        // THEN
        checkAttributes(for: [.h1, .italic], inRange: wholeRange)
        // AND WHEN
        deselect(.h1)
        // THEN
        checkAttributes(for: .italic, inRange: wholeRange)
        // AND WHEN
        deselect(.italic)
        // THEN
        checkAttributes(for: .none, inRange: wholeRange)
    }
    
    // MARK: - Lists
    
    func testThatSelectingListInsertsNewItemPrefix_Number() {
        // GIVEN
        let text = "Oh Hai!"
        insertText(text)
        // WHEN
        select(.oList)
        // THEN
        XCTAssertEqual(sut.text, "1. \(text)")
    }
    
    func testThatSelectingListInsertsNewItemPrefix_Bullet() {
        // GIVEN
        let text = "Oh Hai!"
        insertText(text)
        // WHEN
        select(.uList)
        // THEN
        XCTAssertEqual(sut.text, "- \(text)")
    }
    
    func testThatDeselectingListRemovesItemPrefix_Number() {
        // GIVEN
        let text = "Oh Hai!"
        insertText("1. \(text)")
        // WHEN
        deselect(.oList)
        // THEN
        XCTAssertEqual(sut.text, text)
    }
    
    func testThatDeselectingListRemovesItemPrefix_Bullet() {
        // GIVEN
        let text = "Oh Hai!"
        ["- ", "+ ", "* "].forEach {
            insertText($0 + text)
            // WHEN
            deselect(.uList)
            // THEN
            XCTAssertEqual(sut.text, text)
            // AFTER
            sut.text = ""
        }
    }
    
    func testThatSelectingListBelowExistingItemInsertsNewItemWithCorrectPrefix_Number() {
        // GIVEN
        insertText("1. Oh Hai!\n")
        insertText("OK Bai!")
        // WHEN
        select(.oList)
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!\n2. OK Bai!")
    }
    
    func testThatSelectingListBelowExistingItemInsertsNewItemWithCorrectPrefix_Bullet() {
        ["• ", "- ", "+ ", "* "].forEach {
            // GIVEN
            insertText($0 + "Oh Hai!\n")
            insertText("OK Bai!")
            // WHEN
            select(.uList)
            // THEN
            XCTAssertEqual(sut.text, $0 + "Oh Hai!\n" + $0 + "OK Bai!")
            // AFTER
            sut.text = ""
        }
    }
    
    func testThatChangingListTypeConvertsPrefix() {
        // GIVEN
        insertText("1. Oh Hai!")
        // WHEN
        select(.uList)
        // THEN
        XCTAssertEqual(sut.text, "- Oh Hai!")
        // AND WHEN
        select(.oList)
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!")
    }
    
    func testThatInsertingNewLineAfterItemCreatesNewEmptyItem() {
        // GIVEN
        insertText("1. Oh Hai!")
        // WHEN
        insertText("\n")
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!\n2. ")
    }
    
    func testThatInsertingNewLineAfterEmptyItemDeletesTheItem() {
        // GIVEN
        insertText("1. Oh Hai!\n2. ")
        // WHEN
        insertText("\n")
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!\n")
    }
    
    func testThatInsertingNewLineInMiddleOfItemSplitsItemIntoTwoItems() {
        // GIVEN
        insertText("- Oh Hai!")
        // place caret just before "H"
        sut.selectedRange = NSMakeRange(5, 0)
        // WHEN
        insertText("\n")
        // THEN
        XCTAssertEqual(sut.text, "- Oh \n- Hai!")
    }
    
    func testThatInsertingAndRemovingListItemPreservesCurrentTextSelection() {
        // GIVEN
        insertText("Oh Hai!")
        // select "Hai"
        sut.selectedRange = NSMakeRange(3, 3)
        // WHEN
        select(.oList)
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!")
        XCTAssertEqual(sut.selectedRange, NSMakeRange(6, 3))
        // AND WHEN
        deselect(.oList)
        // THEN
        XCTAssertEqual(sut.text, "Oh Hai!")
        XCTAssertEqual(sut.selectedRange, NSMakeRange(3, 3))
    }
    
    func testThatIfSelectionIsInListPrefixThenRemovingListItemSetsSelectionToStartOfLine() {
        // GIVEN
        insertText("1. Oh Hai!\n2. Ok Bai!")
        // select "2. "
        sut.selectedRange = NSMakeRange(12, 3)
        // WHEN
        deselect(.oList)
        // THEN
        XCTAssertEqual(sut.text, "1. Oh Hai!\nOk Bai!")
        XCTAssertEqual(sut.selectedRange, NSMakeRange(11, 0))
    }
    
    func testThatDeletingPartOfListPrefixRemovesListMarkdownForLine_Number() {
        // GIVEN
        let text = "Oh Hai!"
        insertText(text)
        select(.oList)
        XCTAssertEqual(sut.text, "1. Oh Hai!")
        checkAttributes(for: .oList, inRange: NSMakeRange(0, text.length + 3))
        // WHEN
        deleteText(in: NSMakeRange(2, 1))
        // THEN
        XCTAssertEqual(sut.text, "1.Oh Hai!")
        checkAttributes(for: .none, inRange: NSMakeRange(0, text.length + 2))
        XCTAssertEqual(sut.activeMarkdown, .none)
    }
    
    func testThatDeletingPartOfListPrefixRemovesListMarkdownForLine_Bullet() {
        // GIVEN
        let text = "Oh Hai!"
        insertText(text)
        select(.uList)
        XCTAssertEqual(sut.text, "- Oh Hai!")
        checkAttributes(for: .uList, inRange: NSMakeRange(0, text.length + 2))
        // WHEN
        deleteText(in: NSMakeRange(1, 1))
        // THEN
        XCTAssertEqual(sut.text, "-Oh Hai!")
        checkAttributes(for: .none, inRange: NSMakeRange(0, text.length + 1))
        XCTAssertEqual(sut.activeMarkdown, .none)
    }
    
    func testThatTypingListPrefixAddsListMarkdownForLine_Number() {
        // GIVEN
        let text = "1. Oh Hai!"
        // WHEN
        text.forEach { insertText(String($0)) }
        // THEN
        XCTAssertEqual(sut.text, text)
        checkAttributes(for: .oList, inRange: NSMakeRange(0, text.length))
        XCTAssertEqual(sut.activeMarkdown, .oList)
    }
    
    func testThatTypingListPrefixAddsListMarkdownForLine_Bullet() {
        // GIVEN
        let text = "+ Oh Hai!"
        // WHEN
        text.forEach { insertText(String($0)) }
        // THEN
        XCTAssertEqual(sut.text, text)
        checkAttributes(for: .uList, inRange: NSMakeRange(0, text.length))
        XCTAssertEqual(sut.activeMarkdown, .uList)
    }
    
    func testThatIfNewLineAfterListItemIsDeletedThenListIsAppliedToWholeLine() {
        // GIVEN
        let line1 = "1. Oh Hai!"
        let line2 = "Ok Bai!"
        insertText(line1)
        insertText("\n" + line2)
        checkAttributes(for: .oList, inRange: NSMakeRange(0, line1.length + 1))
        checkAttributes(for: .none, inRange: NSMakeRange(line1.length + 1, line2.length))
        // WHEN
        let rangeOfNewline = NSMakeRange(line1.length, 1)
        deleteText(in: rangeOfNewline)
        // THEN
        XCTAssertEqual(sut.text, line1 + line2)
        checkAttributes(for: .oList, inRange: NSMakeRange(0, line1.length + line2.length))
    }
    
}

private extension String {
    var length: Int {
        return (self as NSString).length
    }
}
