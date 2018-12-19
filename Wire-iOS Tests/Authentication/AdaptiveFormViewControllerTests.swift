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
    var sut: AdaptiveFormViewController!

    // wrap the SUT in a mock navigator VC to mock the traitcollection's horizontalSizeClass.
    var mockParentViewControler: UINavigationController!

    override func setUp() {
        super.setUp()
        child = VerificationCodeStepViewController(credential: "user@example.com")
        sut = AdaptiveFormViewController(childViewController: child)
        mockParentViewControler = UINavigationController(rootViewController: sut)
    }

    override func tearDown() {
        child = nil
        mockParentViewControler = nil
        sut = nil
        super.tearDown()
    }

    func testThatItHasCorrectLayout() {
        verifyInAllDeviceSizes(view: sut.view) { _, isPad in
            let traitCollection: UITraitCollection
            if isPad {
                traitCollection = UITraitCollection(horizontalSizeClass: .regular)
            } else {
                traitCollection = UITraitCollection(horizontalSizeClass: .compact)
            }

            self.mockParentViewControler.setOverrideTraitCollection(traitCollection, forChild: self.sut)
            self.sut.traitCollectionDidChange(nil)
        }
    }
}
