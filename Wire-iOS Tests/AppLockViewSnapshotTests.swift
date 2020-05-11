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

extension UIView {
    var wrapInVicwController: UIViewController {
        let viewController = UIViewController()
        viewController.view = self

        return viewController
    }
}

final class AppLockViewSnapshotTests: XCTestCase {

    var sut: AppLockView!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForReauthUI_TouchID() {
        sut = AppLockView(authenticationType: .touchID)
        sut.showReauth = true

        verifyInAllDeviceSizes(matching: sut.wrapInVicwController)
    }

    func testForReauthUI_FaceID() {
        sut = AppLockView(authenticationType: .faceID)
        sut.showReauth = true

        verifyInAllDeviceSizes(matching: sut.wrapInVicwController)
    }

    func testForReauthUI_Password() {
        sut = AppLockView(authenticationType: .passcode)
        sut.showReauth = true

        verifyInAllDeviceSizes(matching: sut.wrapInVicwController)
    }

    func testForReauthUI_Unvailable() {
        sut = AppLockView(authenticationType: .unavailable)
        sut.showReauth = true

        verifyInAllDeviceSizes(matching: sut.wrapInVicwController)
    }

}
