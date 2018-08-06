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
    @objc func isPreviousSenderSame(forMessage message: ZMConversationMessage?) -> Bool {
        guard let message = message,
            let _ = messages.index(of: message as! ZMMessage),
              Message.isNormal(message),
              !Message.isKnock(message) else { return false }

        guard let previousMessage = messagePrevious(to: message),
              previousMessage.sender == message.sender,
              Message.isNormal(previousMessage) else { return false }

        return true
    }
    
    static let burstSeparatorTimeDifference: TimeInterval = 60 * 45
    
    public func layoutProperties(for message: ZMConversationMessage) -> ConversationCellLayoutProperties {
        let layoutProperties = ConversationCellLayoutProperties()
        
        layoutProperties.showSender       = self.shouldShowSender(for: message)
        layoutProperties.showUnreadMarker = message.equals(to: firstUnreadMessage)
        layoutProperties.showBurstTimestamp = self.shouldShowBurstSeparator(for: message) || layoutProperties.showUnreadMarker
        layoutProperties.showDayBurstTimestamp = self.shouldShowDaySeparator(for: message)
        layoutProperties.topPadding       = self.topPadding(for: message, showingSender:layoutProperties.showSender, showingTimestamp:layoutProperties.showBurstTimestamp)
        layoutProperties.alwaysShowDeliveryState = self.shouldShowAlwaysDeliveryState(for: message)
        
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
    
    func shouldShowSender(for message: ZMConversationMessage) -> Bool {
        if let systemMessageData = message.systemMessageData,
            systemMessageData.systemMessageType == .messageDeletedForEveryone {
            return true
        }
 
        if !message.isSystem {
            if !self.isPreviousSenderSame(forMessage: message) || message.updatedAt != nil {
                return true
            }
            
            
            if let previousMessage = self.messagePrevious(to: message) {
                return previousMessage.isKnock
            }
        }
        
        return false
    }
    
    func shouldShowBurstSeparator(for message: ZMConversationMessage) -> Bool {
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
        
        guard let previousMessage = self.messagePrevious(to: message),
              let currentMessageServerTimestamp = message.serverTimestamp,
              let previousMessageServerTimestamp = previousMessage.serverTimestamp else {
            return true
        }
    
        return currentMessageServerTimestamp.timeIntervalSince(previousMessageServerTimestamp) > type(of: self).burstSeparatorTimeDifference
    }
    
    func topPadding(for message: ZMConversationMessage, showingSender: Bool, showingTimestamp: Bool) -> CGFloat {
        guard let previousMessage = self.messagePrevious(to :message) else {
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
