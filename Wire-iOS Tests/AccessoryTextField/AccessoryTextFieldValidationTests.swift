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

import XCTest
@testable import Wire

final class AccessoryTextFieldValidateionTests: XCTestCase {
    var sut: AccessoryTextField!
    var mockViewController: MockViewController!

    class MockViewController: UIViewController, TextFieldValidationDelegate {

        var errorCounter = 0
        var successCounter = 0

        var lastError: TextFieldValidator.ValidationError = .none

        func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError) {

            if error == .none {
                successCounter += 1
            } else {
                errorCounter += 1
                lastError = error
            }
        }
    }

    override func setUp() {
        super.setUp()

        sut = AccessoryTextField()
        mockViewController = MockViewController()
        sut.textFieldValidationDelegate = mockViewController
    }

    override func tearDown() {
        mockViewController = nil
        sut = nil

        super.tearDown()
    }

    fileprivate func checkSucceed(textFieldType: AccessoryTextField.Kind,
                                  text: String,
                                  file: StaticString = #file,
                                  line: UInt = #line) {

        // WHEN
        sut.kind = textFieldType
        sut.text = text
        sut.confirmButton.sendActions(for: .touchUpInside)

        // THEN
        XCTAssertEqual(mockViewController.errorCounter, 0, "Should not have an error", file: file, line: line)
        XCTAssertEqual(mockViewController.successCounter, 1, "Should have been success", file: file, line: line)
        XCTAssertEqual(mockViewController.lastError, .none, "Should not have error", file: file, line: line)
    }

    fileprivate func checkError(textFieldType: AccessoryTextField.Kind,
                                text: String?,
                                expectedError: TextFieldValidator.ValidationError,
                                file: StaticString = #file,
                                line: UInt = #line) {

        // WHEN
        sut.kind = textFieldType
        sut.text = text
        sut.confirmButton.sendActions(for: .touchUpInside)

        // THEN
        XCTAssertEqual(mockViewController.errorCounter, 1, "Should have an error", file: file, line: line)
        XCTAssertEqual(mockViewController.successCounter, 0, "Should not have been success", file: file, line: line)
        XCTAssertEqual(expectedError, mockViewController.lastError, "Error should be \(expectedError), was \(mockViewController.lastError)", file: file, line: line)
    }

    // MARK: - happy cases

    func testThatConfirmButtonIsEnabledWhenThereIsText() {
        // GIVEN
        XCTAssertFalse(sut.confirmButton.isEnabled)

        // WHEN
        sut.insertText("some")

        // THEN
        XCTAssertTrue(sut.confirmButton.isEnabled)
    }

    func testThatSucceedAfterSendEditingChangedForDefaultTextField() {
        // GIVEN
        let type: AccessoryTextField.Kind = .unknown
        let text = "blah"

        // WHEN & THEN
        checkSucceed(textFieldType: type, text: text)
    }

    func testThatSucceedAfterSendEditingChangedForPasswordTextField() {
        // GIVEN
        let type: AccessoryTextField.Kind = .password
        let text = "blahblah"

        // WHEN & THEN
        checkSucceed(textFieldType: type, text: text)
    }

    func testThatEmailIsValidatedWhenSetToEmailType() {
        // GIVEN
        let type: AccessoryTextField.Kind = .email
        let text = "blahblah@wire.com"

        // WHEN & THEN
        checkSucceed(textFieldType: type, text: text)
    }

    func testThatNameIsValidWhenSetToNameType() {
        // GIVEN
        let type: AccessoryTextField.Kind = .name
        let text = "foo bar"

        // WHEN & THEN
        checkSucceed(textFieldType: type, text: text)
    }

    // MARK: - unhappy cases
    func testThatOneCharacterNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.Kind = .name
        let text = "a"

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .tooShort(kind: type))
    }

    func testThat65CharacterNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.Kind = .name
        let text = String(repeating: "a", count: 65)

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .tooLong(kind: type))
    }

    func testThatNilNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.Kind = .name

        // WHEN & THEN
        checkError(textFieldType: type, text: nil, expectedError: .tooShort(kind: type))
    }

    func testThatInvalidEmailDoesNotPassValidation() {
        // GIVEN
        let type: AccessoryTextField.Kind = .email
        let text = "This is not a valid email address"

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .invalidEmail)
    }

    func testThat255CharactersEmailDoesNotPassValidation() {
        // GIVEN
        let type: AccessoryTextField.Kind = .email
        let suffix = "@wire.com"
        let text = String(repeating: "b", count: 255 - suffix.count) + suffix

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .tooLong(kind: type))
    }

    func testThat7CharacterPasswordIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.Kind = .password
        let text = String(repeating: "a", count: 7)

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .tooShort(kind: type))
    }

    func testThat129CharacterPasswordIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.Kind = .password
        let text = String(repeating: "a", count: 129)

        // WHEN & THEN
        checkError(textFieldType: type, text: text, expectedError: .tooLong(kind: type))
    }

    // MARK: - keyboard properties

    func testThatPasswordIsSecuredWhenSetToPasswordType() {
        // GIVEN
        let kind: AccessoryTextField.Kind = .password
        let text = "This is a valid password"

        // WHEN
        sut.kind = kind
        sut.text = text
        sut.sendActions(for: .editingChanged)

        // THEN
        XCTAssertTrue(sut.isSecureTextEntry)
    }
}
