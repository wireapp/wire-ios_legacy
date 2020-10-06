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

protocol AppStateCalculatorDelegate: class {
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: (() -> Void)?)
}

class AppStateCalculator: SessionManagerDelegate {
    
    // MARK - Public Property
    weak var delegate: AppStateCalculatorDelegate?
    
    // MARK - Private Property
    private var loadingAccount : Account?
    private var databaseEncryptionObserverToken: Any? = nil
    
    func sessionManagerWillLogout(error: Error?,
                                  userSessionCanBeTornDown: (() -> Void)?) {
        databaseEncryptionObserverToken = nil
        let appState: AppState = .unauthenticated(error: error as NSError?)
        delegate?.appStateCalculator(self,
                                     didCalculate: appState,
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
        let appState: AppState = .unauthenticated(error: authenticationError)
        delegate?.appStateCalculator(self,
                                     didCalculate: appState,
                                     completion: nil)
    }
        
    func sessionManagerDidBlacklistCurrentVersion() {
        delegate?.appStateCalculator(self,
                                     didCalculate: .blacklisted,
                                     completion: nil)
    }
    
    func sessionManagerDidBlacklistJailbrokenDevice() {
        delegate?.appStateCalculator(self,
                                     didCalculate: .jailbroken,
                                     completion: nil)
    }
    
    func sessionManagerWillMigrateLegacyAccount() {
        delegate?.appStateCalculator(self,
                                     didCalculate: .migrating,
                                     completion: nil)
    }
    
    func sessionManagerWillMigrateAccount(_ account: Account) {
        guard account == loadingAccount else { return }
        delegate?.appStateCalculator(self,
                                     didCalculate: .migrating,
                                     completion: nil)
    }
    
    func sessionManagerWillOpenAccount(_ account: Account,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        databaseEncryptionObserverToken = nil
        loadingAccount = account
        let appState: AppState = .loading(account: account,
                                          from: SessionManager.shared?.accountManager.selectedAccount)
        delegate?.appStateCalculator(self,
                                     didCalculate: appState,
                                     completion: userSessionCanBeTornDown)
    }
    
    func sessionManagerActivated(userSession: ZMUserSession) {
        userSession.checkIfLoggedIn { [weak self] loggedIn in
            guard
                loggedIn,
                let strongRef = self
            else {
                return
            }
            
            self?.loadingAccount = nil
            
            // NOTE: we don't enter the unauthenticated appstate here if we are not logged in
            //       because we will receive `sessionManagerDidLogout()` with an auth error
            let appState: AppState = .authenticated(completedRegistration: false,
                                                    databaseIsLocked: userSession.isDatabaseLocked)
            strongRef.delegate?.appStateCalculator(strongRef,
                                                   didCalculate: appState,
                                                   completion: nil)
        }
        
        databaseEncryptionObserverToken = userSession.registerDatabaseLockedHandler({ [weak self] isDatabaseLocked in
            guard let strongRef = self else {
                return
            }
            
            let appState: AppState = .authenticated(completedRegistration: false,
                                                    databaseIsLocked: isDatabaseLocked)
            strongRef.delegate?.appStateCalculator(strongRef,
                                                   didCalculate: appState,
                                                   completion: nil)
        })
    }
}
