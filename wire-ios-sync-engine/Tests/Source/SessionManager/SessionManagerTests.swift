//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTesting
import PushKit
import LocalAuthentication
@testable import WireSyncEngine

final class SessionManagerTests: IntegrationTest {

    var delegate: SessionManagerTestDelegate!
    var sut: SessionManager?

    override func setUp() {
        super.setUp()
        delegate = SessionManagerTestDelegate()
        createSelfUserAndConversation()
    }

    func createManager(
        launchOptions: LaunchOptions = [:],
        maxNumberAccounts: Int = SessionManager.defaultMaxNumberAccounts,
        requiredTokenType: PushToken.TokenType = .standard
    ) -> SessionManager? {
        guard let application = application else { return nil }
        let environment = MockEnvironment()
        let reachability = MockReachability()
        let unauthenticatedSessionFactory = MockUnauthenticatedSessionFactory(transportSession: mockTransportSession, environment: environment, reachability: reachability)
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: mockMediaManager,
            flowManager: FlowManagerMock(),
            transportSession: mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        let sessionManager = SessionManager(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: "0.0.0",
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachability,
            delegate: delegate,
            application: application,
            pushRegistry: pushRegistry,
            dispatchGroup: dispatchGroup,
            environment: environment,
            configuration: sessionManagerConfiguration,
            detector: jailbreakDetector,
            requiredPushTokenType: requiredTokenType
        )

        sessionManager.start(launchOptions: launchOptions)

        return sessionManager
    }

    override func tearDown() {
        delegate = nil
        sut = nil
        super.tearDown()
    }

    // MARK: max account number
    func testThatDefaultMaxAccountNumberIs3_whenDefaultValueIsUsed() {
        // given and when
        let sut = createManager()!

        // then
        XCTAssertEqual(sut.maxNumberAccounts, 3)
    }

    func testThatMaxAccountNumberIs2_whenInitWithMaxAccountNumberAs2() {
        // given and when
        let sut = createManager(maxNumberAccounts: 2)!

        // then
        XCTAssertEqual(sut.maxNumberAccounts, 2)
    }

    func testThatItCreatesUnauthenticatedSessionAndNotifiesDelegateIfStoreIsNotAvailable() {

        // given
        let observer = SessionManagerObserverMock()
        let token = sut?.addSessionManagerCreatedSessionObserver(observer)

        // when
        sut = createManager()

        // then
        XCTAssertNil(delegate.userSession)
        XCTAssertTrue(delegate.sessionManagerDidFailToLogin)
        XCTAssertNotNil(sut?.unauthenticatedSession)
        withExtendedLifetime(token) {
            XCTAssertEqual([], observer.createdUserSession)
        }
    }

    func testThatItCreatesUserSessionAndNotifiesDelegateIfStoreIsAvailable() {
        // given
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "", userIdentifier: currentUserIdentifier)
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        manager.addAndSelect(account)

        // when
        sut = createManager()
        let observer = SessionManagerObserverMock()
        let token = sut?.addSessionManagerCreatedSessionObserver(observer)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertNotNil(delegate.userSession)
        XCTAssertNil(sut?.unauthenticatedSession)
        withExtendedLifetime(token) {
            XCTAssertEqual([delegate.userSession].compactMap { $0 }, observer.createdUserSession)
        }
    }

    func testThatItNotifiesObserverWhenCreatingAndTearingDownSession() {

        // GIVEN
        let account = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        guard let application = application else { return XCTFail() }

        let sessionManagerExpectation = self.expectation(description: "Session manager and session is loaded")

        let observer = SessionManagerObserverMock()
        var createToken: Any?
        var destroyToken: Any?

        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        // WHEN
        createToken = testSessionManager.addSessionManagerCreatedSessionObserver(observer)
        destroyToken = testSessionManager.addSessionManagerDestroyedSessionObserver(observer)

        withExtendedLifetime(createToken) {
            testSessionManager.loadSession(for: account) { userSession in
                XCTAssertNotNil(userSession)
                sessionManagerExpectation.fulfill()
            }
        }

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual([testSessionManager.activeUserSession!], observer.createdUserSession)

        // AND WHEN
        withExtendedLifetime(destroyToken) {
            testSessionManager.tearDownBackgroundSession(for: account.userIdentifier)
        }

        // THEN
        XCTAssertEqual([account.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatItNotifiesDestroyedSessionObserverWhenCurrentSessionIsLoggedOut() {

        // GIVEN
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!
        let observer = SessionManagerObserverMock()
        let token = sessionManager?.addSessionManagerDestroyedSessionObserver(observer)

        // WHEN
        withExtendedLifetime(token) {
            sessionManager?.logoutCurrentSession()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // THEN
        XCTAssertEqual([account.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatItNotifiesDestroyedSessionObserverWhenMemoryWarningReceived() {

        // GIVEN
        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true

        let account1 = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account1).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        let account2 = self.createAccount(with: UUID.create())
        sessionManager!.environment.cookieStorage(for: account2).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        guard let application = application else { return XCTFail() }

        let sessionManagerExpectation = self.expectation(description: "Session manager and sessions are loaded")
        let observer = SessionManagerObserverMock()

        var destroyToken: Any?

        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: self.delegate,
            application: application,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            detector: jailbreakDetector,
            requiredPushTokenType: .standard
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        // WHEN
        destroyToken = testSessionManager.addSessionManagerDestroyedSessionObserver(observer)

        testSessionManager.loadSession(for: account1) { userSession in
            XCTAssertNotNil(userSession)

            // load second account
            testSessionManager.loadSession(for: account2) { userSession in
                XCTAssertNotNil(userSession)
                sessionManagerExpectation.fulfill()
            }
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(testSessionManager.backgroundUserSessions.count, 2)
        XCTAssertEqual(testSessionManager.backgroundUserSessions[account2.userIdentifier], testSessionManager.activeUserSession)

        withExtendedLifetime(destroyToken) {
            NotificationCenter.default.post(Notification(name: UIApplication.didReceiveMemoryWarningNotification))
        }

        // THEN
        XCTAssertEqual([account1.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatJailbrokenDeviceCallsDelegateMethod() {

        // GIVEN
        guard let application = application else { return XCTFail() }
        let jailbreakDetector = MockJailbreakDetector(jailbroken: true)
        let configuration = SessionManagerConfiguration(blockOnJailbreakOrRoot: true)

        // WHEN
        _ = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: self.delegate,
            application: application,
            environment: sessionManager!.environment,
            configuration: configuration,
            detector: jailbreakDetector,
            requiredPushTokenType: .standard
        )

        XCTAssertTrue(self.delegate.jailbroken)
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatJailbrokenDeviceDeletesAccount() {
        // GIVEN
        sut = createManager()
        (sut?.jailbreakDetector as! MockJailbreakDetector).jailbroken = true
        sut?.configuration.wipeOnJailbreakOrRoot = true

        // WHEN
        sut?.accountManager.addAndSelect(createAccount())
        XCTAssertEqual(sut?.accountManager.accounts.count, 1)

        // THEN
        performIgnoringZMLogError {
            self.sut!.checkJailbreakIfNeeded()
        }
        XCTAssertEqual(self.sut?.accountManager.accounts.count, 0)
    }

    func testAuthenticationAfterReboot() {
        // GIVEN
        sut = createManager()

        // WHEN
        sut?.accountManager.addAndSelect(createAccount())
        XCTAssertEqual(sut?.accountManager.accounts.count, 1)

        // THEN
        let logoutExpectation = expectation(description: "Authentication after reboot")

        delegate.onLogout = { error in
            XCTAssertNil(self.sut?.activeUserSession)
            XCTAssertEqual(error?.userSessionErrorCode, .needsAuthenticationAfterReboot)
            logoutExpectation.fulfill()
        }

        performIgnoringZMLogError {
            self.sut!.performPostRebootLogout()
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 2))
    }

    func testThatShouldPerformPostRebootLogoutReturnsFalseIfNotRebooted() {
        // GIVEN
        sut = createManager()
        sut?.configuration.authenticateAfterReboot = true
        sut?.accountManager.addAndSelect(createAccount())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sut?.accountManager.accounts.count, 1)
        SessionManager.previousSystemBootTime = ProcessInfo.processInfo.bootTime()

        // WHEN/THEN
        performIgnoringZMLogError {
            XCTAssertFalse(self.sut!.shouldPerformPostRebootLogout())
        }
    }

    func testThatShouldPerformPostRebootLogoutReturnsFalseIfNoPreviousBootTimeExists() {

        // GIVEN
        sut = createManager()
        sut?.configuration.authenticateAfterReboot = true
        sut?.accountManager.addAndSelect(createAccount())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sut?.accountManager.accounts.count, 1)
        ZMKeychain.deleteAllKeychainItems(withAccountName: SessionManager.previousSystemBootTimeContainer)

        // WHEN/THEN
        performIgnoringZMLogError {
            XCTAssertFalse(self.sut!.shouldPerformPostRebootLogout())
        }
    }

}

extension IntegrationTest {
    func createAccount() -> Account {
        return createAccount(with: currentUserIdentifier)
    }

    func createAccount(with id: UUID) -> Account {
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail()
            fatalError()
        }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "Test Account", userIdentifier: id)
        manager.addOrUpdate(account)

        return account
    }

    func createSelfClient(_ context: NSManagedObjectContext) -> UserClient {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = nil
        selfClient.user = ZMUser.selfUser(in: context)
        return selfClient
    }
}

class SessionManagertests_AccountDeletion: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesTheAccountFolder_WhenDeletingAccountWithoutActiveUserSession() throws {
        // given
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail()
            return
        }
        let account = self.createAccount()

        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        try FileManager.default.createDirectory(at: accountFolder, withIntermediateDirectories: true, attributes: nil)

        // when
        performIgnoringZMLogError {
            self.sessionManager!.delete(account: account)
        }

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccountFolder_WhenDeletingActiveUserSessionAccount() throws {
        // given
        XCTAssert(login())

        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }

        let account = sessionManager!.accountManager.selectedAccount!
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        // when
        performIgnoringZMLogError {
            self.sessionManager!.delete(account: account)
        }

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

}

class SessionManagerTests_AuthenticationFailure: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesTheCookie_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        XCTAssertTrue(sessionManager!.isSelectedAccountAuthenticated)

        // when
        let account = sessionManager!.accountManager.selectedAccount!
        sessionManager?.authenticationInvalidated(NSError(code: .accessTokenExpired, userInfo: nil), accountId: account.userIdentifier)

        // then
        XCTAssertFalse(sessionManager!.isSelectedAccountAuthenticated)
    }

    func testThatItDeletesAccount_IfRemoteClientIsDeleted() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.authenticationInvalidated(NSError(code: .clientDeletedRemotely, userInfo: nil), accountId: account.userIdentifier)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItTearsDownActiveUserSession_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        XCTAssertNotNil(sessionManager?.activeUserSession)

        // when
        let account = sessionManager!.accountManager.selectedAccount!
        sessionManager?.authenticationInvalidated(NSError(code: .accessTokenExpired, userInfo: nil), accountId: account.userIdentifier)

        // then
        XCTAssertNil(sessionManager?.activeUserSession)
    }

    func testThatItTearsDownBackgroundUserSession_OnAuthentictionFailure() {
        // given
        let additionalAccount = Account(userName: "Additional Account", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: additionalAccount).authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        sessionManager!.accountManager.addOrUpdate(additionalAccount)

        XCTAssert(login())
        XCTAssertNotNil(sessionManager?.activeUserSession)

        // load additional account as a background session
        sessionManager!.withSession(for: additionalAccount, perform: { _ in })
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])

        // when
        sessionManager?.authenticationInvalidated(NSError(code: .accessTokenExpired, userInfo: nil), accountId: additionalAccount.userIdentifier)

        // then
        XCTAssertNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])
    }

}

class SessionManagerTests_EncryptionAtRestMigration: IntegrationTest {

    override var useInMemoryStore: Bool {
        return false
    }

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsEnabled() throws {
        // given
        XCTAssertTrue(login())
        let expectedText = "Hello World"
        userSession?.perform({
            let groupConversation = self.conversation(for: self.groupConversation)
            try! groupConversation?.appendText(content: expectedText)
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try userSession?.setEncryptionAtRest(enabled: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userSession?.encryptMessagesAtRest, true)

        try userSession?.unlockDatabase(with: LAContext())
        let groupConversation = self.conversation(for: self.groupConversation)
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2 
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsDisabled() throws {

        // given
        XCTAssertTrue(login())
        let expectedText = "Hello World"
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try userSession?.setEncryptionAtRest(enabled: true, skipMigration: true)
        userSession?.perform({
            let groupConversation = self.conversation(for: self.groupConversation)
            try! groupConversation?.appendText(content: expectedText)
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        try userSession?.setEncryptionAtRest(enabled: false)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(userSession?.encryptMessagesAtRest, false)

        let groupConversation = self.conversation(for: self.groupConversation)
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

}

class SessionManagerTests_EncryptionAtRestIsEnabledByDefault_Option: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    override var useInMemoryStore: Bool {
        return false
    }

    override var sessionManagerConfiguration: SessionManagerConfiguration {
        return SessionManagerConfiguration(encryptionAtRestIsEnabledByDefault: true)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatEncryptionAtRestIsEnabled_OnActiveUserSession() {
        // given
        XCTAssertTrue(login())

        // then
#if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
#endif
        XCTAssertTrue(sessionManager?.activeUserSession?.encryptMessagesAtRest == true)
    }

}

class SessionManagerTests_PasswordVerificationFailure_With_DeleteAccountAfterThreshold: IntegrationTest {
    private var threshold: Int? = 2
    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    override var sessionManagerConfiguration: SessionManagerConfiguration {
        return SessionManagerConfiguration(failedPasswordThresholdBeforeWipe: threshold)
    }

    func testThatItDeletesAccount_IfLimitIsReached() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.passwordVerificationDidFail(with: threshold!)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDoesntDeleteAccount_IfLimitIsNotReached() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.passwordVerificationDidFail(with: threshold! - 1)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertTrue(FileManager.default.fileExists(atPath: accountFolder.path))
    }
}

class SessionManagerTests_AuthenticationFailure_With_DeleteAccountOnAuthentictionFailure: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    override var sessionManagerConfiguration: SessionManagerConfiguration {
        return SessionManagerConfiguration(wipeOnCookieInvalid: true)
    }

    func testThatItDeletesTheAccount_OnLaunchIfAccessTokenHasExpired() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        deleteAuthenticationCookie()
        recreateSessionManager()

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccount_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.authenticationInvalidated(NSError(code: .accessTokenExpired, userInfo: nil), accountId: account.userIdentifier)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccount_OnAuthentictionFailureForBackgroundSession() {
        // given
        let additionalAccount = Account(userName: "Additional Account", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: additionalAccount).authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        sessionManager!.accountManager.addOrUpdate(additionalAccount)

        XCTAssert(login())

        XCTAssertNotNil(sessionManager?.activeUserSession)

        // load additional account as a background session
        let sessionLoaded = expectation(description: "Background session loaded")
        sessionManager?.withSession(for: additionalAccount, perform: {_ in
            sessionLoaded.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])

        // when
        sessionManager?.authenticationInvalidated(NSError(code: .accessTokenExpired, userInfo: nil), accountId: additionalAccount.userIdentifier)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: additionalAccount.userIdentifier, applicationContainer: sharedContainer)

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

}

class SessionManagerTests_Teams: IntegrationTest {

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItUpdatesAccountAfterLoginWithTeamName() {
        // given
        let teamName = "Wire"
        let image = MockAsset(in: mockTransportSession.managedObjectContext, forID: selfUser.previewProfileAssetIdentifier!)
        self.mockTransportSession.performRemoteChanges { session in
            let team = session.insertTeam(withName: teamName, isBound: true, users: [self.selfUser])
            team.creator = self.selfUser
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        _ = MockAsset(in: mockTransportSession.managedObjectContext, forID: selfUser.previewProfileAssetIdentifier!)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first, manager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertEqual(account.teamName, teamName)
        XCTAssertEqual(account.imageData, image?.data)
        XCTAssertNil(account.teamImageData)
        XCTAssertEqual(account.loginCredentials, selfUser.loginCredentials)
    }

    func testThatItUpdatesAccountAfterTeamNameChanges() {
        // given
        var team: MockTeam!
        self.mockTransportSession.performRemoteChanges { session in
            team = session.insertTeam(withName: "Wire", isBound: true, users: [self.selfUser])
            team.creator = self.selfUser
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssert(login())

        let newTeamName = "Not Wire"
        self.mockTransportSession.performRemoteChanges { _ in
            team.name = newTeamName
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let account = sessionManager?.accountManager.accounts.first, sessionManager?.accountManager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertEqual(account.teamName, newTeamName)
    }

    func testThatItUpdatesAccountAfterTeamImageDataChanges() {
        // given
        let assetData = "image".data(using: .utf8)!
        var asset: MockAsset!
        var team: MockTeam!
        self.mockTransportSession.performRemoteChanges { session in
            team = session.insertTeam(withName: "Wire", isBound: true, users: [self.selfUser])
            team.creator = self.selfUser
            asset = session.insertAsset(with: UUID(), assetToken: UUID(), assetData: assetData, contentType: "image/jpeg")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssert(login())

        // when
        self.mockTransportSession.performRemoteChanges { _ in
            team.pictureAssetId = asset.identifier
        }
        user(for: selfUser)?.team?.requestImage()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let account = sessionManager?.accountManager.accounts.first, sessionManager?.accountManager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertEqual(account.teamImageData, assetData)
    }

    func testThatItUpdatesAccountWithUserDetailsAfterLogin() {
        // when
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first, manager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, self.selfUser.name)
        let image = MockAsset(in: mockTransportSession.managedObjectContext, forID: selfUser.previewProfileAssetIdentifier!)

        XCTAssertEqual(account.imageData, image?.data)
    }

    func testThatItUpdatesAccountWithUserDetailsAfterLoginIntoExistingAccount() {
        // given
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        closePushChannelAndWaitUntilClosed()
        XCTAssert(login())

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first, manager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, self.selfUser.name)
        let image = MockAsset(in: mockTransportSession.managedObjectContext, forID: selfUser.previewProfileAssetIdentifier!)

        XCTAssertEqual(account.imageData, image?.data)
    }

    func testThatItUpdatesAccountAfterUserNameChange() {
        // when
        XCTAssert(login())

        let newName = "BOB"
        self.mockTransportSession.performRemoteChanges { _ in
            self.selfUser.name = newName
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first, manager.accounts.count == 1 else { XCTFail("Should have one account"); return }
        XCTAssertEqual(account.userIdentifier.transportString(), self.selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, selfUser.name)
    }

    func testThatItSendsAuthenticationErrorWhenAccountLimitIsReached() throws {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())
        let account3 = Account(userName: "Account 3", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)
        sessionManager?.accountManager.addOrUpdate(account2)
        sessionManager?.accountManager.addOrUpdate(account3)

        // when
        XCTAssert(login(ignoreAuthenticationFailures: true))

        // then
        guard
            let delegate = mockLoginDelegete,
            let error = delegate.currentError
        else {
            return XCTFail()
        }

        XCTAssertTrue(delegate.didCallAuthenticationDidFail)
        XCTAssertEqual(error, NSError(code: .accountLimitReached, userInfo: nil))
    }

    func testThatItChecksAccountsForExistingAccount() {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)

        // then
        XCTAssertTrue(sessionManager!.session(session: self.unauthenticatedSession!, isExistingAccount: account1))
        XCTAssertFalse(sessionManager!.session(session: self.unauthenticatedSession!, isExistingAccount: account2))
    }
}

final class SessionManagerTests_MultiUserSession: IntegrationTest {

    override func setUp() {
         super.setUp()

        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true
    }

    func testThatItLoadsAndKeepsBackgroundUserSession() {
        // GIVEN
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account1 = Account(userName: "Test Account 1", userIdentifier: currentUserIdentifier)
        manager.addOrUpdate(account1)

        let account2 = Account(userName: "Test Account 2", userIdentifier: UUID())
        manager.addOrUpdate(account2)
        // WHEN
        weak var sessionForAccount1Reference: ZMUserSession?
        let session1LoadedExpectation = self.expectation(description: "Session for account 1 loaded")
        self.sessionManager!.withSession(for: account1, perform: { sessionForAccount1 in
            // THEN
            session1LoadedExpectation.fulfill()
            XCTAssertNotNil(sessionForAccount1.managedObjectContext)
            sessionForAccount1Reference = sessionForAccount1
        })
        // WHEN
        weak var sessionForAccount2Reference: ZMUserSession?
        let session2LoadedExpectation = self.expectation(description: "Session for account 2 loaded")
        self.sessionManager!.withSession(for: account1, perform: { sessionForAccount2 in
            // THEN
            session2LoadedExpectation.fulfill()
            XCTAssertNotNil(sessionForAccount2.managedObjectContext)
            sessionForAccount2Reference = sessionForAccount2
        })

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(sessionForAccount1Reference)
            XCTAssertNotNil(sessionForAccount2Reference)

            self.sessionManager!.tearDownAllBackgroundSessions()
        })
    }

    func testThatItUnloadsUserSession() {
        // GIVEN
        let account = self.createAccount()

        // WHEN
        let sessionLoadedExpectation = self.expectation(description: "Session loaded")
        self.sessionManager!.withSession(for: account, perform: { session in
            XCTAssertNotNil(session.managedObjectContext)
            sessionLoadedExpectation.fulfill()
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        // THEN
        XCTAssertNotNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])

        // AND WHEN
        self.sessionManager!.tearDownAllBackgroundSessions()

        // THEN
        XCTAssertNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])
    }

    func testThatItDoesNotUnloadActiveUserSessionFromMemoryWarning() {
        // GIVEN
        let account = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        guard let application = application else { return XCTFail() }

        let sessionManagerExpectation = self.expectation(description: "Session manager and session is loaded")

        // WHEN
        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        testSessionManager.loadSession(for: account) { userSession in
            XCTAssertNotNil(userSession)
            sessionManagerExpectation.fulfill()
        }

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // WHEN
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        // THEN
        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // CLEANUP
        testSessionManager.tearDownAllBackgroundSessions()
    }

    func testThatItUnloadBackgroundUserSessionFromMemoryWarning() {
        // GIVEN
        let account = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        guard let application = application else { return XCTFail() }

        let sessionManagerExpectation = self.expectation(description: "Session manager and session is loaded")

        // WHEN
        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        testSessionManager.withSession(for: account) { userSession in
            XCTAssertNotNil(userSession)
            sessionManagerExpectation.fulfill()
        }

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // WHEN
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        // THEN
        XCTAssertNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // CLEANUP
        testSessionManager.tearDownAllBackgroundSessions()
    }

    func prepareSession(for account: Account) {
        weak var weakSession: ZMUserSession?

        autoreleasepool {
            var session: ZMUserSession! = nil
            self.sessionManager?.withSession(for: account, perform: { createdSession in
                session = createdSession
                weakSession = createdSession
            })

            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            let selfUser = ZMUser.selfUser(inUserSession: session)
            selfUser.remoteIdentifier = currentUserIdentifier

            self.sessionManager!.tearDownAllBackgroundSessions()
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            session = nil
            XCTAssertNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])
        }
        self.userSession = nil
        XCTAssertNil(weakSession)
    }

    func testThatItLoadsAccountForPush() {
        // GIVEN
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        self.sessionManager?.accountManager.addOrUpdate(account)

        self.prepareSession(for: account)

        let payload: [AnyHashable: Any] = [
            "data": [
                "user": currentUserIdentifier.transportString()
            ]
        ]

        // WHEN
        let pushCompleted = self.expectation(description: "Push completed")
        pushRegistry.mockIncomingPushPayload(payload, completion: {
            DispatchQueue.main.async {
                // THEN
                XCTAssertNotNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])

                // CLEANUP
                self.sessionManager!.tearDownAllBackgroundSessions()
                pushCompleted.fulfill()
            }
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItLoadsOnlyOneAccountForPush() {
        // GIVEN
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        self.sessionManager?.accountManager.addOrUpdate(account)

        self.prepareSession(for: account)

        let payload: [AnyHashable: Any] = [
            "data": [
                "user": currentUserIdentifier.transportString()
            ]
        ]

        // WHEN
        let pushCompleted1 = self.expectation(description: "Push completed 1")
        var userSession1: ZMUserSession!
        let pushCompleted2 = self.expectation(description: "Push completed 2")
        var userSession2: ZMUserSession!
        pushRegistry.mockIncomingPushPayload(payload, completion: {
            pushCompleted1.fulfill()
            userSession1 = self.sessionManager!.backgroundUserSessions[account.userIdentifier]
        })
        pushRegistry.mockIncomingPushPayload(payload, completion: {
            pushCompleted2.fulfill()
            userSession2 = self.sessionManager!.backgroundUserSessions[account.userIdentifier]
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(userSession1)
        XCTAssertNotNil(userSession2)
        XCTAssertEqual(userSession1, userSession2)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func setupSession() -> ZMUserSession {
        let manager = self.sessionManager!.accountManager
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        manager.addOrUpdate(account)
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        manager.addAndSelect(account)

        var session: ZMUserSession! = nil

        let sessionLoadExpectation = self.expectation(description: "Session loaded")
        self.sessionManager?.withSession(for: account, perform: { createdSession in
            session = createdSession
            sessionLoadExpectation.fulfill()
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        let selfUser = ZMUser.selfUser(in: session.managedObjectContext)
        selfUser.remoteIdentifier = currentUserIdentifier
        session.managedObjectContext.saveOrRollback()

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        _ = createSelfClient(session.managedObjectContext)

        session.syncManagedObjectContext.performGroupedBlock {
            _ = ZMConversation.fetchOrCreate(with: self.currentUserIdentifier, domain: nil, in: session.syncManagedObjectContext)
            session.syncManagedObjectContext.saveOrRollback()
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return session
    }

    func testThatItConfiguresNotificationSettingsWhenAccountIsActivated() {
        // GIVEN
        _ = self.setupSession()
        let expectation = self.expectation(description: "Session loaded")
        sessionManager?.notificationCenter = notificationCenter!

        guard
            let sessionManager = self.sessionManager,
            let account = sessionManager.accountManager.account(with: currentUserIdentifier)
            else { return XCTFail() }

        // WHEN
        sessionManager.select(account, completion: { userSession in
            XCTAssertNotNil(userSession)
            expectation.fulfill()
        })

        XCTAssertTrue(self.wait(withTimeout: 0.1) { return self.sessionManager!.activeUserSession != nil })
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(self.notificationCenter?.registeredNotificationCategories, WireSyncEngine.PushNotificationCategory.allCategories)
        XCTAssertEqual(self.notificationCenter?.requestedAuthorizationOptions, [.alert, .badge, .sound])
        XCTAssertNotNil(self.notificationCenter?.delegate)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesTheAccountForPushReaction() {
        // GIVEN
        let session = self.setupSession() // TODO: crash at RequireString([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue],
//        "Must call be called on the main queue.");
        session.isPerformingSync = false
        application?.applicationState = .background

        let selfConversation = ZMConversation.fetch(with: currentUserIdentifier, domain: nil, in: session.managedObjectContext)

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertNil(self.sessionManager!.activeUserSession)

        // WHEN
        self.sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleNotificationResponse(actionIdentifier: "",
                                                   categoryIdentifier: category,
                                                   userInfo: userInfo,
                                                   completionHandler: {})
        }

        XCTAssertTrue(self.wait(withTimeout: 0.1) { return self.sessionManager!.activeUserSession != nil })
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(self.sessionManager!.activeUserSession, session)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesTheAccountForPushAction() {
        // GIVEN
        let session = self.setupSession()
        session.isPerformingSync = false
        application?.applicationState = .inactive

        let selfConversation = ZMConversation.fetch(with: currentUserIdentifier, domain: nil, in: session.managedObjectContext)

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertNil(self.sessionManager!.activeUserSession)

        // WHEN
        let completionExpectation = self.expectation(description: "Completed action")
        self.sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleNotificationResponse(actionIdentifier: "",
                                                   categoryIdentifier: category,
                                                   userInfo: userInfo,
                                                   completionHandler: completionExpectation.fulfill)
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(self.sessionManager!.activeUserSession, session)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItCallsForegroundNotificationResponderMethod() {
        // GIVEN
        let session = self.setupSession()
        session.isPerformingSync = false

        let responder = MockForegroundNotificationResponder()
        self.sessionManager?.foregroundNotificationResponder = responder

        let selfConversation = ZMConversation.fetch(with: currentUserIdentifier, domain: nil, in: session.managedObjectContext)

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertTrue(responder.notificationPermissionRequests.isEmpty)

        // WHEN
        let completionExpectation = self.expectation(description: "Completed action")
        self.sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleInAppNotification(with: userInfo, categoryIdentifier: category) { _ in
                completionExpectation.fulfill()
            }
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(responder.notificationPermissionRequests.count, 1)
        XCTAssertEqual(responder.notificationPermissionRequests.first!, selfConversation?.remoteIdentifier)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesAccountWhichReceivesACallInTheBackground() {
        // GIVEN
        let manager = sessionManager!.accountManager
        let account1 = Account(userName: "Test Account 1", userIdentifier: currentUserIdentifier)
        sessionManager!.environment.cookieStorage(for: account1).authenticationCookieData = NSData.secureRandomData(ofLength: 16)

        manager.addOrUpdate(account1)
        let account2 = Account(userName: "Test Account 2", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: account2).authenticationCookieData = NSData.secureRandomData(ofLength: 16)
        manager.addOrUpdate(account2)

        // Make account 1 the active session
        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { (session) in
            session1 = session
        })
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // Load session for account 2 in the background
        weak var session2: ZMUserSession?
        weak var conversation: ZMConversation?
        weak var caller: ZMUser?
        self.sessionManager!.withSession(for: account2, perform: { session in
            session2 = session
            conversation = ZMConversation.insertNewObject(in: session.managedObjectContext)
            caller = ZMUser.insertNewObject(in: session.managedObjectContext)
        })
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        sessionManager?.callCenterDidChange(callState: .answered(degraded: false), conversation: conversation!, caller: caller!, timestamp: nil, previousCallState: nil)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sessionManager!.activeUserSession, session2)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    // the purpose of this test is to ensure push payloads can be processed in
    // the background as soon as the SessionManager is created
    func testThatABackgroundTaskCanBeCreatedAfterCreatingSessionManager() {
        // WHEN
        let activity = BackgroundActivityFactory.shared.startBackgroundActivity(withName: "PushActivity")

        // THEN
        XCTAssertNotNil(activity)
    }
}

final class SessionManagerTests_AppLock: IntegrationTest {

    private var appLock: MockAppLock!

    override func setUp() {
        super.setUp()
        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true
        appLock = MockAppLock()
    }

    override func tearDown() {
        sessionManager!.tearDownAllBackgroundSessions()
        appLock = nil
        mockTransportSession.doNotRespondToRequests = false
        super.tearDown()
    }

    func test_ItBeginsAppLockTimer_WhenChangingTheActiveUserSession() {
        // Given
        let account1 = addAccount(name: "Account 1", userIdentifier: currentUserIdentifier)
        let account2 = addAccount(name: "Account 2", userIdentifier: .create())

        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { (session) in
            session1 = session
            session1?.appLockController = self.appLock
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // When
        let switchedAccount = expectation(description: "switched account")
        sessionManager?.select(account2, completion: { _ in
            switchedAccount.fulfill()
        }, tearDownCompletion: nil)

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(appLock.methodCalls.beginTimer.count, 1)
    }

    func test_ItBeginAppLockTimer_WhenTheAppResignsActive() {
        // Given
        let account1 = addAccount(name: "Account 1", userIdentifier: currentUserIdentifier)

        // Make account 1 the active session.
        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { (session) in
            session1 = session
            session1?.appLockController = self.appLock
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // When
        let notification = Notification(name: UIApplication.willResignActiveNotification)
        sessionManager!.applicationWillResignActive(notification)

        // Then
        XCTAssertEqual(appLock.methodCalls.beginTimer.count, 1)
    }

}

extension NSManagedObjectContext {
    func createSelfUserAndSelfConversation() {
        let selfUser = ZMUser.selfUser(in: self)
        selfUser.remoteIdentifier = UUID()

        let selfConversation = ZMConversation.insertNewObject(in: self)
        selfConversation.remoteIdentifier = ZMConversation.selfConversationIdentifier(in: self)
    }
}

extension SessionManagerTests {
    func testThatItMarksConversationsAsRead() {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)
        sessionManager?.accountManager.addOrUpdate(account2)

        var conversations: [ZMConversation] = []

        let conversation1CreatedExpectation = self.expectation(description: "Conversation 1 created")

        self.sessionManager?.withSession(for: account1, perform: { createdSession in
            createdSession.managedObjectContext.createSelfUserAndSelfConversation()

            let conversation1 = createdSession.insertConversationWithUnreadMessage()
            conversations.append(conversation1)
            XCTAssertNotNil(conversation1.firstUnreadMessage)
            createdSession.managedObjectContext.saveOrRollback()
            conversation1CreatedExpectation.fulfill()
        })

        let conversation2CreatedExpectation = self.expectation(description: "Conversation 2 created")

        self.sessionManager?.withSession(for: account2, perform: { createdSession in
            createdSession.managedObjectContext.createSelfUserAndSelfConversation()

            let conversation2 = createdSession.insertConversationWithUnreadMessage()
            XCTAssertNotNil(conversation2.firstUnreadMessage)
            conversations.append(conversation2)
            createdSession.managedObjectContext.saveOrRollback()
            conversation2CreatedExpectation.fulfill()
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(conversations.count, 2)
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 2)

        // when
        let doneExpectation = self.expectation(description: "Conversations are marked as read")

        self.sessionManager?.markAllConversationsAsRead(completion: {
            doneExpectation.fulfill()
        })

        // then
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)

        // cleanup
        self.sessionManager!.tearDownAllBackgroundSessions()
    }
}

extension SessionManagerTests {

    func testThatItLogsOutWithCompanyLoginURL() throws {
        // GIVEN
        let id = UUID(uuidString: "1E628B42-4C83-49B7-B2B4-EF27BFE503EF")!
        let url = URL(string: "wire://start-sso/wire-\(id)")!
        let presentationDelegate = MockPresentationDelegate()

        sessionManager?.presentationDelegate = presentationDelegate
        XCTAssertTrue(login())
        XCTAssertNotNil(userSession)

        // WHEN
        try sessionManager?.openURL(url)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(userSession)
    }

}

// MARK: - Mocks
class SessionManagerTestDelegate: SessionManagerDelegate {
    var onLogout: ((NSError?) -> Void)?
    var appState = "authenticated"
    var isInAuthenticatedAppState: Bool {
        return appState == "authenticated"
    }
    var isInUnathenticatedAppState: Bool {
        return appState == "unauthenticated"
    }
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        onLogout?(error as NSError?)
        userSessionCanBeTornDown?()
    }

    var sessionManagerDidFailToLogin: Bool = false
    func sessionManagerDidFailToLogin(error: Error?) {
        sessionManagerDidFailToLogin = true
    }

    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        userSessionCanBeTornDown()
    }

    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        // no op
    }

    func sessionManagerDidFailToLoadDatabase() {
        // no op
    }

    var jailbroken = false
    func sessionManagerDidBlacklistJailbrokenDevice() {
        jailbroken = true
    }

    var userSession: ZMUserSession?
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        self.userSession = userSession
    }

    func sessionManagerDidReportLockChange(forSession session: UserSessionAppLockInterface) {
        // No op
    }

    var startedMigrationCalled = false
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        startedMigrationCalled = true
    }

    func sessionManagerDidPerformFederationMigration(authenticated: Bool) {
        // no op
    }

}

class SessionManagerObserverMock: SessionManagerCreatedSessionObserver, SessionManagerDestroyedSessionObserver {

    var createdUserSession: [ZMUserSession] = []
    var createdUnauthenticatedSession: [UnauthenticatedSession] = []
    var destroyedUserSessions: [UUID] = []

    func sessionManagerCreated(userSession: ZMUserSession) {
        createdUserSession.append(userSession)
    }

    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) {
        createdUnauthenticatedSession.append(unauthenticatedSession)
    }

    func sessionManagerDestroyedUserSession(for accountId: UUID) {
        destroyedUserSessions.append(accountId)
    }

}

class MockForegroundNotificationResponder: NSObject, ForegroundNotificationResponder {

    var notificationPermissionRequests: [UUID] = []

    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool {
        notificationPermissionRequests.append(userInfo.conversationID!)
        return true
    }
}
