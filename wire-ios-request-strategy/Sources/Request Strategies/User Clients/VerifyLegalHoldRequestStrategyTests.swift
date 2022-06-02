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
@testable import WireRequestStrategy

private typealias ClientListByUser = [String: [String]]
private typealias UserListByDomain = [String: ClientListByUser]

private protocol TransportDataConvertible: Codable {
    var transportData: ZMTransportData { get }
}

private extension TransportDataConvertible {
    var transportData: ZMTransportData {
        let encoded = try! JSONEncoder.defaultEncoder.encode(self)
        return try! JSONSerialization.jsonObject(with: encoded, options: []) as! ZMTransportData
    }
}

private struct ClientUpdateResponse: Codable, TransportDataConvertible {

    enum ErrorLabel: String, Codable {
        case unknownClient = "unknown-client"
    }

    var label: ErrorLabel?
    var missing: ClientListByUser?
    var deleted: ClientListByUser?
    var redundant: ClientListByUser?

    init(missing: ClientListByUser) {
        self.missing = missing
    }
}

extension Payload.MessageSendingStatus: TransportDataConvertible {
    fileprivate init(missing: UserListByDomain) {
        self.init(
            time: .init(),
            missing: missing,
            redundant: .init(),
            deleted: .init(),
            failedToSend: .init()
        )
    }
}

class VerifyLegalHoldRequestStrategyTests: MessagingTestBase {

    var sut: VerifyLegalHoldRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = VerifyLegalHoldRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold() {
        testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: .v0)
        testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: .v1)
    }

    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: APIVersion) {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> =  [conversation]

            // WHEN
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            // THEN
            var expectedPath: String
            switch apiVersion {
            case .v0:
                expectedPath = "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages"
            case .v1:
                expectedPath = "/v1/conversations/\(conversation.domain!)/\(conversation.remoteIdentifier!.transportString())/proteus/messages"
            }

            XCTAssertEqual(self.sut.nextRequest(for: apiVersion)?.path, expectedPath)
        }
    }

    // MARK: Response handling

    func testThatItResetsNeedsToVerifyLegalHoldFlag_WhenReceivingTheResponse() {
        var conversation: ZMConversation!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let conversationSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: .v0)

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: [:] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(conversation.needsToVerifyLegalHold)
        }
    }

    func testThatItRegistersMissingClients() {
        testThatItRegistersMissingClients(apiVersion: .v0)
        testThatItRegistersMissingClients(apiVersion: .v1)
    }

    private func testThatItRegistersMissingClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let clientID = "client123"

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))

            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [self.otherUser.remoteIdentifier.transportString(): [clientID]]

            var transportData: ZMTransportData
            switch apiVersion {
            case .v0:
                transportData = ClientUpdateResponse(missing: clientListByUserID).transportData
            case .v1:
                transportData = Payload.MessageSendingStatus(missing: [self.otherUser.domain!: clientListByUserID]).transportData
            }

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: transportData, httpStatus: 412, transportSessionError: nil, apiVersion: apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            guard let client = UserClient.fetchUserClient(withRemoteId: clientID, forUser: self.otherUser, createIfNeeded: false) else { return XCTFail("Failed to fetch client") }

            XCTAssertEqual(client.remoteIdentifier, clientID)
        }
    }

    func testThatItDeletesDeletedClients() {
        testThatItRegistersMissingClients(apiVersion: .v0)
        testThatItRegistersMissingClients(apiVersion: .v1)
    }

    private func testThatItDeletesDeletedClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        let existingClientID = "client2"
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: true))
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: existingClientID, forUser: self.otherUser, createIfNeeded: true))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [self.otherUser.remoteIdentifier.transportString(): [existingClientID]]

            var transportData: ZMTransportData
            switch apiVersion {
            case .v0:
                transportData = ClientUpdateResponse(missing: clientListByUserID).transportData
            case .v1:
                transportData = Payload.MessageSendingStatus(missing: [self.otherUser.domain!: clientListByUserID]).transportData
            }

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: transportData, httpStatus: 412, transportSessionError: nil, apiVersion: apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            guard let existingClient = UserClient.fetchUserClient(withRemoteId: existingClientID, forUser: self.otherUser, createIfNeeded: false) else { return XCTFail("Failed to fetch existing client") }

            XCTAssertNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: false))
            XCTAssertEqual(existingClient.remoteIdentifier, existingClientID)
        }
    }

    func testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry() {
        testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: .v0)
        testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: .v1)
    }

    private func testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: true))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: apiVersion)

            var transportData: ZMTransportData
            switch apiVersion {
            case .v0:
                transportData = ClientUpdateResponse(missing: ClientListByUser()).transportData
            case .v1:
                transportData = Payload.MessageSendingStatus(missing: UserListByDomain()).transportData
            }

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: transportData, httpStatus: 412, transportSessionError: nil, apiVersion: apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: false))
        }
    }

    func testThatItIgnoresMissingSelfClients() {
        testThatItIgnoresMissingSelfClients(apiVersion: .v0)
        testThatItIgnoresMissingSelfClients(apiVersion: .v1)
    }

    private func testThatItIgnoresMissingSelfClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let selfClientID = "selfClient1"

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let clientSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(clientSet)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = "example.com"
            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [selfUser.remoteIdentifier.transportString(): [selfClientID]]

            var transportData: ZMTransportData
            switch apiVersion {
            case .v0:
                transportData = ClientUpdateResponse(missing: clientListByUserID).transportData
            case .v1:
                transportData = Payload.MessageSendingStatus(missing: [selfUser.domain!: clientListByUserID]).transportData
            }

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: transportData, httpStatus: 412, transportSessionError: nil, apiVersion: apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            XCTAssertNotNil(selfUser.selfClient())
        }
    }

}
