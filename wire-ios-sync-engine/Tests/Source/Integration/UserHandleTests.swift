//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireSyncEngine
import WireMockTransport

class UserHandleTests: IntegrationTest {

    var userProfileStatusObserver: TestUserProfileUpdateObserver!

    var observerToken: Any?

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()

        XCTAssertTrue(login())

        self.userProfileStatusObserver = TestUserProfileUpdateObserver()
        self.observerToken = self.userSession?.userProfile?.add(observer: self.userProfileStatusObserver)
    }

    override func tearDown() {
        self.observerToken = nil
        self.userProfileStatusObserver = nil
        super.tearDown()
    }

    func testThatItCanCheckThatAHandleIsAvailable() {

        // GIVEN
        let handle = "Oscar"

        // WHEN
        self.userSession?.userProfile?.requestCheckHandleAvailability(handle: handle)

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = self.userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didCheckAvailabilityOfHandle(let _handle, let available):
            XCTAssertEqual(handle, _handle)
            XCTAssertTrue(available)
        default:
            XCTFail()
        }
    }

    func testThatItCanCheckThatAHandleIsNotAvailable() {

        // GIVEN
        let handle = "Oscar"

        self.mockTransportSession.performRemoteChanges { (_) in
            self.user1.handle = handle
        }

        // WHEN
        self.userSession?.userProfile?.requestCheckHandleAvailability(handle: handle)

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = self.userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didCheckAvailabilityOfHandle(let _handle, let available):
            XCTAssertEqual(handle, _handle)
            XCTAssertFalse(available)
        default:
            XCTFail()
        }
    }

    func testThatItCanSetTheHandle() {

        // GIVEN
        let handle = "Evelyn"

        // WHEN
        self.userSession?.userProfile?.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = self.userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didSetHandle:
            break
        default:
            XCTFail()
            return
        }

        let selfUser = ZMUser.selfUser(inUserSession: self.userSession!)
        XCTAssertEqual(selfUser.handle, handle)

        self.mockTransportSession.performRemoteChanges { _ in
            XCTAssertEqual(self.selfUser.handle, handle)
        }
    }

    func testThatItIsNotifiedWhenFailsToSetTheHandleBecauseItExists() {

        // GIVEN
        let handle = "Evelyn"

        self.mockTransportSession.performRemoteChanges { (_) in
            self.user1.handle = handle
        }

        // WHEN
        self.userSession?.userProfile?.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = self.userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandleBecauseExisting:
            break
        default:
            XCTFail()
            return
        }
    }

    func testThatItIsNotifiedWhenFailsToSetTheHandle() {

        // GIVEN
        let handle = "Evelyn"

        self.mockTransportSession.responseGeneratorBlock = { req in
            if req.path == "/self/handle" {
                return ZMTransportResponse(payload: nil, httpStatus: 400, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            }
            return nil
        }

        // WHEN
        self.userSession?.userProfile?.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(self.userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = self.userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandle:
            break
        default:
            XCTFail()
            return
        }
    }
}
