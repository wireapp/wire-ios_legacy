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


#import "ConversationListViewController.h"
@import WireSyncEngine;

@class SearchViewController;
@class ConversationListTopBar;
@class NetworkStatusViewController;
@class ConversationListBottomBarController;
@class ConversationListContentController;
@class PermissionDeniedViewController;
@class ConversationActionController;
@class ConversationListTopBar;
@class ConversationListOnboardingHint;

@interface ConversationListViewController ()
@property (nonatomic, nullable) SearchViewController *searchViewController;
@property (nonatomic, nonnull) ConversationListContentController *listContentController;
@property (nonatomic, weak, nullable) id<UserProfile> userProfile;
@property (nonatomic, nonnull) NetworkStatusViewController *networkStatusViewController;

@property (nonatomic, nonnull) UILabel *noConversationLabel;
@property (nonatomic, nullable) PermissionDeniedViewController *pushPermissionDeniedViewController;
@property (nonatomic, nullable) ConversationActionController *actionsController;
@property (nonatomic, null_unspecified) UIView *conversationListContainer;
@property (nonatomic, null_unspecified) ConversationListBottomBarController *bottomBarController;

@property (nonatomic, null_unspecified) ConversationListTopBar *topBar;
@property (nonatomic, null_unspecified) ConversationListOnboardingHint *onboardingHint;

@property (nonatomic, null_unspecified) NSLayoutConstraint *bottomBarBottomOffset;
@property (nonatomic, null_unspecified) NSLayoutConstraint *bottomBarToolTipConstraint;

/// for NetworkStatusViewDelegate
@property (nonatomic) BOOL shouldAnimateNetworkStatusView;
@property (nonatomic) BOOL dataUsagePermissionDialogDisplayed;


- (void)removeUserProfileObserver;
@end

