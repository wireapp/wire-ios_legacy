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
@testable import WireDataModel

class UnregisteredUserTests: XCTestCase {

    func testThatItValidatesTheUserName() {
        // GIVEN
        let validName = "Maria"
        let longName = "Ro" + String(repeating: "x", count: 200) + "y"
        let shortName = "M"

        // THEN
        XCTAssertTrue(UnregisteredUser.normalizedName(validName).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedName(longName).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedName(shortName).isValid)
    }

    func testThatItValidatesTheEmail() {
        // GIVEN
        let validEmail = "anette@foo.bar"
        let invalidEmail = "kathrine@"

        // THEN
        XCTAssertTrue(UnregisteredUser.normalizedEmailAddress(validEmail).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedEmailAddress(invalidEmail).isValid)
    }

    func testThatItValidatesThePhoneNumber() {
        // GIVEN
        let validPhone = "+4912345678"
        let invalidPhone = "+49" + String(repeating: "0", count: 100)

        // WHEN
        XCTAssertTrue(UnregisteredUser.normalizedPhoneNumber(validPhone).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedPhoneNumber(invalidPhone).isValid)
    }

    func testThatItDoesNotValidateAPhoneNumberWithLettersWithTheRightError() {
        // GIVEN
        let phoneWithLetters = "+49abcdefg"
        let shortPhoneWithLetters = "ab"

        // WHEN
        let normalizedPhoneWithLetters = UnregisteredUser.normalizedPhoneNumber(phoneWithLetters)
        let normalizedShortPhoneWithLetters = UnregisteredUser.normalizedPhoneNumber(shortPhoneWithLetters)

        // THEN
        assertNormalizationErrorCode(normalizedPhoneWithLetters, .phoneNumberContainsInvalidCharacters)
        assertNormalizationErrorCode(normalizedShortPhoneWithLetters, .phoneNumberContainsInvalidCharacters)
    }

    func testThatItDoesNotValidateAShortPhoneNumberWithTheRightError() {
        // GIVEN
        let shortPhone = "+49"

        // WHEN
        let normalizedPhone = UnregisteredUser.normalizedPhoneNumber(shortPhone)

        // THEN
        assertNormalizationErrorCode(normalizedPhone, .tooShort)
    }

    func testThatItDoesNotValidateALongPhoneNumberWithTheRightError() {
        // GIVEN
        let longPhone = "+4900000002132131241241234234"

        // WHEN
        let normalizedPhone = UnregisteredUser.normalizedPhoneNumber(longPhone)

        // THEN
        assertNormalizationErrorCode(normalizedPhone, .tooLong)
    }

    func testThatItNormalizesThePhoneNumber() {
        // GIVEN
        let phoneNumber = "+49(123)45.6-78"

        // WHEN
        let normalizedPhoneNumber = UnregisteredUser.normalizedPhoneNumber(phoneNumber)

        // THEN
        assertNormalizationValue(normalizedPhoneNumber, "+4912345678")
    }

    func testThatItNormalizesTheEmailAddress() {
        // GIVEN
        let email = " john.doe@gmail.com "

        // WHEN
        let normalizedEmail = UnregisteredUser.normalizedEmailAddress(email)

        // THEN
        assertNormalizationValue(normalizedEmail, "john.doe@gmail.com")
    }

    func testThatItReturnsCompletedWhenUserIsComplete_Phone() {
        // GIVEN
        let user = UnregisteredUser()

        // WHEN
        user.name = "Mario"
        user.credentials = .phone("+49123456789")
        user.verificationCode = "123456"
        user.accentColorValue = .softPink
        user.acceptedTermsOfService = true
        user.marketingConsent = false

        // THEN
        XCTAssertTrue(user.isComplete)
        XCTAssertFalse(user.needsPassword)
    }

    func testThatItReturnsCompletedWhenUserIsComplete_Email() {
        // GIVEN
        let user = UnregisteredUser()

        // WHEN
        user.name = "Mario"
        user.credentials = .email("alexis@example.com")
        user.verificationCode = "123456"
        user.accentColorValue = .softPink
        user.acceptedTermsOfService = true
        user.marketingConsent = false

        // WHEN: we check if the user needs a password
        XCTAssertFalse(user.isComplete)
        XCTAssertTrue(user.needsPassword)

        // WHEN: we provide the password
        user.password = "12345678"

        // THEN
        XCTAssertTrue(user.isComplete)
        XCTAssertFalse(user.needsPassword)
    }

}

// MARK: - Helpers

private extension UnregisteredUserTests {

    func assertNormalizationValue<T>(_ normalizationResult: NormalizationResult<T>, _ expectedValue: T) where T: Equatable {
        guard case let .valid(value) = normalizationResult else {
            XCTFail()
            return
        }

        XCTAssertEqual(value, expectedValue)
    }

    func assertNormalizationErrorCode<T>(_ normalizationResult: NormalizationResult<T>, _ expectedCode: ZMManagedObjectValidationErrorCode) {
        guard case let .invalid(errorCode) = normalizationResult else {
            XCTFail()
            return
        }

        XCTAssertEqual(errorCode, expectedCode)
    }

}
