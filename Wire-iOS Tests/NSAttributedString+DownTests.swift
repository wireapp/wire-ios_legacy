//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import XCTest
@testable import Wire

final class NSAttributedStringDownTests: XCTestCase {

    func testThatItReturnsH1Character() {
        // GIVEN
        let plainTextSymbol = "#"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)

    }

    func testThatItReturnsH2Characters() {
        // GIVEN
        let plainTextSymbol = "##"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsH3Characters() {
        // GIVEN
        let plainTextSymbol = "###"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsH4Characters() {
        // GIVEN
        let plainTextSymbol = "####"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsH5Characters() {
        // GIVEN
        let plainTextSymbol = "#####"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsH6Characters() {
        // GIVEN
        let plainTextSymbol = "######"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsBlockQuoteSymbol() {
        // GIVEN
        let plainTextSymbol = ">"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsTwoBlockQuoteSymbols() {
        // GIVEN
        let plainTextSymbol = ">>"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsThreeBlockQuoteSymbols() {
        // GIVEN
        let plainTextSymbol = ">>>"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsFourBlockQuoteSymbols() {
        // GIVEN
        let plainTextSymbol = ">>>>"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsTwoBoldSymbols() {
        // GIVEN
        let plainTextSymbol = "**"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsThreeBoldSymbols() {
        // GIVEN
        let plainTextSymbol = "***"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

    func testThatItReturnsFourBoldSymbols() {
        // GIVEN
        let plainTextSymbol = "****"

        // WHEN
        let sut  = NSMutableAttributedString.markdown(from: plainTextSymbol, style: NSAttributedString.style)

        // THEN
        XCTAssertEqual(sut.string, plainTextSymbol)
    }

}
