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

class MockTransportSessionJoinConversationTests: MockTransportSessionTests {

    var selfUser: MockUser!
    var conversation: MockConversation!

    override func setUp() {
        super.setUp()
        sut.performRemoteChanges { session in
            self.selfUser = session.insertSelfUser(withName: "me")
            self.conversation = session.insertConversation(withCreator: self.selfUser, otherUsers: [self.selfUser!], type: .group)

        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    override func tearDown() {
        selfUser = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - POST /conversations/join

    func testThatItReturnsCorrectResponse_ForRequestToJoinConversation() {
        // given
        let payload = [
            "code": "test-code",
            "key": "test-key",
        ] as ZMTransportData


        // when
        let response = self.response(forPayload: payload, path: "/conversations/join", method: .methodPOST, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any],
              let data = receivedPayload["data"] as? [String: Any],
              let userIds = data["user_ids"] as? [String] else {
            XCTFail()
            return
        }

        XCTAssertEqual(receivedPayload["type"] as! String, "conversation.member-join")
        XCTAssertNotNil(receivedPayload["conversation"])
        XCTAssertTrue(userIds.contains(selfUser.identifier))
    }

    func testThatItDoesNotReturnError_WhenConversationExists() {
        // given
        let payload = [
            "code": "existing-conversation-code",
            "key": "test-key",
        ] as ZMTransportData


        // when
        let response = self.response(forPayload: payload, path: "/conversations/join", method: .methodPOST, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 204)
    }

    func testThatItReturnsError_WhenTheCodeIsInvalid() {
        // given
        let payload = [
            "code": "wrong-code",
            "key": "test-key",
        ] as ZMTransportData


        // when
        let response = self.response(forPayload: payload, path: "/conversations/join", method: .methodPOST, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 404)
        guard let receivedPayload = response?.payload as? [String: Any] else {
            XCTFail()
            return
        }

        XCTAssertEqual(receivedPayload["label"] as! String, "no-conversation-code")
    }

    // MARK: - GET /conversations/join

    func testThatItReturnsIdAndNameForANewConversation() {
        // given
        let path = String(format: "/conversations/join?code=%@&key=%@", "test-code", "test-key")

        // when
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else {
            XCTFail()
            return
        }

        XCTAssertNotNil(receivedPayload["id"])
        XCTAssertNotNil(receivedPayload["name"])
        let existingConversation = fetchConversation(with: receivedPayload["id"] as! String, in: sut.managedObjectContext)
        XCTAssertNil(existingConversation)
    }

    func testThatItReturnsIdAndNameForExistingConversation() {
        // given
        let path = String(format: "/conversations/join?code=%@&key=%@", "existing-conversation-code", "test-key")

        // when
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 200)
        guard let receivedPayload = response?.payload as? [String: Any] else {
            XCTFail()
            return
        }

        XCTAssertNotNil(receivedPayload["id"])
        XCTAssertNotNil(receivedPayload["name"])
        let existingConversation = fetchConversation(with: receivedPayload["id"] as! String, in: sut.managedObjectContext)
        XCTAssertEqual(existingConversation, conversation)
    }

    func testThatItReturnsError_WhenTheCodeIsInvalid_FetchConversation() {
        // given
        let path = String(format: "/conversations/join?code=%@&key=%@", "wrong-code", "test-key")

        // when
        let response = self.response(forPayload: nil, path: path, method: .methodGET, apiVersion: .v0)

        // then
        XCTAssertEqual(response?.httpStatus, 404)
        guard let receivedPayload = response?.payload as? [String: Any] else {
            XCTFail()
            return
        }

        XCTAssertEqual(receivedPayload["label"] as! String, "no-conversation-code")
    }

    private func fetchConversation(with identifier: String, in managedObjectContext: NSManagedObjectContext) -> MockConversation? {
        let request = MockConversation.sortedFetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", identifier.lowercased())
        let conversations = managedObjectContext.executeFetchRequestOrAssert(request) as? [MockConversation]
        return conversations?.first
    }

}
