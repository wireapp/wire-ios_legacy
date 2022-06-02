//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import WireTesting
import WireDataModel

class ZMClientMessageTests_Unarchiving: BaseZMClientMessageTests {

    func testThatItUnarchivesAConversationWhenItWasNotCleared() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true

        let genericMessage = GenericMessage(content: Text(content: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)

        // when
        performPretendingUiMocIsSyncMoc {
            XCTAssertNotNil(ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil))
        }

        // then
        XCTAssertFalse(conversation.isArchived)
    }

    func testThatItDoesNotUnarchiveASilencedConversation() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        conversation.mutedMessageTypes = .all

        let genericMessage = GenericMessage(content: Text(content: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)

        // when
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertTrue(conversation.isArchived)
    }

    func testThatItDoesNotUnarchiveAClearedConversation_TimestampForMessageIsOlder() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        let lastMessage = try! conversation.appendText(content: "foo") as! ZMClientMessage
        lastMessage.serverTimestamp = Date().addingTimeInterval(10)
        conversation.lastServerTimeStamp = lastMessage.serverTimestamp!
        conversation.clearMessageHistory()

        let genericMessage = GenericMessage(content: Text(content: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)
        XCTAssertNotNil(event)

        XCTAssertGreaterThan(conversation.clearedTimeStamp!.timeIntervalSince1970, event.timestamp!.timeIntervalSince1970)

        // when
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertTrue(conversation.isArchived)
    }

    func testThatItUnarchivesAClearedConversation_TimestampForMessageIsNewer() {

        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        let lastMessage = try! conversation.appendText(content: "foo") as! ZMClientMessage
        lastMessage.serverTimestamp = Date().addingTimeInterval(-10)
        conversation.lastServerTimeStamp = lastMessage.serverTimestamp!
        conversation.clearMessageHistory()

        let genericMessage = GenericMessage(content: Text(content: "bar"))
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)

        XCTAssertLessThan(conversation.clearedTimeStamp!.timeIntervalSince1970, event.timestamp!.timeIntervalSince1970)

        // when
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        // then
        XCTAssertFalse(conversation.isArchived)
    }

}
