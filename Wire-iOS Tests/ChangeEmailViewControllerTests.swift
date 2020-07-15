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

final class ChangeEmailViewControllerTests: XCTestCase {

    private func createSut(emailAddress: String?) -> UIViewController{
        let mockUser = MockUserType.createSelfUser(name: "User")
        mockUser.emailAddress = emailAddress

        let sut = ChangeEmailViewController(user: mockUser)
        let viewController = sut.wrapInNavigationController(navigationControllerClass: SettingsStyleNavigationController.self)
        
        viewController.view.backgroundColor = .black
        
        return viewController
    }
    
    func testForChangingExistingEmail() {
        // GIVEN & WHEN
        let viewController = createSut(emailAddress: "user@example.com")

        // THEN
        verify(matching: viewController)
    }

    func testForAddingEmail() {
        // GIVEN & WHEN
        let viewController = createSut(emailAddress: nil)
        
        // THEN
        verify(matching: viewController)
    }

}
