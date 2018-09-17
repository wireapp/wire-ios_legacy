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
import WireExtensionComponents

private let zmLog = ZMSLog(tag: "UI")

extension Notification.Name {
    static let appUnlocked = Notification.Name("AppUnlocked")
}

@objcMembers final class AppLockViewController: UIViewController {
    fileprivate var lockView: AppLockView!
    fileprivate static let authenticationPersistancePeriod: TimeInterval = 10
    fileprivate var localAuthenticationCancelled: Bool = false
    fileprivate var localAuthenticationNeeded: Bool = true

    fileprivate var dimContents: Bool = false {
        didSet {
            self.view.isHidden = !self.dimContents
        }
    }
    
    static let shared = AppLockViewController()

    static var isLocked: Bool {
        return shared.dimContents
    }

    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockViewController.applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockViewController.applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockViewController.applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: .none)
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
        
        self.dimContents = false
    }
    
    fileprivate func resignKeyboardIfNeeded() {
        if self.dimContents {
            self.resignKeyboard()
        }
    }
    
    fileprivate func resignKeyboard() {
        delay(1) {
            UIApplication.shared.keyWindow?.endEditing(true)
        }
    }
    
    fileprivate func showUnlockIfNeeded() {
        if AppLock.isActive && self.localAuthenticationNeeded {
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
        guard AppLock.isActive else {
            callback(.none)
            return
        }
        
        let lastAuthDate = AppLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        if timeSinceAuth >= 0 && timeSinceAuth < type(of: self).authenticationPersistancePeriod {
            callback(true)
            return
        }
        
        AppLock.evaluateAuthentication(description: "self.settings.privacy_security.lock_app.description".localized) { (success, error) in
            DispatchQueue.main.async {
                callback(success)
                if let success = success, success {
                    AppLock.lastUnlockedDate = Date()
                    NotificationCenter.default.post(name: .appUnlocked, object: self, userInfo: nil)

                } else {
                    zmLog.error("Local authentication error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
}

// MARK: - Application state observators

extension AppLockViewController {
    @objc func applicationWillResignActive() {
        if AppLock.isActive {
            self.resignKeyboard()
            self.dimContents = true
        }
    }
    
    @objc func applicationDidEnterBackground() {
        if !self.localAuthenticationNeeded {
            AppLock.lastUnlockedDate = Date()
        }

        self.localAuthenticationCancelled = false

        self.localAuthenticationNeeded = true
        if AppLock.isActive {
            self.dimContents = true
        }
    }
    
    @objc func applicationDidBecomeActive() {
        self.showUnlockIfNeeded()
    }
}
