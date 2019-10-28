
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
@testable import Wire

final class NewMessagesMatcherTests: XCTestCase {

    var sut: NewMessagesMatcher!

    override func setUp() {
        super.setUp()
        sut = NewMessagesMatcher()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForShouldNotSummerizeCase() {
        let conversationStatus: ConversationStatus = ConversationStatus(isGroup: true,
                                                                        hasMessages: true,
                                                                        hasUnsentMessages: true,
                                                                        messagesRequiringAttention: [],
                                                                        messagesRequiringAttentionByType: [:],
                                                                        isTyping: true,
                                                                        mutedMessageTypes: MutedMessageTypes(),
                                                                        isOngoingCall: true,
                                                                        isBlocked: true,
                                                                        isSelfAnActiveMember: true,
                                                                        hasSelfMention: true,
                                                                        hasSelfReply: true)

        let mockConversation = ZMConversation()

        let string = sut.description(with: conversationStatus, conversation: mockConversation)

        XCTAssertEqual(string, NSAttributedString())
    }

    func testForSummerizeCase() {
        let messagesRequiringAttentionByType: [StatusMessageType: UInt] = [.mention: 1,
                                                                             .text: 2,
                                                                             .file: 3,
                                                                             .newConversation: 4]


        let conversationStatus: ConversationStatus = ConversationStatus(isGroup: true,
                                                                        hasMessages: true,
                                                                        hasUnsentMessages: true,
                                                                        messagesRequiringAttention: [],
                                                                        messagesRequiringAttentionByType: messagesRequiringAttentionByType,
                                                                        isTyping: true,
                                                                        mutedMessageTypes: MutedMessageTypes.regular,
                                                                        isOngoingCall: true,
                                                                        isBlocked: true,
                                                                        isSelfAnActiveMember: true,
                                                                        hasSelfMention: false,
                                                                        hasSelfReply: false)

        let mockConversation = ZMConversation()

        let string = sut.description(with: conversationStatus, conversation: mockConversation)

        XCTAssertEqual(string?.string, "1 mention, 5 messages")
    }
}
