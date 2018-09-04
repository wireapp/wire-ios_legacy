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

final class ProfileViewControllerTests: ZMSnapshotTestCase {

    var sut: ProfileViewController!
    var mockUser: MockUser!
    
    override func setUp() {
        super.setUp()

        let user = MockUser.mockUsers()[0]
        mockUser = MockUser(for: user)
        mockUser.feature(withUserClients: 6)
    }
    
    override func tearDown() {
        sut = nil
        mockUser = nil

        super.tearDown()
    }

    func testForContextOneToOneConversation(){
        sut = ProfileViewController(user: mockUser!, context: .oneToOneConversation)
        self.verify(view: sut.view)
    }

    func testForDeviceListContext(){
        sut = ProfileViewController(user: mockUser!, context: .deviceList)
        self.verify(view: sut.view)
    }

    func testForWrapInNavigationController(){
        sut = ProfileViewController(user: mockUser!, context: .deviceList)
        let navWrapperController = sut.wrapInNavigationController()

        self.verify(view: navWrapperController.view)
    }
}
