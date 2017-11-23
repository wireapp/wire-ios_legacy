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

class AccessoryTextFieldUnitTests: XCTestCase {

    class MockViewController : UIViewController, AccessoryTextFieldDelegate {
        var errorCounter = 0
        var successCounter = 0

        func validationErrorDidOccur(accessoryTextField: AccessoryTextField, error: TextFieldValidationError?) {
            errorCounter += 1
        }

        func validationSucceed(accessoryTextField: AccessoryTextField, length: Int?) {
            successCounter += 1
        }


    }

    func testThatSucceedAfterSendEditingChangedForDefaultTextField() {
        // GIVEN
        let sut = AccessoryTextField()
        let mockViewController = MockViewController()

        sut.accessoryTextFieldDelegate = mockViewController

        // WHEN
        sut.text = "blah"
        sut.sendActions(for: .editingChanged)

        // THEN
        XCTAssertTrue(mockViewController.errorCounter == 0 && mockViewController.successCounter == 1)
    }

    func testThatPasswordIsSecuredWhenSetToPasswordType() {
        // GIVEN
        let sut = AccessoryTextField(textFieldType: .password)
        let mockViewController = MockViewController()

        sut.accessoryTextFieldDelegate = mockViewController

        // WHEN
        sut.text = "blahblah"
        sut.sendActions(for: .editingChanged)

        // THEN
        XCTAssertTrue(sut.isSecureTextEntry && mockViewController.errorCounter == 0 && mockViewController.successCounter == 1)
    }
}

class AccessoryTextFieldTests: ZMSnapshotTestCase {
    override func setUp() {
        super.setUp()
    }

    func textFieldForSnapshots() -> AccessoryTextField {
        let accessoryTextField = AccessoryTextField()
        accessoryTextField.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        return accessoryTextField
    }

    func testThatItShowsEmptyTextField() {
        // GIVEN
        let sut = textFieldForSnapshots()
        // WHEN && THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsPlaceHolderText() {
        // GIVEN
        let sut = textFieldForSnapshots()

        // WHEN
        sut.placeholder = "team name"

        // THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsTextInputedAndConfrimButtonIsEnabled() {
        // GIVEN
        let sut = textFieldForSnapshots()

        // WHEN
        sut.text = "Wire Team"
        sut.textFieldDidChange(textField: sut)

        // THEN
        self.verify(view: sut.snapshotView())
    }

    func testThatItShowsPasswordInputedAndConfrimButtonIsEnabled() {
        // GIVEN
        let sut = AccessoryTextField(textFieldType: .password)
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)

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


