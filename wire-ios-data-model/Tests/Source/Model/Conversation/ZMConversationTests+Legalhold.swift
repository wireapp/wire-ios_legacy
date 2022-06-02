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

import XCTest
@testable import WireDataModel

class ZMConversationTests_Legalhold: ZMConversationTestsBase {

    // MARK: - Update legal hold on client changes

    func testThatLegalholdIsActivatedForUser_WhenLegalholdClientIsDiscovered() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            XCTAssertFalse(user.isUnderLegalHold)

            // WHEN
            self.createClient(ofType: .legalHold, class: .legalHold, for: user)

            // THEN
            XCTAssertTrue(user.isUnderLegalHold)
        }
    }

    func testThatLegalholdIsDeactivatedForUser_WhenLegalholdClientIsDeleted() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: user)
            XCTAssertTrue(user.isUnderLegalHold)

            // WHEN
            legalHoldClient.deleteClientAndEndSession()

            // THEN
            XCTAssertFalse(user.isUnderLegalHold)
        }
    }

    func testThatLegalholdIsActivatedForConversation_WhenLegalholdClientIsDiscovered() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [otherUser])

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
        }
    }

    func testThatLegalholdIsDeactivatedInConversation_OnlyWhenTheLastLegalholdClientIsDeleted() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            legalHoldClient.deleteClientAndEndSession()

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    // MARK: - Update legal hold on participant changes

    func testThatLegalholdIsInConversation_WhenParticipantIsAdded() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
        }
    }

    func testThatLegalholdIsDeactivatedInConversation_WhenTheLastLegalholdParticipantIsRemoved() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            conversation.removeParticipantAndUpdateConversationState(user: otherUser, initiatingUser: selfUser)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    func testThatLegalholdIsNotDeactivatedInConversation_WhenParticipantIsRemoved() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            conversation.removeParticipantAndUpdateConversationState(user: otherUserB, initiatingUser: selfUser)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
        }
    }

    // MARK: - Verify legal hold

    func testThatLegalholdIsActivatedIfFalselyDeactivated_WhenVerifyingLegalHold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)
            conversation.legalHoldStatus = .disabled

            // WHEN
            let noChanges: ZMConversationRemoteClientChangeSet = []
            conversation.updateSecurityLevelIfNeededAfterFetchingClients(changes: noChanges)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
        }
    }

    func testThatLegalholdIsDeactivatedIfFalselyActivated_WhenVerifyingLegalHold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)
            conversation.legalHoldStatus = .enabled

            // WHEN
            let noChanges: ZMConversationRemoteClientChangeSet = []
            conversation.updateSecurityLevelIfNeededAfterFetchingClients(changes: noChanges)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    func testThatLegalholdStaysActivatedIfCorrectlyActivated_WhenVerifyingLegalHold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            let noChanges: ZMConversationRemoteClientChangeSet = []
            conversation.updateSecurityLevelIfNeededAfterFetchingClients(changes: noChanges)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
        }
    }

    func testThatLegalholdStaysDeactivatedIfCorrectlyDeactivated_WhenVerifyingLegalHold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let noChanges: ZMConversationRemoteClientChangeSet = []
            conversation.updateSecurityLevelIfNeededAfterFetchingClients(changes: noChanges)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    // MARK: - System messages

    func testThatLegalholdSystemMessageIsInserted_WhenUserIsDiscoveredToBeUnderLegalhold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [otherUser])

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            let lastMessage = conversation.lastMessage as? ZMSystemMessage
            XCTAssertTrue(lastMessage?.systemMessageType == .legalHoldEnabled)
            XCTAssertEqual(lastMessage?.users, [])
        }
    }

    func testThatLegalholdSystemMessageIsNotInserted_WhenSecondUserUserIsDiscoveredToBeUnderLegalhold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [otherUser])

            // THEN
            let legalHoldMessageCount: () -> Int = {
                conversation.allMessages
                    .filter { ($0 as? ZMSystemMessage)?.systemMessageType == .legalHoldEnabled }
                    .count
            }

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
            XCTAssertEqual(legalHoldMessageCount(), 1)

            // WHEN
            let legalHoldClientB = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUserB)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClientB], causedBy: [otherUserB])

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
            XCTAssertEqual(legalHoldMessageCount(), 1)
        }
    }

    func testThatLegalholdSystemMessageIsInserted_WhenUserIsNoLongerUnderLegalhold() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            legalHoldClient.deleteClientAndEndSession()

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            let lastMessage = conversation.lastMessage as? ZMSystemMessage
            XCTAssertTrue(lastMessage?.systemMessageType == .legalHoldDisabled)
            XCTAssertEqual(lastMessage?.users, [])
        }
    }

    func testThatLegalholdSystemMessageIsInserted_WhenUserIsRemoved() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser, otherUserB]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            // WHEN
            conversation.removeParticipantAndUpdateConversationState(user: otherUser, initiatingUser: selfUser)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            let lastMessage = conversation.lastMessage as? ZMSystemMessage
            XCTAssertTrue(lastMessage?.systemMessageType == .legalHoldDisabled)
            XCTAssertTrue(lastMessage?.users == [])
        }
    }

    func testThatLegalHoldSystemMessageIsInstertedAtProperPosition_WhenCreatingGroup() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            let otherUserB = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .legalHold, class: .legalHold, for: selfUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            self.createClient(ofType: .permanent, class: .phone, for: otherUserB)

            // WHEN
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [otherUser, otherUserB], team: nil)!

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)
            let messages = conversation.lastMessages()

            let firstMessage = messages.last as? ZMSystemMessage
            XCTAssertTrue(firstMessage?.systemMessageType == .newConversation)

            let lastMessage = messages.first as? ZMSystemMessage
            XCTAssertTrue(lastMessage?.systemMessageType == .legalHoldEnabled)
        }
    }

    // MARK: - Discovering legal hold

    func testThatItExpiresAllPendingMessages_WhenLegalholdIsDiscovered() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let message = try! conversation.appendText(content: "Legal hold is coming to town") as! ZMOTRMessage
            Thread.sleep(forTimeInterval: 0.05)

            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: message)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
            XCTAssertEqual(conversation.messagesThatCausedSecurityLevelDegradation, [message])
        }
    }

    func testThatItExpiresPendingMesssageEdit_WhenLegalholdIsDiscovered() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let message = try! conversation.appendText(content: "Legal hold is coming to town") as! ZMOTRMessage
            message.delivered = true
            message.serverTimestamp = Date().addingTimeInterval(-ZMMessage.defaultExpirationTime() * 2)
            message.textMessageData?.editText("Legal hold is leaving", mentions: [], fetchLinkPreview: false)
            Thread.sleep(forTimeInterval: 0.05)

            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: message)

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
            XCTAssertEqual(conversation.messagesThatCausedSecurityLevelDegradation, [message])
        }
    }

    func testItResendsAllPreviouslyExpiredMessages_WhenConfirmingLegalholdPresence() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let message = try! conversation.appendText(content: "Legal hold is coming") as! ZMOTRMessage
            message.sender = otherUser

            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: message)
            XCTAssertEqual(conversation.legalHoldStatus, .pendingApproval)

            self.performPretendingSyncMocIsUiMoc {
                conversation.acknowledgePrivacyWarning(withResendIntent: true)
            }

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .enabled)

            XCTAssertFalse(message.isExpired)
            XCTAssertFalse(message.causedSecurityLevelDegradation)
            XCTAssertTrue(conversation.messagesThatCausedSecurityLevelDegradation.isEmpty)
        }
    }

    func testItUpdatesNeedsToVerifyLegalHold_WhenCallingVerifyLegalHoldSubjects() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let conversation = self.createConversation(in: self.syncMOC)

            // WHEN
            conversation.verifyLegalHoldSubjects()

            // THEN
            XCTAssertTrue(conversation.needsToVerifyLegalHold)
        }
    }

    func testThatItDoesntUpdateLegalHoldStatus_WhenNeedsToVerifyLegalHoldStatusIsTrue() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)
            conversation.needsToVerifyLegalHold = true

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [otherUser])

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    func testThatItDoesntUpdateLegalHoldStatus_WhenAnyClientStillNeedsToBeFetchedFromTheBackend() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            XCTAssertEqual(conversation.legalHoldStatus, .disabled)

            // WHEN
            let legalHoldClient = self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            legalHoldClient.needsToBeUpdatedFromBackend = true
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: [legalHoldClient], causedBy: [otherUser])

            // THEN
            XCTAssertEqual(conversation.legalHoldStatus, .disabled)
        }
    }

    // MARK: - Message Status Hints

    func testThatItUpdatesFromMessageHint_EnabledToDisabled() {
        assertLegalHoldHintBehavior(initiallyEnabled: true, receivedStatus: .disabled, expectedStatus: .disabled, expectSystemMessage: true, expectLegalHoldVerification: true, messageContent: {
            Text(content: "Legal hold is coming to town!")
        })
    }

    func testThatItUpdatesFromMessageHint_EnabledToDisabled_Ephemeral() {
        assertLegalHoldHintBehavior(initiallyEnabled: true, receivedStatus: .disabled, expectedStatus: .disabled, expectSystemMessage: true, expectLegalHoldVerification: true, messageContent: {
            Ephemeral(content: Text(content: "Legal hold is coming to town!"), expiresAfter: 60)
        })
    }

    func testThatItUpdatesFromMessageHint_DisabledToEnabled() {
        assertLegalHoldHintBehavior(initiallyEnabled: false, receivedStatus: .enabled, expectedStatus: .pendingApproval, expectSystemMessage: true, expectLegalHoldVerification: true, messageContent: {
            Text(content: "🙈🙉🙊")
        })
    }

    func testThatItUpdatesFromMessageHint_DisabledToEnabled_Ephemeral() {
        assertLegalHoldHintBehavior(initiallyEnabled: false, receivedStatus: .enabled, expectedStatus: .pendingApproval, expectSystemMessage: true, expectLegalHoldVerification: true, messageContent: {
            Ephemeral(content: Text(content: "🙈🙉🙊"), expiresAfter: 60)
        })
    }

    func testThatItDoesNotUpdateFromMessageHint_EnabledToEnabled() {
        assertLegalHoldHintBehavior(initiallyEnabled: true, receivedStatus: .enabled, expectedStatus: .pendingApproval, expectSystemMessage: false, expectLegalHoldVerification: false, messageContent: {
            Text(content: "Hello? Can you hear me?")
        })
    }

    func testThatItDoesNotUpdateFromMessageHint_DisabledToDisabled() {
        assertLegalHoldHintBehavior(initiallyEnabled: false, receivedStatus: .disabled, expectedStatus: .disabled, expectSystemMessage: false, expectLegalHoldVerification: false, messageContent: {
            Text(content: "Really not enabled.")
        })
    }

    func testThatItDoesNotUpdateFromMessageHint_EnabledReceivingMessageWithUnknownLegalHoldStatus() {
        assertLegalHoldHintBehavior(initiallyEnabled: true, receivedStatus: .unknown, expectedStatus: .pendingApproval, expectSystemMessage: false, expectLegalHoldVerification: false, messageContent: {
            Text(content: "I know nothing")
        })
    }

    // MARK: - Helpers

    @discardableResult
    private func createClient(ofType clientType: DeviceType, class deviceClass: DeviceClass, for user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: syncMOC)
        client.type = clientType
        client.deviceClass = deviceClass
        client.user = user
        return client
    }

    private func assertLegalHoldHintBehavior(initiallyEnabled: Bool,
                                             receivedStatus: LegalHoldStatus,
                                             expectedStatus: ZMConversationLegalHoldStatus,
                                             expectSystemMessage: Bool,
                                             expectLegalHoldVerification: Bool,
                                             messageContent: @escaping () -> MessageCapable, file: StaticString = #file, line: UInt = #line) {
        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID()

            self.createSelfClient(onMOC: self.syncMOC)
            self.createClient(ofType: .permanent, class: .phone, for: otherUser)

            if initiallyEnabled {
                self.createClient(ofType: .legalHold, class: .legalHold, for: otherUser)
            } else {
                self.createClient(ofType: .permanent, class: .phone, for: otherUser)
            }

            let conversation = self.createConversation(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]), role: nil)

            let lastMessageBeforeHint = conversation.lastMessage as? ZMSystemMessage
            XCTAssertEqual(conversation.legalHoldStatus, initiallyEnabled ? .pendingApproval : .disabled, file: file, line: line)

            // WHEN
            let nonce = UUID()
            var genericMessage = GenericMessage(content: messageContent(), nonce: nonce)
            genericMessage.setLegalHoldStatus(receivedStatus)

            let genericMessageData = try? genericMessage.serializedData()
            let payload: [String: Any] = [
                "conversation": conversation.remoteIdentifier!.transportString(),
                "from": otherUser.remoteIdentifier!.transportString(),
                "time": Date(),
                "type": "conversation.otr-message-add",
                "data": [
                    "text": genericMessageData?.base64String()
                ]
            ]

            let updateEvent = ZMUpdateEvent(uuid: UUID(), payload: payload, transient: false, decrypted: true, source: .download)!
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.syncMOC, prefetchResult: nil)

            // THEN
            let lastMessage = conversation.lastMessages(limit: 2).last as? ZMSystemMessage
            XCTAssertEqual(conversation.legalHoldStatus, expectedStatus, file: file, line: line)
            XCTAssertEqual(conversation.needsToVerifyLegalHold, expectLegalHoldVerification, file: file, line: line)

            if expectSystemMessage {
                XCTAssertNotEqual(lastMessage, lastMessageBeforeHint, file: file, line: line)
                XCTAssertEqual(lastMessage?.systemMessageType, expectedStatus.denotesEnabledComplianceDevice ? .legalHoldEnabled : .legalHoldDisabled, file: file, line: line)
                XCTAssertTrue(lastMessage?.users == [], file: file, line: line)
            } else {
                XCTAssertEqual(lastMessage, lastMessageBeforeHint, file: file, line: line)
            }
        }
    }

}
