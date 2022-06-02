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

private var zmLog = ZMSLog(tag: "ConversationListObserverCenter")

extension Notification.Name {
    static let conversationListsDidReload = Notification.Name("conversationListsDidReloadNotification")
    static let conversationListDidChange = Notification.Name("conversationListDidChangeNotification")
    static let conversationListDidChangeFolders = Notification.Name("conversationListDidChangeFoldersNotification")
}

extension NSManagedObjectContext {

    static let ConversationListObserverCenterKey = "ConversationListObserverCenterKey"

    @objc public var conversationListObserverCenter: ConversationListObserverCenter {
        // FIXME: Uncomment and fix crash when running tests
        // assert(zm_isUserInterfaceContext, "ConversationListObserver does not exist in syncMOC")

        if let observer = self.userInfo[NSManagedObjectContext.ConversationListObserverCenterKey] as? ConversationListObserverCenter {
            return observer
        }

        let newObserver = ConversationListObserverCenter(managedObjectContext: self)
        self.userInfo[NSManagedObjectContext.ConversationListObserverCenterKey] = newObserver
        return newObserver
    }
}

public class ConversationListObserverCenter: NSObject, ZMConversationObserver, ChangeInfoConsumer {

    fileprivate var listSnapshots: [String: ConversationListSnapshot] = [:]

    var isTornDown: Bool = false
    var insertedConversations = [ZMConversation]()
    var deletedConversations = [ZMConversation]()
    var insertedLabels = [Label]()
    var deletedLabels = [Label]()

    weak var managedObjectContext: NSManagedObjectContext!

    fileprivate init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    /// Adds a conversationList to the objects to observe or replace any existing snapshot
    @objc public func startObservingList(_ conversationList: ZMConversationList) {
        if listSnapshots[conversationList.identifier] == nil {
            zmLog.debug("Adding conversationList with identifier \(conversationList.identifier)")
        } else {
            zmLog.debug("Recreating snapshot for conversationList with identifier \(conversationList.identifier)")
            zmLog.ifDebug {
                (conversationList as Array).forEach {
                    zmLog.debug("Conversation in \(conversationList.identifier) includes: \(String(describing: $0.objectID)) with type: \($0.conversationType.rawValue)")
                }
            }
        }
        listSnapshots[conversationList.identifier] = ConversationListSnapshot(conversationList: conversationList, managedObjectContext: self.managedObjectContext)
    }

    /// Removes the conversationList from the objects to observe
    @objc public func removeConversationList(_ conversationList: ZMConversationList) {
        zmLog.debug("Removing conversationList with identifier \(conversationList.identifier)")
        listSnapshots.removeValue(forKey: conversationList.identifier)
    }

    // MARK: Forwarding updates
    public func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]]) {

        let insertedLabels = self.insertedLabels
        let deletedLabels = self.deletedLabels
        self.insertedLabels = []
        self.deletedLabels = []

        managedObjectContext.conversationListDirectory().insertFolders(insertedLabels.filter({ $0.kind == .folder }))
        managedObjectContext.conversationListDirectory().deleteFolders(deletedLabels.filter({ $0.kind == .folder }))

        if !insertedLabels.isEmpty || !deletedLabels.isEmpty {
            NotificationInContext.init(name: .conversationListDidChangeFolders, context: managedObjectContext.notificationContext).post()
        }

        if let convChanges = changes[ZMConversation.classIdentifier] as? [ConversationChangeInfo] {
            convChanges.forEach {conversationDidChange($0)}
        } else if let messageChanges = changes[ZMClientMessage.classIdentifier] as? [MessageChangeInfo] {
            messageChanges.forEach {messagesDidChange($0)}
        } else if let labelChanges = changes[Label.classIdentifier] as? [LabelChangeInfo] {
            labelChanges.forEach {labelDidChange($0)}
        }

        let insertedConversations = self.insertedConversations
        let deletedConversations = self.deletedConversations
        self.insertedConversations = []
        self.deletedConversations = []

        forwardToSnapshots {
            $0.conversationsChanges(inserted: insertedConversations, deleted: deletedConversations)
            $0.recalculateListAndNotify()
        }
    }

    private func labelDidChange(_ changes: LabelChangeInfo) {
        guard let label = changes.label as? Label else { return }

        if changes.markedForDeletion, label.kind == .folder, label.markedForDeletion {
            managedObjectContext.conversationListDirectory().deleteFolders([label])
        }

        if changes.conversationsChanged {
            for conversation in label.conversations {
                let changeInfo = ConversationChangeInfo(object: conversation)
                changeInfo.changedKeys.insert(#keyPath(ZMConversation.labels))
                conversationDidChange(changeInfo)
            }
        }
    }

    /// Handles updated messages that could be visible in the conversation list
    private func messagesDidChange(_ changes: MessageChangeInfo) {
        guard let conversation = changes.message.conversation, changes.underlyingMessageChanged else { return }

        let changeInfo = ConversationChangeInfo(object: conversation)
        changeInfo.changedKeys.insert(#keyPath(ZMConversation.allMessages))
        conversationDidChange(changeInfo)
    }

    /// Handles updated conversations, updates lists and notifies observers
    public func conversationDidChange(_ changes: ConversationChangeInfo) {
        guard    changes.nameChanged              || changes.connectionStateChanged  || changes.isArchivedChanged
              || changes.mutedMessageTypesChanged || changes.lastModifiedDateChanged || changes.conversationListIndicatorChanged
              || changes.clearedChanged           || changes.securityLevelChanged    || changes.teamChanged
              || changes.messagesChanged          || changes.labelsChanged
        else { return }
        zmLog.debug("conversationDidChange with changes \(changes.customDebugDescription)")
        forwardToSnapshots {$0.processConversationChanges(changes)}
    }

    /// Stores inserted or deleted folders temporarily until save / merge completes
    func folderChanges(inserted: [Label], deleted: [Label]) {
        guard !inserted.isEmpty || !deleted.isEmpty else { return }

        zmLog.debug("\(inserted.count) folder(s) inserted - \(deleted.count) folder(s) deleted")

        insertedLabels.append(contentsOf: inserted)
        deletedLabels.append(contentsOf: deleted)
    }

    /// Stores inserted or deleted conversations temporarily until save / merge completes
    func conversationsChanges(inserted: [ZMConversation], deleted: [ZMConversation]) {
        if deleted.count == 0 && inserted.count == 0 { return }
        zmLog.debug("\(inserted.count) conversation inserted - \(deleted.count) conversation deleted")
        inserted.forEach {
            zmLog.debug("Inserted: \($0.objectID) conversationType: \($0.conversationType.rawValue)")
        }
        deleted.forEach {
            zmLog.debug("Deleted: \($0.objectID) conversationType: \($0.conversationType.rawValue)")
        }
        insertedConversations.append(contentsOf: inserted)
        deletedConversations.append(contentsOf: deleted)
    }

    /// Applys a function on a token and cleares tokens with deallocated lists
    private func forwardToSnapshots(block: ((ConversationListSnapshot) -> Void)) {
        var snapshotsToRemove = [String]()
        listSnapshots.forEach { (identifier, snapshot) in
            guard snapshot.conversationList != nil else {
                snapshotsToRemove.append(identifier)
                return
            }
            block(snapshot)
        }

        // clean up snapshotlist
        snapshotsToRemove.forEach {listSnapshots.removeValue(forKey: $0)}
    }

    public func stopObserving() {
        // We should always re-create the snapshots when re-entering the foreground
        // Therefore it would be safe to clear the snapshots here
        listSnapshots = [:]
        zmLog.debug("\(#function), clearing listSnapshots")
    }

    public func startObserving() {
        // list snapshots are automatically re-created when the lists are re-created and `recreateSnapshot(for conversation:)` is called
        zmLog.debug(#function)

        managedObjectContext.conversationListDirectory().refetchAllLists(in: managedObjectContext)

        NotificationInContext.init(name: .conversationListsDidReload, context: managedObjectContext.notificationContext).post()
    }
}

extension ConversationListObserverCenter: TearDownCapable {
    public func tearDown() {
        if isTornDown { return }
        isTornDown = true
        listSnapshots = [:]
    }
}

class ConversationListSnapshot: NSObject {

    fileprivate var state: SetSnapshot<ZMConversation>
    weak var conversationList: ZMConversationList?
    fileprivate var tornDown = false
    var conversationChanges = [ConversationChangeInfo]()
    var needsToRecalculate = false

    private var managedObjectContext: NSManagedObjectContext

    init(conversationList: ZMConversationList, managedObjectContext: NSManagedObjectContext) {
        self.conversationList = conversationList
        self.state = SetSnapshot(set: conversationList.toOrderedSetState(), moveType: .uiCollectionView)
        self.managedObjectContext = managedObjectContext
        super.init()
    }

    /// Processes conversationChanges and removes or insert conversations and notifies observers
    fileprivate func processConversationChanges(_ changes: ConversationChangeInfo) {
        guard let list = conversationList else { return }

        let conversation = changes.conversation
        if list.contains(conversation) {
            // list contains conversation and needs to be updated
            if !updateDidRemoveConversation(list: list, changes: changes) {
                conversationChanges.append(changes)
            }
            needsToRecalculate = true
        }
        else if list.predicateMatchesConversation(conversation) {
            // list did not contain conversation and now it should
            zmLog.debug("Inserted conversation: \(changes.conversation.objectID) with type: \(changes.conversation.conversationType.rawValue) into list \(list.identifier)")
            list.insertConversations(Set(arrayLiteral: conversation))
            needsToRecalculate = true
        }

        zmLog.debug("Snapshot for list \(list.identifier) processed change, needsToRecalculate: \(needsToRecalculate)")
    }

    private func updateDidRemoveConversation(list: ZMConversationList, changes: ConversationChangeInfo) -> Bool {
        if !list.predicateMatchesConversation(changes.conversation) {
            list.removeConversations(Set(arrayLiteral: changes.conversation))
            zmLog.debug("Removed conversation: \(changes.conversation.objectID) with type: \(changes.conversation.conversationType.rawValue) from list \(list.identifier)")
            return true
        }
        if list.sortingIsAffected(byConversationKeys: changes.changedKeys) {
            list.resortConversation(changes.conversation)
            zmLog.debug("Resorted conversation \(changes.conversation.objectID) with type: \(changes.conversation.conversationType.rawValue) in list \(list.identifier)")
        }
        return false
    }

    /// Handles inserted and removed conversations and updates lists
    func conversationsChanges(inserted: [ZMConversation], deleted: [ZMConversation]) {
        guard let list = conversationList else { return }

        let conversationsToInsert = Set(inserted.filter { list.predicateMatchesConversation($0)})
        let conversationsToRemove = Set(deleted.filter { list.contains($0)})
        zmLog.debug("List \(list.identifier) is inserting \(conversationsToInsert.count) and deletes \(conversationsToRemove.count) conversations")

        list.insertConversations(conversationsToInsert)
        list.removeConversations(conversationsToRemove)

        if !conversationsToInsert.isEmpty || !conversationsToRemove.isEmpty {
            needsToRecalculate = true
        }
        zmLog.debug("Snapshot for  list \(list.identifier) processed inserts and deletes, needsToRecalculate: \(needsToRecalculate)")
    }

    func recalculateListAndNotify() {
        guard let list = self.conversationList, needsToRecalculate || conversationChanges.count > 0 else {
            zmLog.debug("List \(String(describing: self.conversationList?.identifier)) has no changes")
            return
        }

        var listChange: ConversationListChangeInfo?
        defer {
            notifyObservers(conversationChanges: conversationChanges, listChanges: listChange)
            conversationChanges = []
            needsToRecalculate = false
        }

        let changedSet = Set(conversationChanges.compactMap {$0.conversation})
        guard let newStateUpdate = self.state.updatedState(changedSet, observedObject: list, newSet: list.toOrderedSetState())
        else {
            zmLog.debug("Recalculated list \(list.identifier), but old state is same as new state")
            return
        }

        zmLog.debug("Recalculated  list \(list.identifier) and updated snapshot")
        self.state = newStateUpdate.newSnapshot
        listChange = ConversationListChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
    }

    private func notifyObservers(conversationChanges: [ConversationChangeInfo],
                                 listChanges: ConversationListChangeInfo?) {
        guard listChanges != nil || conversationChanges.count != 0 else { return }

        var userInfo = [String: Any]()
        if conversationChanges.count > 0 {
            userInfo["conversationChangeInfos"] = conversationChanges
        }
        if let changes = listChanges {
            userInfo["conversationListChangeInfo"] = changes
        }
        guard !userInfo.isEmpty else {
            zmLog.debug("No changes for conversationList \(String(describing: self.conversationList))")
            return
        }

        let notification = NotificationInContext(name: .conversationListDidChange,
                                                 context: managedObjectContext.notificationContext,
                                                 object: conversationList,
                                                 userInfo: userInfo)

        zmLog.debug(logMessage(for: conversationChanges, listChanges: listChanges))
        notification.post()
    }

    func logMessage(for conversationChanges: [ConversationChangeInfo], listChanges: ConversationListChangeInfo?) -> String {
        var message = "Posting notification for list \(String(describing: conversationList?.identifier)) with conversationChanges: \n"
        message.append(conversationChanges.map {$0.customDebugDescription}.joined(separator: "\n"))

        guard let changeInfo = listChanges else { return message }
        message.append("\n ConversationListChangeInfo: \(changeInfo.description)")
        return message
    }

}
