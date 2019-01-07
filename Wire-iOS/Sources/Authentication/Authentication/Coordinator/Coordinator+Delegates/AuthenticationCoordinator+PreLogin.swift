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

extension AuthenticationCoordinator: PreLoginAuthenticationObserver {

    /// Called when the authentication succeeds. We ignore this event, as
    /// we are waiting for the client registration event to fire to transition to the next step.
    func authenticationDidSucceed() {
        log.info("Received \"authentication did succeed\" event. Ignoring, waiting for client registration event.")
    }

    /// Called when the credentials could not be authenticated.
    func authenticationDidFail(_ error: NSError) {
        eventResponderChain.handleEvent(ofType: .authenticationFailure(error))
    }

    /// Called when the backup is ready to be imported.
    func authenticationReadyToImportBackup(existingAccount: Bool) {
        eventResponderChain.handleEvent(ofType: .backupReady(existingAccount))
    }

    /// Called when the phone login called became available.
    func loginCodeRequestDidSucceed() {
        eventResponderChain.handleEvent(ofType: .loginCodeAvailable)
    }

    /// Called when the phone login code couldn't be requested manually.
    func loginCodeRequestDidFail(_ error: NSError) {
        eventResponderChain.handleEvent(ofType: .authenticationFailure(error))
    }

}
