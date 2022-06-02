//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
import WireTransport
import WireRequestStrategy
import WireLinkPreview

class PushMessageHandlerDummy: NSObject, PushMessageHandler {

    func didFailToSend(_ message: ZMMessage) {
        // nop
    }
}

class ClientRegistrationStatus: NSObject, ClientRegistrationDelegate {

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var clientIsReadyForRequests: Bool {
        if let clientId = context.persistentStoreMetadata(forKey: "PersistedClientId") as? String { // TODO move constant into shared framework
            return !clientId.isEmpty
        }

        return false
    }

    func didDetectCurrentClientDeletion() {
        // nop
    }
}

class AuthenticationStatus: AuthenticationStatusProvider {

    let transportSession: ZMTransportSession

    init(transportSession: ZMTransportSession) {
        self.transportSession = transportSession
    }

    var state: AuthenticationState {
        return isLoggedIn ? .authenticated : .unauthenticated
    }

    private var isLoggedIn: Bool {
        return transportSession.cookieStorage.authenticationCookieData != nil
    }

}

extension BackendEnvironmentProvider {
    func cookieStorage(for account: Account) -> ZMPersistentCookieStorage {
        let backendURL = self.backendURL.host!
        return ZMPersistentCookieStorage(forServerName: backendURL, userIdentifier: account.userIdentifier)
    }

    public func isAuthenticated(_ account: Account) -> Bool {
        return cookieStorage(for: account).authenticationCookieData != nil
    }
}

class ApplicationStatusDirectory: ApplicationStatus {

    let transportSession: ZMTransportSession

    /// The authentication status used to verify a user is authenticated
    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client
    public let clientRegistrationStatus: ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public init(transportSession: ZMTransportSession, authenticationStatus: AuthenticationStatusProvider, clientRegistrationStatus: ClientRegistrationStatus, linkPreviewDetector: LinkPreviewDetectorType) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
    }

    public convenience init(syncContext: NSManagedObjectContext, transportSession: ZMTransportSession) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()
        self.init(transportSession: transportSession, authenticationStatus: authenticationStatus, clientRegistrationStatus: clientRegistrationStatus, linkPreviewDetector: linkPreviewDetector)
    }

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            return .online
        } else {
            return .unauthenticated
        }
    }

    public var operationState: OperationState {
        return .foreground
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        return self.clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        return transportSession
    }

    func requestSlowSync() {
        // we don't do slow syncing in the share engine
    }

}

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of 
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public class SharingSession {

    /// The failure reason of a `SharingSession` initialization
    /// - NeedsMigration: The database needs a migration which is only done in the main app
    /// - LoggedOut: No user is logged in
    /// - missingSharedContainer: The shared container is missing
    public enum InitializationError: Error {
        case needsMigration, loggedOut, missingSharedContainer
    }

    /// The `NSManagedObjectContext` used to retrieve the conversations
    var userInterfaceContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }

    private var syncContext: NSManagedObjectContext {
        return coreDataStack.syncContext
    }

    /// Directory of all application statuses
    private let applicationStatusDirectory: ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persistet
    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    public let analyticsEventPersistence: ShareExtensionAnalyticsPersistence

    private var contextSaveObserverToken: NSObjectProtocol?

    let transportSession: ZMTransportSession

    let coreDataStack: CoreDataStack

    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        return userInterfaceContext.conversationListDirectory()
    }

    /// Whether all prerequsisties for sharing are met
    public var canShare: Bool {
        return applicationStatusDirectory.authenticationStatus.state == .authenticated && applicationStatusDirectory.clientRegistrationStatus.clientIsReadyForRequests
    }

    /// List of non-archived conversations in which the user can write
    /// The list will be sorted by relevance
    public var writeableNonArchivedConversations: [Conversation] {
        return directory.unarchivedConversations.writeableConversations
    }

    /// List of archived conversations in which the user can write
    public var writebleArchivedConversations: [Conversation] {
        return directory.archivedConversations.writeableConversations
    }

    private let operationLoop: RequestGeneratingOperationLoop

    private let strategyFactory: StrategyFactory

    public let appLockController: AppLockType

    public var fileSharingFeature: Feature.FileSharing {
        let featureService = FeatureService(context: coreDataStack.viewContext)
        return featureService.fetchFileSharing()
    }

    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown

    public convenience init(applicationGroupIdentifier: String,
                            accountIdentifier: UUID,
                            hostBundleIdentifier: String,
                            environment: BackendEnvironmentProvider,
                            appLockConfig: AppLockController.LegacyConfig?) throws {

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)

        let coreDataStack = CoreDataStack(account: Account(userName: "", userIdentifier: accountIdentifier),
                                          applicationContainer: sharedContainerURL)

        guard coreDataStack.storesExists else {
            throw InitializationError.missingSharedContainer
        }

        guard !coreDataStack.needsMigration  else {
            throw InitializationError.needsMigration
        }

        var storeError: Error?
        coreDataStack.loadStores { _ in
            storeError = storeError
        }

        guard storeError == nil else { throw InitializationError.missingSharedContainer }

        let cookieStorage = ZMPersistentCookieStorage(forServerName: environment.backendURL.host!, userIdentifier: accountIdentifier)
        let reachabilityGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Sharing session reachability")!
        let serverNames = [environment.backendURL, environment.backendWSURL].compactMap { $0.host }
        let reachability = ZMReachability(serverNames: serverNames, group: reachabilityGroup)

        let transportSession =  ZMTransportSession(
            environment: environment,
            cookieStorage: cookieStorage,
            reachability: reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: applicationGroupIdentifier,
            applicationVersion: "1.0.0"
        )

        try self.init(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL),
            appLockConfig: appLockConfig)
    }

    internal init(accountIdentifier: UUID,
                  coreDataStack: CoreDataStack,
                  transportSession: ZMTransportSession,
                  cachesDirectory: URL,
                  saveNotificationPersistence: ContextDidSaveNotificationPersistence,
                  analyticsEventPersistence: ShareExtensionAnalyticsPersistence,
                  applicationStatusDirectory: ApplicationStatusDirectory,
                  operationLoop: RequestGeneratingOperationLoop,
                  strategyFactory: StrategyFactory,
                  appLockConfig: AppLockController.LegacyConfig?
        ) throws {

        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.analyticsEventPersistence = analyticsEventPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory

        let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)
        self.appLockController = AppLockController(userId: accountIdentifier, selfUser: selfUser, legacyConfig: appLockConfig)

        guard applicationStatusDirectory.authenticationStatus.state == .authenticated else { throw InitializationError.loggedOut }

        setupCaches(at: cachesDirectory)
        setupObservers()
    }

    public convenience init(accountIdentifier: UUID,
                            coreDataStack: CoreDataStack,
                            transportSession: ZMTransportSession,
                            cachesDirectory: URL,
                            accountContainer: URL,
                            appLockConfig: AppLockController.LegacyConfig?) throws {

        let applicationStatusDirectory = ApplicationStatusDirectory(syncContext: coreDataStack.syncContext, transportSession: transportSession)
        let linkPreviewPreprocessor = LinkPreviewPreprocessor(linkPreviewDetector: applicationStatusDirectory.linkPreviewDetector, managedObjectContext: coreDataStack.syncContext)

        let strategyFactory = StrategyFactory(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            linkPreviewPreprocessor: linkPreviewPreprocessor
        )

        let requestGeneratorStore = RequestGeneratorStore(strategies: strategyFactory.strategies)

        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        let analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: accountContainer)

        try self.init(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            appLockConfig: appLockConfig
        )
    }

    deinit {
        if let token = contextSaveObserverToken {
            NotificationCenter.default.removeObserver(token)
            contextSaveObserverToken = nil
        }
        transportSession.reachability.tearDown()
        transportSession.tearDown()
        strategyFactory.tearDown()
    }

    private func setupCaches(at cachesDirectory: URL) {

        let userImageCache = UserImageLocalCache(location: cachesDirectory)
        userInterfaceContext.zm_userImageCache = userImageCache
        syncContext.zm_userImageCache = userImageCache

        let fileAssetcache = FileAssetCache(location: cachesDirectory)
        userInterfaceContext.zm_fileAssetCache = fileAssetcache
        syncContext.zm_fileAssetCache = fileAssetcache
    }

    private func setupObservers() {
        contextSaveObserverToken = NotificationCenter.default.addObserver(
            forName: contextWasMergedNotification,
            object: nil,
            queue: .main,
            using: { [weak self] note in
                self?.saveNotificationPersistence.add(note)
                DarwinNotification.shareExtDidSaveNote.post()
            }
        )
    }

    public func enqueue(changes: @escaping () -> Void) {
        enqueue(changes: changes, completionHandler: nil)
    }

    public func enqueue(changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        userInterfaceContext.performGroupedBlock { [weak self] in
            changes()
            self?.userInterfaceContext.saveOrRollback()
            completionHandler?()
        }
    }

}

extension SharingSession: LinkPreviewDetectorType {
    public func downloadLinkPreviews(inText text: String, excluding: [NSRange], completion: @escaping ([LinkMetadata]) -> Void) {
        applicationStatusDirectory.linkPreviewDetector.downloadLinkPreviews(inText: text, excluding: excluding, completion: completion)
    }

}

// MARK: - Helper

fileprivate extension ZMConversationList {
    var writeableConversations: [Conversation] {
        return self.filter {
            if let conversation = $0 as? ZMConversation {
                return !conversation.isReadOnly
            }
            return false
        }.compactMap { $0 as? Conversation }
    }

}
