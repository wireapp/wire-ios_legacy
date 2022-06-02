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

final class NotificationsTrackerTests: MessagingTestBase {

    var sut: NotificationsTracker!
    var mockAnalytics: MockAnalytics!

    override func setUp() {
        super.setUp()
        mockAnalytics = MockAnalytics()
        sut = NotificationsTracker(analytics: mockAnalytics)
    }

    override func tearDown() {
        sut = nil
        mockAnalytics = nil
        super.tearDown()
    }

    func testThatItDoesNotDispatchEventWithNoAttributesSet() {
        // WHEN
        sut.dispatchEvent()

        // THEN
        XCTAssertEqual(mockAnalytics.taggedEvents.count, 0)
        XCTAssertEqual(mockAnalytics.taggedEventsWithAttributes.count, 0)
    }

    func testThatItDoesIncrementCounters_started() {
        // WHEN
        sut.registerReceivedPush()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.startedProcessing.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 1)
    }

    func testThatItDoesIncrementCounters_fetching() {
        // WHEN
        sut.registerStartStreamFetching()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.startedFetchingStream.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 1)
    }

    func testThatItDoesIncrementCounters_completedFetching() {
        // WHEN
        sut.registerFinishStreamFetching()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.finishedFetchingStream.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 1)
    }

    func testThatItDoesIncrementCounters_finished() {
        // WHEN
        sut.registerNotificationProcessingCompleted()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.finishedProcessing.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 1)
    }

    func testThatItDoesIncrementCounters_aborted() {
        // WHEN
        sut.registerProcessingAborted()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.abortedProcessing.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 1)
    }

    func testThatItIncrementsCounterTwice() {
        // WHEN
        sut.registerReceivedPush()
        sut.registerReceivedPush()

        // THEN
        let attributes = mockAnalytics.persistedAttributes(for: sut.eventName)
        let identifier = NotificationsTracker.Attributes.startedProcessing.identifier
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes?[identifier] as? Int, 2)
    }

    func testThatItDispatchesPersistedAttributes() {
        // GIVEN
        sut.registerReceivedPush()
        sut.registerStartStreamFetching()
        sut.registerFinishStreamFetching()
        sut.registerNotificationProcessingCompleted()
        sut.registerProcessingAborted()

        // WHEN
        sut.dispatchEvent()

        // THEN
        let payload: [String: NSObject] = [
            NotificationsTracker.Attributes.startedProcessing.identifier: 1 as NSObject,
            NotificationsTracker.Attributes.startedFetchingStream.identifier: 1 as NSObject,
            NotificationsTracker.Attributes.finishedFetchingStream.identifier: 1 as NSObject,
            NotificationsTracker.Attributes.finishedProcessing.identifier: 1 as NSObject,
            NotificationsTracker.Attributes.abortedProcessing.identifier: 1 as NSObject
        ]
        guard let attributes = mockAnalytics.taggedEventsWithAttributes.first?.attributes else {
            XCTFail("Attributes are missing"); return
        }
        XCTAssertEqual(payload, attributes)
    }
}
