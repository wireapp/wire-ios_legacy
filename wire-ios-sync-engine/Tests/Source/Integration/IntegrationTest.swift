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

import Foundation
import WireTesting
import WireDataModel
import WireTransport.Testing
import avs

@testable import WireSyncEngine

final class MockAuthenticatedSessionFactory: AuthenticatedSessionFactory {

    let transportSession: TransportSessionType

    init(application: ZMApplication, mediaManager: MediaManagerType, flowManager: FlowManagerType, transportSession: TransportSessionType, environment: BackendEnvironmentProvider, reachability: ReachabilityProvider & TearDownCapable) {
        self.transportSession = transportSession
        super.init(
            appVersion: "0.0.0",
            application: application,
            mediaManager: mediaManager,
            flowManager: flowManager,
            environment: environment,
            reachability: reachability,
            analytics: nil
        )
    }

    override func session(for account: Account, coreDataStack: CoreDataStack, configuration: ZMUserSession.Configuration = .init()) -> ZMUserSession? {
        return ZMUserSession(
            userId: account.userIdentifier,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManager,
            analytics: analytics,
            application: application,
            appVersion: appVersion,
            coreDataStack: coreDataStack,
            configuration: configuration
        )
    }

}

final class MockUnauthenticatedSessionFactory: UnauthenticatedSessionFactory {

    let transportSession: UnauthenticatedTransportSessionProtocol

    init(transportSession: UnauthenticatedTransportSessionProtocol,
         environment: BackendEnvironmentProvider,
         reachability: ReachabilityProvider) {
        self.transportSession = transportSession
        super.init(appVersion: "1.0", environment: environment, reachability: reachability)
    }

    override func session(delegate: UnauthenticatedSessionDelegate,
                          authenticationStatusDelegate: ZMAuthenticationStatusDelegate) -> UnauthenticatedSession {
        return UnauthenticatedSession(transportSession: transportSession,
                                      reachability: reachability,
                                      delegate: delegate,
                                      authenticationStatusDelegate: authenticationStatusDelegate)
    }
}

extension IntegrationTest {
    var sessionManagerConfiguration: SessionManagerConfiguration {
        return SessionManagerConfiguration.defaultConfiguration
    }

    var shouldProcessLegacyPushes: Bool {
        return false
    }

    static let SelfUserEmail = "myself@user.example.com"
    static let SelfUserPassword = "fgf0934';$@#%"

    var jailbreakDetector: JailbreakDetectorProtocol {
        return MockJailbreakDetector()
    }

    @objc
    func _setUp() {

        UserClientRequestFactory._test_overrideNumberOfKeys = 1

        sharedContainerDirectory = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        deleteSharedContainerContent()
        ZMPersistentCookieStorage.setDoNotPersistToKeychain(!useRealKeychain)

        pushRegistry = PushRegistryMock(queue: nil)
        application = ApplicationMock()
        notificationCenter = UserNotificationCenterMock()
        mockTransportSession = MockTransportSession(dispatchGroup: self.dispatchGroup)
        mockTransportSession.cookieStorage = ZMPersistentCookieStorage(forServerName: mockEnvironment.backendURL.host!, userIdentifier: currentUserIdentifier)
        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3IntegrationMock.self
        mockTransportSession.cookieStorage.deleteKeychainItems()
        createSessionManager()
        mockTransportSession.useLegaclyPushNotifications = shouldProcessLegacyPushes
    }

    func setupTimers() {
        userSession?.syncManagedObjectContext.performGroupedAndWait {
            $0.zm_createMessageObfuscationTimer()
        }
        userSession?.managedObjectContext.zm_createMessageDeletionTimer()
    }

    func destroyTimers() {
        userSession?.syncManagedObjectContext.performGroupedAndWait {
            $0.zm_teardownMessageObfuscationTimer()
        }
        userSession?.managedObjectContext.zm_teardownMessageDeletionTimer()
    }

    @objc
    func _tearDown() {
        UserClientRequestFactory._test_overrideNumberOfKeys = nil
        destroyTimers()
        sharedSearchDirectory?.tearDown()
        sharedSearchDirectory = nil
        mockTransportSession?.cleanUp()
        mockTransportSession = nil
        userSession = nil
        userSession?.tearDown()
        sessionManager = nil
        selfUser = nil
        user1 = nil
        user2 = nil
        user3 = nil
        user4 = nil
        user5 = nil
        team = nil
        teamUser1 = nil
        teamUser2 = nil
        serviceUser = nil
        groupConversationWithWholeTeam = nil
        selfToUser1Conversation = nil
        selfToUser2Conversation = nil
        connectionSelfToUser1 = nil
        connectionSelfToUser2 = nil
        selfConversation = nil
        groupConversation = nil
        groupConversationWithServiceUser = nil
        application = nil
        notificationCenter = nil
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        deleteSharedContainerContent()
        sharedContainerDirectory = nil

    }

    @objc
    func destroySessionManager() {
        destroyTimers()
        userSession?.tearDown()
        userSession = nil
        sessionManager = nil

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    private func deleteSharedContainerContent() {
        try? FileManager.default.contentsOfDirectory(at: sharedContainerDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }

    @objc
    func deleteAuthenticationCookie() {
        ZMPersistentCookieStorage.deleteAllKeychainItems()
        mockTransportSession.cookieStorage.deleteKeychainItems()
    }

    @objc
    func recreateSessionManager() {
        closePushChannelAndWaitUntilClosed()
        destroySharedSearchDirectory()
        destroySessionManager()
        createSessionManager()
    }

    @objc
    func recreateSessionManagerAndDeleteLocalData() {
        closePushChannelAndWaitUntilClosed()
        mockTransportSession.resetReceivedRequests()
        destroySharedSearchDirectory()
        destroySessionManager()
        deleteAuthenticationCookie()
        deleteSharedContainerContent()
        createSessionManager()
    }

    @objc
    func createSessionManager() {
        guard let application = application, let transportSession = mockTransportSession else { return XCTFail() }
        let reachability = MockReachability()
        let unauthenticatedSessionFactory = MockUnauthenticatedSessionFactory(transportSession: transportSession, environment: mockEnvironment, reachability: reachability)
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: mockMediaManager,
            flowManager: FlowManagerMock(),
            transportSession: transportSession,
            environment: mockEnvironment,
            reachability: reachability
        )

        sessionManager = SessionManager(
            appVersion: "0.0.0",
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachability,
            delegate: self,
            application: application,
            pushRegistry: pushRegistry,
            dispatchGroup: self.dispatchGroup,
            environment: mockEnvironment,
            configuration: sessionManagerConfiguration,
            detector: jailbreakDetector,
            requiredPushTokenType: shouldProcessLegacyPushes ? .voip : .standard
        )

        sessionManager?.loginDelegate = mockLoginDelegete

        sessionManager?.start(launchOptions: [:])

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }

    @objc
    func createSharedSearchDirectory() {
        guard sharedSearchDirectory == nil else { return }
        guard let userSession = userSession else { XCTFail("Could not create shared SearchDirectory");  return }
        sharedSearchDirectory = SearchDirectory(userSession: userSession)
    }

    @objc
    func destroySharedSearchDirectory() {
        sharedSearchDirectory?.tearDown()
        sharedSearchDirectory = nil
    }

    @objc
    var unauthenticatedSession: UnauthenticatedSession? {
        return sessionManager?.unauthenticatedSession
    }

    @objc
    func createSelfUserAndConversation() {

        mockTransportSession.performRemoteChanges({ session in
            let selfUser = session.insertSelfUser(withName: "The Self User")
            selfUser.email = IntegrationTest.SelfUserEmail
            selfUser.password = IntegrationTest.SelfUserPassword
            selfUser.identifier = self.currentUserIdentifier.transportString()
            selfUser.phone = ""
            selfUser.accentID = 2
            session.addProfilePicture(to: selfUser)
            session.addV3ProfilePicture(to: selfUser)

            let selfConversation = session.insertSelfConversation(withSelfUser: selfUser)
            selfConversation.identifier = selfUser.identifier

            self.selfUser = selfUser
            self.selfConversation = selfConversation
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    @objc
    func createExtraUsersAndConversations() {

        mockTransportSession.performRemoteChanges({ session in
            let user1 = session.insertUser(withName: "Extra User1")
            user1.email = "user1@example.com"
            user1.phone = "6543"
            user1.accentID = 3
            session.addProfilePicture(to: user1)
            session.addV3ProfilePicture(to: user1)
            self.user1 = user1

            let user2 = session.insertUser(withName: "Extra User2")
            user2.email = "user2@example.com"
            user2.phone = "4534"
            user2.accentID = 1
            self.user2 = user2

            let user3 = session.insertUser(withName: "Extra User3")
            user3.email = "user3@example.com"
            user3.phone = "340958"
            user3.accentID = 4
            session.addProfilePicture(to: user3)
            session.addV3ProfilePicture(to: user3)
            self.user3 = user3

            let user4 = session.insertUser(withName: "Extra User4")
            user4.email = "user4@example.com"
            user4.phone = "2349857"
            user4.accentID = 7
            session.addProfilePicture(to: user4)
            session.addV3ProfilePicture(to: user4)
            self.user4 = user4

            let user5 = session.insertUser(withName: "Extra User5")
            user5.email = "user5@example.com"
            user5.phone = "555466434325"
            user5.accentID = 7
            self.user5 = user5

            let selfToUser1Conversation = session.insertOneOnOneConversation(withSelfUser: self.selfUser, otherUser: user1)
            selfToUser1Conversation.creator = self.selfUser
            selfToUser1Conversation.setValue("Connection conversation to user 1", forKey: "name")
            self.selfToUser1Conversation = selfToUser1Conversation

            let selfToUser2Conversation = session.insertOneOnOneConversation(withSelfUser: self.selfUser, otherUser: user2)
            selfToUser2Conversation.creator = user2

            selfToUser2Conversation.setValue("Connection conversation to user 2", forKey: "name")
            self.selfToUser2Conversation = selfToUser2Conversation

            let groupConversation = session.insertGroupConversation(withSelfUser: self.selfUser, otherUsers: [user1, user2, user3])
            groupConversation.creator = user3
            groupConversation.changeName(by: self.selfUser, name: "Group conversation")
            self.groupConversation = groupConversation

            let connectionSelfToUser1 = session.insertConnection(withSelfUser: self.selfUser, to: user1)
            connectionSelfToUser1.status = "accepted"
            connectionSelfToUser1.lastUpdate = Date(timeIntervalSinceNow: -3)
            connectionSelfToUser1.conversation = selfToUser1Conversation
            self.connectionSelfToUser1 = connectionSelfToUser1

            let connectionSelfToUser2 = session.insertConnection(withSelfUser: self.selfUser, to: user2)
            connectionSelfToUser2.status = "accepted"
            connectionSelfToUser2.lastUpdate = Date(timeIntervalSinceNow: -5)
            connectionSelfToUser2.conversation = selfToUser2Conversation
            self.connectionSelfToUser2 = connectionSelfToUser2
        })
    }

    @objc
    func createTeamAndConversations() {
        mockTransportSession.performRemoteChanges({ session in

            let user1 = session.insertUser(withName: "Team user1")
            user1.accentID = 7
            self.teamUser1 = user1

            let user2 = session.insertUser(withName: "Team user2")
            user2.accentID = 1
            self.teamUser2 = user2

            let team = session.insertTeam(withName: "A Team", isBound: true, users: [self.selfUser, user1, user2])
            team.creator = user1
            self.team = team

            let bot = session.insertUser(withName: "Botty the Bot")
            bot.accentID = 3
            session.addProfilePicture(to: bot)
            session.addV3ProfilePicture(to: bot)
            self.serviceUser = bot

            let groupConversation = session.insertGroupConversation(withSelfUser: self.selfUser, otherUsers: [user1, user2, bot])
            groupConversation.team = team
            groupConversation.creator = user2
            groupConversation.changeName(by: self.selfUser, name: "Group conversation with bot")
            self.groupConversationWithServiceUser = groupConversation

            let teamConversation = session.insertGroupConversation(withSelfUser: self.selfUser, otherUsers: [self.teamUser1!, self.teamUser2!])
            teamConversation.team = team
            teamConversation.creator = self.selfUser
            teamConversation.changeName(by: self.selfUser, name: "Team Group conversation")
            self.groupConversationWithWholeTeam = teamConversation
            MockRole.createConversationRoles(context: self.mockTransportSession.managedObjectContext)
            let pc = MockParticipantRole.insert(in: self.mockTransportSession.managedObjectContext, conversation: groupConversation, user: self.selfUser)
            pc.role = MockRole.adminRole
        })
    }

    @objc
    func login() -> Bool {
        let credentials = ZMEmailCredentials(email: IntegrationTest.SelfUserEmail, password: IntegrationTest.SelfUserPassword)
        return login(withCredentials: credentials, ignoreAuthenticationFailures: false)
    }

    @objc(loginAndIgnoreAuthenticationFailures:)
    func login(ignoreAuthenticationFailures: Bool) -> Bool {
        let credentials = ZMEmailCredentials(email: IntegrationTest.SelfUserEmail, password: IntegrationTest.SelfUserPassword)
        return login(withCredentials: credentials, ignoreAuthenticationFailures: ignoreAuthenticationFailures)
    }

    @objc
    func login(withCredentials credentials: ZMCredentials, ignoreAuthenticationFailures: Bool = false) -> Bool {
        sessionManager?.unauthenticatedSession?.login(with: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sessionManager?.unauthenticatedSession?.continueAfterBackupImportStep()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return mockLoginDelegete?.didCallAuthenticationDidSucceed ?? false
    }

    @objc(prefetchRemoteClientByInsertingMessageInConversation:)
    func prefetchClientByInsertingMessage(in mockConversation: MockConversation) {
        guard let convo = conversation(for: mockConversation) else { return }
        userSession?.perform {
            try! convo.appendText(content: "hum, t'es sûr?")
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    @objc(userForMockUser:)
    func user(for mockUser: MockUser) -> ZMUser? {
        let uuid = mockUser.managedObjectContext!.performGroupedAndWait { _ in
            return mockUser.identifier.uuid()
        }
        let data = (uuid as NSUUID).data() as NSData
        let predicate = NSPredicate(format: "remoteIdentifier_data == %@", data)
        let request = ZMUser.sortedFetchRequest(with: predicate)
        let result = userSession?.managedObjectContext.executeFetchRequestOrAssert(request) as? [ZMUser]

        if let user = result?.first {
            return user
        } else {
            return nil
        }
    }

    @objc(conversationForMockConversation:)
    func conversation(for mockConversation: MockConversation) -> ZMConversation? {
        let uuid = mockConversation.managedObjectContext!.performGroupedAndWait { _ in
            return mockConversation.identifier.uuid()
        }
        let data = (uuid as NSUUID).data() as NSData
        let predicate = NSPredicate(format: "remoteIdentifier_data == %@", data)
        let request = ZMConversation.sortedFetchRequest(with: predicate)
        let result = userSession?.managedObjectContext.executeFetchRequestOrAssert(request) as? [ZMConversation]

        if let conversation = result?.first {
            return conversation
        } else {
            return nil
        }
    }

    @objc(establishSessionWithMockUser:)
    func establishSession(with mockUser: MockUser) {
        mockTransportSession.performRemoteChanges({ session in
            if mockUser.clients.count == 0 {
                session.registerClient(for: mockUser)
            }

            for client in mockUser.clients {
                self.userSession?.syncManagedObjectContext.performGroupedBlockAndWait {
                    self.establishSessionFromSelf(toRemote: client as! MockUserClient)
                }
            }
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

}

extension IntegrationTest {

    @discardableResult
    @objc(createSentConnectionFromUserWithName:uuid:)
    func createSentConnection(fromUserWithName name: String, uuid: UUID) -> MockUser {
        return createConnection(fromUserWithName: name, uuid: uuid, status: "sent")
    }

    @discardableResult
    @objc(createPendingConnectionFromUserWithName:uuid:)
    func createPendingConnection(fromUserWithName name: String, uuid: UUID) -> MockUser {
        return createConnection(fromUserWithName: name, uuid: uuid, status: "pending")
    }

    @discardableResult
    @objc(createConnectionFromUserWithName:uuid:status:)
    func createConnection(fromUserWithName name: String, uuid: UUID, status: String) -> MockUser {
        let mockUser = createUser(withName: name, uuid: uuid)

        mockTransportSession.performRemoteChanges({ session in
            let connection = session.insertConnection(withSelfUser: self.selfUser, to: mockUser)
            connection.message = "Hello, my friend."
            connection.status = status
            connection.lastUpdate = Date(timeIntervalSinceNow: -20000)

            let conversation = session.insertConversation(withSelfUser: self.selfUser, creator: mockUser, otherUsers: [], type: .invalid)
            connection.conversation = conversation
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return mockUser
    }

    @discardableResult
    @objc(createUserWithName:uuid:)
    func createUser(withName name: String, uuid: UUID) -> MockUser {
        var user: MockUser?
        mockTransportSession.performRemoteChanges({ session in
            user = session.insertUser(withName: name)
            user?.identifier = uuid.transportString()
        })

        return user!
    }

    @objc(performRemoteChangesExludedFromNotificationStream:)
    func performRemoteChangesExludedFromNotificationStream(_ changes: @escaping (_ session: MockTransportSessionObjectCreation) -> Void) {
        mockTransportSession.performRemoteChanges { session in
            changes(session)
            self.mockTransportSession.saveAndCreatePushChannelEvents()
        }
    }

    func simulateNotificationStreamInterruption(
        changesBeforeInterruption: ((_ session: MockTransportSessionObjectCreation) -> Void)? = nil,
        changesAfterInterruption: ((_ session: MockTransportSessionObjectCreation) -> Void)? = nil) {

        closePushChannelAndWaitUntilClosed()
        changesBeforeInterruption.apply(mockTransportSession.performRemoteChanges)
        mockTransportSession.performRemoteChanges { (session) in
            session.clearNotifications()

            if let changes = changesAfterInterruption {
                changes(session)
            } else {
                // We always need some kind of change in order to not have an empty notification stream
                self.user5.name = "User 5 \(UUID())"
            }
        }
        openPushChannelAndWaitUntilOpened()
    }

    func performSlowSync() {
        userSession?.applicationStatusDirectory?.syncStatus.forceSlowSync()
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func closePushChannelAndWaitUntilClosed() {
        mockTransportSession.performRemoteChanges { session in
            self.mockTransportSession.pushChannel.keepOpen = false
            session.simulatePushChannelClosed()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func openPushChannelAndWaitUntilOpened() {
        mockTransportSession.performRemoteChanges { _ in
            self.mockTransportSession.pushChannel.keepOpen = true
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func simulateApplicationWillEnterForeground() {
        application?.simulateApplicationWillEnterForeground()
    }

    func simulateApplicationDidEnterBackground() {
        closePushChannelAndWaitUntilClosed() // do not use websocket
        application?.setBackground()
        application?.simulateApplicationDidEnterBackground()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
    }

}

extension IntegrationTest {
    @objc(remotelyAppendSelfConversationWithZMClearedForMockConversation:atTime:)
    func remotelyAppendSelfConversationWithZMCleared(for mockConversation: MockConversation, at time: Date) {
        let genericMessage = GenericMessage(content: Cleared(timestamp: time, conversationID: UUID(uuidString: mockConversation.identifier)!))
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfConversation.insertClientMessage(from: self.selfUser, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
    }

    @objc(remotelyAppendSelfConversationWithZMLastReadForMockConversation:atTime:)
    func remotelyAppendSelfConversationWithZMLastRead(for mockConversation: MockConversation, at time: Date) {
        let genericMessage = GenericMessage(content: LastRead(conversationID: UUID(uuidString: mockConversation.identifier)!, lastReadTimestamp: time))
        mockTransportSession.performRemoteChanges { _ in
            do {
                self.selfConversation.insertClientMessage(from: self.selfUser, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }
    }
}

extension IntegrationTest: SessionManagerDelegate {

    public var isInAuthenticatedAppState: Bool {
        return appState == "authenticated"
    }

    public var isInUnathenticatedAppState: Bool {
        return appState == "unauthenticated"
    }

    public func sessionManagerDidFailToLogin(error: Error?) {
        // no op
    }

    public func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        self.userSession = userSession

        if let notificationCenter = self.notificationCenter {
            self.userSession?.localNotificationDispatcher?.notificationCenter = notificationCenter
        }

        self.userSession?.syncManagedObjectContext.performGroupedBlock {
            self.userSession?.syncManagedObjectContext.setPersistentStoreMetadata(NSNumber(value: true), key: ZMSkipHotfix)
        }

        setupTimers()
    }

    public func sessionManagerDidReportLockChange(forSession session: UserSessionAppLockInterface) {
        // No op
    }

    public func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        self.userSession = nil
        userSessionCanBeTornDown()
    }

    public func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        self.userSession = nil
        userSessionCanBeTornDown?()
    }

    public func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        // no-op
    }

    public func sessionManagerDidBlacklistJailbrokenDevice() {
        // no-op
    }

    public func sessionManagerDidFailToLoadDatabase() {
        // no-op
    }

    public func sessionManagerWillOpenAccount(_ account: Account,
                                              from selectedAccount: Account?,
                                              userSessionCanBeTornDown: @escaping () -> Void) {
        self.userSession = nil
        userSessionCanBeTornDown()
    }

    public func sessionManagerDidPerformFederationMigration(authenticated: Bool) {
        // no op
    }

}

@objcMembers
public class MockLoginDelegate: NSObject, LoginDelegate {
    public var currentError: NSError?

    public var didCallLoginCodeRequestDidFail: Bool = false
    public func loginCodeRequestDidFail(_ error: NSError) {
        currentError = error
        didCallLoginCodeRequestDidFail = true
    }

    public var didCallLoginCodeRequestDidSucceed: Bool = false
    public func loginCodeRequestDidSucceed() {
        didCallLoginCodeRequestDidSucceed = true
    }

    public var didCallAuthenticationDidFail: Bool = false
    public func authenticationDidFail(_ error: NSError) {
        currentError = error
        didCallAuthenticationDidFail = true
    }

    public var didCallAuthenticationInvalidated: Bool = false
    public func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        currentError = error
        didCallAuthenticationInvalidated = true
    }

    public var didCallAuthenticationDidSucceed: Bool = false
    public func authenticationDidSucceed() {
        didCallAuthenticationDidSucceed = true
    }

    public var didCallAuthenticationReadyToImportBackup: Bool = false
    public func authenticationReadyToImportBackup(existingAccount: Bool) {
        didCallAuthenticationReadyToImportBackup = true
    }

    public var didCallClientRegistrationDidSucceed: Bool = false
    public func clientRegistrationDidSucceed(accountId: UUID) {
        didCallClientRegistrationDidSucceed = true
    }

    public var didCallClientRegistrationDidFail: Bool = false
    public func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        currentError = error
        didCallClientRegistrationDidFail = true
    }
}

// MARK: - Configure default APIVersion

@objc
extension IntegrationTest {

    func configureDefaultAPIVersion() {
        APIVersion.current = .v0
    }

}

// MARK: - Account Helper

extension IntegrationTest {
    func addAccount(name: String, userIdentifier: UUID) -> Account {
        let account = Account(userName: name, userIdentifier: userIdentifier)
        let cookie = NSData.secureRandomData(ofLength: 16)
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = cookie
        sessionManager!.accountManager.addOrUpdate(account)
        return account
    }
}
