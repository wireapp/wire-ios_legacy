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

typealias AppLockInteractorUserSession = UserSessionVerifyPasswordInterface & UserSessionEncryptionAtRestInterface

protocol AppLockInteractorInput: class {
    var isCustomPasscodeNotSet: Bool { get }
    func evaluateAuthentication(description: String)
    func verify(password: String)
    func verify(customPasscode: String)
}

protocol AppLockInteractorOutput: class {
    func authenticationEvaluated(with result: AppLock.AuthenticationResult)
    func passwordVerified(with result: VerifyPasswordResult?)
}

final class AppLockInteractor {
    weak var output: AppLockInteractorOutput?
    
    // For tests
    var appLock: AppLock.Type = AppLock.self
    var dispatchQueue: DispatchQueue = DispatchQueue.main
    var _userSession: AppLockInteractorUserSession?
    
    // Workaround because accessing `ZMUserSession.shared()` crashes
    // if done at init (AppRootViewController won't be instantianted)
    private var userSession: AppLockInteractorUserSession? {
        return _userSession ?? ZMUserSession.shared()
    }
    
    private var isDatabaseLocked: Bool
    
    init(isDatabaseLocked: Bool) {
        self.isDatabaseLocked = isDatabaseLocked
    }
}

// MARK: - Interface
extension AppLockInteractor: AppLockInteractorInput {
    var isCustomPasscodeNotSet: Bool {
        return AppLock.isCustomPasscodeNotSet
    }
    
    func evaluateAuthentication(description: String) {
        appLock.evaluateAuthentication(scenario: authenticationScenario,
                                       description: description.localized) { [weak self] result, context in
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
            appLock.persistBiometrics()
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
    
}

// MARK: - Helpers
extension AppLockInteractor {
    
    private var authenticationScenario: AppLock.AuthenticationScenario {
        if isDatabaseLocked {
            return .databaseLock
        } else {
            return .screenLock(requireBiometrics: AppLock.rules.useBiometricsOrAccountPassword,
                               grantAccessIfPolicyCannotBeEvaluated: !AppLock.rules.forceAppLock)
        }
    }
    
    private func notifyPasswordVerified(with result: VerifyPasswordResult?) {
        dispatchQueue.async { [weak self] in
            self?.output?.passwordVerified(with: result)
        }
    }
    
}
