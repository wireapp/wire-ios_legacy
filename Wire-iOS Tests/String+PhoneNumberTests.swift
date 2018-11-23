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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatPhoneNumberWithSpaceIsParsed(){
        // GIVEN
        sut = "+41 86 079 209 36 37"

        // WHEN
        let presetCountry = Country(iso: "", e164: NSNumber(value: 49))
        let result = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            country, phoneNumber in
            if let country = country, let phoneNumber = phoneNumber {
                XCTAssertEqual(country.iso, "ch")
                XCTAssertEqual(phoneNumber, "860792093637")
            }
        }

        // THEN
        XCTAssertFalse(result)
    }

    func testThatPhoneNumberWithoutSpaceIsParsed(){
        // GIVEN
        sut = "+41860792093637"

        // WHEN
        let presetCountry = Country(iso: "", e164: NSNumber(value: 49))
        let result = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            country, phoneNumber in
            if let country = country, let phoneNumber = phoneNumber {
                XCTAssertEqual(country.iso, "ch")
                XCTAssertEqual(phoneNumber, "860792093637")
            }
        }

        // THEN
        XCTAssertFalse(result)
    }

    func testThatPhoneNumberWithNoCountryCodeIsNotParsed(){
        // GIVEN
        sut = "86 079 209 36 37"

        // WHEN
        let presetCountry = Country(iso: "", e164: NSNumber(value: 49))
        let result = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            country, phoneNumber in
            XCTAssertNil(country)
            XCTAssertNil(phoneNumber)
        }

        // THEN
        XCTAssert(result)
    }

    func testThatInvalidPhoneNumberIsNotParsed(){
        // GIVEN
        sut = "860792093637860792093637860792093637"

        // WHEN
        let presetCountry = Country(iso: "", e164: NSNumber(value: 49))
        let result = sut.shouldInsertAsPhoneNumber(presetCountry: presetCountry) {
            country, phoneNumber in
            XCTAssertNil(country)
            XCTAssertNil(phoneNumber)
        }

        // THEN
        XCTAssertFalse(result)
    }
}
