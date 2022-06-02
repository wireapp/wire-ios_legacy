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

import Foundation

extension ZMConversation {
    fileprivate func unarchive(with message: ZMOTRMessage) {
        self.internalIsArchived = false

        if self.lastServerTimeStamp != nil, let serverTimestamp = message.serverTimestamp {
            self.updateArchived(serverTimestamp, synchronize: false)
        }
    }
}

extension ZMOTRMessage {

    @objc(unarchiveIfNeeded:)
    func unarchiveIfNeeded(_ conversation: ZMConversation) {
        if let clearedTimestamp = conversation.clearedTimeStamp,
            let serverTimestamp = self.serverTimestamp,
            serverTimestamp.compare(clearedTimestamp) == ComparisonResult.orderedAscending {
                return
        }

        unarchiveIfCurrentUserIsMentionedOrQuoted(conversation)

        unarchiveIfNotSilenced(conversation)
    }

    private func unarchiveIfCurrentUserIsMentionedOrQuoted(_ conversation: ZMConversation) {

        if conversation.isArchived,
            let sender = self.sender,
            !sender.isSelfUser,
            let textMessageData = self.textMessageData,
            !conversation.mutedMessageTypes.contains(.mentionsAndReplies),
            textMessageData.isMentioningSelf || textMessageData.isQuotingSelf {
            conversation.unarchive(with: self)
        }
    }

    private func unarchiveIfNotSilenced(_ conversation: ZMConversation) {
        if conversation.isArchived, conversation.mutedMessageTypes == .none {
            conversation.unarchive(with: self)
        }
    }
}
