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
    
    // MARK: - Private Set Property
    private(set) var previousAppState: AppState = .headless
    private(set) var pendingAppState: AppState? = nil
    private(set) var appState: AppState = .headless {
        willSet {
            previousAppState = appState
        }
    }
    
    // MARK: - Private Property
    private var loadingAccount: Account?
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
    
    func sessionManagerDidFailToLogin(account: Account?,
                                      from selectedAccount: Account?,
                                      error: Error) {
        var authenticationError: NSError?
        // We only care about the error if it concerns the selected account, or the loading account.
        if account != nil && (selectedAccount == account || loadingAccount == account) {
            authenticationError = error as NSError
        }
        // When the account is nil, we care about the error if there are some accounts in accountManager
        else if account == nil && selectedAccount != nil {
            authenticationError = error as NSError
        }

        loadingAccount = nil
        transition(to: .unauthenticated(error: authenticationError))
    }
        
    func sessionManagerDidBlacklistCurrentVersion() {
        transition(to: .blacklisted)
    }
    
    func sessionManagerDidBlacklistJailbrokenDevice() {
        transition(to: .jailbroken)
    }
    
    func sessionManagerWillMigrateLegacyAccount() {
        transition(to: .migrating)
    }
    
    func sessionManagerWillMigrateAccount(_ account: Account) {
        guard account == loadingAccount else { return }
        transition(to: .migrating)
    }
    
    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        loadingAccount = account
        let appState: AppState = .loading(account: account,
                                          from: selectedAccount)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerDidReportDatabaseLockChange(isLocked: Bool) {
        loadingAccount = nil
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
    
    // NOTA BENE: THIS MUST BE USED JUST FOR TESTING PURPOSE
    public func testHelper_setLoadingAccount(_ loadingAccount: Account) {
        self.loadingAccount = loadingAccount
    }
}
