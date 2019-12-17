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

private enum AuthenticationState {
    case needed
    case cancelled
    case authenticated
    case pendingPassword

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

// MARK: - AppLockPresenter
class AppLockPresenter {
    weak var userInterface: AppLockUserInterface?
    private var authenticationState: AuthenticationState
    private var appLockService: AppLockService
    
    init(userInterface: AppLockUserInterface) {
        self.userInterface = userInterface
        self.authenticationState = .needed
        self.appLockService = AppLockService()
        self.appLockService.output = self
        self.addApplicationStateObservers()
    }
    
    func requireAuthentication() {
        authenticationState = .needed
        requireAuthenticationIfNeeded()
    }
    
    private func requireAuthenticationIfNeeded() {
        guard AppLock.isActive, appLockService.isLockTimeoutReached else {
            setContents(dimmed: false)
            return
        }
        switch authenticationState {
        case .needed, .authenticated:
            authenticationState = .needed
            setContents(dimmed: true)
            appLockService.evaluateAuthentication()
        case .cancelled:
            setContents(dimmed: true, withReauth: true)
        case .pendingPassword:
            break
        }
    }
}

// MARK: - Account password helper
extension AppLockPresenter {
    private func requestAccountPassword(with message: String) {
        userInterface?.presentRequestPasswordController(with: message) { password in
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                guard let password = password, !password.isEmpty else {
                    self.authenticationState = .cancelled
                    self.setContents(dimmed: true, withReauth: true)
                    return
                }
                self.userInterface?.setLoadingActivity(visible: true)
                self.appLockService.verify(password: password)
            }
        }
    }
}

// MARK: - AppLockServiceOutput
extension AppLockPresenter: AppLockServiceOutput {
    func authenticationEvaluated(with result: AppLock.AuthenticationResult) {
        authenticationState.update(with: result)
        setContents(dimmed: result != .granted, withReauth: result == .unavailable)

        if case .needAccountPassword = result {
            requestAccountPassword(with: "Generic message")
        }
        
        if case .granted = result {
            appUnlocked()
        }
    }
    
    func passwordVerified(with result: VerifyPasswordResult?) {
        userInterface?.setLoadingActivity(visible: false)
        guard let result = result else {
            self.setContents(dimmed: true, withReauth: true)
            return
        }
        setContents(dimmed: result != .validated)
        switch result {
        case .validated:
            appUnlocked()
        case .denied, .unknown:
            requestAccountPassword(with: "Wrong password")
        case .timeout:
            requestAccountPassword(with: "Try again online")
        }
    }
}

// MARK: - App state observers
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

// MARK: - Helpers
extension AppLockPresenter {
    private func setContents(dimmed: Bool, withReauth showReauth: Bool = false) {
        self.userInterface?.setContents(dimmed: dimmed)
        self.userInterface?.setReauth(visible: showReauth)
    }
    
    private func appUnlocked() {
        authenticationState = .authenticated
        AppLock.lastUnlockedDate = Date()
        NotificationCenter.default.post(name: .appUnlocked, object: self, userInfo: nil)
    }
}
