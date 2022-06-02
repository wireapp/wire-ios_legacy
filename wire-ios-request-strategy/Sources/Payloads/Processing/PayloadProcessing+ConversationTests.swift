// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import XCTest
@testable import WireRequestStrategy

class PayloadProcessing_ConversationTests: MessagingTestBase {

    override func tearDown() {
        APIVersion.isFederationEnabled = false
        super.tearDown()
    }

    // MARK: Group conversations

    func testUpdateOrCreateConversation_Group_UpdatesQualifiedID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            APIVersion.isFederationEnabled = true
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversation = Payload.Conversation(qualifiedID: qualifiedID,
                                                    type: BackendConversationType.group.rawValue)

            // when
            conversation.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertEqual(self.groupConversation.domain, qualifiedID.domain)
        }
    }

    func testUpdateOrCreateConversation_Group_DoesntUpdatesQualifiedID_WhenFederationIsDisabled() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            APIVersion.isFederationEnabled = false
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversation = Payload.Conversation(qualifiedID: qualifiedID,
                                                    id: qualifiedID.uuid,
                                                    type: BackendConversationType.group.rawValue)

            // when
            conversation.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertNil(self.groupConversation.domain)
        }
    }

    func testUpdateOrCreateConversation_Group_SetsNeedsToBeUpdatedFromBackend() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.groupConversation.needsToBeUpdatedFromBackend = true
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.group.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertFalse(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testUpdateOrCreateConversation_Group_CreatesConversation() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.group.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertNotNil(ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC))
        }
    }

    func testUpdateOrCreateConversation_Group_AddSystemMessageWhenCreatingGroup() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.group.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC)
            XCTAssertEqual(conversation?.lastMessage?.systemMessageData?.systemMessageType, .newConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesLastServerTimestamp() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let serverTimestamp = Date()
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC, serverTimestamp: serverTimestamp)

            // then
            XCTAssertEqual(self.groupConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesUserDefinedName() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let name = "Example name"
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           name: name)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.userDefinedName, name)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesTeamID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let teamID = UUID()
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           teamID: teamID)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.teamRemoteIdentifier, teamID)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesCreator() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let creator = self.otherUser.remoteIdentifier
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           creator: creator)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.creator, self.otherUser)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMembers() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           members: members)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            let otherUserSet: Set<ZMUser?> = [self.otherUser, selfUser]
            XCTAssertEqual(self.groupConversation.localParticipants, otherUserSet)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesReadReceiptMode() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = self.groupConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           readReceiptMode: 1)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertTrue(self.groupConversation.hasReadReceiptsEnabled)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesAccessStatus() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let accessMode: ConversationAccessMode = .allowGuests
            let accessRole: Set<ConversationAccessRoleV2> = [.teamMember]
            let qualifiedID = self.groupConversation.qualifiedID!

            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           access: accessMode.stringValue,
                                                           accessRoleV2: accessRole.map(\.rawValue))
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.accessMode, accessMode)
            XCTAssertEqual(self.groupConversation.accessRoles, accessRole)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdateAccessRoleV2() throws {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let accessMode: ConversationAccessMode = .allowGuests
            let accessRoleV2: Set<ConversationAccessRoleV2> = [.teamMember, .nonTeamMember, .guest]
            let qualifiedID = self.groupConversation.qualifiedID!

            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           access: accessMode.stringValue,
                                                           accessRoleV2: accessRoleV2.map(\.rawValue))

            // WHEN
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // THEN
            XCTAssertEqual(self.groupConversation.accessRoles, accessRoleV2)

        }
    }

    func testThatItMapsFromLegacyAccessRoleToAccessRoleV2() throws {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let accessRole: ConversationAccessRole = .team
            let qualifiedID = self.groupConversation.qualifiedID!

            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           accessRole: accessRole.rawValue)
            // WHEN
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // THEN
            let accessRoleV2 = ConversationAccessRoleV2.fromLegacyAccessRole(accessRole)
            XCTAssertEqual(self.groupConversation.accessRoles, accessRoleV2)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMessageTimer() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let messageTimer = MessageDestructionTimeoutValue.fiveMinutes
            let qualifiedID = self.groupConversation.qualifiedID!

            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           messageTimer: messageTimer.rawValue * 1000)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutValue, messageTimer)
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutType, .groupConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMutedStatus() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let mutedMessageTypes: MutedMessageTypes = .all
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        mutedStatus: Int(mutedMessageTypes.rawValue),
                                                        mutedReference: Date())
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [])
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           members: members)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.groupConversation.mutedMessageTypes, mutedMessageTypes)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesArchivedStatus() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        archived: true,
                                                        archivedReference: Date())
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [])
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.group.rawValue,
                                                           members: members)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertTrue(self.groupConversation.isArchived)
        }
    }

    // MARK: 1:1 / Connection Conversations

    func testUpdateOrCreateConversation_OneToOne_CreatesConversation() throws {
        syncMOC.performGroupedAndWait { syncMOC in
            // given
            APIVersion.isFederationEnabled = true
            self.otherUser.connection?.conversation = nil

            let conversationID = UUID()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = QualifiedID(uuid: conversationID, domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.oneOnOne.rawValue,
                                                           members: members)
            let otherUserSet: Set<ZMUser> = [selfUser, self.otherUser]

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.otherUser.connection?.conversation?.remoteIdentifier, conversationID)
            XCTAssertEqual(self.otherUser.connection?.conversation?.domain, self.owningDomain)
            XCTAssertEqual(self.otherUser.connection?.conversation?.conversationType, .oneOnOne)
            XCTAssertEqual(self.otherUser.connection?.conversation?.localParticipants, otherUserSet)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_DoesntAssignDomain_WhenFederationIsDisabled() throws {
        syncMOC.performGroupedAndWait { syncMOC in
            // given
            APIVersion.isFederationEnabled = false
            self.otherUser.connection?.conversation = nil

            let conversationID = UUID()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = QualifiedID(uuid: conversationID, domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.oneOnOne.rawValue,
                                                           members: members)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.otherUser.connection?.conversation?.remoteIdentifier, conversationID)
            XCTAssertNil(self.otherUser.connection?.conversation?.domain)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesConversationType() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
            conversation.domain = self.owningDomain
            let qualifiedID = conversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.connection.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(conversation.conversationType, .connection)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesLastServerTimestamp() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let serverTimestamp = Date()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.oneOnOne.rawValue,
                                                           members: members)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC, serverTimestamp: serverTimestamp)

            // then
            XCTAssertEqual(self.oneToOneConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_MergesWithExistingConversation() throws {
        try syncMOC.performGroupedAndWait { syncMOC in
            // given

            // We already have a local 1:1 conversation
            self.otherUser.connection?.conversation.remoteIdentifier = nil
            self.otherUser.connection?.conversation.domain = nil

            // The remote 1:1 conversation also exists but it's not linked to the connection
            let existingTextMessage = "Hello World"
            let existingConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            existingConversation.remoteIdentifier = UUID()
            existingConversation.domain = self.owningDomain
            try existingConversation.appendText(content: existingTextMessage)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let conversationPayload = Payload.Conversation(qualifiedID: existingConversation.qualifiedID!,
                                                           type: BackendConversationType.connection.rawValue,
                                                           members: members)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertTrue(existingConversation.isZombieObject)
            XCTAssertEqual(self.otherUser.connection?.conversation?.lastMessage?.textMessageData?.messageText, existingTextMessage)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesMutedStatus() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let mutedMessageTypes: MutedMessageTypes = .all
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        mutedStatus: Int(mutedMessageTypes.rawValue),
                                                        mutedReference: Date())
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.oneOnOne.rawValue,
                                                           members: members)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertEqual(self.oneToOneConversation.mutedMessageTypes, mutedMessageTypes)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesArchivedStatus() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        archived: true,
                                                        archivedReference: Date())
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID,
                                                           type: BackendConversationType.oneOnOne.rawValue,
                                                           members: members)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertTrue(self.oneToOneConversation.isArchived)
        }
    }

    // MARK: Self conversation

    func testUpdateOrCreateConversation_Self_CreatesConversation() throws {
        try syncMOC.performGroupedAndWait { syncMOC in
            // given
            APIVersion.isFederationEnabled = true
            let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC))
            XCTAssertEqual(conversation.conversationType, .`self`)
        }
    }

    func testUpdateOrCreateConversation_Self_DoesntAssignDomain_WhenFederationIsDisabled() throws {
        try syncMOC.performGroupedAndWait { syncMOC in
            // given
            APIVersion.isFederationEnabled = false
            let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID.uuid, domain: nil, in: self.syncMOC))
            XCTAssertEqual(conversation.conversationType, .`self`)
            XCTAssertNil(conversation.domain)
        }
    }

    func testUpdateOrCreateConversation_Self_ResetsNeedsToBeUpdatedFromBackend() throws {
        syncMOC.performGroupedAndWait { syncMOC in
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.needsToBeUpdatedFromBackend = true
            conversation.remoteIdentifier = UUID()
            conversation.domain = self.owningDomain
            let qualifiedID = conversation.qualifiedID!
            let conversationPayload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

            // when
            conversationPayload.updateOrCreate(in: self.syncMOC)

            // then
            XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
        }
    }

    func testUpdateOrCreateConversation_Self_UpdatesLastServerTimestamp() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let serverTimestamp = Date()
            let selfConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            selfConversation.remoteIdentifier = ZMConversation.selfConversationIdentifier(in: self.syncMOC)
            selfConversation.domain = self.owningDomain
            let conversationPayload = Payload.Conversation(qualifiedID: selfConversation.qualifiedID!,
                                                           type: BackendConversationType.`self`.rawValue)
            // when
            conversationPayload.updateOrCreate(in: self.syncMOC, serverTimestamp: serverTimestamp)

            // then
            XCTAssertEqual(selfConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

}
