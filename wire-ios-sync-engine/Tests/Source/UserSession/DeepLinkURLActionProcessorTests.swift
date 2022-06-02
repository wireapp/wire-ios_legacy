//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
@testable import WireSyncEngine

class DeepLinkURLActionProcessorTests: DatabaseTest {

    var presentationDelegate: MockPresentationDelegate!
    var sut: WireSyncEngine.DeepLinkURLActionProcessor!
    var mockTransportSession: MockTransportSession!
    var mockUpdateEventProcessor: MockUpdateEventProcessor!

    override func setUp() {
        super.setUp()
        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)
        mockUpdateEventProcessor = MockUpdateEventProcessor()
        presentationDelegate = MockPresentationDelegate()
        sut = WireSyncEngine.DeepLinkURLActionProcessor(contextProvider: coreDataStack!,
                                                        transportSession: mockTransportSession,
                                                        eventProcessor: mockUpdateEventProcessor)
        APIVersion.current = .v0
    }

    override func tearDown() {
        presentationDelegate = nil
        sut = nil
        mockTransportSession = nil
        mockUpdateEventProcessor = nil
        APIVersion.current = nil
        super.tearDown()
    }

    // MARK: Tests

    func testThatItAsksForConversationToBeShown() {
        // given
        let conversationId = UUID()
        let action: URLAction = .openConversation(id: conversationId)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = conversationId

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.showConversationCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showConversationCalls.first, conversation)
    }

    func testThatItReportsTheActionAsFailed_WhenTheConversationDoesntExist() {
        // given
        let conversationId = UUID()
        let action: URLAction = .openConversation(id: conversationId)

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.1 as? DeepLinkRequestError, .invalidConversationLink)
    }

    func testThatItAsksToShowUserProfile_WhenUserIsKnown() {
        // given
        let userId = UUID()
        let action: URLAction = .openUserProfile(id: userId)
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userId

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.showUserProfileCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showUserProfileCalls.first as? ZMUser, user)
    }

    func testThatItAsksToShowConnectionRequest_WhenUserIsUnknown() {
        // given
        let userId = UUID()
        let action: URLAction = .openUserProfile(id: userId)

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)

        // then
        XCTAssertEqual(presentationDelegate.showConnectionRequestCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showConnectionRequestCalls.first, userId)
    }

    func testThatItCompletesTheJoinConversationAction_WhenCodeIsValid() {
        // given
        let action: URLAction = .joinConversation(key: "test-key", code: "test-code")

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockUpdateEventProcessor.processedEvents.count, 1)
        XCTAssertEqual(mockUpdateEventProcessor.processedEvents.first?.type, .conversationMemberJoin)
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.first, action)
    }

    func testThatItReportsTheJoinConversationActionAsFailed_WhenCodeIsInvalid() {
        // given
        let action: URLAction = .joinConversation(key: "test-key", code: "wrong-code")

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.1 as? ConversationFetchError, ConversationFetchError.invalidCode)
    }

}
