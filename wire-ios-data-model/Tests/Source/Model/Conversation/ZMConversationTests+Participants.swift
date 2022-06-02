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

final class ConversationParticipantsTests: ZMConversationTestsBase {

	func testThatSortedOtherParticipantsReutrnsUsersSortedByName() {
		// GIVEN
		let sut = createConversation(in: uiMOC)

		let user1 = createUser()
		user1.name = "Zeta"

		let user2 = createUser()
		user2.name = "Alpha"

		let user3 = createUser()
		user3.name = "Beta"
		user3.providerIdentifier = "dummy ID"
		user3.serviceIdentifier = "dummy ID"

		sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3]), role: nil)

		// WHEN & THEN
		XCTAssertEqual(sut.sortedOtherParticipants as! [ZMUser], [user2, user1])
	}

	func testThatSortedServiceUsersReutrnsUsersSortedByName() {
		// GIVEN
		let sut = createConversation(in: uiMOC)

		let user1 = createUser()
		user1.name = "Zeta"
		user1.providerIdentifier = "dummy ID"
		user1.serviceIdentifier = "dummy ID"

		let user2 = createUser()
		user2.name = "Alpha"
		user2.providerIdentifier = "dummy ID"
		user2.serviceIdentifier = "dummy ID"

		let user3 = createUser()
		user3.name = "Beta"

		sut.addParticipantsAndUpdateConversationState(users: Set([user2, user1, user3]), role: nil)

		// WHEN & THEN
		XCTAssertEqual(sut.sortedServiceUsers as! [ZMUser], [user2, user1])
	}

	func testThatLocalParticipantsExcludesUsersMarkedForDeletion() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)

        // THEN
        XCTAssertEqual(sut.localParticipants, Set([user1]))
    }

    func testThatLocalRolesExcludesUsersMarkedForDeletion() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)

        // THEN
        XCTAssertEqual(sut.localParticipantRoles.map { $0.user }, [user1])
    }

    func testThatRemoveThenAddParticipants() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)

        XCTAssertEqual(sut.participantRoles.count, 2)
        XCTAssertEqual(sut.localParticipants.count, 2)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)
        sut.addParticipantAndUpdateConversationState(user: user2, role: nil)

        // THEN
        XCTAssertEqual(Set(sut.participantRoles.map { $0.user }), Set([user1, user2]))
        XCTAssertEqual(sut.localParticipants, Set([user1, user2]))
    }

    func testThatAddThenRemoveParticipants() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()

        sut.addParticipantAndUpdateConversationState(user: user1, role: nil)

        // WHEN
        sut.addParticipantAndUpdateConversationState(user: user2, role: nil)
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)
        uiMOC.processPendingChanges()

        // THEN
        XCTAssertEqual(Set(sut.participantRoles.map { $0.user }), Set([user1]))
        XCTAssertEqual(sut.localParticipants, Set([user1]))

        XCTAssert(user2.participantRoles.isEmpty, "\(user2.participantRoles)")
    }

    func testThatItAddsMissingParticipantInGroup() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // when
        conversation.addParticipantAndSystemMessageIfMissing(user, date: Date())

        // then
        XCTAssertTrue(conversation.localParticipants.contains(user))
        let systemMessage = conversation.lastMessage as? ZMSystemMessage
        XCTAssertEqual(systemMessage?.systemMessageType, ZMSystemMessageType.participantsAdded)
    }

    func testThatItDoesntAddParticipantsAddedSystemMessageIfUserIsNotMissing() {
        // given
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        // when
        conversation.addParticipantAndSystemMessageIfMissing(user, date: Date())

        // then
        XCTAssertTrue(conversation.localParticipants.contains(user))
        XCTAssertEqual(conversation.allMessages.count, 0)
    }

    func testThatItDoesntCreateAConnectionIfSelfUserIsMissing() {
        // given
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = connection
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        // when
        conversation.addParticipantAndSystemMessageIfMissing(selfUser, date: Date())

        // then
        XCTAssertNotEqual(selfUser.connection, connection)
    }

    func testThatItAddsParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user1 = self.createUser()
        let user2 = self.createUser()

        // when
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: user2, role: nil)

        // then
        let expectedActiveParticipants = Set([user1, user2])
        XCTAssertEqual(expectedActiveParticipants, conversation.localParticipants)
    }

    func testThatItDoesNotUnarchiveTheConversationWhenTheSelfUserIsAddedIfMuted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        conversation.mutedStatus = MutedMessageOptionValue.all.rawValue
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier =  UUID.create()

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversation.isArchived)
    }

    func testThatItUnarchivesTheConversationWhenTheSelfUserIsAdded() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        conversation.remoteIdentifier = UUID.create()
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier =  UUID.create()

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // then
        XCTAssertFalse(conversation.isArchived)
    }

    func testThatItCanRemoveTheSelfUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user1 = self.createUser()
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier =  UUID.create()

        conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, user1]), role: nil)

        XCTAssertTrue(conversation.isSelfAnActiveMember)

        // when
        conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: user1)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(conversation.isSelfAnActiveMember)
    }

    func testThatItDoesNothingForUnknownParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let user1 = self.createUser()
        let user2 = self.createUser()
        let user3 = self.createUser()
        let unknownUser = self.createUser()
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3]), role: nil)

        // when
        conversation.removeParticipantAndUpdateConversationState(user: unknownUser, initiatingUser: user1)

        // then
        let expectedActiveParticipants = Set([user1, user2, user3])
        XCTAssertEqual(expectedActiveParticipants, conversation.localParticipants)
    }

    func testThatActiveParticipantsContainsSelf() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: self.uiMOC), role: nil)

        // then
        XCTAssertTrue(conversation.localParticipants.contains(selfUser))

        // when
        conversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: self.uiMOC))

        // then
        XCTAssertFalse(conversation.localParticipants.contains(selfUser))
    }

    func testThatLocalParticipantsExcludingSelfDoesNotContainSelf() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertFalse(conversation.localParticipantsExcludingSelf.contains(selfUser))
    }

    func testThatAddingSelfToExistingConversationMarksItAsNeedingToUpdate() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create() // this makes it "exists"
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
    }

    func testThatAddingSelfToNonExistingConversationDoesNotNeedUpdate() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = nil // this makes it as local only
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
    }

    // MARK: - Sorting

    func testThatItSortsParticipantsByFullName() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let uuid = UUID.create()
        conversation.remoteIdentifier = uuid

        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        let user1 = self.createUser()
        let user2 = self.createUser()
        let user3 = self.createUser()
        let user4 = self.createUser()

        selfUser.name = "Super User"
        user1.name = "Hans im Glueck"
        user2.name = "Anna Blume"
        user3.name = "Susi Super"
        user4.name = "Super Susann"

        // when
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3, user4]), role: nil)
        self.uiMOC.saveOrRollback()

        // then
        let expected = [user2, user1, user4, user3]

        XCTAssertEqual(conversation.sortedActiveParticipants, expected)
    }

    // MARK: - ConnectedUser

    func testThatTheConnectedUserIsNilForGroupConversation() {
        // when
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.insertNewObject(in: self.uiMOC), role: nil)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.insertNewObject(in: self.uiMOC), role: nil)

        // then
        XCTAssertNil(conversation.connectedUser)
    }

    func testThatTheConnectedUserIsNilForSelfconversation() {
        // when
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .self

        // then
        XCTAssertNil(conversation.connectedUser)
    }

    func testThatWeHaveAConnectedUserForOneOnOneConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .oneOnOne
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let connection = ZMConnection.insertNewObject(in: self.uiMOC)
        connection.to = user

        // when
        connection.conversation = conversation

        // then
        XCTAssertEqual(conversation.connectedUser, user)
    }

    func testThatWeHaveAConnectedUserForConnectionConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .connection
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        let connection = ZMConnection.insertNewObject(in: self.uiMOC)
        connection.to = user

        // when
        connection.conversation = conversation

        // then
        XCTAssertEqual(conversation.connectedUser, user)
    }

    // MARK: - Roles

    func testThatWeGetAConversationRolesIfItIsAPartOfATeam() {
        // given
        let team = self.createTeam(in: self.uiMOC)
        let user1 = self.createTeamMember(in: self.uiMOC, for: team)
        let user2 = self.createTeamMember(in: self.uiMOC, for: team)
        let conversation = ZMConversation.insertGroupConversation(moc: self.uiMOC, participants: [user1, user2], name: self.name, team: team)

        // when
        let adminRole = Role.create(managedObjectContext: uiMOC, name: "wire_admin", team: team)
        let memberRole = Role.create(managedObjectContext: uiMOC, name: "wire_member", team: team)
        team.roles.insert(adminRole)
        team.roles.insert(memberRole)

        // then
        XCTAssertNotNil(conversation!.team)
        XCTAssertEqual(conversation!.getRoles(), conversation!.team!.roles)
        XCTAssertNotEqual(conversation!.getRoles(), conversation!.nonTeamRoles)
    }

    func testThatWeGetAConversationRolesIfItIsNotAPartOfATeam() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group

        // when
        let adminRole = Role.create(managedObjectContext: uiMOC, name: "wire_admin", conversation: conversation)
        conversation.nonTeamRoles.insert(adminRole)

        // then
        XCTAssertNil(conversation.team)
        XCTAssertEqual(conversation.getRoles(), conversation.nonTeamRoles)
        XCTAssertNotEqual(conversation.getRoles(), conversation.team?.roles)
    }

    func testThatItAddsParticipantsWithTheGivenRoleForAllParticipants() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"

        // when
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: role1)

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.compactMap { $0.role}, [role1, role1])
    }

    func testThatItAddsParticipantsWithTheGivenRole() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
                (user1, role1),
                (user2, role2)
        ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.first {$0.user == user1}?.role, role1)
        XCTAssertEqual(conversation.participantRoles.first {$0.user == user2}?.role, role2)
    }

    func testThatItDoesNotAddDeletedParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"
        user2.isAccountDeleted = true

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role2)
        ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 1)
        XCTAssertEqual(conversation.participantRoles.first {$0.user == user1}?.role, role1)
    }

    func testThatItUpdateParticipantWithTheGivenRole() {

        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: self.uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: self.uiMOC)
        user2.name = "user2"
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role1)
            ])

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role2)
            ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.first {$0.user == user1}?.role, role1)
        XCTAssertEqual(conversation.participantRoles.first {$0.user == user2}?.role, role2)
    }

    func testThatItRefetchesRolesIfNoRoles() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }

    func testThatItRefetchesRolesIfRolesAreEmpty() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            let role = Role.create(managedObjectContext: self.syncMOC, name: "foo", conversation: conversation)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: role)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }

    func testThatItDoesNotRefetchRolesIfRolesAreNotEmpty() {

        syncMOC.performGroupedAndWait { _ -> Void in
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            let role = Role.create(managedObjectContext: self.syncMOC, name: "foo", conversation: conversation)
            var created = false
            _ = Action.fetchOrCreate(with: "delete", role: role, in: self.syncMOC, created: &created)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: role)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertFalse(conversation.needsToDownloadRoles)
        }
    }
}
