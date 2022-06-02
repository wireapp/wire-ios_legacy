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

struct ModifiedObjects {

    let updated: Set<ZMManagedObject>
    let refreshed: Set<ZMManagedObject>
    let inserted: Set<ZMManagedObject>
    let deleted: Set<ZMManagedObject>

    var updatedAndRefreshed: Set<ZMManagedObject> {
        return updated.union(refreshed)
    }

    var allObjects: Set<ZMManagedObject> {
        return [updated, refreshed, inserted, deleted].reduce(Set()) { $0.union($1) }
    }

    init?(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return nil }

        self.init(
            updated: Self.extractObjects(for: NSUpdatedObjectsKey, from: userInfo),
            refreshed: Self.extractObjects(for: NSRefreshedObjectsKey, from: userInfo),
            inserted: Self.extractObjects(for: NSInsertedObjectsKey, from: userInfo),
            deleted: Self.extractObjects(for: NSDeletedObjectsKey, from: userInfo)
        )
    }

    init(
        updated: Set<ZMManagedObject> = [],
        refreshed: Set<ZMManagedObject> = [],
        inserted: Set<ZMManagedObject> = [],
        deleted: Set<ZMManagedObject> = []
    ) {
        self.updated = updated
        self.refreshed = refreshed
        self.inserted = inserted
        self.deleted = deleted
    }

    private static func extractObjects(for key: String, from userInfo: [String: Any]) -> Set<ZMManagedObject> {
        guard let objects = userInfo[key] else { return Set() }

        switch objects {
        case let managedObjects as Set<ZMManagedObject>:
            return managedObjects

        case let nsObjects as Set<NSObject>:
            NotificationDispatcher.log.warn("Unable to cast userInfo content to Set of ZMManagedObject. Is there a new entity that does not inherit form it?")
            let managedObjects = nsObjects.compactMap { $0 as? ZMManagedObject }
            return Set(managedObjects)

        default:
            assertionFailure("Unable to extract objects in userInfo")
            return Set()
        }
    }
}
