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
#import "Analytics+iOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WR_ColorScheme.h"
#import "UIFont+MagicAccess.h"
#import "Wire-Swift.h"
#import "ZClientViewController.h"

@import WireUtilities;

@implementation ActionSheetController (Conversation)

+ (ActionSheetController *)dialogForConversationDetails:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style
{
    ZMUser *user = conversation.firstActiveParticipantOtherThanSelf;
    BOOL isConnectionOrOneOnOne = conversation.conversationType == ZMConversationTypeConnection
                               || conversation.conversationType == ZMConversationTypeOneOnOne;

    if (isConnectionOrOneOnOne && nil != user) {
        return [self dialogForConnectionOrOneOnOneConversation:conversation style:style];
    } else {
        ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:conversation.displayName
                                                                                             layout:ActionSheetControllerLayoutList
                                                                                              style:style];
        [actionSheetController addActionsForConversation:conversation];
        return actionSheetController;
    }
}

+ (ActionSheetController *)dialogForConnectionOrOneOnOneConversation:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style
{
    ZMUser *user = conversation.firstActiveParticipantOtherThanSelf;
    Require(nil != user);
    Require(conversation.conversationType == ZMConversationTypeConnection || conversation.conversationType == ZMConversationTypeOneOnOne);

    UserNameDetailViewModel *model = [[UserNameDetailViewModel alloc] initWithUser:user
                                                                      fallbackName:@""
                                                                   addressBookName:BareUserToUser(user).addressBookEntry.cachedName
                                                                 commonConnections:user.totalCommonConnections];

    UserNameDetailView *detailView = [[UserNameDetailView alloc] init];
    [detailView configureWith:model];
    ActionSheetController *controller = [[ActionSheetController alloc] initWithTitleView:detailView
                                                                                  layout:ActionSheetControllerLayoutList
                                                                                   style:style
                                                                            dismissStyle:ActionSheetControllerDismissStyleBackground];
    [controller addActionsForConversation:conversation];
    return controller;
}

- (void)addActionsForConversation:(ZMConversation *)conversation
{
    [self addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.cancel", nil) iconType:ZetaIconTypeNone style:SheetActionStyleCancel handler:^(SheetAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    NSMutableOrderedSet *allowedActions = [NSMutableOrderedSet orderedSetWithArray:@[ConversationActionUnblockUser,
                                                                                     ConversationActionCancelConnectionRequest,
                                                                                     ConversationActionBlockUser,
                                                                                     ConversationActionLeave,
                                                                                     ConversationActionDelete,
                                                                                     ConversationActionUnarchive,
                                                                                     ConversationActionArchive,
                                                                                     ConversationActionUnsilence,
                                                                                     ConversationActionSilence]];
    [allowedActions intersectOrderedSet:conversation.availableActions];
    
    for (ConversationAction *action in allowedActions) {
        [self addAction:[self sheetActionForConversationActionType:action inConversation:conversation]];
    }
}

- (SheetAction *)sheetActionForConversationActionType:(ConversationAction *)conversationAction inConversation:(ZMConversation *)conversation
{
    @weakify(self);
    void (^dismissAndEnqueue)(dispatch_block_t block) = ^(dispatch_block_t block) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:^{
            [[ZMUserSession sharedSession] enqueueChanges:block];
        }];
    };
    
    void (^transitionToListAndEnqueue)(dispatch_block_t block) = ^(dispatch_block_t block) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:^{
            [[ZClientViewController sharedZClientViewController] transitionToListAnimated:YES completion:^{
                [[ZMUserSession sharedSession] enqueueChanges:block];
            }];
        }];
    };
        
    SheetAction *action = nil;
    
    if ([conversationAction isEqualToString:ConversationActionArchive])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.archive", nil)
                            iconType:ZetaIconTypeArchive
                             handler:^(SheetAction *action) {
                                 transitionToListAndEnqueue(^{ conversation.isArchived = YES; });
                                 [Analytics.shared tagArchivedConversation];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionUnarchive])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.unarchive", nil)
                            iconType:ZetaIconTypeArchive
                             handler:^(SheetAction *action) {
                                 transitionToListAndEnqueue(^{ conversation.isArchived = NO; });
                                 [Analytics.shared tagUnarchivedConversation];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionSilence])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.silence.mute", nil)
                            iconType:ZetaIconTypeBellWithStrikethrough
                             handler:^(SheetAction *action) {
                                 dismissAndEnqueue(^{ conversation.isSilenced = YES; });
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionUnsilence])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.silence.unmute", nil)
                            iconType:ZetaIconTypeBellWithStrikethrough
                             handler:^(SheetAction *action) {
                                 dismissAndEnqueue(^{ conversation.isSilenced = NO; });
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionLeave])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.leave", nil)
                            iconType:ZetaIconTypeLeave
                             handler:^(SheetAction *action) {
                                 @strongify(self);
                                 [self pushActionSheetController:
                                  [self dialogForLeavingConversation:conversation style:self.style completion:^(BOOL canceled, BOOL deleteConversation) {
                                     if (canceled) {
                                         [self popActionSheetControllerAnimated:YES completion:nil];
                                     } else {
                                         transitionToListAndEnqueue(^{
                                             if (deleteConversation) {
                                                 [conversation clearMessageHistory];
                                                 [[Analytics shared] tagEventObject:[AnalyticsGroupConversationEvent
                                                                                     eventForDeleteAction:@"delete"
                                                                                     withNumberOfParticipants:conversation.activeParticipants.count]];
                                             }
                                             [conversation removeParticipant:[ZMUser selfUser]];
                                             [[Analytics shared] tagEventObject:[AnalyticsGroupConversationEvent eventForLeaveAction:LeaveGroupActionLeave participantCount:conversation.activeParticipants.count]];
                                         });
                                     }
                                 }] animated:YES completion:nil];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionDelete])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.delete", nil)
                            iconType:ZetaIconTypeDelete
                             handler:^(SheetAction *action) {
                                 @strongify(self);
                                 @weakify(self);
                                 [self pushActionSheetController:[self dialogForDeletingConversation:conversation style:self.style completion:^(BOOL canceled, BOOL leaveConversation) {
                                     @strongify(self);
                                     if (canceled) {
                                         [self popActionSheetControllerAnimated:YES completion:nil];
                                     } else {
                                         transitionToListAndEnqueue(^{
                                             [conversation clearMessageHistory];
                                             
                                             [[Analytics shared] tagEventObject:[AnalyticsGroupConversationEvent
                                                                                 eventForDeleteAction:@"delete"
                                                                                 withNumberOfParticipants:conversation.activeParticipants.count]];
                                             
                                             if (leaveConversation) {
                                                 [conversation removeParticipant:[ZMUser selfUser]];
                                                 
                                                 [[Analytics shared] tagEventObject:[AnalyticsGroupConversationEvent
                                                                                     eventForLeaveAction:LeaveGroupActionLeave
                                                                                     participantCount:conversation.activeParticipants.count]];
                                             }
                                         });
                                     }
                                 }] animated:YES completion:nil];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionBlockUser])
    {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"profile.block_dialog.button_block", nil)
                            iconType:ZetaIconTypeBlock
                             handler:^(SheetAction *action) {
                                 @strongify(self);
                                 [self pushActionSheetController:[ActionSheetController dialogForBlockingUser:conversation.connectedUser style:self.style completion:^(BOOL canceled) {
                                     if (canceled) {
                                         [self popActionSheetControllerAnimated:YES completion:nil];
                                     } else {
                                         transitionToListAndEnqueue(^{ [conversation.connectedUser toggleBlocked]; });
                                     }
                                 }] animated:YES completion:nil];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionUnblockUser]) {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"profile.unblock_button_title", nil)
                            iconType:ZetaIconTypeBlock
                             handler:^(SheetAction *action) {
                                 @strongify(self);
                                 [self pushActionSheetController:[ActionSheetController dialogForBlockingUser:conversation.connectedUser style:self.style completion:^(BOOL canceled) {
                                     if (canceled) {
                                         [self popActionSheetControllerAnimated:YES completion:nil];
                                     } else {
                                         dismissAndEnqueue(^{ [conversation.connectedUser toggleBlocked]; });
                                     }
                                 }] animated:YES completion:nil];
                             }];
    }
    else if ([conversationAction isEqualToString:ConversationActionCancelConnectionRequest]) {
        action =
        [SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.cancel_connection_request", @"")
                            iconType:ZetaIconTypeNone
                             handler:^(SheetAction *action) {
                                 @strongify(self);
                                 [self pushActionSheetController:[ActionSheetController dialogForCancelingConnectionRequestWithUser:conversation.connectedUser style:self.style completion:^(BOOL canceled) {
                                     if (canceled) {
                                         [self popActionSheetControllerAnimated:YES completion:nil];
                                     } else {
                                         dismissAndEnqueue(^{ [conversation.connectedUser cancelConnectionRequest]; });
                                     }
                                 }] animated:YES completion:nil];

        }];
    }
    
    return action;
}

- (ActionSheetController *)dialogForDeletingConversation:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled, BOOL leaveConversation))completion
{
    ActionSheetController *actionSheetController =
    [[ActionSheetController alloc] initWithTitle:conversation.displayName
                                          layout:ActionSheetControllerLayoutAlert
                                           style:style];
    
    actionSheetController.messageTitle = NSLocalizedString(@"meta.menu.delete_content.dialog_title", nil);
    actionSheetController.message = NSLocalizedString(@"meta.menu.delete_content.dialog_message", nil);
    
    if (conversation.conversationType == ZMConversationTypeGroup && [conversation.activeParticipants containsObject:[ZMUser selfUser]]) {
        [actionSheetController addCheckmarkButtonWithConfigurationHandler:^(CheckBoxButton *checkBoxButton) {
            [checkBoxButton setTitle:[NSLocalizedString(@"meta.menu.delete_content.leave_as_well_message", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        }];
    }
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.delete_content.button_cancel", nil) iconType:ZetaIconTypeNone style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES, NO);
    }]];
    
    IconButton *alsoLeaveButton = actionSheetController.checkBoxButtons.firstObject;
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.delete_content.button_delete", nil)
                                                         iconType:ZetaIconTypeNone
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                              completion(NO, alsoLeaveButton.selected);
                                                          }]];
    
    return actionSheetController;
}

- (ActionSheetController *)dialogForLeavingConversation:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled, BOOL deleteConversation))completion
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:conversation.displayName layout:ActionSheetControllerLayoutAlert style:style];
    
    actionSheetController.messageTitle = NSLocalizedString(@"meta.leave_conversation_dialog_title", @"");
    actionSheetController.message = NSLocalizedString(@"meta.leave_conversation_dialog_message", @"");

    NSString *alsoDeleteTitle = NSLocalizedString(@"meta.leave_conversation.delete_content_as_well_message", @"");
    [actionSheetController addCheckmarkButtonWithConfigurationHandler:^(CheckBoxButton *checkBoxButton) {
        [checkBoxButton setTitle:alsoDeleteTitle.uppercasedWithCurrentLocale forState:UIControlStateNormal];
    }];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.leave_conversation_button_cancel", nil) iconType:ZetaIconTypeBell style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES, NO);
    }]];

    IconButton *alsoDeleteButton = actionSheetController.checkBoxButtons.firstObject;
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.leave_conversation_button_leave", nil)
                                                         iconType:ZetaIconTypeBell
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(NO, alsoDeleteButton.selected);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetController *)dialogForBlockingUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:@"" layout:ActionSheetControllerLayoutAlert style:style];
    
    actionSheetController.messageTitle = user.isBlocked ? NSLocalizedString(@"profile.unblock_button_title", nil) :  NSLocalizedString(@"profile.block_dialog.title", nil);
    actionSheetController.message = [NSString stringWithFormat:NSLocalizedString(@"profile.block_dialog.message", nil), user.displayName];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.block_dialog.button_cancel", nil) iconType:ZetaIconTypeBell style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES);
    }]];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.block_dialog.button_block", nil)
                                                         iconType:ZetaIconTypeBell
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(NO);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetController *)dialogForRemovingUser:(ZMUser *)user fromConversation:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:conversation.displayName layout:ActionSheetControllerLayoutAlert style:style];
    
    actionSheetController.messageTitle = NSLocalizedString(@"profile.remove_dialog_title", @"");
    actionSheetController.message = [NSString stringWithFormat:NSLocalizedString(@"profile.remove_dialog_message", @""), user.displayName];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.remove_dialog_button_cancel", nil) iconType:ZetaIconTypeBell style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES);
    }]];
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.remove_dialog_button_remove", nil)
                                                         iconType:ZetaIconTypeNone
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(NO);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetController *)dialogForAcceptingConnectionRequestWithUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL ignored))completion
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:@"" layout:ActionSheetControllerLayoutAlert style:style];
    
    actionSheetController.messageTitle = NSLocalizedString(@"profile.connection_request_dialog.title", nil);
    actionSheetController.message = [NSString stringWithFormat:NSLocalizedString(@"profile.connection_request_dialog.message", nil), user.displayName];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.connection_request_dialog.button_cancel", nil) iconType:ZetaIconTypeNone style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES);
    }]];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.connection_request_dialog.button_connect", nil)
                                                         iconType:ZetaIconTypeNone
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                              if (completion != nil) completion(NO);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetController *)dialogForCancelingConnectionRequestWithUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:@"" layout:ActionSheetControllerLayoutAlert style:style];
    
    actionSheetController.messageTitle = NSLocalizedString(@"profile.cancel_connection_request_dialog.title", nil);
    actionSheetController.message = [NSString stringWithFormat:NSLocalizedString(@"profile.cancel_connection_request_dialog.message", nil), user.displayName];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.cancel_connection_request_dialog.button_no", nil) iconType:ZetaIconTypeNone style:SheetActionStyleCancel handler:^(SheetAction *action) {
        if (completion != nil) completion(YES);
    }]];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"profile.cancel_connection_request_dialog.button_yes", nil)
                                                         iconType:ZetaIconTypeNone
                                                            style:SheetActionStyleDefault
                                                          handler:^(SheetAction *action) {
                                                                if (completion != nil) completion(NO);
                                                          }]];
    
    return actionSheetController;
}

+ (ActionSheetController *)dialogForUnknownClientsForUsers:(NSSet<ZMUser *> *)users style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL sendAnywayPressed, BOOL showDetailsPressed))completion
{
    ActionSheetController *actionSheetController =
    [[ActionSheetController alloc] initWithTitle:nil
                                          layout:ActionSheetControllerLayoutAlert
                                           style:style
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

- (void)addCheckmarkButtonWithConfigurationHandler:(void (^)(CheckBoxButton *checkBoxButton))configurationHandler
{
    NSString *styleClass = nil;
    ColorSchemeVariant colorSchemeVariant;
    if (self.style == ActionSheetControllerStyleLight) {
        styleClass = @"light";
        colorSchemeVariant = ColorSchemeVariantLight;
    } else {
        styleClass = @"dark";
        colorSchemeVariant = ColorSchemeVariantDark;
    }
    
    UIColor *iconColorSelected = [UIColor wr_colorFromColorScheme:ColorSchemeColorIconSelected variant:colorSchemeVariant];
    UIColor *iconColorSelectedBackground = [UIColor wr_colorFromColorScheme:ColorSchemeColorIconBackgroundSelected variant:colorSchemeVariant];
    
    [self addCheckBoxButtonWithConfigurationHandler:^(CheckBoxButton *checkBoxButton) {
        checkBoxButton.cas_styleClass = styleClass;
        [checkBoxButton setIcon:ZetaIconTypeCheckmark withSize:ZetaIconSizeTiny color:[UIColor clearColor] backgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
        [checkBoxButton setIcon:ZetaIconTypeCheckmark withSize:ZetaIconSizeTiny color:iconColorSelected backgroundColor:iconColorSelectedBackground forState:UIControlStateSelected];
        [checkBoxButton addTarget:checkBoxButton action:@selector(toggleSelected:) forControlEvents:UIControlEventTouchUpInside];
         configurationHandler(checkBoxButton);
    }];
}

+ (ActionSheetControllerStyle)defaultStyle
{
    return [[ColorScheme defaultColorScheme] variant] == ColorSchemeVariantLight ? ActionSheetControllerStyleLight : ActionSheetControllerStyleDark;
}

@end
