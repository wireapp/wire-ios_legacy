//
//  MarklightTextView.swift
//  Wire-iOS
//
//  Created by John Nguyen on 22.07.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
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
        sut.stripEmptyListItems()
        
        // then
        let expectation = ["1. example", "2. example", "", "- example", ""].joined(separator: "\n")
        XCTAssertEqual(sut.text, expectation)
        
    }
}
