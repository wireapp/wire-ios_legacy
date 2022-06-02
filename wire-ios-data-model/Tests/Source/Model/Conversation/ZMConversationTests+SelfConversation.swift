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

import Foundation
@testable import WireDataModel

class ZMConversationTests_SelfConversation: ZMConversationTestsBase {
    func testThatItUpdatesTheLastReadTimestamp() {
        // GIVEN
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = nonce
        conversation.lastReadServerTimeStamp = Date(timeIntervalSince1970: 0)

        let timeinterval: Int64 = 10000
        let lastRead = LastRead.with {
            $0.conversationID = nonce.transportString()
            $0.lastReadTimestamp = timeinterval
        }

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMConversation.updateConversation(withLastReadFromSelfConversation: lastRead, inContext: self.uiMOC)
        }
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(conversation.lastReadServerTimeStamp, Date(timeIntervalSince1970: Double(integerLiteral: timeinterval) / 1000))
    }

    func testThatItUpdatesClearedTimestamp() {
        // GIVEN
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = nonce
        conversation.clearedTimeStamp = Date(timeIntervalSince1970: 0)

        let timeinterval: Int64 = 10000
        let cleared = Cleared.with {
            $0.conversationID = nonce.transportString()
            $0.clearedTimestamp = timeinterval
        }

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMConversation.updateConversation(withClearedFromSelfConversation: cleared, inContext: self.uiMOC)
        }
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(conversation.clearedTimeStamp, Date(timeIntervalSince1970: Double(integerLiteral: timeinterval) / 1000))
    }
}
