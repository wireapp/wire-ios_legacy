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


#import "Message+Private.h"
#import "Message+Formatting.h"
#import "Constants.h"
#import "Settings.h"

@import WireExtensionComponents;

@implementation Message

+ (MessageType)messageType:(id<ZMConversationMessage>)message
{
    if ([self isImageMessage:message]) {
        return MessageTypeImage;
    }
    if ([self isKnockMessage:message]) {
        return MessageTypePing;
    }
    if ([self isTextMessage:message]) {
        if ((message.textMessageData.linkPreview != nil) || ([self linkAttachments:message.textMessageData].count > 0)) {
            return MessageTypeRichMedia;
        }
        return MessageTypeText;
    }
    if ([self isFileTransferMessage:message]) {
        if (message.fileMessageData.isVideo) {
            return MessageTypeVideo;
        }
        if (message.fileMessageData.isAudio) {
            return MessageTypeAudio;
        }
        return MessageTypeFile;
    }
    if ([self isSystemMessage:message]) {
        return MessageTypeSystem;
    }
    if ([self isLocationMessage:message]) {
        return MessageTypeLocation;
    }
    return MessageTypeUnknown;
}

+ (BOOL)isTextMessage:(id<ZMConversationMessage>)message
{
    return message.textMessageData != nil;
}

+ (BOOL)isImageMessage:(id<ZMConversationMessage>)message
{
    return message.imageMessageData != nil;
}

+ (BOOL)isKnockMessage:(id<ZMConversationMessage>)message
{
    return message.knockMessageData != nil;
}

+ (BOOL)isFileTransferMessage:(id<ZMConversationMessage>)message
{
    return message.fileMessageData != nil;
}

+ (BOOL)isVideoMessage:(id<ZMConversationMessage>)message
{
    return [self isFileTransferMessage:message] && [message.fileMessageData isVideo];
}

+ (BOOL)isAudioMessage:(id<ZMConversationMessage>)message
{
    return [self isFileTransferMessage:message] && [message.fileMessageData isAudio];
}

+ (BOOL)isLocationMessage:(id<ZMConversationMessage>)message
{
    return message.locationMessageData != nil;
}

+ (BOOL)isSystemMessage:(id<ZMConversationMessage>)message
{
    return message.systemMessageData != nil;
}

+ (BOOL)isNormalMessage:(id<ZMConversationMessage>)message
{
    return [self isTextMessage:message] || [self isImageMessage:message] || [self isKnockMessage:message] || [self isFileTransferMessage:message] || [self isVideoMessage:message] || [self isAudioMessage:message] || [self isLocationMessage:message] ;
}

+ (BOOL)isConnectionRequestMessage:(id<ZMConversationMessage>)message
{
    if ([self isSystemMessage:message]) {
        return message.systemMessageData.systemMessageType == ZMSystemMessageTypeConnectionRequest;
    }
    return NO;
}

+ (BOOL)isMissedCallMessage:(id<ZMConversationMessage>)message
{
    if ([self isSystemMessage:message]) {
        return message.systemMessageData.systemMessageType == ZMSystemMessageTypeMissedCall;
    }
    return NO;
}

+ (BOOL)isDeletedMessage:(id<ZMConversationMessage>)message
{
    return [Message isSystemMessage:message] && ((ZMSystemMessage *)message).systemMessageType == ZMSystemMessageTypeMessageDeletedForEveryone;
}

+ (NSString *)formattedReceivedDateForMessage:(id<ZMConversationMessage>)message
{
    // Today's date
    NSDate *today = [NSDate new];
    
    NSDate *serverTimestamp = message.serverTimestamp;
    if (! serverTimestamp) {
        serverTimestamp = today;
    }
    
    return [serverTimestamp wr_formattedDate];
}

+ (BOOL)shouldShowTimestamp:(id<ZMConversationMessage>)message
{
    BOOL allowedType =  [Message isTextMessage:message] ||
                        [Message isImageMessage:message] ||
                        [Message isFileTransferMessage:message] ||
                        [Message isKnockMessage:message] ||
                        [Message isLocationMessage:message] ||
                        [Message isDeletedMessage:message];
    
    return allowedType;
}

+ (NSDateFormatter *)shortVersionDateFormatter
{
    static NSDateFormatter *shortVersionDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortVersionDateFormatter = [[NSDateFormatter alloc] init];
        [shortVersionDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [shortVersionDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    });
    
    return shortVersionDateFormatter;
}

+ (NSDateFormatter *)longVersionTimeFormatter
{
    static NSDateFormatter *longVersionTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        longVersionTimeFormatter = [[NSDateFormatter alloc] init];
        [longVersionTimeFormatter setDateStyle:NSDateFormatterNoStyle];
        [longVersionTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    });
    
    return longVersionTimeFormatter;
}

+ (BOOL)isPresentableAsNotification:(id<ZMConversationMessage>)message
{
    BOOL isChatHeadsDisabled = [[Settings sharedSettings] chatHeadsDisabled];
    BOOL isConversationSilenced = message.conversation.isSilenced;
    BOOL isSenderSelfUser = [message.sender isSelfUser];
    BOOL isMessageUnread = (NSUInteger) message.serverTimestamp.timeIntervalSinceReferenceDate > message.conversation.lastReadMessage.serverTimestamp.timeIntervalSinceReferenceDate;
    // only show a notification chathead if the message is new (recently sent)
    BOOL isTimelyMessage = [[NSDate date] timeIntervalSinceDate:message.serverTimestamp] <= (0.5f);
    BOOL isSystemMessage = [self isSystemMessage:message];

    return ! isChatHeadsDisabled &&
            ! isConversationSilenced &&
            ! isSenderSelfUser &&
            isMessageUnread &&
            isTimelyMessage &&
            ! isSystemMessage;
}

@end
