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
@testable import WireDataModel

class ZMConversationTests_Timestamps: ZMConversationTestsBase {

    // MARK: - Unread Count

    func testThatLastUnreadKnockDateIsSetWhenMessageInserted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let knock = GenericMessage(content: Knock.with { $0.hotKnock = false })
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            do {
                try message.setUnderlyingMessage(knock)
            } catch {
                XCTFail()
            }
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation

            // when
            conversation.updateTimestampsAfterInsertingMessage(message)

            // then
            XCTAssertEqual(conversation.lastUnreadKnockDate, timestamp)
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
        }
    }

    func testThatLastUnreadMissedCallDateIsSetWhenMessageInserted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            message.systemMessageType = .missedCall
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation

            // when
            conversation.updateTimestampsAfterInsertingMessage(message)

            // then
            XCTAssertEqual(conversation.lastUnreadMissedCallDate, timestamp)
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
        }
    }

    func testThatUnreadCountIsUpdatedWhenMessageIsInserted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation

            // when
            conversation.updateTimestampsAfterInsertingMessage(message)

            // then
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
            XCTAssertEqual(conversation.estimatedUnreadSelfMentionCount, 0)
        }
    }

    func testThatSelfMentionUnreadCountIsUpdatedWhenMessageIsInserted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let mention = Mention(range: NSRange(location: 0, length: 4), user: self.selfUser)
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)

            let textMessage = GenericMessage(content: Text(content: "@joe hello", mentions: [mention], linkPreviews: [], replyingTo: nil), nonce: nonce)
            do {
                try message.setUnderlyingMessage(textMessage)
            } catch {
                XCTFail()
            }
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation

            // when
            conversation.updateTimestampsAfterInsertingMessage(message)

            // then
            XCTAssertEqual(conversation.estimatedUnreadSelfMentionCount, 1)
        }
    }

    func testThatUnreadCountIsUpdatedWhenMessageIsDeleted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation
            conversation.updateTimestampsAfterInsertingMessage(message)
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)

            // when
            message.visibleInConversation = nil
            conversation.updateTimestampsAfterDeletingMessage()

            // then
            XCTAssertEqual(conversation.estimatedUnreadCount, 0)
        }
    }

    func testThatUnreadSelfMentionCountIsUpdatedWhenMessageIsDeleted() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let timestamp = Date()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let mention = Mention(range: NSRange(location: 0, length: 4), user: self.selfUser)
            let message = ZMClientMessage(nonce: nonce, managedObjectContext: self.syncMOC)

            let textMessage = GenericMessage(content: Text(content: "@joe hello", mentions: [mention], linkPreviews: [], replyingTo: nil), nonce: nonce)
            do {
                try message.setUnderlyingMessage(textMessage)
            } catch {
                XCTFail()
            }
            message.serverTimestamp = timestamp
            message.visibleInConversation = conversation
            conversation.updateTimestampsAfterInsertingMessage(message)
            XCTAssertEqual(conversation.internalEstimatedUnreadSelfMentionCount, 1)

            // when
            message.visibleInConversation = nil
            conversation.updateTimestampsAfterDeletingMessage()

            // then
            XCTAssertEqual(conversation.internalEstimatedUnreadSelfMentionCount, 0)
        }
    }

    func testThatNeedsToCalculateUnreadMessagesFlagIsUpdatedWhenMessageFromUpdateEventIsInserted() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()

            let nonce = UUID.create()
            let message = GenericMessage(content: Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce)
            let contentData = try? message.serializedData()
            let data = contentData?.base64String()

            let payload = self.payloadForMessage(in: conversation, type: EventConversationAddClientMessage, data: data!)
            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
            XCTAssertNotNil(event)

            // when
            var sut: ZMClientMessage?
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertEqual(sut?.conversation, conversation)
            XCTAssertTrue(conversation.needsToCalculateUnreadMessages)
        }
    }

    func testThatNeedsToCalculateUnreadMessagesFlagIsUpdatedAfterCallingtTheCalculateLastUnreadMessages() {

        // given
        syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.needsToCalculateUnreadMessages = true

            // when
            conversation.calculateLastUnreadMessages()

            // then
            XCTAssertFalse(conversation.needsToCalculateUnreadMessages)
        }
    }

    // MARK: - Cleared Date

    func testThatClearedTimestampIsUpdated() {
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        // when
        conversation.updateCleared(timestamp)

        // then
        XCTAssertEqual(conversation.clearedTimeStamp, timestamp)
    }

    func testThatClearedTimestampIsNotUpdatedToAnOlderTimestamp() {

        let timestamp = Date()
        let olderTimestamp = timestamp.addingTimeInterval(-100)
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.clearedTimeStamp = timestamp

        // when
        conversation.updateCleared(olderTimestamp)

        // then
        XCTAssertEqual(conversation.clearedTimeStamp, timestamp)
    }

    // MARK: - Modified Date

    func testThatModifiedDateIsUpdatedWhenMessageInserted() {
        // given
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.serverTimestamp = timestamp

        // when
        conversation.updateTimestampsAfterInsertingMessage(message)

        // then
        XCTAssertEqual(conversation.lastModifiedDate, timestamp)
    }

    func testThatModifiedDateIsNotUpdatedWhenMessageWhichShouldNotUpdateModifiedDateIsInserted() {
        // given
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.systemMessageType = .participantsRemoved
        message.serverTimestamp = timestamp

        // when
        conversation.updateTimestampsAfterInsertingMessage(message)

        // then
        XCTAssertNil(conversation.lastModifiedDate)
    }

    // MARK: - Last Read Date

    func testThatLastReadDateIsNotUpdatedWhenMessageFromSelfUserInserted() {
        // given
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.serverTimestamp = timestamp
        message.sender = selfUser

        // when
        conversation.updateTimestampsAfterInsertingMessage(message)

        // then
        XCTAssertNil(conversation.lastReadServerTimeStamp)
    }

    func testThatLastReadDateIsNotUpdatedWhenMessageFromOtherUserInserted() {
        // given
        let otherUser = createUser()
        let timestamp = Date()
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.serverTimestamp = timestamp
        message.sender = otherUser

        // when
        conversation.updateTimestampsAfterInsertingMessage(message)

        // then
        XCTAssertNil(conversation.lastReadServerTimeStamp)
    }

    func testThatItSendsANotificationWhenSettingTheLastRead() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        // expect
        expectation(forNotification: ZMConversation.lastReadDidChangeNotificationName, object: nil) { (_) -> Bool in
            return true
        }

        // when
        conversation.updateLastRead(Date())
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: - First Unread Message

    func testThatItReturnsTheFirstUnreadMessageIfWeHaveItLocally() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        // when
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.visibleInConversation = conversation

        // then
        XCTAssertEqual(conversation.firstUnreadMessage as? ZMClientMessage, message)
    }

    func testThatItReturnsTheFirstUnreadMessageMentioningSelfIfWeHaveItLocally() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        // when
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message1.visibleInConversation = conversation
        message1.serverTimestamp = Date(timeIntervalSinceNow: -2)

        let nonce = UUID()
        let message2 = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let mention = Mention(range: NSRange(location: 0, length: 4), user: selfUser)

        let textMessage = GenericMessage(content: Text(content: "@joe hello", mentions: [mention], linkPreviews: [], replyingTo: nil), nonce: nonce)
        do {
            try message2.setUnderlyingMessage(textMessage)
        } catch {
            XCTFail()
        }
        message2.visibleInConversation = conversation
        message1.serverTimestamp = Date(timeIntervalSinceNow: -1)

        // then
        XCTAssertEqual(conversation.firstUnreadMessageMentioningSelf as? ZMClientMessage, message2)
    }

    func testThatItReturnsNilIfTheLastReadServerTimestampIsMoreRecent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.visibleInConversation = conversation

        // when
        conversation.lastReadServerTimeStamp = message.serverTimestamp

        // then
        XCTAssertNil(conversation.firstUnreadMessage)
    }

    func testThatItSkipsMessagesWhichDoesntGenerateUnreadDotsDirectlyBeforeFirstUnreadMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        // when
        let messageWhichDoesntGenerateUnreadDot = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        messageWhichDoesntGenerateUnreadDot.systemMessageType = .participantsAdded
        messageWhichDoesntGenerateUnreadDot.visibleInConversation = conversation

        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.visibleInConversation = conversation

        // then
        XCTAssertEqual(conversation.firstUnreadMessage as? ZMClientMessage, message)
    }

    func testThatTheParentMessageIsReturnedIfItHasUnreadChildMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        let systemMessage1 = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage1.systemMessageType = .missedCall
        systemMessage1.visibleInConversation = conversation
        conversation.lastReadServerTimeStamp = systemMessage1.serverTimestamp

        // when
        let systemMessage2 = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage2.systemMessageType = .missedCall
        systemMessage2.hiddenInConversation = conversation
        systemMessage2.parentMessage = systemMessage1

        // then
        XCTAssertEqual(conversation.firstUnreadMessage as? ZMSystemMessage, systemMessage1)
    }

    func testThatTheParentMessageIsNotReturnedIfAllChildMessagesAreRead() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)

        let systemMessage1 = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage1.systemMessageType = .missedCall
        systemMessage1.visibleInConversation = conversation

        let systemMessage2 = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        systemMessage2.systemMessageType = .missedCall
        systemMessage2.hiddenInConversation = conversation
        systemMessage2.parentMessage = systemMessage1

        // when
        conversation.lastReadServerTimeStamp = systemMessage2.serverTimestamp

        // then
        XCTAssertNil(conversation.firstUnreadMessage)
    }

    // MARK: - Relevant Messages

    func testThatNotRelevantMessagesDoesntCountTowardsUnreadMessagesAmount() {

        syncMOC.performGroupedBlockAndWait {

            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)

            let systemMessage1 = ZMSystemMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            systemMessage1.systemMessageType = .missedCall
            systemMessage1.visibleInConversation = conversation

            let systemMessage2 = ZMSystemMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            systemMessage2.systemMessageType = .missedCall
            systemMessage2.visibleInConversation = conversation
            systemMessage2.relevantForConversationStatus = false

            let textMessage = ZMTextMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            textMessage.text = "Test"
            textMessage.visibleInConversation = conversation

            // when
            conversation.updateTimestampsAfterInsertingMessage(textMessage)

            // then
            XCTAssertEqual(conversation.unreadMessages.count, 2)
            XCTAssertTrue(conversation.unreadMessages.contains { $0.nonce == systemMessage1.nonce})
            XCTAssertFalse(conversation.unreadMessages.contains { $0.nonce == systemMessage2.nonce})
            XCTAssertTrue(conversation.unreadMessages.contains { $0.nonce == textMessage.nonce})
        }
    }

}
