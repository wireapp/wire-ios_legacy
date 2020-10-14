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
    case authenticated(completedRegistration: Bool, databaseIsLocked: Bool)
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
    
    // MARK - Public Property
    weak var delegate: AppStateCalculatorDelegate?
    
    // MARK - Private Set Property
    private(set) var previousAppState: AppState = .headless
    private(set) var appState: AppState = .headless {
        willSet {
            previousAppState = appState
        }
    }
    
    // MARK - Private Property
    private var loadingAccount : Account?
    private var databaseEncryptionObserverToken: Any? = nil
    private var observerTokens: [NSObjectProtocol] = []
    
    // MARK - Private Implemetation
    private func transition(to appState: AppState,
                            force: Bool = false,
                            completion: (() -> Void)? = nil) {
        guard self.appState != appState || force else {
            completion?()
            return
        }
        
        self.appState = appState
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
        transition(to: appState, force: true)
    }
    
    func applicationDidEnterBackground() { }
    
    func applicationWillEnterForeground() { }
}

// MARK - SessionManagerDelegate
extension AppStateCalculator: SessionManagerDelegate {
    func sessionManagerWillLogout(error: Error?,
                                  userSessionCanBeTornDown: (() -> Void)?) {
        databaseEncryptionObserverToken = nil
        let appState: AppState = .unauthenticated(error: error as NSError?)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerDidFailToLogin(account: Account?, error: Error) {
        let selectedAccount = SessionManager.shared?.accountManager.selectedAccount
        var authenticationError: NSError?
        // We only care about the error if it concerns the selected account, or the loading account.
        if account != nil && (selectedAccount == account || loadingAccount == account) {
            authenticationError = error as NSError
        }
        // When the account is nil, we care about the error if there are some accounts in accountManager
        else if account == nil && SessionManager.shared?.accountManager.accounts.count > 0 {
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
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        databaseEncryptionObserverToken = nil
        loadingAccount = account
        let appState: AppState = .loading(account: account,
                                          from: SessionManager.shared?.accountManager.selectedAccount)
        transition(to: appState,
                   completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerActivated(userSession: ZMUserSession) {
        userSession.checkIfLoggedIn { [weak self] loggedIn in
            guard loggedIn else {
                return
            }
            self?.loadingAccount = nil
            
            // NOTE: we don't enter the unauthenticated appstate here if we are not logged in
            //       because we will receive `sessionManagerDidLogout()` with an auth error
            let appState: AppState = .authenticated(completedRegistration: false,
                                                    databaseIsLocked: userSession.isDatabaseLocked)
            self?.transition(to: appState)
        }
        
        databaseEncryptionObserverToken = userSession.registerDatabaseLockedHandler({ [weak self] isDatabaseLocked in
            let appState: AppState = .authenticated(completedRegistration: false,
                                                    databaseIsLocked: isDatabaseLocked)
            self?.transition(to: appState)
        })
    }
}

// MARK - AuthenticationCoordinatorDelegate
extension AppStateCalculator: AuthenticationCoordinatorDelegate {
    func userAuthenticationDidComplete(addedAccount: Bool) {
        let databaseIsLocked = ZMUserSession.shared()?.isDatabaseLocked ?? false
        let appState: AppState = .authenticated(completedRegistration: addedAccount,
                                                databaseIsLocked: databaseIsLocked)
        transition(to: appState)
    }
}
