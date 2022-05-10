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
import SnapshotTesting

final class UnlockViewControllerTests: ZMSnapshotTestCase {
    var sut: UnlockViewController!

    override func setUp() {
        super.setUp()
        let selfUser = MockUserType.createSelfUser(name: "Bobby McFerrin")
        sut = UnlockViewController(selfUser: selfUser)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func fillPasscode() {
        sut.validatedTextField.text = "Passcode"
        sut.validationUpdated(sender: sut.validatedTextField, error: nil)
    }

    func testForInitState() {
        verify(matching: sut)
    }

    func testForPasscodeFilled() {
        // GIVEN & WHEN
        fillPasscode()

        // THEN
        verify(matching: sut)
    }

    func testForErrorState() {
        // GIVEN
        fillPasscode()

        // WHEN
        sut.showWrongPasscodeMessage()

        // THEN
        verify(matching: sut)
    }

    func testForPasscodeRevealed() {
        // GIVEN
        fillPasscode()

        // WHEN
        sut.buttonPressed(UIButton())

        // THEN
        verify(matching: sut)
    }
}
