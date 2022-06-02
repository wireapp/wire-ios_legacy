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

class ZMSearchUserTests_TeamUser: ModelObjectsTests {

    func testThatSearchUserIsRecognizedAsTeamMember_WhenBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                      name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightOrange,
                                      remoteIdentifier: UUID(),
                                      teamIdentifier: team.remoteIdentifier)

        // then
        XCTAssertTrue(searchUser.isTeamMember)
        XCTAssertTrue(searchUser.isConnected)
    }

    func testThatSearchUserIsNotRecognizedAsTeamMember_WhenNotBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                      name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightOrange,
                                      remoteIdentifier: UUID(),
                                      teamIdentifier: UUID())

        // then
        XCTAssertFalse(searchUser.isTeamMember)
        XCTAssertFalse(searchUser.isConnected)
    }

    func testThatOneToOneConversationIsCreated_WhenBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                      name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightOrange,
                                      remoteIdentifier: UUID(),
                                      teamIdentifier: team.remoteIdentifier)
        uiMOC.saveOrRollback()

        // then
        XCTAssertNotNil(searchUser.oneToOneConversation)
    }

    func testThatOneToOneConversationIsNotCreated_WhenNotBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                      name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightOrange,
                                      remoteIdentifier: UUID(),
                                      teamIdentifier: UUID())
        uiMOC.saveOrRollback()

        // then
        XCTAssertNil(searchUser.oneToOneConversation)
    }

    func testThatSearchUserCanBeUpdatedTeamMembershipDetails() {
        // given
        let creator = UUID()
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = ZMSearchUser(contextProvider: self.coreDataStack,
                                      name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightOrange,
                                      remoteIdentifier: UUID(),
                                      teamIdentifier: team.remoteIdentifier)

        // when
        searchUser.updateWithTeamMembership(permissions: .partner, createdBy: creator)

        // then
        XCTAssertEqual(searchUser.teamRole, .partner)
        XCTAssertEqual(searchUser.teamCreatedBy, creator)
    }

}
