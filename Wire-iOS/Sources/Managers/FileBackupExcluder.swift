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

final internal class FileBackupExcluder: NSObject {

    private static let filesToExclude: [FileInDirectory] = [
        (.libraryDirectory, "Preferences/com.apple.EmojiCache.plist"),
        (.libraryDirectory, ".")
    ]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override internal init() {
        super.init()
        
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
    
    @objc internal func applicationWillEnterForeground(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }
    
    @objc internal func applicationWillResignActive(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }
    
    private func excludeFilesFromBackup() {
        do {
            try type(of: self).filesToExclude.forEach { (directory, path) in
                let url = URL.wr_directory(for: directory).appendingPathComponent(path)
                try url.excludeFromBackupIfExists()
            }
        }
        catch (let error) {
            zmLog.error("Cannot exclude file from the backup: \(self): \(error)")
        }
    }

    @objc public func excludeLibraryFolderInSharedContainer(sharedContainerURL : URL ) {
        do {
            let libraryURL = sharedContainerURL.appendingPathComponent("Library")
            try libraryURL.excludeFromBackupIfExists()
        } catch {
            zmLog.error("Cannot exclude file from the backup: \(self): \(error)")
        }
    }
}


fileprivate extension URL {

    func excludeFromBackupIfExists() throws {
        if FileManager.default.fileExists(atPath: path) {
            try wr_excludeFromBackup()
        }
    }

}
