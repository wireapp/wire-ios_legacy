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
@testable import WireDataModel

class UserTypeTests_Materialize: ModelObjectsTests {

    func testThatWeCanMaterializeSearchUsers() {
        // given
        let userIDs = [UUID(), UUID(), UUID()]
        let searchUsers = userIDs.map({ createSearchUser(name: "John Doe", remoteIdentifier: $0) }) as [UserType]

        // when
        let materializedUsers = searchUsers.materialize(in: uiMOC)

        // then
        XCTAssertEqual(materializedUsers.count, 3)
        XCTAssertEqual(materializedUsers.map(\.remoteIdentifier), userIDs)
    }

    func testThatMaterializedTeamUserHasMembership_WhenBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let teamSearchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                          name: "Team",
                                          handle: "team",
                                          accentColor: .brightOrange,
                                          remoteIdentifier: UUID(),
                                          teamIdentifier: team.remoteIdentifier)
        uiMOC.saveOrRollback()

        // when
        let materializedUser = teamSearchUser.materialize(in: uiMOC)!

        // then
        XCTAssertTrue(materializedUser.isTeamMember)
    }

    func testThatSearchUserWithoutRemoteIdentifierIsIgnored() {
        // given
        let userIDs = [UUID(), UUID(), UUID()]
        let incompleteSearchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                                name: "Incomplete",
                                                handle: "incomplete",
                                                accentColor: .brightOrange,
                                                remoteIdentifier: nil)
        var searchUsers = userIDs.map({ createSearchUser(name: "John Doe", remoteIdentifier: $0) }) as [UserType]
        searchUsers.append(incompleteSearchUser)

        // when
        let materializedUsers = searchUsers.materialize(in: uiMOC)

        // then
        XCTAssertEqual(materializedUsers.count, 3)
        XCTAssertEqual(materializedUsers.map(\.remoteIdentifier), userIDs)
    }

    func testThatAlreadyMaterializedUsersAreUntouched() {
        // given
        let userIDs = [UUID(), UUID(), UUID()]
        let concreteUsers = userIDs.map({
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.remoteIdentifier = $0
            return user
        }) as [ZMUser]

        // when
        let materializedUsers = (concreteUsers as [UserType]).materialize(in: uiMOC)

        // then
        XCTAssertEqual(materializedUsers, concreteUsers)
    }

    // MARK: - Helpers

    func createSearchUser(name: String, remoteIdentifier: UUID = UUID()) -> ZMSearchUser {
        return ZMSearchUser(contextProvider: self.coreDataStack,
                            name: name.capitalized,
                            handle: name.lowercased(),
                            accentColor: .brightOrange,
                            remoteIdentifier: remoteIdentifier)
    }

}
