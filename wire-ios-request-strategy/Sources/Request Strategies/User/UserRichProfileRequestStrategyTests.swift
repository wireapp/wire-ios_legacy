////
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
@testable import WireRequestStrategy

class UserRichProfileRequestStrategyTests: MessagingTestBase {

    var applicationStatus: MockApplicationStatus!
    var sut: UserRichProfileRequestStrategy!

    override func setUp() {
        super.setUp()

        self.syncMOC.performGroupedAndWait { moc in
            self.applicationStatus = MockApplicationStatus()
            self.applicationStatus.mockSynchronizationState = .online
            self.sut = UserRichProfileRequestStrategy(withManagedObjectContext: moc, applicationStatus: self.applicationStatus)
        }
    }

    override func tearDown() {
        sut = nil
        applicationStatus = nil

        super.tearDown()
    }

    func testThatItGeneratesARequestWhenSettingIsModified() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let userID = UUID()
            let user = ZMUser.fetchOrCreate(with: userID, domain: nil, in: self.syncMOC)
            user.needsRichProfileUpdate = true
            self.sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: user)) })

            // when
            guard let request = self.sut.nextRequest(for: .v0) else { XCTFail("Request is nil"); return }

            // then
            XCTAssertEqual(request.path, "/users/\(userID)/rich-info")
            XCTAssertEqual(request.method, .methodGET)
        }
    }

    func testThatItParsesAResponse() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let userID = UUID()
            let user = ZMUser.fetchOrCreate(with: userID, domain: nil, in: self.syncMOC)
            user.needsRichProfileUpdate = true
            self.sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: user)) })
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)

            // when
            let type = "some"
            let value = "value"
            let payload = [
                "fields": [
                    ["type": type, "value": value]
                ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            self.sut.update(user, with: response, downstreamSync: nil)

            // then
            XCTAssertFalse(user.needsRichProfileUpdate)
            XCTAssertEqual(user.richProfile, [UserRichProfileField(type: type, value: value)])
        }
    }

    func testThatItResetsTheFlagOnError() {
        self.syncMOC.performGroupedAndWait { _ in
            // given
            let userID = UUID()
            let user = ZMUser.fetchOrCreate(with: userID, domain: nil, in: self.syncMOC)
            user.needsRichProfileUpdate = true
            self.sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: user)) })
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)

            // when
            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            self.sut.delete(user, with: response, downstreamSync: nil)

            // then
            XCTAssertFalse(user.needsRichProfileUpdate)
        }
    }

}
