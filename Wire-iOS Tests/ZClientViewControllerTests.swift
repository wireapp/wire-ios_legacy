
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

final class ZClientViewControllerTests: XCTestCase {
    var sut: ZClientViewController!
    var userSessionMock: MockZMUserSession!

    override func setUp() {
        super.setUp()

        let mockSelfUser = MockUserType.createSelfUser(name: "Bob")
        userSessionMock = MockZMUserSession()
        sut = ZClientViewController(account: Account.mockAccount(imageData: mockImageData), selfUser: mockSelfUser, userSession: userSessionMock)
    }

    override func tearDown() {
        sut = nil
        userSessionMock = nil

        super.tearDown()
    }

    func testForShowDataUsagePermissionDialogIfNeeded() {
        /// alert is not shown before the flags are set
        var alert = sut.createDataUsagePermissionDialogIfNeeded()
        XCTAssertNil(alert)

        /// GIVEN
        sut.needToShowDataUsagePermissionDialog = true
        sut.isComingFromRegistration = true

        alert = sut.createDataUsagePermissionDialogIfNeeded()
        XCTAssertNotNil(alert)

        /// WHEN
        sut.dataUsagePermissionDialogDisplayed = true

        /// should not show alert for the second time
        alert = sut.createDataUsagePermissionDialogIfNeeded()
        XCTAssertNil(alert)
    }

    func testThatCustomPasscodeWillBeDeleted_AfterUserNotifiedOfDisabledApplock() {
        // Given
        let appLock = AppLockModule.MockAppLockController()
        sut._userSession!.appLockController = appLock
        
        // When
        sut.appLockChangeWarningViewControllerDidDismiss()
        
        // Then
        XCTAssertEqual(appLock.methodCalls.deletePasscode.count, 1)
    }
}
