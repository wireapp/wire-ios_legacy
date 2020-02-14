//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class ChangeEmailViewControllerTests: ZMSnapshotTestCase {

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .black
    }

    func testForChangingExistingEmail() {
        // GIVEN
        let mockUser = MockUserType.createSelfUser(name: "User")
        mockUser.emailAddress = "user@example.com"

        // WHEN
        let sut = ChangeEmailViewController(user: mockUser)
        let viewController = sut.wrapInNavigationController(SettingsStyleNavigationController.self)

        // THEN
        verify(view: viewController.view)
    }

    func testForAddingEmail() {
        // GIVEN
        let mockUser = MockUserType.createSelfUser(name: "User")
        mockUser.emailAddress = nil

        // WHEN
        let sut = ChangeEmailViewController(user: mockUser)
        let viewController = sut.wrapInNavigationController(SettingsStyleNavigationController.self)

        // THEN
        verify(view: viewController.view)
    }

}
