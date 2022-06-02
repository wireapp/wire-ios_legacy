//
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

@objc(ZMThirdPartyServicesDelegate)
public protocol ThirdPartyServicesDelegate: NSObjectProtocol {

    /// This will get called at a convenient point in time when Hockey and Localytics should upload their data.
    /// We try not to have Hockey and Localytics use the network while we're sync'ing.
    @objc(userSessionIsReadyToUploadServicesData:)
    func userSessionIsReadyToUploadServicesData(userSession: ZMUserSession)

}

@objc(UserSessionSelfUserClientDelegate)
public protocol UserSessionSelfUserClientDelegate: NSObjectProtocol {
    /// Invoked when a client is successfully registered
    func clientRegistrationDidSucceed(accountId: UUID)

    /// Invoked when there was an error registering the client
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID)
}

@objc(UserSessionLogoutDelegate)
public protocol UserSessionLogoutDelegate: NSObjectProtocol {
    /// Invoked when the user successfully logged out
    func userDidLogout(accountId: UUID)

    /// Invoked when the authentication has proven invalid
    func authenticationInvalidated(_ error: NSError, accountId: UUID)
}

typealias UserSessionDelegate = UserSessionEncryptionAtRestDelegate
    & UserSessionSelfUserClientDelegate
    & UserSessionLogoutDelegate
    & UserSessionAppLockDelegate

@objcMembers
public class ZMUserSession: NSObject {

    private let appVersion: String
    private var tokens: [Any] = []
    private var tornDown: Bool = false

    var isNetworkOnline: Bool = true
    var isPerformingSync: Bool = true {
        willSet {
            notificationDispatcher.operationMode = newValue ? .economical : .normal
        }
    }
    var hasNotifiedThirdPartyServices: Bool = false

    var coreDataStack: CoreDataStack!
    let application: ZMApplication
    let flowManager: FlowManagerType
    var mediaManager: MediaManagerType
    var analytics: AnalyticsType?
    var transportSession: TransportSessionType
    let storedDidSaveNotifications: ContextDidSaveNotificationPersistence
    let userExpirationObserver: UserExpirationObserver
    var updateEventProcessor: UpdateEventProcessor?
    var strategyDirectory: StrategyDirectoryProtocol?
    var syncStrategy: ZMSyncStrategy?
    var operationLoop: ZMOperationLoop?
    var notificationDispatcher: NotificationDispatcher
    var localNotificationDispatcher: LocalNotificationDispatcher?
    var applicationStatusDirectory: ApplicationStatusDirectory?
    var callStateObserver: CallStateObserver?
    var messageReplyObserver: ManagedObjectContextChangeObserver?
    var likeMesssageObserver: ManagedObjectContextChangeObserver?
    var urlActionProcessors: [URLActionProcessor]?
    let debugCommands: [String: DebugCommand]
    let eventProcessingTracker: EventProcessingTracker = EventProcessingTracker()
    let hotFix: ZMHotFix

    public lazy var featureService = FeatureService(context: syncContext)

    public var appLockController: AppLockType

    public var fileSharingFeature: Feature.FileSharing {
        let featureService = FeatureService(context: coreDataStack.viewContext)
        return featureService.fetchFileSharing()
    }

    public var selfDeletingMessagesFeature: Feature.SelfDeletingMessages {
        let featureService = FeatureService(context: coreDataStack.viewContext)
        return featureService.fetchSelfDeletingMesssages()
    }

    public var conversationGuestLinksFeature: Feature.ConversationGuestLinks {
        let featureService = FeatureService(context: coreDataStack.viewContext)
        return featureService.fetchConversationGuestLinks()
    }

    public var classifiedDomainsFeature: Feature.ClassifiedDomains {
        let featureService = FeatureService(context: coreDataStack.viewContext)
        return featureService.fetchClassifiedDomains()
    }

    public var hasCompletedInitialSync: Bool = false

    public var topConversationsDirectory: TopConversationsDirectory

    public var managedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.viewContext
    }

    public var syncManagedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.syncContext
    }

    public var searchManagedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.searchContext
    }

    public var sharedContainerURL: URL { // TODO jacob we don't want this to be public
        return coreDataStack.applicationContainer
    }

    public var selfUserClient: UserClient? { // TODO jacob we don't want this to be public
        return ZMUser.selfUser(in: managedObjectContext).selfClient()
    }

    public var userProfile: UserProfile? {
        return applicationStatusDirectory?.userProfileUpdateStatus
    }

    public var userProfileImage: UserProfileImageUpdateProtocol? {
        return applicationStatusDirectory?.userProfileImageUpdateStatus
    }

    public var conversationDirectory: ConversationDirectoryType {
        return managedObjectContext.conversationListDirectory()
    }

    public var operationStatus: OperationStatus? { // TODO jacob we don't want this to be public
        return applicationStatusDirectory?.operationStatus
    }

    public private(set) var networkState: ZMNetworkState = .online {
        didSet {
            if oldValue != networkState {
                ZMNetworkAvailabilityChangeNotification.notify(networkState: networkState, userSession: self)
            }
        }
    }

    public var isNotificationContentHidden: Bool {
        get {
            guard let value = managedObjectContext.persistentStoreMetadata(forKey: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey) as? NSNumber else {
                return false
            }

            return value.boolValue
        }
        set {
            managedObjectContext.setPersistentStoreMetadata(NSNumber(value: newValue), key: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey)
        }
    }

    weak var delegate: UserSessionDelegate?

    // TODO remove this property and move functionality to separate protocols under UserSessionDelegate
    public weak var sessionManager: SessionManagerType?

    public weak var thirdPartyServicesDelegate: ThirdPartyServicesDelegate?

    // MARK: - Tear down

    deinit {
        require(tornDown, "tearDown must be called before the ZMUserSession is deallocated")
    }

    public func tearDown() {
        guard !tornDown else { return }

        tokens.removeAll()
        application.unregisterObserverForStateChange(self)
        callStateObserver = nil
        syncStrategy?.tearDown()
        syncStrategy = nil
        operationLoop?.tearDown()
        operationLoop = nil
        transportSession.tearDown()
        applicationStatusDirectory = nil
        notificationDispatcher.tearDown()

        // Wait for all sync operations to finish
        syncManagedObjectContext.performGroupedBlockAndWait { }

        let uiMOC = coreDataStack.viewContext
        coreDataStack = nil

        let shouldWaitOnUIMoc = !(OperationQueue.current == OperationQueue.main && uiMOC.concurrencyType == .mainQueueConcurrencyType)
        if shouldWaitOnUIMoc {
            uiMOC.performAndWait {
                // warning: this will hang if the uiMoc queue is same as self.requestQueue (typically uiMoc queue is the main queue)
            }
        }

        NotificationCenter.default.removeObserver(self)

        tornDown = true
    }

    public init(userId: UUID,
                transportSession: TransportSessionType,
                mediaManager: MediaManagerType,
                flowManager: FlowManagerType,
                analytics: AnalyticsType?,
                eventProcessor: UpdateEventProcessor? = nil,
                strategyDirectory: StrategyDirectoryProtocol? = nil,
                syncStrategy: ZMSyncStrategy? = nil,
                operationLoop: ZMOperationLoop? = nil,
                application: ZMApplication,
                appVersion: String,
                coreDataStack: CoreDataStack,
                configuration: Configuration) {

        coreDataStack.syncContext.performGroupedBlockAndWait {
            coreDataStack.syncContext.analytics = analytics
            coreDataStack.syncContext.zm_userInterface = coreDataStack.viewContext
        }

        coreDataStack.viewContext.zm_sync = coreDataStack.syncContext

        self.application = application
        self.appVersion = appVersion
        self.flowManager = flowManager
        self.mediaManager = mediaManager
        self.analytics = analytics
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.notificationDispatcher = NotificationDispatcher(managedObjectContext: coreDataStack.viewContext)
        self.storedDidSaveNotifications = ContextDidSaveNotificationPersistence(accountContainer: coreDataStack.accountContainer)
        self.userExpirationObserver = UserExpirationObserver(managedObjectContext: coreDataStack.viewContext)
        self.topConversationsDirectory = TopConversationsDirectory(managedObjectContext: coreDataStack.viewContext)
        self.debugCommands = ZMUserSession.initDebugCommands()
        self.hotFix = ZMHotFix(syncMOC: coreDataStack.syncContext)
        self.appLockController = AppLockController(userId: userId, selfUser: .selfUser(in: coreDataStack.viewContext), legacyConfig: configuration.appLockConfig)
        super.init()

        appLockController.delegate = self

        configureCaches()

        syncManagedObjectContext.performGroupedBlockAndWait {
            self.localNotificationDispatcher = LocalNotificationDispatcher(in: coreDataStack.syncContext)
            self.configureTransportSession()
            self.applicationStatusDirectory = self.createApplicationStatusDirectory()
            self.updateEventProcessor = eventProcessor ?? self.createUpdateEventProcessor()
            self.strategyDirectory = strategyDirectory ?? self.createStrategyDirectory(useLegacyPushNotifications: configuration.useLegacyPushNotifications)
            self.syncStrategy = syncStrategy ?? self.createSyncStrategy()
            self.operationLoop = operationLoop ?? self.createOperationLoop()
            self.urlActionProcessors = self.createURLActionProcessors()
            self.callStateObserver = CallStateObserver(localNotificationDispatcher: self.localNotificationDispatcher!,
                                                       contextProvider: self,
                                                       callNotificationStyleProvider: self)
        }

        updateEventProcessor!.eventConsumers = self.strategyDirectory!.eventConsumers
        registerForCalculateBadgeCountNotification()
        registerForRegisteringPushTokenNotification()
        registerForBackgroundNotifications()
        enableBackgroundFetch()
        observeChangesOnShareExtension()
        startEphemeralTimers()
        notifyUserAboutChangesInAvailabilityBehaviourIfNeeded()
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
        restoreDebugCommandsState()
    }

    private func configureTransportSession() {
        transportSession.pushChannel.clientID = selfUserClient?.remoteIdentifier
        transportSession.setNetworkStateDelegate(self)
        transportSession.setAccessTokenRenewalFailureHandler { [weak self] (response) in
            self?.transportSessionAccessTokenDidFail(response: response)
        }
    }

    private func configureCaches() {
        let cacheLocation = FileManager.default.cachesURLForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)
        ZMUserSession.moveCachesIfNeededForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)

        let userImageCache = UserImageLocalCache(location: cacheLocation)
        let fileAssetCache = FileAssetCache(location: cacheLocation)

        managedObjectContext.zm_userImageCache = userImageCache
        managedObjectContext.zm_fileAssetCache = fileAssetCache
        managedObjectContext.zm_searchUserCache = NSCache()

        syncManagedObjectContext.performGroupedBlockAndWait {
            self.syncManagedObjectContext.zm_userImageCache = userImageCache
            self.syncManagedObjectContext.zm_fileAssetCache = fileAssetCache
        }

    }

    private func createStrategyDirectory(useLegacyPushNotifications: Bool) -> StrategyDirectoryProtocol {
        return StrategyDirectory(contextProvider: coreDataStack,
                                 applicationStatusDirectory: applicationStatusDirectory!,
                                 cookieStorage: transportSession.cookieStorage,
                                 pushMessageHandler: localNotificationDispatcher!,
                                 flowManager: flowManager,
                                 updateEventProcessor: updateEventProcessor!,
                                 localNotificationDispatcher: localNotificationDispatcher!,
                                 useLegacyPushNotifications: useLegacyPushNotifications)
    }

    private func createUpdateEventProcessor() -> EventProcessor {
        return EventProcessor(storeProvider: self.coreDataStack,
                              syncStatus: applicationStatusDirectory!.syncStatus,
                              eventProcessingTracker: eventProcessingTracker)
    }

    private func createApplicationStatusDirectory() -> ApplicationStatusDirectory {
        let applicationStatusDirectory = ApplicationStatusDirectory(withManagedObjectContext: self.syncManagedObjectContext,
                                                                    cookieStorage: transportSession.cookieStorage,
                                                                    requestCancellation: transportSession,
                                                                    application: application,
                                                                    syncStateDelegate: self,
                                                                    analytics: analytics)

        applicationStatusDirectory.clientRegistrationStatus.prepareForClientRegistration()
        self.hasCompletedInitialSync = !applicationStatusDirectory.syncStatus.isSlowSyncing

        return applicationStatusDirectory
    }

    private func createURLActionProcessors() -> [URLActionProcessor] {
        return [
            DeepLinkURLActionProcessor(contextProvider: coreDataStack,
                                       transportSession: transportSession,
                                       eventProcessor: updateEventProcessor!),
            ConnectToBotURLActionProcessor(contextprovider: coreDataStack,
                                           transportSession: transportSession,
                                           eventProcessor: updateEventProcessor!)
        ]
    }

    private func createSyncStrategy() -> ZMSyncStrategy {
        return ZMSyncStrategy(contextProvider: coreDataStack,
                              notificationsDispatcher: notificationDispatcher,
                              applicationStatusDirectory: applicationStatusDirectory!,
                              application: application,
                              strategyDirectory: strategyDirectory!,
                              eventProcessingTracker: eventProcessingTracker)
    }

    private func createOperationLoop() -> ZMOperationLoop {
        return ZMOperationLoop(transportSession: transportSession,
                               requestStrategy: syncStrategy,
                               updateEventProcessor: updateEventProcessor!,
                               applicationStatusDirectory: applicationStatusDirectory!,
                               uiMOC: managedObjectContext,
                               syncMOC: syncManagedObjectContext)
    }

    func startRequestLoopTracker() {
        transportSession.requestLoopDetectionCallback = { path in
            guard !path.hasSuffix("/typing") else { return }

            Logging.network.warn("Request loop happening at path: \(path)")

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: ZMLoggingRequestLoopNotificationName),
                                                object: nil,
                                                userInfo: ["path": path])
            }
        }
    }

    private func registerForCalculateBadgeCountNotification() {
        tokens.append(NotificationInContext.addObserver(name: .calculateBadgeCount, context: managedObjectContext.notificationContext) { [weak self] (_) in
            self?.calculateBadgeCount()
        })
    }

    /// Count number of conversations with unread messages and update the application icon badge count.
    private func calculateBadgeCount() {
        let accountID = coreDataStack.account.userIdentifier
        let unreadCount = Int(ZMConversation.unreadConversationCount(in: self.syncManagedObjectContext))
        Logging.push.safePublic("Updating badge count for \(accountID) to \(SanitizedString(stringLiteral: String(unreadCount)))")
        self.sessionManager?.updateAppIconBadge(accountID: accountID, unreadCount: unreadCount)
    }

    private func registerForBackgroundNotifications() {
        application.registerObserverForDidEnterBackground(self, selector: #selector(applicationDidEnterBackground(_:)))
        application.registerObserverForWillEnterForeground(self, selector: #selector(applicationWillEnterForeground(_:)))

    }

    private func enableBackgroundFetch() {
        // We enable background fetch by setting the minimum interval to something different from UIApplicationBackgroundFetchIntervalNever
        application.setMinimumBackgroundFetchInterval(10.0 * 60.0 + Double(arc4random_uniform(5 * 60)))
    }

    private func notifyUserAboutChangesInAvailabilityBehaviourIfNeeded() {
        syncManagedObjectContext.performGroupedBlock {
            self.localNotificationDispatcher?.notifyAvailabilityBehaviourChangedIfNeeded()
        }
    }

    // MARK: - Network

    public func requestSlowSync() {
        applicationStatusDirectory?.requestSlowSync()
    }

    private func transportSessionAccessTokenDidFail(response: ZMTransportResponse) {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let strongRef = self else { return }
            let selfUser = ZMUser.selfUser(in: strongRef.managedObjectContext)
            let error = NSError.userSessionErrorWith(.accessTokenExpired, userInfo: selfUser.loginCredentials.dictionaryRepresentation)
            strongRef.notifyAuthenticationInvalidated(error)
        }
    }

    // MARK: - Perform changes

    public func saveOrRollbackChanges() {
        managedObjectContext.saveOrRollback()
    }

    @objc(performChanges:)
    public func perform(_ changes: @escaping () -> Void) {
        managedObjectContext.performGroupedBlockAndWait { [weak self] in
            changes()
            self?.saveOrRollbackChanges()
        }
    }

    @objc(enqueueChanges:)
    public func enqueue(_ changes: @escaping () -> Void) {
        enqueue(changes, completionHandler: nil)
    }

    @objc(enqueueChanges:completionHandler:)
    public func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        managedObjectContext.performGroupedBlock { [weak self] in
            changes()
            self?.saveOrRollbackChanges()
            completionHandler?()
        }
    }

    @objc(enqueueDelayedChanges:completionHandler:)
    public func enqueueDelayed(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        managedObjectContext.performGroupedBlock { [weak self] in
            changes()
            self?.saveOrRollbackChanges()

            let group = ZMSDispatchGroup(label: "enqueueDelayedChanges")
            self?.managedObjectContext.enqueueDelayedSave(with: group)

            group?.notify(on: DispatchQueue.global(qos: .background), block: {
                self?.managedObjectContext.performGroupedBlock {
                    completionHandler?()
                }
            })
        }
    }

    // MARK: - Account

    public func initiateUserDeletion() {
        syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.setPersistentStoreMetadata(NSNumber(value: true), key: DeleteAccountRequestStrategy.userDeletionInitiatedKey)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

}

extension ZMUserSession: ZMNetworkStateDelegate {

    public func didReceiveData() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isNetworkOnline = true
            self?.updateNetworkState()
        }
    }

    public func didGoOffline() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isNetworkOnline = false
            self?.updateNetworkState()
            self?.saveOrRollbackChanges()

        }
    }

    func updateNetworkState() {
        let state: ZMNetworkState

        if isNetworkOnline {
            if isPerformingSync {
                state = .onlineSynchronizing
            } else {
                state = .online
            }
        } else {
            state = .offline
        }

        networkState = state
    }

}

extension ZMUserSession: ZMSyncStateDelegate {

    public func didStartSlowSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.notificationDispatcher.isEnabled = false
            self?.updateNetworkState()
        }
    }

    public func didFinishSlowSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.hasCompletedInitialSync = true
            self?.notificationDispatcher.isEnabled = true

            if let context = self?.managedObjectContext {
                ZMUserSession.notifyInitialSyncCompleted(context: context)
            }
        }
    }

    public func didStartQuickSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }
    }

    public func didFinishQuickSync() {
        processEvents()

        managedObjectContext.performGroupedBlock { [weak self] in
            self?.notifyThirdPartyServices()
        }

        fetchFeatureConfigs()
    }

    func processEvents() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }

        let hasMoreEventsToProcess = updateEventProcessor!.processEventsIfReady()
        let isSyncing = applicationStatusDirectory?.syncStatus.isSyncing == true

        if !hasMoreEventsToProcess {
            hotFix.applyPatches()
        }

        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = hasMoreEventsToProcess || isSyncing
            self?.updateNetworkState()
        }
    }

    private func fetchFeatureConfigs() {
        let action = GetFeatureConfigsAction { result in
            if case let .failure(reason) = result {
                Logging.network.error("Failed to fetch feature configs: \(String(describing: reason))")
            }
        }

        action.send(in: syncContext.notificationContext)
    }

    public func didRegisterSelfUserClient(_ userClient: UserClient!) {
        // If during registration user allowed notifications,
        // The push token can only be registered after client registration
        transportSession.pushChannel.clientID = userClient.remoteIdentifier
        registerCurrentPushToken()
        UserClient.triggerSelfClientCapabilityUpdate(syncContext)

        managedObjectContext.performGroupedBlock { [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.clientRegistrationDidSucceed(accountId: accountId)
        }
    }

    public func didFailToRegisterSelfUserClient(error: Error!) {
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.clientRegistrationDidFail(error as NSError, accountId: accountId)
        }
    }

    public func didDeleteSelfUserClient(error: Error!) {
        notifyAuthenticationInvalidated(error)
    }

    public func notifyThirdPartyServices() {
        if !hasNotifiedThirdPartyServices {
            hasNotifiedThirdPartyServices = true
            thirdPartyServicesDelegate?.userSessionIsReadyToUploadServicesData(userSession: self)
        }
    }

    private func notifyAuthenticationInvalidated(_ error: Error) {
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.authenticationInvalidated(error as NSError, accountId: accountId)
        }
    }
}

extension ZMUserSession: URLActionProcessor {
    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        urlActionProcessors?.forEach({ $0.process(urlAction: urlAction, delegate: delegate)})
    }
}

private extension NSManagedObjectContext {
    var selfUserId: UUID? {
        ZMUser.selfUser(in: self).remoteIdentifier
    }
}

extension ZMUserSession: ContextProvider {

    public var account: Account {
        return coreDataStack.account
    }

    public var viewContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }

    public var syncContext: NSManagedObjectContext {
        return coreDataStack.syncContext
    }

    public var searchContext: NSManagedObjectContext {
        return coreDataStack.searchContext
    }

    public var eventContext: NSManagedObjectContext {
        return coreDataStack.eventContext
    }

}
