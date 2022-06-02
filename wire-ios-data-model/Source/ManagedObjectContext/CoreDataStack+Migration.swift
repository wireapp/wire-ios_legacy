////
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

extension CoreDataStack {

    public enum MigrationError: Error {
        case missingLocalStore
        case migrationFailed(Error)
    }

    private static let fileManager = FileManager()
    private static let workQueue = DispatchQueue(label: "Local storage migration", qos: .userInitiated)
    private static let databaseDirectoryName = "data"

    // Each migration for any account will be created in a unique subdirectory inside.
    // Calling `clearMigrationDirectory` will remove this directory and all migrations.
    public static var migrationDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("migration")
    }

    // Calling this method will delete all migrations stored inside `migrationDirectory`.
    public static func clearMigrationDirectory(dispatchGroup: ZMSDispatchGroup? = nil) {
        workQueue.async(group: dispatchGroup) {
            removeDirectory(at: migrationDirectory)
        }
    }

    static func removeDirectory(at url: URL) {
        do {
            guard Self.fileManager.fileExists(atPath: url.path) else { return }
            try Self.fileManager.removeItem(at: url)
        } catch {
            Logging.localStorage.debug("error removing directory: \(error)")
        }
    }

    /// Perform a migration on the local storage.
    ///
    /// The migration will be performed on a temporary copy of the local store which will
    /// replace the local store if the migration is successfull.
    ///
    /// - Parameters:
    ///   - accountIdentifier: identifier of account being backed up
    ///   - applicationContainer: shared application container
    ///   - dispatchGroup: group for testing
    ///   - migration: block which performs the migration work
    ///   - completion: called on main thread when done.
    public static func migrateLocalStorage(
        accountIdentifier: UUID,
        applicationContainer: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        migration: @escaping (NSManagedObjectContext) throws -> Void,
        completion: @escaping (Result<Void>) -> Void
        ) {

        func fail(_ error: MigrationError) {
            Logging.localStorage.error("Migrating local store failed: \(error)")

            // Clean up temporary migration store
            removeDirectory(at: Self.migrationDirectory)

            DispatchQueue.main.async(group: dispatchGroup) {
                completion(.failure(error))
            }
        }

        let accountDirectory = Self.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        let storeFile = accountDirectory.appendingPersistentStoreLocation()

        guard fileManager.fileExists(atPath: accountDirectory.path) else { return fail(.missingLocalStore) }

        let migrationDirectory = self.migrationDirectory.appendingPathComponent(UUID().uuidString)
        let databaseDirectory = migrationDirectory.appendingPathComponent(databaseDirectoryName)

        workQueue.async(group: dispatchGroup) {
            do {
                let model = CoreDataStack.loadMessagingModel()
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

                // Create target directory
                try fileManager.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
                let migrationStoreLocation = databaseDirectory.appendingStoreFile()
                let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)

                // Recreate the persistent store inside a new location
                try coordinator.replacePersistentStore(
                    at: migrationStoreLocation,
                    destinationOptions: options,
                    withPersistentStoreFrom: storeFile,
                    sourceOptions: options,
                    ofType: NSSQLiteStoreType
                )

                try performMigration(coordinator: coordinator,
                                     location: migrationStoreLocation,
                                     options: options,
                                     migration: migration)

                // Import the persistent store to the account data directory
                try coordinator.replacePersistentStore(
                    at: storeFile,
                    destinationOptions: options,
                    withPersistentStoreFrom: migrationStoreLocation,
                    sourceOptions: options,
                    ofType: NSSQLiteStoreType
                )

                // Clean up temporary migration store
                removeDirectory(at: Self.migrationDirectory)

                DispatchQueue.main.async(group: dispatchGroup) {
                    completion(.success(()))
                }
            } catch {
                fail(.migrationFailed(error))
            }
        }
    }

    private static func performMigration(coordinator: NSPersistentStoreCoordinator, location: URL, options: [String: Any], migration: @escaping (NSManagedObjectContext) throws -> Void) throws {

        // Add persistent store at the new location to allow creation of NSManagedObjectContext
        _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: location, options: options)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        try context.performGroupedAndWait { context in
            try migration(context)
            _ = context.makeMetadataPersistent()
            try context.save()
        }
    }

}
