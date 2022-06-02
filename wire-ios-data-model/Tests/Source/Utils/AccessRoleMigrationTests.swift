//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class AccessRoleMigrationTests: DiskDatabaseTest {

    func testForcingToFetchConversationAccessRoles() {

        // GIVEN
        let selfUser = ZMUser.selfUser(in: moc)
        let team = createTeam()
        team.remoteIdentifier = UUID.create()
        _ = createMembership(user: selfUser, team: team)

        let groupConvo = createConversation()
        groupConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvo.userDefinedName = "Group"
        groupConvo.needsToBeUpdatedFromBackend = false

        let groupConvoInTeam = createConversation()
        groupConvoInTeam.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvoInTeam.userDefinedName = "Group"
        groupConvoInTeam.needsToBeUpdatedFromBackend = false
        groupConvoInTeam.team = team

        let groupConvoInAnotherTeam = createConversation()
        groupConvoInAnotherTeam.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvoInAnotherTeam.userDefinedName = "Group"
        groupConvoInAnotherTeam.needsToBeUpdatedFromBackend = false
        groupConvoInAnotherTeam.teamRemoteIdentifier = UUID.create()

        let oneToOneConvo = createConversation()
        oneToOneConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        oneToOneConvo.conversationType = .oneOnOne
        oneToOneConvo.userDefinedName = "OneToOne"
        oneToOneConvo.needsToBeUpdatedFromBackend = false

        self.moc.saveOrRollback()

        // WHEN
        WireDataModel.ZMConversation.forceToFetchConversationAccessRoles(in: moc)

        // THEN
        XCTAssertTrue(oneToOneConvo.needsToBeUpdatedFromBackend)
        XCTAssertTrue(groupConvoInTeam.needsToBeUpdatedFromBackend)
        XCTAssertTrue(groupConvo.needsToBeUpdatedFromBackend)
        XCTAssertTrue(groupConvoInAnotherTeam.needsToBeUpdatedFromBackend)
    }

}
