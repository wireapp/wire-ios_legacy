//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireTesting

@testable import WireSyncEngine

class CallEventStatusTests: ZMTBaseTest {

    var sut: CallEventStatus!

    override func setUp() {
        super.setUp()

        sut = CallEventStatus()
        sut.eventProcessingTimoutInterval = 0.1
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatWaitForCallEventCompleteImmediatelyIfNoCallEventsAreScheduled() {

        // expect
        let processingDidComplete = expectation(description: "processingDidComplete")

        // when
        let hasUnprocessedCallEvents = sut.waitForCallEventProcessingToComplete {
            processingDidComplete.fulfill()
        }

        XCTAssertFalse(hasUnprocessedCallEvents)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatWaitForCallEventCompleteWhenScheduledCallEventIsProcessed() {

        // given
        sut.scheduledCallEventForProcessing()

        // expect
        let processingDidComplete = expectation(description: "processingDidComplete")
        let hasUnprocessedCallEvents = sut.waitForCallEventProcessingToComplete {
            processingDidComplete.fulfill()
        }

        // when
        sut.finishedProcessingCallEvent()
        XCTAssertTrue(hasUnprocessedCallEvents)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatWaitForCallEventCompleteWhenScheduledCallEventIsProcessedWhenTimeoutTimerIsStillRunning() {

        // given
        sut.scheduledCallEventForProcessing()
        sut.finishedProcessingCallEvent()

        // expect
        let processingDidComplete = expectation(description: "processingDidComplete")
        let hasUnprocessedCallEvents = sut.waitForCallEventProcessingToComplete {
            processingDidComplete.fulfill()
        }

        // when
        XCTAssertTrue(hasUnprocessedCallEvents)
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
