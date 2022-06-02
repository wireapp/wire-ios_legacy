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
import WireTesting
@testable import WireSyncEngine

class SessionManagerTests_MessageRetention: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    override var useInMemoryStore: Bool {
        return false
    }

    func testThatItDeletesMessagesOlderThanTheRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system messages

        // when
        sessionManager?.configuration.messageRetentionInterval = 1
        spinMainQueue(withTimeout: 1)
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 0)
    }

    func testThatItKeepsMessagesNewerThanTheRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system messages

        // when
        sessionManager?.configuration.messageRetentionInterval = 100
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4)
    }

    func testThatItKeepsMessagesIfThereIsNoRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system messages

        // when
        sessionManager?.configuration.messageRetentionInterval = nil
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4)
    }

}
