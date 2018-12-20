//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

/// User default key for the array of enabled logs
private let enabledLogsKey = "WireEnabledZMLogTags"


extension Settings {
    
    /// Enable/disable a log
    func set(logTag: String, enabled: Bool) {

        ZMSLog.set(level: enabled ? .debug : .warn, tag: logTag)
        saveEnabledLogs()
    }
    
    /// Save to user defaults the list of logs that are enabled
    private func saveEnabledLogs() {
        let enabledLogs = ZMSLog.allTags.filter { tag in
            let level = ZMSLog.getLevel(tag: tag)
            return level == .debug || level == .info
        } as NSArray
        
        UserDefaults.shared().set(enabledLogs, forKey: enabledLogsKey)
        setLogRecording(enabled: enabledLogs.count > 0)
    }
    
    /// Loads from user default the list of logs that are enabled
    @objc public func loadEnabledLogs() {
        let avsTag = "AVS"
        if isInternal {
            var tagsToEnable = Set(arrayLiteral: avsTag)
            if let savedTags = UserDefaults.shared().object(forKey: enabledLogsKey) as? Array<String> {
                tagsToEnable.formUnion(savedTags)
            } else {
                tagsToEnable.formUnion(["Network", "SessionManager", "Conversations", "calling", "link previews", "event-processing", "SyncStatus", "OperationStatus", "Push", "Crypto", "cryptobox"])
            }
            enableLogs(tagsToEnable)
        } else {
            enableLogs([avsTag])
        }
    }
    
    private func enableLogs(_ tags : Set<String>) {
        tags.forEach { (tag) in
            ZMSLog.set(level: .debug, tag: tag)
        }
        setLogRecording(enabled: !tags.isEmpty)
    }
    
    /// Sets whether recording is enabled
    private func setLogRecording(enabled: Bool) {
        if enabled {
            ZMSLog.startRecording(isInternal: isInternal)
        } else {
            ZMSLog.stopRecording()
        }
    }
    
    private var isInternal: Bool {
        return DeveloperMenuState.developerMenuEnabled()
    }
}
