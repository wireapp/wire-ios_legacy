// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
@testable import WireRequestStrategy

final class UpdateRoleActionHandlerTests: MessagingTestBase {

    var sut: UpdateRoleActionHandler!
    var user: ZMUser!
    var conversation: ZMConversation!
    var role: Role!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            let userID = UUID()
            user.remoteIdentifier = userID
            user.domain = self.owningDomain
            self.user = user

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [])!
            let conversationID = UUID()
            conversation.remoteIdentifier = conversationID
            conversation.conversationType = .group
            conversation.domain = self.owningDomain
            self.conversation = conversation

            let role = Role.insertNewObject(in: self.syncMOC)
            role.name = UUID().uuidString
            role.conversation = self.conversation
            self.role = role
        }

        sut = UpdateRoleActionHandler(context: syncMOC)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatItCreatesAnExpectedRequestForUpdatingRole() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = self.user.remoteIdentifier!
            let conversationID = self.conversation.remoteIdentifier!
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/conversations/\(conversationID.transportString())/members/\(userID.transportString())")
            let payload = Payload.ConversationUpdateRole(request)
            XCTAssertEqual(payload?.role, self.role.name)
        }
    }

    func testThatItFailsCreatingRequestWhenUserIDIsMissing() {
        syncMOC.performGroupedAndWait { _ in
            // given
            self.user.remoteIdentifier = nil
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)

            // when
            let request = self.sut.request(for: action, apiVersion: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItFailesCreatingRequestWhenConversationIDIsMissing() {
        syncMOC.performGroupedAndWait { _ in
            // given
            self.conversation.remoteIdentifier = nil
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)

            // when
            let request = self.sut.request(for: action, apiVersion: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatItFailesCreatingRequestWhenRoleNameIsMissing() {
        syncMOC.performGroupedAndWait { _ in
            // given
            self.role.name = nil
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)

            // when
            let request = self.sut.request(for: action, apiVersion: .v0)

            // then
            XCTAssertNil(request)
        }
    }

    func testThatTheSucceededRequestUpdatesTheDatabase() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)
            let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertEqual(self.user.participantRoles.first { $0.conversation == self.conversation }?.role, self.role)
        }
    }

    func testThatTheFailedRequestDoesNotUpdateTheDatabase() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let action = UpdateRoleAction(user: self.user, conversation: self.conversation, role: self.role)
            let response = ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(self.user.participantRoles.isEmpty)
        }
    }
}
