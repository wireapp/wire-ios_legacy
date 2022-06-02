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
@testable import WireDataModel

class CoreDataStackTests_ClearStorage: ZMTBaseTest {

    let account: Account = Account(userName: "", userIdentifier: UUID())

    var applicationContainer: URL {
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("CoreDataStackTests")
    }

    func testThatPersistentStoreIsCleared_WhenUpgradingFromLegacyInstallation() {
        // given
        let existingFiles = createStoreFilesInLegacyLocations()

        // when
        _ = CoreDataStack(account: account,
                          applicationContainer: applicationContainer,
                          inMemoryStore: false,
                          dispatchGroup: dispatchGroup)

        // then
        for file in existingFiles {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path),
                           "\(file.path) should have been deleted")
        }
    }

    func testThatSessionDirectoryIsCleared_WhenUpgradingFromLegacyInstallation() {
        // given
        let existingFiles = createSessionFilesInLegacyLocations()

        // when
        _ = CoreDataStack(account: account,
                          applicationContainer: applicationContainer,
                          inMemoryStore: false,
                          dispatchGroup: dispatchGroup)

        // then
        for file in existingFiles {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path),
                           "\(file.path) should have been deleted")
        }
    }

    func testThatAccountStorageIsNotCleared_WhenTheInitialStoreIsCreated() throws {
        // given
        createAccountDirectory()

        // when
        _ = CoreDataStack(account: account,
                          applicationContainer: applicationContainer,
                          inMemoryStore: false,
                          dispatchGroup: dispatchGroup)

        // then
        let accountsDirectory = applicationContainer.appendingPathComponent("Accounts")
        XCTAssertTrue(FileManager.default.fileExists(atPath: accountsDirectory.path),
                       "\(accountsDirectory.path) should not have been deleted")
    }

    func testThatStorageIsNotCleared_WhenUpgradingFromSupportedInstallation() throws {
        // given
        let existingFiles = createStoreFilesInLegacyLocations()
        try createAccountDataDirectory()

        // when
        _ = CoreDataStack(account: account,
                          applicationContainer: applicationContainer,
                          inMemoryStore: false,
                          dispatchGroup: dispatchGroup)

        // then
        for file in existingFiles {
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path),
                           "\(file.path) should not have been deleted")
        }
    }

    // MARK: Helpers

    func createAccountDataDirectory() throws {
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier,
                                                            applicationContainer: applicationContainer)

        try FileManager.default.createDirectory(at: accountFolder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    func createAccountDirectory() {
        let accountStore = AccountStore(root: applicationContainer)
        accountStore.add(Account(userName: "", userIdentifier: UUID()))
    }

    func createStoreFilesInLegacyLocations() -> [URL] {
        return previousStorageLocations.flatMap { (location) -> [URL] in
            let fileManager = FileManager.default
            try? fileManager.createDirectory(at: location,
                                            withIntermediateDirectories: true,
                                            attributes: nil)

            let messageStoreFiles = CoreDataStack.storeFileExtensions.map { location.appendingStoreFile().appendingSuffixToLastPathComponent(suffix: $0)
            }

            let eventStoreFiles = CoreDataStack.storeFileExtensions.map {
                location.appendingEventStoreFile().appendingSuffixToLastPathComponent(suffix: $0)
            }

            let storeFiles = messageStoreFiles + eventStoreFiles

            for storeFile in storeFiles {
                let success = fileManager.createFile(atPath: storeFile.path,
                                                     contents: "hello".data(using: .utf8)!,
                                                     attributes: nil)

                XCTAssertTrue(success)

            }

            return storeFiles
        }
    }

    func createSessionFilesInLegacyLocations() -> [URL] {
        return previousStorageLocations.map { (location) -> URL in
            let fileManager = FileManager.default
            let sessionDirectory = location.appendingPathComponent("otr")
            try! fileManager.createDirectory(at: sessionDirectory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
            return sessionDirectory
        }
    }

    /// Previous storage locations for the persistent store or key store
    var previousStorageLocations: [URL] {
        let accountID = account.userIdentifier.uuidString
        let bundleID = Bundle.main.bundleIdentifier!

        return [
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!,
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!,
            applicationContainer,
            applicationContainer.appendingPathComponent(bundleID),
            applicationContainer.appendingPathComponent(bundleID).appendingPathComponent(accountID),
            applicationContainer.appendingPathComponent(bundleID).appendingPathComponent(accountID).appendingPathComponent("store")
        ]
    }

}
