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
import LocalAuthentication

typealias AppLockInteractorUserSession = UserSessionVerifyPasswordInterface & UserSessionEncryptionAtRestInterface & UserSessionAppLockInterface

protocol AppLockInteractorInput: class {
    var isCustomPasscodeNotSet: Bool { get }
    var isAuthenticationNeeded: Bool { get }
    var isDimmingScreenWhenInactive: Bool { get }
    var useCustomPasscode: Bool { get }
    var lastUnlockedDate: Date { get set }
    var needsToInformOfChange: Bool { get }
    func evaluateAuthentication(description: String)
    func verify(password: String)
    func verify(customPasscode: String)
    func appStateDidTransition(to newState: AppState)
}

protocol AppLockInteractorOutput: class {
    func authenticationEvaluated(with result: AppLockController.AuthenticationResult)
    func passwordVerified(with result: VerifyPasswordResult?)
}

final class AppLockInteractor {
    weak var output: AppLockInteractorOutput?
    
    // For tests
    var dispatchQueue: DispatchQueue = DispatchQueue.main
    var _userSession: AppLockInteractorUserSession?
    
    // Workaround because accessing `ZMUserSession.shared()` crashes
    // if done at init (RootViewController won't be instantianted)
    private var userSession: AppLockInteractorUserSession? {
        return _userSession ?? ZMUserSession.shared()
    }
    
    var appState: AppState?

    var appLock: AppLockType? {
        return userSession?.appLockController
    }

    var isAppLockActive: Bool {
        return appLock?.isActive ?? false
    }

    var useCustomPasscode: Bool {
        return true//appLock?.config.useCustomCodeInsteadOfAccountPassword == true
    }

    var lastUnlockedDate: Date {
        get { userSession?.appLockController.lastUnlockedDate ?? Date() }
        set {
            if var session = userSession {
                session.appLockController.lastUnlockedDate = newValue
            }
        }
    }

    var isAppLockForced: Bool {
        return appLock?.config.forceAppLock ?? false
    }

    var shouldUseBiometricsOrAccountPassword: Bool {
        return appLock?.config.useBiometricsOrAccountPassword ?? false
    }

    var timeout: UInt {
        return appLock?.config.appLockTimeout ?? .max
    }

}

// MARK: - Interface
extension AppLockInteractor: AppLockInteractorInput {
    var isCustomPasscodeNotSet: Bool {
        return appLock?.isCustomPasscodeNotSet ?? false
    }
    
    var needsToInformOfChange: Bool {
        return false //appLock?.needsToInformUserOfFeatureChange ?? false
    }
    
    var isAuthenticationNeeded: Bool {
        let screenLockIsActive = isAppLockActive && isLockTimeoutReached && isAppStateAuthenticated
        
        return screenLockIsActive || isDatabaseLocked
    }
    
    var isDimmingScreenWhenInactive: Bool {
        return isAppLockActive || userSession?.encryptMessagesAtRest == true
    }
    
    func evaluateAuthentication(description: String) {
        appLock?.evaluateAuthentication(description: description.localized) { [weak self] result, context in
            guard let `self` = self else { return }
                        
            self.dispatchQueue.async {
                if case .granted = result {
                    try? self.userSession?.unlockDatabase(with: context)
                }
                
                self.output?.authenticationEvaluated(with: result)
            }
        }
    }
    
    private func processVerifyResult(result: VerifyPasswordResult?) {
        notifyPasswordVerified(with: result)
        if case .validated = result {
            appLock?.persistBiometrics()
        }
    }
    
    func verify(customPasscode: String) {
        
        let result: VerifyPasswordResult
        
        if let data: Data = Keychain.fetchPasscode() {
            result = customPasscode == String(data: data, encoding: .utf8) ? .validated : .denied
        } else {
            result = .unknown
        }
        
        processVerifyResult(result: result)
    }

    func verify(password: String) {
        userSession?.verify(password: password) { [weak self] result in
            self?.processVerifyResult(result: result)
        }
    }
    
    func appStateDidTransition(to newState: AppState) {
        if let state = appState,
            case AppState.unauthenticated(error: _) = state,
            case AppState.authenticated(completedRegistration: _) = newState {
            lastUnlockedDate = Date()
        }
        appState = newState
    }
}

// MARK: - Helpers
extension AppLockInteractor {
    
    private var authenticationScenario: AppLockController.AuthenticationScenario {
        if isDatabaseLocked {
            return .databaseLock
        } else {
            return .screenLock(requireBiometrics: shouldUseBiometricsOrAccountPassword,
                               grantAccessIfPolicyCannotBeEvaluated: !isAppLockForced)
        }
    }
    
    private func notifyPasswordVerified(with result: VerifyPasswordResult?) {
        dispatchQueue.async { [weak self] in
            self?.output?.passwordVerified(with: result)
        }
    }
    
    private var isDatabaseLocked: Bool {
        guard let state = appState else { return false }
        if case AppState.authenticated(completedRegistration: _, isDatabaseLocked: let isDatabaseLocked) = state {
            return isDatabaseLocked
        }
        return false
    }
    
    private var isAppStateAuthenticated: Bool {
        guard let state = appState else { return false }
        if case AppState.authenticated(completedRegistration: _) = state {
            return true
        }
        return false
    }
    
    private var isLockTimeoutReached: Bool {
        let lastAuthDate = lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        let isWithinTimeoutWindow = (0..<Double(timeout)).contains(timeSinceAuth)
        return !isWithinTimeoutWindow
    }
}
