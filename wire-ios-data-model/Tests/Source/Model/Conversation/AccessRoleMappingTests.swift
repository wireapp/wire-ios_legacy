//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class AccessRoleMappingTests: XCTestCase {

    // MARK: Test Access Role Mapping from AccessRoleV2 to Access Role

    func testAccessRoleMappingFromAccessRoleV2ToAccessRole() {

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([]), .private)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember]), .team)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .nonTeamMember]), .activated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .nonTeamMember, .guest]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .nonTeamMember, .guest, .service]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .nonTeamMember, .service]), .activated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .guest]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .guest, .service]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.teamMember, .service]), .activated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.nonTeamMember]), .activated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.nonTeamMember, .guest]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.nonTeamMember, .guest, .service]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.nonTeamMember, .service]), .activated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.guest]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.guest, .service]), .nonActivated)

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRole.fromAccessRoleV2([.service]), .activated)
    }

    // MARK: Test Access Role Mapping from AccessRole to AccessRoleV2

    func testAccessRoleMappingFromAccessRoleToAccessRoleV2() {
        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRoleV2.fromLegacyAccessRole(.team), [.teamMember])

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRoleV2.fromLegacyAccessRole(.activated), [.teamMember, .nonTeamMember, .guest])

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRoleV2.fromLegacyAccessRole(.nonActivated), [.teamMember, .nonTeamMember, .guest, .service])

        // WHEN & THEN
        XCTAssertEqual(ConversationAccessRoleV2.fromLegacyAccessRole(.private), [])
    }

}
