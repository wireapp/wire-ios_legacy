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


#import "ConversationListViewController+StartUI.h"
#import "Analytics.h"
#import "StartUIViewController.h"
#import "WireSyncEngine+iOS.h"
#import "ZClientViewController.h"

#import "Wire-Swift.h"

@import MobileCoreServices;

@interface ConversationListViewController (StartUI)

@end

typedef void (^ConversationCreatedBlock)(ZMConversation *);

@implementation ConversationListViewController (StartUI)

- (void)withConversationForUsers:(NSSet<ZMUser *>*)users callback:(ConversationCreatedBlock)onConversationCreated {
    
    [self dismissPeoplePickerWithCompletionBlock:^{
        if (users.count == 1) {
            
            ZMUser *user = users.anyObject;
            if ([user respondsToSelector:@selector(oneToOneConversation)]) {
                ZMConversation __block *oneToOneConversation = nil;
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    oneToOneConversation = user.oneToOneConversation;
                } completionHandler:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        onConversationCreated(oneToOneConversation);
                    });
                }];
            }
        }
        else if (users.count > 1) {
            
            ZMConversation __block *conversation = nil;
            [[ZMUserSession sharedSession] enqueueChanges:^{
                Team *team = ZMUser.selfUser.team;

                conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                     withParticipants:users.allObjects
                                                                               inTeam:team];
            } completionHandler:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    onConversationCreated(conversation);
                });
            }];
        }
    }];
}

#pragma mark - People picker delegate

- (void)startUI:(StartUIViewController *)startUI didSelectUsers:(NSSet *)users
{    
    if (users.count == 0) {
        return;
    }
    
    [self withConversationForUsers:users callback:^(ZMConversation *conversation) {
        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                    focusOnView:YES
                                                                       animated:YES];
    }];
}

- (void)startUI:(StartUIViewController *)startUI didSelectConversation:(ZMConversation *)conversation
{
    [self dismissPeoplePickerWithCompletionBlock:^{
        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                    focusOnView:YES
                                                                       animated:YES];
    }];
}

- (void)startUI:(StartUIViewController *)startUI createConversationWithUsers:(NSSet<ZMUser *> *)users name:(NSString *)name allowGuests:(BOOL)allowGuests enableReceipts:(BOOL)enableReceipts
{
    if (self.presentedViewController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self createConversationWithUsers:users name:name allowGuests:allowGuests enableReceipts:enableReceipts];
        }];
    }
    else {
        [self createConversationWithUsers:users name:name allowGuests:allowGuests enableReceipts:enableReceipts];
    }
}

- (void)createConversationWithUsers:(NSSet<ZMUser *> *)users name:(NSString *)name allowGuests:(BOOL)allowGuests enableReceipts:(BOOL)enableReceipts
{
    __block ZMConversation *conversation = nil;
    [ZMUserSession.sharedSession enqueueChanges:^{
        conversation = [ZMConversation insertGroupConversationIntoUserSession:ZMUserSession.sharedSession
                                                             withParticipants:users.allObjects
                                                                         name:name
                                                                       inTeam:ZMUser.selfUser.team
                                                                  allowGuests: allowGuests
                                                                 readReceipts:enableReceipts];
    } completionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ZClientViewController.sharedZClientViewController selectConversation:conversation focusOnView:YES animated:YES];
        });
    }];
}

@end
