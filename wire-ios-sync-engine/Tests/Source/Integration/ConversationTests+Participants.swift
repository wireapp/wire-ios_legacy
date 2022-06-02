//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationTests_Participants: ConversationTestsBase {

    func testThatAddingAndRemovingAParticipantToAConversationSendsOutChangeNotifications() {

        // given
        XCTAssert(login())

        let conversation = self.conversation(for: emptyGroupConversation)!
        let connectedUser = user(for: self.user2)!

        let observer = ConversationChangeObserver(conversation: conversation)
        observer?.clearNotifications()

        // when
        conversation.addParticipants([connectedUser], completion: { (_) in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then - Participants changes and messages changes (System message for the added user)

        XCTAssertEqual(observer?.notifications.count, 1)
        guard let note1 = observer?.notifications.firstObject as? ConversationChangeInfo else {
            return XCTFail()
        }
        XCTAssertEqual(note1.conversation, conversation)
        XCTAssertTrue(note1.participantsChanged)
        XCTAssertTrue(note1.messagesChanged)
        observer?.notifications.removeAllObjects()

        // when
        conversation.removeParticipant(connectedUser, completion: { (_) in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then - Participants changes and messages changes (System message for the removed user)
        XCTAssertEqual(observer?.notifications.count, 1)
        let note2 = observer?.notifications.firstObject as! ConversationChangeInfo
        XCTAssertEqual(note2.conversation, conversation)
        XCTAssertTrue(note2.participantsChanged)
        XCTAssertTrue(note2.messagesChanged)

        observer?.notifications.removeAllObjects()
    }

    func testThatAddingParticipantsToAConversationIsSynchronizedWithBackend() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: emptyGroupConversation)!
        let connectedUser = user(for: self.user2)!

        XCTAssertFalse(conversation.localParticipants.contains(connectedUser))

        // when
        conversation.addParticipants([connectedUser], completion: { (_) in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversation.localParticipants.contains(connectedUser))

        // Tear down & recreate contexts
        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(login())

        // then
        XCTAssertTrue(self.conversation(for: emptyGroupConversation)!.localParticipants.contains(user(for: self.user2)!))
    }

    func testThatRemovingParticipantsFromAConversationIsSynchronizedWithBackend() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: groupConversation)!
        let connectedUser = user(for: self.user2)!

        XCTAssertTrue(conversation.localParticipants.contains(connectedUser))

        // when
        conversation.removeParticipant(connectedUser, completion: { (_) in })
        XCTAssertTrue( waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(conversation.localParticipants.contains(connectedUser))

        // Tear down & recreate contexts
        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(login())

        // then
        XCTAssertFalse(self.conversation(for: groupConversation)!.localParticipants.contains(user(for: self.user2)!))
    }

    func testThatNotificationsAreReceivedWhenConversationsAreFaulted() {
        // given
        XCTAssertTrue(login())

        // I am faulting conversation, will maintain the "message" relations as faulted
        let conversationList = ZMConversationList.conversations(inUserSession: userSession!)
        let conversation1 = conversation(for: self.selfToUser1Conversation)
        let previousIndex = conversationList.index(of: conversation1)

        XCTAssertEqual(conversationList.count, 5)

        let observer = ConversationListChangeObserver.init(conversationList: conversationList)

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            let message = GenericMessage(content: Text(content: "some message", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.selfToUser1Conversation.encryptAndInsertData(from: self.user1.clients.anyObject() as! MockUserClient,
                                                              to: self.selfUser.clients.anyObject() as! MockUserClient,
                                                              data: try! message.serializedData())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer?.notifications.count, 2) // Two updates because unread count is updated separately
        let note1 = observer?.notifications.lastObject as! ConversationListChangeInfo
        XCTAssertEqual(note1.zm_movedIndexPairs.first, ZMMovedIndex.init(from: UInt(previousIndex), to: 0))
    }

}
