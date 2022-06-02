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

class ZMMessageTests_ShouldGenerateUnreadCount: BaseZMClientMessageTests {

    // MARK: New Conversation

    func testThatNewConversationSystemMessage_fromOtherGeneratesUnreadCount() {
        // given
        let conversation = createConversation(in: uiMOC)
        conversation.lastServerTimeStamp = Date()

        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .newConversation
        systemMessage.sender = user1
        systemMessage.visibleInConversation = conversation

        // then
        XCTAssertTrue(systemMessage.shouldGenerateUnreadCount())
    }

    func testThatNewConversationSystemMessage_fromSelfDoesntGenerateUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .newConversation
        systemMessage.sender = selfUser

        // then
        XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
    }

    // MARK: Add Participants

    func testThatAddParticipantSystemMessage_fromSelfDoesntGenerateUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsAdded
        systemMessage.sender = selfUser
        systemMessage.users = Set(arrayLiteral: user1)

        // then
        XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
    }

    func testThatAddParticipantSystemMessage_fromOtherInvolvingSomeoneElseDoesntGenerateUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsAdded
        systemMessage.sender = user1
        systemMessage.users = Set(arrayLiteral: user2)

        // then
        XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
    }

    func testThatAddParticipantSystemMessage_fromOtherInvolvingSelfGeneratesUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsAdded
        systemMessage.sender = user1
        systemMessage.users = Set(arrayLiteral: selfUser)

        // then
        XCTAssertTrue(systemMessage.shouldGenerateUnreadCount())
    }

    // MARK: Remove Participants

    func testThatRemoveParticipantSystemMessage_fromSelfDoesntGenerateUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsRemoved
        systemMessage.sender = selfUser
        systemMessage.users = Set(arrayLiteral: user1)

        // then
        XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
    }

    func testThatRemoveParticipantSystemMessage_fromOtherInvolvingSomeoneElseDoesntGenerateUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsRemoved
        systemMessage.sender = user1
        systemMessage.users = Set(arrayLiteral: user2)

        // then
        XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
    }

    func testThatRemoveParticipantSystemMessage_fromOtherInvolvingSelfGeneratesUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .participantsRemoved
        systemMessage.sender = user1
        systemMessage.users = Set(arrayLiteral: selfUser)

        // then
        XCTAssertTrue(systemMessage.shouldGenerateUnreadCount())
    }

    // MARK: Missed Call

    func testThatMissedCallSystemMessage_generatesUnreadCount() {
        // given
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage.systemMessageType = .missedCall
        systemMessage.sender = user1

        // then
        XCTAssertTrue(systemMessage.shouldGenerateUnreadCount())
    }

    // MARK: Non-unread count generating system messages

    func testThatRemainingSystemMessages_doesntGenerateUnreadCount() {

        let nonUnreadCountGeneratingSystemMessages: [ZMSystemMessageType] = [.connectionRequest,
                                                                             .connectionUpdate,
                                                                             .conversationIsSecure,
                                                                             .conversationNameChanged,
                                                                             .decryptionFailed,
                                                                             .decryptionFailed_RemoteIdentityChanged,
                                                                             .ignoredClient,
                                                                             .messageDeletedForEveryone,
                                                                             .messageTimerUpdate,
                                                                             .newClient,
                                                                             .performedCall,
                                                                             .potentialGap,
                                                                             .reactivatedDevice,
                                                                             .readReceiptsDisabled,
                                                                             .readReceiptsEnabled,
                                                                             .readReceiptsOn,
                                                                             .teamMemberLeave,
                                                                             .usingNewDevice]

        for systemMessageType in nonUnreadCountGeneratingSystemMessages {
            // given
            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
            systemMessage.systemMessageType = systemMessageType
            systemMessage.sender = user1

            // then
            XCTAssertFalse(systemMessage.shouldGenerateUnreadCount())
        }
    }

}
