// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class PhoneNumberTests: XCTestCase {

    func testThatPhoneNumberStructWithLeadingZeroCanBeCompared() {
        // GIVEN
        let phoneNumber1 = PhoneNumber(fullNumber: "+49017612345678")
        let phoneNumber2 = PhoneNumber(fullNumber: "+4917612345678")

        // WHEN & THEN
        XCTAssertEqual(phoneNumber1, phoneNumber2)

    }

    func testThatDifferentNumbersAreNotEqual() {
        // GIVEN
        let phoneNumber1 = PhoneNumber(fullNumber: "+4917212345678")
        let phoneNumber2 = PhoneNumber(fullNumber: "+4917612345678")

        // WHEN & THEN
        XCTAssertNotEqual(phoneNumber1, phoneNumber2)
    }

    func testThatUSnumberAreCamparable() {
        // GIVEN
        let phoneNumber1 = PhoneNumber(countryCode: 1, numberWithoutCode: "5417543010")
        let phoneNumber2 = PhoneNumber(fullNumber: "+1-541-754-3010")

        // WHEN & THEN
        XCTAssertEqual(phoneNumber1, phoneNumber2)
    }
}
