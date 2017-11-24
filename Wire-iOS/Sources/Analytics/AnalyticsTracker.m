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


#import "AnalyticsTracker.h"
#import "Analytics.h"

NSString *const AnalyticsContextKey = @"context";
NSString *const AnalyticsMethodKey = @"method";

#pragma mark - AnalyticsContext

NSString *const AnalyticsContextSignIn = @"sign_in";
NSString *const AnalyticsContextProfile = @"profile";
NSString *const AnalyticsContextPostLogin = @"post_login";
NSString *const AnalyticsContextConversation = @"conversation";
NSString *const AnalyticsContextRegistrationPhone = @"phone";
NSString *const AnalyticsContextRegistrationEmail = @"email";

#pragma mark - AnalyticsEventTypes

NSString *const AnalyticsEventTypePermissions = @"PermissionRequested";
NSString *const AnalyticsEventTypeMedia = @"Media";

#pragma mark - AnalyticsEventTypePermissions

NSString *const AnalyticsEventTypePermissionsCategoryKey = @"category";
NSString *const AnalyticsEventTypePermissionsStateKey = @"state";

NSString *const AnalyticsEventTypePermissionsCategoryCamera = @"camera";
NSString *const AnalyticsEventTypePermissionsCategoryPushNotifications = @"pushNotifications";

NSString *const AnalyticsEventTypePermissionsStateAllowed = @"allowed";
NSString *const AnalyticsEventTypePermissionsStateDenied = @"denied";

#pragma mark - AnalyticsEventTypeMedia

NSString *const AnalyticsEventMediaLinkTypeKey = @"LinkType";
NSString *const AnalyticsEventMediaLinkTypeNone = @"WWW";
NSString *const AnalyticsEventMediaLinkTypeYouTube = @"YouTube";
NSString *const AnalyticsEventMediaLinkTypeSoundCloud = @"SoundClound";

NSString *const AnalyticsEventMediaActionKey = @"action";
NSString *const AnalyticsEventMediaActionPosted = @"post";
NSString *const AnalyticsEventMediaActionVisited = @"visit";

NSString *const AnalyticsEventConversationTypeKey = @"type";
NSString *const AnalyticsEventConversationTypeGroup = @"group";
NSString *const AnalyticsEventConversationTypeOneToOne = @"1:1";
NSString *const AnalyticsEventConversationTypeUnknown = @"unknown";

#pragma mark - Invitations

NSString *const AnalyticsEventInviteContactListOpened = @"connect.opened_invite_contacts";
NSString *const AnalyticsEventInvitationSentToAddressBook = @"connect.sent_invite_to_contact";
NSString *const AnalyticsEventInvitationSentToAddressBookMethodEmail = @"email";
NSString *const AnalyticsEventInvitationSentToAddressBookMethodPhone = @"phone";
NSString *const AnalyticsEventInvitationSentToAddressBookFromSearch = @"from_search";
NSString *const AnalyticsEventOpenedMenuForGenericInvite = @"connect.opened_generic_invite_menu";
NSString *const AnalyticsEventAcceptedGenericInvite = @"connect.accepted_generic_invite";


@interface AnalyticsTracker ()

@property (nonatomic, copy) NSString *context;

@end

@implementation AnalyticsTracker

+ (instancetype)analyticsTrackerWithContext:(NSString *)context
{
    id tracker = [[self alloc] initWithContext:context];
    return tracker;
}

- (instancetype)initWithContext:(NSString *)context
{
    self = [super init];
    
    if (self) {
    
        self.context = context;
    }
    
    return self;
}

#pragma mark - Tagging Methods

- (void)tagEvent:(NSString *) event
{
    [self tagEvent:event attributes:@{}];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *) attributes
{
    NSMutableDictionary *contextAttributes = [attributes mutableCopy];
    
    if (contextAttributes == nil) {
        contextAttributes = [NSMutableDictionary dictionary];
    }
    
    if (self.context && contextAttributes[AnalyticsContextKey] == nil) {
        
        contextAttributes[AnalyticsContextKey] = self.context;
    }
        
    [[Analytics shared] tagEvent:event attributes:[contextAttributes copy]];
}

@end
