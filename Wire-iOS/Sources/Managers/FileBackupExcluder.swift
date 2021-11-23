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
import WireSystem
import UIKit
import WireCommonComponents

private let zmLog = ZMSLog(tag: "UI")

final class FileBackupExcluder: BackupExcluder {

    private static let filesToExclude: [FileInDirectory] = [
        (.libraryDirectory, "Preferences/com.apple.EmojiCache.plist"),
        (.libraryDirectory, ".")
    ]

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FileBackupExcluder.applicationWillEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: .none)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FileBackupExcluder.applicationWillResignActive(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: .none)

        self.excludeFilesFromBackup()
    }

    @objc
    private func applicationWillEnterForeground(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }

    @objc
    private func applicationWillResignActive(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }

    private func excludeFilesFromBackup() {
        do {
            try FileBackupExcluder.exclude(filesToExclude: FileBackupExcluder.filesToExclude)
        } catch {
            zmLog.error("Cannot exclude file from the backup: \(self): \(error)")
        }
    }

    func excludeLibraryFolderInSharedContainer(sharedContainerURL: URL ) {
        do {
            let libraryURL = sharedContainerURL.appendingPathComponent("Library")
            try libraryURL.excludeFromBackupIfExists()
        } catch {
            zmLog.error("Cannot exclude file from the backup: \(self): \(error)")
        }
    }
}
