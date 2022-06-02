//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class ApplicationStatusDirectoryTests: MessagingTest {

    var sut: ApplicationStatusDirectory!

    override func setUp() {
        super.setUp()

        let cookieStorage = ZMPersistentCookieStorage()
        let mockApplication = ApplicationMock()

        sut = ApplicationStatusDirectory(withManagedObjectContext: syncMOC, cookieStorage: cookieStorage, requestCancellation: self, application: mockApplication, syncStateDelegate: self)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testThatOperationStatusIsUpdatedWhenCallStarts() {
        // given
        let note = NotificationInContext(name: CallStateObserver.CallInProgressNotification, context: uiMOC.notificationContext, userInfo: [CallStateObserver.CallInProgressKey: true ])

        // when
        note.post()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.operationStatus.hasOngoingCall)
    }

    func testThatOperationStatusIsUpdatedWhenCallEnds() {
        // given
        sut.operationStatus.hasOngoingCall = true
        let note = NotificationInContext(name: CallStateObserver.CallInProgressNotification, context: uiMOC.notificationContext, userInfo: [CallStateObserver.CallInProgressKey: false ])

        // when
        note.post()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.operationStatus.hasOngoingCall)
    }

}

extension ApplicationStatusDirectoryTests: ZMRequestCancellation {

    func cancelTask(with taskIdentifier: ZMTaskIdentifier) {
        // no-op
    }

}

extension ApplicationStatusDirectoryTests: ZMSyncStateDelegate {

    func didStartSlowSync() {
        // no-op
    }

    func didFinishSlowSync() {
        // no-op
    }

    func didStartQuickSync() {
        // no-op
    }

    func didFinishQuickSync() {
        // no-op
    }

    func didRegisterSelfUserClient(_ userClient: UserClient!) {
        // nop
    }

    func didFailToRegisterSelfUserClient(error: Error!) {
        // nop
    }

    func didDeleteSelfUserClient(error: Error!) {
        // nop
    }}
