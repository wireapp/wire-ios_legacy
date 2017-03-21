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


@implementation Message (UI)

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
                        [Message isDeletedMessage:message] ||
                        [Message isMissedCallMessage:message] ||
                        [Message isPerformedCallMessage:message];

    return allowedType;
}

+ (BOOL)shouldShowDeliveryState:(id<ZMConversationMessage>)message
{
    return ![Message isPerformedCallMessage:message] && ![Message isMissedCallMessage:message];
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

+ (NSDateFormatter *)dayFormatter
{
    static NSDateFormatter *dayFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dayFormatter = [[NSDateFormatter alloc] init];
        dayFormatter.dateFormat = @"d MMMM, EEEE";
    });

    return dayFormatter;
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

+ (NSString *)nonNilImageDataIdentifier:(id<ZMConversationMessage>)message
{
    NSString *identifier = message.imageMessageData.imageDataIdentifier;
    if (! identifier) {
        DDLogWarn(@"Image cache key is nil!");
        return [NSString stringWithFormat:@"nonnil-%p", message.imageMessageData.imageData];
    }
    return identifier;
}

+ (BOOL)canBePrefetched:(id<ZMConversationMessage>)message
{
    return [Message isFileTransferMessage:message] ||
           [Message isImageMessage:message] ||
           [Message isTextMessage:message];
}

@end
