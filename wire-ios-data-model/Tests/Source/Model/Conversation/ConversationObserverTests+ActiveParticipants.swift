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

// MARK: - Participants
extension ConversationObserverTests {

    func testThatItRecalculatesActiveParticipantsWhenIsSelfActiveUserKeyChanges() {
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

        // when

        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: { conversation, _ in
                                                    conversation.minus(user: ZMUser.selfUser(in: uiMOC), isFromLocal: true)},
                                                expectedChangedFields: ["nameChanged",
                                                                        "participantsChanged",
                                                                        "activeParticipantsChanged"],
                                                expectedChangedKeys: ["localParticipantRoles", "displayName", "activeParticipants"]
        )

        // then
        XCTAssertFalse(conversation.isSelfAnActiveMember)
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.activeParticipants.count, 2)
    }

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

        // when

        checkThatItNotifiesTheObserverOfAChange(conversation,
                                                modifier: { conversation, _ in
                                                    conversation.internalRemoveParticipants([user2],
                                                                                            sender: user1)
                                                          },
                                                expectedChangedFields: ["nameChanged",
                                                                        "participantsChanged",
                                                                        "activeParticipantsChanged"
                                                                       ],
                                                expectedChangedKeys: ["localParticipantRoles",
                                                                      "displayName",
                                                                      "activeParticipants"
                                                                     ]
        )

        // then
        XCTAssert(conversation.isSelfAnActiveMember)
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.activeParticipants.count, 2)
    }
}
