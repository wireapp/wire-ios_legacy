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
import XCTest
@testable import Wire

class ConversationStatusLineTests_Muting: CoreDataSnapshotTestCase {

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
    }

    override var needsCaches: Bool {
        return true
    }
}

// MARK: - Only replies
extension ConversationStatusLineTests_Muting {
    func testStatusShowSpecialSummaryForSingleEphemeralReplyWhenOnlyReplies_oneToOne() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.messageDestructionTimeout = .local(100)

        let selfMessage = appendSelfMessage(to: sut)

        appendReply(to: sut, selfMessage: selfMessage)
        sut.mutedMessageTypes = .regular
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Replied to your message")
    }

    /// TODO: move this test to SE
    func testStatusShowSpecialSummaryForSingleEphemeralReplyWhenOnlyReplies_group() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.addParticipantAndSystemMessageIfMissing(createUser(name: "other"), date: nil)
        sut.messageDestructionTimeout = .local(100)

        let selfMessage = appendSelfMessage(to: sut)

        appendReply(to: sut, selfMessage: selfMessage)
        markAllMessagesAsUnread(in: sut)

        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Someone replied to your message")
    }

    func testStatusShowSummaryForMultipleEphemeralRepliesWhenOnlyReplies() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.messageDestructionTimeout = .local(100)

        let selfMessage = appendSelfMessage(to: sut)

        for _ in 1...5 {
            appendReply(to: sut, selfMessage: selfMessage)
        }
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Someone replied to your message")
    }

    func testStatusShowSummaryForMultipleMessagesAndReplyWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.mutedMessageTypes = [.all]
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }

        let selfMessage = appendSelfMessage(to: sut)

        appendReply(to: sut, selfMessage: selfMessage)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "1 reply, 5 messages")
    }

    func testStatusShowSummaryForOneReplyWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.mutedMessageTypes = [.all]

        let selfMessage = appendSelfMessage(to: sut)

        appendReply(to: sut, selfMessage: selfMessage)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "1 reply")
    }

    func testStatusShowSummaryForMultipleRepliesAndMultipleMessagesWhenOnlyReplies() {
        // GIVEN
        let sut = self.otherUserConversation!
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }

        let selfMessage = appendSelfMessage(to: sut)

        for _ in 1...5 {
            appendReply(to: sut, selfMessage: selfMessage)
        }
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "5 replies, 5 messages")
    }

}

// MARK: - mentions & replies
extension ConversationStatusLineTests_Muting {
    func testStatusShowSummaryForMultipleMentionsAndRepliesAndMultipleMessagesWhenOnlyMentionsAndReplies() {
        // GIVEN
        let sut = self.otherUserConversation!
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }

        let selfMessage = appendSelfMessage(to: sut)

        for _ in 1...5 {
            appendReply(to: sut, selfMessage: selfMessage)
        }

        for _ in 1...5 {
            appendMention(to: sut)
        }

        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "5 mentions, 5 replies, 5 messages")
    }

}

// MARK: - Only mentions
extension ConversationStatusLineTests_Muting {
    func testStatusShowSummaryForSingleMessageWhenOnlyMentions() {
        // GIVEN
        let sut = self.otherUserConversation!
        appendTextMessage(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "1 message")
    }

    func testStatusShowSpecialSummaryForSingleEphemeralMentionWhenOnlyMentions_oneToOne() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.messageDestructionTimeout = .local(100)
        appendMention(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Mentioned you")
    }

    func testStatusShowSpecialSummaryForSingleEphemeralMentionWhenOnlyMentions_group() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.addParticipantAndSystemMessageIfMissing(createUser(name: "other"), date: nil)
        sut.messageDestructionTimeout = .local(100)
        appendMention(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Someone mentioned you")
    }

    func testStatusShowSummaryForMultipleEphemeralMentionsWhenOnlyMentions() {
        // GIVEN
        let sut = self.createGroupConversation()
        sut.messageDestructionTimeout = .local(100)
        for _ in 1...5 {
            appendMention(to: sut)
        }
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "5 mentions")
    }

    func testStatusShowContentForSingleMentionWhenOnlyMentions() {
        // GIVEN
        let sut = self.otherUserConversation!
        appendTextMessage(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "1 message")
    }

    func testStatusShowSummaryForMultipleMentionsWhenOnlyMentions() {
        // GIVEN
        let sut = self.otherUserConversation!
        for _ in 1...5 {
            appendMention(to: sut)
        }
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "5 mentions")
    }

    func testStatusShowSummaryForMultipleMentionsAndMultipleMessagesWhenOnlyMentions() {
        // GIVEN
        let sut = self.otherUserConversation!
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }
        for _ in 1...5 {
            appendMention(to: sut)
        }
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .regular

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "5 mentions, 5 messages")
    }
}

// MARK: - No notifications
extension ConversationStatusLineTests_Muting {
    func testStatusShowSummaryForSingleMentionWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        appendMention(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .all

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "1 mention")
    }

    func testStatusShowSummaryForSingleEphemeralMentionWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.messageDestructionTimeout = .local(100)
        appendMention(to: sut)
        markAllMessagesAsUnread(in: sut)
        sut.mutedMessageTypes = .all

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "1 mention")
    }

    func testStatusShowSummaryForMultipleMessagesWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.mutedMessageTypes = [.all]
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "5 messages")
    }

    func testStatusShowSummaryForMultipleVariousMessagesWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.mutedMessageTypes = [.all]
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }
        for _ in 1...5 {
            appendImage(to: sut)
        }
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "10 messages")
    }

    func testStatusShowSummaryForMultipleMessagesAndMentionWhenNoNotifications() {
        // GIVEN
        let sut = self.otherUserConversation!
        sut.mutedMessageTypes = [.all]
        for _ in 1...5 {
            appendTextMessage(to: sut)
        }
        appendMention(to: sut)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "1 mention, 5 messages")
    }

}
