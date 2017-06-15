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
#import "Analytics+iOS.h"
#import "StartUIViewController.h"
#import "WireSyncEngine+iOS.h"
#import "CameraViewController.h"
#import "ZClientViewController.h"

#import "Wire-Swift.h"

@interface ConversationListViewController (StartUI) <CameraViewControllerDelegate>

@end

@implementation ConversationListViewController (StartUI)

#pragma mark - People picker delegate

- (void)startUI:(StartUIViewController *)startUI didSelectUsers:(NSSet *)users forAction:(StartUIAction)action
{
    [[Analytics shared] tagScreen:@"MAIN"];
    
    if (users.count == 0) {
        [[Analytics shared] tagSearchAbortedWithSource:AnalyticsEventSourceUnspecified];
        
        return;
    }
    BOOL call = NO;
    BOOL videoCall = NO;
    
    Team *team = ZMUser.selfUser.team;
    
    switch (action) {
        case StartUIActionCreateOrOpenConversation:
        {
            [self dismissPeoplePickerWithCompletionBlock:^{
                __block ZMConversation *conversation = nil;
                
                if (users.count == 1) {
                    ZMUser *user = users.anyObject;
                    [[ZMUserSession sharedSession] enqueueChanges:^{
                        conversation = [user oneToOneConversationInTeam:team];
                    } completionHandler:^{
                        [Analytics.shared tagOpenedExistingConversationWithType:conversation.conversationType];
                        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                    focusOnView:YES
                                                                                       animated:YES];
                    }];
                }
                else {
                    
                    [[ZMUserSession sharedSession] enqueueChanges:^{
                        conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                             withParticipants:users.allObjects
                                                                                       inTeam:team];
                    } completionHandler:^{
                        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                    focusOnView:YES
                                                                                       animated:YES];
                        
                        AnalyticsGroupConversationEvent *event = [AnalyticsGroupConversationEvent eventForCreatedGroupWithContext:CreatedGroupContextStartUI
                                                                                                                 participantCount:conversation.activeParticipants.count]; // Include self
                        [[Analytics shared] tagEventObject:event];
                    }];
                }
            }];
        }
            break;
        case StartUIActionVideoCall:
            call = YES;
            videoCall = YES;
            break;
        case StartUIActionCall:
            call = YES;
            videoCall = NO;
            break;
            break;
        case StartUIActionPostPicture:
        {
            self.startUISelectedUsers = users;
            CameraViewController *cameraViewController = [[CameraViewController alloc] init];
            cameraViewController.savePhotosToCameraRoll = YES;
            cameraViewController.delegate = self;
            
            if (users.count == 1) {
                ZMUser *user = users.anyObject;
                
                cameraViewController.previewTitle = [user.displayName uppercasedWithCurrentLocale];
            }
            
            [self presentViewController:cameraViewController animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
    
    if (call) {
        [self dismissPeoplePickerWithCompletionBlock:^{
            if (users.count == 1) {
                __block ZMConversation *conversation = nil;
                ZMUser *user = users.anyObject;

                [[ZMUserSession sharedSession] enqueueChanges:^{
                    conversation = [user oneToOneConversationInTeam:team];
                } completionHandler:^{
                    [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                focusOnView:YES
                                                                                   animated:YES];
                    @weakify(self);
                    self.startCallToken =
                    [conversation onCreatedRemotely:^{
                        @strongify(self);
                        if (videoCall) {
                            [conversation startVideoCallWithCompletionHandler:nil];
                        }
                        else {
                            [conversation startAudioCallWithCompletionHandler:nil];
                        }
                        self.startCallToken = nil;
                    }];
                }];
            }
            else if (users.count > 1) {
                
                ZMConversation __block *conversation = nil;
                
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                         withParticipants:users.allObjects
                                                                                   inTeam:team];
                } completionHandler:^{
                    
                    [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                focusOnView:YES
                                                                                   animated:YES];
                    
                    @weakify(self);
                    self.startCallToken =
                    [conversation onCreatedRemotely:^{
                        @strongify(self);
                        [conversation startAudioCallWithCompletionHandler:nil];
                        self.startCallToken = nil;
                    }];
                    
                    AnalyticsGroupConversationEvent *event = [AnalyticsGroupConversationEvent eventForCreatedGroupWithContext:CreatedGroupContextStartUI
                                                                                                             participantCount:conversation.activeParticipants.count]; // Include self
                    [[Analytics shared] tagEventObject:event];
                }];
            }
        }];
    }
    
    [[Analytics shared] tagEventObject:[AnalyticsSearchResultEvent eventForSearchResultUsed:YES participantCount:[users count]]];
}

- (void)startUIDidCancel:(StartUIViewController *)startUI
{
    [[Analytics shared] tagScreen:@"MAIN"];
    [[Analytics shared] tagSearchAbortedWithSource:AnalyticsEventSourceUnspecified];
    
    [self dismissPeoplePickerWithCompletionBlock:nil];
}

- (void)startUI:(StartUIViewController *)startUI didSelectConversation:(ZMConversation *)conversation
{
    [Analytics.shared tagOpenedExistingConversationWithType:conversation.conversationType];

    [self dismissPeoplePickerWithCompletionBlock:^{
        [[Analytics shared] tagScreen:@"MAIN"];
        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                    focusOnView:YES
                                                                       animated:YES];
    }];
}

#pragma mark - CameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(CameraViewController *)cameraViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)cameraViewController:(CameraViewController *)cameraViewController didPickImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata
{
    Team *team = ZMUser.selfUser.team;

    [self dismissViewControllerAnimated:YES completion:^() {
        [self dismissPeoplePickerWithCompletionBlock:^{
            
            if (self.startUISelectedUsers.count == 1) {
                
                ZMUser *user = self.startUISelectedUsers.anyObject;
                ZMConversation *oneToOneConversation = [user oneToOneConversationInTeam:team];
                
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    [oneToOneConversation appendMessageWithImageData:imageData];
                } completionHandler:^{
                    [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:oneToOneConversation];
                    
                    [[Analytics shared] tagMediaSentPictureInConversation:oneToOneConversation
                                                                 metadata:metadata];
                    [[ZClientViewController sharedZClientViewController] selectConversation:oneToOneConversation
                                                                                focusOnView:YES
                                                                                   animated:YES];
                }];
                self.startUISelectedUsers = nil;
            }
            else if (self.startUISelectedUsers.count > 1) {
                
                ZMConversation __block *conversation = nil;
                @weakify(self);
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    conversation = [ZMConversation insertGroupConversationIntoUserSession:[ZMUserSession sharedSession]
                                                                         withParticipants:self.startUISelectedUsers.allObjects
                                                                                   inTeam:team];
                } completionHandler:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[ZMUserSession sharedSession] enqueueChanges:^{
                            [conversation appendMessageWithImageData:imageData];
                        } completionHandler:^{
                            [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:conversation];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                            focusOnView:YES
                                                                                               animated:YES];
                            });
                        }];
                    });
                    
                    @strongify(self);
                    AnalyticsGroupConversationEvent *event = [AnalyticsGroupConversationEvent eventForCreatedGroupWithContext:CreatedGroupContextStartUI
                                                                                                             participantCount:conversation.activeParticipants.count]; // Include self
                    [[Analytics shared] tagEventObject:event];
                    
                    self.startUISelectedUsers = nil;
                }];
            }
        }];
    }];
    
}

@end
