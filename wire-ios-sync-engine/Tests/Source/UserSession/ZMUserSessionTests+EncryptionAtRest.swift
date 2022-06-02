////
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

import Foundation
import LocalAuthentication
@testable import WireSyncEngine

class MockUserSessionDelegate: NSObject, UserSessionDelegate {

    var calledSetEncryptionAtRest: (Bool, Account, EncryptionKeys)?
    func setEncryptionAtRest(enabled: Bool, account: Account, encryptionKeys: EncryptionKeys) {
        calledSetEncryptionAtRest = (enabled, account, encryptionKeys)
    }

    func userSessionDidUnlock(_ session: ZMUserSession) {

    }

    func clientRegistrationDidSucceed(accountId: UUID) { }

    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) { }

    var calleduserDidLogout: (Bool, UUID)?
    func userDidLogout(accountId: UUID) {
        calleduserDidLogout = (true, accountId)
    }

    func authenticationInvalidated(_ error: NSError, accountId: UUID) { }
}

final class ZMUserSessionTests_EncryptionAtRest: ZMUserSessionTestsBase {

    private var activityManager: MockBackgroundActivityManager!
    private var factory: BackgroundActivityFactory!

    private var account: Account {
        Account(userName: "", userIdentifier: ZMUser.selfUser(in: syncMOC).remoteIdentifier)
    }

    override func setUp() {
        super.setUp()

        activityManager = MockBackgroundActivityManager()
        factory = BackgroundActivityFactory.shared
        factory.activityManager = activityManager
    }

    override func tearDown() {
        factory = nil
        activityManager = nil
        try! EncryptionKeys.deleteKeys(for: account)

        super.tearDown()
    }

    private func setEncryptionAtRest(enabled: Bool, file: StaticString = #file, line: UInt = #line) {
        try? sut.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

    // MARK: - Database migration

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsEnabled() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try sut.setEncryptionAtRest(enabled: true)

        // then
        XCTAssertNotNil(userSessionDelegate.calledSetEncryptionAtRest)
        XCTAssertEqual(userSessionDelegate.calledSetEncryptionAtRest?.0, true)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDelegateIsCalled_WhenEncryptionAtRestIsDisabled() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)
        let userSessionDelegate = MockUserSessionDelegate()
        sut.delegate = userSessionDelegate

        // when
        try sut.setEncryptionAtRest(enabled: false)

        // then
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertNotNil(userSessionDelegate.calledSetEncryptionAtRest)
        XCTAssertEqual(userSessionDelegate.calledSetEncryptionAtRest?.0, false)
    }

    // MARK: - Database locking/unlocking

    func testThatDatabaseIsUnlocked_WhenEncryptionAtRestIsDisabled() {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()

        // when
        setEncryptionAtRest(enabled: false)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterActivatingEncryptionAtRest() {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()

        // when
        setEncryptionAtRest(enabled: true)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterDeactivatingEncryptionAtRest() {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // when
        setEncryptionAtRest(enabled: false)

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterUnlockingDatabase() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let context = LAContext()
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try sut.unlockDatabase(with: context)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsLocked_AfterEnteringBackground() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // when
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertTrue(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsLocked_AfterBackgroundTaskCompletesInTheBackground() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // when
        let activity = factory.startBackgroundActivity(withName: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        factory.endBackgroundActivity(activity)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertTrue(sut.isDatabaseLocked)
    }

    func testThatDatabaseIsNotLocked_IfThereIsAnActiveBackgroundTask() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // when
        let activity = factory.startBackgroundActivity(withName: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isDatabaseLocked)
        factory.endBackgroundActivity(activity)
    }

    // @SF.Locking @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsLocked_WhenTheCustomTimeoutHasExpiredInTheBackground() throws {
        // given
        factory.backgroundTaskTimeout = 2

        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // when
        _ = factory.startBackgroundActivity(withName: "Activity 1")!
        application.simulateApplicationDidEnterBackground()
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertNotNil(sut.managedObjectContext.encryptionKeys)

        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "The expiration handler is called.")], timeout: 4.0)

        // then
        XCTAssertTrue(sut.isDatabaseLocked)
        XCTAssertNil(sut.managedObjectContext.encryptionKeys)
    }

    // MARK: - Database lock handler/observer

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseLockedHandlerIsCalled_AfterDatabaseIsLocked() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        // expect
        let databaseIsLocked = expectation(description: "database is locked")
        var token: Any? = sut.registerDatabaseLockedHandler { (isDatabaseLocked) in
            if isDatabaseLocked {
                databaseIsLocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        sut.applicationDidEnterBackground(nil)
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // cleanup
        token = nil
    }

    func testThatDatabaseLockedHandlerIsCalled_AfterUnlockingDatabase() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // expect
        let databaseIsUnlocked = expectation(description: "database is unlocked")
        var token: Any? = sut.registerDatabaseLockedHandler { (isDatabaseLocked) in
            if !isDatabaseLocked {
                databaseIsUnlocked.fulfill()
            }
        }
        XCTAssertNotNil(token)

        // when
        let context = LAContext()
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try sut.unlockDatabase(with: context)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // cleanup
        token = nil
    }

    // MARK: - Misc

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatOldEncryptionKeysAreReplaced_AfterActivatingEncryptionAtRest() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()

#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        let oldKeys = try EncryptionKeys.createKeys(for: account)

        // when
        setEncryptionAtRest(enabled: true)

        // then
        let newKeys = syncMOC.encryptionKeys

        XCTAssertFalse(sut.isDatabaseLocked)
        XCTAssertNotEqual(oldKeys, newKeys)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatIfDatabaseIsLocked_ThenUserSessionLockIsSet() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: true)

        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertTrue(sut.isDatabaseLocked)

        // then
        XCTAssertEqual(sut.lock, .database)
    }

    func testThatIfDatabaseIsNotLocked_ThenUserSessionLockIsNotSet() throws {
        // given
        simulateLoggedInUser()
        syncMOC.saveOrRollback()
        setEncryptionAtRest(enabled: false)
        XCTAssertFalse(sut.isDatabaseLocked)

        // then
        XCTAssertNotEqual(sut.lock, .database)
    }

}
