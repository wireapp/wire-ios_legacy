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

extension ConversationTableViewDataSource {
    
    func messagePrevious(to message: ZMConversationMessage, at index: Int) -> ZMConversationMessage? {
        var previous = NSNotFound
        
        if index < messages.count - 1 && index != NSNotFound {
            previous = index + 1
        }
        
        if previous != NSNotFound {
            return messages[previous]
        }
        
        return nil
    }
    
    func shouldShowDaySeparator(for message: ZMConversationMessage, at index: Int) -> Bool {
        guard let previous = messagePrevious(to: message, at: index)?.serverTimestamp, let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }

    func isPreviousSenderSame(forMessage message: ZMConversationMessage?, at index: Int) -> Bool {
        guard let message = message,
              Message.isNormal(message),
              !Message.isKnock(message) else { return false }

        guard let previousMessage = messagePrevious(to: message, at: index),
              previousMessage.sender == message.sender,
              Message.isNormal(previousMessage) else { return false }

        return true
    }
    
    static let burstSeparatorTimeDifference: TimeInterval = 60 * 45
    
    public func layoutProperties(for message: ZMConversationMessage, at index: Int) -> ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        
        layoutProperties.showSender            = shouldShowSender(for: message, at: index)
        layoutProperties.showUnreadMarker      = message.equals(to: firstUnreadMessage)
        layoutProperties.showBurstTimestamp    = shouldShowBurstSeparator(for: message, at: index) || layoutProperties.showUnreadMarker
        layoutProperties.showDayBurstTimestamp = shouldShowDaySeparator(for: message, at: index)
        layoutProperties.topPadding            = topPadding(for: message, at: index, showingSender:layoutProperties.showSender, showingTimestamp:layoutProperties.showBurstTimestamp)
        layoutProperties.alwaysShowDeliveryState = shouldShowAlwaysDeliveryState(for: message)
        
        if let textMessageData = message.textMessageData {
            layoutProperties.linkAttachments = Message.linkAttachments(textMessageData)
        }
        
        return layoutProperties
    }
    
    func shouldShowAlwaysDeliveryState(for message: ZMConversationMessage) -> Bool {
        if let sender = message.sender, sender.isSelfUser,
            let conversation = message.conversation,
            conversation.conversationType == .oneOnOne,
            let lastSentMessage = conversation.lastMessageSent(by: sender, limit: 10),
            message.equals(to: lastSentMessage) {
            return true
        }
        return false
    }
    
    func shouldShowSender(for message: ZMConversationMessage, at index: Int) -> Bool {
        if let systemMessageData = message.systemMessageData,
            systemMessageData.systemMessageType == .messageDeletedForEveryone {
            return true
        }
 
        if !message.isSystem {
            if !self.isPreviousSenderSame(forMessage: message, at: index) || message.updatedAt != nil {
                return true
            }
            
            if let previousMessage = self.messagePrevious(to: message, at: index) {
                return previousMessage.isKnock
            }
        }
        
        return false
    }
    
    func shouldShowBurstSeparator(for message: ZMConversationMessage, at index: Int) -> Bool {
        if let systemMessageData = message.systemMessageData {
            switch systemMessageData.systemMessageType {
            case .newClient, .conversationIsSecure, .reactivatedDevice, .newConversation, .usingNewDevice, .messageDeletedForEveryone, .missedCall, .performedCall:
                return false
            default:
                return true
            }
        }
        
        if message.isKnock {
            return false
        }
        
        if !message.isNormal && !message.isSystem {
            return false
        }
        
        guard let previousMessage = self.messagePrevious(to: message, at: index),
              let currentMessageServerTimestamp = message.serverTimestamp,
              let previousMessageServerTimestamp = previousMessage.serverTimestamp else {
            return true
        }
    
        return currentMessageServerTimestamp.timeIntervalSince(previousMessageServerTimestamp) > type(of: self).burstSeparatorTimeDifference
    }
    
    func topPadding(for message: ZMConversationMessage, at index: Int, showingSender: Bool, showingTimestamp: Bool) -> CGFloat {
        guard let previousMessage = self.messagePrevious(to: message, at: index) else {
            return self.topMargin(for: message, showingSender: showingSender, showingTimestamp: showingTimestamp)
        }
    
        return max(self.topMargin(for: message, showingSender: showingSender, showingTimestamp: showingTimestamp), self.bottomMargin(for: previousMessage))
    }
    
    func topMargin(for message: ZMConversationMessage, showingSender: Bool, showingTimestamp: Bool) -> CGFloat {
        if message.isSystem || showingTimestamp {
            return 16
        }
        else if message.isNormal {
            return 12
        }
        else {
            return 0
        }
    }
    
    func bottomMargin(for message: ZMConversationMessage) -> CGFloat {
        if message.isSystem {
            return 16
        }
        else if message.isNormal {
            return 12
        }
        else {
            return 0
        }
    }
}
