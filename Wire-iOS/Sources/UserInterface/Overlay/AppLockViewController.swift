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
import Cartography
import LocalAuthentication
import CocoaLumberjackSwift
import HockeySDK.BITHockeyManager


@objc final class AppLockViewController: UIViewController {
    fileprivate var lockView: AppLockView!
    fileprivate static let authenticationPersistancePeriod: TimeInterval = 10
    fileprivate var localAuthenticationCancelled: Bool = false
    fileprivate var localAuthenticationNeeded: Bool = true
    fileprivate var dimContents: Bool = false {
        didSet {
            self.view.isHidden = !self.dimContents
        }
    }

    static var settingsPropertyFactory: SettingsPropertyFactory {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: UserDefaults.standard,
                                                              analytics: Analytics.shared(),
                                                              mediaManager: AVSProvider.shared.mediaManager,
                                                              userSession: ZMUserSession.shared()!,
                                                              selfUser: ZMUser.selfUser(),
                                                              crashlogManager: BITHockeyManager.shared())
        
        return settingsPropertyFactory
    }
    
    fileprivate var appLockActive: Bool {
        let lockApp = type(of: self).settingsPropertyFactory.property(.lockApp)
        
        return lockApp.value() == SettingsPropertyValue(true)
    }
    
    fileprivate var lastUnlockedDate: Date {
        get {
            let lastAuthDateProperty = type(of: self).settingsPropertyFactory.property(.lockAppLastDate)
            return Date(timeIntervalSinceReferenceDate: TimeInterval(lastAuthDateProperty.value().value() as! UInt32))
        }
        
        set {
            let lastAuthDateProperty = type(of: self).settingsPropertyFactory.property(.lockAppLastDate)
            try! lastAuthDateProperty.set(newValue: SettingsPropertyValue(UInt32(newValue.timeIntervalSinceReferenceDate)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lockView = AppLockView()
        self.lockView.onReauthRequested = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.localAuthenticationCancelled = false
            self.localAuthenticationNeeded = true
            self.showUnlockIfNeeded()
        }
        
        self.view.addSubview(self.lockView)
        
        constrain(self.view, self.lockView) { view, lockView in
            lockView.edges == view.edges
        }
        
        self.showUnlockIfNeeded()
        
        self.resignKeyboardIfNeeded()
    }
    
    fileprivate func resignKeyboardIfNeeded() {
        if self.dimContents {
            delay(1) {
                UIApplication.shared.keyWindow?.endEditing(true)
            }
        }
    }
    
    fileprivate func showUnlockIfNeeded() {
        if self.appLockActive && self.localAuthenticationNeeded {
            self.dimContents = true
        
            if self.localAuthenticationCancelled {
                self.lockView.showReauth = true
            }
            else {
                self.lockView.showReauth = false
                self.requireLocalAuthenticationIfNeeded { grantedOptional in
                    
                    let granted = grantedOptional ?? true
                    
                    self.dimContents = !granted
                    self.localAuthenticationCancelled = !granted
                    self.localAuthenticationNeeded = !granted
                }
            }
        }
        else {
            self.lockView.showReauth = false
            self.dimContents = false
        }
    }

    /// @param callback confirmation; if the auth is not needed or is not possible on the current device called with '.none'
    func requireLocalAuthenticationIfNeeded(with callback: @escaping (Bool?)->()) {
        guard #available(iOS 9.0, *), self.appLockActive else {
            callback(.none)
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
        else {
            DDLogError("Local authentication error: \(error?.localizedDescription)")
            callback(.none)
        }
    }
}

extension AppLockViewController: UIApplicationDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        if self.appLockActive {
            self.dimContents = true
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if !self.localAuthenticationNeeded {
            self.lastUnlockedDate = Date()
        }
        
        self.localAuthenticationNeeded = true
        if self.appLockActive {
            self.dimContents = true
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.showUnlockIfNeeded()
        self.resignKeyboardIfNeeded()
    }
}
