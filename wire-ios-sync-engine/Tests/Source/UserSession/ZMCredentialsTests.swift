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
import WireUtilities

class ZMCredentialTests: MessagingTest {

    func testThatItStoresPhoneCredentials() {
        let phoneNumber = "+4912345678"
        let code = "aabbcc"

        let sut = ZMPhoneCredentials(phoneNumber: phoneNumber, verificationCode: code)

        XCTAssertEqual(sut.phoneNumber, phoneNumber)
        XCTAssertEqual(sut.phoneNumberVerificationCode, code)

    }

    func testThatItNormalizesThePhoneNumber() {
        let originalPhoneNumber = "+49(123)45.6-78"
        var phone: Any? = originalPhoneNumber

        _ = try? ZMPhoneNumberValidator.validateValue(&phone)

        let code = "aabbcc"

        let sut = ZMPhoneCredentials(phoneNumber: phone as! String, verificationCode: code)

        XCTAssertEqual(sut.phoneNumber, phone as? String)
        XCTAssertEqual(sut.phoneNumberVerificationCode, code)
        XCTAssertNotEqual(phone as? String, originalPhoneNumber, "Should not have modified original")
    }
}
