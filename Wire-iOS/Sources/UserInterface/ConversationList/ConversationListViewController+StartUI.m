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
#import "CameraViewController.h"
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
                
                AnalyticsGroupConversationEvent *event = [AnalyticsGroupConversationEvent eventForCreatedGroupWithContext:CreatedGroupContextStartUI
                                                                                                         participantCount:conversation.activeParticipants.count]; // Include self
                [[Analytics shared] tagEventObject:event];
            }];
        }
    }];
}

#pragma mark - People picker delegate

- (void)startUI:(StartUIViewController *)startUI didSelectUsers:(NSSet *)users forAction:(StartUIAction)action
{    
    if (users.count == 0) {
        [[Analytics shared] tagSearchAbortedWithSource:AnalyticsEventSourceUnspecified];
        
        return;
    }
    
    BOOL videoCall = NO;
    
    switch (action) {
        case StartUIActionCreateOrOpenConversation:
        {
            [self withConversationForUsers:users callback:^(ZMConversation *conversation) {
                [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                            focusOnView:YES
                                                                               animated:YES];
            }];
        }
            break;
        case StartUIActionVideoCall:
        {
            videoCall = YES;
            // fallthrough
        }
        case StartUIActionCall:
        {
            [self dismissPeoplePickerWithCompletionBlock:^{
                if (users.count == 1) {
                    __block ZMConversation *conversation = nil;
                    ZMUser *user = users.anyObject;
                    
                    if ([user respondsToSelector:@selector(oneToOneConversation)]) {
                        [[ZMUserSession sharedSession] enqueueChanges:^{
                            conversation = user.oneToOneConversation;
                        } completionHandler:^{
                            [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                        focusOnView:YES
                                                                                           animated:YES];
                            @weakify(self);
                            self.startCallToken =
                            [conversation onCreatedRemotely:^{
                                @strongify(self);
                                if (videoCall) {
                                    [conversation startVideoCall];
                                }
                                else {
                                    [conversation startAudioCall];
                                }
                                self.startCallToken = nil;
                            }];
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
                        
                        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                    focusOnView:YES
                                                                                       animated:YES];
                        
                        @weakify(self);
                        self.startCallToken =
                        [conversation onCreatedRemotely:^{
                            @strongify(self);
                            [conversation startAudioCall];
                            self.startCallToken = nil;
                        }];
                        
                        AnalyticsGroupConversationEvent *event = [AnalyticsGroupConversationEvent eventForCreatedGroupWithContext:CreatedGroupContextStartUI
                                                                                                                 participantCount:conversation.activeParticipants.count]; // Include self
                        [[Analytics shared] tagEventObject:event];
                    }];
                }
            }];
        }
            break;
        case StartUIActionPostPicture:
        {
            CameraPicker *picker = [[CameraPicker alloc] initWithTarget:self];
            picker.didPickImage = ^(UIImage *image) {
                NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
                [self withConversationForUsers:users callback:^(ZMConversation *conversation) {
                    [[ZMUserSession sharedSession] enqueueChanges:^{
                        [conversation appendMessageWithImageData:imageData];
                    } completionHandler:^{
                        [[Analytics shared] tagMediaAction:ConversationMediaActionPhoto inConversation:conversation];
                        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:conversation];
                        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                    focusOnView:YES
                                                                                       animated:YES];
                    }];
                }];
            };
            picker.didPickVideo = ^(NSURL *videoURL) {
                [self withConversationForUsers:users callback:^(ZMConversation *conversation) {
                    [FileMetaDataGenerator metadataForFileAtURL:videoURL
                                                            UTI:(NSString *)kUTTypeMovie
                                                           name:@"Recording"
                                                     completion:^(ZMFileMetadata * metadata) {
                                                         [conversation appendMessageWithFileMetadata:metadata];
                                                         [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                                                                     focusOnView:YES
                                                                                                                        animated:YES];
                                                     }];
                }];
            };
            
            [picker pick];
        }
            break;
        default:
            break;
    }
    
    [[Analytics shared] tagEventObject:[AnalyticsSearchResultEvent eventForSearchResultUsed:YES participantCount:[users count]]];
}

- (void)startUIDidCancel:(StartUIViewController *)startUI
{
    [[Analytics shared] tagSearchAbortedWithSource:AnalyticsEventSourceUnspecified];
    
    [self dismissPeoplePickerWithCompletionBlock:nil];
}

- (void)startUI:(StartUIViewController *)startUI didSelectConversation:(ZMConversation *)conversation
{
    [Analytics.shared tagOpenedExistingConversationWithType:conversation.conversationType];

    [self dismissPeoplePickerWithCompletionBlock:^{
        [[ZClientViewController sharedZClientViewController] selectConversation:conversation
                                                                    focusOnView:YES
                                                                       animated:YES];
    }];
}

@end
