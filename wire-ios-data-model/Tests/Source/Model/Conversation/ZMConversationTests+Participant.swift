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

@testable import WireDataModel

extension ZMConversationTests {
    func testThatItRecalculatesActiveParticipantsWhenOtherActiveParticipantsKeyChanges() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.add(user: ZMUser.selfUser(in: uiMOC), isFromLocal: true)

        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        conversation.internalAddParticipants([user1, user2])

        XCTAssert(conversation.isSelfAnActiveMember)
        XCTAssertEqual(conversation.participantRoles.count, 3)
        XCTAssertEqual(conversation.activeParticipants.count, 3)

        // expect
        keyValueObservingExpectation(for: conversation, keyPath: "activeParticipants", expectedValue: nil)

        // when

        conversation.internalRemoveParticipants([user2],
                                                sender: user1)

        uiMOC.processPendingChanges()

        // then
        XCTAssert(conversation.isSelfAnActiveMember)
        XCTAssertEqual(conversation.participantRoles.count, 3)
        XCTAssertEqual(conversation.activeParticipants.count, 2)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }
}
