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

import XCTest
@testable import WireSyncEngine

final class SyncStatusTests: MessagingTest {

    var sut: SyncStatus!
    var mockSyncDelegate: MockSyncStateDelegate!
    override func setUp() {
        super.setUp()
        mockSyncDelegate = MockSyncStateDelegate()
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
    }

    override func tearDown() {
        uiMOC.zm_lastNotificationID = nil
        mockSyncDelegate = nil
        sut = nil
        super.tearDown()
    }

    func testThatWhenIntializingWithoutLastEventIDItStartsInStateFetchingLastUpdateEventID() {
        // given
        uiMOC.zm_lastNotificationID = nil

        // when
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatWhenIntializingWihtLastEventIDItStartsInStateFetchingMissingEvents() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID

        // when
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    private var syncPhases: [SyncPhase] {
        return [.fetchingLastUpdateEventID,
                .fetchingTeams,
                .fetchingTeamMembers,
                .fetchingTeamRoles,
                .fetchingConnections,
                .fetchingConversations,
                .fetchingUsers,
                .fetchingSelfUser,
                .fetchingLegalHoldStatus,
                .fetchingLabels,
                .fetchingMissedEvents]
    }

    func testThatItGoesThroughTheStatesInSpecificOrder() {
        syncPhases.forEach { syncPhase in
            // given / then
            XCTAssertEqual(sut.currentSyncPhase, syncPhase)
            // when
            sut.finishCurrentSyncPhase(phase: syncPhase)
        }
        // then
        XCTAssertEqual(sut.currentSyncPhase, .done)
    }

    func testThatItSavesTheLastNotificationIDOnlyAfterFinishingUserPhase() {
        // given
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        sut.updateLastUpdateEventID(eventID: UUID.timeBasedUUID() as UUID)
        XCTAssertNil(uiMOC.zm_lastNotificationID)

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)

        // then
        XCTAssertNotNil(uiMOC.zm_lastNotificationID)

    }

    func testThatItDoesNotSetTheLastNotificationIDIfItHasNone() {
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        XCTAssertNotNil(uiMOC.zm_lastNotificationID)

        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeamMembers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeamRoles)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingConnections)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingConversations)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // then
        XCTAssertNotNil(uiMOC.zm_lastNotificationID)
    }

    func testThatItNotifiesTheStateDelegateWhenFinishingSync() {
        // given
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        XCTAssertFalse(mockSyncDelegate.didCallFinishSlowSync)
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallFinishSlowSync)
        XCTAssertTrue(mockSyncDelegate.didCallFinishQuickSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingSlowSync() {
        // given
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartSlowSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingQuickSync() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)
    }

    func testThatItDoesNotNotifyTheStateDelegateWhenAlreadySyncing() {
        // given
        mockSyncDelegate.didCallStartQuickSync = false
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)

        XCTAssertFalse(mockSyncDelegate.didCallStartQuickSync)

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)

        // then
        XCTAssertFalse(mockSyncDelegate.didCallStartQuickSync)
    }

    func testThatItNotifiesTheStateDelegateWhenPushChannelClosedThatSyncStarted() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        mockSyncDelegate.didCallStartQuickSync = false

        // when
        sut.pushChannelDidClose()

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)

    }

}

// MARK: QuickSync
extension SyncStatusTests {

    func testThatItStartsQuickSyncWhenPushChannelOpens_PreviousPhaseDone() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItDoesNotStartsQuickSyncWhenPushChannelOpens_PreviousInSlowSync() {
        // given
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatItRestartsQuickSyncWhenPushChannelOpens_PreviousInQuickSync() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItRestartsQuickSyncWhenPushChannelClosedDuringQuickSync() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.pushChannelDidClose()
        sut.pushChannelDidOpen()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItRestartsSlowSyncWhenRestartSlowSyncIsCalled() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.forceSlowSync()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItRestartsSlowSyncWhenRestartSlowSyncNotificationIsFired() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        NotificationInContext(name: .ForceSlowSync, context: uiMOC.notificationContext).post()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItDoesNotRestartsQuickSyncWhenPushChannelIsClosed() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.pushChannelDidClose()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .done)
    }

    func testThatItEntersSlowSyncIfQuickSyncFailed() {
        // given
        uiMOC.zm_lastNotificationID = UUID.timeBasedUUID() as UUID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatItClearsLastNotificationIDWhenQuickSyncFails() {
        // given
        let oldID = UUID.timeBasedUUID() as UUID
        let newID = UUID.timeBasedUUID() as UUID
        uiMOC.zm_lastNotificationID = oldID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.updateLastUpdateEventID(eventID: newID)
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertNil(uiMOC.zm_lastNotificationID)
    }

    func testThatItSavesLastNotificationIDOnlyAfterSlowSyncFinishedSuccessfullyAfterFailedQuickSync() {
        // given
        let oldID = UUID.timeBasedUUID() as UUID
        let newID = UUID.timeBasedUUID() as UUID
        uiMOC.zm_lastNotificationID = oldID
        sut = SyncStatus(managedObjectContext: uiMOC, syncStateDelegate: mockSyncDelegate)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.updateLastUpdateEventID(eventID: newID)
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // and when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, newID)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLegalHoldStatus)
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLabels)
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)

        // then
        XCTAssertEqual(uiMOC.zm_lastNotificationID, newID)
        XCTAssertNotEqual(uiMOC.zm_lastNotificationID, oldID)
    }
}
