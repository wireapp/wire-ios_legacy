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


#import "AnalyticsTracker+Media.h"

@implementation AnalyticsTracker (Media)

- (void)tagExternalLinkPostEventForAttachmentType:(LinkAttachmentType)linkAttachmentType
                                 conversationType:(ZMConversationType)conversationType
{
    NSDictionary *attributes = [self attributesForAction:AnalyticsEventMediaActionPosted
                                      linkAttachmentType:linkAttachmentType
                                        conversationType:conversationType];
    [self tagLinkVisitEventWithAttributes:attributes];
}

- (void)tagExternalLinkVisitEventForAttachmentType:(LinkAttachmentType)linkAttachmentType
                                  conversationType:(ZMConversationType)conversationType
{
    NSDictionary *attributes = [self attributesForAction:AnalyticsEventMediaActionVisited
                                      linkAttachmentType:linkAttachmentType
                                        conversationType:conversationType];
    [self tagLinkVisitEventWithAttributes:attributes];
}

- (void)tagLinkVisitEventWithAttributes:(NSDictionary *)attributes
{
    [self tagEvent:AnalyticsEventTypeMedia attributes:attributes];
}

- (NSDictionary *)attributesForAction:(NSString *)action
                   linkAttachmentType:(LinkAttachmentType)linkAttachmentType
                     conversationType:(ZMConversationType)conversationType
{
    return @{
             AnalyticsEventMediaLinkTypeKey: [self.class linkTypeForLinkAttachmentType:linkAttachmentType],
             AnalyticsEventMediaActionKey: action,
             AnalyticsEventConversationTypeKey: [self.class attributeForConversationType:conversationType],
             };
}

+ (NSString *)attributeForConversationType:(ZMConversationType)conversationType
{
    NSString *attribute = nil;
    switch (conversationType) {
        case ZMConversationTypeOneOnOne:
            attribute = AnalyticsEventConversationTypeOneToOne;
            break;
        case ZMConversationTypeGroup:
            attribute = AnalyticsEventConversationTypeGroup;
            break;
        case ZMConversationTypeConnection:
        case ZMConversationTypeInvalid:
        case ZMConversationTypeSelf:
        default:
            attribute = AnalyticsEventConversationTypeUnknown;
            break;
    }
    return attribute;
}

+ (NSString *)linkTypeForLinkAttachmentType:(LinkAttachmentType)linkAttachmentType
{
    NSString *linkType = nil;
    switch (linkAttachmentType) {            
        case LinkAttachmentTypeYoutubeVideo:
            linkType = AnalyticsEventMediaLinkTypeYouTube;
            break;
            
        case LinkAttachmentTypeSoundcloudSet:
        case LinkAttachmentTypeSoundcloudTrack:
            linkType = AnalyticsEventMediaLinkTypeSoundCloud;
            break;
            
        case LinkAttachmentTypeNone:
        default:
            linkType = AnalyticsEventMediaLinkTypeNone;
            break;
    }
    
    return linkType;
}

@end
