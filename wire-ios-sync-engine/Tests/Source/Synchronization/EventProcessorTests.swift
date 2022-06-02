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

import XCTest
@testable import WireSyncEngine

class EventProcessorTests: MessagingTest {

    var sut: EventProcessor!
    var syncStatus: SyncStatus!
    var syncStateDelegate: ZMSyncStateDelegate!
    var eventProcessingTracker: EventProcessingTracker!
    var mockEventsConsumers: [MockEventConsumer]!

    override func setUp() {
        super.setUp()

        createSelfClient()
        syncMOC.zm_lastNotificationID = UUID() // simulate a completed slow sync

        mockEventsConsumers = [MockEventConsumer(), MockEventConsumer()]
        eventProcessingTracker = EventProcessingTracker()

        syncStateDelegate = MockSyncStateDelegate()

        syncStatus = SyncStatus(managedObjectContext: coreDataStack.syncContext,
                                syncStateDelegate: syncStateDelegate)

        sut = EventProcessor(storeProvider: coreDataStack,
                             syncStatus: syncStatus,
                             eventProcessingTracker: eventProcessingTracker)
        sut.eventConsumers = mockEventsConsumers
    }

    override func tearDown() {
        eventProcessingTracker = nil
        syncStateDelegate = nil
        syncStatus = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Helpers

    func completeQuickSync() {
        syncStatus.currentSyncPhase = .done
        syncStatus.pushChannelDidOpen()
        syncStatus.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
    }

    func createSampleEvents(conversationID: UUID  = UUID(), messageNonce: UUID = UUID()) -> [ZMUpdateEvent] {
        let payload1: [String: Any] = ["type": "conversation.member-join",
                                       "conversation": conversationID]
        let payload2: [String: Any] = ["type": "conversation.message-add",
                                        "data": ["content": "www.wire.com",
                                                 "nonce": messageNonce],
                                        "conversation": conversationID]

        let event1 = ZMUpdateEvent(fromEventStreamPayload: payload1 as ZMTransportData, uuid: nil)!
        let event2 = ZMUpdateEvent(fromEventStreamPayload: payload2 as ZMTransportData, uuid: nil)!

        return [event1, event2]
    }

    // MARK: - Tests

    func testThatEventsAreForwardedToAllEventConsumers_WhenProcessed() {
        // given
        let events = createSampleEvents()
        completeQuickSync()

        // when
        sut.storeAndProcessUpdateEvents(events, ignoreBuffer: false)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })
    }

    func testThatEventsAreBuffered_WhenSyncIsInProgress() {
        // given
        let events = createSampleEvents()

        // when
        sut.storeAndProcessUpdateEvents(events, ignoreBuffer: false)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertFalse(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertFalse(mockEventConsumer.processEventsCalled)
        })
    }

    func testThatItProcessBufferedEvents_WhenSyncCompletes() {
        // given
        let events = createSampleEvents()
        sut.storeAndProcessUpdateEvents(events, ignoreBuffer: false)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        completeQuickSync()
        _ = sut.processEventsIfReady()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })
    }

    func testThatEventsAreProcessedWhileInBackground_WhenSyncIsInProgress_And_IgnoreBufferIsTrue() {
        // given
        let events = createSampleEvents()

        // when
        sut.storeAndProcessUpdateEvents(events, ignoreBuffer: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertFalse(mockEventConsumer.processEventsCalled)
        })
    }

    func testThatItCreatesAFetchBatchRequestWithTheNoncesAndRemoteIdentifiers_RequestedByEventsConsumers() {
        // given
        let converationID = UUID()
        let messageNonce = UUID()
        let events = createSampleEvents(conversationID: converationID, messageNonce: messageNonce)

        // when
        let batchFetchRequest = sut.prefetchRequest(updateEvents: events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let conversationIdSet: NSSet = [converationID]
        let messageNonceSet: NSSet = [messageNonce]
        XCTAssertEqual(batchFetchRequest.remoteIdentifiersToFetch, conversationIdSet)
        XCTAssertEqual(batchFetchRequest.noncesToFetch, messageNonceSet)
    }

}
