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

final class AppStateControllerTests: XCTestCase {

    var sut: AppStateController!

    override func setUp() {
        super.setUp()
        sut = AppStateController()
        sut.isRunningSelfUnitTest = true
        sut.applicationDidBecomeActive()

        if let accounts = SessionManager.shared?.accountManager.accounts {
            for account in accounts {
                SessionManager.shared?.accountManager.remove(account)
            }
        }
    }

    override func tearDown() {

        sut = nil
        super.tearDown()
    }

    // MARK: - tests for .unauthenticated state handling

    func testThatErrorIsIgnoredWhenTheAppFrashInstalled() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.accessTokenExpired, userInfo: nil)

        // WHEN

        // When first time running the app, account is nil and error code is accessTokenExpired
        sut.sessionManagerDidFailToLogin(account: nil, error: error)

        // THEN
        let newAppState = sut.calculateAppState()

        // It should display the landing screen in AppRootViewController
        XCTAssertEqual(SessionManager.shared?.accountManager.accounts.count, 0)
        XCTAssertEqual(newAppState, .unauthenticated(error: nil))
    }

    func testThatErrorIsAssignedWhenTheAccountManagerHasSomeAccounts() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.accessTokenExpired, userInfo: nil)
        // When last time SessionManager store some accounts, but it is invalid
        let account = Account(userName: "dummy", userIdentifier: UUID())
        SessionManager.shared?.accountManager.addAndSelect(account)

        // WHEN
        sut.sessionManagerDidFailToLogin(account: nil, error: error)

        // THEN
        let newAppState = sut.calculateAppState()

        // It should display the login screen in AppRootViewController
        XCTAssertEqual(SessionManager.shared?.accountManager.accounts.count, 1)
        XCTAssertEqual(newAppState, .unauthenticated(error: error))
    }

    func testThatErrorAssignedWhenOtherDeivceRemovedCurrentlyAccount() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.clientDeletedRemotely, userInfo: nil)
        // When last time SessionManager store some accounts, but it is invalid
        let account = Account(userName: "dummy", userIdentifier: UUID())
        SessionManager.shared?.accountManager.addAndSelect(account)

        // WHEN
        sut.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: {})

        // THEN
        let newAppState = sut.calculateAppState()

        // It should display the login screen in AppRootViewController
        XCTAssertEqual(SessionManager.shared?.accountManager.accounts.count, 1)
        XCTAssertEqual(newAppState, .unauthenticated(error: error))
    }

    func testThatErrorAssignedWhenSwitchingToUnauthenticatedAccount() {
        // GIVEN
        // When last time SessionManager store some accounts, but it is invalid
        let account = Account(userName: "dummy", userIdentifier: UUID())
        SessionManager.shared?.accountManager.addAndSelect(account)
        let error = NSError(code: ZMUserSessionErrorCode.accessTokenExpired, userInfo: nil)

        // WHEN
        let accountUnauthenticated = Account(userName: "Unauthenticated", userIdentifier: UUID())
        SessionManager.shared?.accountManager.addAndSelect(accountUnauthenticated)
        sut.sessionManagerDidFailToLogin(account: accountUnauthenticated, error: error)

        // THEN
        let newAppState = sut.calculateAppState()

        // It should display the login screen in AppRootViewController
        XCTAssertGreaterThanOrEqual((SessionManager.shared?.accountManager.accounts.count)!, 0)
        XCTAssertEqual(newAppState, .unauthenticated(error: error))
    }
}
