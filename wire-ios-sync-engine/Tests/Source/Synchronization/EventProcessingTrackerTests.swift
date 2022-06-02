//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class EventProcessingTrackerTests: XCTestCase {

    var sut: EventProcessingTracker!

    override func setUp() {
        super.setUp()
        sut = EventProcessingTracker()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItIncrementCounters_savesPerformed_debugDescription() {
        // given
        XCTAssertEqual(sut.debugDescription, "Optional([:])")

        // when
        sut.registerSavePerformed()

        // then
        XCTAssertEqual(sut.debugDescription, "Optional([\"event_savesPerformed\": 1])")
    }

    func testThatItIncrementCounters_savesPerformed() {
        // when
        sut.registerSavePerformed()

        // then
        verifyIncrement(attribute: .savesPerformed)
    }

    func testThatItIncrementCounters_processedEvents() {
        // when
        sut.registerEventProcessed()

        // then
        verifyIncrement(attribute: .processedEvents)
    }

    func testThatItIncrementCounters_dataUpdatePerformed() {
        // when
        sut.registerDataUpdatePerformed()

        // then
        verifyIncrement(attribute: .dataUpdatePerformed)
    }

    func testThatItIncrementCounters_dataDeletionPerformed() {
        // when
        sut.registerDataDeletionPerformed()

        // then
        verifyIncrement(attribute: .dataDeletionPerformed)
    }

    func testThatItIncrementCounters_dataInsertionPerformed() {
        // when
        sut.registerDataInsertionPerformed()

        // then
        verifyIncrement(attribute: .dataInsertionPerformed)
    }

    func testMultipleIncrements() {
        // when
        sut.registerSavePerformed()
        sut.registerEventProcessed()
        sut.registerDataUpdatePerformed()
        sut.registerDataDeletionPerformed()
        sut.registerDataInsertionPerformed()

        // then
        verifyIncrement(attribute: .dataInsertionPerformed)
        verifyIncrement(attribute: .dataDeletionPerformed)
        verifyIncrement(attribute: .dataUpdatePerformed)
        verifyIncrement(attribute: .processedEvents)
        verifyIncrement(attribute: .savesPerformed)
    }

    func verifyIncrement(attribute: EventProcessingTracker.Attributes) {
        let attributes = sut.persistedAttributes(for: sut.eventName)
        XCTAssertNotNil(attributes)
        XCTAssertEqual(attributes[attribute.identifier] as? Int, 1)
    }

}
