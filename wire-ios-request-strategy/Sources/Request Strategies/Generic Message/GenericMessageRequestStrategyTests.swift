//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
@testable import WireRequestStrategy

class GenericMessageRequestStrategyTests: MessagingTestBase {

    var mockClientRegistrationStatus: MockClientRegistrationStatus!
    var conversation: ZMConversation!
    var sut: GenericMessageRequestStrategy!

    override func setUp() {
        super.setUp()
        mockClientRegistrationStatus = MockClientRegistrationStatus()

        sut = GenericMessageRequestStrategy(context: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)

        syncMOC.performGroupedBlockAndWait {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = UUID.create()

            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.conversationType = .group
            self.conversation.remoteIdentifier = UUID.create()
            self.conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        }
    }

    override func tearDown() {
        sut = nil
        conversation = nil
        mockClientRegistrationStatus = nil
        super.tearDown()
    }

    func testThatItCallsEntityCompletionHandlerOnRequestCompletion() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let expectation = self.expectation(description: "Should complete")
            let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID.create(), text: Text(content: "bar")))
            let message = GenericMessageEntity(conversation: self.conversation, message: genericMessage) {
                XCTAssertEqual($0, response)
                expectation.fulfill()
            }

            // WHEN
            self.sut.request(forEntity: message, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsEntityCompletionHandlerOnShouldRetry() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let expectation = self.expectation(description: "Should complete")
            let response = ZMTransportResponse(payload: nil, httpStatus: 412, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID.create(), text: Text(content: "bar")))
            let message = GenericMessageEntity(conversation: self.conversation, message: genericMessage) {
                XCTAssertEqual($0, response)
                expectation.fulfill()
            }

            // WHEN
            _ = self.sut.shouldTryToResend(entity: message, afterFailureWithResponse: response)

            // THEN
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCreatesARequestForAGenericMessage() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID.create(), text: Text(content: "bar")))
            self.sut.schedule(message: genericMessage, inConversation: self.groupConversation) { ( _ ) in }

            // WHEN
            let request = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertEqual(request!.method, .methodPOST)
            XCTAssertEqual(request!.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
        }
    }

    func testThatItForwardsObjectDidChangeToTheSync() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            self.selfClient.missesClient(self.otherClient)

            let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: UUID.create(), text: Text(content: "bar")))
            self.sut.schedule(message: genericMessage, inConversation: self.groupConversation) { ( _ ) in }

            // WHEN
            let request1 = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertNil(request1)

            // and when
            self.selfClient.removeMissingClient(self.otherClient)
            self.sut.objectsDidChange(Set([self.selfClient]))
            let request2 = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertEqual(request2!.method, .methodPOST)
            XCTAssertEqual(request2!.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
        }
    }

}
