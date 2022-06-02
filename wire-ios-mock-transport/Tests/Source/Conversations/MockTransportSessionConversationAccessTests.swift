////
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

class MockTransportSessionConversationAccessTests: MockTransportSessionTests {

    var team: MockTeam!
    var selfUser: MockUser!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()
        sut.performRemoteChanges { session in
            self.selfUser = session.insertSelfUser(withName: "me")
            self.team = session.insertTeam(withName: "A Team", isBound: true)
            self.conversation = session.insertTeamConversation(to: self.team, with: [session.insertUser(withName: "some")], creator: self.selfUser)

        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    override func tearDown() {
        team = nil
        selfUser = nil
        conversation = nil
        super.tearDown()
    }

    func testThatSettingAccessModeReturnsErrorWhenConversationDoesNotExist() {
        // when
        let response = self.response(forPayload: [:] as ZMTransportData , path: "/conversations/123456/access", method: .methodPUT, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 404)
    }

    func testThatSettingAccessModeReturnsErrorWhenMissingAccess() {
        // given
        let payload = [
            "access_role": "activated",
        ] as ZMTransportData

        // when
        let response = self.response(forPayload: payload , path: "/conversations/\(self.conversation.identifier)/access", method: .methodPUT, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 400)
    }

    func testThatSettingAccessModeReturnsErrorWhenMissingAccessRole() {
        // given
        let payload = [
            "access": ["invite"],
            ] as ZMTransportData

        // when
        let response = self.response(forPayload: payload , path: "/conversations/\(self.conversation.identifier)/access", method: .methodPUT, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 400)
    }

    func testThatSettingAccessModeReturnsCorrectDataInPayload() {

        let role = "team"
        let access = ["invite", "code"]
        let accessRoleV2 = ["team_member", "non_team_member", "guest"]
        // given
        let payload = [
            "access_role": role,
            "access_role_v2": accessRoleV2,
            "access": access,
            ] as ZMTransportData

        // when
        let response = self.response(forPayload: payload , path: "/conversations/\(self.conversation.identifier)/access", method: .methodPUT, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else { XCTFail(); return }
        XCTAssertEqual(receivedPayload["type"] as? String, "conversation.access-update")
        XCTAssertEqual(receivedPayload["conversation"] as? String, conversation.identifier)
        guard let payloadData = receivedPayload["data"] as? [String: Any] else { XCTFail(); return }
        guard let responseRole = payloadData["access_role"] as? String else { XCTFail(); return }
        guard let responseRoleV2 = payloadData["access_role_v2"] as? [String] else { XCTFail(); return }
        guard let responseAccess = payloadData["access"] as? [String] else { XCTFail(); return }


        XCTAssertEqual(responseRole, role)
        XCTAssertEqual(responseRoleV2, accessRoleV2)
        XCTAssertEqual(responseAccess, access)
    }
    
    func testThatItCanCreateTheLink() {
        // given
        self.conversation.accessMode = ["code", "invite"]
        // when
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/code", method: .methodPOST, apiVersion: .v0)
        
        // then
        XCTAssertEqual(response?.httpStatus, 201)
        guard let receivedPayload = response?.payload as? [String: Any] else { XCTFail(); return }
        
        XCTAssertEqual(receivedPayload["type"] as? String, "conversation.code-update")
        XCTAssertEqual(receivedPayload["conversation"] as? String, conversation.identifier)
        guard let payloadData = receivedPayload["data"] as? [String: Any] else { XCTFail(); return }
        XCTAssertNotNil(payloadData["uri"])
        XCTAssertNotNil(payloadData["code"])
        XCTAssertNotNil(payloadData["key"])
        
        XCTAssertNotNil(conversation.link)
    }
    
    func testThatItCannotCreateLinkWhenNoAccessMode() {
        // given
        self.conversation.accessMode = ["invite"]
        // when
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/code", method: .methodPOST, apiVersion: .v0)
        // then
        XCTAssertEqual(response?.httpStatus, 403)
    }
    
    func testThatItCanFetchLinkWhenCreateLink() {
        // given
        let existingLink = "https://wire-website.com/some-other-link"
        self.conversation.accessMode = ["code", "invite"]
        self.conversation.link = existingLink
        // when
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/code", method: .methodPOST, apiVersion: .v0)
        
        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else { XCTFail(); return }
        
        XCTAssertEqual(receivedPayload["uri"] as! String, existingLink)
        XCTAssertNotNil(receivedPayload["code"])
        XCTAssertNotNil(receivedPayload["key"])
    }

    func testThatItFetchesTheGuestLinkStatus() {
        // GIVEN
        self.conversation.guestLinkFeatureStatus = "enabled"
        let status = self.conversation.guestLinkFeatureStatus

        // WHEN
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/features/conversationGuestLinks", method: .methodGET, apiVersion: .v0)

        // THEN
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else { XCTFail(); return }

        XCTAssertEqual(receivedPayload["status"] as! String, status)
    }

    func testThatItFailToFetchGuestLinkStatusWhenConversationIdIsUknown() {
        // GIVEN
        self.conversation.guestLinkFeatureStatus = "enabled"

        // WHEN
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(UUID.create())/features/conversationGuestLinks", method: .methodGET, apiVersion: .v0)

        // THEN
        XCTAssertEqual(response?.httpStatus, 404)
        XCTAssertEqual(response?.payloadLabel(), "no-conversation")
    }
    
    func testThatItCanFetchTheLink() {
        // given
        let existingLink = "https://wire-website.com/some-other-link"
        self.conversation.accessMode = ["code", "invite"]
        self.conversation.link = existingLink
        // when
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/code", method: .methodGET, apiVersion: .v0)
        
        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else { XCTFail(); return }
        
        XCTAssertEqual(receivedPayload["uri"] as! String, existingLink)
        XCTAssertNotNil(receivedPayload["code"])
        XCTAssertNotNil(receivedPayload["key"])
    }
    
    func testThatItCanDeleteLink() {
        // given
        let existingLink = "https://wire-website.com/some-other-link"
        self.conversation.accessMode = ["code", "invite"]
        self.conversation.link = existingLink
        // when
        let response = self.response(forPayload: [:] as ZMTransportData, path: "/conversations/\(self.conversation.identifier)/code", method: .methodDELETE, apiVersion: .v0)
        
        // then
        XCTAssertEqual(response?.httpStatus, 200)
        
        XCTAssertEqual(conversation.link, nil)
    }
}
