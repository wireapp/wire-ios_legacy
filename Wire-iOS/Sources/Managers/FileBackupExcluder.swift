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
import CocoaLumberjackSwift

public extension URL {
    public func wr_excludeFromBackup() throws {
        var mutableCopy = self
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try mutableCopy.setResourceValues(resourceValues)
    }
    
    public static func wr_directory(for searchPathDirectory: NSFileManager.SearchPathDirectory) -> URL {
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(searchPathDirectory, .userDomainMask, true).first!)
    }
}

final internal class FileBackupExcluder: NSObject {
    typealias FileInDirectory = (NSFileManager.SearchPathDirectory, String)
    private static let filesToExclude: [FileInDirectory] = [(.libraryDirectory, "Preferences/com.apple.EmojiCache.plist")]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override internal init() {
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FileBackupExcluder.applicationWillEnterForeground(_:)),
                                               name: .UIApplicationWillEnterForeground,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FileBackupExcluder.applicationWillResignActive(_:)),
                                               name: .UIApplicationWillResignActive,
                                               object: .none)
        
        self.excludeFilesFromBackup()
    }
    
    @objc internal func applicationWillEnterForeground(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }
    
    @objc internal func applicationWillResignActive(_ sender: AnyObject!) {
        self.excludeFilesFromBackup()
    }
    
    internal func excludeFilesFromBackup() {
        do {
            try type(of: self).filesToExclude.forEach { (directory, path) in
                let url = URL.wr_directory(for: directory).appendingPathComponent(path)
                if FileManager.default.fileExists(atPath: url.path) {
                    try url.wr_excludeFromBackup()
                }
            }
        }
        catch (let error) {
            DDLogError("Cannot exclude file from the backup: \(self): \(error)")
        }
    }
}
