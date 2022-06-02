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

class InvalidConversationRemovalTests: DiskDatabaseTest {

    func testThatItOnlyRemovesInvalidConversations() throws {
        // Given
        let user = createUser()
        let conversationTypes: [ZMConversationType] = [.invalid, .group, .oneOnOne, .connection, .`self`]
        let conversations = conversationTypes.map { conversationType -> ZMConversation in
            let conversation = ZMConversation.insertNewObject(in: moc)
            conversation.conversationType = conversationType
            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
            return conversation
        }
        try self.moc.save()

        // When
        WireDataModel.InvalidConversationRemoval.removeInvalid(in: self.moc)

        // Then - invalid conversation is deleted
        let invalidConversation = conversations[0]
        XCTAssertTrue(invalidConversation.isDeleted)
        XCTAssertTrue(invalidConversation.isZombieObject)

        // but all other conversations are still there
        for conversation in conversations.suffix(from: 1) {
            XCTAssertFalse(conversation.isDeleted)
            XCTAssertFalse(conversation.isZombieObject)
        }
    }

}
