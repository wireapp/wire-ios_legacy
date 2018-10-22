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

struct MessageCellContext {
    
    let isSameSenderAsPrevious: Bool
    let isLastMessageSentBySelfUser: Bool
    let isTimeIntervalSinceLastMessageSignificant: Bool
    let isFirstMessageOfTheDay: Bool
    let isFirstUnreadMessage: Bool
    
}

struct UnknownMessageCellDescription: CellDescription { // TODO jacob replace with something else (placeholder for now)
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: ConversationUnknownMessageCellId, for: indexPath)
    }
    
}

extension ZMConversationMessageWindow {
    
    func description(for message: ZMConversationMessage, firstUnreadMessage: ZMConversationMessage?) -> CellDescription {
        let context = self.context(for: message, firstUnreadMessage: firstUnreadMessage)
        
        if message.isText {
            return TextMessageCellDescription(message: message, context: context)
        } else if message.isImage {
            return DefaultMessageCellDescription<NewImageMessageCell>(message: message, context: context)
        } else if message.isVideo {
            return DefaultMessageCellDescription<NewVideoMessageCell>(message: message, context: context)
        } else if (message.isAudio) {
            return DefaultMessageCellDescription<NewAudioMessageCell>(message: message, context: context)
        } else if (message.isFile) {
            return DefaultMessageCellDescription<NewFileMessageCell>(message: message, context: context)
        } else {
            return UnknownMessageCellDescription()
        }
    }
    
    @objc func isPreviousSenderSame(forMessage message: ZMConversationMessage?) -> Bool {
        guard let message = message,
              messages.index(of: message) != NSNotFound,
              Message.isNormal(message),
              !Message.isKnock(message) else { return false }

        guard let previousMessage = messagePrevious(to: message),
              previousMessage.sender == message.sender,
              Message.isNormal(previousMessage) else { return false }

        return true
    }
    
    fileprivate func context(for message: ZMConversationMessage, firstUnreadMessage: ZMConversationMessage?) -> MessageCellContext {
        let significantTimeInterval: TimeInterval = 60 * 45; // 45 minutes
        let isTimeIntervalSinceLastMessageSignificant: Bool
        
        if let timeIntervalToPreviousMessage = timeIntervalToPreviousMessage(from: message) {
            isTimeIntervalSinceLastMessageSignificant = timeIntervalToPreviousMessage > significantTimeInterval
        } else {
            isTimeIntervalSinceLastMessageSignificant = false
        }
        
        return MessageCellContext(isSameSenderAsPrevious: isPreviousSenderSame(forMessage: message),
                                  isLastMessageSentBySelfUser: isLastMessageSentBySelfUser(message),
                                  isTimeIntervalSinceLastMessageSignificant: isTimeIntervalSinceLastMessageSignificant,
                                  isFirstMessageOfTheDay: isFirstMessageOfTheDay(for: message),
                                  isFirstUnreadMessage: message.isEqual(firstUnreadMessage))
    }
    
    fileprivate func timeIntervalToPreviousMessage(from message: ZMConversationMessage) -> TimeInterval? {
        guard let currentMessageTimestamp = message.serverTimestamp, let previousMessageTimestamp = messagePrevious(to: message)?.serverTimestamp else {
            return nil
        }
        
        return currentMessageTimestamp.timeIntervalSince(previousMessageTimestamp)
    }
    
    fileprivate func isLastMessageSentBySelfUser(_ message: ZMConversationMessage) -> Bool {
        return message.isEqual(message.conversation?.lastMessageSent(by: ZMUser.selfUser(), limit: 10))
    }
    
    fileprivate func isFirstMessageOfTheDay(for message: ZMConversationMessage) -> Bool {
        guard let previous = messagePrevious(to: message)?.serverTimestamp, let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }
    
}
