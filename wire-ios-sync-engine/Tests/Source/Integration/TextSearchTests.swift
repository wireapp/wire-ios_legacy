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
import WireTesting

private class MockSearchDelegate: TextSearchQueryDelegate {
    var results = [TextQueryResult]()

    func textSearchQueryDidReceive(result: TextQueryResult) {
        results.append(result)
    }
}

class TextSearchTests: ConversationTestsBase {

    func testThatItFindsAMessageSendRemotely() {
        // Given
        XCTAssertTrue(login())

        let firstClient = user1.clients.anyObject() as! MockUserClient
        let selfClient = selfUser.clients.anyObject() as! MockUserClient

        // When
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: Text(content: "Hello there!"))
            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        guard let convo = conversation(for: selfToUser1Conversation) else { return XCTFail("Undable to get conversation") }
        let lastMessage = convo.lastMessage
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, "Hello there!")

        // Then
        verifyThatItCanSearch(for: "There", in: convo, andFinds: lastMessage as! ZMMessage)
    }

    func testThatItFindsAMessageEditedRemotely() {
        // Given
        XCTAssertTrue(login())

        let firstClient = user1.clients.anyObject() as! MockUserClient
        let selfClient = selfUser.clients.anyObject() as! MockUserClient
        let nonce = UUID.create()

        // When
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: Text(content: "Hello there!"), nonce: nonce)
            do {
                 self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())
             } catch {
                 XCTFail()
             }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        guard let convo = conversation(for: selfToUser1Conversation) else { return XCTFail("Undable to get conversation") }
        guard let lastMessage = convo.lastMessage else { return XCTFail("Undable to get message") }
        XCTAssertEqual(lastMessage.textMessageData?.messageText, "Hello there!")

        // And when
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: MessageEdit(replacingMessageID: nonce, text: Text(content: "This is an edit!!")))

            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())

            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        guard let editedMessage = convo.lastMessage else { return XCTFail("Undable to get message") }
        XCTAssertEqual(editedMessage.textMessageData?.messageText, "This is an edit!!")

        // Then
        verifyThatItCanSearch(for: "edit", in: convo, andFinds: editedMessage as! ZMMessage)
        verifyThatItCanSearch(for: "Hello", in: convo, andFinds: nil)
    }

    func testThatItDoesFindAnEphemeralMessageSentRemotely() {
        // Given
        XCTAssertTrue(login())

        let firstClient = user1.clients.anyObject() as! MockUserClient
        let selfClient = selfUser.clients.anyObject() as! MockUserClient
        let text = "This is an ephemeral message"

        // When
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: Text(content: text), expiresAfterTimeInterval: 300)

            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        guard let convo = conversation(for: selfToUser1Conversation) else { return XCTFail("Undable to get conversation") }
        let lastMessage = convo.lastMessage
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, text)

        // Then
        verifyThatItCanSearch(for: "ephemeral", in: convo, andFinds: lastMessage as! ZMMessage)
    }

    func testThatItDoesNotFindAMessageDeletedRemotely() {
        // Given
        XCTAssertTrue(login())

        let firstClient = user1.clients.anyObject() as! MockUserClient
        let selfClient = selfUser.clients.anyObject() as! MockUserClient
        let nonce = UUID.create()

        // When
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: Text(content: "Hello there!"), nonce: nonce)

            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        guard let convo = conversation(for: selfToUser1Conversation) else { return XCTFail("Undable to get conversation") }
        let lastMessage = convo.lastMessage
        XCTAssertEqual(lastMessage?.textMessageData?.messageText, "Hello there!")

        // Then
        verifyThatItCanSearch(for: "Hello", in: convo, andFinds: lastMessage as! ZMMessage)

        // And when
        mockTransportSession.performRemoteChanges { _ in
            let genericMessage = GenericMessage(content: MessageDelete(messageId: nonce))

            do {
                self.selfToUser1Conversation.encryptAndInsertData(from: firstClient, to: selfClient, data: try genericMessage.serializedData())
            } catch {
                XCTFail()
            }
        }

        // Then
        verifyThatItCanSearch(for: "Hello", in: convo, andFinds: nil)
    }

    func verifyThatItCanSearch(for query: String, in conversation: ZMConversation, andFinds message: ZMMessage?, file: StaticString = #file, line: UInt = #line) {
        // Given
        let delegate = MockSearchDelegate()
        let searchQuery = TextSearchQuery(conversation: conversation, query: query, delegate: delegate)

        // When
        searchQuery?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)

        // Then
        guard let result = delegate.results.last else { return XCTFail("No search result found", file: file, line: line) }

        if let message = message {
            XCTAssertEqual(result.matches.count, 1, file: file, line: line)
            guard let match = result.matches.first else { return XCTFail("No match found", file: file, line: line) }
            XCTAssertEqual(match.textMessageData?.messageText, message.textMessageData?.messageText, file: file, line: line)
        } else {
            XCTAssert(result.matches.isEmpty, file: file, line: line)
        }
    }

}
