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

struct ClientUpdateStatusChange {
    let type: ZMClientUpdateNotificationType
    var clientObjectIDs: [NSManagedObjectID]
    var error: NSError?
}

class ClientUpdateStatusTests: MessagingTest {
    var sut: ClientUpdateStatus!
    var clientObserverToken: Any?
    var receivedNotifications: [ClientUpdateStatusChange] = []

    override func setUp() {
        super.setUp()
        self.sut = ClientUpdateStatus(syncManagedObjectContext: self.syncMOC)

        clientObserverToken = ZMClientUpdateNotification.addObserver(context: uiMOC) { [weak self] (type, clientObjectIDs, error) in
            self?.receivedNotifications.append(ClientUpdateStatusChange(type: type, clientObjectIDs: clientObjectIDs, error: error))
        }
    }

    override func tearDown() {
        sut = nil
        clientObserverToken = nil
        receivedNotifications = []
        super.tearDown()
    }

    func testThatItReturnsfetchingClientsByDefault() {
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients)
    }

    func testThatItReturnsFetchingClientsWhenFetchStarted() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients)
    }

    func insertNewClient(_ isSelfClient: Bool) -> UserClient! {
        var client: UserClient!
        self.syncMOC.performGroupedBlockAndWait { () -> Void in
            client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = isSelfClient ? "selfIdentifier" : "identifier"
            client.user = ZMUser.selfUser(in: self.syncMOC)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        if isSelfClient {
            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: "PersistedClientId")
        }
        return client
    }

    func insertSelfClient() -> UserClient {
        return insertNewClient(true)!
    }

    func insertNewClient() -> UserClient {
        return insertNewClient(false)!
    }

    func testThatFetchedClientsDoNotContainSelfClient() {
        // given
        let selfClient = insertSelfClient()
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([selfClient, otherClient])
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)

        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs.count, 1)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }

    }

    func testThatItCallsTheCompletionHandlerWhenFetchCompletes() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)

        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs.count, 1)
            XCTAssertEqual(clientIDs.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItCallsTheCompletionHandlerWithErrorWhenFetchFails() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.failedToFetchClients()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients) // if we go back online we want to try to verify the client
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clients = note.clientObjectIDs
            XCTAssertEqual(clients, [])
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.deviceIsOffline.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItCallsCompletionHandlerAfterDeletingClient_AllClientsDeleted() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()

        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)
        self.receivedNotifications.removeAll()

        // when
        let credentials = ZMEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.deletingClients)

        self.sut.didDeleteClient()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNotNil(note.clientObjectIDs)
            XCTAssertEqual(note.clientObjectIDs.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.deletionCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfSelfClientWasRemovedRemotely() {
        // given
        _ = insertSelfClient()
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([otherClient])
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.selfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfSelfClientIsNotRegistered() {
        // given
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([otherClient])
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.selfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfCredentialsAreInvalid() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])

        let error = NSError(domain: "ClientManagement", code: Int(ClientUpdateError.invalidCredentials.rawValue), userInfo: nil)
        self.receivedNotifications.removeAll()

        // when
        let credentials = ZMEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        self.sut.failedToDeleteClient(client, error: error)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.deletionFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.invalidCredentials.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItResetsTheDeletionOfTheSelfClientAtInit() {

        // GIVEN
        // remove previous
        clientObserverToken = nil

        // delete self client
        let selfClient = insertSelfClient()
        selfClient.markedToDelete = true
        selfClient.setLocallyModifiedKeys(Set([ZMUserClientMarkedToDeleteKey]))
        selfClient.managedObjectContext?.saveOrRollback()

        // WHEN
        // re-create
        self.sut = ClientUpdateStatus(syncManagedObjectContext: self.syncMOC)
        clientObserverToken = ZMClientUpdateNotification.addObserver(context: uiMOC) { [weak self] (type, clientObjectIDs, error) in
            self?.receivedNotifications.append(ClientUpdateStatusChange(type: type, clientObjectIDs: clientObjectIDs, error: error))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertFalse(selfClient.markedToDelete)
        XCTAssertFalse(selfClient.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))

    }
}
