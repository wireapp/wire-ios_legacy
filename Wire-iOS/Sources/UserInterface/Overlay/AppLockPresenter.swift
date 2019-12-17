//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension Notification.Name {
    static let appUnlocked = Notification.Name("AppUnlocked")
}

protocol AppLockUserInterface: class {
    func presentRequestPasswordController(with message: String, callback: @escaping RequestPasswordController.Callback)
    func setLoadingActivity(visible: Bool)
    func setContents(dimmed: Bool)
    func setReauth(visible: Bool)
}

enum AuthenticationState {
    case needed
    case cancelled
    case authenticated
    case pendingPassword
    
    func needAuthentication() -> Bool {
        guard AppLock.isActive else { return false }
        switch self {
        case .cancelled, .needed, .pendingPassword:
            return true
        case .authenticated:
            return false
        }
    }
    
    mutating func update(with result: AppLock.AuthenticationResult) {
        switch result {
        case .denied:
            self = .cancelled
        case .needAccountPassword:
            self = .pendingPassword
        default:
            break
        }
    }
}

class AppLockPresenter {
    weak var userInterface: AppLockUserInterface?
    private var authenticationState: AuthenticationState
    
    init(userInterface: AppLockUserInterface) {
        self.userInterface = userInterface
        authenticationState = .needed
        addApplicationStateObservers()
        VerifyPasswordRequestStrategy.addPasswordVerifiedObserver(self, selector: #selector(passwordVerified(with:)))
    }
    
    func requireAuthentication() {
        authenticationState = .needed
        requireAuthenticationIfNeeded()
    }
    
    private func requireAuthenticationIfNeeded() {
        guard AppLock.isActive, isLockTimeoutReached else {
            setContents(dimmed: false)
            return
        }
        switch authenticationState {
        case .needed, .authenticated:
            authenticationState = .needed
            setContents(dimmed: true)
            evaluateAuthentication()
        case .cancelled:
            setContents(dimmed: true, withReauth: true)
        default:
            break
        }
    }
}

// MARK: Auth helpers for Biometrics
extension AppLockPresenter {
    
    // Service
    private var isLockTimeoutReached: Bool {
        let lastAuthDate = AppLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        if timeSinceAuth >= 0 && timeSinceAuth < Double(AppLock.rules.appLockTimeout) {
            return false
        }
        return true
    }
    
    // TODO: Find a better name
    private func evaluateAuthentication() {
        AppLock.evaluateAuthentication(description: "self.settings.privacy_security.lock_app.description".localized) { result in
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                self.authenticationState.update(with: result)
                
                if case .needAccountPassword = result {
                    self.requestAccountPassword()
                }
                
                self.setContents(dimmed: result != .granted, withReauth: result == .unavailable)
                
                if case .granted = result {
                    self.appUnlocked()
                }
            }
        }
    }
}

// MARK: Account password helpers
extension AppLockPresenter {
    private func requestAccountPassword() {
        userInterface?.presentRequestPasswordController(with: "Generic Message") { password in
            DispatchQueue.main.async {
                guard let password = password, !password.isEmpty else {
                    self.authenticationState = .cancelled
                    self.setContents(dimmed: true, withReauth: true)
                    return
                }
                self.userInterface?.setLoadingActivity(visible: true)
                ZMUserSession.shared()?.enqueueChanges {
                    // Will call passwordVerified(with:) when completed
                    VerifyPasswordRequestStrategy.triggerPasswordVerification(with: password)
                }
            }
        }
    }
    
    @objc func passwordVerified(with notification: Notification) {
        userInterface?.setLoadingActivity(visible: false)
        guard let result = notification.userInfo?[VerifyPasswordRequestStrategy.verificationResultKey] as? VerifyPasswordResult else {
            self.setContents(dimmed: true, withReauth: true)
            return
        }
        switch result {
        case .validated:
            setContents(dimmed: false)
            appUnlocked()
            BiometricsState.persistCurrentState()
        default:
            requestAccountPassword()
            setContents(dimmed: true)
        }
    }
    
}

// MARK: Helpers
extension AppLockPresenter {
    
    private func setContents(dimmed: Bool, withReauth showReauth: Bool = false) {
        self.userInterface?.setContents(dimmed: dimmed)
        self.userInterface?.setReauth(visible: showReauth)
    }
    // TODO: Find better name
    private func appUnlocked() {
        authenticationState = .authenticated
        AppLock.lastUnlockedDate = Date()
        NotificationCenter.default.post(name: .appUnlocked, object: self, userInfo: nil)
    }
}

extension AppLockPresenter {
    func addApplicationStateObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockPresenter.applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockPresenter.applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppLockPresenter.applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: .none)
    }
    
    @objc func applicationWillResignActive() {
        if AppLock.isActive {
            userInterface?.setContents(dimmed: true)
        }
    }
    
    @objc func applicationDidEnterBackground() {
        if self.authenticationState == .authenticated {
            AppLock.lastUnlockedDate = Date()
        }
        if AppLock.isActive {
            userInterface?.setContents(dimmed: true)
        }
    }
    
    @objc func applicationDidBecomeActive() {
        requireAuthenticationIfNeeded()
    }
}
