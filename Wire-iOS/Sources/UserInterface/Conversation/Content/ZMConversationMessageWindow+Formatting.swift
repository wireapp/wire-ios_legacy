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

extension ZMConversationMessageWindow {
        
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
    
    func context(for message: ZMConversationMessage, firstUnreadMessage: ZMConversationMessage?, searchQueries: [String]) -> ConversationMessageContext {
        let significantTimeInterval: TimeInterval = 60 * 45; // 45 minutes
        let isTimeIntervalSinceLastMessageSignificant: Bool
        
        if let timeIntervalToPreviousMessage = timeIntervalToPreviousMessage(from: message) {
            isTimeIntervalSinceLastMessageSignificant = timeIntervalToPreviousMessage > significantTimeInterval
        } else {
            isTimeIntervalSinceLastMessageSignificant = false
        }
        
        return ConversationMessageContext(
            isSameSenderAsPrevious: isPreviousSenderSame(forMessage: message),
            isTimeIntervalSinceLastMessageSignificant: isTimeIntervalSinceLastMessageSignificant,
            isFirstMessageOfTheDay: isFirstMessageOfTheDay(for: message),
            isFirstUnreadMessage: message.isEqual(firstUnreadMessage),
            isLastMessage: self.messages.index(of: message) == 0,
            searchQueries: searchQueries,
            previousMessageIsKnock: messagePrevious(to: message)?.isKnock == true
        )
    }
    
    fileprivate func timeIntervalToPreviousMessage(from message: ZMConversationMessage) -> TimeInterval? {
        guard let currentMessageTimestamp = message.serverTimestamp, let previousMessageTimestamp = messagePrevious(to: message)?.serverTimestamp else {
            return nil
        }
        
        return currentMessageTimestamp.timeIntervalSince(previousMessageTimestamp)
    }
    
    fileprivate func isFirstMessageOfTheDay(for message: ZMConversationMessage) -> Bool {
        guard let previous = messagePrevious(to: message)?.serverTimestamp, let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }
    
}
