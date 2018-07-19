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


#import "UIActivityViewController+Invite.h"
#import "ShareItemProvider.h"
#import "Analytics.h"

NSString *NSStringFromGenericInviteContext(GenericInviteContext logicalContext);
NSString *NSStringFromGenericInviteContext(GenericInviteContext logicalContext) {
    switch (logicalContext) {
        case GenericInviteContextConversationList:
            return @"conversation_list";
        case GenericInviteContextInvitesSearch:
            return @"invites_search";
        case GenericInviteContextStartUIBanner:
            return @"startui_search";
        case GenericInviteContextStartUISearch:
            return @"startui_banner";
        case GenericInviteContextSettings:
            return @"settings";
    }
}

@implementation UIActivityViewController (Invite)

+ (instancetype)shareInviteActivityViewControllerWithCompletion:(UIActivityViewControllerCompletionWithItemsHandler)completion logicalContext:(GenericInviteContext)logicalContext
{
    ShareItemProvider *item = [[ShareItemProvider alloc] initWithPlaceholderItem:@""];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:nil];
    activity.excludedActivityTypes = @[UIActivityTypeAirDrop];
    activity.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completion) {
            completion(activityType, completed, returnedItems, activityError);
        }
    };

    return activity;
}

@end
