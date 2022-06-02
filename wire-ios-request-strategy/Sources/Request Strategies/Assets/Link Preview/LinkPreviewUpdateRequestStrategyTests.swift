//
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

class LinkPreviewUpdateRequestStrategyTests: MessagingTestBase {

    private var sut: LinkPreviewUpdateRequestStrategy!
    private var applicationStatus: MockApplicationStatus!

    private var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedAndWait { syncMOC in
            self.groupConversation.domain = "example.com"
            self.applicationStatus = MockApplicationStatus()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = LinkPreviewUpdateRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: self.applicationStatus)
        }

        apiVersion = .v0
    }

    override func tearDown() {
        applicationStatus = nil
        sut = nil
        apiVersion = nil
        super.tearDown()
    }

    func testThatItDoesNotCreateARequestInState_Done() {
        self.verifyThatItDoesNotCreateARequest(for: .done)
    }

    func testThatItDoesNotCreateARequestInState_WaitingToBeProcessed() {
        self.verifyThatItDoesNotCreateARequest(for: .waitingToBeProcessed)
    }

    func testThatItDoesNotCreateARequestInState_Downloaded() {
        self.verifyThatItDoesNotCreateARequest(for: .downloaded)
    }

    func testThatItDoesNotCreateARequestInState_Processed() {
        self.verifyThatItDoesNotCreateARequest(for: .processed)
    }

    func testThatItDoesNotCreateARequestInState_Uploaded_ForOtherUser() {
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            let message = self.insertMessage(with: .uploaded)
            message.sender = self.otherUser

            // When
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in

            // Then
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatItDoesCreateARequestInState_Uploaded() {
        apiVersion = .v1

        self.syncMOC.performGroupedAndWait { _ in
            // Given
            let message = self.insertMessage(with: .uploaded)

            // When
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in
            // Then
            self.verifyItCreatesARequest(in: self.groupConversation)
        }
    }

    func testThatItDoesCreateARequestInState_Uploaded_WhenFederationEndpointIsDisabled() {
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            let message = self.insertMessage(with: .uploaded)

            // When
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in
            // Then
            self.verifyItCreatesARequest(in: self.groupConversation)
        }
    }

    func testThatItDoesCreateARequestInState_Uploaded_WhenTheFirstRequestFailed() {
        apiVersion = .v1
        var message: ZMClientMessage!

        self.syncMOC.performGroupedAndWait { _ in

            // Given
            message = self.insertMessage(with: .uploaded)

            // When
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in
            guard let request = self.verifyItCreatesARequest(in: self.groupConversation) else { return }

            // When
            let response = ZMTransportResponse(transportSessionError: NSError.tryAgainLaterError(), apiVersion: self.apiVersion.rawValue)
            request.complete(with: response)
        }
        self.syncMOC.performGroupedAndWait { _ in

            XCTAssertEqual(message.linkPreviewState, .uploaded)

            // Then
            self.verifyItCreatesARequest(in: self.groupConversation)
        }
    }

    func testThatItDoesNotCreateARequestAfterGettingsAResponseForIt() {
        apiVersion = .v1
        var message: ZMClientMessage!
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            message = self.insertMessage(with: .uploaded)
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in
            // Then
            guard let request = self.verifyItCreatesARequest(in: self.groupConversation) else { return }

            // When
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 201,
                                               transportSessionError: nil,
                                               apiVersion: self.apiVersion.rawValue)
            request.complete(with: response)
        }
        self.syncMOC.performGroupedAndWait { _ in
            // Then
            XCTAssertEqual(message.linkPreviewState, .done)
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    // MARK: - Helper

    func insertMessage(with state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) -> ZMClientMessage {
        let message = try! groupConversation.appendText(content: "Test message") as! ZMClientMessage
        message.linkPreviewState = state
        XCTAssert(syncMOC.saveOrRollback(), file: file, line: line)

        return message
    }

    func verifyThatItDoesNotCreateARequest(for state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) {
        self.syncMOC.performGroupedAndWait { _ in
            // Given
            let message = self.insertMessage(with: state)

            // When
            self.process(message)
        }
        self.syncMOC.performGroupedAndWait { _ in

            // Then
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    @discardableResult
    func verifyItCreatesARequest(in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) -> ZMTransportRequest? {
        let request = sut.nextRequest(for: apiVersion)
        let conversationID = conversation.remoteIdentifier!.transportString()
        XCTAssertNotNil(request, "No request generated", file: file, line: line)
        XCTAssertEqual(request?.method, .methodPOST, file: file, line: line)

        switch apiVersion! {
        case .v0:
            XCTAssertEqual(request?.path, "/conversations/\(conversationID)/otr/messages", file: file, line: line)

        case .v1:
            let domain = conversation.domain!
            XCTAssertEqual(request?.path, "/v1/conversations/\(domain)/\(conversationID)/proteus/messages", file: file, line: line)
        }

        return request
    }

    func process(_ message: ZMClientMessage) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange([message])
        }
    }

}
