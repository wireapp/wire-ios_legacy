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

@testable import WireDataModel

class ParticipantRoleTests: ZMBaseManagedObjectTest {

    var user: ZMUser!
    var conversation: ZMConversation!
    var role: Role!

    override func setUp() {
        super.setUp()
        self.user = ZMUser.insertNewObject(in: self.uiMOC)
        self.conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        self.role = Role.insertNewObject(in: self.uiMOC)
    }

    private func createParticipantRole() -> ParticipantRole {
        let pr = ParticipantRole.insertNewObject(in: self.uiMOC)
        pr.user = user
        pr.conversation = conversation
        pr.role = role
        return pr
    }

    func testThatServicesBelongToOneToOneConversations() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let service = createService(in: uiMOC, named: "Bob the Robot")

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group

        let team = Team.insertNewObject(in: self.uiMOC)
        team.remoteIdentifier = UUID.create()
        conversation.team = team

        // WHEN
        conversation.addParticipantAndUpdateConversationState(user: service as! ZMUser, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // THEN
        XCTAssertTrue(ZMConversation.predicateForOneToOneConversations().evaluate(with: conversation))
    }
}
