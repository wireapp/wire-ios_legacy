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

extension SessionManager {
    @objc static var shared : SessionManager? {
        return AppDelegate.shared().sessionManager
    }
    
    // Maximum number of accounts allowed to be signed into the app.
    public static let maxAccounts = 3
    
    func logoutAndDeleteCurrentAccount() {
        guard let selectedAccount = self.accountManager.selectedAccount else {
            fatal("No session manager and selected account to log out from")
        }
        
        guard let sharedContainerURL = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            preconditionFailure("Unable to get shared container URL")
        }
        
        let selectedAccountID = selectedAccount.userIdentifier
        
        self.logoutCurrentSession(deleteCookie: true)
        self.accountManager.remove(selectedAccount)
        
        
        try! FileManager.default.removeItem(at: StorageStack.accountFolder(accountIdentifier: selectedAccountID, applicationContainer: sharedContainerURL))
        
        if let otherAccount = self.accountManager.accounts.first {
            self.accountManager.select(otherAccount)
        }
    }
}
