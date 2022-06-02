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

import Foundation
@testable import WireDataModel

extension ZMConversation {
    @objc var isFullyMuted: Bool {
        return mutedMessageTypes == .all
    }

    @objc var isOnlyMentionsAndReplies: Bool {
        return mutedMessageTypes == .regular
    }
}

class ZMConversationTests_Mute: ZMConversationTestsBase {

    func testThatItDoesNotCountsSilencedConversationsUnreadContentAsUnread() {
        syncMOC.performGroupedAndWait { _ in
            // given
            XCTAssertEqual(ZMConversation.unreadConversationCount(in: self.syncMOC), 0)

            let conversation = self.insertConversation(withUnread: true)
            conversation.mutedMessageTypes = .all

            // when
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            // then
            XCTAssertEqual(ZMConversation.unreadConversationCountExcludingSilenced(in: self.syncMOC, excluding: nil), 0)

        }
    }

    func testThatTheConversationIsNotSilencedByDefault() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        // then
        XCTAssertEqual(conversation.mutedMessageTypes, .none)
    }

    func testThatItReturnsMutedAllViaGetterForNonTeam() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = [.regular]

        // then
        XCTAssertEqual(conversation.mutedMessageTypes, .all)
    }
}

extension ZMConversationTests_Mute {

    // MARK: Conversation mute setting

    func testMessageShouldNotCreateNotification_SelfMessage() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_FullySilenced() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .all
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_RegularSilenced_NotATextMessage() throws {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular
        let message = try conversation.appendKnock()
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_RegularSilenced_HasNoMention() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldCreateNotification_NotSilenced() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testMessageShouldCreateNotification_RegularSilenced_HasMention() {
        // GIVEN
        selfUser.teamIdentifier = UUID()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular
        selfUser.teamIdentifier = UUID()
        let message = try! conversation.appendText(content: "@you", mentions: [Mention(range: NSRange(location: 0, length: 4), user: selfUser)], fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testMessageShouldCreateNotification_RegularSilenced_HasReply() {
        // GIVEN
        selfUser.teamIdentifier = UUID()

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular

        let quotedMessage = try! conversation.appendText(content: "Hi!", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: UUID())
        (quotedMessage as! ZMClientMessage).sender = selfUser

        let message = try! conversation.appendText(content: "Hello!", mentions: [], replyingTo: quotedMessage, fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user

        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    // MARK: - Muted by availability

    func testMessageShouldNotCreateNotification_AvailabilityAway() {
        // GIVEN
        selfUser.availability = .away
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user

        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_AvailabilityBusy_NotATextMessage() throws {
        // GIVEN
        selfUser.availability = .busy
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try conversation.appendKnock()
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_AvailabilityBusy_HasNoMention() {
        // GIVEN
        selfUser.availability = .busy
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldCreateNotification_AvailabilityAvailable() {
        // GIVEN
        selfUser.availability = .available
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user

        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testMessageShouldCreateNotification_AvailabilityNone() {
        // GIVEN
        selfUser.availability = .none
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = try! conversation.appendText(content: "Hello")
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user

        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testMessageShouldCreateNotification_AvailabilityBusy_HasMention() {
        // GIVEN
        selfUser.teamIdentifier = UUID()
        selfUser.availability = .busy

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        selfUser.teamIdentifier = UUID()
        let message = try! conversation.appendText(content: "@you", mentions: [Mention(range: NSRange(location: 0, length: 4), user: selfUser)], fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testMessageShouldCreateNotification_AvailabilityBusy_HasReply() {
        // GIVEN
        selfUser.teamIdentifier = UUID()
        selfUser.availability = .busy

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        let quotedMessage = try! conversation.appendText(content: "Hi!", mentions: [], replyingTo: nil, fetchLinkPreview: false, nonce: UUID())
        (quotedMessage as! ZMClientMessage).sender = selfUser

        let message = try! conversation.appendText(content: "Hello!", mentions: [], replyingTo: quotedMessage, fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user

        // THEN
        XCTAssertFalse(message.isSilenced)
    }

    // MARK: - Muted by availability & Conversation mute setting

    func testMessageShouldNotCreateNotification_AvailabilityBusy_ButFullySilenced_HasMention() {
        // GIVEN
        selfUser.teamIdentifier = UUID()
        selfUser.availability = .busy

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .all

        let message = try! conversation.appendText(content: "@you", mentions: [Mention(range: NSRange(location: 0, length: 4), user: selfUser)], fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

    func testMessageShouldNotCreateNotification_AvailabilityAway_ButRegularSilenced_HasMention() {
        // GIVEN
        selfUser.teamIdentifier = UUID()
        selfUser.availability = .away

        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular

        let message = try! conversation.appendText(content: "@you", mentions: [Mention(range: NSRange(location: 0, length: 4), user: selfUser)], fetchLinkPreview: false, nonce: UUID())
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        (message as! ZMClientMessage).sender = user
        // THEN
        XCTAssertTrue(message.isSilenced)
    }

}

// MARK: - Alarming messages
class ZMConversationTest_Mute_Alarming: BaseCompositeMessageTests {

    func testCompositeMessageShouldCreateNotification_AvailabilityBusy() {
        // GIVEN
        selfUser.availability = .busy
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = compositeMessage(with: compositeProto(items: compositeItemText()))
        conversation.append(message)
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender = user

        // WHEN / THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testCompositeMessageShouldCreateNotification_AvailabilityAway() {
        // GIVEN
        selfUser.availability = .away
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = compositeMessage(with: compositeProto(items: compositeItemText()))
        conversation.append(message)
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender = user

        // WHEN / THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testCompositeMessageShouldCreateNotification_FullySilenced() {
        // GIVEN
        let message = compositeMessage(with: compositeProto(items: compositeItemText()))
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .all
        conversation.append(message)
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender = user

        // WHEN / THEN
        XCTAssertFalse(message.isSilenced)
    }

    func testCompositeMessageShouldCreateNotification_RegularSilenced() {
        // GIVEN
        let message = compositeMessage(with: compositeProto(items: compositeItemText()))
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.mutedMessageTypes = .regular
        conversation.append(message)
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender = user

        // WHEN / THEN
        XCTAssertFalse(message.isSilenced)
    }
}
