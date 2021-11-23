//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class UserRightTests: XCTestCase {

    // MARK: - Properties

    var selfUser: MockUserType!

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        selfUser = MockUserType()
        SelfUser.provider = SelfProvider(selfUser: selfUser)
    }

    override func tearDown() {
        selfUser = nil
        SelfUser.provider = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_SelfUserRights_NoSelfUser() {
        // Given
        SelfUser.provider = nil

        // Then
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .resetPassword))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editName))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editHandle))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editEmail))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editPhone))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editProfilePicture))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editAccentColor))
    }

    func test_SelfUserRights_ManagedByWire_NormalLogin() {
        // Given
        selfUser.managedByWire = true
        selfUser.usesCompanyLogin = false

        // Then
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .resetPassword))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editName))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editHandle))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editEmail))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editPhone))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editProfilePicture))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editAccentColor))
    }

    func test_SelfUserRights_ManagedByWire_SSOLogin() {
        // Given
        selfUser.managedByWire = true
        selfUser.usesCompanyLogin = true

        // Then
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .resetPassword))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editName))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editHandle))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editEmail))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editPhone))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editProfilePicture))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editAccentColor))
    }

    func test_SelfUserRights_NotManagedByWire_NormalLogin() {
        // Given
        selfUser.managedByWire = false
        selfUser.usesCompanyLogin = false

        // Then
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .resetPassword))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editName))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editHandle))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editEmail))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editPhone))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editProfilePicture))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editAccentColor))
    }

    func test_SelfUserRights_NotManagedByWire_SSOLogin() {
        // Given
        selfUser.managedByWire = false
        selfUser.usesCompanyLogin = true

        // Then
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .resetPassword))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editName))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editHandle))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editEmail))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editPhone))
        XCTAssertTrue(UserRight.selfUserIsPermitted(to: .editProfilePicture))
        XCTAssertFalse(UserRight.selfUserIsPermitted(to: .editAccentColor))
    }

}
