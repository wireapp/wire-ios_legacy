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
import CoreData

/// The `NotificationDispatcher` listens for changes to observable entities (e.g message, users, and conversations),
/// extracts information about those changes (e.g which properties changed), and posts notifications about those
/// changes.
///
/// Changes are only observed on the main UI managed object context and are triggered by automatically by
/// Core Data notifications or manually for non Core Data changes.

@objcMembers public class NotificationDispatcher: NSObject, TearDownCapable {

    static var log = ZMSLog(tag: "notifications")

    // MARK: - Public properties

    /// Whether the dispatcher is enabled.
    ///
    /// If set to `false`, all pending changes are discarded and no new notifications are posted.

    public var isEnabled = true {
        didSet {
            guard oldValue != isEnabled else { return }
            isEnabled ? startObserving() : stopObserving()
        }
    }

    /// Determines how detailed and frequent change notifications are fired.

    public var operationMode: OperationMode {
        didSet {
            guard operationMode != oldValue else { return }

            if operationMode == .economical {
                conversationListObserverCenter.stopObserving()
            }

            if oldValue == .economical {
                fireAllNotifications()
                conversationListObserverCenter.startObserving()
            }

            changeDetector = changeDetectorBuilder(operationMode)
        }
    }

    // MARK: - Private properties

    private unowned var managedObjectContext: NSManagedObjectContext

    private var notificationCenterTokens = [Any]()

    private var isTornDown = false

    private var changeInfoConsumers = [UnownedNSObject]()

    private var allChangeInfoConsumers: [ChangeInfoConsumer] {
        var consumers = changeInfoConsumers.compactMap {$0.unbox as? ChangeInfoConsumer}
        consumers.append(searchUserObserverCenter)
        consumers.append(conversationListObserverCenter)
        return consumers
    }

    private var conversationListObserverCenter: ConversationListObserverCenter {
        return managedObjectContext.conversationListObserverCenter
    }

    private var searchUserObserverCenter: SearchUserObserverCenter {
        return managedObjectContext.searchUserObserverCenter
    }

    private var changeDetector: ChangeDetector

    private let changeDetectorBuilder: (OperationMode) -> ChangeDetector

    private var unreadMessages = UnreadMessages()

    // MARK: - Life cycle

    public init(managedObjectContext: NSManagedObjectContext) {
        assert(
            managedObjectContext.zm_isUserInterfaceContext,
            "NotificationDispatcher needs to be initialized with uiMOC"
        )

        self.managedObjectContext = managedObjectContext

        changeDetectorBuilder = { operationMode in
            switch operationMode {
            case .normal:
                let classIdentifiers = [
                    ZMConversation.classIdentifier,
                    ZMUser.classIdentifier,
                    ZMConnection.classIdentifier,
                    UserClient.classIdentifier,
                    ZMMessage.classIdentifier,
                    ZMClientMessage.classIdentifier,
                    ZMAssetClientMessage.classIdentifier,
                    ZMSystemMessage.classIdentifier,
                    Reaction.classIdentifier,
                    ZMGenericMessageData.classIdentifier,
                    Team.classIdentifier,
                    Member.classIdentifier,
                    Label.classIdentifier,
                    ParticipantRole.classIdentifier
                ]

                return ExplicitChangeDetector(
                    classIdentifiers: classIdentifiers,
                    managedObjectContext: managedObjectContext
                )

            case .economical:
                return PotentialChangeDetector()
            }
        }

        operationMode = .normal
        changeDetector = changeDetectorBuilder(operationMode)

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotificationDispatcher.objectsDidChange),
            name: .NSManagedObjectContextObjectsDidChange,
            object: managedObjectContext
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotificationDispatcher.contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: managedObjectContext
        )

        let token = NotificationInContext.addObserver(
            name: .NonCoreDataChangeInManagedObject,
            context: managedObjectContext.notificationContext,
            using: { [weak self] note in self?.nonCoreDataChange(note) }
        )

        notificationCenterTokens.append(token)
    }

    public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        notificationCenterTokens.forEach(NotificationCenter.default.removeObserver)
        notificationCenterTokens = []
        conversationListObserverCenter.tearDown()
        isTornDown = true
    }

    deinit {
        assert(isTornDown)
    }

    // MARK: - Callbacks

    /// Call this when the application enters the background to stop sending notifications and clear current changes.

    func applicationDidEnterBackground() {
        isEnabled = false
    }

    /// Call this when the application will enter the foreground to start sending notifications again.

    func applicationWillEnterForeground() {
        isEnabled = true
    }

    // Called when objects in the context change, it may be called several times between saves.

    func objectsDidChange(_ note: Notification) {
        guard isEnabled else { return }
        process(note: note)
    }

    func contextDidSave(_ note: Notification) {
        guard isEnabled else { return }
        fireAllNotificationsIfAllowed()
    }

    /// This will be called if a change to an object does not cause a change in Core Data,
    /// e.g. downloading the asset and adding it to the cache.

    func nonCoreDataChange(_ note: NotificationInContext) {
        guard
            isEnabled,
            let changedKeys = note.changedKeys,
            let object = note.object as? ZMManagedObject
        else {
            return
        }

        changeDetector.add(changes: Changes(changedKeys: Set(changedKeys)), for: object)

        guard shouldFireNotifications else { return }

        if managedObjectContext.zm_hasChanges {
            // Fire notifications via a save.
            managedObjectContext.enqueueDelayedSave()
        } else {
            fireAllNotifications()
        }
    }

    // MARK: - Methods

    /// Add the given consumer to receive forwarded `ChangeInfo`s.

    public func addChangeInfoConsumer(_ consumer: ChangeInfoConsumer) {
        let boxed = UnownedNSObject(consumer as! NSObject)
        changeInfoConsumers.append(boxed)
    }

    /// Call this AFTER merging the changes from syncMOC into uiMOC.

    public func didMergeChanges(_ changedObjectIDs: Set<NSManagedObjectID>) {
        guard isEnabled else { return }

        let changedObjects = changedObjectIDs.compactMap {
            try? managedObjectContext.existingObject(with: $0) as? ZMManagedObject
        }

        changeDetector.detectChanges(for: ModifiedObjects(updated: Set(changedObjects)))

        fireAllNotificationsIfAllowed()
    }

    /// This can safely be called from any thread as it will switch to uiContext internally.

    public static func notifyNonCoreDataChanges(objectID: NSManagedObjectID, changedKeys: [String], uiContext: NSManagedObjectContext) {
        uiContext.performGroupedBlock {
            guard let uiMessage = try? uiContext.existingObject(with: objectID) else { return }

            NotificationInContext(
                name: .NonCoreDataChangeInManagedObject,
                context: uiContext.notificationContext,
                object: uiMessage,
                changedKeys: changedKeys
            ).post()
        }
    }

    private func stopObserving() {
        changeDetector.reset()
        unreadMessages = UnreadMessages()
        allChangeInfoConsumers.forEach { $0.stopObserving() }
    }

    private func startObserving() {
        allChangeInfoConsumers.forEach { $0.startObserving() }
    }

    private func process(note: Notification) {
        guard let objects = ModifiedObjects(notification: note) else { return }
        forwardChangesToConversationListObserver(modifiedObjects: objects)
        checkForUnreadMessages(insertedObjects: objects.inserted, updatedObjects: objects.updated)
        changeDetector.detectChanges(for: objects)
    }

    private func forwardChangesToConversationListObserver(modifiedObjects: ModifiedObjects) {
        let insertedLabels = modifiedObjects.inserted.compactMap { $0 as? Label }
        let deletedLabels = modifiedObjects.deleted.compactMap { $0 as? Label }
        conversationListObserverCenter.folderChanges(inserted: insertedLabels, deleted: deletedLabels)

        let insertedConversations = modifiedObjects.inserted.compactMap { $0 as? ZMConversation }
        let deletedConversations = modifiedObjects.deleted.compactMap { $0 as? ZMConversation }
        conversationListObserverCenter.conversationsChanges(inserted: insertedConversations, deleted: deletedConversations)
    }

    private func checkForUnreadMessages(insertedObjects: Set<ZMManagedObject>, updatedObjects: Set<ZMManagedObject>) {
        let unreadUnsent = updatedObjects.lazy
            .compactMap { $0 as? ZMMessage }
            .filter { $0.deliveryState == .failedToSend }
            .collect()

        let newUnreads = insertedObjects.lazy
            .compactMap { $0 as? ZMMessage }
            .filter { $0.isUnreadMessage }

        let newUnreadMessages = newUnreads
            .filter { $0.knockMessageData == nil }
            .collect()

        let newUnreadKnocks = newUnreads
            .filter { $0.knockMessageData != nil }
            .collect()

        unreadMessages.unsent.formUnion(unreadUnsent)
        unreadMessages.messages.formUnion(newUnreadMessages)
        unreadMessages.knocks.formUnion(newUnreadKnocks)
    }

    private func fireAllNotificationsIfAllowed() {
        guard shouldFireNotifications else { return }
        fireAllNotifications()
    }

    private var shouldFireNotifications: Bool {
        return operationMode != .economical
    }

    private func fireAllNotifications() {
        let detectedChanges = changeDetector.consumeChanges()
        var changesByClass = [ClassIdentifier: [ObjectChangeInfo]]()
        let unreadMessages = self.unreadMessages
        self.unreadMessages = UnreadMessages()

        detectedChanges.forEach { changeInfo in
            guard let objectInSnapshot = changeInfo.object as? ObjectInSnapshot else { return }

            postNotification(
                name: objectInSnapshot.notificationName,
                object: changeInfo.object,
                changeInfo: changeInfo
            )

            guard let managedObject = changeInfo.object as? ZMManagedObject else { return }

            let classIdentifier = managedObject.classIdentifier
            var previousChanges = changesByClass[classIdentifier] ?? []
            previousChanges.append(changeInfo)
            changesByClass[classIdentifier] = previousChanges
        }

        forwardNotificationToObserverCenters(changeInfos: changesByClass)
        fireNewUnreadMessagesNotifications(unreadMessages: unreadMessages)
    }

    private func fireNewUnreadMessagesNotifications(unreadMessages: UnreadMessages) {
        unreadMessages.changeInfoByNotification.forEach {
            postNotification(name: $0, changeInfo: $1)
        }
    }

    private func forwardNotificationToObserverCenters(changeInfos: [ClassIdentifier: [ObjectChangeInfo]]) {
        allChangeInfoConsumers.forEach {
            $0.objectsDidChange(changes: changeInfos)
        }
    }

    private func postNotification(
        name: Notification.Name,
        object: AnyObject? = nil,
        changeInfo: ObjectChangeInfo
    ) {
        NotificationInContext(
            name: name,
            context: managedObjectContext.notificationContext,
            object: object,
            changeInfo: changeInfo
        ).post()
    }

}

// MARK: - Helper extensions

private extension LazySequenceProtocol {

    func collect() -> [Element] {
        return Array(self)
    }

}
