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
import avs
import WireTransport
import WireUtilities
import CallKit
import PushKit
import UserNotifications
import WireDataModel
import WireRequestStrategy

private let log = ZMSLog(tag: "SessionManager")
private let pushLog = ZMSLog(tag: "Push")

public typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]

public extension Bundle {
    @objc var appGroupIdentifier: String? {
        return bundleIdentifier.map { "group." + $0 }
    }
}

@objc public enum CallNotificationStyle: UInt {
    case pushNotifications
    case callKit
}

public protocol SessionActivationObserver: AnyObject {
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession)
    func sessionManagerDidReportLockChange(forSession session: UserSessionAppLockInterface)
}

public protocol SessionManagerDelegate: SessionActivationObserver {
    func sessionManagerDidFailToLogin(error: Error?)
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?)
    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void)
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void)
    func sessionManagerDidFailToLoadDatabase()
    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason)
    func sessionManagerDidBlacklistJailbrokenDevice()
    func sessionManagerDidPerformFederationMigration(authenticated: Bool)

    var isInAuthenticatedAppState: Bool { get }
    var isInUnathenticatedAppState: Bool { get }
}

/// The public interface for the session manager.

@objc
public protocol SessionManagerType: AnyObject {

    var accountManager: AccountManager { get }

    weak var foregroundNotificationResponder: ForegroundNotificationResponder? { get }

    var callKitManager: CallKitManager? { get }
    var callNotificationStyle: CallNotificationStyle { get }

    func updateAppIconBadge(accountID: UUID, unreadCount: Int)

    /// Will update the push token for the session if it has changed
    func updatePushToken(for session: ZMUserSession)

    /// Configure user notification settings. This will ask the user for permission to display notifications.
    func configureUserNotifications()

    /// Switch account and and ask UI to to navigate to a message in a conversation
    ///
    /// - Parameters:
    ///   - conversation: the conversation to switch
    ///   - message: the message to navigate
    ///   - session: the session of the conversation
    func showConversation(_ conversation: ZMConversation,
                          at message: ZMConversationMessage?,
                          in session: ZMUserSession)

    /// Switch account and and ask UI to navigate to the conversatio list
    func showConversationList(in session: ZMUserSession)

    /// ask UI to open the profile of a user
    func showUserProfile(user: UserType)

    /// ask UI to open the connection request screen
    func showConnectionRequest(userId: UUID)

    /// Needs to be called before we try to register another device because API requires password
    func update(credentials: ZMCredentials) -> Bool

    func passwordVerificationDidFail(with failCount: Int)

}

@objc
public protocol SessionManagerSwitchingDelegate: AnyObject {
    func confirmSwitchingAccount(completion: @escaping (Bool) -> Void)
}

@objc
public protocol ForegroundNotificationResponder: AnyObject {
    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool
}

/// The `SessionManager` class handles the creation of `ZMUserSession` and `UnauthenticatedSession`
/// objects, the handover between them as well as account switching.
///
/// There are multiple things neccessary in order to store (and switch between) multiple accounts on one device, a couple of them are:
/// 1. The folder structure in the app sandbox has to be modeled in a way in which files can be associated with a single account.
/// 2. The login flow should not rely on any persistent state (e.g. no database has to be created on disk before being logged in).
/// 3. There has to be a persistence layer storing information about accounts and the currently selected / active account.
/// 
/// The wire account database and a couple of other related files are stored in the shared container in a folder named by the accounts
/// `remoteIdentifier`. All information about different accounts on a device are stored by the `AccountManager` (see the documentation
/// of that class for more information). The `SessionManager`s main responsibility at the moment is checking whether there is a selected 
/// `Account` or not, and creating an `UnauthenticatedSession` or `ZMUserSession` accordingly. An `UnauthenticatedSession` is used
/// to create requests to either log in existing users or to register new users. It uses its own `UnauthenticatedOperationLoop`, 
/// which is a stripped down version of the regular `ZMOperationLoop`. This unauthenticated operation loop only uses a small subset
/// of transcoders needed to perform the login / registration (and related phone number verification) requests. For more information
/// see `UnauthenticatedOperationLoop`.
///
/// The result of using an `UnauthenticatedSession` is retrieving a remoteIdentifier of a logged in user, as well as a valid cookie.
/// Once those became available, the session will notify the session manager, which in turn will create a regular `ZMUserSession`.
/// For more information about the cookie retrieval consult the documentation in `UnauthenticatedSession`.
///
/// The flow creating either an `UnauthenticatedSession` or `ZMUserSession` after creating an instance of `SessionManager` 
/// is depicted on a high level in the following diagram:
///
///
/// +-----------------------------------------+
/// |         `SessionManager.init`           |
/// +-----------------------------------------+
///
///                    +
///                    |
///                    |
///                    v
///
/// +-----------------------------------------+        YES           Load the selected Account and its
/// | Is there a stored and selected Account? |   +------------->    cookie from disk.
/// +-----------------------------------------+                      Create a `ZMUserSession` using the cookie.
///
///                    +
///                    |
///                    | NO
///                    |
///                    v
///
/// +------------------+---------------------+
/// | Check if there is a database present   |        YES           Open the existing database, retrieve the user identifier,
/// | in the legacy directory (not keyed by  |  +-------------->    create an account with it and select it. Migrate the existing
/// | the users remoteIdentifier)?           |                      cookie for that account and start at the top again.
/// +----------------------------------------+
///
///                    +
///                    |
///                    | NO
///                    |
///                    v
///
/// +------------------+---------------------+
/// | Create a `UnauthenticatedSession` to   |
/// | start the registration or login flow.  |
/// +----------------------------------------+
///

@objcMembers
public final class SessionManager: NSObject, SessionManagerType {

    public enum AccountError: Error {
        case accountLimitReached
    }

    /// Maximum number of accounts which can be logged in simultanously
    public let maxNumberAccounts: Int

    /// Default Maximum number of accounts which can be logged in simultanously
    public static let defaultMaxNumberAccounts: Int = 3

    public let appVersion: String
    var isAppVersionBlacklisted = false
    public weak var delegate: SessionManagerDelegate?
    public let accountManager: AccountManager
    public weak var loginDelegate: LoginDelegate?

    public internal(set) var activeUserSession: ZMUserSession? {
        willSet {
            guard activeUserSession != newValue else { return }
            activeUserSession?.appLockController.beginTimer()
        }
    }

    public private(set) var backgroundUserSessions = [UUID: ZMUserSession]() {
        didSet {
            VoIPPushHelper.setLoadedUserSessions(
                accountIDs: Array(backgroundUserSessions.keys)
            )
        }
    }

    public internal(set) var unauthenticatedSession: UnauthenticatedSession? {
        willSet {
            self.unauthenticatedSession?.tearDown()
        }
        didSet {
            if let session = self.unauthenticatedSession {

                NotificationInContext(name: sessionManagerCreatedUnauthenticatedSessionNotificationName, context: self, object: session).post()
            }
        }

    }
    public weak var presentationDelegate: PresentationDelegate?
    public weak var foregroundNotificationResponder: ForegroundNotificationResponder?
    public weak var switchingDelegate: SessionManagerSwitchingDelegate?
    public let groupQueue: ZMSGroupQueue = DispatchGroupQueue(queue: .main)

    let application: ZMApplication
    var deleteAccountToken: Any?
    var callCenterObserverToken: Any?
    var blacklistVerificator: ZMBlacklistVerificator?
    let reachability: ReachabilityProvider & TearDownCapable
    var pushRegistry: PushRegistry
    let notificationsTracker: NotificationsTracker?
    let configuration: SessionManagerConfiguration
    var pendingURLAction: URLAction?

    var notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()

    internal var authenticatedSessionFactory: AuthenticatedSessionFactory
    internal let unauthenticatedSessionFactory: UnauthenticatedSessionFactory

    fileprivate let sessionLoadingQueue: DispatchQueue = DispatchQueue(label: "sessionLoadingQueue")

    var environment: BackendEnvironmentProvider {
        didSet {
            authenticatedSessionFactory.environment = environment
            unauthenticatedSessionFactory.environment = environment

            // We need a new resolver for the new backend environment.
            apiVersionResolver = createAPIVersionResolver()
            resolveAPIVersion()
        }
    }

    let sharedContainerURL: URL
    let dispatchGroup: ZMSDispatchGroup?
    let jailbreakDetector: JailbreakDetectorProtocol?
    fileprivate var accountTokens: [UUID: [Any]] = [:]
    fileprivate var memoryWarningObserver: NSObjectProtocol?
    fileprivate var isSelectingAccount: Bool = false

    public var callKitManager: CallKitManager? {
        didSet {
            VoIPPushHelper.isCallKitAvailable = callKitManager != nil
        }
    }

    public var isSelectedAccountAuthenticated: Bool {
        guard let selectedAccount = accountManager.selectedAccount else {
            return false
        }

        return environment.isAuthenticated(selectedAccount)
    }

    public var activeUnauthenticatedSession: UnauthenticatedSession {
        return unauthenticatedSession ?? createUnauthenticatedSession()
    }

    private static var avsLogObserver: AVSLogObserver?

    var apiVersionResolver: APIVersionResolver?

    public var requiredPushTokenType: PushToken.TokenType

    public override init() {
        fatal("init() not implemented")
    }

    public convenience init(
        maxNumberAccounts: Int = defaultMaxNumberAccounts,
        appVersion: String,
        mediaManager: MediaManagerType,
        analytics: AnalyticsType?,
        delegate: SessionManagerDelegate?,
        application: ZMApplication,
        environment: BackendEnvironmentProvider,
        configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
        detector: JailbreakDetectorProtocol = JailbreakDetector(),
        requiredPushTokenType: PushToken.TokenType
    ) {
        let group = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Session manager reachability")!
        let flowManager = FlowManager(mediaManager: mediaManager)

        let serverNames = [environment.backendURL, environment.backendWSURL].compactMap { $0.host }
        let reachability = ZMReachability(serverNames: serverNames, group: group)

        let unauthenticatedSessionFactory = UnauthenticatedSessionFactory(
            appVersion: appVersion,
            environment: environment,
            reachability: reachability
        )

        let authenticatedSessionFactory = AuthenticatedSessionFactory(
            appVersion: appVersion,
            application: application,
            mediaManager: mediaManager,
            flowManager: flowManager,
            environment: environment,
            reachability: reachability,
            analytics: analytics
        )

        self.init(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: appVersion,
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            analytics: analytics,
            reachability: reachability,
            delegate: delegate,
            application: application,
            pushRegistry: PKPushRegistry(queue: nil),
            environment: environment,
            configuration: configuration,
            detector: detector,
            requiredPushTokenType: requiredPushTokenType
        )

        if configuration.blacklistDownloadInterval > 0 {
            self.blacklistVerificator = ZMBlacklistVerificator(checkInterval: configuration.blacklistDownloadInterval,
                                                               version: appVersion,
                                                               environment: environment,
                                                               working: nil,
                                                               application: application,
                                                               blacklistCallback: { [weak self] (blacklisted) in
                    guard let `self` = self, !self.isAppVersionBlacklisted else { return }

                    if blacklisted {
                        self.isAppVersionBlacklisted = true
                        self.delegate?.sessionManagerDidBlacklistCurrentVersion(reason: .appVersionBlacklisted)
                        // When the application version is blacklisted we don't want have a
                        // transition to any other state in the UI, so we won't inform it
                        // anymore by setting the delegate to nil.
                        self.delegate = nil
                    }
            })
        }

        self.memoryWarningObserver = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                                                            object: nil,
                                                                            queue: nil,
                                                                            using: {[weak self] _ in
            guard let `self` = self else {
                return
            }
            log.debug("Received memory warning, tearing down background user sessions.")
            self.tearDownAllBackgroundSessions()
        })

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    init(maxNumberAccounts: Int = defaultMaxNumberAccounts,
         appVersion: String,
         authenticatedSessionFactory: AuthenticatedSessionFactory,
         unauthenticatedSessionFactory: UnauthenticatedSessionFactory,
         analytics: AnalyticsType? = nil,
         reachability: ReachabilityProvider & TearDownCapable,
         delegate: SessionManagerDelegate?,
         application: ZMApplication,
         pushRegistry: PushRegistry,
         dispatchGroup: ZMSDispatchGroup? = nil,
         environment: BackendEnvironmentProvider,
         configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
         detector: JailbreakDetectorProtocol = JailbreakDetector(),
         requiredPushTokenType: PushToken.TokenType
    ) {
        SessionManager.enableLogsByEnvironmentVariable()
        self.environment = environment
        self.appVersion = appVersion
        self.application = application
        self.delegate = delegate
        self.dispatchGroup = dispatchGroup
        self.configuration = configuration.copy() as! SessionManagerConfiguration
        self.jailbreakDetector = detector
        self.requiredPushTokenType = requiredPushTokenType

        guard let sharedContainerURL = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            preconditionFailure("Unable to get shared container URL")
        }

        self.sharedContainerURL = sharedContainerURL
        self.accountManager = AccountManager(sharedDirectory: sharedContainerURL)

        log.debug("Starting the session manager:")

        if self.accountManager.accounts.count > 0 {
            log.debug("Known accounts:")
            self.accountManager.accounts.forEach { account in
                log.debug("\(account.userName) -- \(account.userIdentifier) -- \(account.teamName ?? "no team")")
            }

            if let selectedAccount = accountManager.selectedAccount {
                log.debug("Default account: \(selectedAccount.userIdentifier)")
            }
        } else {
            log.debug("No known accounts.")
        }

        self.authenticatedSessionFactory = authenticatedSessionFactory
        self.unauthenticatedSessionFactory = unauthenticatedSessionFactory
        self.reachability = reachability
        self.pushRegistry = pushRegistry
        self.maxNumberAccounts = maxNumberAccounts

        // we must set these before initializing the PushDispatcher b/c if the app
        // received a push from terminated state, it requires these properties to be
        // non nil in order to process the notification
        BackgroundActivityFactory.shared.activityManager = UIApplication.shared

        if let analytics = analytics {
            self.notificationsTracker = NotificationsTracker(analytics: analytics)
        } else {
            self.notificationsTracker = nil
        }

        super.init()

        registerForVoipPushNotifications()
        deleteAccountToken = AccountDeletedNotification.addObserver(observer: self, queue: groupQueue)
        callCenterObserverToken = WireCallCenterV3.addGlobalCallStateObserver(observer: self)

        checkJailbreakIfNeeded()
    }

    private func registerForVoipPushNotifications() {
        pushLog.safePublic("registering for voip push token")
        self.pushRegistry.delegate = self
        let pkPushTypeSet: Set<PKPushType> = [PKPushType.voIP]
        self.pushRegistry.desiredPushTypes = pkPushTypeSet
    }

    public func start(launchOptions: LaunchOptions) {
        if let account = accountManager.selectedAccount {
            selectInitialAccount(account, launchOptions: launchOptions)
        } else {
            createUnauthenticatedSession()
            delegate?.sessionManagerDidFailToLogin(error: nil)
        }
    }

    public func removeDatabaseFromDisk() {
        guard let account = accountManager.selectedAccount else {
            return
        }
        delete(account: account)
    }

    /// Creates an account with the given identifier and migrates its cookie storage.
    private func migrateAccount(with identifier: UUID) -> Account {
        let account = Account(userName: "", userIdentifier: identifier)
        accountManager.addAndSelect(account)
        let migrator = ZMPersistentCookieStorageMigrator(userIdentifier: identifier, serverName: authenticatedSessionFactory.environment.backendURL.host!)
        _ = migrator.createStoreMigratingLegacyStoreIfNeeded()
        return account
    }

    private func selectInitialAccount(_ account: Account, launchOptions: LaunchOptions) {
        if let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL {
            if (try? URLAction(url: url))?.causesLogout == true {
                // Do not log in if the launch URL action causes a logout
                return
            }
        }

        guard !shouldPerformPostRebootLogout() else {
            performPostRebootLogout()
            return
        }

        loadSession(for: account) { [weak self] session in
            guard let `self` = self, let session = session else { return }
            self.updateCurrentAccount(in: session.managedObjectContext)
            session.application(self.application, didFinishLaunching: launchOptions)
        }
    }

    /// Select the account to be the active account.
    /// - completion: runs when the user session was loaded
    /// - tearDownCompletion: runs when the UI no longer holds any references to the previous user session.
    public func select(_ account: Account, completion: ((ZMUserSession) -> Void)? = nil, tearDownCompletion: (() -> Void)? = nil) {
        guard !isSelectingAccount else { return }

        confirmSwitchingAccount { [weak self] in
            self?.isSelectingAccount = true
            let selectedAccount = self?.accountManager.selectedAccount

            self?.delegate?.sessionManagerWillOpenAccount(account,
                                                          from: selectedAccount,
                                                          userSessionCanBeTornDown: { [weak self] in
                self?.activeUserSession = nil
                tearDownCompletion?()
                self?.loadSession(for: account) { [weak self] session in
                    self?.isSelectingAccount = false

                    if let session = session {
                        self?.accountManager.select(account)
                        completion?(session)
                    }
                }
            })
        }
    }

    public func addAccount(userInfo: [String: Any]? = nil) {
        confirmSwitchingAccount { [weak self] in
            let error = NSError(code: .addAccountRequested, userInfo: userInfo)
            self?.delegate?.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: { [weak self] in
                self?.activeUserSession = nil
            })
        }
    }

    public func delete(account: Account) {
        delete(account: account, reason: .userInitiated)
    }

    public func wipeDatabase(for account: Account) {
        delete(account: account, reason: .databaseWiped)
    }

    fileprivate func deleteAllAccounts(reason: ZMAccountDeletedReason) {
        let inactiveAccounts = accountManager.accounts.filter({ $0 != accountManager.selectedAccount })
        inactiveAccounts.forEach({ delete(account: $0, reason: reason) })

        if let activeAccount = accountManager.selectedAccount {
            delete(account: activeAccount, reason: reason)
        }
    }

    fileprivate func delete(account: Account, reason: ZMAccountDeletedReason) {
        log.debug("Deleting account \(account.userIdentifier)...")
        if let secondAccount = accountManager.accounts.first(where: { $0.userIdentifier != account.userIdentifier }) {
            // Deleted an account but we can switch to another account
            select(secondAccount, tearDownCompletion: { [weak self] in
                self?.tearDownSessionAndDelete(account: account)
            })
        } else if accountManager.selectedAccount != account {
            // Deleted an inactive account, there's no need notify the UI
            self.tearDownSessionAndDelete(account: account)
        } else {
            // Deleted the last account so we need to return to the logged out area
            logoutCurrentSession(deleteCookie: true, deleteAccount: true, error: NSError(code: .accountDeleted, userInfo: [ZMAccountDeletedReasonKey: reason]))
        }
    }

    fileprivate func tearDownSessionAndDelete(account: Account) {
        self.tearDownBackgroundSession(for: account.userIdentifier)
        self.deleteAccountData(for: account)
    }

    fileprivate func logout(account: Account, error: Error? = nil) {
        log.debug("Logging out account \(account.userIdentifier)...")

        if let session = backgroundUserSessions[account.userIdentifier] {
            if session == activeUserSession {
                logoutCurrentSession(deleteCookie: true, error: error)
            } else {
                tearDownBackgroundSession(for: account.userIdentifier)
            }
        }
    }

    public func logoutCurrentSession(deleteCookie: Bool = true) {
        logoutCurrentSession(deleteCookie: deleteCookie, error: nil)
    }

    fileprivate func logoutCurrentSession(deleteCookie: Bool = true, deleteAccount: Bool = false, error: Error?) {
        guard let account = accountManager.selectedAccount else {
            return
        }

        backgroundUserSessions[account.userIdentifier] = nil
        tearDownObservers(account: account.userIdentifier)
        notifyUserSessionDestroyed(account.userIdentifier)

        self.createUnauthenticatedSession(accountId: deleteAccount ? nil : account.userIdentifier)

        delegate?.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: { [weak self] in

            if deleteCookie {
                self?.environment.cookieStorage(for: account).deleteKeychainItems()
            }

            self?.activeUserSession?.close(deleteCookie: deleteCookie)
            self?.activeUserSession = nil

            if deleteAccount {
                self?.deleteAccountData(for: account)
            }
        })
    }

    /**
     Loads a session for a given account
     
     - Parameters:
         - account: account for which to load the session
         - completion: called when session is loaded or when session fails to load
     */
    func loadSession(for account: Account, completion: @escaping (ZMUserSession?) -> Void) {
        guard environment.isAuthenticated(account) else {
            completion(nil)

            if configuration.wipeOnCookieInvalid {
                delete(account: account, reason: .sessionExpired)
            } else {
                createUnauthenticatedSession(accountId: account.userIdentifier)

                let error = NSError(code: .accessTokenExpired,
                                    userInfo: account.loginCredentials?.dictionaryRepresentation)
                delegate?.sessionManagerDidFailToLogin(error: error)
            }

            return
        }

        activateSession(for: account, completion: completion)
    }

    fileprivate func activateSession(for account: Account, completion: @escaping (ZMUserSession) -> Void) {
        self.withSession(for: account, notifyAboutMigration: true) { session in
            self.activeUserSession = session
            log.debug("Activated ZMUserSession for account \(String(describing: account.userName)) — \(account.userIdentifier)")

            self.delegate?.sessionManagerDidChangeActiveUserSession(userSession: session)
            self.configureUserNotifications()

            completion(session)

            // If the user isn't logged in it's because they still need
            // to complete the login flow, which will be handle elsewhere.
            if session.isLoggedIn {
                self.delegate?.sessionManagerDidReportLockChange(forSession: session)
                self.performPostUnlockActionsIfPossible(for: session)
            }
        }
    }

    func performPostUnlockActionsIfPossible(for session: ZMUserSession) {
        guard session.lock == .none else { return }
        processPendingURLActionRequiresAuthentication()
    }

    // Loads user session for @c account given and executes the @c action block.
    func withSession(for account: Account,
                     notifyAboutMigration: Bool = false,
                     perform completion: @escaping (ZMUserSession) -> Void) {
        log.debug("Request to load session for \(account)")
        let group = self.dispatchGroup
        group?.enter()
        self.sessionLoadingQueue.serialAsync(do: { onWorkDone in

            if let session = self.backgroundUserSessions[account.userIdentifier] {
                log.debug("Session for \(account) is already loaded")
                completion(session)
                onWorkDone()
                group?.leave()
            } else {
                let coreDataStack = CoreDataStack(account: account,
                                                  applicationContainer: self.sharedContainerURL,
                                                  dispatchGroup: self.dispatchGroup)

                if coreDataStack.needsMigration {
                    self.delegate?.sessionManagerWillMigrateAccount(userSessionCanBeTornDown: {})
                }

                coreDataStack.loadStores { (error) in
                    if error != nil {
                        self.delegate?.sessionManagerDidFailToLoadDatabase()
                    } else {
                        let userSession = self.startBackgroundSession(for: account,
                                                                      with: coreDataStack)
                        completion(userSession)
                    }
                    onWorkDone()
                    group?.leave()
                }
            }
        })
    }

    fileprivate func deleteAccountData(for account: Account) {
        log.debug("Deleting the data for \(account.userName) -- \(account.userIdentifier)")

        environment.cookieStorage(for: account).deleteKeychainItems()
        account.deleteKeychainItems()

        let accountID = account.userIdentifier
        self.accountManager.remove(account)

        do {
            try FileManager.default.removeItem(at: CoreDataStack.accountDataFolder(accountIdentifier: accountID, applicationContainer: sharedContainerURL))
        } catch let error {
            log.error("Impossible to delete the acccount \(account): \(error)")
        }
    }

    fileprivate func registerObservers(account: Account, session: ZMUserSession) {

        let selfUser = ZMUser.selfUser(inUserSession: session)
        let teamObserver = TeamChangeInfo.add(observer: self, for: nil, managedObjectContext: session.managedObjectContext)
        let selfObserver = UserChangeInfo.add(observer: self, for: selfUser, in: session.managedObjectContext)
        let conversationListObserver = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.conversations(inUserSession: session), userSession: session)
        let connectionRequestObserver = ConversationListChangeInfo.add(observer: self, for: ZMConversationList.pendingConnectionConversations(inUserSession: session), userSession: session)
        let unreadCountObserver = NotificationInContext.addObserver(name: .AccountUnreadCountDidChangeNotification,
                                                                    context: account) { [weak self] note in
            guard let account = note.context as? Account else { return }
            self?.accountManager.addOrUpdate(account)
        }

        let databaseEncryptionObserverToken = session.registerDatabaseLockedHandler { [weak self] _ in
            guard session == self?.activeUserSession else { return }
            self?.delegate?.sessionManagerDidReportLockChange(forSession: session)
        }

        accountTokens[account.userIdentifier] = [teamObserver,
                                                 selfObserver!,
                                                 conversationListObserver,
                                                 connectionRequestObserver,
                                                 unreadCountObserver,
                                                 databaseEncryptionObserverToken
        ]
    }

    @discardableResult
    fileprivate func createUnauthenticatedSession(accountId: UUID? = nil) -> UnauthenticatedSession {
        log.debug("Creating unauthenticated session")
        let unauthenticatedSession = unauthenticatedSessionFactory.session(delegate: self,
                                                                           authenticationStatusDelegate: self)
        unauthenticatedSession.accountId = accountId
        self.unauthenticatedSession = unauthenticatedSession
        return unauthenticatedSession
    }

    fileprivate func configure(session userSession: ZMUserSession, for account: Account) {
        userSession.sessionManager = self
        userSession.delegate = self
        require(backgroundUserSessions[account.userIdentifier] == nil, "User session is already loaded")
        backgroundUserSessions[account.userIdentifier] = userSession
        userSession.useConstantBitRateAudio = useConstantBitRateAudio
        userSession.usePackagingFeatureConfig = usePackagingFeatureConfig
        updateOrMigratePushToken(session: userSession)
        registerObservers(account: account, session: userSession)
    }

    func updateOrMigratePushToken(session userSession: ZMUserSession) {
        // If the legacy token exists, migrate it to the PushTokenStorage and delete it from selfClient
        if let client = userSession.selfUserClient, let legacyToken = client.retrieveLegacyPushToken() {
            PushTokenStorage.pushToken = legacyToken
        }

        guard let localToken = PushTokenStorage.pushToken else {
            updatePushToken(for: userSession)
            return
        }

        if localToken.tokenType != requiredPushTokenType {
            userSession.deletePushToken { [weak self] in
                self?.updatePushToken(for: userSession)
            }
        }
    }

    private func deleteMessagesOlderThanRetentionLimit(contextProvider: ContextProvider) {
        guard let messageRetentionInternal = configuration.messageRetentionInterval else { return }

        log.debug("Deleting messages older than the retention limit = \(messageRetentionInternal)")

        contextProvider.syncContext.performGroupedBlock {
            do {
                try ZMMessage.deleteMessagesOlderThan(Date(timeIntervalSinceNow: -messageRetentionInternal), context: contextProvider.syncContext)
            } catch {
                log.error("Failed to delete messages older than the retention limit")
            }
        }
    }

    // Creates the user session for @c account given, calls @c completion when done.
    private func startBackgroundSession(for account: Account, with coreDataStack: CoreDataStack) -> ZMUserSession {
        let sessionConfig = ZMUserSession.Configuration(
            appLockConfig: configuration.legacyAppLockConfig,
            useLegacyPushNotifications: shouldProcessLegacyPushes
        )

        guard let newSession = authenticatedSessionFactory.session(for: account,
                                                                   coreDataStack: coreDataStack,
                                                                   configuration: sessionConfig) else {
            preconditionFailure("Unable to create session for \(account)")
        }
        self.configure(session: newSession, for: account)
        self.deleteMessagesOlderThanRetentionLimit(contextProvider: coreDataStack)
        self.updateSystemBootTimeIfNeeded()

        log.debug("Created ZMUserSession for account \(String(describing: account.userName)) — \(account.userIdentifier)")
        notifyNewUserSessionCreated(newSession)
        return newSession
    }

    internal func tearDownBackgroundSession(for accountId: UUID) {
        guard let userSession = self.backgroundUserSessions[accountId] else {
            log.error("No session to tear down for \(accountId), known sessions: \(self.backgroundUserSessions)")
            return
        }
        userSession.close(deleteCookie: false)
        self.tearDownObservers(account: accountId)
        self.backgroundUserSessions[accountId] = nil
        notifyUserSessionDestroyed(accountId)
    }

    // Tears down and releases all background user sessions.
    internal func tearDownAllBackgroundSessions() {
        let backgroundSessions = backgroundUserSessions.filter { (_, session) -> Bool in
            return activeUserSession != session
        }

        backgroundSessions.keys.forEach({ sessionID in
            tearDownBackgroundSession(for: sessionID)
        })
    }

    fileprivate func tearDownObservers(account: UUID) {
        accountTokens.removeValue(forKey: account)
    }

    deinit {
        backgroundUserSessions.forEach { (_, session) in
            session.tearDown()
        }
        blacklistVerificator?.tearDown()
        unauthenticatedSession?.tearDown()
        reachability.tearDown()
    }

    public var isUserSessionActive: Bool {
        return activeUserSession != nil
    }

    func updateProfileImage(imageData: Data) {
        activeUserSession?.enqueue {
            self.activeUserSession?.userProfileImage?.updateImage(imageData: imageData)
        }
    }

    public var callNotificationStyle: CallNotificationStyle = .callKit {
        didSet {
            if #available(iOS 10.0, *) {
                updateCallNotificationStyle()
            }
        }
    }

    public func updateCallKitConfiguration() {
        callKitManager?.updateConfiguration()
    }

    private func updateCallNotificationStyle() {
        switch callNotificationStyle {
        case .pushNotifications:
            authenticatedSessionFactory.mediaManager.setUiStartsAudio(false)
            callKitManager = nil
        case .callKit:
            // Should be set to true when CallKit is used. Then AVS will not start
            // the audio before the audio session is active
            authenticatedSessionFactory.mediaManager.setUiStartsAudio(true)
            callKitManager = CallKitManager(delegate: self, mediaManager: authenticatedSessionFactory.mediaManager)
        }
    }

    public var useConstantBitRateAudio: Bool = false {
        didSet {
            activeUserSession?.useConstantBitRateAudio = useConstantBitRateAudio
        }
    }

    public var usePackagingFeatureConfig: Bool = false {
        didSet {
            activeUserSession?.usePackagingFeatureConfig = usePackagingFeatureConfig
        }
    }

    internal func checkJailbreakIfNeeded() {
        guard configuration.blockOnJailbreakOrRoot || configuration.wipeOnJailbreakOrRoot else { return }

        if jailbreakDetector?.isJailbroken() == true {

            if configuration.wipeOnJailbreakOrRoot {
                deleteAllAccounts(reason: .jailbreakDetected)
            }

            self.delegate?.sessionManagerDidBlacklistJailbrokenDevice()
            // When the device is jailbroken we don't want have a
            // transition to any other state in the UI, so we won't inform it
            // anymore by setting the delegate to nil.
            self.delegate = nil
        }
    }

    func shouldPerformPostRebootLogout() -> Bool {
        guard configuration.authenticateAfterReboot,
            accountManager.selectedAccount != nil,
            let systemBootTime = ProcessInfo.processInfo.bootTime(),
            let previousSystemBootTime = SessionManager.previousSystemBootTime,
            abs(systemBootTime.timeIntervalSince(previousSystemBootTime)) > 1.0
        else { return false }

        log.debug("Will logout due to device reboot. Previous boot time: \(previousSystemBootTime). Current boot time: \(systemBootTime)")
        return true
    }

    func performPostRebootLogout() {
        let error = NSError(code: .needsAuthenticationAfterReboot, userInfo: accountManager.selectedAccount?.loginCredentials?.dictionaryRepresentation)
        self.logoutCurrentSession(deleteCookie: true, error: error)
        log.debug("Logout caused by device reboot.")
    }

    func updateSystemBootTimeIfNeeded() {
        guard configuration.authenticateAfterReboot, let bootTime = ProcessInfo.processInfo.bootTime() else {
            return
        }

        SessionManager.previousSystemBootTime = bootTime
        log.debug("Updated system boot time: \(bootTime)")
    }

    public func passwordVerificationDidFail(with failCount: Int) {
        guard let count = configuration.failedPasswordThresholdBeforeWipe,
            failCount >= count, let account = accountManager.selectedAccount else {
                return
        }
        delete(account: account, reason: .failedPasswordLimitReached)
    }
}

// MARK: - TeamObserver

extension SessionManager {
    func updateCurrentAccount(in managedObjectContext: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        if let account = accountManager.accounts.first(where: { $0.userIdentifier == selfUser.remoteIdentifier }) {
            if let name = selfUser.team?.name {
                account.teamName = name
            }
            if let userName = selfUser.name {
                account.userName = userName
            }
            if let userProfileImage = selfUser.imageSmallProfileData {
                account.imageData = userProfileImage
            }
            if let teamImageData = selfUser.team?.imageData {
                account.teamImageData = teamImageData
            }

            account.loginCredentials = selfUser.loginCredentials

            // an optional `teamImageData` image could be saved here
            accountManager.addOrUpdate(account)
        }
    }
}

extension SessionManager: TeamObserver {
    public func teamDidChange(_ changeInfo: TeamChangeInfo) {
        let team = changeInfo.team
        guard let managedObjectContext = (team as? Team)?.managedObjectContext else {
            return
        }
        updateCurrentAccount(in: managedObjectContext)
    }
}

// MARK: - ZMUserObserver

extension SessionManager: ZMUserObserver {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.teamsChanged || changeInfo.nameChanged || changeInfo.imageSmallProfileDataChanged {
            guard let user = changeInfo.user as? ZMUser,
                let managedObjectContext = user.managedObjectContext else {
                return
            }
            updateCurrentAccount(in: managedObjectContext)
        }
    }
}

// MARK: - UnauthenticatedSessionDelegate

extension SessionManager {

    /// Needs to be called before we try to register another device because API requires password
    public func update(credentials: ZMCredentials) -> Bool {
        guard let userSession = activeUserSession, let emailCredentials = credentials as? ZMEmailCredentials else { return false }

        userSession.setEmailCredentials(emailCredentials)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        return true
    }
}

extension SessionManager: UnauthenticatedSessionDelegate {

    public func sessionIsAllowedToCreateNewAccount(_ session: UnauthenticatedSession) -> Bool {
        return accountManager.accounts.count < maxNumberAccounts
    }

    public func session(session: UnauthenticatedSession, isExistingAccount account: Account) -> Bool {
        return accountManager.accounts.contains(account)
    }

    public func session(session: UnauthenticatedSession, updatedCredentials credentials: ZMCredentials) -> Bool {
        return update(credentials: credentials)
    }

    public func session(session: UnauthenticatedSession, updatedProfileImage imageData: Data) {
        updateProfileImage(imageData: imageData)
    }

    public func session(session: UnauthenticatedSession, createdAccount account: Account) {
        guard !(accountManager.accounts.count == maxNumberAccounts && accountManager.account(with: account.userIdentifier) == nil) else {
            let error = NSError(code: .accountLimitReached, userInfo: nil)
            loginDelegate?.authenticationDidFail(error)
            return
        }

        accountManager.addAndSelect(account)

        self.activateSession(for: account) { userSession in
            self.updateCurrentAccount(in: userSession.managedObjectContext)

            if let profileImageData = session.authenticationStatus.profileImageData {
                self.updateProfileImage(imageData: profileImageData)
            }

            let registered = session.authenticationStatus.completedRegistration || session.registrationStatus.completedRegistration
            let emailCredentials = session.authenticationStatus.emailCredentials()

            userSession.syncManagedObjectContext.performGroupedBlock {
                userSession.setEmailCredentials(emailCredentials)
                userSession.syncManagedObjectContext.registeredOnThisDevice = registered
                ZMMessage.deleteOldEphemeralMessages(userSession.syncManagedObjectContext)
            }
        }
    }
}

// MARK: - UserSessionSelfUserClientDelegate

extension SessionManager: UserSessionSelfUserClientDelegate {
    public func clientRegistrationDidSucceed(accountId: UUID) {
        log.debug("Client registration was successful")

        if self.configuration.encryptionAtRestEnabledByDefault {
            do {
                try activeUserSession?.setEncryptionAtRest(enabled: true)
            } catch {
                if let account = accountManager.account(with: accountId) {
                    delete(account: account, reason: .biometricPasscodeNotAvailable)
                }
            }
        }

        loginDelegate?.clientRegistrationDidSucceed(accountId: accountId)
    }

    public func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        if unauthenticatedSession == nil || unauthenticatedSession?.accountId != accountId {
            createUnauthenticatedSession(accountId: accountId)
        }
        loginDelegate?.clientRegistrationDidFail(error, accountId: accountId)

        let account = accountManager.account(with: accountId)
        guard account == accountManager.selectedAccount else { return }
        delegate?.sessionManagerDidFailToLogin(error: error)
    }
}

extension SessionManager: AccountDeletedObserver {
    public func accountDeleted(accountId: UUID) {
        log.debug("\(accountId): Account was deleted")

        if let account = accountManager.account(with: accountId) {
            delete(account: account, reason: .sessionExpired)
        }
    }
}

// MARK: - UserSessionLogoutDelegate

extension SessionManager: UserSessionLogoutDelegate {
    /// Invoked when the user successfully logged out
    public func userDidLogout(accountId: UUID) {
        log.debug("\(accountId): User logged out")

        if let account = accountManager.account(with: accountId) {
            delete(account: account, reason: .userInitiated)
        }
    }

    public func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        guard
            let userSessionErrorCode = ZMUserSessionErrorCode(rawValue: UInt(error.code)),
            let account = accountManager.account(with: accountId)
        else {
            return
        }

        log.debug("Authentication invalidated for \(accountId): \(error.code)")

        switch userSessionErrorCode {
        case .clientDeletedRemotely:
            delete(account: account, reason: .sessionExpired)
        case .accessTokenExpired:
            if configuration.wipeOnCookieInvalid {
                delete(account: account, reason: .sessionExpired)
            } else {
                logout(account: account, error: error)
            }

        default:
            if unauthenticatedSession == nil {
                createUnauthenticatedSession(accountId: accountId)
            }

            let account = accountManager.account(with: accountId)
            guard account == accountManager.selectedAccount else { return }
            delegate?.sessionManagerDidFailToLogin(error: error)
        }
    }
}

// MARK: - Application lifetime notifications

extension SessionManager {
    @objc fileprivate func applicationWillEnterForeground(_ note: Notification) {
        BackgroundActivityFactory.shared.resume()

        updateAllUnreadCounts()
        checkJailbreakIfNeeded()

        // Delete expired url scheme verification tokens
        CompanyLoginVerificationToken.flushIfNeeded()

        if let session = activeUserSession {
            // The session lock may have changed so inform the delegate in case.
            self.delegate?.sessionManagerDidReportLockChange(forSession: session)
        }
    }

    @objc func applicationWillResignActive(_ note: Notification) {
        updateAllUnreadCounts()
        activeUserSession?.appLockController.beginTimer()
    }

    @objc fileprivate func applicationDidBecomeActive(_ note: Notification) {
        notificationsTracker?.dispatchEvent()
    }

}

// MARK: - Unread Conversation Count

extension SessionManager: ZMConversationListObserver {

    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {

        // find which account/session the conversation list belongs to & update count
        guard let moc = changeInfo.conversationList.managedObjectContext else { return }

        for (accountId, session) in backgroundUserSessions where session.managedObjectContext == moc {
            updateUnreadCount(for: accountId)
        }
    }

    fileprivate func updateUnreadCount(for accountID: UUID) {
        guard
            let account = self.accountManager.account(with: accountID),
            let session = backgroundUserSessions[accountID]
        else {
            return
        }

        account.unreadConversationCount = Int(ZMConversation.unreadConversationCount(in: session.managedObjectContext))
    }

    fileprivate func updateAllUnreadCounts() {
        for accountID in backgroundUserSessions.keys {
            updateUnreadCount(for: accountID)
        }
    }

    public func updateAppIconBadge(accountID: UUID, unreadCount: Int) {
        DispatchQueue.main.async {
            let account = self.accountManager.account(with: accountID)
            account?.unreadConversationCount = unreadCount
            let totalUnreadCount = self.accountManager.totalUnreadCount
            self.application.applicationIconBadgeNumber = totalUnreadCount
            Logging.push.safePublic("Updated badge count to \(SanitizedString(stringLiteral: String(totalUnreadCount)))")
        }
    }
}

extension SessionManager: WireCallCenterCallStateObserver {

    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        guard let moc = conversation.managedObjectContext else { return }

        switch callState {
        case .answered, .outgoing:
            for (_, session) in backgroundUserSessions where session.managedObjectContext == moc && activeUserSession != session {
                showConversation(conversation, at: nil, in: session)
            }
        default:
            return
        }
    }

}

extension SessionManager {

    /// The SSO code provided by the user when clicking their company link. Points to a UUID object.
    public static var companyLoginCodeKey: String {
        return "WireCompanyLoginCode"
    }

    /// The timestamp when the user initiated the request.
    public static var companyLoginRequestTimestampKey: String {
        return "WireCompanyLoginTimesta;p"
    }

}

// MARK: - Session manager observer

@objc public protocol SessionManagerCreatedSessionObserver: AnyObject {
    /// Invoked when the SessionManager creates a user session either by
    /// activating one or creating one in the background. No assumption should
    /// be made that the session is active.
    func sessionManagerCreated(userSession: ZMUserSession)

    /// Invoked when the SessionManager creates a new unauthenticated session.
    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession)
}

@objc public protocol SessionManagerDestroyedSessionObserver: AnyObject {
    /// Invoked when the SessionManager tears down the user session associated
    /// with the accountId.
    func sessionManagerDestroyedUserSession(for accountId: UUID)
}

private let sessionManagerCreatedUnauthenticatedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerCreatedUnauthenticatedSessionNotification")
private let sessionManagerCreatedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerCreatedSessionNotification")
private let sessionManagerDestroyedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerDestroyedSessionNotification")

extension SessionManager: NotificationContext {

    public func addUnauthenticatedSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
            name: sessionManagerCreatedUnauthenticatedSessionNotificationName,
            context: self) { [weak observer] note in observer?.sessionManagerCreated(unauthenticatedSession: note.object as! UnauthenticatedSession) }
    }

    public func addSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
            name: sessionManagerCreatedSessionNotificationName,
            context: self) { [weak observer] note in observer?.sessionManagerCreated(userSession: note.object as! ZMUserSession) }
    }

    public func addSessionManagerDestroyedSessionObserver(_ observer: SessionManagerDestroyedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
        name: sessionManagerDestroyedSessionNotificationName,
        context: self) { [weak observer] note in observer?.sessionManagerDestroyedUserSession(for: note.object as! UUID) }
    }

    fileprivate func notifyNewUserSessionCreated(_ userSession: ZMUserSession) {
        NotificationInContext(name: sessionManagerCreatedSessionNotificationName, context: self, object: userSession).post()
    }

    fileprivate func notifyUserSessionDestroyed(_ accountId: UUID) {
        NotificationInContext(name: sessionManagerDestroyedSessionNotificationName, context: self, object: accountId as AnyObject).post()
    }
}

extension SessionManager {
    public func markAllConversationsAsRead(completion: (() -> Void)?) {
        let group = DispatchGroup()

        self.accountManager.accounts.forEach { account in
            group.enter()
            self.withSession(for: account) { userSession in
                userSession.perform {
                    userSession.markAllConversationsAsRead()
                }

                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion?()
        }
    }
}

extension SessionManager {

    public func confirmSwitchingAccount(completion: @escaping () -> Void) {
        guard
            let switchingDelegate = switchingDelegate,
            let activeUserSession = activeUserSession,
            activeUserSession.isCallOngoing
        else {
            return completion()
        }

        switchingDelegate.confirmSwitchingAccount(completion: { confirmed in
            if confirmed {
                activeUserSession.callCenter?.endAllCalls()
                completion()
            }
        })
    }
}

// MARK: - AVS Logging
extension SessionManager {
    public static func startAVSLogging() {
        avsLogObserver = AVSLogObserver()
    }

    public static func stopAVSLogging() {
        avsLogObserver = nil
    }
}
