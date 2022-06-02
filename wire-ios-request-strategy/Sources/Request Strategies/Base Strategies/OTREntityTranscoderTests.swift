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

import WireDataModel
@testable import WireRequestStrategy
import XCTest

@objcMembers class MockOTREntity: OTREntity, Hashable {

    var context: NSManagedObjectContext
    public var expirationDate: Date?
    public var isExpired: Bool = false
    public func expire() {
        isExpired = true
    }

    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // no-op
    }
    public var conversation: ZMConversation?

    var isMissingClients = false
    var didCallHandleClientUpdates = false
    var isDelivered = false

    var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    init(conversation: ZMConversation, context: NSManagedObjectContext) {
        self.conversation = conversation
        self.context = context
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.conversation!)
    }

    func detectedRedundantUsers(_ users: [ZMUser]) {
        // no-op
    }

    func delivered(with response: ZMTransportResponse) {
        isDelivered = true
    }

}

extension MockOTREntity: ProteusMessage {
    var debugInfo: String {
        "Mock ProteusMessage"
    }

    func encryptForTransport() -> EncryptedPayloadGenerator.Payload? {
        return ("non-qualified".data(using: .utf8)!, .doNotIgnoreAnyMissingClient)
    }

    func encryptForTransportQualified() -> EncryptedPayloadGenerator.Payload? {
        return ("qualified".data(using: .utf8)!, .doNotIgnoreAnyMissingClient)
    }

}

func == (lhs: MockOTREntity, rhs: MockOTREntity) -> Bool {
    return lhs === rhs
}

class OTREntityTranscoderTests: MessagingTestBase {

    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var mockEntity: MockOTREntity!
    var sut: OTREntityTranscoder<MockOTREntity>!

    override func setUp() {
        super.setUp()

        self.syncMOC.performGroupedAndWait { moc in
            self.mockEntity = MockOTREntity(conversation: self.groupConversation, context: moc)
            self.sut = OTREntityTranscoder(context: moc, clientRegistrationDelegate: self.mockClientRegistrationStatus)
        }
    }

    override func tearDown() {
        self.mockEntity = nil
        self.sut = nil
        super.tearDown()
    }

    func testThatItHandlesDeletionOfSelfClient() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let payload = [
                "label": "unknown-client"
            ]

            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            XCTAssertFalse(self.sut.shouldTryToResend(entity: self.mockEntity, afterFailureWithResponse: response))

            // THEN
            XCTAssertEqual(self.mockClientRegistrationStatus.deletionCalls, 1)
        }
    }

    func testThatItHandlesDeletionOfClient() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let payload = [
                "deleted": ["\(self.otherUser.remoteIdentifier!)": [self.otherClient.remoteIdentifier!] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(self.otherClient.isDeleted)
        }
    }

    func testThatItHandlesMissingClient_addsClientToListOfMissingClients() {
        self.syncMOC.performGroupedAndWait { moc in
            // GIVEN
            let user = ZMUser.insertNewObject(in: moc)
            user.remoteIdentifier = UUID.create()
            let clientId = "ajsd9898u13a"

            let payload = [
                "missing": ["\(user.remoteIdentifier!)": [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 1)
            XCTAssertEqual(self.selfClient.missingClients!.first!.remoteIdentifier, clientId)
        }
    }

    func testThatItHandlesMissingClient_ignoresClientIfItAlreadyHasAnEstablishedSession() {
        self.syncMOC.performGroupedAndWait { moc in
            // GIVEN
            let user = ZMUser.insertNewObject(in: moc)
            user.remoteIdentifier = UUID.create()

            let clientId = "ajsd9898u13a"
            let userClient = UserClient.fetchUserClient(withRemoteId: clientId, forUser: user, createIfNeeded: true)!
            self.establishSessionFromSelf(to: userClient)

            let payload = [
                "missing": ["\(user.remoteIdentifier!)": [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatItHandlesMissingClient_MarkAsNeedsToDownloadNotAlreadyThere() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let user = self.createUser()
            let clientId = "ajsd9898u13a"

            let payload = [
                "missing": ["\(user.remoteIdentifier!)": [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItHandlesRedundantClient_MarkUserAsNeedsToBeUpdatedFromBackend() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let user = self.createUser()
            user.needsToBeUpdatedFromBackend = false
            let clientId = "ajsd9898u13a"
            let payload = [
                "redundant": ["\(user.remoteIdentifier!)": [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(user.needsToBeUpdatedFromBackend)
        }
    }

}
