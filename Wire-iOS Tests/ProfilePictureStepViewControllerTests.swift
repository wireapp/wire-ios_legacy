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

final class ProfilePictureStepViewControllerTests: ZMSnapshotTestCase {
    
    var sut: ProfilePictureStepViewController!
    var configurationBlock: ((UIView, Bool) -> Void)!

    override func setUp() {
        super.setUp()

        accentColor = .strongBlue

        let user = ZMIncompleteRegistrationUser()
        sut = ProfilePictureStepViewController(unregisteredUser: user)

        configurationBlock = {[weak self] _, _ in
            guard let weakSelf = self else { return }

            weakSelf.sut.loadViewIfNeeded()
            weakSelf.sut.viewWillAppear(false)
            weakSelf.sut.showLoadingView = false
            weakSelf.sut.profilePictureImageView.image = weakSelf.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItRendersTheViewControllerCorrectlyInAllDeviceSizes() {
        verifyInAllDeviceSizes(view: sut.view, configuration: configurationBlock!)

    }
}
