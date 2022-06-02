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

// MARK: - Public accessors

@objc(ZMPersistableMetadata) public protocol PersistableInMetadata: NSObjectProtocol {}

extension NSString: PersistableInMetadata {}
extension NSNumber: PersistableInMetadata {}
extension NSDate: PersistableInMetadata {}
extension NSData: PersistableInMetadata {}

public protocol SwiftPersistableInMetadata {}
extension String: SwiftPersistableInMetadata {}
extension Date: SwiftPersistableInMetadata {}
extension Data: SwiftPersistableInMetadata {}
extension Array: SwiftPersistableInMetadata {}
extension Int: SwiftPersistableInMetadata {}

// TODO: Swift 4
// extension Array where Element == SwiftPersistableInMetadata: SwiftPersistableInMetadata {}

extension NSManagedObjectContext {

    @objc(setPersistentStoreMetadata:forKey:) public func setPersistentStoreMetadata(_ persistable: PersistableInMetadata?, key: String) {
        self.setPersistentStoreMetadata(data: persistable, key: key)
    }

    public func setPersistentStoreMetadata(_ data: SwiftPersistableInMetadata?, key: String) {
        self.setPersistentStoreMetadata(data: data, key: key)
    }

    public func setPersistentStoreMetadata<T: SwiftPersistableInMetadata>(array: [T], key: String) {
        self.setPersistentStoreMetadata(data: array as NSArray, key: key)
    }
}

// MARK: - Internal setters/getters

private let metadataKey = "ZMMetadataKey"
private let metadataKeysToRemove = "ZMMetadataKeysToRemove"

extension NSManagedObjectContext {

    /// Non-persisted store metadata
    @objc internal var nonCommittedMetadata: NSMutableDictionary {
        return self.userInfo[metadataKey] as? NSMutableDictionary ?? NSMutableDictionary()
    }

    /// Non-persisted deleted metadata (need to keep around to know what to remove
    /// from the store when persisting)
    @objc internal var nonCommittedDeletedMetadataKeys: Set<String> {
        return self.userInfo[metadataKeysToRemove] as? Set<String> ?? Set<String>()
    }

    /// Discard non commited store metadata
    fileprivate func discardNonCommitedMetadata() {
        self.userInfo[metadataKeysToRemove] = [String]()
        self.userInfo[metadataKey] = [String: Any]()
    }

    /// Persist in-memory metadata to persistent store
    @objc func makeMetadataPersistent() -> Bool {

        guard nonCommittedMetadata.count > 0 || nonCommittedDeletedMetadataKeys.count > 0 else { return false }

        let store = self.persistentStoreCoordinator!.persistentStores.first!
        var storedMetadata = self.persistentStoreCoordinator!.metadata(for: store)

        // remove keys
        self.nonCommittedDeletedMetadataKeys.forEach { storedMetadata.removeValue(forKey: $0) }

        // set keys
        for (key, value) in self.nonCommittedMetadata {
            guard let stringKey = key as? String else {
                fatal("Wrong key in nonCommittedMetadata: \(key), value is \(value)")
            }
            storedMetadata[stringKey] = value
        }

        self.persistentStoreCoordinator?.setMetadata(storedMetadata, for: store)
        self.discardNonCommitedMetadata()

        return true
    }

    /// Remove key from list of keys that will be deleted next time
    /// the metadata is persisted to disk
    fileprivate func removeFromNonCommittedDeteledMetadataKeys(key: String) {
        var deletedKeys = self.nonCommittedDeletedMetadataKeys
        deletedKeys.remove(key)
        self.userInfo[metadataKeysToRemove] = deletedKeys
    }

    /// Adds a key to the list of keys to be deleted next time the metadata is persisted to disk
    fileprivate func addNonCommittedDeletedMetadataKey(key: String) {
        var deletedKeys = self.nonCommittedDeletedMetadataKeys
        deletedKeys.insert(key)
        self.userInfo[metadataKeysToRemove] = deletedKeys
    }

    /// Set a value in the metadata for the store. The value won't be persisted until the metadata is persisted
    fileprivate func setPersistentStoreMetadata(data: Any?, key: String) {
        let metadata = self.nonCommittedMetadata
        if let data = data {
            self.removeFromNonCommittedDeteledMetadataKeys(key: key)
            metadata.setObject(data, forKey: key as NSCopying)
        } else {
            self.addNonCommittedDeletedMetadataKey(key: key)
            metadata.removeObject(forKey: key)
        }
        self.userInfo[metadataKey] = metadata
    }
}
