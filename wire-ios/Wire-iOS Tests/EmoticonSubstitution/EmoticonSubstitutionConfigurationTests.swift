//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class EmoticonSubstitutionConfigurationTests: XCTestCase {

    func testThatParsingFileReturnsAConfiguration() {
        // Given

        // When

        let config = createEmoticonSubstitutionConfiguration(fileName: "emo-test-01.json")

        // Then
        XCTAssertNotNil(config)
    }

    func testThatParsingFileContainsCorrectRules() {
        // Given

        // When
        let config = createEmoticonSubstitutionConfiguration(fileName: "emo-test-01.json")
        XCTAssertNotNil(config)

        // Then
        XCTAssertNotNil(config.substitutionRules[":)"] as! String, "':)' shortcut not parsed")
        XCTAssertNotNil(config.substitutionRules[":-)"] as! String, "':-)' shortcut not parsed")

        XCTAssertEqual(config.substitutionRules[":)"] as! String, "😊")
        XCTAssertEqual(config.substitutionRules[":-)"] as! String, "😊")
    }

    func testThatParsingPerformanceForFullConfigurationIsEnoughForUsingOnMainQueue() {
        // EmoticonSubstitutionConfiguration is intended to be used on main thread,
        // so performance is important: parsing should not take much time.

        // Given

        measure({
            // When
            let config = createEmoticonSubstitutionConfiguration(fileName: "emoticons.min.json")

            // Then
            XCTAssertNotNil(config)
        })
    }

    func testThatShortcutsAreSortedCorrectly() {
        // Given

        // When
        let config = createEmoticonSubstitutionConfiguration(fileName: "emo-test-02.json")
        XCTAssertNotNil(config)

        // Then
        XCTAssertEqual(config.shortcuts[0] as! String, "}:-)")
        XCTAssertEqual(config.shortcuts[1] as! String, ":-)")
        XCTAssertEqual(config.shortcuts[2] as! String, ":)")
    }

}
