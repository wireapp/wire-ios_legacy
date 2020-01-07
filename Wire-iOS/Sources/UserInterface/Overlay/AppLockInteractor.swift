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

protocol AppLockInteractorInput: class {
    var isLockTimeoutReached: Bool { get }
    func evaluateAuthentication(description: String)
    func verify(password: String)
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
    
    init() {
        VerifyPasswordRequestStrategy.addPasswordVerifiedObserver(self, selector: #selector(passwordVerified(with:)))
    }
}

// MARK: - Interface
extension AppLockInteractor: AppLockInteractorInput {
    var isLockTimeoutReached: Bool {
        let lastAuthDate = appLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        if timeSinceAuth >= 0 && timeSinceAuth < Double(appLock.rules.appLockTimeout) {
            return false
        }
        return true
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
        ZMUserSession.shared()?.enqueueChanges {
            // Will send .passwordVerified notification when completed
            VerifyPasswordRequestStrategy.triggerPasswordVerification(with: password)
        }
    }
}

// MARK: - Notification Observer
extension AppLockInteractor {
    @objc private func passwordVerified(with notification: Notification) {
        guard let result = notification.userInfo?[VerifyPasswordRequestStrategy.verificationResultKey] as? VerifyPasswordResult else {
            notifyPasswordVerified(with: nil)
            return
        }
        notifyPasswordVerified(with: result)
        if case .validated = result {
            appLock.persistBiometrics()
        }
    }
    
    private func notifyPasswordVerified(with result: VerifyPasswordResult?) {
        self.dispatchQueue.async { [weak self] in
            self?.output?.passwordVerified(with: result)
        }
    }
}
