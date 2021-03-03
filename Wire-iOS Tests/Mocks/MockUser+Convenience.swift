//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest

/**
 * A class that facilitates writing snapshot tests with mock users.
 *
 * It allows you to create team and non-team users with appropriate initial
 * parameters.
 */

extension MockUser {

    /**
     * Creates a self-user with the specified name and team membership.
     * - parameter name: The name of the user.
     * - parameter teamID: The ID of the team of the user, or `nil` if they're not on a team.
     * - returns: A configured mock user object to use as a self-user.
     * - note: The accent color of a self user is red by default.
     */

    static func createSelfUser(name: String, inTeam teamID: UUID?) -> MockUser {
        let user = MockUser()
        user.name = name
        user.displayName = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.isSelfUser = true
        user.isTeamMember = teamID != nil
        user.teamIdentifier = teamID
        user.teamRole = teamID != nil ? .member : .none
        user.accentColorValue = .vividRed
        user.remoteIdentifier = UUID()
        return user
    }

    /**
     * Creates a connected user with the specified name and team membership.
     * - parameter name: The name of the user.
     * - parameter teamID: The ID of the team of the user, or `nil` if they're not on a team.
     * - returns: A configured mock user object to use as a user the self-user can interact with.
     * - note: The accent color of a self user is orange by default.
     */

    static func createConnectedUser(name: String, inTeam teamID: UUID?) -> MockUser {
        let user = MockUser()
        user.name = name
        user.displayName = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.isConnected = true
        user.isTeamMember = teamID != nil
        user.teamIdentifier = teamID
        user.teamRole = teamID != nil ? .member : .none
        user.accentColorValue = .brightOrange
        user.emailAddress = teamID != nil ? "test@email.com" : nil
        user.remoteIdentifier = UUID()
        return user
    }

}
