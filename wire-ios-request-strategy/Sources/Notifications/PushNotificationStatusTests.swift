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
@testable import WireRequestStrategy

@objc class FakeGroupQueue: NSObject, ZMSGroupQueue {

    var dispatchGroup: ZMSDispatchGroup! {
        return nil
    }

    func performGroupedBlock(_ block : @escaping () -> Void) {
        block()
    }

}

// MARK: - Tests

class PushNotificationStatusTests: MessagingTestBase {

    var sut: PushNotificationStatus!

    override func setUp() {
        super.setUp()

        sut = PushNotificationStatus(managedObjectContext: syncMOC)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatStatusIsInProgressWhenAddingEventIdToFetch() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) { }
        }

        // then
        XCTAssertTrue(sut.hasEventsToFetch)
    }

    func testThatStatusIsInProgressWhenNotAllEventsIdsHaveBeenFetched() {
        // given
        let eventId1 = UUID.timeBasedUUID() as UUID
        let eventId2 = UUID.timeBasedUUID() as UUID

        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId1) { }
            self.sut.fetch(eventId: eventId2) { }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [eventId1], lastEventId: eventId1, finished: true)
        }

        // then
        XCTAssertTrue(sut.hasEventsToFetch)
    }

    func testThatStatusIsDoneAfterEventIdIsFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) { }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [eventId], lastEventId: eventId, finished: true)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
    }

    func testThatStatusIsDoneAfterEventIdIsFetchedEvenIfMoreEventsWillBeFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) { }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [eventId], lastEventId: eventId, finished: false)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
    }

    func testThatStatusIsDoneAfterEventIdIsFetchedEvenIfNoEventsWereDownloaded() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) { }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [], lastEventId: eventId, finished: true)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
    }

    func testThatStatusIsDoneIfEventsCantBeFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) { }
        }

        // when
        sut.didFailToFetchEvents()

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
    }

    func testThatCompletionHandlerIsNotCalledIfAllEventsHaveNotBeenFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID

        // expect
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) {
                XCTFail("Didn't expect completion handler to be called")
            }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [eventId], lastEventId: eventId, finished: false)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
    }

    func testThatCompletionHandlerIsCalledAfterAllEventsHaveBeenFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        let expectation = self.expectation(description: "completion handler was called")

        // expect
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) {
                expectation.fulfill()
            }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [eventId], lastEventId: eventId, finished: true)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatCompletionHandlerIsCalledEvenIfNoEventsWereDownloaded() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        let expectation = self.expectation(description: "completion handler was called")

        // expect
        syncMOC.performGroupedBlockAndWait {
            self.sut.fetch(eventId: eventId) {
                expectation.fulfill()
            }
        }

        // when
        syncMOC.performGroupedBlockAndWait {
            self.sut.didFetch(eventIds: [], lastEventId: eventId, finished: true)
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatCompletionHandlerIsCalledImmediatelyIfEventHasAlreadyBeenFetched() {
        // given
        let eventId = UUID.timeBasedUUID() as UUID
        let expectation = self.expectation(description: "completion handler was called")
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_lastNotificationID = eventId

            // when
            self.sut.fetch(eventId: eventId) {
                expectation.fulfill()
            }
        }

        // then
        XCTAssertFalse(sut.hasEventsToFetch)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
