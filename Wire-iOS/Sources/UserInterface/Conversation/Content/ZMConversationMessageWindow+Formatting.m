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


#import "ZMConversationMessageWindow+Formatting.h"
#import "ConversationCell.h"
#import "Wire-Swift.h"


static NSTimeInterval const BurstSeparatorTimeDifference = 60 * 45; // 45 minutes


@implementation ZMConversationMessageWindow (Formatting)

- (ConversationCellLayoutProperties *)layoutPropertiesForMessage:(id<ZMConversationMessage>)message firstUnreadMessage:(id<ZMConversationMessage>)firstUnreadMessage
{
    ConversationCellLayoutProperties *layoutProperties = [[ConversationCellLayoutProperties alloc] init];
    layoutProperties.showSender       = [self shouldShowSenderForMessage:message];
    layoutProperties.showUnreadMarker = firstUnreadMessage != nil && [message isEqual:firstUnreadMessage];
    layoutProperties.showBurstTimestamp = [self shouldShowBurstSeparatorForMessage:message] || layoutProperties.showUnreadMarker;
    layoutProperties.showDayBurstTimestamp = [self shouldShowDaySeparatorForMessage:message];
    layoutProperties.topPadding       = [self topPaddingForMessage:message showingSender:layoutProperties.showSender showingTimestamp:layoutProperties.showBurstTimestamp];
    layoutProperties.alwaysShowDeliveryState = [self shouldShowAlwaysDeliveryStateForMessage:message];
    
    return layoutProperties;
}

- (BOOL)shouldShowAlwaysDeliveryStateForMessage:(id<ZMConversationMessage>)message
{
    // Loop back and check if this was last message sent by us
    if (message.sender.isSelfUser && message.conversation.conversationType == ZMConversationTypeOneOnOne) {
        if ([message.conversation lastMessageSentByUser:[ZMUser selfUser] limit:10] == message) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)shouldShowSenderForMessage:(id<ZMConversationMessage>)message
{
    BOOL systemMessage = [Message isSystemMessage:message];
    if (systemMessage && [(ZMSystemMessage *)message systemMessageType] == ZMSystemMessageTypeMessageDeletedForEveryone) {
        // Message Deleted system messages always show the sender image
        return YES;
    }
    
    if (!systemMessage) {
        if (![self isPreviousSenderSameForMessage:message] || message.updatedAt != nil) {
            return YES;
        }

        id <ZMConversationMessage> previousMessage = [self messagePreviousToMessage:message];
        if (nil != previousMessage) {
            return [Message isKnockMessage:previousMessage];
        }
    }
    
    return NO;
}

- (BOOL)shouldShowBurstSeparatorForMessage:(id<ZMConversationMessage>)message
{
    if ([Message isSystemMessage:message]) {
        id<ZMSystemMessageData> systemMessage = message.systemMessageData;
        
        return  systemMessage.systemMessageType != ZMSystemMessageTypeNewClient &&
                systemMessage.systemMessageType != ZMSystemMessageTypeConversationIsSecure &&
                systemMessage.systemMessageType != ZMSystemMessageTypeReactivatedDevice &&
                systemMessage.systemMessageType != ZMSystemMessageTypeNewConversation &&
                systemMessage.systemMessageType != ZMSystemMessageTypeUsingNewDevice &&
                systemMessage.systemMessageType != ZMSystemMessageTypeMessageDeletedForEveryone &&
                systemMessage.systemMessageType != ZMSystemMessageTypeMissedCall &&
                systemMessage.systemMessageType != ZMSystemMessageTypePerformedCall;
    }
    
    if ([Message isKnockMessage:message]) {
        return NO;
    }
    
    if (! [Message isNormalMessage:message] && ! [Message isSystemMessage:message]) {
        return NO;
    }
    
    id<ZMConversationMessage>previousMessage = [self messagePreviousToMessage:message];
    
    if (! previousMessage) {
        return YES;
    }
    
    BOOL showTimestamp = NO;
    NSTimeInterval seconds = [message.serverTimestamp timeIntervalSinceDate:previousMessage.serverTimestamp];
    
    if (seconds > BurstSeparatorTimeDifference) {
        showTimestamp = YES;
    }
    
    return showTimestamp;
}

- (CGFloat)topPaddingForMessage:(id<ZMConversationMessage>)message showingSender:(BOOL)showingSender showingTimestamp:(BOOL)showingTimestamp
{
    id<ZMConversationMessage>previousMessage = [self messagePreviousToMessage:message];
    
    if (! previousMessage) {
        return [self topMarginForMessage:message showingSender:showingSender showingTimestamp:showingTimestamp];
    }
    
    return MAX([self topMarginForMessage:message showingSender:showingSender showingTimestamp:showingTimestamp], [self bottomMarginForMessage:previousMessage]);
}

- (CGFloat)topMarginForMessage:(id<ZMConversationMessage>)message showingSender:(BOOL)showingSender showingTimestamp:(BOOL)showingTimestamp
{
    if ([Message isSystemMessage:message] || showingTimestamp) {
        return 16;
    }
    else if ([Message isNormalMessage:message]) {
        return 12;
    }
    
    return 0;
}

- (CGFloat)bottomMarginForMessage:(id<ZMConversationMessage>)message
{
    if ([Message isSystemMessage:message]) {
        return 16;
    }
    else if ([Message isNormalMessage:message]) {
        return 12;
    }
    
    return 0;
}

@end
