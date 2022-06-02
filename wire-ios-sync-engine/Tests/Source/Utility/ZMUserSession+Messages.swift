//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension ZMUserSession {
    @discardableResult func insertUnreadDotGeneratingMessageMessage(in conversation: ZMConversation) -> ZMSystemMessage {
        let newTime = conversation.lastServerTimeStamp?.addingTimeInterval(5) ?? Date()

        let user = ZMUser.insertNewObject(in: self.managedObjectContext)
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: self.managedObjectContext)
        message.serverTimestamp = newTime
        message.systemMessageType = .missedCall
        message.sender = user
        conversation.lastServerTimeStamp = message.serverTimestamp
        conversation.mutableMessages.add(message)
        return message
    }

    @discardableResult func insertConversationWithUnreadMessage() -> ZMConversation {
        let conversation = ZMConversation.insertGroupConversation(session: self, participants: [])!
        conversation.remoteIdentifier = UUID()

        self.insertUnreadDotGeneratingMessageMessage(in: conversation)
        // then
        XCTAssertNotNil(conversation.firstUnreadMessage)
        return conversation
    }
}
