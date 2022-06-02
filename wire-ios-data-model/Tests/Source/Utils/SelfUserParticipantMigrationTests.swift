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

import Foundation
import XCTest
@testable import WireDataModel

class SelfUserParticipantMigrationTests: DiskDatabaseTest {

    func testMigrationIsSelfAnActiveMemberToTheParticipantRoles() {

        // Given
        let oldKey = "isSelfAnActiveMember"
        let conversation = createConversation()
        conversation.willAccessValue(forKey: oldKey)
        conversation.setPrimitiveValue(NSNumber(value: true), forKey: oldKey)
        conversation.didAccessValue(forKey: oldKey)
        self.moc.saveOrRollback()

        // When
        WireDataModel.ZMConversation.migrateIsSelfAnActiveMemberToTheParticipantRoles(in: moc)

        // Then
        let hasSelfUser = conversation.participantRoles.contains(where: { (role) -> Bool in
            role.user?.isSelfUser == true
        })
        XCTAssertTrue(hasSelfUser)
    }

    func testMigrationDoesntCreateDuplicateTeamRoles() {
        // Given
        let oldKey = "isSelfAnActiveMember"
        let team = createTeam()
        let selfUser = ZMUser.selfUser(in: self.moc)
        _ = createMembership(user: selfUser, team: team)
        let conversation1 = createConversation()
        let conversation2 = createConversation()

        [conversation1, conversation2].forEach { conversation in
            conversation.team = team
            conversation.willAccessValue(forKey: oldKey)
            conversation.setPrimitiveValue(NSNumber(value: true), forKey: oldKey)
            conversation.didAccessValue(forKey: oldKey)
        }

        self.moc.saveOrRollback()

        // When
        WireDataModel.ZMConversation.migrateIsSelfAnActiveMemberToTheParticipantRoles(in: moc)

        // Then
        XCTAssertEqual(team.roles.count, 1)
    }

    func testAddUserFromTheConnectionToTheParticipantRoles() {
        // Given
        let conversation = createConversation()
        let newUser = ZMUser.insertNewObject(in: moc)
        newUser.remoteIdentifier = UUID.create()
        _ = createConnection(to: newUser, conversation: conversation)

        // When
        WireDataModel.ZMConversation.addUserFromTheConnectionToTheParticipantRoles(in: moc)

        // Then
        XCTAssertEqual(conversation.participantRoles.count, 1)
    }
}
