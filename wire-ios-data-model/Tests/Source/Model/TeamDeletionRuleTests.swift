//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import WireTesting
@testable import WireDataModel

class TeamDeletionRuleTests: BaseZMClientMessageTests {

    func testThatItDoesntDeleteConversationsWhichArePartOfATeamWhenTeamGetsDeleted() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let (uuid1, uuid2, uuid3) = (UUID.create(), UUID.create(), UUID.create())
        let conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.remoteIdentifier = uuid1
        let conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.remoteIdentifier = uuid2
        let conversation3 = ZMConversation.insertNewObject(in: uiMOC)
        conversation3.remoteIdentifier = uuid3

        conversation1.team = team
        conversation2.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(team.conversations, [conversation1, conversation2])

        // when
        uiMOC.delete(team)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertNotNil(ZMConversation.fetch(with: uuid1, in: uiMOC))
        XCTAssertNotNil(ZMConversation.fetch(with: uuid2, in: uiMOC))
        XCTAssertEqual(ZMConversation.fetch(with: uuid3, in: uiMOC), conversation3)
    }

    func testThatItDeletesMembersWhichArePartOfATeamWhenTeamGetsDeleted() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let member1 = Member.insertNewObject(in: uiMOC)
        let member2 = Member.insertNewObject(in: uiMOC)
        let member3 = Member.insertNewObject(in: uiMOC)

        member1.team = team
        member2.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(team.members, [member1, member2])

        // when
        uiMOC.delete(team)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then

        guard let members = uiMOC.executeFetchRequestOrAssert(NSFetchRequest(entityName: Member.entityName())) as? [Member] else {
            return XCTFail("No members fetched")
        }

        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(members.first, member3)
    }

    func testThatItDoesNotDeleteUsersOfMembersWhichArePartOfATeamWhenTeamGetsDeleted() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let member = Member.insertNewObject(in: uiMOC)
        let userId = UUID.create()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userId

        member.user = user
        member.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // when
        uiMOC.delete(team)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        let fetchedUser = ZMUser.fetch(with: userId, in: uiMOC)
        XCTAssertEqual(fetchedUser, user)
        XCTAssertNil(fetchedUser?.membership)
    }

    func testThatItDoesNotDeleteATeamWhenAMemberOfItGetsDeleted() {
        // given
        let uuid = UUID.create()
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = uuid
        let member = Member.insertNewObject(in: uiMOC)
        member.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(team.members, [member])

        // when
        uiMOC.delete(member)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        XCTAssertEqual(Team.fetch(with: uuid, in: uiMOC), team)
    }

    func testThatItDoesNotDeleteATeamWhenAConversationOfItGetsDeleted() {
        // given
        let uuid = UUID.create()
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = uuid
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(team.conversations, [conversation])

        // when
        uiMOC.delete(conversation)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        XCTAssertEqual(Team.fetch(with: uuid, in: uiMOC), team)
    }

    func testThatItDeletesMembersOfAUserWhenTheUserGetsDeleted() {
        // given
        let teamId = UUID.create()
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = teamId

        let userId = UUID.create()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userId

        let member1 = Member.insertNewObject(in: uiMOC)
        member1.user = user
        member1.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // when
        uiMOC.delete(user)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        do {
            XCTAssertNil(ZMUser.fetch(with: userId, in: uiMOC))
            guard let team = Team.fetch(with: teamId, in: uiMOC) else { return XCTFail("No team") }
            XCTAssertTrue(team.members.isEmpty)
        }
    }

    func testThatItDoesNotDeleteAMembersUserWhenThatMemberGetsDeleted() {
        // given
        let teamId = UUID.create()
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = teamId

        let userId = UUID.create()
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userId

        let member = Member.insertNewObject(in: uiMOC)
        member.user = user
        member.team = team

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // when
        uiMOC.delete(member)
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        do {
            guard let user = ZMUser.fetch(with: userId, in: uiMOC) else { return XCTFail("No user") }
            XCTAssertNil(user.membership)
            guard let team = Team.fetch(with: teamId, in: uiMOC) else { return XCTFail("No team") }
            XCTAssertTrue(team.members.isEmpty)
        }
    }

}
