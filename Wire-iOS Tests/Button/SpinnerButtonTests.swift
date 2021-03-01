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

    func createSut(title: String = "Deutsches Ipsum Dolor deserunt Schnaps has schnell Tollit Zauberer ius Polizei Saepe Schnaps elaboraret Ich habe fertig ne") {
        sut = SpinnerButton.alarmButton()
        sut.setTitle(title, for: .normal)
    }

    func testForShortTitle() {
        // GIVEN
        createSut(title: "Yes, I am safe.")

        // WHEN

        // THEN
        XCTAssert(sut.isEnabled)
        verifyInAllPhoneWidths(matching: sut)
    }

    func testForSpinnerOverlapsTitle() {
        // GIVEN
        createSut(title: "No, I need rescue. I am on the west side.")

        // WHEN
        sut.isLoading = true

        // THEN
        verifyInWidths(matching: sut,
                       widths: Set([300]),
                       snapshotBackgroundColor: UIColor.from(scheme: .contentBackground).withAlphaComponent(CGFloat.SpinnerButton.spinnerBackgroundAlpha))
    }

    func testForSpinnerIsHidden() {
        // GIVEN
        createSut()

        // WHEN

        // THEN
        XCTAssert(sut.isEnabled)
        verifyInAllPhoneWidths(matching: sut)
    }

    func testForSpinnerIsShown() {
        // GIVEN

        // WHEN

        // THEN
        ColorScheme.default.variant = .dark
        createSut()
        sut.isLoading = true

        verifyInAllPhoneWidths(matching: sut,
                               snapshotBackgroundColor: UIColor.from(scheme: .contentBackground),
                               named: "dark")

        ColorScheme.default.variant = .light
        createSut()
        sut.isLoading = true
        verifyInAllPhoneWidths(matching: sut,
                               snapshotBackgroundColor: UIColor.from(scheme: .contentBackground),
                               named: "light")
    }
}
