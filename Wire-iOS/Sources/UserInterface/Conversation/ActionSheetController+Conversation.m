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


#import <Classy/Classy.h>

@import WireExtensionComponents;
#import "ActionSheetController+Conversation.h"
#import "ZMConversation+Actions.h"
#import "WireSyncEngine+iOS.h"
#import "Analytics.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIFont+MagicAccess.h"
#import "Wire-Swift.h"
#import "ZClientViewController.h"

@import WireUtilities;

@implementation ActionSheetController (Conversation)

+ (ActionSheetController *)dialogForUnknownClientsForUsers:(NSSet<ZMUser *> *)users completion:(void (^)(BOOL sendAnywayPressed, BOOL showDetailsPressed))completion
{
    ActionSheetController *actionSheetController =
    [[ActionSheetController alloc] initWithTitle:nil
                                          layout:ActionSheetControllerLayoutAlert
                                           style:self.defaultStyle
                                    dismissStyle:ActionSheetControllerDismissStyleBackground];
    
    NSString *userNames = [[[users mapWithBlock:^(ZMUser *user) {
        return user.displayName;
    }] allObjects] componentsJoinedByString:@", "];
 
    NSString *titleFormat = users.count <= 1 ? NSLocalizedString(@"meta.degraded.degradation_reason_message.singular", @"") : NSLocalizedString(@"meta.degraded.degradation_reason_message.plural", @"");
    NSString *messageTitle = [NSString stringWithFormat:titleFormat, userNames, nil];
    NSString *showActionTitle = NSLocalizedString(@"meta.degraded.show_device_button", nil);

    actionSheetController.messageTitle = messageTitle;
    actionSheetController.message = NSLocalizedString(@"meta.degraded.dialog_message", @"");
    actionSheetController.iconImage = [WireStyleKit imageOfShieldnotverified];

    [actionSheetController addAction:[SheetAction actionWithTitle:showActionTitle
                                                         iconType:ZetaIconTypeNone
                                                            style:SheetActionStyleCancel
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(NO, YES);
                                                          }]];

    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.degraded.send_anyway_button", nil)
                                                         iconType:ZetaIconTypeNone
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(YES, NO);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetControllerStyle)defaultStyle
{
    return ColorScheme.defaultColorScheme.variant == ColorSchemeVariantLight
    ? ActionSheetControllerStyleLight
    : ActionSheetControllerStyleDark;
}

@end
