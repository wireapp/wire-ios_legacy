//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

// whitelisted files, so the FileRelocator doesn't consider to check these system files.
// - com.apple.nsurlsessiond is used by the system as cache while sharing an item.
// - .DS_Store is the hidden file for folder preferences used in macOS (only for simulator)
private let whitelistedFiles = ["com.apple.nsurlsessiond", ".DS_Store"]
private let zmLog = ZMSLog(tag: "ZMUserSession")

extension ZMUserSession {

    /// Checks the Library/Caches folder in the shared container directory for files that have not been assigned to a user account 
    /// and moves them to a folder named `wire-account-{accountIdentifier}` if there is no user-account folder yet
    /// It asserts if the caches folder contains unassigned files even though there is already an existing user account folder as this would be considered a programmer error
    @objc public static func moveCachesIfNeededForAccount(with accountIdentifier: UUID?, in sharedContainerURL: URL) {
        // FIXME: accountIdentifier should be non-nullable
        guard let accountIdentifier = accountIdentifier else { return }

        let fm = FileManager.default
        let newCacheLocation = fm.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL)
        let oldCacheLocation = fm.cachesURLForAccount(with: nil, in: sharedContainerURL)

        guard let files = (try? fm.contentsOfDirectory(atPath: oldCacheLocation.path))
        else { return }

        fm.createAndProtectDirectory(at: newCacheLocation)

        // FIXME: Use dictionary grouping in Swift4
        // see https://developer.apple.com/documentation/swift/dictionary/2893436-init
        let result = group(fileNames: files.filter { !whitelistedFiles.contains($0) })
        if result.assigned.count == 0 {
            result.unassigned.forEach {
                let newLocation = newCacheLocation.appendingPathComponent($0)
                let oldLocation = oldCacheLocation.appendingPathComponent($0)
                zmLog.debug("Moving non-assigned Cache folder from \(oldLocation) to \(newLocation)")
                do {
                    try fm.moveItem(at: oldLocation, to: newLocation)
                } catch let error {
                    zmLog.error("Failed to move non-assigned Cache folder from \(oldLocation) to \(newLocation) - \(error)")
                    do {
                        try fm.removeItem(at: oldLocation)
                    } catch let anError {
                        fatal("Could not remove unassigned cache folder at \(oldLocation) - \(anError)")
                    }
                }
            }
        } else if result.unassigned.count > 0 {
            requireInternal(false, "Caches folder contains items that have not been assigned to an account. Items should always be assigned to an account. Use `FileManager.cachesURLForAccount(with accountIdentifier:, in sharedContainerURL:)` to get the default Cache location for the current account")
        }
    }

    /// Groups files by checking if the fileName starts with the cachesFolderPrefix
    static func group(fileNames: [String]) -> (assigned: [String], unassigned: [String]) {
        let result: ([String], [String]) = fileNames.reduce(([], [])) { (tempResult, fileName) in
            if fileName.hasPrefix(FileManager.cachesFolderPrefix) {
                return (tempResult.0 + [fileName], tempResult.1)
            }
            return (tempResult.0, tempResult.1 + [fileName])
        }
        return result
    }

}
