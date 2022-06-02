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

/// Directory of various conversation lists
/// This object is expected to be used on the UI context only
@objcMembers public class TopConversationsDirectory: NSObject {

    fileprivate let uiMOC: NSManagedObjectContext
    fileprivate let syncMOC: NSManagedObjectContext
    fileprivate static let topConversationSize = 25

    /// Cached top conversations
    /// - warning: Might include deleted or blocked conversations
    fileprivate var topConversationsCache: [ZMConversation] = []

    public init(managedObjectContext: NSManagedObjectContext) {
        uiMOC = managedObjectContext
        syncMOC = managedObjectContext.zm_sync
        super.init()
        self.loadList()
    }
}

// MARK: - Top conversation
private let topConversationsObjectIDKey = "WireTopConversationsObjectIDKey"

@objc extension TopConversationsDirectory {

    public func refreshTopConversations() {
        syncMOC.performGroupedBlock {
            let conversations = self.fetchOneOnOneConversations()

            // Mapping from conversation to message count in the last month
            let countByConversation = conversations.mapToDictionary { $0.lastMonthMessageCount() }
            let sorted = countByConversation.filter { $0.1 > 0 }.sorted {  $0.1 > $1.1 }.prefix(TopConversationsDirectory.topConversationSize)
            let identifiers = sorted.compactMap { $0.0.objectID }
            self.updateUIList(with: identifiers)
        }
    }

    private func updateUIList(with identifiers: [NSManagedObjectID]) {
        uiMOC.performGroupedBlock {
            self.topConversationsCache = identifiers.compactMap {
                (try? self.uiMOC.existingObject(with: $0)) as? ZMConversation
            }
            self.persistList()
        }
    }

    private func fetchOneOnOneConversations() -> [ZMConversation] {
        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicateForActiveOneOnOneConversations)

        return syncMOC.fetchOrAssert(request: request) as! [ZMConversation]
    }

    /// Top conversations
    public var topConversations: [ZMConversation] {
        return self.topConversationsCache.filter { !$0.isZombieObject && $0.connection?.status == .accepted }
    }

    /// Persist list of conversations to persistent store
    private func persistList() {
        let valueToSave = self.topConversations.map { $0.objectID.uriRepresentation().absoluteString }
        self.uiMOC.setPersistentStoreMetadata(array: valueToSave, key: topConversationsObjectIDKey)
        TopConversationsDirectoryNotification().post(in: uiMOC.notificationContext)
    }

    /// Load list from persistent store
    fileprivate func loadList() {
        guard let ids = self.uiMOC.persistentStoreMetadata(forKey: topConversationsObjectIDKey) as? [String] else {
            return
        }
        let managedObjectIDs = ids.compactMap(URL.init).compactMap { self.uiMOC.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: $0) }
        self.topConversationsCache = managedObjectIDs.compactMap { self.uiMOC.object(with: $0) as? ZMConversation }
    }
}

// MARK: – Observation
@objc public protocol TopConversationsDirectoryObserver {

    @objc func topConversationsDidChange()

}

struct TopConversationsDirectoryNotification: SelfPostingNotification {

    static let notificationName = NSNotification.Name(rawValue: "TopConversationsDirectoryNotification")
}

extension TopConversationsDirectory {

    @objc(addObserver:) public func add(observer: TopConversationsDirectoryObserver) -> Any {
        return NotificationInContext.addObserver(name: TopConversationsDirectoryNotification.notificationName, context: uiMOC.notificationContext) { [weak observer] _ in
            observer?.topConversationsDidChange()
        }
    }

}

fileprivate extension ZMConversation {

    static var predicateForActiveOneOnOneConversations: NSPredicate {
        let oneOnOnePredicate = NSPredicate(format: "%K == %d", #keyPath(ZMConversation.conversationType), ZMConversationType.oneOnOne.rawValue)
        let acceptedPredicate = NSPredicate(format: "%K == %d", #keyPath(ZMConversation.connection.status), ZMConnectionStatus.accepted.rawValue)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [oneOnOnePredicate, acceptedPredicate])
    }

    func lastMonthMessageCount() -> Int {
        guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else { return 0 }

        var count = 0
        for message in lastMessages() {
            guard let timestamp = message.serverTimestamp else { continue }
            guard nil == message.systemMessageData else { continue }
            guard timestamp >= oneMonthAgo else { return count }
            count += 1
        }

        return count
    }

}
