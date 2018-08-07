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

/**
 * Provides and asks for context when registering users.
 */

protocol AuthenticationCoordinatorDelegate: class {

    /**
     * The coordinator finished authenticating the user.
     *
     * - parameter registered: Whether the current user was registered (`true`),
     * or simply logged in (`false`).
     */

    func userAuthenticationDidComplete(registered: Bool)

    /**
     * Whether the authenticated user was registered on this device.
     *
     * - returns: `true` if the user was registered on this device, `false` otherwise.
     */

    func authenticatedUserWasRegisteredOnThisDevice() -> Bool

    /**
     * Whether the authenticated user needs an e-mail address to register their client.
     *
     * - returns: `true` if the user needs to add an e-mail, `false` otherwise.
     */

    func authenticatedUserNeedsEmailCredentials() -> Bool

    /**
     * The authentication coordinator requested the shared user session.
     * - returns: The shared user session, if any.
     */

    func authenticationCoordinatorRequestedSharedUserSession() -> ZMUserSession?

    /**
     * The authentication coordinator requested the shared user profile.
     * - returns: The shared user profile, if any.
     */

    func authenticationCoordinatorRequestedSelfUserProfile() -> UserProfile?

    /**
     * The authentication coordinator requested the shared user.
     * - returns: The shared user, if any.
     */

    func authenticationCoordinatorRequestedSelfUser() -> ZMUser?

    /**
     * The authentication coordinator requested the number of accounts.
     * - returns: The number of currently logged in accounts.
     */

    func authenticationCoordinatorRequestedNumberOfAccounts() -> Int

}
