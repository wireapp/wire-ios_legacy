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

final class PasscodeSetupViewControllerTests: XCTestCase {
    var sut: PasscodeSetupViewController!

    override func tearDown() {
        sut = nil
    }

    private func fillPasscode() {
        sut.passcodeTextField.text = "P@ssc0de"
        sut.validationUpdated(sender: sut.passcodeTextField, error: nil)
    }

    func testForInitState() {
        verifyAllIPhoneSizes(createSut: { size in
            let vc = PasscodeSetupViewController(callback: nil,
                                                 useCompactLayout: size.height <= CGFloat.iPhone4Inch.height)
            return vc
        })
    }

    func testForInitStateInDarkTheme() {
        sut = PasscodeSetupViewController(callback: nil, variant: .dark, useCompactLayout: false)
        verify(matching: sut)
    }

    func testForPasscodePassed() {
        // GIVEN
        sut = PasscodeSetupViewController(callback: nil, useCompactLayout: false)
        fillPasscode()

        // WHEN
        PasscodeError.allCases.forEach {
            sut.setValidationLabelsState(errorReason: $0, passed: true)
        }

        // THEN
        verify(matching: sut)
    }
}
