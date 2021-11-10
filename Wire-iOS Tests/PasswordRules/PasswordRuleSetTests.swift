//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class PasswordRuleSetTests: XCTestCase {

    var defaultRuleSet: PasswordRuleSet!

    override func setUp() {
        super.setUp()
        defaultRuleSet = PasswordRuleSet(minimumLength: 8, maximumLength: 15, allowedCharacters: [.unicode], requiredCharacters: [.digits, .uppercase, .lowercase, .special])
    }

    override func tearDown() {
        defaultRuleSet = nil
        super.tearDown()
    }

    // MARK: - Creation

    func testThatItAddsRequiredCharactersToAllowedSet() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 10, maximumLength: 100, allowedCharacters: [.asciiPrintable], requiredCharacters: [.custom("🐼")])

        // THEN
        let panda = Unicode.Scalar(Int(0x1F43C))!
        let pandaCharset = CharacterSet(charactersIn: "🐼")

        XCTAssertEqual(ruleSet.requiredCharacterSets, [.custom("🐼"): pandaCharset])
        XCTAssertTrue(ruleSet.allowedCharacterSet.contains(panda))
        XCTAssertTrue(ruleSet.allowedCharacterSet.isSuperset(of: CharacterSet.asciiPrintableSet))
    }

    // MARK: - Validation

    // @SF.Locking @TSFI.UserInterface @S0.1
    func testPasswordNotMatchingRuleSet() {
        // Valid
        checkPassword("Passw0rd!", expectedResult: .valid)
        checkPassword("Pass w0rd!", expectedResult: .valid)
        checkPassword("Päss w0rd!", expectedResult: .valid)
        checkPassword("Päss\u{1F43C}w0rd!", expectedResult: .valid)

        // Invalid
        checkPassword("aA1!aA1!aA1!aA1!aA1!", expectedResult: .invalid(violations: [.tooLong]))
        checkPassword("aA1!", expectedResult: .invalid(violations: [.tooShort]))
        checkPassword("A1!A1!A1!A1!", expectedResult: .invalid(violations: [.missingRequiredClasses([.lowercase])]))
        checkPassword("a1!a1!a1!a1!", expectedResult: .invalid(violations: [.missingRequiredClasses([.uppercase])]))
        checkPassword("aA!aA!aA!aA!", expectedResult: .invalid(violations: [.missingRequiredClasses([.digits])]))
        checkPassword("aA1aA1aA1aA1", expectedResult: .invalid(violations: [.missingRequiredClasses([.special])]))
        checkPassword("aaaaAAAA", expectedResult: .invalid(violations: [.missingRequiredClasses([.digits, .special])]))
    }

    func checkPassword(_ password: String, expectedResult: PasswordValidationResult, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(defaultRuleSet.validatePassword(password), expectedResult, file: file, line: line)
    }

    // @SF.Locking @TSFI.UserInterface @S0.1
    func testThatItDetectsDisallowedCharacter() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 8, maximumLength: 120, allowedCharacters: [.asciiPrintable], requiredCharacters: [.digits])
        let passwordWithHebrew = "1Passworד"

        // WHEN
        let result = ruleSet.validatePassword(passwordWithHebrew)

        // THEN
        let dalet = Unicode.Scalar(Int(0x05D3))!
        XCTAssertEqual(result, .invalid(violations: [.disallowedCharacter(dalet)]))
    }

    // MARK: - Codable

    func testThatItDecodesFromJSON() throws {
        // GIVEN
        let json = """
        {
            "new_password_minimum_length": 8,
            "new_password_maximum_length": 120,
            "new_password_allowed_characters": [
                "ascii-printable",
            ],
            "new_password_required_characters": [
                "digits",
                "[🐼]"
            ]
        }
        """

        // WHEN
        let jsonDecoder = JSONDecoder()
        let ruleSet = try jsonDecoder.decode(PasswordRuleSet.self, from: Data(json.utf8))

        // THEN
        let panda = Unicode.Scalar(Int(0x1F43C))!
        let pandaCharset = CharacterSet(charactersIn: "🐼")

        XCTAssertEqual(ruleSet.minimumLength, 8)
        XCTAssertEqual(ruleSet.maximumLength, 120)
        XCTAssertEqual(ruleSet.allowedCharacters, [.asciiPrintable, .digits, .custom("🐼")])
        XCTAssertTrue(ruleSet.allowedCharacterSet.contains(panda))
        XCTAssertTrue(ruleSet.allowedCharacterSet.isSuperset(of: CharacterSet.asciiPrintableSet))
        XCTAssertEqual(ruleSet.requiredCharacterSets, [.digits: .decimalDigits, .custom("🐼"): pandaCharset])
    }

    func testThatItEncodesToAppleKeychainFormat() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 10, maximumLength: 100, allowedCharacters: [.asciiPrintable], requiredCharacters: [.custom("🐼")])

        // WHEN
        let keychainFormat = ruleSet.encodeInKeychainFormat()

        // THEN
        XCTAssertEqual(keychainFormat, "minlength: 10; maxlength: 100; allowed: ascii-printable; allowed: [🐼]; required: [🐼];")
    }

}
