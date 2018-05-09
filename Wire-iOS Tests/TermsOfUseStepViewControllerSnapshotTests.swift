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

final class TermsOfUseStepViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: TermsOfUseStepViewController!
    var mockDevice: MockDevice!
    var mockParentViewControler: UIViewController!

    override func setUp() {
        super.setUp()

        mockDevice = MockDevice()
        sut = TermsOfUseStepViewController(device: mockDevice)

        recordMode = true
    }

    override func tearDown() {
        sut = nil
        mockDevice = nil

        super.tearDown()
    }


    func testForIPhone() {
        self.verify(view: sut.view)
    }

    func testForIPadRegular() {
        // GIVEN & WHEN
        mockDevice.userInterfaceIdiom = .pad
//        let traitCollection = UITraitCollection(horizontalSizeClass: .regular)
//        mockParentViewControler = UIViewController()
//        mockParentViewControler.addToSelf(sut)
//        mockParentViewControler.setOverrideTraitCollection(traitCollection, forChildViewController: sut)

        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: 768, height: 1024))
//        mockParentViewControler = nil

        // THEN
        self.verify(view: sut.view)
    }
}
