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
import WireTesting
import WireDataModel
import WireCryptobox

@testable import WireRequestStrategy

class FetchClientRequestStrategyTests: MessagingTestBase {

    var sut: FetchingClientRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    var apiVersion: APIVersion! {
        didSet {
            APIVersion.current = apiVersion
        }
    }

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = FetchingClientRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
        NotificationCenter.default.addObserver(self, selector: #selector(FetchClientRequestStrategyTests.didReceiveAuthenticationNotification(_:)), name: NSNotification.Name(rawValue: "ZMUserSessionAuthenticationNotificationName"), object: nil)
        apiVersion = .v0
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockApplicationStatus = nil
        sut = nil
        NotificationCenter.default.removeObserver(self)
        apiVersion = nil
        super.tearDown()
    }

    func didReceiveAuthenticationNotification(_ notification: NSNotification) {

    }

}

// MARK: - Fetching client based on needsToBeUpdatedFromBackend flag

extension FetchClientRequestStrategyTests {

    func testThatItCreatesARequest_WhenUserClientNeedsToBeUpdatedFromBackend() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.apiVersion = .v1
            self.otherUser.domain = nil
            let clientUUID = UUID()
            let client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> = [client]

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)

            // THEN
            let request = self.sut.nextRequest(for: self.apiVersion)
            XCTAssertEqual(request?.path, "/v1/users/\(self.otherUser.remoteIdentifier!.transportString())/clients/\(clientUUID.transportString())")
        }
    }

    func testThatItUpdatesTheClient_WhenReceivingTheResponse() {
        apiVersion = .v1

        var client: UserClient!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.otherUser.domain = nil
            let clientUUID = UUID()
            let payload = [
                    "id": clientUUID.transportString(),
                    "class": "phone"
                ]
            client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> = [client]

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(client.deviceClass, .phone)
        }
    }

    func testThatItDeletesTheClient_WhenReceivingPermanentErrorResponse() {
        apiVersion = .v1

        var client: UserClient!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.otherUser.domain = nil
            let clientUUID = UUID()
            client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> =  [client]

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(client.isZombieObject)
        }
    }

}

// MARK: - Fetching clients in batches

extension FetchClientRequestStrategyTests {

    func testThatItCreatesABatchRequest_WhenUserClientNeedsToBeUpdatedFromBackend_AndDomainIsAvailble() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.apiVersion = .v1
            let clientUUID = UUID()
            let client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> = [client]
            self.otherUser.domain = "example.com"

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)

            // THEN
            XCTAssertEqual(self.sut.nextRequest(for: self.apiVersion)?.path, "/v1/users/list-clients")
        }
    }

    func testThatItUpdatesTheClient_WhenReceivingTheBatchResponse() {
        apiVersion = .v1

        var client: UserClient!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let clientUUID = UUID()
            let payload = [
                "example.com": [self.otherUser.remoteIdentifier.transportString(): [
                    Payload.UserClient(id: clientUUID.transportString(),
                                       deviceClass: "phone")
                    ]]
            ]
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> = [client]
            self.otherUser.domain = "example.com"
            self.syncMOC.saveOrRollback()

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)
            let request = self.sut.nextRequest(for: self.apiVersion)
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: self.apiVersion.rawValue)

            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(client.deviceClass, .phone)
        }
    }

    func testThatItDeletesLocalClient_WhenNotIncludedInBatchResponse() {
        apiVersion = .v1

        var client: UserClient!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let clientUUID = UUID()
            client = UserClient.fetchUserClient(withRemoteId: clientUUID.transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let clientSet: Set<NSManagedObject> = [client]
            let userID = self.otherUser.remoteIdentifier.transportString()
            let payload: Payload.UserClientByDomain = [
                "example.com": [userID: []]
            ]
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            self.otherUser.domain = "example.com"

            // WHEN
            client.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(clientSet)
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                                        httpStatus: 200,
                                                        transportSessionError: nil,
                                                        apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(client.isZombieObject)
        }
    }

    func testThatItMarksNewClientsAsMissingAndIgnored_WhenReceivingTheBatchResponse() {
        apiVersion = .v1
        var existingClient: UserClient!
        let newClientID = UUID()

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let userID = self.otherUser.remoteIdentifier!
            let payload = [
                "example.com": [userID.transportString(): [
                    Payload.UserClient(id: newClientID.transportString(),
                                       deviceClass: "phone")
                    ]]
            ]
            let payloadAsString = String(bytes: payload.payloadData()!, encoding: .utf8)!
            existingClient = UserClient.fetchUserClient(withRemoteId: UUID().transportString(), forUser: self.otherUser, createIfNeeded: true)!
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            self.otherUser.domain = "example.com"

            // WHEN
            existingClient.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(existingClientSet)
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                                        httpStatus: 200,
                                                        transportSessionError: nil,
                                                        apiVersion: self.apiVersion.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            let newClient = UserClient.fetchUserClient(withRemoteId: newClientID.transportString(), forUser: self.otherUser, createIfNeeded: false)!
            XCTAssertFalse(self.selfClient.trustedClients.contains(newClient))
            XCTAssertTrue(self.selfClient.ignoredClients.contains(newClient))
            XCTAssertTrue(self.selfClient.missingClients!.contains(newClient))
        }
    }

}

// MARK: - Fetching Other Users Clients

extension FetchClientRequestStrategyTests {

    func payloadForOtherClients(_ identifiers: String...) -> ZMTransportData {
        return identifiers.reduce([]) { $0 + [["id": $1,
                                               "class": "phone"]] } as ZMTransportData
    }

    func testThatItCreatesOtherUsersClientsCorrectly() {
        // GIVEN
        let (firstIdentifier, secondIdentifier) = (UUID.create().transportString(), UUID.create().transportString())
        let payload = [
            [
                "id": firstIdentifier,
                "class": "phone"
            ],
            [
                "id": secondIdentifier,
                "class": "tablet"
            ]
        ]

        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        let identifier = UUID.create()
        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = identifier
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let expectedDeviceClasses: Set<DeviceClass> = [.phone, .tablet]
            let actualDeviceClasses = Set(user.clients.compactMap(\.deviceClass))
            let expectedIdentifiers: Set<String> = [firstIdentifier, secondIdentifier]
            let actualIdentifiers = Set(user.clients.compactMap(\.remoteIdentifier))
            XCTAssertEqual(user.clients.count, 2)
            XCTAssertEqual(expectedDeviceClasses, actualDeviceClasses)
            XCTAssertEqual(expectedIdentifiers, actualIdentifiers)
        }
    }

    func testThatItAddsOtherUsersNewFetchedClientsToSelfUsersMissingClients() {
        // GIVEN
        var user: ZMUser!
        var payload: ZMTransportData!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            let (firstIdentifier, secondIdentifier) = (UUID.create().transportString(), UUID.create().transportString())
            payload = self.payloadForOtherClients(firstIdentifier, secondIdentifier)
            let identifier = UUID.create()
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = identifier
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(user.clients.count, 2)
            XCTAssertEqual(user.clients, self.selfClient.missingClients)
        }
    }

    func testThatItDeletesLocalClientsNotIncludedInResponseToFetchOtherUsersClients() {
        // GIVEN
        var payload: ZMTransportData!
        var firstIdentifier: String!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)

            firstIdentifier = UUID.create().transportString()
            payload = self.payloadForOtherClients(firstIdentifier)
            self.otherUser.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 1)
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 1)
            XCTAssertEqual(self.otherUser.clients.first?.remoteIdentifier, firstIdentifier)
        }
    }

    func testThatItCreatesLegacyRequest_WhenFederationEndpointIsNotAvailable() {
        // GIVEN
        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            user = self.selfClient.user!
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        self.syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: self.apiVersion)

            // THEN
            if let request = request {
                let path = "/users/\(user.remoteIdentifier!.transportString())/clients"
                XCTAssertEqual(request.path, path)
                XCTAssertEqual(request.method, .methodGET)
            } else {
                XCTFail("Failed to create request")
            }
        }
    }

    func testThatItCreatesBatchRequest_WhenFederationEndpointIsAvailable() {
        // GIVEN
        apiVersion = .v1

        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            user = self.selfClient.user!
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        self.syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest(for: self.apiVersion)

            // THEN
            if let request = request {
                let path = "/v1/users/list-clients"
                XCTAssertEqual(request.path, path)
                XCTAssertEqual(request.method, .methodPOST)
            } else {
                XCTFail("Failed to create request")
            }
        }
    }
}

// MARK: - Fetching other user's clients / RemoteIdentifierObjectSync
extension FetchClientRequestStrategyTests {

    func testThatItDoesNotDeleteAnObjectWhenResponseContainsRemoteID() {

        // GIVEN
        var payload: ZMTransportData!
        self.syncMOC.performGroupedBlockAndWait {
            let user = self.otherClient.user
            user?.fetchUserClients()
            payload = [["id": self.otherClient.remoteIdentifier!, "class": "phone"]] as NSArray
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(self.otherClient.isDeleted)
        }
    }

    func testThatItAddsFetchedClientToIgnoredClientsWhenClientDoesNotExist() {
        // GIVEN
        var payload: ZMTransportData!
        let remoteIdentifier = "aabbccdd0011"
        self.syncMOC.performGroupedBlockAndWait {
            self.otherUser.fetchUserClients()
            payload = [["id": remoteIdentifier, "class": "phone"]] as NSArray
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.selfClient.trustedClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
            XCTAssertNotNil(self.selfClient.ignoredClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
        }
    }

    func testThatItAddsFetchedClientToIgnoredClientsWhenClientHasNoSession() {
        // GIVEN
        var payload: ZMTransportData!
        var client: UserClient!
        self.syncMOC.performGroupedBlockAndWait {
            client = self.createClient(user: self.otherUser)
            XCTAssertFalse(client.hasSessionWithSelfClient)
            self.otherUser.fetchUserClients()
            payload = [["id": client.remoteIdentifier!, "class": "phone"]] as NSArray
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(self.selfClient.trustedClients.contains(client))
            XCTAssertTrue(self.selfClient.ignoredClients.contains(client))
        }
    }

    func testThatItAddsFetchedClientToIgnoredClientsWhenSessionExistsButClientDoesNotExist() {
        // GIVEN
        var payload: ZMTransportData!
        let remoteIdentifier = "aabbccdd0011"
        var sessionIdentifier: EncryptionSessionIdentifier!
        self.syncMOC.performGroupedBlockAndWait {
            sessionIdentifier = EncryptionSessionIdentifier(userId: self.otherUser!.remoteIdentifier.uuidString, clientId: remoteIdentifier)
            self.otherUser.fetchUserClients()
            payload = [["id": remoteIdentifier, "class": "phone"]] as NSArray
            self.selfClient.keysStore.encryptionContext.perform {
                try! $0.createClientSession(sessionIdentifier, base64PreKeyString: self.selfClient.keysStore.lastPreKey()) // just a bogus key is OK
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.selfClient.trustedClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
            XCTAssertNotNil(self.selfClient.ignoredClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
        }
    }

    func testThatItDeletesAnObjectWhenResponseDoesNotContainRemoteID() {
        // GIVEN
        let remoteID = "otherRemoteID"
        let payload: [[String: Any]] = [["id": remoteID, "class": "phone"]]
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNotEqual(self.otherClient.remoteIdentifier, remoteID)
            let user = self.otherClient.user
            user?.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: self.apiVersion.rawValue)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.otherClient.isZombieObject)
        }
    }
}
