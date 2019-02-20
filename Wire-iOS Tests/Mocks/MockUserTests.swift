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

class MockUserTests: ZMSnapshotTestCase {

    /// The ID of the current team.
    var teamIdentifier: UUID!
    
    override func setUp() {
        super.setUp()
        teamIdentifier = UUID()
    }
    
    override func tearDown() {
        teamIdentifier = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /**
     * Creates a self-user with the specified name and team membership.
     * - parameter name: The name of the user.
     * - parameter inTeam: Whether the user is a member of the current team.
     * - returns: A configured mock user object to use as a self-user.
     * - note: The accent color of a self user is red by default.
     */
    
    func createSelfUser(name: String, inTeam: Bool) -> MockUser {
        let user = MockUser()
        user.name = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.isSelfUser = true
        user.isTeamMember = inTeam
        user.teamIdentifier = inTeam ? teamIdentifier : nil
        user.accentColorValue = .vividRed
        return user
    }

    /**
     * Creates a connected user with the specified name and team membership.
     * - parameter name: The name of the user.
     * - parameter inTeam: Whether the user is a member of a team.
     * - parameter overrideTeamIdentifier: The team ID to use if you don't want the created user
     * to be a member of the current team. If `inTeam` is `false`, this parameter is ignored.
     * - returns: A configured mock user object to use as a user the self-user can interact with.
     * - note: The accent color of a self user is red by default.
     */

    func createConnectedUser(name: String, inTeam: Bool, overrideTeamIdentifier: UUID? = nil) -> MockUser {
        let user = MockUser()
        user.name = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.isConnected = true
        user.isTeamMember = inTeam
        
        if inTeam {
            user.teamIdentifier = overrideTeamIdentifier ?? teamIdentifier
        } else {
            user.teamIdentifier = nil
        }
        
        user.accentColorValue = .brightOrange
        return user
    }
    
}
