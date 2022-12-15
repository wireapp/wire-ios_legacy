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
@testable import Wire

final class LocationSendViewControllerTests: ZMSnapshotTestCase {

    var sut: LocationSendViewController! = nil

    override func setUp() {
        super.setUp()
        sut = LocationSendViewController()
        sut.overrideUserInterfaceStyle = .light
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersSendControllerCorrectly_ShortAddress() {
        sut.address = "Hackescher Markt"
        verifyInAllPhoneWidths(view: sut.prepareForSnapshot())
    }

    func testThatItRendersSendControllerCorrectly_MediumAddress() {
        sut.address = "Hackescher Markt, 10178 Berlin"
        verifyInAllPhoneWidths(view: sut.prepareForSnapshot())
    }

    func testThatItRendersSendControllerCorrectly_LongAddress() {
        sut.address = "Hackescher Markt, Rosenthaler Straße 41, 10178 Berlin"
        verifyInAllPhoneWidths(view: sut.prepareForSnapshot())
    }

}

private extension UIViewController {
    func prepareForSnapshot() -> UIView {
        view.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return view
    }
}
