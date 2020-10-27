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

final class AppStateCalculatorTests: XCTestCase {

    var sut: AppStateCalculator!
    var appRootRouter: AppRootRouterMock!
    
    override func setUp() {
        super.setUp()
        sut = AppStateCalculator()
        appRootRouter = AppRootRouterMock()
        appRootRouter.isAppStateCalculatorCalled = false
        sut.delegate = appRootRouter
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests AppState Cases
    
    func testThatSessionManagerDidBlacklistCurrentVersion() {
        // WHEN
        sut.sessionManagerDidBlacklistCurrentVersion()

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testThatSessionManagerWillMigrateLegacyAccount() {
        // WHEN
        sut.sessionManagerWillMigrateLegacyAccount()

        // THEN
        XCTAssertEqual(sut.appState, .migrating)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
        
    func testThatSessionManagerDidJailbreakCurrentVersion() {
        // WHEN
        sut.sessionManagerDidBlacklistJailbrokenDevice()

        // THEN
        XCTAssertEqual(sut.appState, .jailbroken)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testThatSessionManagerWillMigrateAccount() {
        // GIVEN
        let account = Account(userName: "dummy", userIdentifier: UUID())
        
        // WHEN
        // Will first set the selected account
        sut.sessionManagerWillOpenAccount(account, userSessionCanBeTornDown: { })
        
        // THEN
        XCTAssertEqual(sut.appState, .loading(account: account, from: nil))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        appRootRouter.isAppStateCalculatorCalled = false
        
        // WHEN
        // Will migrate to that account
        sut.sessionManagerWillMigrateAccount(account)
        
        // THEN
        XCTAssertEqual(sut.appState, .migrating)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testThatSessionManagerWillNotMigrateAccount() {
        // GIVEN
        let account = Account(userName: "dummy", userIdentifier: UUID())
        let otherAccount = Account(userName: "otherDummy", userIdentifier: UUID())
        
        // WHEN
        // Will first set the selected account
        sut.sessionManagerWillOpenAccount(account, userSessionCanBeTornDown: { })
        
        // THEN
        XCTAssertEqual(sut.appState, .loading(account: account, from: nil))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        appRootRouter.isAppStateCalculatorCalled = false
        
        // WHEN
        // Will migrate to that account
        sut.sessionManagerWillMigrateAccount(otherAccount)
        
        // THEN
        XCTAssertFalse(appRootRouter.isAppStateCalculatorCalled)
    }

    func testThatWillLogout() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.unknownError, userInfo: nil)
        
        // WHEN
        sut.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: nil)

        // THEN
        XCTAssertEqual(sut.appState, .unauthenticated(error: error as NSError?))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testThatSessionManagerDidFailToLogin() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.invalidCredentials, userInfo: nil)
        let account = Account(userName: "dummy", userIdentifier: UUID())
        
        // WHEN
        sut.sessionManagerDidFailToLogin(account: account, error: error)

        // THEN
        XCTAssertEqual(sut.appState, .unauthenticated(error: nil))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testThatSessionManagerDidUpdateActiveUserSession() {
        // GIVEN
        let isDatabaseLocked = true
        
        // WHEN
        sut.sessionManagerDidUpdateActiveUserSession(isDatabaseLocked: isDatabaseLocked)

        // THEN
        XCTAssertEqual(sut.appState, .authenticated(completedRegistration: false,
                                                    databaseIsLocked: isDatabaseLocked))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    // MARK: - Tests AppState Changes
    
    func testApplicationDontTransitIfAppStateDontChange() {
        // WHEN
        sut.sessionManagerDidBlacklistCurrentVersion()

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        appRootRouter.isAppStateCalculatorCalled = false

        // WHEN
        sut.sessionManagerDidBlacklistCurrentVersion()

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted)
        XCTAssertFalse(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testApplicationDontTransitIfAppStateChange() {
        // WHEN
        sut.sessionManagerDidBlacklistCurrentVersion()

        // THEN
        XCTAssertEqual(sut.appState, .blacklisted)
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        let isDatabaseLocked = true
        appRootRouter.isAppStateCalculatorCalled = false

        // WHEN
        sut.sessionManagerDidUpdateActiveUserSession(isDatabaseLocked: isDatabaseLocked)

        // THEN
        XCTAssertEqual(sut.appState, .authenticated(completedRegistration: false,
                                                    databaseIsLocked: isDatabaseLocked))
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
    
    // MARK: - Tests When App Become Active
    
    func testApplicationDontTransitIfAppStateDontChangeWhenAppBecomeActive() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.accessTokenExpired, userInfo: nil)
        
        // WHEN
        // Initial App State Before Going in Background
        sut.sessionManagerDidFailToLogin(account: nil, error: error)
        
        // THEN
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        appRootRouter.isAppStateCalculatorCalled = false
        
        // WHEN
        sut.applicationDidEnterBackground()
        sut.applicationDidBecomeActive()
        
        // THEN
        XCTAssertFalse(appRootRouter.isAppStateCalculatorCalled)
    }
    
    func testApplicationTransitIfAppStateChangesWhenAppBecomesActive() {
        // GIVEN
        let error = NSError(code: ZMUserSessionErrorCode.accessTokenExpired, userInfo: nil)
        
        // WHEN
        // Initial AppState before going in background
        sut.sessionManagerDidFailToLogin(account: nil, error: error)
        
        // THEN
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
        
        // GIVEN
        appRootRouter.isAppStateCalculatorCalled = false
        
        // WHEN
        sut.applicationDidEnterBackground()
        // AppState changes when the app is in background
        sut.sessionManagerDidBlacklistCurrentVersion()
        sut.applicationDidBecomeActive()
        
        // THEN
        XCTAssertTrue(appRootRouter.isAppStateCalculatorCalled)
    }
}

class AppRootRouterMock: AppStateCalculatorDelegate {
    var isAppStateCalculatorCalled: Bool = false
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: @escaping () -> Void) {
        isAppStateCalculatorCalled = true
    }
}
