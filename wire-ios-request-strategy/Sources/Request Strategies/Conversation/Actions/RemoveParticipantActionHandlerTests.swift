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

class RemoveParticipantActionHandlerTests: MessagingTestBase {

    var sut: RemoveParticipantActionHandler!
    var user: ZMUser!
    var service: ZMUser!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            let userID = UUID()
            user.remoteIdentifier = userID
            user.domain = self.owningDomain
            self.user = user

            let service = ZMUser.insertNewObject(in: self.syncMOC)
            let serviceID = UUID()
            service.providerIdentifier = "providerIdentifier"
            service.serviceIdentifier = "serviceIdentifier"
            service.remoteIdentifier = serviceID
            service.domain = self.owningDomain

            self.service = service

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [])!
            let conversationID = UUID()
            conversation.remoteIdentifier = conversationID
            conversation.conversationType = .group
            conversation.domain = self.owningDomain
            self.conversation = conversation
        }

        sut = RemoveParticipantActionHandler(context: syncMOC)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    // MARK: - Request Generation

    func testThatItCreatesARequestForRemovingAParticipant_NonFederated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = self.user.remoteIdentifier!.transportString()
            let conversationID = self.conversation.remoteIdentifier!.transportString()
            let action = RemoveParticipantAction(user: self.user, conversation: self.conversation)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/conversations/\(conversationID)/members/\(userID)")
            XCTAssertEqual(request.method, .methodDELETE)
        }
    }

    func testThatItCreatesARequestForRemovingAParticipant_Federated() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let userID = self.user.remoteIdentifier!
            let conversationID = self.conversation.remoteIdentifier!
            let domain = self.owningDomain
            let action = RemoveParticipantAction(user: self.user, conversation: self.conversation)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v1))

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID)/members/\(domain)/\(userID)")
            XCTAssertEqual(request.method, .methodDELETE)
        }
    }

    // MARK: - Request Processing

    func testThatItParsesAllKnownRemoveParticipantErrorResponses() {

        let errorResponses: [(ConversationRemoveParticipantError, ZMTransportResponse)] = [
            (ConversationRemoveParticipantError.invalidOperation, ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)),
            (ConversationRemoveParticipantError.conversationNotFound, ZMTransportResponse(payload: ["label": "no-conversation"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        ]

        for (expectedError, response) in errorResponses {
            guard let error = ConversationRemoveParticipantError(response: response) else {
                return XCTFail("Error is invalid")
            }

            if case error = expectedError {
                // success
            } else {
                XCTFail("Unexpected error")
            }
        }
    }

    func testThatItProcessMemberLeaveEventInTheResponse() throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // given
            conversation.addParticipantAndUpdateConversationState(user: self.user, role: nil)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let action = RemoveParticipantAction(user: user, conversation: conversation)
            let memberLeave = Payload.UpdateConverationMemberLeave(userIDs: [user.remoteIdentifier!], qualifiedUserIDs: [user.qualifiedID!])
            let conversationEvent = conversationEventPayload(from: memberLeave,
                                                             conversationID: conversation.qualifiedID,
                                                             senderID: selfUser.qualifiedID)
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertFalse(conversation.localParticipants.contains(user))
        }
    }

    func testThatItProcessMemberLeaveEventInTheResponse_Bots() throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // given
            conversation.addParticipantAndUpdateConversationState(user: service, role: nil)

            let selfUser = ZMUser.selfUser(in: syncMOC)
            let action = RemoveParticipantAction(user: service, conversation: conversation)
            let memberLeave = Payload.UpdateConverationMemberLeave(userIDs: [service.remoteIdentifier!], qualifiedUserIDs: [service.qualifiedID!])
            let conversationEvent = conversationEventPayload(from: memberLeave,
                                                             conversationID: conversation.qualifiedID,
                                                             senderID: selfUser.qualifiedID)

            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertFalse(conversation.localParticipants.contains(service))
        }
    }

    func testThatItUpdatesClearedTimestamp_WhenSelfUserIsRemoved() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            message.serverTimestamp = Date()
            self.conversation.mutableMessages.add(message)
            self.conversation.lastServerTimeStamp = message.serverTimestamp?.addingTimeInterval(5)

            self.conversation.clearMessageHistory()
            self.syncMOC.saveOrRollback()

            let action = RemoveParticipantAction(user: selfUser, conversation: self.conversation)
            let memberLeaveTimestamp = Date().addingTimeInterval(1000)
            let memberLeave = Payload.UpdateConverationMemberLeave(userIDs: [selfUser.remoteIdentifier!], qualifiedUserIDs: [selfUser.qualifiedID!])
            let conversationEvent = self.conversationEventPayload(
                from: memberLeave,
                conversationID: self.conversation.qualifiedID,
                senderID: selfUser.qualifiedID,
                timestamp: memberLeaveTimestamp)
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)
            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertEqual(self.conversation.clearedTimeStamp?.transportString(), memberLeaveTimestamp.transportString())
        }
    }

    func testThatItCallsResultHandler_On200() {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // given
            conversation.addParticipantAndUpdateConversationState(user: self.user, role: nil)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            var action = RemoveParticipantAction(user: user, conversation: conversation)
            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .success = result {
                    expectation.fulfill()
                }
            }

            let memberLeave = Payload.UpdateConverationMemberLeave(userIDs: [user.remoteIdentifier!], qualifiedUserIDs: [user.qualifiedID!])
            let conversationEvent = conversationEventPayload(from: memberLeave,
                                                             conversationID: conversation.qualifiedID,
                                                             senderID: selfUser.qualifiedID)
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_On204() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = RemoveParticipantAction(user: user, conversation: conversation)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .success = result {
                    expectation.fulfill()
                }
            }
            let response = ZMTransportResponse(payload: nil,
                                               httpStatus: 204,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnError() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = RemoveParticipantAction(user: user, conversation: conversation)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .failure = result {
                    expectation.fulfill()
                }
            }

            let response = ZMTransportResponse(payload: nil,
                                               httpStatus: 404,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}
