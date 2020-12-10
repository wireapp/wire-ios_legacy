//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

enum AppState: Equatable {
    case headless
    case authenticated(completedRegistration: Bool, isDatabaseLocked: Bool)
    case unauthenticated(error : NSError?)
    case blacklisted
    case jailbroken
    case migrating
    case loading(account: Account, from: Account?)
}

protocol AppStateCalculatorDelegate: class {
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: @escaping () -> Void)
}

class AppStateCalculator {
    
    init() {
        setupApplicationNotifications()
    }
    
    deinit {
        removeObserverToken()
    }
    
    // MARK: - Public Property
    weak var delegate: AppStateCalculatorDelegate?
    var wasUnauthenticated: Bool {
        guard case .unauthenticated(_) = previousAppState else {
            return false
        }
        return true
    }

    // MARK: - Private Set Property
    private(set) var previousAppState: AppState = .headless
    private(set) var pendingAppState: AppState? = nil
    private(set) var appState: AppState = .headless {
        willSet {
            previousAppState = appState
        }
    }
    
    // MARK: - Private Property
    private var isDatabaseLocked: Bool = false
    private var observerTokens: [NSObjectProtocol] = []
    private var hasEnteredForeground: Bool = false
    
    // MARK: - Private Implementation
    private func transition(to appState: AppState,
                            completion: (() -> Void)? = nil) {
        guard hasEnteredForeground  else {
            pendingAppState = appState
            completion?()
            return
        }
        
        guard self.appState != appState else {
            completion?()
            return
        }
        
        self.appState = appState
        self.pendingAppState = nil
        ZMSLog(tag: "AppState").debug("transitioning to app state: \(appState)")
        delegate?.appStateCalculator(self, didCalculate: appState, completion: {
            completion?()
        })
    }
}

// MARK: - ApplicationStateObserving
extension AppStateCalculator: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }
    
    func removeObserverToken() {
        observerTokens.removeAll()
    }
    
    func applicationDidBecomeActive() {
        hasEnteredForeground = true
        transition(to: pendingAppState ?? appState)
    }
    
    func applicationDidEnterBackground() { }
    
    func applicationWillEnterForeground() { }
}

// MARK: - SessionManagerDelegate
extension AppStateCalculator: SessionManagerDelegate {
    func sessionManagerWillLogout(error: Error?,
                                  userSessionCanBeTornDown: (() -> Void)?) {
        let appState: AppState = .unauthenticated(error: error as NSError?)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerDidFailToLogin(error: Error?) {
        transition(to: .unauthenticated(error: error as NSError?))
    }
        
    func sessionManagerDidBlacklistCurrentVersion() {
        transition(to: .blacklisted)
    }
    
    func sessionManagerDidBlacklistJailbrokenDevice() {
        transition(to: .jailbroken)
    }
        
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        transition(to: .migrating, completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        let appState: AppState = .loading(account: account,
                                          from: selectedAccount)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerDidReportDatabaseLockChange(isLocked: Bool) {
        isDatabaseLocked = isLocked
        let appState: AppState = .authenticated(completedRegistration: false,
                                                isDatabaseLocked: isLocked)
        transition(to: appState)
    }
    
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) { }
}

// MARK: - AuthenticationCoordinatorDelegate
extension AppStateCalculator: AuthenticationCoordinatorDelegate {
    func userAuthenticationDidComplete(addedAccount: Bool) {
        let appState: AppState = .authenticated(completedRegistration: addedAccount,
                                                isDatabaseLocked: isDatabaseLocked)
        transition(to: appState)
    }
}

extension AppStateCalculator {
    // NOTA BENE: THIS MUST BE USED JUST FOR TESTING PURPOSE
    public func testHelper_setAppState(_ appState: AppState) {
        self.appState = appState
        transition(to: appState)
    }
}
