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

extension ZMConversationTestsBase {
    @discardableResult
    @objc(insertConversationWithUnread:)
    func insertConversation(withUnread hasUnread: Bool) -> ZMConversation {
        let messageDate = Date(timeIntervalSince1970: 230000000)
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .oneOnOne
        conversation.lastServerTimeStamp = messageDate
        if hasUnread {
            let message = ZMClientMessage(nonce: NSUUID.create(), managedObjectContext: syncMOC)
            message.serverTimestamp = messageDate
            conversation.lastReadServerTimeStamp = messageDate.addingTimeInterval(-1000)
            conversation.append(message)
        }
        syncMOC.saveOrRollback()
        return conversation
    }
}

final class ZMConversationTests_Knock: ZMConversationTestsBase {
    func testThatItCanInsertAKnock() {
        syncMOC.performGroupedBlockAndWait({ [self] in

            // given
            let conversation = self.createConversationWithMessages()
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            // when
            let knock = try? conversation?.appendKnock()
            let msg = conversation?.lastMessage as! ZMMessage

            // then
            XCTAssertEqual(knock as? ZMMessage, msg)
            XCTAssertNotNil(knock?.knockMessageData)
            XCTAssert(knock!.isUserSender(selfUser))
        })

    }

    private func createConversationWithMessages() -> ZMConversation? {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = NSUUID.create()
        for text in ["A", "B", "C", "D", "E"] {
            conversation._appendText(content: text)
        }
        XCTAssert(syncMOC.saveOrRollback())
        return conversation
    }
}
