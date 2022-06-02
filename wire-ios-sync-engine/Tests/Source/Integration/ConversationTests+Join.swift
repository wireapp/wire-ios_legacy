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

class ConversationTests_Join: ConversationTestsBase {

    // MARK: - Join conversation

    func testThatTheSelfUserJoinsAConversation_OnSuccessfulResponse() {
        // GIVEN
        XCTAssert(login())

        // Convert MockUser -> ZMUser
        let selfUser_zmUser = user(for: self.selfUser)!

        // WHEN
        // Key value doesn't affect the test result
        ZMConversation.join(key: "test-key",
                            code: "test-code",
                            transportSession: userSession!.transportSession,
                            eventProcessor: userSession!.updateEventProcessor!,
                            contextProvider: userSession!.coreDataStack,
                            completion: { result in
                                // THEN
                                if case .success(let conversation) = result {
                                    XCTAssertNotNil(conversation)
                                    XCTAssertTrue(conversation.localParticipants.map(\.remoteIdentifier).contains(selfUser_zmUser.remoteIdentifier))
                                } else {
                                    XCTFail()
                                }
                            })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatTheSelfUserDoesNotJoinAConversation_OnFailureResponse() {
        // GIVEN
        XCTAssert(login())

        // WHEN
        let conversationJoiningFailed = expectation(description: "Failed to join the conversation")
        // Key value doesn't affect the test result
        ZMConversation.join(key: "test-key",
                            code: "wrong-code",
                            transportSession: userSession!.transportSession,
                            eventProcessor: userSession!.updateEventProcessor!,
                            contextProvider: userSession!.coreDataStack,
                            completion: { result in
                                // THEN
                                if case .failure(let error) = result {
                                    XCTAssertEqual(error as! ConversationJoinError, ConversationJoinError.invalidCode)
                                    conversationJoiningFailed.fulfill()
                                } else {
                                    XCTFail()
                                }
                            })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5, handler: nil))
    }

    func testThatAnErrorIsReported_WhenTheSelfUsersIsAlreadyAParticipant() {
        // GIVEN
        XCTAssert(login())

        // WHEN
        let userIsParticipant = expectation(description: "The user was already a participant in the conversation")
        // Key value doesn't affect the test result
        ZMConversation.join(key: "test-key",
                            code: "existing-conversation-code",
                            transportSession: userSession!.transportSession,
                            eventProcessor: userSession!.updateEventProcessor!,
                            contextProvider: userSession!.coreDataStack,
                            completion: { result  in
                                // THEN
                                if case .failure(let error) = result {
                                    XCTAssertEqual(error as! ConversationJoinError, ConversationJoinError.unknown)
                                    userIsParticipant.fulfill()
                                } else {
                                    XCTFail()
                                }
                            })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: - Fetch conversation ID and name

    func testThatItReturnsConversationIdAndName_ForExistingConversation() {
        // GIVEN
        XCTAssert(login())
        let viewContext = userSession!.coreDataStack.viewContext

        // WHEN
        // Key value doesn't affect the test result
        ZMConversation.fetchIdAndName(key: "test-key",
                                      code: "existing-conversation-code",
                                      transportSession: userSession!.transportSession,
                                      eventProcessor: userSession!.updateEventProcessor!,
                                      contextProvider: userSession!.coreDataStack) { (result) in
            // THEN
            if case .success((let conversationID, let conversationName)) = result {
                XCTAssertNotNil(conversationID)
                XCTAssertNotNil(conversationName)
                let conversation = ZMConversation.fetch(with: conversationID, in: viewContext)
                XCTAssertTrue(conversation!.isSelfAnActiveMember)
            } else {
                XCTFail()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItReturnsConversationIdAndName_ForANewConversation() {
        // GIVEN
        XCTAssert(login())
        let viewContext = userSession!.coreDataStack.viewContext

        // WHEN
        // Key value doesn't affect the test result
        ZMConversation.fetchIdAndName(key: "test-key",
                                      code: "test-code",
                                      transportSession: userSession!.transportSession,
                                      eventProcessor: userSession!.updateEventProcessor!,
                                      contextProvider: userSession!.coreDataStack) { (result) in
            // THEN
            if case .success((let conversationID, let conversationName)) = result {
                XCTAssertNotNil(conversationID)
                XCTAssertNotNil(conversationName)
                let conversation = ZMConversation.fetch(with: conversationID, in: viewContext)
                XCTAssertNil(conversation)
            } else {
                XCTFail()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItDoesNotReturnConversationIdAndName_WhenCodeIsInvalid() {
        // GIVEN
        XCTAssert(login())

        // WHEN
        let conversationFetchingFailed = expectation(description: "Failed to fetch the conversation")
        // Key value doesn't affect the test result
        ZMConversation.fetchIdAndName(key: "test-key",
                                      code: "wrong-code",
                                      transportSession: userSession!.transportSession,
                                      eventProcessor: userSession!.updateEventProcessor!,
                                      contextProvider: userSession!.coreDataStack) { (result) in
            // THEN
            if case .failure(let error) = result {
                XCTAssertEqual(error as! ConversationFetchError, ConversationFetchError.invalidCode)
                conversationFetchingFailed.fulfill()
            } else {
                XCTFail()
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}
