//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension AuthenticationCoordinator: LoginDelegate {
    
    func loginCodeRequestDidFail(_ error: NSError) {
        eventResponderChain.handleEvent(ofType: .authenticationFailure(error as NSError))
    }
    
    /// Invoked when requesting a login code succeded
    func loginCodeRequestDidSucceed() {
        eventResponderChain.handleEvent(ofType: .loginCodeAvailable)
    }
    
    /// Invoked when the authentication failed, or when the cookie was revoked
    func authenticationDidFail(_ error: NSError) {
        eventResponderChain.handleEvent(ofType: .authenticationFailure(error as NSError))
    }

    /// Invoked when the authentication has proven invalid
    func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        authenticationDidFail(error)
    }
    
    /// Invoked when the authentication succeeded and the user now has a valid
    func authenticationDidSucceed() {
        log.info("Received \"authentication did succeed\" event. Ignoring, waiting for client registration event.")
    }

    /// Invoked when we have provided correct credentials and have an opportunity to import backup
    func authenticationReadyToImportBackup(existingAccount: Bool) {
        addedAccount = !existingAccount
        eventResponderChain.handleEvent(ofType: .backupReady(existingAccount))
    }
    
    /// Invoked when a client is successfully registered
    func clientRegistrationDidSucceed(accountId: UUID) {
        eventResponderChain.handleEvent(ofType: .clientRegistrationSuccess)
    }

    /// Invoked when the client failed to register.
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        eventResponderChain.handleEvent(ofType: .clientRegistrationError(error, accountId))
    }
}
