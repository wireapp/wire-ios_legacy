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

import XCTest

class ConversationTests_ClearingHistory: ConversationTestsBase {

    func loginAndFillConversationWithMessages(mockConversation: MockConversation, messagesCount: UInt) {
        XCTAssertTrue(login())

        var conversation = self.conversation(for: mockConversation)
        let selfUserSet: Set<AnyHashable> = [self.selfUser]
        let otherUser = mockConversation.activeUsers.firstObjectNot(in: selfUserSet) as! MockUser

        // given
        let fromClient = otherUser.clients.anyObject() as! MockUserClient
        let toClient = self.selfUser.clients.anyObject() as! MockUserClient

        self.mockTransportSession.performRemoteChanges { (_) in
            // If the client is not registered yet we need to account for the added System Message
            for i in 0..<(Int(messagesCount) - conversation!.allMessages.count) {

                let message = GenericMessage(content: Text(content: "foo" + String(i), mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
                mockConversation.encryptAndInsertData(from: fromClient,
                                                      to: toClient,
                                                      data: try! message.serializedData())
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        conversation = self.conversation(for: mockConversation)
        conversation?.markAsRead()

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation!.allMessages.count, Int(messagesCount))
    }

    func testThatItRemovesMessagesAfterReceivingAPushEventToClearHistory() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        var conversation = self.conversation(for: self.groupConversation!)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when removing messages remotely

        self.remotelyAppendSelfConversationWithZMCleared(for: self.groupConversation, at: conversation!.lastServerTimeStamp!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when adding new messages
        self.userSession?.perform {
            self.spinMainQueue(withTimeout: 1)// if the message is sent within the same second of clearing the window, it will not be added when resyncing
            let message = try! conversation?.appendText(content: "lalala")
            conversation?.markMessagesAsRead(until: message!)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.allMessages.count, 1)

        self.recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Wait for sync to be done
        XCTAssertTrue(self.login())

        // then
        conversation = self.conversation(for: self.groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let objectIDs = conversationDirectory?.conversationsIncludingArchived.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        XCTAssertTrue(objectIDs!.contains(conversationID!))
    }

    func testThatDeletedConversationsStayDeletedAfterResyncing() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)

        var conversation = self.conversation(for: self.groupConversation!)
        XCTAssertEqual(conversation!.allMessages.count, 5)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when deleting the conversation remotely

        self.mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.remotelyAppendSelfConversationWithZMCleared(for: self.groupConversation, at: conversation!.lastServerTimeStamp!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation!.allMessages.count, 0)
        XCTAssertFalse(conversationDirectory!.conversationsIncludingArchived.contains(conversation))

        conversation = nil
        self.recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Wait for sync to be done
        XCTAssertTrue(self.login())

        // then
        conversation = self.conversation(for: self.groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let conversationsIncludingArchivedObjectIDs = conversationDirectory?.conversationsIncludingArchived.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        let archivedConversationsObjectIDs = conversationDirectory?.archivedConversations.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        let clearedConversationsObjectIDs = conversationDirectory?.clearedConversations.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        XCTAssertFalse(conversationsIncludingArchivedObjectIDs!.contains(conversationID!))
        XCTAssertFalse(archivedConversationsObjectIDs!.contains(conversationID!))
        XCTAssertTrue(clearedConversationsObjectIDs!.contains(conversationID!))
    }

    func testFirstArchivingThenClearingRemotelyShouldDeleteConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        let conversation = self.conversation(for: self.groupConversation!)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        self.mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.remotelyAppendSelfConversationWithZMCleared(for: self.groupConversation, at: conversation!.lastServerTimeStamp!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let objectIDs = conversationDirectory?.conversationsIncludingArchived.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        XCTAssertFalse(objectIDs!.contains(conversationID!))
    }

    func testFirstClearingThenArchivingRemotelyShouldDeleteConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        let conversation = self.conversation(for: self.groupConversation!)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        self.remotelyAppendSelfConversationWithZMCleared(for: self.groupConversation, at: conversation!.lastServerTimeStamp!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let objectIDs = conversationDirectory?.conversationsIncludingArchived.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        XCTAssertFalse(objectIDs!.contains(conversationID!))
    }

    func testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationLists() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        let conversation = self.conversation(for: self.groupConversation!)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()

        // when archiving the conversation remotely
        self.mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversationDirectory!.conversationsIncludingArchived.contains(conversation))
        XCTAssertTrue(conversationDirectory!.archivedConversations.contains(conversation))
        XCTAssertFalse(conversationDirectory!.clearedConversations.contains(conversation))
    }

    func testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationListsAfterResyncing() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        var conversation = self.conversation(for: self.groupConversation!)

        let conversationDirectory = self.userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when deleting the conversation remotely, whiping the cache and resyncing
        self.mockTransportSession.performRemoteChanges { (_) in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(self.login())

        // then
        conversation = self.conversation(for: self.groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let conversationsIncludingArchivedObjectIDs = conversationDirectory?.conversationsIncludingArchived.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        let archivedConversationsObjectIDs = conversationDirectory?.archivedConversations.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        let clearedConversationsObjectIDs = conversationDirectory?.clearedConversations.compactMap { $0 as? ZMConversation}.map { $0.objectID }
        XCTAssertTrue(conversationsIncludingArchivedObjectIDs!.contains(conversationID!))
        XCTAssertTrue(archivedConversationsObjectIDs!.contains(conversationID!))
        XCTAssertFalse(clearedConversationsObjectIDs!.contains(conversationID!))
    }

    func testThatReceivingRemoteTextMessageRevealsClearedConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        var conversation = self.conversation(for: self.groupConversation!)

        self.userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            self.spinMainQueue(withTimeout: 1)// if the action happens within the same second the user clears the history, the event is not added
            let message = GenericMessage(content: Text(content: "foo", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.groupConversation.encryptAndInsertData(from: self.user2.clients.anyObject() as! MockUserClient,
                                                        to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                        data: try! message.serializedData())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: self.groupConversation!)
        XCTAssertEqual(conversation!.allMessages.count, 1)
        XCTAssertFalse(conversation!.isArchived)
    }

    func testThatReceivingRemoteSystemMessageRevealsClearedConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        var conversation = self.conversation(for: self.groupConversation!)

        self.userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            self.spinMainQueue(withTimeout: 1)// if the action happens within the same second the user clears the history, the event is not added
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.user3)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: self.groupConversation!)

        XCTAssertEqual(conversation!.allMessages.count, 1)
        XCTAssertTrue(conversation!.isArchived)
    }

    func testThatOpeningClearedConversationRevealsIt() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: self.groupConversation, messagesCount: messagesCount)
        var conversation = self.conversation(for: self.groupConversation!)

        self.userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        self.userSession?.perform {
            conversation?.revealClearedConversation()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: self.groupConversation!)
        XCTAssertEqual(conversation!.allMessages.count, 0)
        XCTAssertFalse(conversation!.isArchived)
    }
}
