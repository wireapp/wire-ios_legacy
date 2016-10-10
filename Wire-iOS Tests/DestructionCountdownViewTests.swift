//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography
@testable import Wire


class DestructionCountdownViewTests: ZMSnapshotTestCase {

    var sut: DestructionCountdownView!

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        sut = DestructionCountdownView()
        recordMode = true
    }

    func testThatItRendersCorrectlyInInitialState() {
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_80_Percent_Fraction() {
        sut.update(fraction: 0.8)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_60_Percent_Fraction() {
        sut.update(fraction: 0.6)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_50_Percent_Fraction() {
        sut.update(fraction: 0.5)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_40_Percent_Fraction() {
        sut.update(fraction: 0.4)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_20_Percent_Fraction() {
        sut.update(fraction: 0.2)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

    func testThatItRendersCorrectly_0_Percent_Fraction() {
        sut.update(fraction: 0)
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
        verify(view: sut)
    }

}
