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
@testable import WireSyncEngine

class ConversationTests_LegalHold: ConversationTestsBase {

    func testThatItInsertsLegalHoldSystemMessage_WhenDiscoveringLegalHoldClientOnSending() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)
        mockTransportSession.performRemoteChanges { (session) in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        // when
        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let secondToLastMessage = conversation?.lastMessages()[1] as? ZMSystemMessage
        XCTAssertEqual(secondToLastMessage?.systemMessageType, .legalHoldEnabled)
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenLegalHoldClientIsReportedAsDeletedOnSending() {
        // given
        XCTAssertTrue(login())
        let conversation = self.conversation(for: selfToUser1Conversation)
        var legalHoldClient: MockUserClient!
        mockTransportSession.performRemoteChanges { (session) in
            legalHoldClient = session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        conversation?.acknowledgePrivacyWarning(withResendIntent: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .enabled)

        mockTransportSession.performRemoteChanges { (session) in
            session.deleteUserClient(withIdentifier: legalHoldClient.identifier!, for: self.user1)
        }

        // when
        userSession?.perform {
            try! conversation?.appendText(content: "Hello")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastMessage = conversation?.lastMessage as? ZMSystemMessage
        XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldDisabled)
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenUserUnderLegalHoldIsJoiningConversation() {
        // given
        XCTAssertTrue(login())

        let legalHoldUser = self.user(for: user1)!
        let groupConversation = self.conversation(for: self.groupConversation)
        mockTransportSession.performRemoteChanges { (session) in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }
        legalHoldUser.fetchUserClients()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        groupConversation?.addParticipants([legalHoldUser], completion: { _ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastMessage = groupConversation?.lastMessage as? ZMSystemMessage
        XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldEnabled)
        XCTAssertEqual(groupConversation?.legalHoldStatus, .pendingApproval)
    }

    func testThatItInsertsLegalHoldSystemMessage_WhenUserUnderLegalHoldIsLeavingConversation() {
        // given
        XCTAssertTrue(login())

        let legalHoldUser = self.user(for: user1)!
        let groupConversation = self.conversation(for: self.groupConversation)

        mockTransportSession.performRemoteChanges { (session) in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }
        legalHoldUser.fetchUserClients()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        groupConversation?.addParticipants([legalHoldUser], completion: { _ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(groupConversation?.legalHoldStatus, .pendingApproval)

        // when
        groupConversation?.removeParticipant(legalHoldUser, completion: {_ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let lastMessage = groupConversation?.lastMessage as? ZMSystemMessage
        XCTAssertEqual(lastMessage?.systemMessageType, .legalHoldDisabled)
        XCTAssertEqual(groupConversation?.legalHoldStatus, .disabled)
    }

    // MARK: Legal hold status flag

    func testThatItUpdatesLegalHoldStatus_WhenReceivingLegalHoldStatusFlagEnabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { (session) in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        // when
        mockTransportSession.performRemoteChanges { (_) in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.enabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }

        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

    func testThatItUpdatesLegalHoldStatus_WhenReceivingLegalHoldStatusFlagDisabled() {
        // given
        XCTAssertTrue(login())

        let legalHoldUser = self.user(for: user1)!
        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        var legalHoldClient: MockUserClient!
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { (session) in
            legalHoldClient = session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        legalHoldUser.fetchUserClients()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        // when
        mockTransportSession.performRemoteChanges { (session) in
            session.deleteUserClient(withIdentifier: legalHoldClient.identifier!, for: self.user1)
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.disabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItRepairsAnIncorrectLegalHoldStatus_AfterReceivingLegalHoldStatusFlagEnabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        // when
        mockTransportSession.performRemoteChanges { (_) in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.enabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

         // then
        XCTAssertEqual(conversation?.legalHoldStatus, .disabled)
    }

    func testThatItRepairsAnIncorrectLegalHoldStatus_AfterReceivingLegalHoldStatusFlagDisabled() {
        // given
        XCTAssertTrue(login())

        let selfUserClient = self.selfUser.clients.anyObject() as! MockUserClient
        let otherUserClient = user1.clients.anyObject() as! MockUserClient
        let conversation = self.conversation(for: selfToUser1Conversation)

        mockTransportSession.performRemoteChanges { (session) in
            session.registerClient(for: self.user1, label: "Legal Hold", type: "legalhold", deviceClass: "legalhold")
        }

        userSession?.perform {
            try! conversation!.appendText(content: "This is the best group!")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)

        // when
        mockTransportSession.performRemoteChanges { (_) in
            var genericMessage = GenericMessage(content: Text(content: "Hello"))
            genericMessage.setLegalHoldStatus(.disabled)
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: otherUserClient, to: selfUserClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail("Error in adding data: \(error)")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.legalHoldStatus, .pendingApproval)
    }

}
