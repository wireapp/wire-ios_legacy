//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "ZMClientRegistrationStatus")

extension ZMClientRegistrationStatus {
    @objc(didFailToRegisterClient:)
    public func didFail(toRegisterClient error: NSError) {
        zmLog.debug(#function)

        var error: NSError = error

        // we should not reset login state for client registration errors
        if error.code != ZMUserSessionErrorCode.needsPasswordToRegisterClient.rawValue && error.code != ZMUserSessionErrorCode.needsToRegisterEmailToRegisterClient.rawValue && error.code != ZMUserSessionErrorCode.canNotRegisterMoreClients.rawValue {
            emailCredentials = nil
        }

        if error.code == ZMUserSessionErrorCode.needsPasswordToRegisterClient.rawValue {
            // help the user by providing the email associated with this account
            error = NSError(domain: error.domain, code: error.code, userInfo: ZMUser.selfUser(in: managedObjectContext).loginCredentials.dictionaryRepresentation)
        }

        if error.code == ZMUserSessionErrorCode.needsPasswordToRegisterClient.rawValue || error.code == ZMUserSessionErrorCode.invalidCredentials.rawValue {
            // set this label to block additional requests while we are waiting for the user to (re-)enter the password
            needsToCheckCredentials = true
        }

        if error.code == ZMUserSessionErrorCode.canNotRegisterMoreClients.rawValue {
            // Wait and fetch the clients before sending the error
            isWaitingForUserClients = true
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        } else {
            registrationStatusDelegate?.didFailToRegisterSelfUserClient(error: error)
        }
    }

    @objc
    public func invalidateCookieAndNotify() {
        emailCredentials = nil
        cookieStorage.deleteKeychainItems()

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let outError = NSError.userSessionErrorWith(ZMUserSessionErrorCode.clientDeletedRemotely, userInfo: selfUser.loginCredentials.dictionaryRepresentation)
        registrationStatusDelegate?.didDeleteSelfUserClient(error: outError)
    }
}
