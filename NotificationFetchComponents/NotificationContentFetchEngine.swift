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
import WireDataModel
import WireTransport
import WireRequestStrategy


public class NotificationFetchEngine {

    /// The failure reason of a `SharingSession` initialization
    /// - NeedsMigration: The database needs a migration which is only done in the main app
    /// - LoggedOut:      No user is logged in
    enum InitializationError: Error {
        case needsMigration, loggedOut, missingSharedContainer
    }

    /// The `NSManagedObjectContext` used to retrieve the conversations
    let userInterfaceContext: NSManagedObjectContext

    private let syncContext: NSManagedObjectContext

    /// The authentication status used to verify a user is authenticated
    private let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client
    private let clientRegistrationStatus : ClientRegistrationDelegate

    let transportSession: ZMTransportSession

    private var observerToken: NSObjectProtocol?
    private let strategyFactory: StrategyFactory

    public var changeClosure: (() -> Void)?

    /// Whether all prerequsisties are met
    public var authenticated: Bool {
        return authenticationStatus.state == .authenticated && clientRegistrationStatus.clientIsReadyForRequests
    }

    private let operationLoop: RequestGeneratingOperationLoop

    /// Initializes a new `NotificationFetchEngine` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown
    public convenience init(applicationGroupIdentifier: String, hostBundleIdentifier: String) throws {

        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw InitializationError.missingSharedContainer
        }

        let storeURL = sharedContainerURL.appendingPathComponent(hostBundleIdentifier, isDirectory: true).appendingPathComponent("store.wiredatabase")
        let keyStoreURL = sharedContainerURL

        guard !NSManagedObjectContext.needsToPrepareLocalStore(at: storeURL) else { throw InitializationError.needsMigration }


        let userInterfaceContext = NSManagedObjectContext.createUserInterfaceContextWithStore(at: storeURL)!
        let syncContext = NSManagedObjectContext.createSyncContextWithStore(at: storeURL, keyStore: keyStoreURL)!

        userInterfaceContext.zm_sync = syncContext
        syncContext.zm_userInterface = userInterfaceContext

        let environment = ZMBackendEnvironment(userDefaults: UserDefaults.shared())

        let transportSession =  ZMTransportSession(
            baseURL: environment.backendURL,
            websocketURL: environment.backendWSURL,
            mainGroupQueue: userInterfaceContext,
            initialAccessToken: ZMAccessToken(),
            application: nil,
            sharedContainerIdentifier: applicationGroupIdentifier
        )

        try self.init(
            userInterfaceContext: userInterfaceContext,
            syncContext: syncContext,
            transportSession: transportSession,
            sharedContainerURL: sharedContainerURL
        )
    }

    internal init(userInterfaceContext: NSManagedObjectContext,
                  syncContext: NSManagedObjectContext,
                  transportSession: ZMTransportSession,
                  sharedContainerURL: URL,
                  authenticationStatus: AuthenticationStatusProvider,
                  clientRegistrationStatus: ClientRegistrationStatus,
                  operationLoop: RequestGeneratingOperationLoop,
                  strategyFactory: StrategyFactory
                  ) throws {

        self.userInterfaceContext = userInterfaceContext
        self.syncContext = syncContext
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory

        guard authenticationStatus.state == .authenticated else { throw InitializationError.loggedOut }

        setupCaches(atContainerURL: sharedContainerURL)
        setupObservers()
    }

    public convenience init(userInterfaceContext: NSManagedObjectContext, syncContext: NSManagedObjectContext, transportSession: ZMTransportSession, sharedContainerURL: URL) throws {

        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)

        let factory = StrategyFactory(
            syncContext: syncContext,
            registrationStatus: clientRegistrationStatus,
            cancellationProvider: transportSession
        )

        let requestGeneratorStore = RequestGeneratorStore(strategies: factory.strategies)

        let operationLoop = RequestGeneratingOperationLoop(
            userContext: userInterfaceContext,
            syncContext: syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        try self.init(
            userInterfaceContext: userInterfaceContext,
            syncContext: syncContext,
            transportSession: transportSession,
            sharedContainerURL: sharedContainerURL,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: clientRegistrationStatus,
            operationLoop: operationLoop,
            strategyFactory: factory
        )
    }

    deinit {
        transportSession.tearDown()
        strategyFactory.tearDown()
    }

    private func setupCaches(atContainerURL containerURL: URL) {
        let cachesURL = containerURL.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Caches", isDirectory: true)

        let userImageCache = UserImageLocalCache(location: cachesURL)
        userInterfaceContext.zm_userImageCache = userImageCache
        syncContext.zm_userImageCache = userImageCache

        let imageAssetCache = ImageAssetCache(MBLimit: 50, location: cachesURL)
        userInterfaceContext.zm_imageAssetCache = imageAssetCache
        syncContext.zm_imageAssetCache = imageAssetCache

        let fileAssetcache = FileAssetCache(location: cachesURL)
        userInterfaceContext.zm_fileAssetCache = fileAssetcache
        syncContext.zm_fileAssetCache = fileAssetcache
    }

    public func fetch(_ nonce: UUID, conversation: UUID) -> ZMAssetClientMessage? {
        guard let conversation = ZMConversation.fetch(withRemoteIdentifier: conversation, in: userInterfaceContext) else { return nil }
        return ZMAssetClientMessage.fetch(withNonce: nonce, for: conversation, in: userInterfaceContext)
    }

    private func setupObservers() {
        observerToken = NotificationCenterObserverToken(
            name: .NonCoreDataChangeInManagedObject,
            object: nil,
            queue: .main,
            block: { [weak self] note in self?.changeClosure?() }
        )
    }

}
