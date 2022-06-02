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

@testable import WireSyncEngine
import XCTest

class SearchRequestTests: MessagingTest {

    func testThatItTruncatesTheQuery() {
        // given
        let croppedString = "f".padding(toLength: 200, withPad: "o", startingAt: 0)
        let tooLongString = "f".padding(toLength: 300, withPad: "o", startingAt: 0)

        // when
        let request = SearchRequest(query: tooLongString, searchOptions: [])

        // then
        XCTAssertEqual(request.query.string, croppedString)
    }

    func testThatItNormalizesTheQuery() {
        // given
        let query = "Ã.b.ć "

        // when
        let request = SearchRequest(query: query, searchOptions: [])

        // then
        XCTAssertEqual(request.normalizedQuery, "abc")
    }

    func testThatItParsesHandleAndDomain() throws {
        // without leading @
        try assertHandleAndDomain(from: "john@example.com", handle: "john", domain: "example.com")

        // with leading @
        try assertHandleAndDomain(from: "@john@example.com", handle: "john", domain: "example.com")

        // with double @
        try assertHandleAndDomain(from: "@@john@example.com", handle: "john", domain: "example.com")

        // with trailing whitespace
        try assertHandleAndDomain(from: "john@example.com ", handle: "john", domain: "example.com")

        // with leading whitespace
        try assertHandleAndDomain(from: " john@example.com ", handle: "john", domain: "example.com")

        // missing domain
        try assertHandleAndDomain(from: "@john", handle: "john", domain: nil)
    }

    // MARK: - Helpers

    func assertHandleAndDomain(
        from query: String,
        handle expectedHandle: String,
        domain expectedDomain: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // when
        let request = SearchRequest(query: query, searchOptions: [])

        // then
        XCTAssertEqual(request.query.string, expectedHandle, file: file, line: line)
        XCTAssertEqual(request.searchDomain, expectedDomain, file: file, line: line)
    }

}
