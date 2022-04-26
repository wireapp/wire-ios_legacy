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

final class ButtonTests: XCTestCase {
    var sut: Wire.Button!

    override func setUp() {
        sut = Button(style: .empty, fontSpec: .smallLightFont)
    }

    override func tearDown() {
        sut = nil
    }

    func testForLongTitleCanBeWrapped() {
        // GIVEN
        sut.titleLabel?.lineBreakMode = .byWordWrapping
        sut.titleLabel?.numberOfLines = 0
        sut.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 20)
        sut.setTitle("Dummy button with long long long long long long long long title", for: .normal)

        // WHEN & THEN
        verifyInAllPhoneWidths(matching: sut)
    }

    func testForStyleChangedToFull() {
        // GIVEN
        sut.setTitle("Dummy button", for: .normal)

        // WHEN
        sut.style = .full

        // THEN
        verify(matching: sut)
    }

    func testForStyleChangedToEmpty() {
        // GIVEN
        sut.setTitle("Dummy button", for: .normal)

        // WHEN
        sut.style = .full
        sut.style = .empty

        // THEN
        verify(matching: sut)
    }
}
