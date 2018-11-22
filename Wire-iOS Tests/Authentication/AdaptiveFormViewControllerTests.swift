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

class AdaptiveFormViewControllerTests: ZMSnapshotTestCase {

    var child: VerificationCodeStepViewController!
    var mockDevice: MockDevice! = MockDevice()
    var mockParentViewControler: UIViewController! = UIViewController()

    override func setUp() {
        super.setUp()
        child = VerificationCodeStepViewController(credential: "user@example.com")

        recordMode = true
    }

    override func tearDown() {
        child = nil
        mockDevice = nil
        mockParentViewControler = nil
        super.tearDown()
    }

    func testThatItHasCorrectLayout() {
        // GIVEN
        let sut = AdaptiveFormViewController(childViewController: child, device: mockDevice)
        mockParentViewControler.addChild(sut)

        // THEN
        verifyInAllDeviceSizes(view: sut.view) { _, isPad in
            let traitCollection: UITraitCollection
            if isPad {
                self.mockDevice.userInterfaceIdiom = .pad
                traitCollection = UITraitCollection(horizontalSizeClass: .regular)
            } else {
                self.mockDevice.userInterfaceIdiom = .phone
                traitCollection = UITraitCollection(horizontalSizeClass: .compact)
            }

            ///TODO: mock a parent for SUT
            self.mockParentViewControler.setOverrideTraitCollection(traitCollection, forChild: sut)
//            sut.setOverrideTraitCollection(traitCollection, forChild: self.child)
            sut.traitCollectionDidChange(nil)
//            self.child.traitCollectionDidChange(nil)
        }
    }

    func testForIPadRegular() {
        // GIVEN
        mockDevice.userInterfaceIdiom = .pad
        let sut = AdaptiveFormViewController(childViewController: child, device: mockDevice)
        mockParentViewControler.addChild(sut)

        // WHEN
        let traitCollection = UITraitCollection(horizontalSizeClass: .regular)

        mockParentViewControler.setOverrideTraitCollection(traitCollection, forChild: sut)
        sut.traitCollectionDidChange(nil)

        sut.view.frame = CGRect(origin: .zero, size: CGSize(width: 768, height: 1024))

        // THEN
        self.verify(view: sut.view)
    }


}
