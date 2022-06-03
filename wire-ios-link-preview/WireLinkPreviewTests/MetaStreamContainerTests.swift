// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireLinkPreview

class MetaStreamContainerTests: XCTestCase {

    var sut: MetaStreamContainer! = nil

    override func setUp() {
        super.setUp()
        sut = MetaStreamContainer()
    }

    func testThatItAppendsBytes_UTF8() {
        assertThatItAppendsBytes()
    }

    func testThatItAppendsBytes_Latin_1() {
        assertThatItAppendsBytes(encoding: .isoLatin1)
    }

    func testThatItAppendsBytes_ASCII() {
        assertThatItAppendsBytes(encoding: .ascii)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Lowercase() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head>")
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Capitalized() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</Head>")
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Uppercase() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</HEAD>")
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_WithSpaces() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head >", shouldUpdate: false)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Lowercase_Latin1() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head>", encoding: .isoLatin1)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Capitalized_Latin1() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</Head>", encoding: .isoLatin1)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Uppercase_Latin1() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</HEAD>", encoding: .isoLatin1)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_WithSpaces_Latin1() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head >", shouldUpdate: false, encoding: .isoLatin1)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Lowercase_ASCII() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head>", encoding: .ascii)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Capitalized_ASCII() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</Head>", encoding: .ascii)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_Uppercase_ASCII() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</HEAD>", encoding: .ascii)
    }

    func testThatItSets_reachedEndOfHead_WhenDataContainsHead_WithSpaces_ASCII() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head >", shouldUpdate: false, encoding: .ascii)
    }

    func testThatItExtractsTheHead_whenAllInOneLine() {
        let head = "<head>header</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head)
    }

    func testThatItExtractsTheHead_whenHeadStartIsMissing() {
        let html = "<!DOCTYPE html><html lang=\"en\">header</head>"
        assertThatItExtractsTheCorrectHead(html, expectedHead: html)
    }

    func testThatItExtractsTheHead_whenHeadStartIsMissingButContainsHeader() {
        let html = "<!DOCTYPE html><html lang=\"en\"><header>some</header>header</head>"
        assertThatItExtractsTheCorrectHead(html, expectedHead: html)
    }

    func testThatItExtractsTheHead_whenHeadStartIsAfterEnd() {
        let head = "<head>"
        let body = "<!DOCTYPE html><html lang=\"en\">header</head>"
        let html = body + head
        assertThatItExtractsTheCorrectHead(html, expectedHead: body)
    }

    func testThatItExtractsTheHead_whenOneASeparateLine() {
        let head = "<head>\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head)
    }

    func testThatItExtractsTheHead_whenItHasAttributes() {
        let head = "<head data-network=\"123\">\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head)
    }

    func testThatItExtractsTheHead_whenAllInOneLine_Latin1() {
        let head = "<head>header</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .isoLatin1)
    }

    func testThatItExtractsTheHead_whenOneASeparateLine_Latin1() {
        let head = "<head>\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .isoLatin1)
    }

    func testThatItExtractsTheHead_whenItHasAttributes_Latin1() {
        let head = "<head data-network=\"123\">\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .isoLatin1)
    }

    func testThatItExtractsTheHead_whenAllInOneLine_ASCII() {
        let head = "<head>header</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .ascii)
    }

    func testThatItExtractsTheHead_whenOneASeparateLine_ASCII() {
        let head = "<head>\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .ascii)
    }

    func testThatItExtractsTheHead_whenItHasAttributes_ASCII() {
        let head = "<head data-network=\"123\">\nheader\n</head>"
        let html = "<!DOCTYPE html><html lang=\"en\">\n\(head)"
        assertThatItExtractsTheCorrectHead(html, expectedHead: head, encoding: .ascii)
    }

    // MARK: - Helper

    func assertThatItExtractsTheCorrectHead(_ html: String, expectedHead: String, encoding: String.Encoding = .utf8, file: StaticString = #file, line: UInt = #line) {
        // when
        sut.addData(html.data(using: encoding)!)

        // then
        XCTAssertTrue(sut.reachedEndOfHead, "Should reach end of head", file: file, line: line)
        guard let head = sut.head else { return XCTFail("Head was nil", file: file, line: line) }
        XCTAssertEqual(head, expectedHead, "Should have expected head", file: file, line: line)
    }

    func assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead(_ head: String, shouldUpdate: Bool = true, encoding: String.Encoding = .utf8, line: UInt = #line) {
        // given
        let first = "First".data(using: encoding)!
        let second = "Head".data(using: encoding)!
        let fourth = "End".data(using: encoding)!

        // when & then
        sut.addData(first)
        XCTAssertFalse(sut.reachedEndOfHead, line: line)

        // when & then
        sut.addData(second)
        XCTAssertFalse(sut.reachedEndOfHead, line: line)

        // when & then
        sut.addData(head.data(using: encoding)!)
        XCTAssertEqual(sut.reachedEndOfHead, shouldUpdate, line: line)

        // when & then
        sut.addData(fourth)
        XCTAssertEqual(sut.reachedEndOfHead, shouldUpdate, line: line)
    }

    func assertThatItAppendsBytes(file: StaticString = #file, line: UInt = #line, encoding: String.Encoding = .utf8) {
        // given
        let first = "First".data(using: encoding)!
        let second = "Second".data(using: encoding)!

        // when
        sut.addData(first)

        // then
        XCTAssertEqual(sut.bytes, first)
        XCTAssertEqual(sut.stringContent, "First")

        // when
        sut.addData(second)

        // then
        let expected = "FirstSecond".data(using: encoding)!
        XCTAssertEqual(sut.bytes, expected)
        XCTAssertEqual(sut.stringContent, "FirstSecond")
    }

}
