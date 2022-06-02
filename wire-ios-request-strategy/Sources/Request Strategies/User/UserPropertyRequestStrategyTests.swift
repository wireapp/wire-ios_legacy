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
@testable import WireRequestStrategy

class UserPropertyRequestStrategyTests: MessagingTestBase {

    var applicationStatus: MockApplicationStatus!
    var sut: UserPropertyRequestStrategy!

    override func setUp() {
        super.setUp()

        self.syncMOC.performGroupedAndWait { moc in
            self.applicationStatus = MockApplicationStatus()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = UserPropertyRequestStrategy(withManagedObjectContext: moc, applicationStatus: self.applicationStatus)
        }
    }

    override func tearDown() {
        sut = nil
        applicationStatus = nil

        super.tearDown()
    }

    func testThatItGeneratesARequestWhenSettingIsModified() {
        self.syncMOC.performGroupedAndWait { moc in
            // given
            let selfUser = ZMUser.selfUser(in: moc)
            selfUser.needsToBeUpdatedFromBackend = false
            selfUser.readReceiptsEnabled = true
            self.sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: selfUser)) })

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)
        }
    }

    func testThatItUpdatesPropertyFromUpdateEvent() {
        self.syncMOC.performGroupedAndWait { moc in
            // given
            let selfUser = ZMUser.selfUser(in: moc)
            selfUser.needsPropertiesUpdate = false

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
                "type": "user.properties-set",
                "key": "WIRE_RECEIPT_MODE",
                "value": 1] as ZMTransportData), uuid: nil)!

            // when
            self.sut.processEvents([updateEvent], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertTrue(selfUser.readReceiptsEnabled)
            XCTAssertTrue(selfUser.readReceiptsEnabledChangedRemotely)
        }
    }

    func testThatItUpdatesPropertyFromUpdateEvent_false() {
        self.syncMOC.performGroupedAndWait { moc in
            // given
            let selfUser = ZMUser.selfUser(in: moc)
            selfUser.needsPropertiesUpdate = false
            selfUser.readReceiptsEnabled = true

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
                "type": "user.properties-set",
                "key": "WIRE_RECEIPT_MODE",
                "value": 0] as ZMTransportData), uuid: nil)!

            // when
            self.sut.processEvents([updateEvent], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertFalse(selfUser.readReceiptsEnabled)
            XCTAssertTrue(selfUser.readReceiptsEnabledChangedRemotely)
        }
    }

    func testThatItUpdatesPropertyFromUpdateEvent_delete() {
        self.syncMOC.performGroupedAndWait { moc in

            // given
            let selfUser = ZMUser.selfUser(in: moc)
            selfUser.needsPropertiesUpdate = false
            selfUser.readReceiptsEnabled = true

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
                "type": "user.properties-delete",
                "key": "WIRE_RECEIPT_MODE"] as ZMTransportData), uuid: nil)!

            // when
            self.sut.processEvents([updateEvent], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertFalse(selfUser.readReceiptsEnabled)
            XCTAssertTrue(selfUser.readReceiptsEnabledChangedRemotely)
        }
    }
}

// MARK: - Downstream sync
extension UserPropertyRequestStrategyTests {
    func testThatItIsFetchingPropertyValue() {
        self.syncMOC.performGroupedAndWait { moc in
            // given
            let selfUser = ZMUser.selfUser(in: moc)

            // when
            let request = self.sut.nextRequestIfAllowed(for: .v0)

            XCTAssertNotNil(request)
            XCTAssertEqual(request!.method, .methodGET)
            XCTAssertEqual(request!.path, "properties/WIRE_RECEIPT_MODE")

            let response = ZMTransportResponse(payload: "1" as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            self.sut.didReceive(response, forSingleRequest: self.sut.downstreamSync)

            // then
            XCTAssertFalse(selfUser.needsPropertiesUpdate)
            XCTAssertTrue(selfUser.readReceiptsEnabled)
            XCTAssertFalse(selfUser.readReceiptsEnabledChangedRemotely)
        }
    }

    func testThatItIsFetchingPropertyValue_404() {
        self.syncMOC.performGroupedAndWait { moc in
            // given
            let selfUser = ZMUser.selfUser(in: moc)

            // when
            let request = self.sut.nextRequestIfAllowed(for: .v0)

            XCTAssertNotNil(request)
            XCTAssertEqual(request!.method, .methodGET)
            XCTAssertEqual(request!.path, "properties/WIRE_RECEIPT_MODE")

            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

            self.sut.didReceive(response, forSingleRequest: self.sut.downstreamSync)

            // then
            XCTAssertFalse(selfUser.needsPropertiesUpdate)
            XCTAssertFalse(selfUser.readReceiptsEnabled)
            XCTAssertFalse(selfUser.readReceiptsEnabledChangedRemotely)
        }
    }
}
