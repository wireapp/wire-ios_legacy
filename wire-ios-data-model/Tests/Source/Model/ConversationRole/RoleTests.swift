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

final class RoleTests: ZMBaseManagedObjectTest {

    let payload: [String: Any] = [
        "actions": [
            "add_conversation_member",
            "remove_conversation_member",
            "modify_conversation_name",
            "modify_conversation_message_timer",
            "modify_conversation_receipt_mode",
            "modify_conversation_access",
            "modify_other_conversation_member",
            "leave_conversation",
            "delete_conversation"
        ],
        "conversation_role": "wire_admin"
    ]

    var mockConversation: ZMConversation!

    override func setUp() {
        super.setUp()

        mockConversation = ZMConversation.insertNewObject(in: uiMOC)
    }

    override func tearDown() {
        mockConversation = nil
        super.tearDown()
    }

    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set(arrayLiteral: Role.nameKey,
                                             Role.teamKey,
                                             Role.conversationKey,
                                             Role.actionsKey,
                                             Role.participantRolesKey)

        let role = Role.insertNewObject(in: uiMOC)

        XCTAssertEqual(role.keysTrackedForLocalModifications(), expectedKeys)
    }

    func testThatActionsAreCreatedFromPayload() {
        // given & when
        let sut = Role.createOrUpdate(with: payload,
                                      teamOrConversation: .conversation(mockConversation),
                                      context: uiMOC)!

        // then
        XCTAssertEqual(sut.actions.count, 9)
        XCTAssertEqual(sut.name, "wire_admin")

        let action = sut.actions.sorted(by: { $0.name < $1.name }).first!
        XCTAssertEqual(action.name, "add_conversation_member")
    }

    func testThatCreateOrUpdate_FetchesAnExistingRole() {
        // given
        let role = Role.createOrUpdate(with: payload,
                                       teamOrConversation: .conversation(mockConversation),
                                       context: uiMOC)

        // when
        let fetchedRole = Role.createOrUpdate(with: payload,
                                              teamOrConversation: .conversation(mockConversation),
                                              context: uiMOC)

        // then
        XCTAssertEqual(role, fetchedRole)
    }
}
