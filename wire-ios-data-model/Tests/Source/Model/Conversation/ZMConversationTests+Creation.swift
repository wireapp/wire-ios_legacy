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
// but WITHOUT ANY WARRANTY without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
@testable import WireDataModel

final class ZMConversationTests_Creation: ZMConversationTestsBase {

    func testThatItCreatesParticipantsWithTheGivenRoleForAllParticipants() {

        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", team: team)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"

        // when
        let conversation = ZMConversation.insertGroupConversation(
            moc: self.uiMOC,
            participants: [user1, user2],
            name: "Foo",
            team: team,
            participantsRole: role1
        )!

        // then
        XCTAssertEqual(conversation.participantRoles.compactMap { $0.role}, [role1, role1, role1])
    }

    func testThatItCreatesConversationAndIncludesSelfUser() {

        // given
        let team = Team.insertNewObject(in: self.uiMOC)
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", team: team)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"

        // when
        let conversation = ZMConversation.insertGroupConversation(
            moc: self.uiMOC,
            participants: [user1, user2],
            name: "Foo",
            team: team,
            participantsRole: role1
            )!

        // then
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        XCTAssertEqual(conversation.localParticipants, Set([selfUser, user1, user2]))
    }

}
