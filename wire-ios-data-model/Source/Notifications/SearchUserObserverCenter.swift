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

private var zmLog = ZMSLog(tag: "SearchUserObserverCenter")

extension NSManagedObjectContext {

    static let SearchUserObserverCenterKey = "SearchUserObserverCenterKey"

    @objc public var searchUserObserverCenter: SearchUserObserverCenter {
        assert(zm_isUserInterfaceContext, "SearchUserObserverCenter does not exist in syncMOC")

        if let observer = self.userInfo[NSManagedObjectContext.SearchUserObserverCenterKey] as? SearchUserObserverCenter {
            return observer
        }

        let newObserver = SearchUserObserverCenter(managedObjectContext: self)
        self.userInfo[NSManagedObjectContext.SearchUserObserverCenterKey] = newObserver
        return newObserver
    }
}

public class SearchUserSnapshot {

    /// Keys that we want to be notified for
    static let observableKeys: [String] = [#keyPath(ZMSearchUser.name),
                                            #keyPath(ZMSearchUser.completeImageData),
                                            #keyPath(ZMSearchUser.previewImageData),
                                            #keyPath(ZMSearchUser.isConnected),
                                            #keyPath(ZMSearchUser.user),
                                            #keyPath(ZMSearchUser.isPendingApprovalByOtherUser)]

    weak var searchUser: ZMSearchUser?
    public private (set) var snapshotValues: [String: NSObject?]

    /// The managed object context used for notifications
    weak var managedObjectContext: NSManagedObjectContext?

    public init(searchUser: ZMSearchUser, managedObjectContext: NSManagedObjectContext) {
        self.searchUser = searchUser
        self.snapshotValues = SearchUserSnapshot.createSnapshots(searchUser: searchUser)
        self.managedObjectContext = managedObjectContext
    }

    /// Creates a snapshot values for the observableKeys keys and stores them
    static func createSnapshots(searchUser: ZMSearchUser) -> [String: NSObject?] {
        return observableKeys.mapToDictionaryWithOptionalValue { searchUser.value(forKey: $0) as? NSObject }
    }

    /// Updates the snapshot values for the observableKeys keys,
    /// returns the changes keys if keys changed or nil when nothing changed
    func updateAndNotify() {
        guard let searchUser = searchUser else { return }
        let newSnapshotValues = SearchUserSnapshot.createSnapshots(searchUser: searchUser)

        var changedKeys = [String]()
        newSnapshotValues.forEach {
            guard let oldValue = snapshotValues[$0.key] else {
                changedKeys.append($0.key)
                return
            }
            if oldValue != $0.value {
                changedKeys.append($0.key)
            }
        }
        snapshotValues = newSnapshotValues
        postNotification(changedKeys: changedKeys)
    }

    /// Post a UserChangeInfo for the specified SearchUser
    func postNotification(changedKeys: [String]) {
        guard changedKeys.count > 0,
            let searchUser = searchUser,
            let moc = self.managedObjectContext
            else { return }

        let userChange = UserChangeInfo(object: searchUser)
        userChange.changedKeys = Set(changedKeys)
        NotificationInContext(name: .SearchUserChange,
                              context: moc.notificationContext,
                              object: searchUser,
                              changeInfo: userChange).post()
    }
}

@objcMembers public class SearchUserObserverCenter: NSObject, ChangeInfoConsumer {

    /// Map of searchUser remoteID to snapshot
    internal var snapshots: [UUID: SearchUserSnapshot] = [:]

    weak var managedObjectContext: NSManagedObjectContext?

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    /// Adds a snapshots for the specified searchUser if not already present
    public func addSearchUser(_ searchUser: ZMSearchUser) {
        guard let remoteID = searchUser.remoteIdentifier,
            let moc = self.managedObjectContext else {
            zmLog.warn("SearchUserObserverCenter: SearchUser does not have a remoteIdentifier? \(searchUser)")
            return
        }
        snapshots[remoteID] = snapshots[remoteID] ?? SearchUserSnapshot(searchUser: searchUser, managedObjectContext: moc)
    }

    /// Removes all snapshots for searchUsers that are not contained in this set
    /// This should be called when the searchDirectory changes
    public func searchDirectoryDidUpdate(newSearchUsers: [ZMSearchUser]) {
        let remoteIDs = newSearchUsers.compactMap {$0.remoteIdentifier}
        let currentRemoteIds = Set(snapshots.keys)
        let toRemove = currentRemoteIds.subtracting(remoteIDs)
        toRemove.forEach {snapshots.removeValue(forKey: $0)}
    }

    /// Removes the snapshots for the specified searchUser
    public func removeSearchUser(_ searchUser: ZMSearchUser) {
        guard let remoteID = searchUser.remoteIdentifier else {
            zmLog.warn("SearchUserObserverCenter: SearchUser does not have a remoteIdentifier? \(searchUser)")
            return
        }
        snapshots.removeValue(forKey: remoteID)
    }

    /// Removes all snapshots
    /// This needs to be called when tearing down the search directory
    public func reset() {
        snapshots = [:]
    }

    public func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]]) {
        guard let userChanges = changes[ZMUser.entityName()] as? [UserChangeInfo] else { return }
        userChanges.forEach {usersDidChange(info: $0)}
    }

    /// Matches the userChangeInfo with the searchUser snapshots and updates those if needed
    func usersDidChange(info: UserChangeInfo) {
        guard snapshots.count > 0 else { return }

        guard info.nameChanged || info.imageMediumDataChanged || info.imageSmallProfileDataChanged || info.connectionStateChanged,
            let user = info.user as? ZMUser,
            let remoteID = user.remoteIdentifier,
            let snapshot = snapshots[remoteID]
        else {
                return
        }

        guard let searchUser = snapshot.searchUser else {
            snapshots.removeValue(forKey: remoteID)
            return
        }

        guard searchUser.user != nil else {
            // When inserting a connection with a remote user, the user is first inserted into the sync context, then merged into the UI context
            // Only then the relationship is set between searchUser and user. Therefore we might receive the userChange notification about the updated connectionState BEFORE the relationship is set.
            // We will wait until we get notified via `notifyUpdatedSearchUser:`
            return
        }
        snapshot.updateAndNotify()
    }

    /// Updates the snapshot of the given searchUser
    public func notifyUpdatedSearchUser(_ searchUser: ZMSearchUser) {
        guard let remoteID = searchUser.remoteIdentifier,
              let snapshot = snapshots[remoteID]
        else { return }

        snapshot.updateAndNotify()
    }

    public func stopObserving() {
        // do nothing
    }

    public func startObserving() {
        // do nothing
    }

}
