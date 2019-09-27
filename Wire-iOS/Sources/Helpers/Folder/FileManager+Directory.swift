
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "FileManager")

extension FileManager {

    /// Create a directiory excluded from back up
    ///
    /// - Parameter pathComponent: folder to create
    func createBackupExcludedDirectoryIfNeeded(_ pathComponent: String) {
        guard let url = URL.directoryURL(pathComponent) else { return }

        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }

            try url.wr_excludeFromBackup()
        }
        catch (let exception) {
            zmLog.error("Error creating \(String(describing: url)): \(exception)")
        }

    }
}

extension URL {
    static func directoryURL(_ pathComponent: String) -> URL? {
        let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url?.appendingPathComponent(pathComponent)
    }
}
