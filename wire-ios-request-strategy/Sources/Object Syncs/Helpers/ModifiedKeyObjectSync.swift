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

protocol ModifiedKeyObjectSyncTranscoder: AnyObject {

    associatedtype Object: ZMManagedObject

    /// Called when the `ModifiedKeyObjectSync` request an object to be synchronized
    /// due to a key being modified.
    ///
    /// - Parameters:
    ///   - keys: key which has been modified
    ///   - object: object which has been modified
    ///   - completion: Completion handler which should be called when the modified
    ///                 object has been synchronzied with the backend.
    func synchronize(key: String, for object: Object, completion: @escaping () -> Void)
}

/**
 ModifiedKeyObjectSync synchronizes an object when a given property has been modified on
 the object.

 This only works for core data entities which inherit from `ZMManagedObject`.
 */
class ModifiedKeyObjectSync<Transcoder: ModifiedKeyObjectSyncTranscoder>: NSObject, ZMContextChangeTracker {

    let trackedKey: String
    let modifiedPredicate: NSPredicate?
    var pending: Set<Transcoder.Object> = Set()

    weak var transcoder: Transcoder?

    /// - Parameters:
    ///   - trackedKey: Key / property which should synchchronized when modified.
    ///   - modifiedPredicate: Predicate which determine if an object has been modified or not. If omitted
    ///                        an object is considered modified in all cases when the tracked key has been changed.
    init(trackedKey: String,
         modifiedPredicate: NSPredicate? = nil) {
        self.trackedKey = trackedKey
        self.modifiedPredicate = modifiedPredicate
    }

    func objectsDidChange(_ objects: Set<NSManagedObject>) {
        let trackedObjects = objects.compactMap({ $0 as? Transcoder.Object})
        let modifiedObjects = trackedObjects.filter({ modifiedPredicate?.evaluate(with: $0) ?? true })

        addModifiedObjects(modifiedObjects)
    }

    func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        if let modifiedPredicate = modifiedPredicate {
            return Transcoder.Object.sortedFetchRequest(with: modifiedPredicate)
        } else {
            return Transcoder.Object.sortedFetchRequest()
        }
    }

    func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        let trackedObjects = objects.compactMap({ $0 as? Transcoder.Object})

        addModifiedObjects(trackedObjects)
    }

    func addModifiedObjects(_ objects: [Transcoder.Object]) {
        for modifiedObject in objects {
            guard let modifiedKeys = modifiedObject.modifiedKeys,
                  modifiedKeys.contains(trackedKey),
                  !pending.contains(modifiedObject)
            else { continue }

            pending.insert(modifiedObject)
            transcoder?.synchronize(key: trackedKey, for: modifiedObject, completion: {
                modifiedObject.resetLocallyModifiedKeys(modifiedKeys)
                self.pending.remove(modifiedObject)
            })
        }
    }

}
