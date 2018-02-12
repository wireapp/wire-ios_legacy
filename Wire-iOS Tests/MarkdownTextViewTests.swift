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
    
    // MARK: - Attributes
    
    // MARK: Headers
    
    func checkHeader(_ md: Markdown) {
        // given
        let text = "Oh Hai!"
        // when
        sut.markdownBarView(bar, didSelectMarkdown: md, with: bar.headerButton)
        sut.insertText(text)
        // then
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: 0, effectiveRange: &range)
        
        let attrs: [String: Any] = [
            MarkdownIDAttributeName: md,
            NSFontAttributeName: style.baseFont.withSize(style.headerSize(for: md)!).bold,
            NSForegroundColorAttributeName: style.baseFontColor,
            NSParagraphStyleAttributeName: style.baseParagraphStyle
        ]
        
        XCTAssertTrue(equal(attrs, result))
        XCTAssertEqual(NSMakeRange(0, text.length), range)
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
        // given
        let text = "Oh Hai!"
        // when
        sut.markdownBarView(bar, didSelectMarkdown: .bold, with: bar.boldButton)
        sut.insertText(text)
        // then
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: 0, effectiveRange: &range)
        
        let attrs: [String: Any] = [
            MarkdownIDAttributeName: Markdown.bold,
            NSFontAttributeName: style.baseFont.bold,
            NSForegroundColorAttributeName: style.baseFontColor,
            NSParagraphStyleAttributeName: style.baseParagraphStyle
        ]
        
        XCTAssertTrue(equal(attrs, result))
        XCTAssertEqual(NSMakeRange(0, text.length), range)
    }
    
    func testThatItCreatesCorrectAttributes_Italic() {
        // given
        let text = "Oh Hai!"
        // when
        sut.markdownBarView(bar, didSelectMarkdown: .italic, with: bar.italicButton)
        sut.insertText(text)
        // then
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: 0, effectiveRange: &range)
        
        let attrs: [String: Any] = [
            MarkdownIDAttributeName: Markdown.italic,
            NSFontAttributeName: style.baseFont.italic,
            NSForegroundColorAttributeName: style.baseFontColor,
            NSParagraphStyleAttributeName: style.baseParagraphStyle
        ]
        
        XCTAssertTrue(equal(attrs, result))
        XCTAssertEqual(NSMakeRange(0, text.length), range)
    }

    func testThatItCreatesCorrectAttributes_Code() {
        // given
        let text = "Oh Hai!"
        // when
        sut.markdownBarView(bar, didSelectMarkdown: .code, with: bar.codeButton)
        sut.insertText(text)
        // then
        var range = NSMakeRange(NSNotFound, 0)
        let result = sut.attributedText.attributes(at: 0, effectiveRange: &range)
        
        let attrs: [String: Any] = [
            MarkdownIDAttributeName: Markdown.code,
            NSFontAttributeName: style.codeFont,
            NSForegroundColorAttributeName: style.codeColor!,
            NSParagraphStyleAttributeName: style.baseParagraphStyle
        ]
        
        XCTAssertTrue(equal(attrs, result))
        XCTAssertEqual(NSMakeRange(0, text.length), range)
    }

}

private extension String {
    var length: Int {
        return (self as NSString).length
    }
}
