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


#import <Foundation/Foundation.h>
#import <zmessaging/zmessaging.h>
#import "Message.h"

@class ConversationCellLayoutProperties;
@class LinkAttachment;

@interface NSAttributedString (FormatLinkAttachments)
+ (NSAttributedString *)formattedStringWithLinkAttachments:(NSArray <LinkAttachment *>*)linkAttachments
                                                forMessage:(id<ZMTextMessageData>)message
                                                   isGiphy:(BOOL)isGiphy;
@end

@interface Message (Formatting)
+ (NSArray *)linkAttachments:(id<ZMTextMessageData>)message;

/// This method needs to be called as soon as the text color configuration got changed: Magic changes cause of rotation for instance
+ (void)invalidateTextColorConfiguration;

@end
