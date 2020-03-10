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

final class SpinnerButtonTests: XCTestCase {
    var sut: SpinnerButton!

    override func tearDown() {
        sut = nil
    }

    func createSut() {
        sut = SpinnerButton(style: .empty)
        sut.setTitle("Deutsches Ipsum Dolor deserunt Schnaps has schnell Tollit Zauberer ius Polizei Saepe Schnaps elaboraret Ich habe fertig ne", for: .normal)
    }

    func testForSpinnerIsHidden() {
        //GIVEN
        createSut()

        //WHEN

        //THEN
        XCTAssert(sut.isEnabled)
        verifyInAllPhoneWidths(matching: sut)
    }

    func testForSpinnerIsShown() {
        //GIVEN

        //WHEN

        //THEN
        ColorScheme.default.variant = .dark
        createSut()
        sut.isLoading = true

        XCTAssertFalse(sut.isEnabled)

        verifyInAllPhoneWidths(matching:sut,
                               named: "dark")

        ColorScheme.default.variant = .light
        createSut()
        sut.isLoading = true
        verifyInAllPhoneWidths(matching:sut,
                               named: "light")
    }
}
