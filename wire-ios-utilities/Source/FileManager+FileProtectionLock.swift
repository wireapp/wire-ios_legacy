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

#if os(iOS)
    import UIKit
#endif



extension FileManager {
    
    /// Returns true if the file system is accessible, else false if it is locked
    /// due to encryption.
    ///
    public func isFileSystemAccessible() -> Bool {
        
        // create dummy file
        guard let cachesDirectory = self.urls(for: .cachesDirectory, in: .userDomainMask).first else { return false }
        createAndProtectDirectory(at: cachesDirectory)
        let dummyFile = cachesDirectory.appendingPathComponent("dummy_lock")
        let data = "testing".data(using: .utf8)!
        try? data.write(to: dummyFile)
        
        // protect until first unlock
        self.setProtectionUntilFirstUserAuthentication(dummyFile)
        
        // try to access the dummy file then clean up
        let result = fileExistsButIsNotReadableDueToEncryption(at: dummyFile)
        try? self.removeItem(at: dummyFile)
        return !result
    }
    
    /// Check if the file is created, but still locked.
    ///
    private func fileExistsButIsNotReadableDueToEncryption(at url: URL) -> Bool {
        guard self.fileExists(atPath: url.path) else { return false }
        return (try? FileHandle(forReadingFrom: url)) == nil
    }
    
    /// Executes the given block when the file system is unlocked and returns a token.
    /// This token needs to be retain in order for the block to be called.
    ///
    public func executeWhenFileSystemIsAccessible(_ block: @escaping () -> Void) -> Any? {
        
        #if os(iOS)
        // We need to handle the case when the database file is encrypted by iOS and user never entered the passcode
        // We use default core data protection mode NSFileProtectionCompleteUntilFirstUserAuthentication
        if !isFileSystemAccessible() {
            return executeOnceFileSystemIsUnlocked {
                block()
            }
        } else {
            block()
            return nil
        }
        #else
            block()
            return nil
        #endif
        
    }
    
    
    /// Listen for the notification for when first authentication has been completed
    /// (c.f. `NSFileProtectionCompleteUntilFirstUserAuthentication`). Once it's available, it will
    /// execute the closure.
    ///
    #if os(iOS)
    private func executeOnceFileSystemIsUnlocked(execute block: @escaping ()->()) -> Any {
        
        // This happens when
        // (1) User has passcode enabled
        // (2) User turns the phone on, but do not enter the passcode yet
        // (3) App is awake on the background due to VoIP push notification
        
        return NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: nil) { _ in block() }
    }
    #endif
}
