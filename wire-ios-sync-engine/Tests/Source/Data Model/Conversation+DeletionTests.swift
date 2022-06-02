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
@testable import WireSyncEngine

class Conversation_DeletionTests: DatabaseTest {

    var mockTransportSession: MockTransportSession!

    override func setUp() {
        super.setUp()
        APIVersion.current = .v0
        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)
    }

    override func tearDown() {
        mockTransportSession.cleanUp()
        mockTransportSession = nil
        APIVersion.current = nil
        super.tearDown()
    }

    func testThatItParsesAllKnownConversationDeletionErrorResponses() {

        let errorResponses: [(ConversationDeletionError, ZMTransportResponse)] = [
            (ConversationDeletionError.invalidOperation, ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)),
            (ConversationDeletionError.conversationNotFound, ZMTransportResponse(payload: ["label": "no-conversation"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        ]

        for (expectedError, response) in errorResponses {
            guard let error = ConversationDeletionError(response: response) else { return XCTFail() }

            if case error = expectedError {
                // success
            } else {
                XCTFail()
            }
        }
    }

    func testItThatReturnsFailure_WhenAttempingToDeleteNonTeamConveration() {
        // GIVEN
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [])!
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        let invalidOperationfailure = expectation(description: "Invalid Operation")

        // WHEN
        conversation.delete(in: coreDataStack!, transportSession: mockTransportSession) { (result) in
            if case .failure(let error) = result {
                if case ConversationDeletionError.invalidOperation = error {
                    invalidOperationfailure.fulfill()
                }
            }
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testItThatReturnsFailure_WhenAttempingToDeleteLocalConveration() {
        // GIVEN
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [])!
        conversation.conversationType = .group
        conversation.teamRemoteIdentifier = UUID()
        let invalidOperationfailure = expectation(description: "Invalid Operation")

        // WHEN
        conversation.delete(in: coreDataStack!, transportSession: mockTransportSession) { (result) in
            if case .failure(let error) = result {
                if case ConversationDeletionError.invalidOperation = error {
                    invalidOperationfailure.fulfill()
                }
            }
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Request Factory

    func testThatItGeneratesRequest_ForDeletingTeamConveration() {
        // GIVEN
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [])!
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        conversation.teamRemoteIdentifier = UUID()

        // WHEN
        guard let request = WireSyncEngine.ConversationDeletionRequestFactory.requestForDeletingTeamConversation(conversation) else { return XCTFail() }

        // THEN
        XCTAssertEqual(request.path, "/teams/\(conversation.teamRemoteIdentifier!.transportString())/conversations/\(conversation.remoteIdentifier!.transportString())")
    }

}
