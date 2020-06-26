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
import SnapshotTesting

final class AccessoryTextFieldTests: XCTestCase {
    var sut: AccessoryTextField!

    override func setUp() {
        super.setUp()

        sut = AccessoryTextField()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItShowsEmptyTextField() {
        // GIVEN

        // WHEN && THEN
        verify(matching: sut)
    }

    func testThatItShowsPlaceHolderText() {
        // GIVEN

        // WHEN
        sut.placeholder = "TEAM NAME"

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsTextInputedAndConfrimButtonIsEnabled() {
        // GIVEN

        // WHEN
        sut.text = "Wire Team"
        sut.textFieldDidChange(textField: sut)

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsPasswordInputedAndConfirmButtonIsEnabled() {
        // GIVEN
        sut.kind = .password(isNew: false)

        // WHEN
        sut.text = "Password"
        sut.textFieldDidChange(textField: sut)

        // THEN
        verify(matching: sut)
    }

    func testThatItShowsGuidanceDot() {
        // GIVEN
        sut.kind = .password(isNew: false)
        sut.showGuidanceDot()

        // WHEN
        sut.text = "Password"
        sut.textFieldDidChange(textField: sut)

        // THEN
        verify(matching: sut)
    }
}
