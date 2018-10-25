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


#import "LinkAttachment.h"



@implementation LinkAttachment

- (instancetype)initWithURL:(NSURL *)URL range:(NSRange)range string:(NSString *)string
{
    self = [super init];
    
    if (self) {
        _URL = URL;
        _range = range;
        _string = string;
        _type = [self linkAttachmentTypeForURL:URL];
    }
    
    return self;
}

- (LinkAttachmentType)linkAttachmentTypeForURL:(NSURL *)URL
{
    LinkAttachmentType linkAttachmentType = LinkAttachmentTypeNone;
    
    NSString *URLString = [URL absoluteString];
    
    if ([self.class regularExpression:self.class.youtubeMatcher matchesString:URLString]) {
        linkAttachmentType = LinkAttachmentTypeYoutubeVideo;
    }
    else if ([self.class regularExpression:self.class.soundcloudSingleTrackMatcher matchesString:URLString]) {
        linkAttachmentType = LinkAttachmentTypeSoundcloudTrack;
    }
    else if ([self.class regularExpression:self.class.soundcloudSetMatcher matchesString:URLString]) {
        linkAttachmentType = LinkAttachmentTypeSoundcloudSet;
    }

    return linkAttachmentType;
}

#pragma mark - Matchers

+ (BOOL)regularExpression:(NSRegularExpression *)regularExpression matchesString:(NSString *)string
{
    return [regularExpression rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)].location != NSNotFound;
}

+ (NSRegularExpression *)soundcloudMatcher
{
    static NSRegularExpression *soundcloudMatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundcloudMatcher = [NSRegularExpression regularExpressionWithPattern:@"^(http://|https://)?(m\\.)?soundcloud\\.com/[a-zA-Z0-9-_]+(/?)$"
                                                                      options:0 error:nil];
    });
    return soundcloudMatcher;
}

+ (NSRegularExpression *)soundcloudSingleTrackMatcher
{
    static NSRegularExpression *soundCloudSingleTrackMatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundCloudSingleTrackMatcher = [NSRegularExpression regularExpressionWithPattern:@"^(http://|https://)?(m\\.)?soundcloud\\.com/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+(/?)$"
                                                                                 options:0 error:nil];
    });
    return soundCloudSingleTrackMatcher;
}

+ (NSRegularExpression *)soundcloudSetMatcher
{
    static NSRegularExpression *soundcloudSetMatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundcloudSetMatcher = [NSRegularExpression regularExpressionWithPattern:@"^(http://|https://)?(m\\.)?soundcloud\\.com/[a-zA-Z0-9-_]+(/sets/[a-zA-Z0-9-_]+/?)$"
                                                                         options:0 error:nil];
    });
    return soundcloudSetMatcher;
}

+ (NSRegularExpression *)soundcloudMobileMatcher
{
    static NSRegularExpression *soundcloudMobileMatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        soundcloudMobileMatcher = [NSRegularExpression regularExpressionWithPattern:@"^(http://|https://)?m\\.soundcloud\\.com/[a-zA-Z0-9-_/]+(/?)$"
                                                                            options:0 error:nil];
    });
    return soundcloudMobileMatcher;
}

+ (NSRegularExpression *)youtubeMatcher
{
    static NSRegularExpression *youtubeMatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        youtubeMatcher = [NSRegularExpression regularExpressionWithPattern:@"^(http://|https://)?(www\\.|m\\.)?(youtube\\.com|youtu\\.?be)/.+$"
                                                                   options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return youtubeMatcher;
}

@end
