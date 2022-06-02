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
import XCTest

class CoreDataStackTests_Migration: DatabaseBaseTest {

    enum TestError: Error {
        case somethingWentWrong
    }

    override func tearDown() {
        CoreDataStack.clearMigrationDirectory(dispatchGroup: dispatchGroup)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
        super.tearDown()
    }

    func performMigration(accountIdentifier: UUID,
                          migration: @escaping (NSManagedObjectContext) throws -> Void) -> Result<Void>? {
        var result: Result<Void>?
        CoreDataStack.migrateLocalStorage(accountIdentifier: accountIdentifier,
                                          applicationContainer: applicationContainer,
                                          dispatchGroup: dispatchGroup,
                                          migration: migration,
                                          completion: { result = $0 })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return result
    }

    // MARK: - Migration tests

    func testThatLocalStoreMigration_CanAlterTheDatabase() throws {
        // given
        let metadataValue = 242
        let metadataKey = "hello"
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        let result = performMigration(accountIdentifier: uuid) { (context) in
            context.setPersistentStoreMetadata(metadataValue, key: metadataKey)
        }

        // then
        guard case .success = result else { return XCTFail() }

        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        let storedValue = directory.viewContext.persistentStoreMetadata(forKey: metadataKey) as? Int
        XCTAssertEqual(storedValue, metadataValue)
    }

    func testThatLocalStoreMigration_DoesNotAlterTheDatabase_WhenMigrationFails() throws {
        // given
        let metadataValue = 242
        let metadataKey = "hello"
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        var result: Result<Void>?
        performIgnoringZMLogError {
            result = self.performMigration(accountIdentifier: uuid) { (context) in
                context.setPersistentStoreMetadata(metadataValue, key: metadataKey)
                try context.save()
                throw TestError.somethingWentWrong
            }
        }

        // then
        guard case .failure(CoreDataStack.MigrationError.migrationFailed(TestError.somethingWentWrong)) = result else { return XCTFail() }

        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        let storedValue = directory.viewContext.persistentStoreMetadata(forKey: metadataKey) as? Int
        XCTAssertNil(storedValue)
    }

    func testThatLocalStoreMigration_FailWhenLocalStoreDoesNotExist() throws {
        // given
        let uuid = UUID()

        // when
        var result: Result<Void>?
        performIgnoringZMLogError {
            result = self.performMigration(accountIdentifier: uuid) { (_) in }
        }

        // then
        guard case .failure(CoreDataStack.MigrationError.missingLocalStore) = result else { return XCTFail() }
    }

    func testThatLocalStoreMigration_DeletesTemporaryStore_OnSuccess() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        let result = performMigration(accountIdentifier: uuid) { (_) in }

        // then
        guard case .success = result else { return XCTFail() }

        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
    }

    func testThatLocalStoreMigration_DeletesTemporaryStore_OnFailure() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        var result: Result<Void>?
        performIgnoringZMLogError {
            result = self.performMigration(accountIdentifier: uuid) { (_) in
                throw TestError.somethingWentWrong
            }
        }

        // then
        guard case .failure(CoreDataStack.MigrationError.migrationFailed(TestError.somethingWentWrong)) = result else { return XCTFail() }

        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
    }

}
