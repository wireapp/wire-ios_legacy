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

final class String_PhoneNumberTests: XCTestCase {

    var sut: String!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatPhoneNumberWithSpaceIsParsed() {
        // GIVEN
        sut = "+41 86 079 209 36 37"

        // WHEN & THEN
        let presetCountry = Country(iso: "", e164: 49)

        if let (country, phoneNumberWithoutCountryCode) = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            XCTAssertEqual(country.iso, "ch")
            XCTAssertEqual(phoneNumberWithoutCountryCode, "860792093637")
        } else {
            XCTFail("Failed to parse phone number with space")
        }
    }

    func testThatPhoneNumberWithDash() {
        // GIVEN
        sut = "+41 86-079-209-36-37"

        // WHEN
        let presetCountry = Country(iso: "", e164: 49)

        if let (country, phoneNumberWithoutCountryCode) = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            // THEN
            XCTAssertEqual(country.iso, "ch")
            XCTAssertEqual(phoneNumberWithoutCountryCode, "860792093637")
        } else {
            XCTFail("Failed to parse phone number with dash")
        }
    }

    func testThatPhoneNumberWithLeadingZeroIsParsed() {
        // GIVEN
        sut = "+49017612345678"

        // WHEN & THEN
        let presetCountry = Country(iso: "", e164: 49)

        if let (country, phoneNumberWithoutCountryCode) = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            XCTAssertEqual(country.iso, "de")
            XCTAssertEqual(phoneNumberWithoutCountryCode, "017612345678")
        } else {
            XCTFail("Failed to parse phone number with leading zero")
        }
    }

    func testThatPhoneNumberWithoutSpaceIsParsed() {
        // GIVEN
        sut = "+41860792093637"

        // WHEN & THEN
        let presetCountry = Country(iso: "", e164: 49)

        if let (country, phoneNumberWithoutCountryCode) = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            XCTAssertEqual(country.iso, "ch")
            XCTAssertEqual(phoneNumberWithoutCountryCode, "860792093637")
        } else {
            XCTFail("Failed to parse phone number without space")
        }
    }

    func testThatPhoneNumberWithNoCountryCodeIsParsedAndNormized() {
        // GIVEN
        sut = "86 079 209 36 37"

        // WHEN & THEN
        let presetCountry = Country(iso: "", e164: 49)

        if let (country, phoneNumberWithoutCountryCode) = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            XCTAssertEqual(country.e164, 49)
            XCTAssertEqual(phoneNumberWithoutCountryCode, "860792093637")
        } else {
            XCTFail("Failed to parse phone number with no country code")
        }
    }

    func testThatInvalidPhoneNumberIsNotParsed() {
        // GIVEN
        sut = "860792093637860792093637860792093637"

        // WHEN & THEN
        let presetCountry = Country(iso: "", e164: 49)

        let ret = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry)
        XCTAssertNil(ret)
    }
}
