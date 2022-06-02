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

import XCTest
@testable import WireDataModel

class ZMConversationTests_Silencing: ZMConversationTestsBase {

    func testThatSilencingUpdatesProperties() {
        // given
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = timestamp

        // when
        conversation.mutedMessageTypes = .all
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversation.silencedChangedTimestamp, timestamp)
        XCTAssertTrue(conversation.modifiedKeys!.contains(ZMConversationSilencedChangedTimeStampKey))
    }

    // We still want to synchronize silenced changes even if nothing has happend in between
    func testThatSilencingUpdatesPropertiesWhenLastServerTimestampHasNotChanged() {
        // given
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = timestamp
        conversation.silencedChangedTimestamp = timestamp

        // when
        conversation.mutedMessageTypes = .all
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversation.silencedChangedTimestamp, timestamp)
        XCTAssertTrue(conversation.modifiedKeys!.contains(ZMConversationSilencedChangedTimeStampKey))
    }

    func testThatSilencingUpdatesPropertiesWhenPerformedOnSEContext() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.lastServerTimeStamp = timestamp

            // when
            conversation.updateMuted(timestamp, synchronize: true)
            self.syncMOC.saveOrRollback()

            // then
            XCTAssertEqual(conversation.silencedChangedTimestamp, timestamp)
            XCTAssertTrue(conversation.modifiedKeys!.contains(ZMConversationSilencedChangedTimeStampKey))
        }
    }

    func archivedConversation(with mutedMessageTypes: MutedMessageTypes) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()

        let otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser.remoteIdentifier = UUID()

        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)

        conversation.isArchived = true
        conversation.mutedMessageTypes = mutedMessageTypes

        XCTAssertTrue(conversation.isArchived)
        XCTAssertEqual(conversation.mutedMessageTypes, mutedMessageTypes)

        return conversation
    }

    func event(for message: String, in conversation: ZMConversation, mentions: [Mention] = [], replyingTo quotedMessage: ZMClientMessage? = nil) -> ZMUpdateEvent {
        let text = Text(content: message, mentions: mentions, linkPreviews: [], replyingTo: quotedMessage)
        let message = GenericMessage(content: text, nonce: UUID())

        let dataString = try! message.serializedData().base64EncodedString()

        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddClientMessage, data: dataString)

        return ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: UUID())!
    }

    func testThatAppendingAMessageMentioningSelfInAnArchived_RegularMuted_ConversationUnarchivesIt() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.teamIdentifier = UUID()

        let conversation = archivedConversation(with: .regular)

        // WHEN
        let mention = Mention(range: NSRange(location: 0, length: 9), user: selfUser)
        let event = self.event(for: "@selfUser", in: conversation, mentions: [mention])

        self.performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }

        // THEN
        XCTAssertFalse(conversation.isArchived)
        XCTAssertEqual(conversation.mutedMessageTypes, .regular)
    }

    func testThatAppendingAMessageMentioningSelfInAnArchived_FullyMuted_ConversationDoesNotUnarchiveIt() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.teamIdentifier = UUID()

        let conversation = archivedConversation(with: .all)

        // WHEN
        let mention = Mention(range: NSRange(location: 0, length: 9), user: selfUser)
        let event = self.event(for: "@selfUser", in: conversation, mentions: [mention])

        self.performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }

        // THEN
        XCTAssertTrue(conversation.isArchived)
        XCTAssertEqual(conversation.mutedMessageTypes, .all)
    }

    func testThatAppendingAMessageQuotingSelfInAnArchived_RegularMuted_ConversationUnarchivesIt() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.teamIdentifier = UUID()

        let conversation = archivedConversation(with: .regular)

        // WHEN
        let quotedMessage = try! conversation.appendText(content: "Hello!", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: .create()) as! ZMClientMessage
        quotedMessage.sender = selfUser

        // appending the message unarchives the conversation, so archive it again.
        conversation.isArchived = true
        XCTAssertTrue(conversation.isArchived)

        let event = self.event(for: "Hi!", in: conversation, replyingTo: quotedMessage)

        self.performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }

        // THEN
        XCTAssertFalse(conversation.isArchived)
        XCTAssertEqual(conversation.mutedMessageTypes, .regular)
    }

    func testThatAppendingAMessageQuotingSelfInAnArchived_FullyMuted_ConversationDoesNotUnarchiveIt() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.teamIdentifier = UUID()

        let conversation = archivedConversation(with: .all)

        // WHEN
        let quotedMessage = try! conversation.appendText(content: "Hello!", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: .create()) as! ZMClientMessage
        quotedMessage.sender = selfUser

        // appending the message unarchives the conversation, so archive it again.
        conversation.isArchived = true
        XCTAssertTrue(conversation.isArchived)

        let event = self.event(for: "Hi!", in: conversation, replyingTo: quotedMessage)

        self.performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }

        // THEN
        XCTAssertTrue(conversation.isArchived)
        XCTAssertEqual(conversation.mutedMessageTypes, .all)
    }
}
