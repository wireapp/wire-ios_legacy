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

class ConversationTests_LastRead: ConversationTestsBase {

    func testThatEstimatedUnreadCountIsIncreasedAfterRecevingATextMessage() {
        // login
        XCTAssertTrue(login())

        // given
        let fromClient = self.user1.clients.anyObject()  as! MockUserClient
        var toClient = self.selfUser.clients.anyObject() as! MockUserClient

        self.mockTransportSession.performRemoteChanges { (_) in
            let message = GenericMessage(content: Text(content: "Will insert this to have a message to read", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient,
                                                              to: toClient,
                                                              data: try! message.serializedData())
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(self.login())

        let conversation = self.conversation(for: self.selfToUser1Conversation!)

        XCTAssertEqual(conversation!.estimatedUnreadCount, 0)

        toClient = self.selfUser.clients.first(where: { (client) -> Bool in
            guard let client = client as? MockUserClient else {
                return false
            }
            return client.identifier == ZMUser.selfUser(in: self.userSession!.managedObjectContext).selfClient()!.remoteIdentifier
        }) as! MockUserClient

        // when
        self.mockTransportSession.performRemoteChanges { (_) in
            let message = GenericMessage(content: Text(content: "This should increase the unread count", mentions: [], linkPreviews: [], replyingTo: nil), nonce: UUID.create())
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient,
                                                              to: toClient,
                                                              data: try! message.serializedData())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation!.estimatedUnreadCount, 1)
    }
}
