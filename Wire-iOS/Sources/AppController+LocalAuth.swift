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
import LocalAuthentication
import CocoaLumberjackSwift
import HockeySDK.BITHockeyManager

extension AppController {
    static var settingsPropertyFactory: SettingsPropertyFactory {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: UserDefaults.standard,
                                                              analytics: Analytics.shared(),
                                                              mediaManager: AVSProvider.shared.mediaManager,
                                                              userSession: ZMUserSession.shared()!,
                                                              selfUser: ZMUser.selfUser(),
                                                              crashlogManager: BITHockeyManager.shared())
        
        return settingsPropertyFactory
    }
    
    var appLockActive: Bool {
        let lockApp = type(of: self).settingsPropertyFactory.property(.lockApp)
        
        return lockApp.value() == SettingsPropertyValue(true)
    }
    
    static let authenticationPersistancePeriod: TimeInterval = 10
    
    var lastUnlockedDate: Date {
        get {
            let lastAuthDateProperty = type(of: self).settingsPropertyFactory.property(.lockAppLastDate)
            return Date(timeIntervalSinceReferenceDate: TimeInterval(lastAuthDateProperty.value().value() as! UInt32))
        }
        
        set {
            let lastAuthDateProperty = type(of: self).settingsPropertyFactory.property(.lockAppLastDate)
            try! lastAuthDateProperty.set(newValue: SettingsPropertyValue(UInt32(newValue.timeIntervalSinceReferenceDate)))
        }
    }
    
    /// @param callback confirmation; if auth is not needed called with 'true'
    func requireLocalAuthenticationIfNeeded(with callback: @escaping (Bool)->()) {
        guard #available(iOS 9.0, *), self.appLockActive else {
            callback(true)
            return
        }
        
        let lastAuthDate = self.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        if timeSinceAuth >= 0 && timeSinceAuth < type(of: self).authenticationPersistancePeriod {
            callback(true)
            return
        }
        
        let context: LAContext = LAContext()
        var error: NSError?
        let description = "self.settings.privacy_security.lock_app.description".localized
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: description, reply: { (success, error) -> Void in
                DispatchQueue.main.async {
                    callback(success)
                    
                    if !success {
                        DDLogError("Local authentication error: \(error?.localizedDescription)")
                    }
                    else {
                        self.lastUnlockedDate = Date()
                    }
                }
            })
        }
       
        if error != nil {
            DDLogError("Local authentication error: \(error?.localizedDescription)")
            callback(false)
        }
    }
}
