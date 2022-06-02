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

import Foundation
@testable import WireDataModel

final class ConversationGapsAndWindowTests: ZMConversationTestsBase {

    func testThatItInsertsANewConversation() {
        // given
        let user1 = createUser()
        let user2 = createUser()
        let user3 = createUser()
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC,
                                                                  participants: [user1, user2, user3],
                                                                  name: nil,
                                                                  team: nil,
                                                                  allowGuests: true,
                                                                  readReceipts: false,
                                                                  participantsRole: nil)

        // then
        let conversations = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        XCTAssertEqual(conversations.count, 1)
        let fetchedConversation = conversations[0] as? ZMConversation
        XCTAssertEqual(fetchedConversation?.conversationType, .group)
        XCTAssertEqual(conversation?.objectID, fetchedConversation?.objectID)

        let expectedParticipants = Set<AnyHashable>([user1, user2, user3, selfUser])
        XCTAssertEqual(expectedParticipants, conversation?.localParticipants)
    }

    func testThatItInsertsANewConversationInUIContext() {
        // given

        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        let user3 = ZMUser.insertNewObject(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2, user3], name: nil, team: nil, allowGuests: true, readReceipts: false, participantsRole: nil)

        try! uiMOC.save()

        // then
        XCTAssertNotNil(conversation)

        let fetchRequest = ZMConversation.sortedFetchRequest()
        let conversations = uiMOC.executeFetchRequestOrAssert(fetchRequest)

        XCTAssertEqual(conversations.count, 1)
        let fetchedConversation = conversations[0] as? ZMConversation
        XCTAssertEqual(conversation?.objectID, fetchedConversation?.objectID)

        let expectedParticipants = Set<AnyHashable>([user1, user2, user3, selfUser])
        XCTAssertEqual(expectedParticipants, conversation?.localParticipants)

    }

}
