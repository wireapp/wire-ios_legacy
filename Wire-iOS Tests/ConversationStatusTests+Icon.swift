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

class ConversationStatusTests_Icon: CoreDataSnapshotTestCase {

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
    }

    override var needsCaches: Bool {
        return true
    }

    enum UnreadMessageType {
        case text
        case mention
    }

    func conversationWithUnread(_ messageType: UnreadMessageType, muted: MutedMessageTypes) -> ZMConversation {
        let conversation = self.otherUserConversation!
        conversation.mutedMessageTypes = muted

        switch messageType {
        case .text:
            (conversation.append(text: "test") as! ZMMessage).sender = self.otherUser
        case .mention:
            let selfMention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
            (conversation.append(text: "@self test", mentions: [selfMention]) as! ZMMessage).sender = self.otherUser
            conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        }
        conversation.lastReadServerTimeStamp = Date.distantPast
        return conversation
    }

    func testThatItShowsBadgeCountWithMessageWhenAllNotifications() {
        // given
        let sut = conversationWithUnread(.text, muted: .none)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .unreadMessages(count: 1))
    }

    func testThatItShowsMentionIconWithMentionWhenAllNotifications() {
        // GIVEN
        let sut = conversationWithUnread(.mention, muted: .none)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .mention)
    }

    func testThatItShowsSilencedIconWithMessageWhenMentionsOnly() {
        // given
        let sut = conversationWithUnread(.text, muted: .regular)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .silenced)
    }

    func testThatItShowsMentionIconWithMentionWhenMentionsOnly() {
        // given
        let sut = conversationWithUnread(.mention, muted: .regular)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .mention)
    }

    func testThatItShowsSilencedIconWithMessageWhenNoNotifications() {
        // given
        let sut = conversationWithUnread(.text, muted: .all)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .silenced)
    }

    func testThatItShowsSilencedIconWithMentionWhenNoNotifications() {
        // given
        let sut = conversationWithUnread(.mention, muted: .all)

        // when
        let icon = sut.status.icon(for: sut)

        // then
        XCTAssertEqual(icon, .silenced)
    }
}
