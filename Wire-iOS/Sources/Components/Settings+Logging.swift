//
//  Settings+Logging.swift
//  Wire-iOS
//
//  Created by Marco Conti on 24/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import ZMCSystem

private let enabledLogsKey = "WireEnabledZMLogTags"

extension Settings {
    
    func set(logTag: String, enabled: Bool) {
        ZMLogSetLevelForTag(enabled ? .debug : .warn, (logTag as NSString).utf8String!)
        saveEnabledLogs()
    }
    
    private func saveEnabledLogs() {
        let enabledLogs = ZMLogGetAllTags().filter { str in
            let level = ZMLogGetLevelForTag(str as! String)
            return level == .debug || level == .info
        } as NSArray
        
        UserDefaults.shared().set(enabledLogs, forKey: enabledLogsKey)
    }
    
    @objc public func loadEnabledLogs() {
        
        guard let tagsToEnable = UserDefaults.shared().value(forKey: enabledLogsKey) as? Array<NSString> else {
            return
        }
        
        tagsToEnable.forEach { (tag) in
            ZMLogSetLevelForTag(.debug, tag.utf8String!)
        }
    }
}
