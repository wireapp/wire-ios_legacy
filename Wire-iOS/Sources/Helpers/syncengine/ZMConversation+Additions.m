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


#import "ZMConversation+Additions.h"

#import "WireSyncEngine+iOS.h"
#import "ZMUserSession+iOS.h"
#import <AVFoundation/AVFoundation.h>
#import "Analytics.h"
#import "Analytics.h"
#import "UIAlertController+Wire.h"
#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "ZClientViewController.h"
#import "UIApplication+Permissions.h"
#import "Wire-Swift.h"
#import "Settings.h"
#import "Constants.h"
#import "Wire-Swift.h"

@implementation ZMConversation (Additions)

- (ZMConversation *)addParticipantsOrCreateConversation:(NSSet *)participants
{
    if (! participants || participants.count == 0) {
        return self;
    }

    if (self.conversationType == ZMConversationTypeGroup) {
        [self addParticipantsOrShowError:participants];
        return self;
    }
    else if (self.conversationType == ZMConversationTypeOneOnOne &&
               (participants.count > 1 || (participants.count == 1 && ! [self.connectedUser isEqual:participants.anyObject]))) {

        Team *team = ZMUser.selfUser.team;

        NSMutableArray *listOfPeople = [participants.allObjects mutableCopy];
        [listOfPeople addObject:self.connectedUser];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                             withParticipants:listOfPeople
                                                                                       inTeam:team];

        return conversation;
    }

    return self;
}

- (ZMUser *)lastMessageSender
{
    ZMConversationType const conversationType = self.conversationType;
    if (conversationType == ZMConversationTypeGroup) {
        id<ZMConversationMessage>lastMessage = [self.messages lastObject];
        ZMUser *lastMessageSender = lastMessage.sender;
        return lastMessageSender;
    }
    else if (conversationType == ZMConversationTypeOneOnOne || conversationType == ZMConversationTypeConnection) {
        ZMUser *lastMessageSender = self.connectedUser;
        return lastMessageSender;
    }
    else if (conversationType == ZMConversationTypeSelf) {
        return [ZMUser selfUser];
    }
    // ZMConversationTypeInvalid
    return nil;
}

- (nullable id<ZMConversationMessage>)lastMessageSentByUser:(ZMUser *)user limit:(NSUInteger)limit
{
    ZMMessage *lastUserMessage = nil;
    
    NSUInteger index = 0;
    for (ZMMessage *enumeratedMessage in self.messages.reverseObjectEnumerator) {
        if (index > limit) {
            break;
        }
        if (enumeratedMessage.sender == user) {
            lastUserMessage = enumeratedMessage;
            break;
        }
        index++;
    }
    
    return lastUserMessage;
}

- (ZMUser *)firstActiveParticipantOtherThanSelf
{
    ZMUser *selfUser = [ZMUser selfUser];
    for (ZMUser *user in self.activeParticipants) {
        if ( ! [user isEqual:selfUser]) {
            return user;
        }
    }
    return nil;
}

- (id<ZMConversationMessage>)firstTextMessage
{
    // This is used currently to find the first text message in a connection request
    for (id<ZMConversationMessage>message in self.messages) {
        if ([Message isTextMessage:message]) {
            return message;
        }
    }
    
    return nil;
}

- (id<ZMConversationMessage>)lastTextMessage
{
    id<ZMConversationMessage> message = nil;
    
    // This is only used currently for the 'extras' mode where we show the last line of the conversation in the list
    for (NSInteger i = self.messages.count - 1; i >= 0; i--) {
        id<ZMConversationMessage>currentMessage = [self.messages objectAtIndex:i];
        if ([Message isTextMessage:currentMessage]) {
            message = currentMessage;
            break;
        }
    }
    
    return message;
}

- (BOOL)shouldShowBurstSeparatorForMessage:(id<ZMConversationMessage>)message
{
    // Missed calls should always show timestamp
    if ([Message isSystemMessage:message] &&
        message.systemMessageData.systemMessageType == ZMSystemMessageTypeMissedCall) {
        return YES;
    }

    if ([Message isKnockMessage:message]) {
        return NO;
    }

    if (! [Message isNormalMessage:message] && ! [Message isSystemMessage:message]) {
        return NO;
    }

    NSInteger index = [self.messages indexOfObject:message];
    NSInteger previousIndex = self.messages.count - 1;
    if (index != NSNotFound) {
        previousIndex = index - 1;
    }

    id<ZMConversationMessage>previousMessage = nil;

    // Find a previous message, and use it for time calculation
    while (previousIndex > 0 && self.messages.count > 1 && previousMessage != nil && ! [Message isNormalMessage:previousMessage] && ! [Message isSystemMessage:previousMessage]) {
        previousMessage = [self.messages objectAtIndex:previousIndex--];
    }

    if (! previousMessage) {
        return YES;
    }

    BOOL showTimestamp = NO;

    NSTimeInterval seconds = [message.serverTimestamp timeIntervalSinceDate:previousMessage.serverTimestamp];
    NSTimeInterval referenceSeconds = 300;

    if (seconds > referenceSeconds) {
        showTimestamp = YES;
    }

    return showTimestamp;
}

- (BOOL)selfUserIsActiveParticipant
{
    return [self.activeParticipants containsObject:[ZMUser selfUser]];
}

@end
