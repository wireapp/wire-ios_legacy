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

final class AppStateController : NSObject {

    /**
     * The possible states of authentication.
     */

    enum AuthenticationState {
        /// The user is not logged in.
        case loggedOut

        /// The user logged in. This contains a flag to check if the account is new in the database.
        case loggedIn(addedAccount: Bool)

        /// The state is not determnined yet. This is the default, until we hear about the state from the session manager.
        case undetermined
    }
    
    private(set) var appState : AppState = .headless
    private(set) var lastAppState : AppState = .headless
    weak var delegate : AppStateControllerDelegate? = nil
    
    fileprivate var isBlacklisted = false
    fileprivate var isJailbroken = false
    fileprivate var hasEnteredForeground = false
    fileprivate var isMigrating = false
    fileprivate var loadingAccount : Account?
    fileprivate var authenticationError : NSError?
    fileprivate var isRunningTests = ProcessInfo.processInfo.isRunningTests
    var isRunningSelfUnitTest = false

    /// The state of authentication.
    fileprivate(set) var authenticationState: AuthenticationState = .undetermined
    
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
            return .blacklisted(jailbroken: false)
        }
        
        if isJailbroken {
            return .blacklisted(jailbroken: true)
        }
        
        if let account = loadingAccount {
            return .loading(account: account, from: SessionManager.shared?.accountManager.selectedAccount)
        }

        switch authenticationState {
        case .loggedIn(let addedAccount):
            return .authenticated(completedRegistration: addedAccount)
        case .loggedOut:
            return .unauthenticated(error: authenticationError)
        case .undetermined:
            return .headless
        }
    }
    
    func updateAppState(completion: (() -> Void)? = nil) {
        let newAppState = calculateAppState()
        
        switch (appState, newAppState) {
        case (_, .unauthenticated):
            break
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
            notifyTransition()
        } else {
            completion?()
        }
    }
    
    private func notifyTransition() {
        NotificationCenter.default.post(name: AppStateController.appStateDidTransition,
                                        object: nil,
                                        userInfo: [AppStateController.appStateKey: appState])
    }

}

extension AppStateController : SessionManagerDelegate {
    
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        authenticationError = error as NSError?
        authenticationState = .loggedOut

        updateAppState {
            userSessionCanBeTornDown?()
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
        authenticationState = .loggedOut
        updateAppState()
    }
        
    func sessionManagerDidBlacklistCurrentVersion() {
        isBlacklisted = true
        updateAppState()
    }
    
    func sessionManagerDidBlacklistJailbrokenDevice() {
        isJailbroken = true
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

            self?.authenticationState = .loggedIn(addedAccount: false)
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
        guard let emailAddress = selfUser?.emailAddress else { return false }
        return emailAddress.isEmpty
    }

    var sharedUserSession: ZMUserSession? {
        return ZMUserSession.shared()
    }

    var selfUserProfile: UserProfileUpdateStatus? {
        return sharedUserSession?.userProfile as? UserProfileUpdateStatus
    }

    var selfUser: UserType? {
        return ZMUserSession.shared()?.selfUser
    }

    var numberOfAccounts: Int {
        return SessionManager.numberOfAccounts
    }

    func userAuthenticationDidComplete(addedAccount: Bool) {
        authenticationState = .loggedIn(addedAccount: addedAccount)
        updateAppState()
    }
    
}

extension AppStateController {
    static let appStateDidTransition = Notification.Name(rawValue: "AppStateDidTransitionNotification")
    static let appStateKey = "AppState"
}
