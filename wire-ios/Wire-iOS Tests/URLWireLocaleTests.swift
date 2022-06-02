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

class URLWireLocaleTests: XCTestCase {

    func testThatLocaleParameterGetsAppended() {
        // GIVEN
        let url = URL(string: "https://wire.com")!

        // WHEN
        let localizedURL = url.appendingLocaleParameter

        // THEN
        XCTAssertEqual(localizedURL.absoluteString, "https://wire.com?hl=en_US")
    }

    func testThatLocaleParameterGetsAppendedRightWithQuestionMarkAtTheEnd() {
        // GIVEN
        let url = URL(string: "https://wire.com?")!

        // WHEN
        let localizedURL = url.appendingLocaleParameter

        // THEN
        XCTAssertEqual(localizedURL.absoluteString, "https://wire.com?hl=en_US")
    }

    func testThatLocaleParameterGetsAppendedRightWithOtherParameters() {
        // GIVEN
        let url = URL(string: "https://wire.com?test=1&")!

        // WHEN
        let localizedURL = url.appendingLocaleParameter

        // THEN
        let urlComponents = URLComponents(url: localizedURL, resolvingAgainstBaseURL: false)!

        XCTAssertTrue(urlComponents.queryItems?.contains(URLQueryItem(name: "hl", value: "en_US")) == true)
        XCTAssertTrue(urlComponents.queryItems?.contains(URLQueryItem(name: "test", value: "1")) == true)
    }

    func testThatLocaleParameterGetsAppendedRightWithOtherParametersNoAndCharacter() {
        // GIVEN
        let url = URL(string: "https://wire.com?test=1")!

        // WHEN
        let localizedURL = url.appendingLocaleParameter

        // THEN
        let urlComponents = URLComponents(url: localizedURL, resolvingAgainstBaseURL: false)!

        XCTAssertTrue(urlComponents.queryItems?.contains(URLQueryItem(name: "hl", value: "en_US")) == true)
        XCTAssertTrue(urlComponents.queryItems?.contains(URLQueryItem(name: "test", value: "1")) == true)
    }

}
