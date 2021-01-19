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

extension MockUserType {

    class func createDefaultSelfUser() -> MockUserType {
        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        mockSelfUser.accentColorValue = .vividRed

        return mockSelfUser
    }

    /// Creates a self-user with the specified name and team membership.
    ///
    /// - Parameters:
    ///   - name: The name of the user.
    ///   - teamID: The ID of the team of the user, or `nil` if they're not on a team.
    ///
    /// - Returns: A configured mock user object to use as a self-user.

    class func createSelfUser(name: String, inTeam teamID: UUID? = nil) -> MockUserType {
        let user = createUser(name: name, inTeam: teamID)
        user.isSelfUser = true
        user.accentColorValue = .vividRed
        return user
    }

    /// Creates a connected user with the specified name and team membership.
    ///
    /// - Parameters:
    ///   - name: The name of the user.
    ///   - teamID: The ID of the team of the user, or `nil` if they're not on a team.
    ///
    /// - Returns: A configured mock user object to use as a user the self-user can interact with.

    class func createConnectedUser(name: String, inTeam teamID: UUID? = nil) -> MockUserType {
        let user = createUser(name: name, inTeam: teamID)
        user.isSelfUser = false
        user.isConnected = true
        user.emailAddress = teamID != nil ? "test@email.com" : nil
        user.accentColorValue = .brightOrange
        return user
    }

    /// Creates a user with the specified name and team membership.
    ///
    /// - Parameters:
    ///   - name: The name of the user.
    ///   - teamID: The ID of the team of the user, or `nil` if they're not on a team.
    ///
    /// - Returns: A standard mock user object with default values.

    class func createUser(name: String, inTeam teamID: UUID? = nil) -> MockUserType {
        let user = MockUserType()
        user.name = name
        user.displayName = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.teamIdentifier = teamID
        user.teamRole = teamID != nil ? .member : .none
        return user
    }

}
