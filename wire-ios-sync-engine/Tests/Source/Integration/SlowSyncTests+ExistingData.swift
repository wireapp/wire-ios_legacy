//
//  SlowSyncTests.swift
//  WireSyncEngine-iOS-Tests
//
//  Created by Jacob Persson on 04.09.19.
//  Copyright © 2019 Zeta Project Gmbh. All rights reserved.
//

import XCTest
import WireTesting

class SlowSyncTests_ExistingData: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    // MARK: - Slow sync with existing data

    func testThatConversationIsDeleted_WhenDiscoveredToBeDeletedDuringSlowSync() {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)!

        performRemoteChangesExludedFromNotificationStream { session in
            session.delete(self.groupConversation)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(conversation.isZombieObject)

        // WHEN
        performSlowSync()

        // THEN
        XCTAssertTrue(conversation.isZombieObject)
    }

    func testThatSelfUserLeavesConversation_WhenDiscoveredToBeInaccessibledDuringSlowSync() {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)!

        performRemoteChangesExludedFromNotificationStream { _ in
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.selfUser)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(conversation.isSelfAnActiveMember)

        // WHEN
        performSlowSync()

        // THEN
        XCTAssertFalse(conversation.isSelfAnActiveMember)
    }

}
