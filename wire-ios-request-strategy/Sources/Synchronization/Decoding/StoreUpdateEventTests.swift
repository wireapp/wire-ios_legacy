//
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

import WireTesting
@testable import WireRequestStrategy

class StoreUpdateEventTests: MessagingTestBase {

    var account: Account!
    var publicKey: SecKey?
    var encryptionKeys: EncryptionKeys?

    override func setUp() {
        super.setUp()

        self.eventMOC.performGroupedBlockAndWait { [self] in
            account = Account(userName: "John Doe", userIdentifier: UUID())
            // Notice: keys are nil when test with iOS 15 simulator. ref:https://wearezeta.atlassian.net/browse/SQCORE-1188
            encryptionKeys = try? EncryptionKeys.createKeys(for: account)
            publicKey = try? EncryptionKeys.publicKey(for: account)
        }
    }

    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        account = nil
        publicKey = nil
        encryptionKeys = nil
        super.tearDown()
    }

    func testThatYouCanCreateAnEvent() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            // when
            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2) {

                // then
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItFetchesAllStoredEvents() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 0),
                  let storedEvent2 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 1),
                  let storedEvent3 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2)
            else {
                return XCTFail("Could not create storedEvents")
            }

            // when
            let batch = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: 4)

            // then
            XCTAssertEqual(batch.count, 3)
            XCTAssertTrue(batch.contains(storedEvent1))
            XCTAssertTrue(batch.contains(storedEvent2))
            XCTAssertTrue(batch.contains(storedEvent3))
            batch.forEach { XCTAssertFalse($0.isFault) }
        }
    }

    func testThatItOrdersEventsBySortIndex() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])
            let event = ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID.create())!

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 0),
                  let storedEvent2 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 30),
                  let storedEvent3 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 10)
            else {
                return XCTFail("Could not create storedEvents")
            }

            // when
            let storedEvents = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: 3)

            // then
            XCTAssertEqual(storedEvents[0], storedEvent1)
            XCTAssertEqual(storedEvents[1], storedEvent3)
            XCTAssertEqual(storedEvents[2], storedEvent2)
        }
    }

    func testThatItReturnsOnlyDefinedBatchSize() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])
            let event = ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID.create())!

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 0),
                  let storedEvent2 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 10),
                  let storedEvent3 = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 30)
            else {
                return XCTFail("Could not create storedEvents")
            }

            // when
            let firstBatch = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: 2)

            // then
            XCTAssertEqual(firstBatch.count, 2)
            XCTAssertTrue(firstBatch.contains(storedEvent1))
            XCTAssertTrue(firstBatch.contains(storedEvent2))
            XCTAssertFalse(firstBatch.contains(storedEvent3))

            // when
            firstBatch.forEach(self.eventMOC.delete)
            let secondBatch = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: 2)

            // then
            XCTAssertEqual(secondBatch.count, 1)
            XCTAssertTrue(secondBatch.contains(storedEvent3))
        }
    }

    func testThatItReturnsHighestIndex() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!

            guard (StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 0) != nil),
                  (StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 1) != nil),
                  (StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2) != nil)
            else {
                return XCTFail("Could not create storedEvents")
            }

            // when
            let highestIndex = StoredUpdateEvent.highestIndex(self.eventMOC)

            // then
            XCTAssertEqual(highestIndex, 2)
        }
    }

    func testThatItCanConvertAnEventToStoredEventAndBack() {

        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!

            // when
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 0)
            else {
                return XCTFail("Could not create storedEvents")

            }

            guard let restoredEvent = StoredUpdateEvent.eventsFromStoredEvents([storedEvent]).first
            else {
                return XCTFail("Could not create original event")
            }

            // then
            XCTAssertEqual(restoredEvent, event)
            XCTAssertEqual(restoredEvent.payload["foo"] as? String, event.payload["foo"] as? String)
            XCTAssertEqual(restoredEvent.isTransient, event.isTransient)
            XCTAssertEqual(restoredEvent.source, event.source)
            XCTAssertEqual(restoredEvent.uuid, event.uuid)
        }
    }
}

// MARK: - Encrypting / Decrypting events using public / private keys

extension StoreUpdateEventTests {
    func testThatItEncryptsEventIfThePublicKeyIsNotNil() throws {
        // given
        try eventMOC.performGroupedAndWait { _ in
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            // when
            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2, publicKey: self.publicKey) {
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
                XCTAssertNotNil(storedEvent.payload)

                #if targetEnvironment(simulator) && swift(>=5.4)
                if #available(iOS 15, *) {
                    XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
                }
                #endif

                XCTAssertTrue(storedEvent.isEncrypted)

                guard let privateKey = self.encryptionKeys?.privateKey else {
                    XCTFail("private key not found")
                    return
                }

                let decryptedData = SecKeyCreateDecryptedData(privateKey,
                                                              .eciesEncryptionCofactorX963SHA256AESGCM,
                                                              storedEvent.payload![StoredUpdateEvent.encryptedPayloadKey] as! CFData,
                                                              nil)
                let payload: NSDictionary = try JSONSerialization.jsonObject(with: decryptedData! as Data, options: []) as! NSDictionary
                XCTAssertEqual(payload, event.payload as NSDictionary)

            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItDoesNotEncryptEventIfThePublicKeyIsNil() throws {
        // given
        publicKey = nil

        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            // when
            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2, publicKey: self.publicKey) {
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
                XCTAssertNotNil(storedEvent.payload)
                XCTAssertFalse(storedEvent.isEncrypted)
            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItDecryptsAndConvertsStoreEventToTheUpdateEventIfThePrivateKeyIsNotNil() throws {
        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2, publicKey: self.publicKey) {
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
                XCTAssertNotNil(storedEvent.payload)
                #if targetEnvironment(simulator) && swift(>=5.4)
                if #available(iOS 15, *) {
                    XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
                }
                #endif
                XCTAssertTrue(storedEvent.isEncrypted)

                // when
                let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents([storedEvent], encryptionKeys: self.encryptionKeys)

                // then
                XCTAssertEqual(convertedEvents.first!.debugInformation, event.debugInformation)
                XCTAssertEqual(convertedEvents.first!.payload as NSDictionary, event.payload as NSDictionary)
                XCTAssertEqual(convertedEvents.first!.isTransient, event.isTransient)
                XCTAssertEqual(convertedEvents.first!.source, event.source)
                XCTAssertEqual(convertedEvents.first!.uuid?.transportString(), event.uuid?.transportString())

            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItConvertsStoreEventToTheUpdateEventIfThePrivateKeyIsNil() throws {
        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2, publicKey: nil) {
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
                XCTAssertNotNil(storedEvent.payload)
                XCTAssertFalse(storedEvent.isEncrypted)

                // when
                let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents([storedEvent], encryptionKeys: nil)

                // then
                XCTAssertEqual(convertedEvents.first!.debugInformation, event.debugInformation)
                XCTAssertEqual(convertedEvents.first!.payload as NSDictionary, event.payload as NSDictionary)
                XCTAssertEqual(convertedEvents.first!.isTransient, event.isTransient)
                XCTAssertEqual(convertedEvents.first!.source, event.source)
                XCTAssertEqual(convertedEvents.first!.uuid?.transportString(), event.uuid?.transportString())

            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItCanNotConvertEncryptedStoredEventWithoutPrivateKey() throws {
        // given
        self.eventMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let payload = self.payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
            event.appendDebugInformation("Highly informative description")

            if let storedEvent = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: 2, publicKey: self.publicKey) {
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
                XCTAssertNotNil(storedEvent.payload)
                #if targetEnvironment(simulator) && swift(>=5.4)
                if #available(iOS 15, *) {
                    XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
                }
                #endif
                XCTAssertTrue(storedEvent.isEncrypted)

                // when
                let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents([storedEvent], encryptionKeys: nil)

                // then
                XCTAssertTrue(convertedEvents.isEmpty)
            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }
}
