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

import Foundation
import XCTest
import WireCommonComponents
@testable import Wire

// cutAndPrefixedWithEllipsis
final class NSAttributedStringHighlightTests: XCTestCase {
    func testThatItReturnsEmptyStringOnEmpty() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 0, fittingIntoWidth: 1000)
        // THEN
        XCTAssertEqual(sut, prefixed)
    }

    func testThatItPrefixesShortString() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 0, fittingIntoWidth: 1000)
        // THEN
        XCTAssertEqual(String.ellipsis + sut, prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromZero() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world, Hello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 0, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(String.ellipsis + sut, prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromFirstWord() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world, Hello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 6, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(NSAttributedString(string: String.ellipsis + "world, Hello world, Hello world", attributes: [:]), prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromSecondWord() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world, Hello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 15, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(NSAttributedString(string: String.ellipsis + "world, Hello world, Hello world", attributes: [:]), prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromThirdWord() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world, Hello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 19, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(NSAttributedString(string: String.ellipsis + "Hello world, Hello world", attributes: [:]), prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromThirdWordNewline() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world,\nHello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: 15, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(NSAttributedString(string: String.ellipsis + "Hello world, Hello world", attributes: [:]), prefixed)
    }

    func testThatItCutsAndPrefixesLongStringFromTheEnd() {
        // GIVEN
        let sut = NSMutableAttributedString(string: "Hello world,\n Hello world, Hello world", attributes: [:])
        // WHEN
        let prefixed = sut.cutAndPrefixedWithEllipsis(from: (sut.string as NSString).length - 1, fittingIntoWidth: 100)
        // THEN
        XCTAssertEqual(NSAttributedString(string: String.ellipsis + "Hello world", attributes: [:]), prefixed)
    }
}

// allRanges on String
final class StringAllRangesOfStringTests: XCTestCase {
    func testThatItIgnoresEmptyString() {
        // GIVEN
        let sut = ""
        // WHEN
        let result = sut.allRanges(of: ["test"])
        // THEN
        XCTAssertTrue(result.isEmpty)
    }

    func testThatItIgnoresZeroQueries() {
        // GIVEN
        let sut = "test"
        // WHEN
        let result = sut.allRanges(of: [])
        // THEN
        XCTAssertTrue(result.isEmpty)
    }

    func testThatItIgnoresOneEmptyQuery() {
        // GIVEN
        let sut = "test"
        // WHEN
        let result = sut.allRanges(of: [""])
        // THEN
        XCTAssertTrue(result.isEmpty)
    }

    func testThatItFindsOneQueryOnce() {
        // GIVEN
        let sut = "the test string"
        // WHEN
        let result = sut.allRanges(of: ["test"])
        // THEN

        XCTAssertEqual(result.keys.count, 1)
        XCTAssertEqual(result.keys.first, "test")
        XCTAssertEqual(result["test"]!, [NSRange(location: 4, length: 4)])
    }

    func testThatItFindsOneQueryMultiple() {
        // GIVEN
        let sut = "the test string test"
        // WHEN
        let result = sut.allRanges(of: ["test"])
        // THEN
        XCTAssertEqual(result.keys.count, 1)
        XCTAssertEqual(result.keys.first, "test")
        XCTAssertEqual(result["test"]!, [NSRange(location: 4, length: 4), NSRange(location: 16, length: 4)])
    }

    func testThatItFindsManyQueriesOnce() {
        // GIVEN
        let sut = "the test string"
        // WHEN
        let result = sut.allRanges(of: ["test", "string"])
        // THEN
        XCTAssertEqual(result.keys.count, 2)
        XCTAssertTrue(result.keys.contains("test"))
        XCTAssertTrue(result.keys.contains("string"))
        XCTAssertEqual(result["test"]!, [NSRange(location: 4, length: 4)])
        XCTAssertEqual(result["string"]!, [NSRange(location: 9, length: 6)])
    }
}

// rangeOfStrings on String
final class StringRangeOfStringTests: XCTestCase {
    func testThatRangeOfStringsIgnoresEmptyStringNoQuery() {
        // GIVEN
        let string = ""
        // WHEN
        let result = string.range(of: [])
        // THEN
        XCTAssertEqual(result, .none)
    }

    func testThatRangeOfStringsIgnoresEmptyStringOneQuery() {
        // GIVEN
        let string = ""
        // WHEN
        let result = string.range(of: ["home"])
        // THEN
        XCTAssertEqual(result, .none)
    }

    func testThatRangeOfStringsFindsOneStringOneQuery() {
        // GIVEN
        let string = "the android is not home alone"
        // WHEN
        let result = string.range(of: ["home"])
        // THEN
        XCTAssertEqual(result, string.range(of: "home"))
    }

    func testThatRangeOfStringsFindsFirstStringsTwoQuery() {
        // GIVEN
        let string = "the android is not home alone"
        // WHEN
        let result = string.range(of: ["home", "alone"])
        // THEN
        XCTAssertEqual(result, string.range(of: "home"))
    }

    func testThatRangeOfStringsFindsSecondStringTwoQuery() {
        // GIVEN
        let string = "the android is not home alone"
        // WHEN
        let result = string.range(of: ["alone", "android"])
        // THEN
        XCTAssertEqual(result, string.range(of: "android"))
    }
}
