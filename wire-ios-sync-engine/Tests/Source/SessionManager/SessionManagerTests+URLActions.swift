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

import Foundation
import WireTesting
@testable import WireSyncEngine

class SessionManagerTests_URLActions: IntegrationTest {

    var presentationDelegate: MockPresentationDelegate!

    override func setUp() {
        super.setUp()

        presentationDelegate = MockPresentationDelegate()
        sessionManager?.presentationDelegate = presentationDelegate
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    override func tearDown() {
        presentationDelegate = nil
        super.tearDown()
    }

    override var useInMemoryStore: Bool {
        return false
    }

    // MARK: Tests

    func testThatItIgnoresNonWireURL() throws {
        // when
        let canOpenURL = try sessionManager?.openURL(URL(string: "https://google.com")!)

        // then
        XCTAssertEqual(canOpenURL, false)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 0)
    }

    func testThatItAsksDelegateIfURLActionShouldBePerformed() throws {
        // given
        presentationDelegate?.isPerformingActions = false
        let url = URL(string: "wire://connect?service=2e1863a6-4a12-11e8-842f-0ed5f89f718b&provider=3879b1ec-4a12-11e8-842f-0ed5f89f718b")!
        XCTAssertTrue(login())

        // when
        let canOpenURL = try sessionManager?.openURL(url)

        // then
        let expectedUserData = ServiceUserData(provider: UUID(uuidString: "3879b1ec-4a12-11e8-842f-0ed5f89f718b")!,
                                               service: UUID(uuidString: "2e1863a6-4a12-11e8-842f-0ed5f89f718b")!)
        XCTAssertEqual(canOpenURL, true)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.first, .connectBot(serviceUser: expectedUserData))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItThrowsAnErrorWhileProcessingAuthenticatedURLAction_WhenLoggedOut() throws {
        // given
        presentationDelegate?.isPerformingActions = false
        let url = URL(string: "wire://connect?service=2e1863a6-4a12-11e8-842f-0ed5f89f718b&provider=3879b1ec-4a12-11e8-842f-0ed5f89f718b")!

        // when then
        XCTAssertThrowsError(try sessionManager?.openURL(url)) { (error) in
            XCTAssertEqual(error as? DeepLinkRequestError, .notLoggedIn)
        }
    }

    func testThatItDelaysURLActionProcessing_UntilUserSessionBecomesAvailable() throws {
        // given: user session is not availablle but we are still authenticated
        XCTAssertTrue(login())
        sessionManager?.logoutCurrentSession(deleteCookie: false)
        presentationDelegate?.isPerformingActions = false

        // when
        let url = URL(string: "wire://connect?service=2e1863a6-4a12-11e8-842f-0ed5f89f718b&provider=3879b1ec-4a12-11e8-842f-0ed5f89f718b")!
        let canOpenURL = try sessionManager?.openURL(url)
        XCTAssertEqual(canOpenURL, true)

        // then: action should get postponed
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 0)

        // when
        XCTAssertTrue(login())

        // then: action should get resumed
        let expectedUserData = ServiceUserData(provider: UUID(uuidString: "3879b1ec-4a12-11e8-842f-0ed5f89f718b")!,
                                               service: UUID(uuidString: "2e1863a6-4a12-11e8-842f-0ed5f89f718b")!)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.first, .connectBot(serviceUser: expectedUserData))
    }

    func testThatItDelaysURLActionProcessing_UntilUserSessionBecomesUnlocked() throws {
        // given: user session is availablle but it is locked
        XCTAssertTrue(login())

        let appLock = MockAppLock()
        appLock.isLocked = true
        userSession!.appLockController = appLock
        XCTAssertTrue(userSession!.isLocked)

        presentationDelegate?.isPerformingActions = false

        // when
        let url = URL(string: "wire://connect?service=2e1863a6-4a12-11e8-842f-0ed5f89f718b&provider=3879b1ec-4a12-11e8-842f-0ed5f89f718b")!
        let canOpenURL = try sessionManager?.openURL(url)
        XCTAssertEqual(canOpenURL, true)

        // then: action should get postponed
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 0)

        // when
        appLock.isLocked = false
        userSession!.delegate?.userSessionDidUnlock(userSession!)

        // then: action should get resumed
        let expectedUserData = ServiceUserData(provider: UUID(uuidString: "3879b1ec-4a12-11e8-842f-0ed5f89f718b")!,
                                               service: UUID(uuidString: "2e1863a6-4a12-11e8-842f-0ed5f89f718b")!)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.shouldPerformActionCalls.first, .connectBot(serviceUser: expectedUserData))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}
