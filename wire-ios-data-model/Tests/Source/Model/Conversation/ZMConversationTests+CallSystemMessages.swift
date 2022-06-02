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

@testable import WireDataModel

class ZMConversationCallSystemMessageTests: ZMConversationTestsBase {

    // MARK: - Missed Call

    func testThatItInsertAMissedCallSystemMessage() {
        syncMOC.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let user = self.createUser(onMoc: self.syncMOC)
            let timestamp = Date()

            // when
            conversation.appendMissedCallMessage(fromUser: user, at: timestamp)

            // then
            guard let message = conversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("No system message")
            }

            XCTAssertEqual(message.sender, user)
            XCTAssertEqual(message.users, [user])
            XCTAssertEqual(message.serverTimestamp, timestamp)
            XCTAssertEqual(message.systemMessageType, .missedCall)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItUpdatesAMissedCallSystemMessageIfAnotherOneIsInsertedSubsequently() {
        syncMOC.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let user = self.createUser(onMoc: self.syncMOC)
            let timestamp = Date()
            let first = conversation.appendMissedCallMessage(fromUser: user, at: timestamp)

            // when
            let second = conversation.appendMissedCallMessage(fromUser: user, at: timestamp.addingTimeInterval(100))

            // then
            guard let message = conversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("No system message")
            }

            XCTAssertEqual(message, first)
            XCTAssertNil(message.hiddenInConversation)
            XCTAssertEqual(message.visibleInConversation, conversation)
            XCTAssertEqual(message.childMessages, [second])

            XCTAssertEqual(second.users, [user])
            XCTAssertEqual(second.parentMessage as? ZMSystemMessage, message)
            XCTAssertEqual(second.systemMessageType, .missedCall)
            XCTAssertNil(second.visibleInConversation)
            XCTAssertEqual(second.hiddenInConversation, conversation)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItUpdatesAMissedCallSystemMessageIfMulitpleOnesAreInsertedSubsequently() {
        syncMOC.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let user = self.createUser(onMoc: self.syncMOC)
            let timestamp = Date()
            let first = conversation.appendMissedCallMessage(fromUser: user, at: timestamp)

            // when
            let messages = (0..<3).map {
                conversation.appendMissedCallMessage(fromUser: user, at: timestamp.addingTimeInterval(TimeInterval($0)))
            }

            // then
            guard let message = conversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("No system message")
            }

            XCTAssertEqual(message, first)
            XCTAssertNil(message.hiddenInConversation)
            XCTAssertEqual(message.visibleInConversation, conversation)
            XCTAssertEqual(message.childMessages, Set(messages))

            messages.forEach {
                XCTAssertEqual($0.users, [user])
                XCTAssertEqual($0.parentMessage as? ZMSystemMessage, message)
                XCTAssertEqual($0.systemMessageType, .missedCall)
                XCTAssertNil($0.visibleInConversation)
                XCTAssertEqual($0.hiddenInConversation, conversation)
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItDoesNotUpdateAMissedCallSystemMessageIfAnotherOneIsInsertedIntermediateMessage() {
        syncMOC.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let user = self.createUser(onMoc: self.syncMOC)
            let timestamp = Date()
            let first = conversation.appendMissedCallMessage(fromUser: user, at: timestamp)
            let intermediate = try! conversation.appendText(content: "Answer the call, please!") as! ZMMessage

            // when
            let second = conversation.appendMissedCallMessage(fromUser: user, at: timestamp.addingTimeInterval(100))

            // then
            let lastMessages = conversation.lastMessages()
            XCTAssertEqual(lastMessages.count, 3)
            XCTAssertEqual(lastMessages[2] as? ZMSystemMessage, first)
            XCTAssertEqual(lastMessages[1], intermediate)
            XCTAssertEqual(lastMessages[0] as? ZMSystemMessage, second)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItDoesNotUpdatePreviousMissedCallMessageWhenCallerIsDifferent() {
        syncMOC.performGroupedBlock {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let firstUser = self.createUser(onMoc: self.syncMOC), secondUser = self.createUser(onMoc: self.syncMOC)
            let timestamp = Date()
            let first = conversation.appendMissedCallMessage(fromUser: firstUser, at: timestamp)

            // when
            let second = conversation.appendMissedCallMessage(fromUser: secondUser, at: timestamp.addingTimeInterval(100))

            // then
            let lastMessages = conversation.lastMessages()
            XCTAssertEqual(lastMessages.count, 2)
            XCTAssertEqual(lastMessages[1] as? ZMSystemMessage, first)
            XCTAssertEqual(lastMessages[0] as? ZMSystemMessage, second)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    // MARK: - Performed Call

    func testThatItInsertAPerformedCallSystemMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let user = createUser()

        // when
        conversation.appendPerformedCallMessage(with: 42, caller: user)

        // then
        guard let message = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail("No system message")
        }

        XCTAssertEqual(message.sender, user)
        XCTAssertEqual(message.users, [user])
        XCTAssertEqual(message.duration, 42)
        XCTAssertEqual(message.systemMessageType, .performedCall)
    }

    func testThatItUpdatesAPerformedCallSystemMessageIfAnotherOneIsInsertedSubsequently() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let user = createUser()
        let first = conversation.appendPerformedCallMessage(with: 42, caller: user)

        // when
        let second = conversation.appendPerformedCallMessage(with: 60, caller: user)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        guard let message = conversation.lastMessage as? ZMSystemMessage else {
            return XCTFail("No system message")
        }

        XCTAssertEqual(message, first)
        XCTAssertNil(message.hiddenInConversation)
        XCTAssertEqual(message.visibleInConversation, conversation)
        XCTAssertEqual(message.childMessages, [second])

        XCTAssertEqual(second.users, [user])
        XCTAssertEqual(second.parentMessage as? ZMSystemMessage, message)
        XCTAssertEqual(second.systemMessageType, .performedCall)
        XCTAssertNil(second.visibleInConversation)
        XCTAssertEqual(second.hiddenInConversation, conversation)
    }

    func testThatItDoesNotUpdateAPerformedCallSystemMessageIfAnotherOneIsInsertedIntermediateMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let user = createUser()
        let first = conversation.appendPerformedCallMessage(with: 42, caller: user)
        let intermediate = try! conversation.appendText(content: "Answer the call, please!") as! ZMMessage

        // when
        let second = conversation.appendPerformedCallMessage(with: 42, caller: user)

        // then
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 3)
        XCTAssertEqual(lastMessages[2] as? ZMSystemMessage, first)
        XCTAssertEqual(lastMessages[1], intermediate)
        XCTAssertEqual(lastMessages[0] as? ZMSystemMessage, second)
    }

    func testThatItDoesNotUpdatePreviousPerformedCallMessageWhenCallerIsDifferent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let firstUser = createUser(), secondUser = createUser()
        let first = conversation.appendPerformedCallMessage(with: 42, caller: firstUser)

        // when
        let second = conversation.appendPerformedCallMessage(with: 42, caller: secondUser)

        // then
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 2)
        XCTAssertEqual(lastMessages[1] as? ZMSystemMessage, first)
        XCTAssertEqual(lastMessages[0] as? ZMSystemMessage, second)
    }

}
