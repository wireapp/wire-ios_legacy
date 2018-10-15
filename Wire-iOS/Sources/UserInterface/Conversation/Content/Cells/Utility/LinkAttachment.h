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

typedef NS_ENUM(NSUInteger, LinkAttachmentType) {
    LinkAttachmentTypeNone = 0,
    LinkAttachmentTypeSoundcloudTrack,
    LinkAttachmentTypeSoundcloudSet,
    LinkAttachmentTypeYoutubeVideo
};



/// AttachmentURL is describing an URL which is a sub part of an NSString.
@interface LinkAttachment : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)URL range:(NSRange)range string:(NSString *)string NS_DESIGNATED_INITIALIZER;

/// Returns the range of the URL in the text which it's a part of.
@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSString *string;
@property (nonatomic, readonly) LinkAttachmentType type;
@property (nonatomic, readonly) NSURL *URL;

@end
