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

protocol AppLockInteractorInput: class {
    var isAuthenticationNeeded: Bool { get }
    func evaluateAuthentication(description: String)
    func verify(password: String)
    func appStateDidTransition(to newState: AppState)
}

protocol AppLockInteractorOutput: class {
    func authenticationEvaluated(with result: AppLock.AuthenticationResult)
    func passwordVerified(with result: VerifyPasswordResult?)
}

class AppLockInteractor {
    weak var output: AppLockInteractorOutput?
    
    // For tests
    var appLock: AppLock.Type = AppLock.self
    var dispatchQueue: DispatchQueue = DispatchQueue.main
    var _userSession: UserSessionVerifyPasswordInterface?
    
    // Workaround because accessing `ZMUserSession.shared()` crashes
    // if done at init (AppRootViewController won't be instantianted)
    private var userSession: UserSessionVerifyPasswordInterface? {
        return _userSession ?? ZMUserSession.shared()
    }
    
    var appState: AppState?
}

// MARK: - Interface
extension AppLockInteractor: AppLockInteractorInput {
    var isAuthenticationNeeded: Bool {
        return appLock.isActive && isLockTimeoutReached && isAppStateAuthenticated
    }
    
    func evaluateAuthentication(description: String) {
        appLock.evaluateAuthentication(description: description.localized) { [weak self] result in
            guard let `self` = self else { return }
            self.dispatchQueue.async {
                self.output?.authenticationEvaluated(with: result)
            }
        }
    }
    
    func verify(password: String) {
        userSession?.verify(password: password) { [weak self] result in
            guard let `self` = self else { return }
            self.notifyPasswordVerified(with: result)
            if case .validated? = result {
                self.appLock.persistBiometrics()
            }
        }
    }
    
    func appStateDidTransition(to newState: AppState) {
        if let state = appState,
            case AppState.unauthenticated(error: _) = state,
            case AppState.authenticated(completedRegistration: _) = newState {
            AppLock.lastUnlockedDate = Date()
        }
        appState = newState
    }
}

// MARK: - Helpers
extension AppLockInteractor {
    private func notifyPasswordVerified(with result: VerifyPasswordResult?) {
        self.dispatchQueue.async { [weak self] in
            self?.output?.passwordVerified(with: result)
        }
    }
    
    private var isAppStateAuthenticated: Bool {
        guard let state = appState else { return false }
        if case AppState.authenticated(completedRegistration: _) = state {
            return true
        }
        return false
    }
    
    private var isLockTimeoutReached: Bool {
        let lastAuthDate = appLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        let isWithinTimeoutWindow = (0..<Double(appLock.rules.appLockTimeout)).contains(timeSinceAuth)
        return !isWithinTimeoutWindow
    }
}
