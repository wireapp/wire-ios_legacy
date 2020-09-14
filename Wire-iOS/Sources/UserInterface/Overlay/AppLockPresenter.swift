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
import UIKit
import WireCommonComponents
import WireSyncEngine

extension Notification.Name {
    static let appUnlocked = Notification.Name("AppUnlocked")
}

protocol AppLockUserInterface: class {
    
    /// present an unlock screen (for input account passcode or custom passcode)
    /// - Parameters:
    ///   - message: message to show on unlock UI, it should be a member of `presentRequestPasswordController`
    ///   - callback: callback to return the inputed passcode
    func presentUnlockScreen(with message: String,
                             callback: @escaping RequestPasswordController.Callback)
    func dismissUnlockScreen()
    
    
    /// Present create passcode screen (when the user first time use the app after updating from a version not support passcode)
    func presentCreatePasscodeScreen(callback: ResultHandler?)
    
    func setSpinner(animating: Bool)
    func setContents(dimmed: Bool)
    func setReauth(visible: Bool)
}

enum AuthenticationState {
    case needed
    case cancelled
    case authenticated
    case pendingPassword

    fileprivate mutating func update(with result: AppLock.AuthenticationResult) {
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

struct AuthenticationMessageKey {
    static let accountPassword = "self.settings.privacy_security.lock_password.description.unlock"
    static let wrongPassword = "self.settings.privacy_security.lock_password.description.wrong_password"
    static let wrongOfflinePassword = "self.settings.privacy_security.lock_password.description.wrong_offline_password"
    static let deviceAuthentication = "self.settings.privacy_security.lock_app.description"
}

// MARK: - AppLockPresenter
final class AppLockPresenter {
    private weak var userInterface: AppLockUserInterface?
    private var authenticationState: AuthenticationState
    private var appLockInteractorInput: AppLockInteractorInput
    
    var dispatchQueue: DispatchQueue = DispatchQueue.main
    
    convenience init(userInterface: AppLockUserInterface) {
        let appLockInteractor = AppLockInteractor()
        self.init(userInterface: userInterface, appLockInteractorInput: appLockInteractor)
        appLockInteractor.output = self
    }
    
    init(userInterface: AppLockUserInterface,
         appLockInteractorInput: AppLockInteractorInput,
         authenticationState: AuthenticationState = .needed) {
        self.userInterface = userInterface
        self.appLockInteractorInput = appLockInteractorInput
        self.authenticationState = authenticationState
        self.addApplicationStateObservers()
    }
    
    func requireAuthentication() {
        authenticationState = .needed
        requireAuthenticationIfNeeded()
    }
    
    func requireAuthenticationIfNeeded() {
        guard appLockInteractorInput.isAuthenticationNeeded else {
            setContents(dimmed: false)
            return
        }
        switch authenticationState {
        case .needed, .authenticated:
            authenticationState = .needed
            setContents(dimmed: true)
            appLockInteractorInput.evaluateAuthentication(description: AuthenticationMessageKey.deviceAuthentication)
        case .cancelled:
            setContents(dimmed: true, withReauth: true)
        case .pendingPassword:
            break
        }
    }
}

// MARK: - Account password helper
extension AppLockPresenter {
    private func checkPassword(password: String) -> Bool {
        guard !password.isEmpty else {
            authenticationState = .cancelled
            setContents(dimmed: true, withReauth: true)
            return false
        }
        
        userInterface?.setSpinner(animating: true)
        
        return true
    }
    
    private func requestAccountPassword(with message: String) {
        userInterface?.presentUnlockScreen(with: message) { [weak self] password in
            guard let `self` = self else { return }
            self.dispatchQueue.async {

                guard let password = password,
                      self.checkPassword(password: password) else { return }

                if AppLock.rules.useCustomCodeInsteadOfAccountPassword {
                    self.appLockInteractorInput.verify(customPasscode: password)
                } else {
                    self.appLockInteractorInput.verify(password: password)
                }
            }
        }
    }
}

// MARK: - AppLockInteractorOutput
extension AppLockPresenter: AppLockInteractorOutput {
    
    func authenticationEvaluated(with result: AppLock.AuthenticationResult) {
        authenticationState.update(with: result)
        setContents(dimmed: result != .granted, withReauth: result == .unavailable)

        if case .needAccountPassword = result {
            // When upgrade form a version not support custom passcode, ask the user to create a new passcode
            if appLockInteractorInput.isCustomPasscodeNotSet {
                userInterface?.presentCreatePasscodeScreen(callback: { _ in
                    // user need to enter the newly created passcode after creation
                    self.setContents(dimmed: true, withReauth: true)
                })
            } else {
                requestAccountPassword(with: AuthenticationMessageKey.accountPassword)
            }
        }
        
        if case .granted = result {
            appUnlocked()
        }
    }
    
    func passwordVerified(with result: VerifyPasswordResult?) {
        userInterface?.setSpinner(animating: false)
        guard let result = result else {
            setContents(dimmed: true, withReauth: true)
            return
        }
        let authNeeded = appLockInteractorInput.isAuthenticationNeeded

        setContents(dimmed: result != .validated && authNeeded)

        switch result {
        case .validated:
            appUnlocked()
        case .denied, .unknown, .timeout:
            if authNeeded {
                requestAccountPassword(with: AuthenticationMessageKey.wrongPassword)
            } else {
                authenticationState = .needed
            }
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appStateDidTransition(_:)),
                                               name: AppStateController.appStateDidTransition,
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

    @objc func appStateDidTransition(_ notification: Notification) {
        guard let appState = notification.userInfo?[AppStateController.appStateKey] as? AppState else { return }
    
        appLockInteractorInput.appStateDidTransition(to: appState)
        switch appState {
        case .authenticated(completedRegistration: _):
            requireAuthenticationIfNeeded()
        default:
            setContents(dimmed: false)
        }
    }
}

// MARK: - Helpers
extension AppLockPresenter {
    private func setContents(dimmed: Bool,
                             withReauth showReauth: Bool = false) {
        userInterface?.setContents(dimmed: dimmed)
        userInterface?.setReauth(visible: showReauth)
    }
    
    private func appUnlocked() {
        userInterface?.dismissUnlockScreen()
        
        authenticationState = .authenticated
        AppLock.lastUnlockedDate = Date()
        NotificationCenter.default.post(name: .appUnlocked, object: self, userInfo: nil)
    }
}
