//
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

final class AppLockViewControllerSnapshotTests: XCTestCase {
    var sut: AppLockViewController!
    
    override func setUp() {
        super.setUp()

        sut = AppLockViewController()
        sut.viewDidLoad()
    }
    
    ///TODO: blur view is not visible in updated snapshots
    func testInitialState() {
        verify(matching: sut)
    }
    
    func testDimmedState() {
        sut.setContents(dimmed: true)
        verify(matching: sut)
    }
    
    func testReauthState() {
        sut.setReauth(visible: true)
        verify(matching: sut)
    }
}
