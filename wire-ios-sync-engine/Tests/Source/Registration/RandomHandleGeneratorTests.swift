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

import Foundation
import XCTest
@testable import WireSyncEngine

class RandomHandleGeneratorTests: XCTestCase {

    func testNormalizationOfString() {
        XCTAssertEqual("Maria LaRochelle".normalizedForUserHandle, "marialarochelle")
        XCTAssertEqual("Mêrié \"LaRöche'lle\"".normalizedForUserHandle, "merielarochelle")
        XCTAssertEqual("Maria I ❤️🍕".normalizedForUserHandle, "mariai")
        XCTAssertEqual(".-/Maria\\-.".normalizedForUserHandle, "maria")
        XCTAssertEqual("苹果".normalizedForUserHandle, "pingguo")
        XCTAssertEqual("תפוח ".normalizedForUserHandle, "tpwh")
        XCTAssertEqual("सेवफलम्".normalizedForUserHandle, "sevaphalam")
        XCTAssertEqual("μήλο".normalizedForUserHandle, "melo")
        XCTAssertEqual("Яблоко".normalizedForUserHandle, "abloko")
        XCTAssertEqual("خطای سطح دسترسی".normalizedForUserHandle, "khtaysthdstrsy")
        XCTAssertEqual("ᑭᒻᒥᓇᐅᔭᖅ".normalizedForUserHandle, "") // unfortunately, Apple's string library can't handle inuktitut
        XCTAssertEqual("    Maria LaRochelle Von Schwerigstein ".normalizedForUserHandle, "marialarochellevonsch")
        XCTAssertEqual(" \n\t Maria LaRochelle Von Schwerigstein ".normalizedForUserHandle, "marialarochellevonsch")
        XCTAssertEqual("🐙☀️".normalizedForUserHandle, "")
    }

    func testHandleGenerationWithValidDisplayName() {

        // GIVEN
        let variations = 3
        let expectedNormalized = "marialarochellevonsch"

        // WHEN
        var handles: [String] = WireSyncEngine.RandomHandleGenerator.generatePossibleHandles(
                displayName: "Maria La Rochelle Von Schwerigstein",
                alternativeNames: variations
            ).reversed() // there is no popFirst, so I will revert to be able to use popLast

        // THEN
        XCTAssertGreaterThan(handles.count, 5 * (variations + 1))
        XCTAssertLessThanOrEqual(handles.count, 50)

        XCTAssertEqual(handles.filter({ $0.utf8.count > 21 }), [])

        // first is normalized name
        XCTAssertEqual(handles.popLast(), expectedNormalized)

        // then with digits 1 to 9
        (1..<10).forEach {
            XCTAssertEqual(handles.popLast(), expectedNormalized.truncated(at: 20)+"\($0)")
        }

        // then 4 with two digits
        let twoDigits = try! NSRegularExpression(pattern: "^\(expectedNormalized.truncated(at: 19))[0-9]{2}$", options: [])
        (0..<4).forEach { _ in
            let handle = handles.popLast()
            XCTAssertTrue(twoDigits.matches(handle), "\(String(describing: handle)) does not match")
        }

        // then 4 with three digits
        let threeDigits = try! NSRegularExpression(pattern: "^\(expectedNormalized.truncated(at: 18))[0-9]{3}$", options: [])
        (0..<4).forEach { _ in
            let handle = handles.popLast()
            XCTAssertTrue(threeDigits.matches(handle), "\(String(describing: handle)) does not match")
        }

        // then 6 with four digits
        let sixDigits = try! NSRegularExpression(pattern: "^\(expectedNormalized.truncated(at: 17))[0-9]{4}$", options: [])
        (0..<6).forEach { _ in
            let handle = handles.popLast()
            XCTAssertTrue(sixDigits.matches(handle), "\(String(describing: handle)) does not match")
        }

        // now random words
        XCTAssertGreaterThan(handles.count, variations*4)
        handles.forEach {
            XCTAssertFalse($0.hasPrefix(expectedNormalized))
        }
    }

    func testThatItSuggestsHandlesWithTwoCharacters() {

        // GIVEN
        let expectedFirstNormalized = "po"

        // WHEN
        let handles: [String] = WireSyncEngine.RandomHandleGenerator.generatePossibleHandles(displayName: "Po", alternativeNames: 0)

        // THEN
        XCTAssertEqual(handles.first, expectedFirstNormalized)
    }

    func testThatItDoesNotSuggestsHandlesWithOneCharacters() {

        // WHEN
        let handles: [String] = WireSyncEngine.RandomHandleGenerator.generatePossibleHandles(displayName: "P", alternativeNames: 0)

        // THEN
        guard let handle = handles.first else { XCTFail(); return }
        XCTAssertGreaterThan(handle.utf8.count, 2)
    }
}

// MARK: - Helpers
extension NSRegularExpression {

    /// Check if the string has a match for this regex
    fileprivate func matches(_ string: String?) -> Bool {
        guard let string = string else {
            return false
        }

        return !self.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)).isEmpty
    }
}
