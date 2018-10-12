//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireSystem

private let zmLog = ZMSLog(tag: "AppState")

protocol AppStateControllerDelegate : class {
    
    func appStateController(transitionedTo appState : AppState, transitionCompleted: @escaping () -> Void)
    
}

class AppStateController : NSObject {
    
    private(set) var appState : AppState = .headless
    private(set) var lastAppState : AppState = .headless
    private var authenticationObserverToken : ZMAuthenticationStatusObserver?
    public weak var delegate : AppStateControllerDelegate? = nil
    
    fileprivate var isBlacklisted = false
    fileprivate var isLoggedIn = false
    fileprivate var isLoggedOut = false
    fileprivate var hasEnteredForeground = false
    fileprivate var isMigrating = false
    fileprivate var hasCompletedRegistration = false
    fileprivate var loadingAccount : Account?
    fileprivate var authenticationError : NSError?
    fileprivate var isRunningTests = ProcessInfo.processInfo.isRunningTests
    var isRunningSelfUnitTest = false
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        appState = calculateAppState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func calculateAppState() -> AppState {
        guard !isRunningTests || isRunningSelfUnitTest else { return .headless }

        if !hasEnteredForeground {
            return .headless
        }
        
        if isMigrating {
            return .migrating
        }
        
        if isBlacklisted {
            return .blacklisted
        }
        
        if let account = loadingAccount {
            return .loading(account: account, from: SessionManager.shared?.accountManager.selectedAccount)
        }
        
        if isLoggedIn {
            return .authenticated(completedRegistration: hasCompletedRegistration)
        }
        
        if isLoggedOut {
            return .unauthenticated(error: authenticationError)
        }
        
        return .headless
    }
    
    func updateAppState(completion: (() -> Void)? = nil) {
        let newAppState = calculateAppState()
        
        switch (appState, newAppState) {
        case (_, .unauthenticated): break
        case (.unauthenticated, _):
            // only clear the error when transitioning out of the unauthenticated state
            authenticationError = nil
        default: break
        }
        
        if newAppState != appState {
            zmLog.debug("transitioning to app state: \(newAppState)")
            lastAppState = appState
            appState = newAppState
            delegate?.appStateController(transitionedTo: appState) {
                completion?()
            }
        } else {
            completion?()
        }
    }
    
}

extension AppStateController : SessionManagerDelegate {
    
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: @escaping () -> Void) {
        authenticationError = error as NSError?

        isLoggedIn = false
        isLoggedOut = true
        updateAppState {
            userSessionCanBeTornDown()
        }
    }
    
    func sessionManagerDidFailToLogin(account: Account?, error: Error) {
        let selectedAccount = SessionManager.shared?.accountManager.selectedAccount

        // We only care about the error if it concerns the selected account, or the loading account.
        if account != nil && (selectedAccount == account || loadingAccount == account) {
            authenticationError = error as NSError
        }
        // When the account is nil, we care about the error if there are some accounts in accountManager
        else if account == nil && SessionManager.shared?.accountManager.accounts.count > 0 {
            authenticationError = error as NSError
        }

        loadingAccount = nil
        isLoggedIn = false
        isLoggedOut = true
        updateAppState()
    }
        
    func sessionManagerDidBlacklistCurrentVersion() {
        isBlacklisted = true
        updateAppState()
    }
    
    func sessionManagerWillMigrateLegacyAccount() {
        isMigrating = true
        updateAppState()
    }
    
    func sessionManagerWillMigrateAccount(_ account: Account) {
        guard account == loadingAccount else { return }
        
        isMigrating = true
        updateAppState()
    }
    
    func sessionManagerWillOpenAccount(_ account: Account, userSessionCanBeTornDown: @escaping () -> Void) {
        loadingAccount = account
        updateAppState { 
            userSessionCanBeTornDown()
        }
    }
    
    func sessionManagerActivated(userSession: ZMUserSession) {        
        userSession.checkIfLoggedIn { [weak self] (loggedIn) in
            guard loggedIn else { return }
            
            // NOTE: we don't enter the unauthenticated state here if we are not logged in
            //       because we will receive `sessionManagerDidLogout()` with an auth error
            
            self?.isLoggedIn = true
            self?.isLoggedOut = !false
            self?.loadingAccount = nil
            self?.isMigrating = false
            self?.updateAppState()
        }
    }
    
}

extension AppStateController {
    
    @objc func applicationDidBecomeActive() {
        hasEnteredForeground = true
        updateAppState()
    }
    
}

extension AppStateController : AuthenticationCoordinatorDelegate {

    var authenticatedUserWasRegisteredOnThisDevice: Bool {
        return ZMUserSession.shared()?.registeredOnThisDevice == true
    }

    var authenticatedUserNeedsEmailCredentials: Bool {
        return ZMUser.selfUser()?.emailAddress?.isEmpty == true
    }

    var sharedUserSession: ZMUserSession? {
        return ZMUserSession.shared()
    }

    var selfUserProfile: UserProfileUpdateStatus? {
        return sharedUserSession?.userProfile as? UserProfileUpdateStatus
    }

    var selfUser: ZMUser? {
        return ZMUser.selfUser()
    }

    var numberOfAccounts: Int {
        return SessionManager.numberOfAccounts
    }

    func userAuthenticationDidComplete(registered: Bool) {
        isLoggedIn = true
        isLoggedOut = false
        hasCompletedRegistration = registered
        updateAppState()
    }
    
}
