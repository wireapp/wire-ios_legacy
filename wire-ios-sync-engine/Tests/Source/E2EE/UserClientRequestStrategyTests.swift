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

import XCTest
@testable import WireSyncEngine
import WireUtilities
import WireTesting
import WireMockTransport
import WireDataModel

@objcMembers
public class MockClientRegistrationStatusDelegate: NSObject, ZMClientRegistrationStatusDelegate {

    public var currentError: Error?

    public var didCallRegisterSelfUserClient: Bool = false
    public func didRegisterSelfUserClient(_ userClient: UserClient!) {
        didCallRegisterSelfUserClient = true
    }

    public var didCallFailRegisterSelfUserClient: Bool = false
    public func didFailToRegisterSelfUserClient(error: Error!) {
        currentError = error
        didCallFailRegisterSelfUserClient = true
    }

    public var didCallDeleteSelfUserClient: Bool = false
    public func didDeleteSelfUserClient(error: Error!) {
        currentError = error
        didCallDeleteSelfUserClient = true
    }
}

class UserClientRequestStrategyTests: RequestStrategyTestBase {

    var sut: UserClientRequestStrategy!
    var clientRegistrationStatus: ZMMockClientRegistrationStatus!
    var mockClientRegistrationStatusDelegate: MockClientRegistrationStatusDelegate!
    var authenticationStatus: MockAuthenticationStatus!
    var clientUpdateStatus: ZMMockClientUpdateStatus!
    let fakeCredentialsProvider = FakeCredentialProvider()

    var cookieStorage: ZMPersistentCookieStorage!

    var spyKeyStore: SpyUserClientKeyStore!

    var postLoginAuthenticationObserverToken: Any?

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedBlockAndWait {
            self.spyKeyStore = SpyUserClientKeyStore(accountDirectory: self.accountDirectory, applicationContainer: self.sharedContainerURL)
            self.cookieStorage = ZMPersistentCookieStorage(forServerName: "myServer", userIdentifier: self.userIdentifier)
            self.mockClientRegistrationStatusDelegate = MockClientRegistrationStatusDelegate()
            self.clientRegistrationStatus = ZMMockClientRegistrationStatus(managedObjectContext: self.syncMOC,
                                                                           cookieStorage: self.cookieStorage,
                                                                           registrationStatusDelegate: self.mockClientRegistrationStatusDelegate)
            self.clientUpdateStatus = ZMMockClientUpdateStatus(syncManagedObjectContext: self.syncMOC)
            self.sut = UserClientRequestStrategy(clientRegistrationStatus: self.clientRegistrationStatus, clientUpdateStatus: self.clientUpdateStatus, context: self.syncMOC, userKeysStore: self.spyKeyStore)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: spyKeyStore.cryptoboxDirectory)

        self.clientRegistrationStatus.tearDown()
        self.clientRegistrationStatus = nil
        self.mockClientRegistrationStatusDelegate = nil
        self.clientUpdateStatus = nil
        self.spyKeyStore = nil
        self.sut.tearDown()
        self.sut = nil
        self.postLoginAuthenticationObserverToken = nil
        super.tearDown()
    }
}

// MARK: Inserting
extension UserClientRequestStrategyTests {

    func createSelfClient(_ context: NSManagedObjectContext) -> UserClient {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = nil
        selfClient.user = ZMUser.selfUser(in: context)
        return selfClient
    }

    func testThatItReturnsRequestForInsertedObject() {
        syncMOC.performGroupedBlockAndWait {

            // given
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.notifyChangeTrackers(client)
            self.clientRegistrationStatus.mockPhase = .unregistered

            // when
            self.clientRegistrationStatus.prepareForClientRegistration()

            let request = self.sut.nextRequest(for: .v0)

            // then
            let expectedRequest = try! self.sut.requestsFactory.registerClientRequest(client, credentials: self.fakeCredentialsProvider.emailCredentials(), cookieLabel: "mycookie", apiVersion: .v0).transportRequest!

            AssertOptionalNotNil(request, "Should return request if there is inserted UserClient object") { request in
                XCTAssertNotNil(request.payload, "Request should contain payload")
                XCTAssertEqual(request.method, expectedRequest.method, "")
                XCTAssertEqual(request.path, expectedRequest.path, "")
            }
        }
    }

    func testThatItDoesNotReturnRequestIfThereIsNoInsertedObject() {
        syncMOC.performGroupedBlockAndWait {

            // given
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.notifyChangeTrackers(client)

            // when
            self.clientRegistrationStatus.prepareForClientRegistration()

            _ = self.sut.nextRequest(for: .v0)
            let nextRequest = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(nextRequest, "Should return request only if UserClient object inserted")
        }
    }

    func testThatItStoresTheRemoteIdentifierWhenUpdatingAnInsertedObject() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.managedObjectContext!.saveOrRollback()

            let remoteIdentifier = "superRandomIdentifer"
            let payload = ["id": remoteIdentifier]
            let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            let request = self.sut.request(forInserting: client, forKeys: Set(), apiVersion: .v0)

            // when
            self.sut.updateInsertedObject(client, request: request!, response: response)

            // then
            XCTAssertNotNil(client.remoteIdentifier, "Should store remoteIdentifier provided by response")
            XCTAssertEqual(client.remoteIdentifier, remoteIdentifier)

            let storedRemoteIdentifier = self.syncMOC.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String
            AssertOptionalEqual(storedRemoteIdentifier, expression2: remoteIdentifier)
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        }
    }

    func testThatItStoresTheLastGeneratedPreKeyIDWhenUpdatingAnInsertedObject() {

        var client: UserClient! = nil
        var maxID_before: UInt16! = nil

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered

            client = self.createSelfClient(self.sut.managedObjectContext!)
            maxID_before = UInt16(client.preKeysRangeMax)
            XCTAssertEqual(maxID_before, 0)

            self.sut.notifyChangeTrackers(client)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(payload: ["id": "fakeRemoteID"] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            let maxID_after = UInt16(client.preKeysRangeMax)
            let expectedMaxID = self.spyKeyStore.lastGeneratedKeys.last?.id

            XCTAssertNotEqual(maxID_after, maxID_before)
            XCTAssertEqual(maxID_after, expectedMaxID)
        }
    }

    func testThatItStoresTheSignalingKeysWhenUpdatingAnInsertedObject() {

        var client: UserClient! = nil
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered

            client = self.createSelfClient(self.syncMOC)
            XCTAssertNil(client.apsDecryptionKey)
            XCTAssertNil(client.apsVerificationKey)

            self.sut.notifyChangeTrackers(client)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(payload: ["id": "fakeRemoteID"] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertNotNil(client.apsDecryptionKey)
            XCTAssertNotNil(client.apsVerificationKey)
        }
    }

    func testThatItNotifiesObserversWhenUpdatingAnInsertedObject() {

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(payload: ["id": "fakeRemoteID"] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertTrue(self.mockClientRegistrationStatusDelegate.didCallRegisterSelfUserClient)
    }

    func testThatItProcessFailedInsertResponseWithAuthenticationError_NoEmail() {

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let responsePayload = ["code": 403, "message": "Re-authentication via password required", "label": "missing-auth"] as [String: Any]
            let response = ZMTransportResponse(payload: responsePayload as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertTrue(self.mockClientRegistrationStatusDelegate.didCallFailRegisterSelfUserClient)
        let expectedError = NSError(domain: NSError.ZMUserSessionErrorDomain,
                                    code: Int(ZMUserSessionErrorCode.invalidCredentials.rawValue),
                                    userInfo: nil)
        XCTAssertEqual(self.mockClientRegistrationStatusDelegate.currentError as NSError?, expectedError)
    }

    func testThatItProcessFailedInsertResponseWithAuthenticationError_HasEmail() {

        let emailAddress = "hello@example.com"

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.setValue(emailAddress, forKey: #keyPath(ZMUser.emailAddress))

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let responsePayload = ["code": 403, "message": "Re-authentication via password required", "label": "missing-auth"] as [String: Any]
            let response = ZMTransportResponse(payload: responsePayload as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            let expectedError = NSError(domain: NSError.ZMUserSessionErrorDomain, code: Int(ZMUserSessionErrorCode.needsPasswordToRegisterClient.rawValue), userInfo: [
                ZMEmailCredentialKey: emailAddress,
                ZMUserHasPasswordKey: true,
                ZMUserUsesCompanyLoginCredentialKey: false,
                ZMUserLoginCredentialsKey: LoginCredentials(emailAddress: emailAddress, phoneNumber: nil, hasPassword: true, usesCompanyLogin: false)
            ])

            XCTAssertTrue(self.mockClientRegistrationStatusDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(self.mockClientRegistrationStatusDelegate.currentError as NSError?, expectedError)
        }
    }

    func testThatItProcessFailedInsertResponseWithTooManyClientsError() {

        syncMOC.performGroupedBlock {
            // given
            self.cookieStorage.authenticationCookieData = Data()
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            guard let request = self.sut.nextRequest(for: .v0) else {
                XCTFail()
                return
            }
            let responsePayload = ["code": 403, "message": "Too many clients", "label": "too-many-clients"] as [String: Any]
            let response = ZMTransportResponse(payload: responsePayload as ZMTransportData?, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            _ = NSError(domain: NSError.ZMUserSessionErrorDomain, code: Int(ZMUserSessionErrorCode.canNotRegisterMoreClients.rawValue), userInfo: nil)

            // when
            self.clientRegistrationStatus.mockPhase = nil
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(self.clientRegistrationStatus.currentPhase, ZMClientRegistrationPhase.fetchingClients)
        }
    }

}

// MARK: Updating
extension UserClientRequestStrategyTests {

    func testThatItReturnsRequestIfNumberOfRemainingKeysIsLessThanMinimum() {

        syncMOC.performGroupedBlockAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // when
            guard let request = self.sut.nextRequest(for: .v0) else {
                XCTFail()
                return
            }

            // then
            let expectedRequest = try! self.sut.requestsFactory.updateClientPreKeysRequest(client, apiVersion: .v0).transportRequest

            AssertOptionalNotNil(request, "Should return request if there is inserted UserClient object") { request in
                XCTAssertNotNil(request.payload, "Request should contain payload")
                XCTAssertEqual(request.method, expectedRequest?.method)
                XCTAssertEqual(request.path, expectedRequest?.path)
            }
        }
    }

    func testThatItDoesNotReturnsRequestIfNumberOfRemainingKeysIsLessThanMinimum_NoRemoteIdentifier() {
        syncMOC.performGroupedBlockAndWait {

            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]

            // when
            client.remoteIdentifier = nil
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItDoesNotReturnRequestIfNumberOfRemainingKeysIsAboveMinimum() {
        syncMOC.performGroupedBlockAndWait {

            // given
            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys)

            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request, "Should not return request if there are enouth keys left")
        }
    }

    func testThatItResetsNumberOfRemainingKeysAfterNewKeysUploaded() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            let expectedNumberOfKeys = client.numberOfKeysRemaining + Int32(self.sut.requestsFactory.keyCount)

            // when
            let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            let userClientNumberOfKeysRemainingKeySet: Set<String> = [ZMUserClientNumberOfKeysRemainingKey]
            _ = self.sut.updateUpdatedObject(client, requestUserInfo: nil, response: response, keysToParse: userClientNumberOfKeysRemainingKeySet)

            // then
            XCTAssertEqual(client.numberOfKeysRemaining, expectedNumberOfKeys)
        }
    }
}

// MARK: Fetching Clients
extension UserClientRequestStrategyTests {

    func  payloadForClients() -> ZMTransportData {
        let payload =  [
            [
                "id": UUID.create().transportString(),
                "type": "permanent",
                "label": "client",
                "time": Date().transportString()
            ],
            [
                "id": UUID.create().transportString(),
                "type": "permanent",
                "label": "client",
                "time": Date().transportString()
            ]
        ]

        return payload as ZMTransportData
    }

    func testThatItNotifiesWhenFinishingFetchingTheClient() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let nextResponse = ZMTransportResponse(payload: self.payloadForClients() as ZMTransportData?, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            _ = self.sut.nextRequest(for: .v0)
            self.sut.didReceive(nextResponse, forSingleRequest: self.sut.fetchAllClientsSync)

            // then
            AssertOptionalNotNil(self.clientUpdateStatus.fetchedClients, "userinfo should contain clientIDs") { _ in
                XCTAssertEqual(self.clientUpdateStatus.fetchedClients.count, 2)
                for client in self.clientUpdateStatus.fetchedClients {
                    XCTAssertEqual(client?.label!, "client")
                }
            }
        }
    }

    func testThatDeletesClientsThatWereNotInTheFetchResponse() {

        var selfUser: ZMUser!
        var selfClient: UserClient!
        var newClient: UserClient!

        syncMOC.performGroupedBlockAndWait {
            // given
            selfClient = self.createSelfClient()
            selfUser = ZMUser.selfUser(in: self.syncMOC)
            let nextResponse = ZMTransportResponse(payload: self.payloadForClients() as ZMTransportData?, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            newClient = UserClient.insertNewObject(in: self.syncMOC)
            newClient.user = selfUser
            newClient.remoteIdentifier = "deleteme"
            self.syncMOC.saveOrRollback()

            // when
            _ = self.sut.nextRequest(for: .v0)
            self.sut.didReceive(nextResponse, forSingleRequest: self.sut.fetchAllClientsSync)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(selfUser.clients.contains(selfClient))
            XCTAssertFalse(selfUser.clients.contains(newClient))
        }
    }
}

// MARK: Deleting
extension UserClientRequestStrategyTests {

    func testThatItCreatesARequestToDeleteAClient_UpdateStatus() {

        syncMOC.performGroupedBlockAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered
            self.clientUpdateStatus.mockPhase = .deletingClients
            let clients = [
                UserClient.insertNewObject(in: self.syncMOC),
                UserClient.insertNewObject(in: self.syncMOC)
            ]
            clients.forEach {
                $0.remoteIdentifier = "\($0.objectID)"
                $0.user = ZMUser.selfUser(in: self.syncMOC)
            }
            self.syncMOC.saveOrRollback()

            // when
            clients[0].markForDeletion()
            self.sut.notifyChangeTrackers(clients[0])

            let nextRequest = self.sut.nextRequest(for: .v0)

            // then
            AssertOptionalNotNil(nextRequest) {
                XCTAssertEqual($0.path, "/clients/\(clients[0].remoteIdentifier!)")
                XCTAssertEqual($0.payload as! [String: String], [
                    "email": self.clientUpdateStatus.mockCredentials.email!,
                    "password": self.clientUpdateStatus.mockCredentials.password!
                    ])
                XCTAssertEqual($0.method, ZMTransportRequestMethod.methodDELETE)
            }
        }
    }

    func testThatItDeletesAClientOnSuccess() {

        // given
        var client: UserClient!

        self.syncMOC.performGroupedBlock {
            client =  UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "\(client.objectID)"
            client.user = ZMUser.selfUser(in: self.syncMOC)
            self.syncMOC.saveOrRollback()

            let response = ZMTransportResponse(payload: [:] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            // when
            let userClientMarkedToDeleteKeySet: Set<String> = [ZMUserClientMarkedToDeleteKey]
            _ = self.sut.updateUpdatedObject(client, requestUserInfo: nil, response: response, keysToParse: userClientMarkedToDeleteKeySet)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(client.isZombieObject)
        }
    }
}

// MARK: - Updating from push events
extension UserClientRequestStrategyTests {

    func testThatItCreatesARequestForClientsThatNeedToUploadSignalingKeys() {

        var existingClient: UserClient! = nil
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateSignalingKeysKeySet: Set<AnyHashable> = [ZMUserClientNeedsToUpdateSignalingKeysKey]

            XCTAssertNil(existingClient.apsVerificationKey)
            XCTAssertNil(existingClient.apsDecryptionKey)

            // when
            existingClient.needsToUploadSignalingKeys = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateSignalingKeysKeySet)
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange(existingClientSet)
            }
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)

            // and when
            let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedBlock {
            XCTAssertNotNil(existingClient.apsVerificationKey)
            XCTAssertNotNil(existingClient.apsDecryptionKey)
            XCTAssertFalse(existingClient.needsToUploadSignalingKeys)
            XCTAssertFalse(existingClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateSignalingKeysKey))
        }
    }

    func testThatItRetriesOnceWhenUploadSignalingKeysFails() {

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateSignalingKeysKeySet: Set<AnyHashable> =  [ZMUserClientNeedsToUpdateSignalingKeysKey]
            XCTAssertNil(existingClient.apsVerificationKey)
            XCTAssertNil(existingClient.apsDecryptionKey)

            existingClient.needsToUploadSignalingKeys = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateSignalingKeysKeySet)
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange(existingClientSet)
            }

            // when
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)
            let badResponse = ZMTransportResponse(payload: ["label": "bad-request"] as ZMTransportData, httpStatus: 400, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            request?.complete(with: badResponse)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let secondRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(secondRequest)
            let success = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            secondRequest?.complete(with: success)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let thirdRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNil(thirdRequest)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItCreatesARequestForClientsThatNeedToUpdateCapabilities() {

        var existingClient: UserClient! = nil
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateCapabilitiesKeySet: Set<AnyHashable> =  [ZMUserClientNeedsToUpdateCapabilitiesKey]

            // when
            existingClient.needsToUpdateCapabilities = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateCapabilitiesKeySet)
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange(existingClientSet)
            }
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)

            // and when
            let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedBlock {
            XCTAssertFalse(existingClient.needsToUpdateCapabilities)
            XCTAssertFalse(existingClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateCapabilitiesKey))
        }
    }

    func testThatItRetriesOnceWhenUpdateCapabilitiesFails() {

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateCapabilitiesKeySet: Set<AnyHashable> = [ZMUserClientNeedsToUpdateCapabilitiesKey]

            existingClient.needsToUpdateCapabilities = true

            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateCapabilitiesKeySet)
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange(existingClientSet)
            }

            // when
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)
            let badResponse = ZMTransportResponse(payload: ["label": "bad-request"] as ZMTransportData, httpStatus: 400, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            request?.complete(with: badResponse)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let secondRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(secondRequest)
            let success = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            secondRequest?.complete(with: success)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let thirdRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNil(thirdRequest)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

}

extension UserClientRequestStrategy {

    func notifyChangeTrackers(_ object: ZMManagedObject) {
        self.contextChangeTrackers.forEach { $0.objectsDidChange(Set([object])) }
    }
}
