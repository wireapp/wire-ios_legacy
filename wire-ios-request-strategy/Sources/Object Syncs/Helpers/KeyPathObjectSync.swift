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

protocol KeyPathObjectSyncTranscoder: AnyObject {

    associatedtype T: Hashable

    /// Called when a object needs to be synchronized. It's the transcoder's responsibillity to call the `completion` handler when the synchronization is successfull or cancel.
    ///
    /// - parameters:
    ///   - object: Object which should be synchronized
    ///   - completion: called when the object as been synchronized
    func synchronize(_ object: T, completion: @escaping () -> Void)

    /// Called when a object was previously requested to be synchronized but the the condition for synchronizing stop being fulfilled before the object finished synchronizing.
    ///
    /// - parameters:
    ///   - object: Object which no longer needs be synchronized.
    func cancel(_ object: T)

}

/**
 KeyPathObjectSync synchronizes objects filtered by a boolean KeyPath which should evaluate to `true` if the object needs to synced.
 
 Note this is only supported for managed objects and for properties which are stored in Core Data.
 
 */
class KeyPathObjectSync<Transcoder: KeyPathObjectSyncTranscoder>: NSObject, ZMContextChangeTracker {

    // MARK: - Life Cycle

    init(entityName: String, _ keyPath: WritableKeyPath<Transcoder.T, Bool>) {
        self.entityName = entityName
        self.keyPath = keyPath
    }

    // MARK: - Properties

    weak var transcoder: Transcoder?

    let entityName: String
    let keyPath: WritableKeyPath<Transcoder.T, Bool>
    var pending: Set<Transcoder.T> = Set()

    // MARK: - ZMContextChangeTracker

    func objectsDidChange(_ objects: Set<NSManagedObject>) {
        let objects = objects.compactMap({ $0 as? Transcoder.T })

        objects.forEach { object in
            var mutableObject = object

            if object[keyPath: keyPath] {
                if !pending.contains(object) {
                    pending.insert(object)
                    transcoder?.synchronize(object) {
                        mutableObject[keyPath: self.keyPath] = false
                    }
                }
            } else if pending.contains(object) {
                pending.remove(object)
                transcoder?.cancel(object)
            }
        }
    }

    func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let keypathExpression =  NSExpression(forKeyPath: keyPath)
        let valueExpression = NSExpression(forConstantValue: true)
        let predicate = NSComparisonPredicate(leftExpression: keypathExpression,
                              rightExpression: valueExpression,
                              modifier: .direct,
                              type: .equalTo)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate

        return fetchRequest
    }

    func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        objectsDidChange(objects)
    }

}
