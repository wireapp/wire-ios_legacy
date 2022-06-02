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

extension CoreDataStack {

    static let storeFileExtensions = ["", "-wal", "-shm"]

    /// Locations where Wire is or has historically been storing data.
    private var storageLocations: [URL] {
        var locations = [.cachesDirectory,
                         .applicationSupportDirectory,
                         .libraryDirectory].compactMap {
                            FileManager.default.urls(for: $0, in: .userDomainMask).first
                         }

        locations.append(applicationContainer)

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            locations.append(applicationContainer
                                .appendingPathComponent(bundleIdentifier))
            locations.append(applicationContainer
                                .appendingPathComponent(bundleIdentifier)
                                .appendingPathComponent(account.userIdentifier.uuidString))
            locations.append(applicationContainer
                                .appendingPathComponent(bundleIdentifier)
                                .appendingPathComponent(account.userIdentifier.uuidString)
                                .appendingPathComponent("store"))
        }

        return locations
    }

    /// Delete all files in directories where Wire has historically
    /// been storing data.
    private func clearStorage() throws {

        for location in storageLocations {
            try clearStoreFiles(in: location)
            try clearSessionStore(in: location)
        }
    }

    private func clearSessionStore(in directory: URL) throws {
        let fileManager = FileManager.default

        let sessionDirectory = directory.appendingSessionStoreFolder()

        if fileManager.fileExists(atPath: sessionDirectory.path) {
            try fileManager.removeItem(at: sessionDirectory)
        }
    }

    private func clearStoreFiles(in directory: URL) throws {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }

        var messageStoreFiles = Self.storeFileExtensions.map {
            directory.appendingStoreFile().appendingSuffixToLastPathComponent(suffix: $0)
        }
        messageStoreFiles.append(directory.appendingStoreSupportFolder())

        let eventStoreFiles = Self.storeFileExtensions.map {
            directory.appendingEventStoreFile().appendingSuffixToLastPathComponent(suffix: $0)
        }

        let storeFiles = messageStoreFiles + eventStoreFiles

        try storeFiles.forEach { (storeFile) in
            if fileManager.fileExists(atPath: storeFile.path) {
                try fileManager.removeItem(at: storeFile)
            }
        }
    }

    private func accountDataFolderExists() -> Bool {
        let accountsFolder = Self.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: applicationContainer)

        return FileManager.default.fileExists(atPath: accountsFolder.path)
    }

    /// Clears any potentially stored files if the account folder doesn't exists.
    /// This either means we are running on a fresh install or the user has upgraded
    /// from a legacy installation which we no longer support.
    func clearStorageIfNecessary() {
        guard !accountDataFolderExists() else { return }

        Logging.localStorage.info("Clearing storage on upgrade from legacy installation")

        do {
            try clearStorage()
        } catch let error {
            Logging.localStorage.error("Failed to clear storage: \(error)")
        }
    }

}
