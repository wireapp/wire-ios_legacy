//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

protocol InsertedObjectSyncTranscoder: AnyObject {

    associatedtype Object: ZMManagedObject

    /// Called when the `InsertedObjectSync` request an object to be synchronized
    /// due to a key being inserted.
    ///
    /// - Parameters:
    ///   - object: object which has been inserted
    ///   - completion: Completion handler which should be called when object has been created
    ///                 on the backend.
    ///
    func insert(object: Object, completion: @escaping () -> Void)

}

/**
 InsertedObjectSync synchronizes objects which has been inserted locally but does yet exist on the backend.

 This only works for core data entities which inherit from `ZMManagedObject`. The rule for when an object does
 not yet exist on the backend is determined by the `predicateForObjectsThatNeedToBeInsertedUpstream()` or
 by the `insertPredicate` if supplied.
 */
class InsertedObjectSync<Transcoder: InsertedObjectSyncTranscoder>: NSObject, ZMContextChangeTracker {

    let insertPredicate: NSPredicate
    var pending: Set<Transcoder.Object> = Set()

    weak var transcoder: Transcoder?

    /// - Parameters:
    ///   - insertPredicate: Predicate which determine when an object only exists locally. If omitted
    ///                     `predicateForObjectsThatNeedToBeInsertedUpstream()` will be used.
    init(insertPredicate: NSPredicate? = nil) {
        self.insertPredicate = insertPredicate ?? Transcoder.Object.predicateForObjectsThatNeedToBeInsertedUpstream()!
    }

    func objectsDidChange(_ objects: Set<NSManagedObject>) {
        var trackedObjects = objects.compactMap({ $0 as? Transcoder.Object})
        let indexOfSecondPartition = trackedObjects.partition(by: insertPredicate.evaluate)
        let insertedObjects = trackedObjects[indexOfSecondPartition...]
        let removedObjects = trackedObjects[..<indexOfSecondPartition]
        addInsertedObjects(Array(insertedObjects))
        removeNoLongerMatchingObjects(Array(removedObjects))
    }

    func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return Transcoder.Object.sortedFetchRequest(with: insertPredicate)
    }

    func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        let insertedObjects = objects.compactMap({ $0 as? Transcoder.Object})

        addInsertedObjects(insertedObjects)
    }

    func addInsertedObjects(_ objects: [Transcoder.Object]) {
        for insertedObject in objects {
            guard !pending.contains(insertedObject) else { continue }

            pending.insert(insertedObject)
            transcoder?.insert(object: insertedObject, completion: {
                self.pending.remove(insertedObject)
            })
        }
    }

    func removeNoLongerMatchingObjects(_ objects: [Transcoder.Object]) {
        pending.subtract(objects)
    }
}
