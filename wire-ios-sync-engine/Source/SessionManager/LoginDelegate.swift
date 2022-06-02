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

@objc
public protocol LoginDelegate: NSObjectProtocol {

    /// Invoked when requesting a login code for the phone failed
    @objc
    func loginCodeRequestDidFail(_ error: NSError)

    /// Invoked when requesting a login code succeded
    @objc
    func loginCodeRequestDidSucceed()

    /// Invoked when the authentication failed, or when the cookie was revoked
    @objc
    func authenticationDidFail(_ error: NSError)

    /// Invoked when the authentication has proven invalid
    @objc
    func authenticationInvalidated(_ error: NSError, accountId: UUID)

    /// Invoked when the authentication succeeded and the user now has a valid
    @objc
    func authenticationDidSucceed()

    /// Invoked when we have provided correct credentials and have an opportunity to import backup
    @objc
    func authenticationReadyToImportBackup(existingAccount: Bool)

    /// Invoked when a client is successfully registered
    @objc
    func clientRegistrationDidSucceed(accountId: UUID)

    /// Invoked when there was an error registering the client
    @objc
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID)

}
