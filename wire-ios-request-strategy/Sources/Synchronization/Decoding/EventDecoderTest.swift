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

public enum EventConversation {
    static let add = "conversation.message-add"
    static let addClientMessage = "conversation.client-message-add"
    static let addOTRMessage = "conversation.otr-message-add"
    static let addAsset = "conversation.asset-add"
    static let addOTRAsset = "conversation.otr-asset-add"
}

class EventDecoderTest: MessagingTestBase {

    var sut: EventDecoder!

    override func setUp() {
        super.setUp()
        sut = EventDecoder(eventMOC: eventMOC, syncMOC: syncMOC)

        syncMOC.performGroupedBlockAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.accountIdentifier
            let selfConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            selfConversation.remoteIdentifier = self.accountIdentifier
            selfConversation.conversationType = .self
        }
    }

    override func tearDown() {
        EventDecoder.testingBatchSize = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - Processing events
extension EventDecoderTest {

    func testThatItProcessesEvents() {

        var didCallBlock = false

        syncMOC.performGroupedBlock {
            // given
            let event = self.eventStreamEvent()
            self.sut.decryptAndStoreEvents([event])

            // when
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(event))
                didCallBlock = true
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessesEventsWithEncryptionKeys() {

        var didCallBlock = false
        let account = Account(userName: "John Doe", userIdentifier: UUID())
        let encryptionKeys = try? EncryptionKeys.createKeys(for: account)

        syncMOC.performGroupedBlock {
            // given
            let event = self.eventStreamEvent()
            self.sut.decryptAndStoreEvents([event])

            // when
            self.sut.processStoredEvents(with: encryptionKeys) { (events) in
                XCTAssertTrue(events.contains(event))
                didCallBlock = true
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessesPreviouslyStoredEventsFirst() {

        EventDecoder.testingBatchSize = 1
        var callCount = 0

        syncMOC.performGroupedBlock {
            // given
            let event1 = self.eventStreamEvent()
            let event2 = self.eventStreamEvent()
            self.sut.decryptAndStoreEvents([event1])

            // when
            self.sut.decryptAndStoreEvents([event2])
            self.sut.processStoredEvents { (events) in
                if callCount == 0 {
                    XCTAssertTrue(events.contains(event1))
                } else if callCount == 1 {
                    XCTAssertTrue(events.contains(event2))
                } else {
                    XCTFail("called too often")
                }
                callCount += 1
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(callCount, 2)
    }

    func testThatItProcessesInBatches() {

        EventDecoder.testingBatchSize = 2
        var callCount = 0

        syncMOC.performGroupedBlock {

            // given
            let event1 = self.eventStreamEvent()
            let event2 = self.eventStreamEvent()
            let event3 = self.eventStreamEvent()
            let event4 = self.eventStreamEvent()

            self.sut.decryptAndStoreEvents([event1, event2, event3, event4])

            // when
            self.sut.processStoredEvents { (events) in
                if callCount == 0 {
                    XCTAssertTrue(events.contains(event1))
                    XCTAssertTrue(events.contains(event2))
                } else if callCount == 1 {
                    XCTAssertTrue(events.contains(event3))
                    XCTAssertTrue(events.contains(event4))
                } else {
                    XCTFail("called too often")
                }
                callCount += 1
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(callCount, 2)
    }

    func testThatItDoesNotProcessTheSameEventsTwiceWhenCalledSuccessively() {

        EventDecoder.testingBatchSize = 2

        syncMOC.performGroupedBlock {

            // given
            let event1 = self.eventStreamEvent()
            let event2 = self.eventStreamEvent()
            let event3 = self.eventStreamEvent()
            let event4 = self.eventStreamEvent()

            self.sut.decryptAndStoreEvents([event1, event2])

            self.sut.processStoredEvents(with: nil) { (events) in
                XCTAssert(events.contains(event1))
                XCTAssert(events.contains(event2))
            }

            self.insert([event3, event4], startIndex: 1)

            // when
            self.sut.processStoredEvents(with: nil) { (events) in
                XCTAssertFalse(events.contains(event1))
                XCTAssertFalse(events.contains(event2))
                XCTAssertTrue(events.contains(event3))
                XCTAssertTrue(events.contains(event4))
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItDoesNotProcessEventsFromOtherUsersArrivingInSelfConversation() {
        var didCallBlock = false

        syncMOC.performGroupedBlock {
            // given
            let event1 = self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: GenericMessage(content: Calling(content: "123")))
            let event2 = self.eventStreamEvent()

            self.insert([event1, event2])

            // when
            self.sut.processStoredEvents(with: nil) { (events) in
                XCTAssertEqual(events, [event2])
                didCallBlock = true
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItDoesProcessEventsFromSelfUserArrivingInSelfConversation() {
        var didCallBlock = false

        syncMOC.performGroupedBlock {
            // given
            let callingBessage = GenericMessage(content: Calling(content: "123"))

            let event1 = self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: callingBessage, from: ZMUser.selfUser(in: self.syncMOC))
            let event2 = self.eventStreamEvent()

            self.insert([event1, event2])

            // when
            self.sut.processStoredEvents(with: nil) { (events) in
                XCTAssertEqual(events, [event1, event2])
                didCallBlock = true
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessAvailabilityEventsFromOtherUsersArrivingInSelfConversation() {
        var didCallBlock = false

        syncMOC.performGroupedBlock {
            // given
            let event1 = self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: GenericMessage(content: WireProtos.Availability(.away)))
            let event2 = self.eventStreamEvent()

            self.insert([event1, event2])

            // when
            self.sut.processStoredEvents(with: nil) { (events) in
                XCTAssertEqual(events, [event1, event2])
                didCallBlock = true
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

}

// MARK: - Already seen events
extension EventDecoderTest {

    func testThatItProcessesEventsWithDifferentUUIDWhenThroughPushEventsFirst() {

        syncMOC.performGroupedBlockAndWait {

            // given
            let pushProcessed = self.expectation(description: "Push event processed")
            let pushEvent = self.pushNotificationEvent()
            let streamEvent = self.eventStreamEvent()

            // when
            self.sut.decryptAndStoreEvents([pushEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(pushEvent))
                pushProcessed.fulfill()
            }

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // and when
            let streamProcessed = self.expectation(description: "Stream event processed")
            self.sut.decryptAndStoreEvents([streamEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(streamEvent))
                streamProcessed.fulfill()
            }

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItDoesNotProcessesEventsWithSameUUIDWhenThroughPushEventsFirst() {

        syncMOC.performGroupedBlockAndWait {

            // given
            let pushProcessed = self.expectation(description: "Push event processed")
            let uuid = UUID.create()
            let pushEvent = self.pushNotificationEvent(uuid: uuid)
            let streamEvent = self.eventStreamEvent(uuid: uuid)

            // when
            self.sut.decryptAndStoreEvents([pushEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(pushEvent))
                pushProcessed.fulfill()
            }

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // and when
            let streamProcessed = self.expectation(description: "Stream event not processed")

            self.sut.decryptAndStoreEvents([streamEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.isEmpty)
                streamProcessed.fulfill()
            }

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItProcessesEventsWithSameUUIDWhenThroughPushEventsFirstAndDiscarding() {

        syncMOC.performGroupedBlockAndWait {

            // given
            let pushProcessed = self.expectation(description: "Push event processed")
            let uuid = UUID.create()
            let pushEvent = self.pushNotificationEvent(uuid: uuid)
            let streamEvent = self.eventStreamEvent(uuid: uuid)

            // when

            self.sut.decryptAndStoreEvents([pushEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(pushEvent))
                pushProcessed.fulfill()
            }
            self.sut.discardListOfAlreadyReceivedPushEventIDs()

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // and when
            let streamProcessed = self.expectation(description: "Stream event processed")

            self.sut.decryptAndStoreEvents([streamEvent])
            self.sut.processStoredEvents { (events) in
                XCTAssertTrue(events.contains(streamEvent))
                streamProcessed.fulfill()
            }

            // then
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

}

// MARK: - Helpers
extension EventDecoderTest {
    /// Returns an event from the notification stream
    func eventStreamEvent(uuid: UUID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let payload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid ?? UUID.create())!
    }

    func eventStreamEvent(conversation: ZMConversation, genericMessage: GenericMessage, from user: ZMUser? = nil, uuid: UUID? = nil) -> ZMUpdateEvent {
        var payload: ZMTransportData
        if let user = user {
            payload = payloadForMessage(in: conversation, type: EventConversation.addOTRMessage, data: ["text": try? genericMessage.serializedData().base64EncodedString()], time: nil, from: user)!
        } else {
            payload = payloadForMessage(in: conversation, type: EventConversation.addOTRMessage, data: ["text": try? genericMessage.serializedData().base64EncodedString()])!
        }

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid ?? UUID.create())!
    }

    /// Returns an event from a push notification
    func pushNotificationEvent(uuid: UUID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let innerPayload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        let payload = [
            "id": (uuid ?? UUID.create()).transportString(),
            "payload": [innerPayload]
        ] as [String: Any]
        let events = ZMUpdateEvent.eventsArray(from: payload as NSDictionary, source: .pushNotification)
        return events!.first!
    }

    func insert(_ events: [ZMUpdateEvent], startIndex: Int64 = 0) {
        eventMOC.performGroupedBlockAndWait {
            events.enumerated().forEach { index, event  in
                _ = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: Int64(startIndex) + Int64(index))
            }

            XCTAssert(self.eventMOC.saveOrRollback())
        }
    }

}
