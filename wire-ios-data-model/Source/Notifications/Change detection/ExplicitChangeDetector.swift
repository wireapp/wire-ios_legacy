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

class ExplicitChangeDetector: ChangeDetector {

    private typealias ObservableChangesByObject = [ZMManagedObject: Changes]

    // MARK: - Properties

    private unowned let context: NSManagedObjectContext

    private var accumulatedChanges = ObservableChangesByObject()
    private let snapshotCenter: SnapshotCenter
    private let dependencyKeyStore: DependencyKeyStore

    // MARK: - Life cycle

    init(classIdentifiers: [ClassIdentifier], managedObjectContext: NSManagedObjectContext) {
        context = managedObjectContext
        snapshotCenter = SnapshotCenter(managedObjectContext: context)
        dependencyKeyStore = DependencyKeyStore(classIdentifiers: classIdentifiers)
    }

    // MARK: - Methods

    func consumeChanges() -> [ObjectChangeInfo] {
        defer {
            accumulatedChanges = [:]
        }

        return  accumulatedChanges.compactMap {
            ObjectChangeInfo.changeInfo(for: $0, changes: $1)
        }
    }

    func reset() {
        accumulatedChanges = [:]
        snapshotCenter.clearAllSnapshots()
    }

    func add(changes: Changes, for object: ZMManagedObject) {
        merge(changes: [object: changes])
    }

    func detectChanges(for objects: ModifiedObjects) {
        snapshotCenter.createSnapshots(for: objects.inserted)

        merge(changes:
            observableChanges(for: objects.updatedAndRefreshed),
            observableChangesCausedByInsertionOrDeletion(for: objects.inserted),
            observableChangesCausedByInsertionOrDeletion(for: objects.deleted)
        )
    }

    // MARK: - Private methods

    /// Detect all observable changes for the given objects and their dependencies.
    ///
    /// - Parameters:
    ///     - objects: A set of modified objects.
    ///     
    /// - Returns:
    ///     A mapping of all objects and their changed keys.

    private func observableChanges(for objects: Set<ZMManagedObject>) -> ObservableChangesByObject {
        objects.lazy
            .map(getChangedKeysSinceLastSave)
            .filter(\.hasChanges)
            .map(observableChangesCausedByChange)
            .reduce([:], combine)
    }

    private func getChangedKeysSinceLastSave(object: ZMManagedObject) -> UpdatedObject {
        var changedKeys = object.changedKeys

        if changedKeys.isEmpty || object.isFault {
            // If the object is a fault, calling changedValues() will return an empty set.
            // Luckily we created a snapshot of the object before the merge happend which
            // we can use to compare the values.
            changedKeys = snapshotCenter.extractChangedKeysFromSnapshot(for: object)
        } else {
            snapshotCenter.updateSnapshot(for: object)
        }

        return UpdatedObject(object: object, changedKeys: changedKeys)
    }

    /// Identify which objects and their observable keys have changed as a result of changes to the given object.
    ///
    /// E.g if `user.fullName` and `conversation.name` both depend on `user.firstName`, then a change to `user.firstName`
    /// causes means `user.fullName` and `conversation.name` must be considered changed too. The result of this method
    /// would then be `[user: firstName, user: fullName, conversation: name]`.
    ///
    /// - Parameters:
    ///     - updatedObject: An object that has changed.
    ///     - changedKeys: The key paths that changed on `updatedObject`.
    ///
    /// - Returns:
    ///     All objects and their observable keys that have changed.

    private func observableChangesCausedByChange(in updatedObject: UpdatedObject) -> ObservableChangesByObject {
        let (object, changedKeys) = (updatedObject.object, updatedObject.changedKeys)

        var result = ObservableChangesByObject()

        let affectedKeysOfUpdatedObject = changedKeys
            .map { dependencyKeyStore.observableKeysAffectedByValue(object.classIdentifier, key: $0) }
            .flattened

        if !affectedKeysOfUpdatedObject.isEmpty {
            result[object] = Changes(changedKeys: affectedKeysOfUpdatedObject)
        }

        if let sideEffectSource = object as? SideEffectSource {
            let affectedKeysOfOtherObjects = sideEffectSource.affectedObjectsAndKeys(keyStore: dependencyKeyStore, knownKeys: changedKeys)
            result = result.merged(with: affectedKeysOfOtherObjects)
        }

        return result
    }

    /// Identify which objects and their observable keys have changed as a result of insertion or deletion
    /// of the given objects.
    ///
    /// E.g insertion of a new conversation participant may affect the conversation name.
    ///
    /// - Parameters:
    ///     - objects: Objects that have been inserted or deleted.
    ///
    /// - Returns:
    ///     All objects and their observable keys that have changed.

    private func observableChangesCausedByInsertionOrDeletion(for objects: Set<ZMManagedObject>) -> ObservableChangesByObject {
        objects.lazy
            .compactMap { $0 as? SideEffectSource }
            .map { $0.affectedObjectsForInsertionOrDeletion(keyStore: self.dependencyKeyStore) }
            .reduce([:], combine)
    }

    // MARK: - Helper methods

    private func merge(changes: ObservableChangesByObject) {
        accumulatedChanges = accumulatedChanges.merged(with: changes)
    }

    private func merge(changes: ObservableChangesByObject...) {
        accumulatedChanges = changes.reduce(accumulatedChanges, combine)
    }

    private func combine(lhs: ObservableChangesByObject, rhs: ObservableChangesByObject) -> ObservableChangesByObject {
        return lhs.merged(with: rhs)
    }

}

// MARK: - Helper extensions

fileprivate extension ExplicitChangeDetector {

    struct UpdatedObject {

        let object: ZMManagedObject
        let changedKeys: Set<String>

        var hasChanges: Bool {
            return !changedKeys.isEmpty
        }

    }

}

private extension Sequence where Element: SetAlgebra {

    var flattened: Element {
        reduce(Element()) { $0.union($1) }
    }

}

private extension LazySequence {

    func collect() -> [Self.Element] {
        return Array(self)
    }

}

private extension NSManagedObject {

    var changedKeys: Set<String> {
        return Set(changedValues().keys)
    }

}
