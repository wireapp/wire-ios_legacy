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
import XCTest
import WireTesting
@testable import WireDataModel

final class DuplicatedEntityRemovalTests: DiskDatabaseTest {

    func appendSystemMessage(conversation: ZMConversation,
                             type: ZMSystemMessageType,
                             sender: ZMUser,
                             users: Set<ZMUser>?,
                             addedUsers: Set<ZMUser> = Set(),
                             clients: Set<UserClient>?,
                             timestamp: Date?,
                             duration: TimeInterval? = nil
        ) -> ZMSystemMessage {

        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: moc)
        systemMessage.systemMessageType = type
        systemMessage.sender = sender
        systemMessage.users = users ?? Set()
        systemMessage.addedUsers = addedUsers
        systemMessage.clients = clients ?? Set()
        systemMessage.serverTimestamp = timestamp
        if let duration = duration {
            systemMessage.duration = duration
        }

        conversation.append(systemMessage)
        systemMessage.visibleInConversation = conversation
        return systemMessage
    }

    func addedOrRemovedSystemMessages(conversation: ZMConversation,
                                      client: UserClient
                                      ) -> [ZMSystemMessage] {
        let addedMessage = self.appendSystemMessage(conversation: conversation,
                                                    type: .newClient,
                                                    sender: ZMUser.selfUser(in: self.moc),
                                                    users: Set(arrayLiteral: client.user!),
                                                    addedUsers: Set(arrayLiteral: client.user!),
                                                    clients: Set(arrayLiteral: client),
                                                    timestamp: Date())

        let ignoredMessage = self.appendSystemMessage(conversation: conversation,
                                                      type: .ignoredClient,
                                                      sender: ZMUser.selfUser(in: self.moc),
                                                      users: Set(arrayLiteral: client.user!),
                                                      clients: Set(arrayLiteral: client),
                                                      timestamp: Date())

        return [addedMessage, ignoredMessage]
    }

    func messages(conversation: ZMConversation) -> [ZMMessage] {
        return (0..<5).map { try! conversation.appendText(content: "Message \($0)") as! ZMMessage }
    }
}

// MARK: - Merge tests
extension DuplicatedEntityRemovalTests {

    func testThatItMergesTwoUserClients() {

        // GIVEN
        let user = createUser()
        let conversation = createConversation()
        let client1 = createClient(user: user)

        let client2 = createClient(user: user)
        client2.remoteIdentifier = client1.remoteIdentifier

        let addedOrRemovedInSystemMessages = Set<ZMSystemMessage>(
            addedOrRemovedSystemMessages(conversation: conversation, client: client2)
        )
        let ignoredByClients = Set((0..<5).map { _ in createClient(user: user) })
        let messagesMissingRecipient = Set<ZMMessage>(messages(conversation: conversation))
        let trustedByClients = Set((0..<5).map { _ in createClient(user: user) })
        let missedByClient = createClient(user: user)

        client2.addedOrRemovedInSystemMessages = addedOrRemovedInSystemMessages
        client2.ignoredByClients = ignoredByClients
        client2.messagesMissingRecipient = messagesMissingRecipient
        client2.trustedByClients = trustedByClients
        client2.missedByClient = missedByClient

        // WHEN
        client1.merge(with: client2)
        self.moc.delete(client2)
        self.moc.saveOrRollback()

        // THEN
        XCTAssertEqual(addedOrRemovedInSystemMessages.count, 2)

        XCTAssertEqual(client1.addedOrRemovedInSystemMessages, addedOrRemovedInSystemMessages)
        XCTAssertEqual(client1.ignoredByClients, ignoredByClients)
        XCTAssertEqual(client1.messagesMissingRecipient, messagesMissingRecipient)
        XCTAssertEqual(client1.trustedByClients, trustedByClients)
        XCTAssertEqual(client1.missedByClient, missedByClient)

        addedOrRemovedInSystemMessages.forEach {
            XCTAssertTrue($0.clients.contains(client1))
            XCTAssertFalse($0.clients.contains(client2))
        }
    }

}

extension Array where Element: ZMManagedObject {

    fileprivate var nonZombies: [Element] {
        return self.filter { !($0.isZombieObject || $0.isDeleted) }
    }
}
