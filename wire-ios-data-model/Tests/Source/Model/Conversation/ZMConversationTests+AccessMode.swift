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
@testable import WireDataModel

class ZMConversationAccessModeTests: ZMConversationTestsBase {
    func conversation() -> ZMConversation {
        return ZMConversation.insertNewObject(in: self.uiMOC)
    }

    var sut: ZMConversation!
    var team: Team!

    override func setUp() {
        super.setUp()
        team = Team.insertNewObject(in: self.uiMOC)
        sut = conversation()
    }

    override func tearDown() {
        team = nil
        sut = nil
        super.tearDown()
    }

    func testThatItCanSetTheMode() {
        sut.accessMode = .teamOnly
        XCTAssertEqual(sut.accessMode, .teamOnly)
        // when
        sut.accessMode = .allowGuests
        // then
        XCTAssertEqual(sut.accessMode, .allowGuests)
    }

    func testAllowingGuests() {
        // GIVEN
        sut.accessRoles = [.teamMember, .service]
        sut.accessMode = .teamOnly

        // WHEN
        sut.allowGuests = true

        XCTAssertEqual(sut.accessMode, .allowGuests)
        XCTAssertEqual(sut.accessRoles, [.teamMember, .nonTeamMember, .service, .guest])
    }

    func testDisallowingGuests() {
        // GIVEN
        sut.accessRoles = [.teamMember, .nonTeamMember, .service, .guest]
        sut.accessMode = .allowGuests

        // WHEN
        sut.allowGuests = false

        XCTAssertEqual(sut.accessMode, .teamOnly)
        XCTAssertEqual(sut.accessRoles, [.teamMember, .service])
    }

    func testAllowingServices() {
        // GIVEN
        sut.accessRoles = [.teamMember]

        // WHEN
        sut.allowServices = true

        // THEN
        XCTAssertEqual(sut.accessRoles, [.teamMember, .service])
    }

    func testDisallowingServices() {
        // GIVEN
        sut.accessRoles = [.teamMember, .service]

        // WHEN
        sut.allowServices = false

        // THEN
        XCTAssertEqual(sut.accessRoles, [.teamMember])
    }

    func testAllowingGuestsAndServices() {
        // GIVEN
        sut.accessRoles = [.teamMember]
        sut.accessMode = .teamOnly

        // WHEN
        sut.allowGuests = true
        sut.allowServices = true

        // THEN
        XCTAssertEqual(sut.accessMode, .allowGuests)
        XCTAssertEqual(sut.accessRoles, [.nonTeamMember, .teamMember, .guest, .service])
    }

    func testDisallowingGuestsAndServices() {
        // GIVEN
        sut.accessRoles = [.teamMember, .guest, .nonTeamMember, .service]
        sut.accessMode = .allowGuests

        // WHEN
        sut.allowGuests = false
        sut.allowServices = false

        // THEN
        XCTAssertEqual(sut.accessMode, .teamOnly)
        XCTAssertEqual(sut.accessRoles, [.teamMember])
    }

    func testDefaultMode() {
        // when & then
        XCTAssertEqual(sut.accessMode, nil)
    }

    func testThatItCanReadTheMode() {
        // when
        sut.accessMode = []
        // then
        XCTAssertEqual(sut.accessMode, [])
    }

    func testThatItIgnoresAccessModeStringsKey() {
        // given
        sut.accessModeStrings = ["invite"]
        // when
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        // then
        XCTAssertFalse(sut.keysThatHaveLocalModifications.contains("accessModeStrings"))

    }

    func testThatItIgnoresAccessRoleStringsKeyV2() {
        // given
        sut.accessRoleStringsV2 = ["guest"]
        // when
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        // then
        XCTAssertFalse(sut.keysThatHaveLocalModifications.contains("accessRoleStringsV2"))
    }

    let testSetAccessMode: [(ConversationAccessMode?, [String]?)] = [(nil, nil),
                                                                     (ConversationAccessMode.teamOnly, []),
                                                                     (ConversationAccessMode.code, ["code"]),
                                                                     (ConversationAccessMode.`private`, ["private"]),
                                                                     (ConversationAccessMode.invite, ["invite"]),
                                                                     (ConversationAccessMode.legacy, ["invite"]),
                                                                     (ConversationAccessMode.allowGuests, ["code", "invite"])]

    func testThatModeSetWithOptionSetReflectedInStrings() {
        testSetAccessMode.forEach {
            // when
            sut.accessMode = $0
            // then
            if let strings = $1 {
                XCTAssertEqual(Set(sut.accessModeStrings!), Set(strings))
            }
            else {
                XCTAssertTrue(sut.accessModeStrings == nil)
            }
        }
    }

    func testThatModeSetWithStringsIsReflectedInOptionSet() {
        testSetAccessMode.forEach {
            // when
            sut.accessModeStrings = $1
            // then
            if let optionSet = $0 {
                XCTAssertEqual(sut.accessMode!, optionSet)
            }
            else {
                XCTAssertTrue(sut.accessMode == nil)
            }
        }
    }

    func testThatGuestsAreNotAllowedWhenAccessModeIsTeamOnly() {
        // WHEN
        sut.accessMode = .teamOnly
        sut.accessRoles = [.teamMember, .guest, .nonTeamMember]

        // THEN
        XCTAssertFalse(sut.allowGuests)
    }

    func testThatGuestsAreAllowedWhenAccessModeIsAllowGuests() {
        // WHEN
        sut.accessMode = .allowGuests
        sut.accessRoles = [.teamMember, .nonTeamMember, .guest]

        // THEN
        XCTAssertTrue(sut.allowGuests)
    }

    func testThatServicesAreAllowed() {
        // WHEN
        sut.accessRoles = [.teamMember, .service]

        // THEN
        XCTAssertTrue(sut.allowServices)
    }

    func testThatServicesAreNotAllowed() {
        // WHEN
        sut.accessRoles = [.teamMember]

        // THEN
        XCTAssertFalse(sut.allowServices)
    }

    func testThatTheConversationIsInsertedWithCorrectAccessModeAccessRole_Default_WithTeam() {
        // when
        let conversation = ZMConversation.insertGroupConversation(moc: self.uiMOC,
                                                                  participants: [],
                                                                  name: "Test Conversation",
                                                                  team: team)!
        // then
        XCTAssertEqual(Set(conversation.accessModeStrings!), ["code", "invite"])
        XCTAssertEqual(Set(conversation.accessRoleStringsV2!), ["guest", "service", "team_member", "non_team_member"])
    }

    func testThatTheConversationIsInsertedWithCorrectAccessModeAccessRole_Default_NoTeam() {
        // when
        let conversation = ZMConversation.insertGroupConversation(moc: self.uiMOC,
                                                                  participants: [],
                                                                  name: "Test Conversation",
                                                                  team: nil)!
        // then
        XCTAssertNil(conversation.accessModeStrings)
        XCTAssertNil(conversation.accessRoleStringsV2)
    }

    func testThatConversationIsInsertedWithCorrectAccessModeAndAccessRoles() {
        // THEN
        assertAccessModeAndRoles(allowGuests: true, allowServices: false, expectedAccessModes: ["code", "invite"], expectedAccessRoles: [.teamMember, .guest, .nonTeamMember])

        assertAccessModeAndRoles(allowGuests: false, allowServices: true, expectedAccessModes: [], expectedAccessRoles: [.teamMember, .service])

        assertAccessModeAndRoles(allowGuests: true, allowServices: true, expectedAccessModes: ["code", "invite"], expectedAccessRoles: [.teamMember, .nonTeamMember, .guest, .service])

        assertAccessModeAndRoles(allowGuests: false, allowServices: false, expectedAccessModes: [], expectedAccessRoles: [.teamMember])

    }

    func assertAccessModeAndRoles(allowGuests: Bool, allowServices: Bool, expectedAccessModes: Set<String>, expectedAccessRoles: Set<ConversationAccessRoleV2>, file: StaticString = #file, line: UInt = #line) {
        // WHEN
        let conversation = ZMConversation.insertGroupConversation(moc: self.uiMOC,
                                                                  participants: [],
                                                                  name: "Test Conversation",
                                                                  team: team,
                                                                  allowGuests: allowGuests,
                                                                  allowServices: allowServices)!
        // THEN
        XCTAssertEqual(Set(conversation.accessModeStrings!), expectedAccessModes, file: file, line: line)
        XCTAssertEqual(Set(conversation.accessRoleStringsV2!), Set(expectedAccessRoles.map(\.rawValue)), file: file, line: line)
    }

    func testThatAccessRoleSetAccessRoleString() {
        // GIVEN
        sut.accessRoles = [.teamMember, .guest, .nonTeamMember, .service]

        // THEN
        XCTAssertEqual(Set(sut.accessRoleStringsV2!), Set(["team_member", "guest", "non_team_member", "service"]))
    }

    func testThatAccessRoleStringSetAccesseRole() {
        // GIVEN
        sut.accessRoleStringsV2 = ["team_member", "non_team_member", "guest", "service"]

        // THEN
        XCTAssertEqual(sut.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
    }
}
