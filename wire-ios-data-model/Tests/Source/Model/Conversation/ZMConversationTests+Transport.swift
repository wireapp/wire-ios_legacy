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
@testable import WireDataModel

class ZMConversationTests_Transport: ZMConversationTestsBase {

    // MARK: Access Mode

    func testThatItUpdateAccessStatus() {
        syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let accessRoles: Set<ConversationAccessRoleV2> = [.teamMember, .guest, .service]
            let accessMode = ConversationAccessMode.allowGuests

            // when
            conversation.updateAccessStatus(accessModes: accessMode.stringValue, accessRoles: accessRoles.map({$0.rawValue}))

            // then
            XCTAssertEqual(conversation.accessMode, accessMode)
            XCTAssertEqual(conversation.accessRoles, accessRoles)
        }
    }

    // MARK: Receipt Mode

    func testThatItUpdateReadReceiptStatusAndInsertsSystemMessage_ForNonEmptyConversations() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.appendNewConversationSystemMessage(at: Date(), users: Set())
            conversation.hasReadReceiptsEnabled = false

            // when
            conversation.updateReceiptMode(1)

            // then
            XCTAssertEqual(conversation.lastMessage?.systemMessageData?.systemMessageType, .readReceiptsOn)
        }
    }

    func testThatItDoesntInsertsSystemMessage_WhenReadReceiptStatusDoesntChange() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.hasReadReceiptsEnabled = true

            // when
            conversation.updateReceiptMode(1)

            // then
            XCTAssertNil(conversation.lastMessage)
        }
    }

    // MARK: Archiving

    func testThatItUpdateArchiveStatus() {
        syncMOC.performGroupedBlockAndWait {
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)

            // when
            conversation.updateArchivedStatus(archived: true, referenceDate: timestamp)

            // then
            XCTAssertEqual(conversation.isArchived, true)
            XCTAssertEqual(conversation.archivedChangedTimestamp, timestamp)
        }
    }

    // MARK: Muting

    func testThatItUpdateMutedStatus() {
        syncMOC.performGroupedBlockAndWait {
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let mutedMessages: MutedMessageTypes = .all

            // when
            conversation.updateMutedStatus(status: mutedMessages.rawValue, referenceDate: timestamp)

            // then
            XCTAssertEqual(conversation.mutedMessageTypes, .all)
            XCTAssertEqual(conversation.silencedChangedTimestamp, timestamp)
        }
    }

    // MARK: Roles

    func testThatItAssignsRoles_WhenNotInTeam() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let user1 = self.createUser(in: self.syncMOC)
            let user2 = self.createUser(in: self.syncMOC)
            let role = Role.create(managedObjectContext: self.syncMOC, name: "test_role", conversation: conversation)

            // when
            conversation.updateMembers([(user1, nil), (user2, role)], selfUserRole: nil)

            // then
            XCTAssertTrue(conversation.localParticipants.contains(user1))
            XCTAssertTrue(conversation.localParticipants.contains(user2))

            guard
                let participant1 = conversation.participantForUser(user1),
                let participant2 = conversation.participantForUser(user2)
            else { return XCTFail() }

            XCTAssertNil(participant1.role)
            XCTAssertEqual(participant2.role?.name, "test_role")
            XCTAssertEqual(conversation.nonTeamRoles.count, 1)
            XCTAssertEqual(conversation.nonTeamRoles.first, participant2.role)
        }
    }

    func testThatItAssignsRoles_WhenInTeam() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.team = team

            let user1 = self.createUser(in: self.syncMOC)
            let user2 = self.createUser(in: self.syncMOC)
            let role1 = Role.create(managedObjectContext: self.syncMOC, name: "test_role1", team: team)
            let role2 = Role.create(managedObjectContext: self.syncMOC, name: "test_role2", team: team)

            // when
            conversation.updateMembers([(user1, role1), (user2, role2)], selfUserRole: nil)

            // then
            XCTAssertTrue(conversation.localParticipants.contains(user1))
            XCTAssertTrue(conversation.localParticipants.contains(user2))

            guard
                let participant1 = conversation.participantForUser(user1),
                let participant2 = conversation.participantForUser(user2)
            else { return XCTFail() }

            XCTAssertEqual(participant1.role?.team, team)
            XCTAssertEqual(participant2.role?.team, team)
            XCTAssertEqual(participant1.role?.name, "test_role1")
            XCTAssertEqual(participant2.role?.name, "test_role2")
            XCTAssertEqual(team.roles, Set([participant1.role, participant2.role].compactMap {$0}))
        }
    }

    func testThatItUpdatesRoles_WhenInTeam() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.team = team
            let user1 = ZMUser.insertNewObject(in: self.syncMOC)
            user1.name = "U1"
            user1.remoteIdentifier = UUID.create()
            let oldRole = Role.create(managedObjectContext: self.syncMOC, name: "ROLE1", team: team)
            conversation.addParticipantAndUpdateConversationState(user: user1, role: oldRole)
            let newRole = Role.create(managedObjectContext: self.syncMOC, name: "new_role", team: team)

            // when
            conversation.updateMembers([(user1, newRole)], selfUserRole: nil)

            // then
            XCTAssertEqual(conversation.participantForUser(user1)?.role, newRole)
        }
    }

    func testThatItAssignsSelfRole_WhenInTeam() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.team = team
            let selfRole = Role.create(managedObjectContext: self.syncMOC, name: "test_role", team: team)

            // when
            conversation.updateMembers([], selfUserRole: selfRole)

            // then
            XCTAssertEqual(conversation.participantForUser(selfUser)?.role, selfRole)
        }
    }

    func testThatItAssignsSelfRole_WhenNotInTeam() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            let selfRole = Role.create(managedObjectContext: self.syncMOC, name: "test_role", conversation: conversation)

            // when
            conversation.updateMembers([], selfUserRole: selfRole)

            // then
            XCTAssertEqual(conversation.participantForUser(selfUser)?.role, selfRole)
        }
    }

    func testThatItRefetchesRoles_WhenSelfUserIsAssignedARole() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
            let selfRole = Role.create(managedObjectContext: self.syncMOC, name: "test_role", conversation: conversation)

            // when
            conversation.updateMembers([], selfUserRole: selfRole)

            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }

}

extension ZMConversation {

    fileprivate func participantForUser(_ user: ZMUser) -> ParticipantRole? {
        return self.participantForUser(id: user.remoteIdentifier!)
    }

    fileprivate func participantForUser(id: UUID) -> ParticipantRole? {
        return self.participantRoles.first(where: { $0.user?.remoteIdentifier == id })
    }
}
