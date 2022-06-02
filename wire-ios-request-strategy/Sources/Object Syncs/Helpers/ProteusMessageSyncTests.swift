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

class ProteusMessageSyncTests: MessagingTestBase {

    var sut: ProteusMessageSync<MockOTREntity>!
    var mockApplicationStatus: MockApplicationStatus!
    let domain = "example.com"
    var qualifiedEndpoint: String!
    var legacyEndpoint: String!

    var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        sut = ProteusMessageSync<MockOTREntity>(context: syncMOC, applicationStatus: mockApplicationStatus)

        syncMOC.performGroupedBlockAndWait { [self] in
            otherUser.domain = domain
            qualifiedEndpoint = "/v1/conversations/\(domain)/\(groupConversation.remoteIdentifier!.transportString())/proteus/messages"
            legacyEndpoint = "/conversations/\(groupConversation.remoteIdentifier!.transportString())/otr/messages"
        }

        apiVersion = .v0
    }

    override func tearDown() {
        apiVersion = nil
        super.tearDown()
    }

    func testThatItNotifiesThatNewRequestsAreAvailable_WhenSynchronizingMessage() {
        // given
        let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)

        // expect
        expectation(forNotification: Notification.Name("RequestAvailableNotification"),
                    object: nil,
                    handler: nil)

        // when
        sut.sync(message) { (_, _) in }

        // then
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallsSyncCompletionHandler_WhenResponseIsSuccessfull() throws {
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)

            // expect
            let expectation = self.expectation(description: "completion is called")
            sut.sync(message) { (result, _) in
                if case .success = result {
                    expectation.fulfill()
                }
            }

            // when
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 201,
                                               transportSessionError: nil,
                                               apiVersion: apiVersion.rawValue)

            sut.nextRequest(for: apiVersion)?.complete(with: response)
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItInformsTheMessageThatItsBeenDelivered_WhenResponseIsSuccessfull() throws {
        var message: MockOTREntity!
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            sut.sync(message, completion: { (_, _) in })

            // when
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 201,
                                               transportSessionError: nil,
                                               apiVersion: apiVersion.rawValue)

            sut.nextRequest(for: apiVersion)?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(message.isDelivered)
        }
    }

    func testThatItCallsSyncCompletionHandler_WhenResponseIsNonRecoverableFailure() throws {
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)

            // expect
            let expectation = self.expectation(description: "completion is called")
            sut.sync(message) { (result, _) in
                if case .failure(let error) = result, error == .gaveUpRetrying {
                    expectation.fulfill()
                }
            }

            // when
            let response = ZMTransportResponse(payload: nil,
                                               httpStatus: 403,
                                               transportSessionError: nil,
                                               apiVersion: apiVersion.rawValue)

            sut.nextRequest(for: apiVersion)?.complete(with: response)
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItRetriesTheRequest_WhenResponseSaysItsATemporaryError() throws {
        apiVersion = .v1

        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            sut.sync(message) { (_, _) in }

            // when
            let response = ZMTransportResponse(transportSessionError: NSError.tryAgainLaterError(), apiVersion: apiVersion.rawValue)
            sut.nextRequest(for: apiVersion)?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait { [self] in
            // then
            XCTAssertEqual(sut.nextRequest(for: apiVersion)?.path, qualifiedEndpoint)
        }
    }

    func testThatItRetriesTheRequest_WhenResponseSaysClientAreMissing() throws {
        apiVersion = .v1
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            sut.sync(message) { (_, _) in }

            // when
            let clientID = UUID().transportString()
            let missing: Payload.ClientListByQualifiedUserID =
                [self.domain:
                    [self.otherUser.remoteIdentifier.transportString(): [clientID]]
                ]
            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:])
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 412,
                                               transportSessionError: nil,
                                               apiVersion: apiVersion.rawValue)

            sut.nextRequest(for: apiVersion)?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedBlockAndWait { [self] in
            // then
            XCTAssertEqual(sut.nextRequest(for: apiVersion)?.path, qualifiedEndpoint)
        }
    }

    func testThatItDetectsThatSelfClientIsDeleted_WhenResponseSaysClientIsUnknown() throws {
            syncMOC.performGroupedBlockAndWait { [self] in
                // given
                let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
                sut.sync(message) { (_, _) in }

                // when
                let payload = Payload.ResponseFailure(code: 403, label: .unknownClient, message: "")
                let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
                let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                                   httpStatus: payload.code,
                                                   transportSessionError: nil,
                                                   apiVersion: apiVersion.rawValue)

                sut.nextRequest(for: apiVersion)?.complete(with: response)
            }
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            syncMOC.performGroupedBlockAndWait { [self] in
                // then
                XCTAssertTrue(mockApplicationStatus.mockClientRegistrationStatus.deletionCalls > 0)
            }
    }

    func testThatItAssignsRequestExpirationDate_WhenAvailableOnMessage() throws {
        syncMOC.performGroupedBlockAndWait { [self] in
            // given
            let expirationDate = Date(timeIntervalSinceNow: 100)
            let message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            message.expirationDate = expirationDate
            sut.sync(message) { (_, _) in }

            // when
            let request = sut.nextRequest(for: apiVersion)

            // then
            XCTAssertEqual(request?.expirationDate, expirationDate)
        }
    }

}
