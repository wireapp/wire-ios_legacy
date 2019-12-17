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

protocol AppLockServiceOutput: class {
    func authenticationEvaluated(with result: AppLock.AuthenticationResult)
    func passwordVerified(with result: VerifyPasswordResult?)
}

class AppLockService {
    weak var output: AppLockServiceOutput?
    
    init() {
        VerifyPasswordRequestStrategy.addPasswordVerifiedObserver(self, selector: #selector(passwordVerified(with:)))
    }
}

// MARK: - Interface
extension AppLockService {
    var isLockTimeoutReached: Bool {
        let lastAuthDate = AppLock.lastUnlockedDate
        
        // The app was authenticated at least N seconds ago
        let timeSinceAuth = -lastAuthDate.timeIntervalSinceNow
        if timeSinceAuth >= 0 && timeSinceAuth < Double(AppLock.rules.appLockTimeout) {
            return false
        }
        return true
    }
    
    func evaluateAuthentication() {
        AppLock.evaluateAuthentication(description: "self.settings.privacy_security.lock_app.description".localized) { result in
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
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
extension AppLockService {
    @objc private func passwordVerified(with notification: Notification) {
        guard let result = notification.userInfo?[VerifyPasswordRequestStrategy.verificationResultKey] as? VerifyPasswordResult else {
            output?.passwordVerified(with: nil)
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.output?.passwordVerified(with: result)
        }
        if case .validated = result {
            BiometricsState.persistCurrentState()
        }
    }
}
