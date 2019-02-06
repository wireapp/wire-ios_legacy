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

final class AppLockViewSnapshotTests: ZMSnapshotTestCase {
    
    var sut: AppLockView!
    
    override func setUp() {
        super.setUp()
        sut = AppLockView()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForReauthUI(){
        sut.showReauth = true

        /// workaround for "FBSnapshotTestCase calls traitCollectionDidChange with invalid argument - previousTraitCollection is unspecific and traitCollection is compact" issue
        let mocViewController = UIViewController()
        mocViewController.view.addSubview(sut)

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.fitInSuperview()


        verifyInAllDeviceSizes(view: mocViewController.view) { _, isPad in
            self.sut.userInterfaceSizeClass = { _ in return isPad ? .regular: .compact}
            self.sut.toggleConstraints()
        }
    }
}
