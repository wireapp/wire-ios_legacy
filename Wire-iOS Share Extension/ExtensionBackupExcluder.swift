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
import WireExtensionComponents

private let zmLog = ZMSLog(tag: "UI")

class ExtensionBackupExcluder {

    private static let filesToExclude: [FileInDirectory] = [
        (.libraryDirectory, "Cookies/Cookies.binarycookies"),
        (.libraryDirectory, ".")
    ]

    static func exclude() {
        do {
            try filesToExclude.forEach { (directory, path) in
                let url = URL.wr_directory(for: directory).appendingPathComponent(path)
                if FileManager.default.fileExists(atPath: url.path) {
                    try url.wr_excludeFromBackup()
                }
            }
        } catch {
            zmLog.error("Cannot exclude file from the backup: \(self): \(error)")
        }
    }

}
