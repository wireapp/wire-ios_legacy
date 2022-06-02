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

class IsTypingTests: IntegrationTest, ZMTypingChangeObserver {

    private typealias Typing = WireSyncEngine.Typing

    private var oldTimeout: TimeInterval = 0
    private var notifications: [TypingChange] = []
    private var token: Any?

    override func setUp() {
        oldTimeout = Typing.defaultTimeout
        Typing.defaultTimeout = 2

        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()

        notifications = []
    }

    override func tearDown() {
        Typing.defaultTimeout = oldTimeout
        token = nil
        super.tearDown()
    }

    func typingDidChange(conversation: ZMConversation, typingUsers: [UserType]) {
        let users = typingUsers.compactMap { $0 as? ZMUser }
        notifications.append(TypingChange(conversation: conversation, typingUsers: Set(users)))
    }

    // MARK: - Tests

    func testThatItSendsTypingNotifications() {
        // Given
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)!
        token = conversation.addTypingObserver(self)

        XCTAssertEqual(conversation.typingUsers.count, 0)

        // When
        mockTransportSession.sendIsTypingEvent(for: groupConversation, user: user1, started: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(notifications.count, 1)
        notifications.removeAll()

        // When
        spinMainQueue(withTimeout: Typing.defaultTimeout + 1)

        // Then
        XCTAssertEqual(notifications.count, 1)
        let notification = notifications.first
        XCTAssertNotNil(notification)
        XCTAssertEqual(notification!.conversation, conversation)
        XCTAssertEqual(notification!.typingUsers.count, 0)
        XCTAssertEqual(conversation.typingUsers.count, 0)
    }

    func testThatItResetsIsTypingWhenATypingUserSendsAMessage() {
        // Given
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)!
        token = conversation.addTypingObserver(self)

        XCTAssertEqual(conversation.typingUsers.count, 0)

        // When
        mockTransportSession.sendIsTypingEvent(for: groupConversation, user: user1, started: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(notifications.count, 1)
        XCTAssertEqual(conversation.typingUsers.count, 1)
        notifications.removeAll()

        // When
        mockTransportSession.performRemoteChanges { _ in
            let content = Text(content: "text text", mentions: [], linkPreviews: [], replyingTo: nil)
            let message = GenericMessage(content: content, nonce: .create())

            do {
                self.groupConversation.encryptAndInsertData(
                    from: self.user1.clients.anyObject() as! MockUserClient,
                    to: self.selfUser.clients.anyObject() as! MockUserClient,
                    data: try message.serializedData())
            } catch {
                XCTFail()
            }

        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(conversation.typingUsers.count, 0)
    }

    func testThatItDoesNotResetIsTypingWhenADifferentUserThanTheTypingUserSendsAMessage() {
        // Given
        XCTAssertTrue(login())

        let conversation = self.conversation(for: groupConversation)!
        token = conversation.addTypingObserver(self)

        XCTAssertEqual(conversation.typingUsers.count, 0)

        // When
        mockTransportSession.sendIsTypingEvent(for: groupConversation, user: user2, started: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(notifications.count, 1)
        XCTAssertEqual(conversation.typingUsers.count, 1)
        notifications.removeAll()

        // When
        mockTransportSession.performRemoteChanges { _ in
            let content = Text(content: "text text", mentions: [], linkPreviews: [], replyingTo: nil)
            let message = GenericMessage(content: content, nonce: .create())

            do {
                self.groupConversation.encryptAndInsertData(
                    from: self.user1.clients.anyObject() as! MockUserClient,
                    to: self.selfUser.clients.anyObject() as! MockUserClient,
                    data: try message.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(conversation.typingUsers.count, 1)
    }

}
