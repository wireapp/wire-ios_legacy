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
import WireCryptobox

extension Sequence where Element: NSManagedObject {

    /// Perform changes on a sequence of NSManagedObjects and save at a regular interval and fault
    /// objects in order to keep memory consumption low.
    ///
    /// - Parameters:
    ///   - saveInterval: Number of changes we are performed before the context is saved
    ///   - block: Change which should be performed on the objects
    func modifyAndSaveInBatches(saveInterval: Int = 10000, _ block: (Element) throws -> Void) throws {
        var processed: [Element] = []

        for element in self {
            try autoreleasepool {
                try block(element)

                processed.append(element)

                if processed.count > saveInterval {
                    let context = element.managedObjectContext

                    try context?.save()
                    processed.forEach({
                        context?.refresh($0, mergeChanges: false)
                    })
                    processed = []
                }
            }
        }

        try processed.last?.managedObjectContext?.save()
    }

}

extension NSManagedObjectContext {

    // MARK: - Migration

    enum MigrationError: LocalizedError {

        case missingDatabaseKey
        case failedToMigrateInstances(type: ZMManagedObject.Type, reason: String)

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                return "A database key is required to migrate."
            case let .failedToMigrateInstances(type, reason):
                return "Failed to migrate all instances of \(type). Reason: \(reason)"
            }
        }

    }

    /// Enables encryption at rest after successfully migrating the database.
    ///
    /// Depending on the size of the database, the migration may take a long time and will block the
    /// thread. If the migration fails for any reason, the feature is not enabled, but the context may
    /// be in a dirty, partially migrated state.
    ///
    /// - Parameters:
    ///   - encryptionKeys: encryption keys that will be used to during migration
    ///   - skipMigration: if `true` the existing content in the database will not be encrypted.
    ///
    ///     **Warning**: not migrating the database can cause data to be lost.
    ///
    /// - Throws: `MigrationError` if the migration failed.

    public func enableEncryptionAtRest(encryptionKeys: EncryptionKeys, skipMigration: Bool = false) throws {
        self.encryptionKeys = encryptionKeys
        encryptMessagesAtRest = true

        guard !skipMigration else { return }

        do {
            try migrateInstancesTowardEncryptionAtRest(type: ZMGenericMessageData.self)
            try migrateInstancesTowardEncryptionAtRest(type: ZMClientMessage.self)
            try migrateInstancesTowardEncryptionAtRest(type: ZMConversation.self)
        } catch {
            encryptMessagesAtRest = false
            throw error
        }
    }

    /// Disables encryption at rest after successfully migrating the database.
    ///
    /// Depending on the size of the database, the migration may take a long time and will block the
    /// thread. If the migration fails for any reason, the feature is not disabled, but the context may
    /// be in a dirty, partially migrated state.
    ///
    /// - Parameters:
    ///   - encryptionKeys: encryption keys that will be used to during migration
    ///   - skipMigration: if `true` the existing content in the database will not be decrypted.
    ///
    ///     **Warning**: not migrating the database can cause data to be lost.
    ///
    /// - Throws: `MigrationError` if the migration failed.

    public func disableEncryptionAtRest(encryptionKeys: EncryptionKeys, skipMigration: Bool = false) throws {
        self.encryptionKeys = encryptionKeys
        encryptMessagesAtRest = false

        guard !skipMigration else { return }

        do {
            try migrateInstancesAwayFromEncryptionAtRest(type: ZMGenericMessageData.self)
            try migrateInstancesAwayFromEncryptionAtRest(type: ZMClientMessage.self)
            try migrateInstancesAwayFromEncryptionAtRest(type: ZMConversation.self)
        } catch {
            encryptMessagesAtRest = true
            throw error
        }
    }

    private func migrateInstancesTowardEncryptionAtRest<T>(type: T.Type) throws
        where T: MigratableEntity {
        do {
            try fetchRequest(forType: type, batchSize: 100).execute().modifyAndSaveInBatches { (instance) in
                try instance.migrateTowardEncryptionAtRest(in: self)
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func migrateInstancesAwayFromEncryptionAtRest<T>(type: T.Type) throws
        where T: MigratableEntity {
        do {
            try fetchRequest(forType: type, batchSize: 100).execute().modifyAndSaveInBatches { (instance) in
                try instance.migrateAwayFromEncryptionAtRest(in: self)
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func fetchRequest<T>(forType type: T.Type, batchSize: Int) -> NSFetchRequest<T>
        where T: MigratableEntity {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        fetchRequest.predicate = type.predicateForObjectsNeedingMigration
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = batchSize
        return fetchRequest
    }

    /// Whether the encryption at rest feature is enabled.

    internal(set) public var encryptMessagesAtRest: Bool {
        get {
            (persistentStoreMetadata(forKey: PersistentMetadataKey.encryptMessagesAtRest.rawValue) as? NSNumber)?.boolValue ?? false
        }

        set {
            setPersistentStoreMetadata(NSNumber(booleanLiteral: newValue),
                                       key: PersistentMetadataKey.encryptMessagesAtRest.rawValue)
        }

    }

    // MARK: - Encryption / Decryption

    enum EncryptionError: LocalizedError {

        case missingDatabaseKey
        case cryptobox(error: ChaCha20Poly1305.AEADEncryption.EncryptionError)

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                return "Database key not found. Perhaps the database is locked."
            case .cryptobox(let error):
                return error.errorDescription
            }
        }

    }

    func encryptData(data: Data) throws -> (data: Data, nonce: Data) {
        guard let key = encryptionKeys?.databaseKey else { throw EncryptionError.missingDatabaseKey }
        let context = contextData()

        do {
            let (ciphertext, nonce) = try ChaCha20Poly1305.AEADEncryption.encrypt(message: data, context: context, key: key._storage)
            return (ciphertext, nonce)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }

    }

    func decryptData(data: Data, nonce: Data) throws -> Data {
        guard let key = encryptionKeys?.databaseKey else { throw EncryptionError.missingDatabaseKey }
        let context = contextData()

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(ciphertext: data, nonce: nonce, context: context, key: key._storage)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }
    }

    private func contextData() -> Data {
        let selfUser = ZMUser.selfUser(in: self)

        guard
            let selfClient = selfUser.selfClient(),
            let selfUserId = selfUser.remoteIdentifier?.transportString(),
            let selfClientId = selfClient.remoteIdentifier,
            let context = (selfUserId + selfClientId).data(using: .utf8)
        else {
            fatalError("Could not obtain self user id and self client id")
        }

        return context
    }

    // MARK: - Database Key

    private static let encryptionKeysUserInfoKey = "encryptionKeys"

    public var encryptionKeys: EncryptionKeys? {
        get { userInfo[Self.encryptionKeysUserInfoKey] as? EncryptionKeys }
        set { userInfo[Self.encryptionKeysUserInfoKey] = newValue }
    }

    func getEncryptionKeys() throws -> EncryptionKeys {
        guard let encryptionKeys = self.encryptionKeys else {
            throw MigrationError.missingDatabaseKey
        }

        return encryptionKeys
    }

}

// MARK: - Migratable

private typealias MigratableEntity = ZMManagedObject & EncryptionAtRestMigratable

/// A type that needs to be migrated when encryption at rest is enabled / disabled.

protocol EncryptionAtRestMigratable {

    /// The predicate to use to fetch specific instances for migration.

    static var predicateForObjectsNeedingMigration: NSPredicate? { get }

    /// Migrate necessary data to adhere to encryption at rest feature.
    ///
    /// For example, encrypt sensitve data and set a nonce.

    func migrateTowardEncryptionAtRest(in moc: NSManagedObjectContext) throws

    /// Migrate necessary data to make it available under normal circumstances.
    ///
    /// For example, decrypt sensitive data and clear the nonce.

    func migrateAwayFromEncryptionAtRest(in moc: NSManagedObjectContext) throws

}
