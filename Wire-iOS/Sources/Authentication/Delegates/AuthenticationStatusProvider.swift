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

/**
 * Provides context about the current authentication stack.
 */

public protocol AuthenticationStatusProvider: class {

    /**
     * Whether the authenticated user was registered on this device.
     *
     * - returns: `true` if the user was registered on this device, `false` otherwise.
     */

    var authenticatedUserWasRegisteredOnThisDevice: Bool { get }

    /**
     * Whether the authenticated user needs an e-mail address to register their client.
     *
     * - returns: `true` if the user needs to add an e-mail, `false` otherwise.
     */

    var authenticatedUserNeedsEmailCredentials: Bool { get }

    /**
     * The authentication coordinator requested the shared user session.
     * - returns: The shared user session, if any.
     */

    var sharedUserSession: ZMUserSession? { get }

    /**
     * The authentication coordinator requested the shared user profile.
     * - returns: The shared user profile, if any.
     */

    var selfUserProfile: UserProfileUpdateStatus? { get }

    /**
     * The authentication coordinator requested the shared user.
     * - returns: The shared user, if any.
     */

    var selfUser: UserType? { get }

    /**
     * The authentication coordinator requested the number of accounts.
     * - returns: The number of currently logged in accounts.
     */

    var numberOfAccounts: Int { get }

}

// MARK: AuthenticationStatusProvider Default Implementation
extension AuthenticationStatusProvider {
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
}

class AuthenticationStatusProviderObject: AuthenticationStatusProvider { }
