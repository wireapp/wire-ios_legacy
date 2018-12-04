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


#import "Settings.h"
#import "Wire-Swift.h"

@import WireExtensionComponents;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@implementation Message (UI)

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

+ (NSDateFormatter *)shortTimeFormatter
{
    static NSDateFormatter *shortTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortTimeFormatter = [[NSDateFormatter alloc] init];
        [shortTimeFormatter setDateStyle:NSDateFormatterNoStyle];
        [shortTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    });

    return shortTimeFormatter;
}

+ (NSDateFormatter *)shortDateFormatter
{
    static NSDateFormatter *shortDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shortDateFormatter = [[NSDateFormatter alloc] init];
        [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    });
    
    return shortDateFormatter;
}

+ (NSDateFormatter *)shortDateTimeFormatter
{
    static NSDateFormatter *longDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [longDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    });
    
    return longDateFormatter;
}

+ (NSDateFormatter *)spellOutDateTimeFormatter
{
    static NSDateFormatter *longDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        longDateFormatter = [[NSDateFormatter alloc] init];
        [longDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [longDateFormatter setTimeStyle:NSDateFormatterShortStyle];
        longDateFormatter.doesRelativeDateFormatting = YES;
    });

    return longDateFormatter;
}

+ (NSString *)nonNilImageDataIdentifier:(id<ZMConversationMessage>)message
{
    NSString *identifier = message.imageMessageData.imageDataIdentifier;
    if (! identifier) {
        ZMLogWarn(@"Image cache key is nil!");
        return [NSString stringWithFormat:@"nonnil-%p", message.imageMessageData.imageData];
    }
    return identifier;
}

+ (BOOL)canBePrefetched:(id<ZMConversationMessage>)message
{
    return [Message isImageMessage:message] ||
           [Message isFileTransferMessage:message] ||
           [Message isTextMessage:message];
}

@end
