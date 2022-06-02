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
import WireRequestStrategy

public protocol NotificationSessionDelegate: AnyObject {

    func notificationSessionDidGenerateNotification(_ notification: ZMLocalNotification?, unreadConversationCount: Int)
    func reportCallEvent(_ event: ZMUpdateEvent, currentTimestamp: TimeInterval)

}

/// A syncing layer for the notification processing
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the notification extension, and hold on to that session
/// for the entire lifetime.
///
public class NotificationSession {

    /// The failure reason of a `NotificationSession` initialization
    /// - noAccount: Account doesn't exist

    public enum InitializationError: Error {
        case noAccount
    }

    // MARK: - Properties

    /// Directory of all application statuses.

    private let applicationStatusDirectory : ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persisted.

    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    private var contextSaveObserverToken: NSObjectProtocol?
    private let transportSession: ZMTransportSession
    private let coreDataStack: CoreDataStack
    private let operationLoop: RequestGeneratingOperationLoop

    public let accountIdentifier: UUID

    private var callEvent: ZMUpdateEvent?
    private var localNotifications = [ZMLocalNotification]()

    private var context: NSManagedObjectContext {
        return coreDataStack.syncContext
    }

    public weak var delegate: NotificationSessionDelegate?

    // MARK: - Life cycle
        
    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.noAccount` in case the account does not exist
    /// - returns: The initialized session object if no error is thrown
    
    public convenience init(
        applicationGroupIdentifier: String,
        accountIdentifier: UUID,
        environment: BackendEnvironmentProvider,
        analytics: AnalyticsType?
    ) throws {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let accountManager = AccountManager(sharedDirectory: sharedContainerURL)

        guard let account = accountManager.account(with: accountIdentifier) else {
            throw InitializationError.noAccount
        }

        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL
        )

        coreDataStack.loadStores { error in
            // TODO jacob error handling
        }

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
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL),
            analytics: analytics,
            accountIdentifier: accountIdentifier
        )
    }

    convenience init(
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        accountContainer: URL,
        analytics: AnalyticsType?,
        accountIdentifier: UUID
    ) throws {
        let applicationStatusDirectory = ApplicationStatusDirectory(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession
        )

        let notificationsTracker = (analytics != nil) ? NotificationsTracker(analytics: analytics!) : nil

        let pushNotificationStrategy = PushNotificationStrategy(
            withManagedObjectContext: coreDataStack.syncContext,
            eventContext: coreDataStack.eventContext,
            applicationStatus: applicationStatusDirectory,
            pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
            notificationsTracker: notificationsTracker
        )

        let requestGeneratorStore = RequestGeneratorStore(strategies: [pushNotificationStrategy])
        
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        
        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        
        try self.init(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            accountIdentifier: accountIdentifier,
            pushNotificationStrategy: pushNotificationStrategy
        )
    }

    init(
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        saveNotificationPersistence: ContextDidSaveNotificationPersistence,
        applicationStatusDirectory: ApplicationStatusDirectory,
        operationLoop: RequestGeneratingOperationLoop,
        accountIdentifier: UUID,
        pushNotificationStrategy: PushNotificationStrategy
    ) throws {
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.accountIdentifier = accountIdentifier
        pushNotificationStrategy.delegate = self
    }

    deinit {
        if let token = contextSaveObserverToken {
            NotificationCenter.default.removeObserver(token)
            contextSaveObserverToken = nil
        }

        transportSession.reachability.tearDown()
        transportSession.tearDown()
    }

    // MARK: - Methods
    
    public func processPushNotification(with payload: [AnyHashable: Any], completion: @escaping (Bool) -> Void) {
        Logging.network.debug("Received push notification with payload: \(payload)")

        coreDataStack.syncContext.performGroupedBlock {
            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
                Logging.push.safePublic("Not displaying notification because app is not authenticated")
                completion(false)
                return
            }
            
            let completionHandler = {
                completion(true)
            }
            
            self.fetchEvents(fromPushChannelPayload: payload, completionHandler: completionHandler)
        }
    }
    
    func fetchEvents(fromPushChannelPayload payload: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        guard let nonce = self.messageNonce(fromPushChannelData: payload) else {
            completionHandler()
            return
        }

        applicationStatusDirectory.pushNotificationStatus.fetch(eventId: nonce, completionHandler: completionHandler)
    }

    private func messageNonce(fromPushChannelData payload: [AnyHashable: Any]) -> UUID? {
        guard
            let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
            let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
            let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String
        else {
            return nil
        }

        return UUID(uuidString: rawUUID)
    }
    
    private enum PushChannelKeys: String {
        case data = "data"
        case identifier = "id"
    }
}

extension NotificationSession: PushNotificationStrategyDelegate {

    func pushNotificationStrategy(_ strategy: PushNotificationStrategy, didFetchEvents events: [ZMUpdateEvent]) {
        for event in events {
            if shouldHandleCallEvent(event) {
                // Only store the last call event.
                callEvent =  event
            } else if let notification = notification(from: event, in: context) {
                localNotifications.append(notification)
            }
        }
    }

    private func shouldHandleCallEvent(_ event: ZMUpdateEvent) -> Bool {
        // The API to report VoIP pushes from the notification service extension
        // is only available from iOS 14.5.
        guard #available(iOSApplicationExtension 14.5, *) else {
            return false
        }

        // Ensure this actually is a call event.
        guard let callContent = CallEventContent(from: event) else {
            return false
        }

        // The sender is needed to report who the call is from.
        guard isValidSender(in: event) else {
            return false
        }

        // The conversation is needed to report where the call is taking place.
        guard let conversation = conversation(in: event) else {
                  return false
              }

        // The call event can be processed if the conversation is not muted
        if conversation.mutedMessageTypesIncludingAvailability != .none {
            return false
        }

        // AVS is ready to process call events.
        guard VoIPPushHelper.isAVSReady else {
            return false
        }

        // CallKit may not be available due to lack of permissions or because it
        // is disabled by the user.
        guard VoIPPushHelper.isCallKitAvailable else {
            return false
        }

        // The user session is needed to process the call event.
        guard VoIPPushHelper.isUserSessionLoaded(accountID: accountIdentifier) else {
            return false
        }

        guard let conversationID = conversation.remoteIdentifier else {
            return false
        }

        let callExistsForConversation = VoIPPushHelper.existsOngoingCallInConversation(
            withID: conversationID
        )

        // We can't report an incoming call if it already exists.
        if case .incomingCall = callContent.callState, callExistsForConversation {
            return false
        }

        // We can't terminate a call if it doesn't exist.
        if case .missedCall = callContent.callState, !callExistsForConversation {
            return false
        }

        return true
    }

    private func isValidSender(in event: ZMUpdateEvent) -> Bool {
        guard let id = event.senderUUID else { return false }
        return ZMUser.fetch(with: id, domain: event.senderDomain, in: context) != nil
    }

    private func conversation(in event: ZMUpdateEvent) -> ZMConversation? {
        guard
            let id = event.conversationUUID,
            let conversation = ZMConversation.fetch(with: id, domain: event.conversationDomain, in: context),
            !conversation.needsToBeUpdatedFromBackend
        else {
            return nil
        }

        return conversation
    }

    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy) {
        processCallEvent()
        processLocalNotifications()
    }

    private func processCallEvent() {
        if let callEvent = callEvent {
            delegate?.reportCallEvent(callEvent, currentTimestamp: context.serverTimeDelta)
            self.callEvent = nil
        }
    }

    private func processLocalNotifications() {
        let notification: ZMLocalNotification?

        if localNotifications.count > 1 {
            notification = ZMLocalNotification.bundledMessages(count: localNotifications.count, in: context)
        } else {
            notification = localNotifications.first
        }

        let unreadCount = Int(ZMConversation.unreadConversationCount(in: context))
        delegate?.notificationSessionDidGenerateNotification(notification, unreadConversationCount: unreadCount)
        localNotifications.removeAll()
    }

}

// MARK: - Converting events to localNotifications

extension NotificationSession {

    private func notification(from event: ZMUpdateEvent, in context: NSManagedObjectContext) -> ZMLocalNotification? {
        var note: ZMLocalNotification?

        guard let conversationID = event.conversationUUID else {
            return nil
        }

        let conversation = ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: context)

        if let callEventContent = CallEventContent(from: event) {
            let currentTimestamp = Date().addingTimeInterval(context.serverTimeDelta)

            /// The caller should not be the same as the user receiving the call event and
            /// the age of the event is less than 30 seconds
            guard
                let callState = callEventContent.callState,
                let callerID = callEventContent.callerID,
                let caller = ZMUser.fetch(with: callerID, domain: event.senderDomain, in: context),
                caller != ZMUser.selfUser(in: context),
                !isEventTimedOut(currentTimestamp: currentTimestamp, eventTimestamp: event.timestamp)
            else {
                return nil
            }

            note = ZMLocalNotification.init(callState: callState, conversation: conversation, caller: caller, moc: context)

        } else {
            note = ZMLocalNotification.init(event: event, conversation: conversation, managedObjectContext: context)
        }

        note?.increaseEstimatedUnreadCount(on: conversation)
        return note
    }

    private func isEventTimedOut(currentTimestamp: Date, eventTimestamp: Date?) -> Bool {
        guard let eventTimestamp = eventTimestamp else {
            return true
        }

        return Int(currentTimestamp.timeIntervalSince(eventTimestamp)) > 30
    }

}

// MARK: - Helpers

private extension CallEventContent {

    init?(from event: ZMUpdateEvent) {
        guard
            event.type == .conversationOtrMessageAdd,
            let message = GenericMessage(from: event),
            message.hasCalling,
            let payload = message.calling.content.data(using: .utf8, allowLossyConversion: false)
        else {
            return nil
        }

        self.init(from: payload)
    }

}
