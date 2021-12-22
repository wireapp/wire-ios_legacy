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
@testable import Wire

final class ChangePhoneViewControllerTests: XCTestCase {
    var sut: ChangePhoneViewController!

    override func setUp() {
        super.setUp()
        sut = ChangePhoneViewController()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForADigitIsAllowed() {
        // GIVEN
        // call viewDidLoad
        sut.loadViewIfNeeded()

        // make table view's cells visible
        sut.view.frame = CGRect(origin: .zero, size: defaultIPhoneSize)
        sut.view.layoutIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = sut.tableView.cellForRow(at: indexPath) as? PhoneNumberInputCell {
            // WHEN
            let input = cell.phoneInputView.input
            let range = input.endIndex ..< input.endIndex
            let changed = cell.phoneInputView.shouldChangeCharacters(in: NSRange(range, in: input), replacementString: "0")

            // THEN
            XCTAssertTrue(changed)
        } else {
            XCTFail()
        }
    }
}
