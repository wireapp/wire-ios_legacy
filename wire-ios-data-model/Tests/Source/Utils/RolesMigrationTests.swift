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

class RolesMigrationTests: DiskDatabaseTest {

    func testMarkingTeamsAndConversationForDownalod() {

        // Given
        let selfUser = ZMUser.selfUser(in: moc)
        let team = createTeam()
        team.remoteIdentifier = UUID.create()
        _ = createMembership(user: selfUser, team: team)
        team.needsToDownloadRoles = false

        let groupConvo = createConversation()
        groupConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvo.userDefinedName = "Group"
        groupConvo.needsToDownloadRoles = false
        groupConvo.needsToBeUpdatedFromBackend = false

        let groupConvoInTeam = createConversation()
        groupConvoInTeam.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvoInTeam.userDefinedName = "Group"
        groupConvoInTeam.needsToDownloadRoles = false
        groupConvoInTeam.needsToBeUpdatedFromBackend = false
        groupConvoInTeam.team = team

        let groupConvoInAnotherTeam = createConversation()
        groupConvoInAnotherTeam.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        groupConvoInAnotherTeam.userDefinedName = "Group"
        groupConvoInAnotherTeam.needsToDownloadRoles = false
        groupConvoInAnotherTeam.needsToBeUpdatedFromBackend = false
        groupConvoInAnotherTeam.teamRemoteIdentifier = UUID.create()

        let groupConvoThatUserLeft = createConversation()
        groupConvoThatUserLeft.needsToDownloadRoles = false
        groupConvoThatUserLeft.userDefinedName = "GroupThatUserLeft"
        groupConvoThatUserLeft.needsToDownloadRoles = false
        groupConvoThatUserLeft.needsToBeUpdatedFromBackend = false

        let oneToOneConvo = createConversation()
        oneToOneConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        oneToOneConvo.conversationType = .oneOnOne
        oneToOneConvo.userDefinedName = "OneToOne"
        oneToOneConvo.needsToDownloadRoles = false
        oneToOneConvo.needsToBeUpdatedFromBackend = false

        let selfConvo = ZMConversation.selfConversation(in: self.moc)
        selfConvo.conversationType = .self
        selfConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        selfConvo.userDefinedName = "Self"
        selfConvo.needsToDownloadRoles = false
        selfConvo.needsToBeUpdatedFromBackend = false

        let connectionConvo = createConversation()
        connectionConvo.conversationType = .connection
        connectionConvo.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        connectionConvo.userDefinedName = "Connection"
        connectionConvo.needsToDownloadRoles = false
        connectionConvo.needsToBeUpdatedFromBackend = false

        self.moc.saveOrRollback()

        // When
        WireDataModel.ZMConversation.forceToFetchConversationRoles(in: moc)

        // Then
        XCTAssertFalse(groupConvoThatUserLeft.needsToDownloadRoles)
        XCTAssertFalse(groupConvoThatUserLeft.needsToBeUpdatedFromBackend)
        XCTAssertFalse(oneToOneConvo.needsToDownloadRoles)
        XCTAssertFalse(oneToOneConvo.needsToBeUpdatedFromBackend)
        XCTAssertFalse(selfConvo.needsToDownloadRoles)
        XCTAssertFalse(selfConvo.needsToBeUpdatedFromBackend)
        XCTAssertFalse(connectionConvo.needsToDownloadRoles)
        XCTAssertFalse(connectionConvo.needsToBeUpdatedFromBackend)
        XCTAssertFalse(groupConvoInTeam.needsToDownloadRoles)
        XCTAssertTrue(groupConvoInTeam.needsToBeUpdatedFromBackend)
        XCTAssertTrue(groupConvo.needsToDownloadRoles)
        XCTAssertTrue(groupConvo.needsToBeUpdatedFromBackend)
        XCTAssertTrue(groupConvoInAnotherTeam.needsToDownloadRoles)
        XCTAssertTrue(groupConvoInAnotherTeam.needsToBeUpdatedFromBackend)
        XCTAssertTrue(team.needsToDownloadRoles)
    }

    func testMigratingUsers() {

        // Given
        let oldKey = "lastServerSyncedActiveParticipants"
        let user1 = ZMUser.insertNewObject(in: moc)
        user1.name = "u1"
        let user2 = ZMUser.insertNewObject(in: moc)
        user2.name = "u2"

        let groupConvo = createConversation()
        let orderedSet = NSOrderedSet(array: [user1, user2])
        groupConvo.setValue(orderedSet, forKey: oldKey)
        self.moc.saveOrRollback()

        // When
        WireDataModel.ZMConversation.migrateUsersToParticipants(in: moc)

        // Then
        XCTAssertEqual(groupConvo.localParticipants, Set([user1, user2]))
        XCTAssertEqual((groupConvo.value(forKey: oldKey) as! NSOrderedSet).count, 0)
    }

}
