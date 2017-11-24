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
import XCTest
@testable import Wire

final class AccessoryTextFieldUnitTests: XCTestCase {
    var sut: AccessoryTextField!
    var mockViewController: MockViewController!

    override func setUp() {
        super.setUp()
        sut = AccessoryTextField()
        mockViewController = MockViewController()
        sut.accessoryTextFieldDelegate = mockViewController
    }

    override func tearDown() {
        super.tearDown()
        mockViewController = nil
        sut = nil
    }

    class MockViewController: AccessoryTextFieldDelegate {
        var errorCounter = 0
        var successCounter = 0

        var lastError: TextFieldValidationError?

        func validationErrorDidOccur(accessoryTextField: AccessoryTextField, error: TextFieldValidationError?) {
            errorCounter += 1
            lastError = error
        }

        func validationSucceed(accessoryTextField: AccessoryTextField, length: Int?) {
            successCounter += 1
        }

    }

    fileprivate func checkNoErrorAndOneSucceed(textFieldType: AccessoryTextField.TextFieldType, text: String) {

        // WHEN
        sut.textFieldType = textFieldType
        sut.text = text
        sut.sendActions(for: .editingChanged)

        // THEN
        XCTAssert(mockViewController.errorCounter == 0)
        XCTAssert(mockViewController.successCounter == 1)
        XCTAssert(sut.confirmButton.isEnabled)
        XCTAssertNil(mockViewController.lastError)
    }

    fileprivate func checkOneErrorAndZeroSucceed(textFieldType: AccessoryTextField.TextFieldType, text: String?, expectedError: TextFieldValidationError) {

        // WHEN
        sut.textFieldType = textFieldType
        sut.text = text
        sut.sendActions(for: .editingChanged)

        // THEN
        XCTAssert(mockViewController.errorCounter == 1)
        XCTAssert(mockViewController.successCounter == 0)
        XCTAssertFalse(sut.confirmButton.isEnabled)
        XCTAssertEqual(expectedError, mockViewController.lastError)
    }

    // MARK: - happy cases

    func testThatSucceedAfterSendEditingChangedForDefaultTextField() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .unknown
        let text = "blah"

        // WHEN & THEN
        checkNoErrorAndOneSucceed(textFieldType: type, text: text)
    }

    func testThatPasswordIsSecuredWhenSetToPasswordType() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .password
        let text = "blahblah"

        // WHEN & THEN
        checkNoErrorAndOneSucceed(textFieldType: type, text: text)
        XCTAssertTrue(sut.isSecureTextEntry)
    }

    func testThatEmailIsValidatedWhenSetToEmailType() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .email
        let text = "blahblah@wire.com"

        // WHEN & THEN
        checkNoErrorAndOneSucceed(textFieldType: type, text: text)
    }

    func testThatNameIsValidWhenSetToNameType() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .name
        let text = "foo bar"

        // WHEN & THEN
        checkNoErrorAndOneSucceed(textFieldType: type, text: text)
    }

    // MARK: - unhappy cases
    func testThatOneCharacterNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .name
        let text = "a"

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .tooShort)
    }

    func testThat65CharacterNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .name
        let text = String(repeating: "a", count: 65)

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .tooLong)
    }

    func testThatNilNameIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .name

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: nil, expectedError: .tooShort)
    }

    func testThatInvalidEmailDoesNotPassValidation() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .email
        let text = "This is not a valid email address"

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .invalidEmail)
    }

    func testThat255CharactersEmailDoesNotPassValidation() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .email
        let suffix = "@wire.com"
        let text = String(repeating: "b", count: 255 - suffix.count) + suffix

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .tooLong)
    }

    func testThat7CharacterPasswordIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .password
        let text = String(repeating: "a", count: 7)

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .tooShort)
    }

    func testThat129CharacterPasswordIsInvalid() {
        // GIVEN
        let type: AccessoryTextField.TextFieldType = .password
        let text = String(repeating: "a", count: 129)

        // WHEN & THEN
        checkOneErrorAndZeroSucceed(textFieldType: type, text: text, expectedError: .tooLong)
    }

}

final class AccessoryTextFieldTests: ZMSnapshotTestCase {
    var sut: AccessoryTextField!
    
    override func setUp() {
        super.setUp()
        sut = AccessoryTextField()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testThatItShowsEmptyTextField() {
        // GIVEN

        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsPlaceHolderText() {
        // GIVEN

        // WHEN
        sut.placeholder = "team name"

        // THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsTextInputedAndConfrimButtonIsEnabled() {
        // GIVEN

        // WHEN
        sut.text = "Wire Team"
        sut.textFieldDidChange(textField: sut)

        // THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsPasswordInputedAndConfrimButtonIsEnabled() {
        // GIVEN
        sut.textFieldType = .password

        // WHEN
        sut.text = "Password"
        sut.textFieldDidChange(textField: sut)

        // THEN
        self.verify(view: sut.snapshotView())
    }
}

fileprivate extension UIView {
    func snapshotView() -> UIView {
        self.layer.speed = 0
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self
    }
}
