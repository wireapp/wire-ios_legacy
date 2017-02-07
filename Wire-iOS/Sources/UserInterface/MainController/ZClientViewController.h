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


#import <UIKit/UIKit.h>
#import "BackgroundViewController.h"


@class ZClientViewControllerConversationDelegate;
@class ZMUserSession;
@class ConversationViewController;
@class ConversationListViewController;
@class ZMConversation;
@class VoiceChannelV2;
@class SplitViewController;
@class UserClient;
@class ZMUser;


@interface ZClientViewController : UIViewController

@property (nonatomic, readonly) BackgroundViewController *backgroundViewController;
@property (nonatomic, readonly) ConversationListViewController *conversationListViewController;
@property (nonatomic, readonly) UIViewController *conversationRootViewController;

@property (nonatomic, readonly) ZMConversation *currentConversation;

@property (nonatomic, readonly) BOOL isConversationViewVisible;

@property (nonatomic, readonly) ZMUserSession *context;
@property (nonatomic) BOOL isComingFromRegistration;

@property (nonatomic, readonly) SplitViewController *splitViewController;

+ (instancetype)sharedZClientViewController;

/**
 * Select a conversation and move the focus to the conversation view.
 *
 * @return YES if it will actually switch, NO if the conversation is already selected.
 */
- (void)selectConversation:(ZMConversation *)conversation focusOnView:(BOOL)focus animated:(BOOL)animated;
- (void)selectConversation:(ZMConversation *)conversation
               focusOnView:(BOOL)focus
                  animated:(BOOL)animated
                completion:(dispatch_block_t)completion;

/**
 * Open the user clients detail screen
 */
- (void)openDetailScreenForUserClient:(UserClient *)client;

/**
 * Open the user clients detail screen
 */
- (void)openDetailScreenForConversation:(ZMConversation *)conversation;

/**
 * Open the user client list screen
 */
- (void)openClientListScreenForUser:(ZMUser *)user;

/**
 * Select the connection inbox and optionally move focus to it.
 */
- (BOOL)selectIncomingContactRequestsAndFocusOnView:(BOOL)focus;

/**
 * Exit the connection inbox.  This contains special logic for reselecting another conversation etc when you
 * have no more connection requests.
 */
- (void)hideIncomingContactRequestsWithCompletion:(dispatch_block_t)completion;

- (void)transitionToListAnimated:(BOOL)animated completion:(dispatch_block_t)completion;

@end
