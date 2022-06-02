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

class ZMConversationTests_UnreadMessages: ZMConversationTestsBase {

    func testThatItCalculatesLastUnreadMessages() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID.create()

           let knock = GenericMessage(content: Knock.with { $0.hotKnock = false })
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            do {
                try message.setUnderlyingMessage(knock)
            } catch {
                XCTFail()
            }
            message.serverTimestamp = Date()
            message.visibleInConversation = conversation
            conversation.updateTimestampsAfterUpdatingMessage(message)

            XCTAssertTrue(conversation.needsToCalculateUnreadMessages)
            XCTAssertEqual(conversation.estimatedUnreadCount, 0)

            // when
            ZMConversation.calculateLastUnreadMessages(in: self.syncMOC)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            // then
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
            XCTAssertFalse(conversation.needsToCalculateUnreadMessages)
        }
    }

}
