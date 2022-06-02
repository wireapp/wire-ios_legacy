////
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

class ZMAuthenticationStatusTests_PhoneAndEmailVerification: XCTestCase {

    var sut: ZMAuthenticationStatus!
    var delegate: MockAuthenticationStatusDelegate!
    var userInfoParser: MockUserInfoParser!

    override func setUp() {
        super.setUp()
        delegate = MockAuthenticationStatusDelegate()
        userInfoParser = MockUserInfoParser()

        let groupQueue = DispatchGroupQueue(queue: DispatchQueue.main)
        sut = ZMAuthenticationStatus(delegate: delegate,
                                     groupQueue: groupQueue,
                                     userInfoParser: userInfoParser)
    }

    func testThatItCanRequestPhoneVerificationCodeForLoginAfterRequestingTheCode() {

        // given
        let originalPhone = "+49(123)45678900"
        var phone: Any? = originalPhone
        _ = try? ZMPhoneNumberValidator.validateValue(&phone)

        // when
        sut.prepareForRequestingPhoneVerificationCode(forLogin: originalPhone)

        // then
        XCTAssertEqual(sut.currentPhase, .requestPhoneVerificationCodeForLogin)
        XCTAssertEqual(sut.loginPhoneNumberThatNeedsAValidationCode, phone as? String)
        XCTAssertNotEqual(originalPhone, phone as? String, "Should not have changed original phone")

    }

    func testThatItCanRequestEmailVerificationCodeForLoginAfterRequestingTheCode() {

        // GIVEN
        let originalEmail = "test@wire.com"
        var email: Any? = originalEmail
        _ = try? ZMEmailAddressValidator.validateValue(&email)

        // WHEN
        sut.prepareForRequestingEmailVerificationCode(forLogin: originalEmail)

        // THEN
        XCTAssertEqual(sut.currentPhase, .requestEmailVerificationCodeForLogin)
        XCTAssertEqual(sut.loginEmailThatNeedsAValidationCode, email as? String)
        XCTAssertEqual(originalEmail, email as? String, "Should not have changed original email")

    }
}
