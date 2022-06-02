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

@testable import WireSyncEngine

class TypingTests: MessagingTest, ZMTypingChangeObserver {

    private typealias Typing = WireSyncEngine.Typing

    private var sut: Typing!
    private var token: Any?
    private var receivedNotifications = [TypingChange]()

    private var conversationA: ZMConversation!
    private var userA: ZMUser!
    private var userB: ZMUser!
    private var userAOnUi: ZMUser!
    private var userBOnUi: ZMUser!

    override func setUp() {
        super.setUp()

        sut = Typing(uiContext: uiMOC, syncContext: syncMOC)
        resetNotifications()

        syncMOC.performGroupedAndWait { _ in
            self.conversationA = ZMConversation.insertNewObject(in: self.syncMOC)
            self.userA = ZMUser.insertNewObject(in: self.syncMOC)
            self.userB = ZMUser.insertNewObject(in: self.syncMOC)
            XCTAssert(self.syncMOC.saveOrRollback())
        }

        let uiConversation = uiMOC.object(with: conversationA.objectID) as! ZMConversation
        token = uiConversation.addTypingObserver(self)

        userAOnUi = uiMOC.object(with: userA.objectID) as? ZMUser
        userBOnUi = uiMOC.object(with: userB.objectID) as? ZMUser
    }

    override func tearDown() {
        sut.tearDown()
        sut = nil
        token = nil
        resetNotifications()
        conversationA = nil
        userA = nil
        userB = nil
        userAOnUi = nil
        userBOnUi = nil
        super.tearDown()
    }

    private func resetNotifications() {
        receivedNotifications.removeAll()
    }

    private func createConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        return conversation
    }

    private func createUser() -> ZMUser {
        return ZMUser.insertNewObject(in: uiMOC)
    }

    func typingDidChange(conversation: ZMConversation, typingUsers: [UserType]) {
        let users = typingUsers.compactMap { $0 as? ZMUser }
        receivedNotifications.append(TypingChange(conversation: conversationA, typingUsers: Set(users)))
    }

    // MARK: - Tests

    func testThatTimeoutIsInitializedWithDefault() {
        // Given, then
        XCTAssertEqual(sut.timeout, Typing.defaultTimeout)
    }

    func testThatItSendsOutANotificationWhenAUserStartsTyping() {
        // When
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        let notification = receivedNotifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation.objectID, conversationA.objectID)
        XCTAssertEqual(notification!.typingUsers, Set([userAOnUi]))
    }

    func testThatItDoesNotSendOutANotificationWhenTheUserIsAlreadyTyping() {
        // Given
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()

        // When
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedNotifications.count, 0)
    }

    func testThatItSendsOutANotificationWhenAUserStopsTyping() {
        // Given
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()

        // When
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(false, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        let notification = receivedNotifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation.objectID, conversationA.objectID)
        XCTAssertEqual(notification!.typingUsers, Set())
    }

    func testThatItSendsOutANotificationWhenAUserTimesOut() {
        // Given
        let timeout = 0.1
        sut.timeout = timeout

        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()

        // When
        spinMainQueue(withTimeout: timeout + 0.2)

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        let notification = receivedNotifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation.objectID, conversationA.objectID)
        XCTAssertEqual(notification!.typingUsers, Set())
    }

    func testThatItDoesNotSendOutANotificationWhenTheUserTypesAgainWithinTheTimeout() {
        // Given
        let timeout = 0.5
        sut.timeout = timeout

        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()
        spinMainQueue(withTimeout: timeout * 0.5)

        // When user types again
        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        spinMainQueue(withTimeout: timeout * 0.5)

        // Then
        XCTAssertEqual(receivedNotifications.count, 0)
    }

    func testThatItSendsOutANotificationAgainWhenAUserTimesOutInARow() {
        // Given
        let timeout = 0.1
        sut.timeout = timeout

        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userA, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()
        spinMainQueue(withTimeout: timeout * 0.5)

        syncMOC.performGroupedBlockAndWait { self.sut.setIsTyping(true, for: self.userB, in: self.conversationA) }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        resetNotifications()

        // When
        spinMainQueue(withTimeout: timeout * 0.6)

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        var notification = receivedNotifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation.objectID, conversationA.objectID)
        XCTAssertEqual(notification!.typingUsers, Set([userBOnUi]))

        resetNotifications()

        // When
        spinMainQueue(withTimeout: timeout * 0.6)

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        notification = receivedNotifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation.objectID, conversationA.objectID)
        XCTAssertEqual(notification!.typingUsers, Set())
    }

}
