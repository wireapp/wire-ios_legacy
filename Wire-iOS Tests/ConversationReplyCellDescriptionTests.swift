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
@testable import Wire

final class ConversationReplyCellDescriptionTests: CoreDataSnapshotTestCase {

    func testThatItDisplaysNameOfOriginalSender() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")!
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversation = otherUserConversation

        // WHEN
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)

        // THEN
        XCTAssertEqual(cellDescription.configuration.senderName, otherUser.name)
    }

    func testThatItDisplaysCorrectNameForSelfReply() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")!
        message.senderUser = MockUserType.createSelfUser(name: "Alice")
        message.conversation = otherUserConversation

        // WHEN
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)

        // THEN
        XCTAssertEqual(cellDescription.configuration.senderName, "You")
    }

    func testThatItFormatsDateForPastDay() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")!
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversation = otherUserConversation
        message.serverTimestamp = Date(timeIntervalSince1970: 1497798000)

        // WHEN
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)

        // THEN
        XCTAssertEqual(cellDescription.configuration.timestamp, "Original message from 6/18/17")
    }

    func testThatItFormatsDateForToday() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")!
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversation = otherUserConversation
        message.serverTimestamp = .today(at: 9, 41)

        // WHEN
        let cellDescription = ConversationReplyCellDescription(quotedMessage: message)

        // THEN
        XCTAssertEqual(cellDescription.configuration.timestamp, "Original message from 9:41 AM")
    }

}
