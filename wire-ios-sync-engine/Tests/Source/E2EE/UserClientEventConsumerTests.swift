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

class UserClientEventConsumerTests: RequestStrategyTestBase {

    var sut: UserClientEventConsumer!
    var clientRegistrationStatus: ZMMockClientRegistrationStatus!
    var clientUpdateStatus: ZMMockClientUpdateStatus!
    var cookieStorage: ZMPersistentCookieStorage!

    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedBlockAndWait {
            self.cookieStorage = ZMPersistentCookieStorage(forServerName: "myServer",
                                                           userIdentifier: self.userIdentifier)

            self.clientUpdateStatus = ZMMockClientUpdateStatus(syncManagedObjectContext: self.syncMOC)

            self.clientRegistrationStatus = ZMMockClientRegistrationStatus(managedObjectContext: self.syncMOC,
                                                                           cookieStorage: self.cookieStorage,
                                                                           registrationStatusDelegate: nil)

            self.sut = UserClientEventConsumer(managedObjectContext: self.syncMOC,
                                               clientRegistrationStatus: self.clientRegistrationStatus,
                                               clientUpdateStatus: self.clientUpdateStatus)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        self.clientRegistrationStatus.tearDown()
        self.clientRegistrationStatus = nil
        self.clientUpdateStatus = nil
        self.sut = nil
        super.tearDown()
    }

    static func payloadForAddingClient(_ clientId: String,
                                       label: String = "device label",
                                       time: Date = Date(timeIntervalSince1970: 12345)
        ) -> ZMTransportData {

        return [
            "client": [
                "id": clientId,
                "label": label,
                "time": time.transportString(),
                "type": "permanent"
            ],
            "type": "user.client-add"
            ] as ZMTransportData
    }

    static func payloadForDeletingClient(_ clientId: String) -> ZMTransportData {

        return [
            "client": [
                "id": clientId
            ],
            "type": "user.client-remove"
            ] as ZMTransportData
    }

    func testThatItAddsAnIgnoredSelfUserClientWhenReceivingAPush() {

        // given
        let clientId = "94766bd92f56923d"
        let clientLabel = "iPhone 23sd Plus Air Pro C"
        let clientTime = Date(timeIntervalSince1970: 1234555)
        var selfUser: ZMUser! = nil
        var selfClient: UserClient! = nil

        syncMOC.performGroupedBlock {
            selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfClient = self.createSelfClient()
            _ = self.createRemoteClient()
            XCTAssertEqual(selfUser.clients.count, 1)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let payload: [String: Any] = [
            "id": "27330a52-bab6-11e5-8183-22000b080265",
            "payload": [
                type(of: self).payloadForAddingClient(clientId, label: clientLabel, time: clientTime)
            ],
            "transient": false
        ]

        let events = ZMUpdateEvent.eventsArray(fromPushChannelData: payload as ZMTransportData)
        guard let event = events!.first else {
            XCTFail()
            return
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)

            // then
            XCTAssertEqual(selfUser.clients.count, 2)
            guard let newClient = selfUser.clients.filter({ $0 != selfClient}).first else {
                XCTFail()
                return
            }
            XCTAssertEqual(newClient.remoteIdentifier, clientId)
            XCTAssertEqual(newClient.label, clientLabel)
            XCTAssertEqual(newClient.activationDate, clientTime)
            XCTAssertTrue(selfClient.ignoredClients.contains(newClient))
        }
    }

    func testThatItAddsASelfUserClientWhenDownloadingAClientEvent() {

        // given
        let clientId = "94766bd92f56923d"
        var selfUser: ZMUser! = nil
        syncMOC.performGroupedBlockAndWait {
            selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertEqual(selfUser.clients.count, 0)
        }

        let payload = type(of: self).payloadForAddingClient(clientId)
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        self.syncMOC.performGroupedBlock {
            self.sut.processEvents([event], liveEvents: false, prefetchResult: .none)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(selfUser.clients.count, 1)
            guard let newClient = selfUser.clients.first else {
                XCTFail()
                return
            }
            XCTAssertEqual(newClient.remoteIdentifier, clientId)
        }

    }

    func testThatItDoesNotAddASelfUserClientWhenReceivingAPushIfTheClientExistsAlready() {

        // given
        var selfUser: ZMUser! = nil
        var existingClient: UserClient! = nil
        syncMOC.performGroupedBlockAndWait {
            selfUser = ZMUser.selfUser(in: self.syncMOC)
            existingClient = self.createSelfClient()
            XCTAssertEqual(selfUser.clients.count, 1)
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            let payload: [String: Any] = [
                "id": "27330a52-bab6-11e5-8183-22000b080265",
                "payload": [
                    type(of: self).payloadForAddingClient(existingClient.remoteIdentifier!)
                ],
                "transient": false
            ]

            let events = ZMUpdateEvent.eventsArray(fromPushChannelData: payload as ZMTransportData)
            guard let event = events!.first else {
                XCTFail()
                return
            }

            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)
        }

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(selfUser.clients.count, 1)
            guard let newClient = selfUser.clients.first else {
                XCTFail()
                return
            }
            XCTAssertEqual(newClient, existingClient)
        }
    }

    func testThatItDeletesASelfClientWhenReceivingAPush() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let existingClient1 = self.createSelfClient()
            let existingClient2 = UserClient.insertNewObject(in: self.syncMOC)
            existingClient2.user = selfUser
            existingClient2.remoteIdentifier = "aabbcc112233"
            self.syncMOC.saveOrRollback()

            XCTAssertEqual(selfUser.clients.count, 2)
            let payload: [String: Any] = [
                "id": "27330a52-bab6-11e5-8183-22000b080265",
                "payload": [
                    type(of: self).payloadForDeletingClient(existingClient2.remoteIdentifier!)
                ],
                "transient": false
            ]

            let events = ZMUpdateEvent.eventsArray(fromPushChannelData: payload as ZMTransportData)
            guard let event = events!.first else {
                XCTFail()
                return
            }

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)

            // then
            XCTAssertEqual(selfUser.clients.count, 1)
            guard let newClient = selfUser.clients.first else {
                XCTFail()
                return
            }
            XCTAssertEqual(newClient, existingClient1)
        }
    }

    func testThatItInvalidatesTheCurrentSelfClientAndWipeCryptoBoxWhenReceivingAPush() {

        syncMOC.performGroupedBlockAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let existingClient = self.createSelfClient()

            var fingerprint: Data?
            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                fingerprint = sessionsDirectory.localFingerprint
            }
            let previousLastPrekey = try? self.syncMOC.zm_cryptKeyStore.lastPreKey()

            XCTAssertEqual(selfUser.clients.count, 1)
            let payload: [String: Any] = [
                "id": "27330a52-bab6-11e5-8183-22000b080265",
                "payload": [
                    type(of: self).payloadForDeletingClient(existingClient.remoteIdentifier!)
                ],
                "transient": false
                ] as [String: Any]

            let events = ZMUpdateEvent.eventsArray(fromPushChannelData: payload as ZMTransportData)
            guard let event = events!.first else { return XCTFail() }

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)

            // then
            var newFingerprint: Data?
            self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
                newFingerprint = sessionsDirectory.localFingerprint
            }
            let newLastPrekey = try? self.syncMOC.zm_cryptKeyStore.lastPreKey()

            XCTAssertNotNil(fingerprint)
            XCTAssertNotNil(newFingerprint)
            XCTAssertNotEqual(fingerprint, newFingerprint)
            XCTAssertNil(selfUser.clients.first?.remoteIdentifier)
            XCTAssertNil(self.syncMOC.persistentStoreMetadata(forKey: ZMPersistedClientIdKey))
            XCTAssertNotNil(fingerprint)
            XCTAssertNotNil(newFingerprint)
            XCTAssertNotEqual(previousLastPrekey, newLastPrekey)
        }
    }

}
