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

typealias AppLockInteractorUserSession = UserSessionEncryptionAtRestInterface & UserSessionAppLockInterface

protocol AppLockInteractorInput: class {
    var needsToCreateCustomPasscode: Bool { get }
    var isCustomPasscodeNotSet: Bool { get }
    var isDimmingScreenWhenInactive: Bool { get }
    var needsToNotifyUser: Bool { get set }
    func evaluateAuthentication(description: String)
    func verify(customPasscode: String)
    func appStateDidTransition(to newState: AppState)
}

protocol AppLockInteractorOutput: class {
    func authenticationEvaluated(with result: AppLockController.AuthenticationResult)
    func passwordVerified(with result: VerifyPasswordResult?)
}

final class OldAppLockInteractor {

    // MARK: - Properties

    weak var output: AppLockInteractorOutput?
    
    // For tests
    var dispatchQueue: DispatchQueue = DispatchQueue.main

    var session: AppLockInteractorUserSession
    
    var appState: AppState?

    var appLock: AppLockType {
        return session.appLockController
    }

    var isAppLockActive: Bool {
        return appLock.isActive
    }

    var shouldUseBiometricsOrCustomPasscode: Bool {
        return appLock.requiresBiometrics
    }

    var needsToNotifyUser: Bool {
        get {
            return appLock.needsToNotifyUser
        }

        set {
            session.appLockController.needsToNotifyUser = newValue
        }
    }

    // MARK: - Life cycle

    init(session: AppLockInteractorUserSession) {
        self.session = session
    }

}

// MARK: - Interface
extension OldAppLockInteractor: AppLockInteractorInput {

    var needsToCreateCustomPasscode: Bool {
        return (AuthenticationType.current == .unavailable || shouldUseBiometricsOrCustomPasscode) && isCustomPasscodeNotSet
    }

    var isCustomPasscodeNotSet: Bool {
        return appLock.isCustomPasscodeNotSet
    }

    var isDimmingScreenWhenInactive: Bool {
        return isAppLockActive || session.encryptMessagesAtRest
    }
    
    func evaluateAuthentication(description: String) {
        appLock.evaluateAuthentication(scenario: authenticationScenario,
                                       description: description.localized) { [weak self] result, context in
            guard let `self` = self else { return }

            self.dispatchQueue.async {
                if case .granted = result, let context = context as? LAContext {
                    try? self.session.unlockDatabase(with: context)
                }
                
                self.output?.authenticationEvaluated(with: result)
            }
        }
    }
    
    private func processVerifyResult(result: VerifyPasswordResult?) {
        notifyPasswordVerified(with: result)
        if case .validated = result {
            // We need to communicate this unlocking with the app lock controller.
            appLock.persistBiometrics()
        }
    }
    
    func verify(customPasscode: String) {
        
        let result: VerifyPasswordResult
        
        if let data = appLock.fetchPasscode() {
            result = customPasscode == String(data: data, encoding: .utf8) ? .validated : .denied
        } else {
            result = .unknown
        }
        
        processVerifyResult(result: result)
    }

    func appStateDidTransition(to newState: AppState) {
        if let state = appState,
            case AppState.unauthenticated(error: _) = state,
            case AppState.authenticated(completedRegistration: _) = newState {
            //lastUnlockedDate = Date()
        }
        appState = newState
    }
}

// MARK: - Helpers
extension OldAppLockInteractor {
    
    private var authenticationScenario: AppLockController.AuthenticationScenario {
        if isDatabaseLocked {
            return .databaseLock
        } else {
            return .screenLock(requireBiometrics: shouldUseBiometricsOrCustomPasscode)
        }
    }
    
    private func notifyPasswordVerified(with result: VerifyPasswordResult?) {
        dispatchQueue.async { [weak self] in
            self?.output?.passwordVerified(with: result)
        }
    }
    
    private var isDatabaseLocked: Bool {
        return false
    }
    
    private var isAppStateAuthenticated: Bool {
        guard let state = appState else { return false }
        if case AppState.authenticated(completedRegistration: _) = state {
            return true
        }
        return false
    }

}
    
