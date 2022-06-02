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
@testable import WireSyncEngine

class ZMUserSessionTests_Syncing: ZMUserSessionTestsBase {

    // MARK: Helpers

    class InitialSyncObserver: NSObject, ZMInitialSyncCompletionObserver {

        var didNotify: Bool = false
        var initialSyncToken: Any?

        init(context: NSManagedObjectContext) {
            super.init()
            initialSyncToken = ZMUserSession.addInitialSyncCompletionObserver(self, context: context)
        }

        func initialSyncCompleted() {
            didNotify = true
        }
    }

    func startQuickSync() {
        sut.applicationStatusDirectory?.syncStatus.currentSyncPhase = .done
        sut.applicationStatusDirectory?.syncStatus.pushChannelDidOpen()
    }

    func finishQuickSync() {
        sut.applicationStatusDirectory?.syncStatus.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
    }

    func startSlowSync() {
        sut.applicationStatusDirectory?.syncStatus.forceSlowSync()
    }

    func finishSlowSync() {
        sut.applicationStatusDirectory?.syncStatus.currentSyncPhase = .lastSlowSyncPhase
        sut.applicationStatusDirectory?.syncStatus.finishCurrentSyncPhase(phase: .lastSlowSyncPhase)
    }

    // MARK: Slow Sync

    func testThatObserverSystemIsDisabledDuringSlowSync() {

        // given
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.notificationDispatcher.isEnabled)

        // when
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.notificationDispatcher.isEnabled)
    }

    func testThatObserverSystemIsEnabledAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(sut.notificationDispatcher.isEnabled)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.notificationDispatcher.isEnabled)
    }

    func testThatInitialSyncIsCompletedAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(sut.hasCompletedInitialSync)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.hasCompletedInitialSync)
    }

    func testThatItNotifiesObserverWhenInitialIsSyncCompleted() {
        // given
        let observer = InitialSyncObserver(context: uiMOC)
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(observer.didNotify)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(observer.didNotify)
    }

    func testThatPerformingSyncIsStillOngoingAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isPerformingSync)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isPerformingSync)
    }

    // MARK: Quick Sync

    func testThatPerformingSyncIsFinishedAfterQuickSync() {

        // given
        startQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isPerformingSync)

        // when
        finishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isPerformingSync)
    }

    // MARK: Process events

    func testThatPerformingSyncIsStillOngoingAfterProcessingEvents_IfQuickSyncIsNotCompleted() {

        // given
        startQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isPerformingSync)

        // when
        sut.processEvents()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isPerformingSync)
    }

    func testThatItNotifiesOnlineSynchronzingWhileProcessingEvents() {

        // given
        startQuickSync()
        finishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let networkStateRecorder = NetworkStateRecorder(userSession: sut)

        // when
        sut.processEvents()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(networkStateRecorder.stateChanges, [.onlineSynchronizing, .online])
        XCTAssertFalse(sut.isPerformingSync)
    }

}
