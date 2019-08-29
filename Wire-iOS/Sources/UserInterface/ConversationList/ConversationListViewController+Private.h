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

NS_ASSUME_NONNULL_BEGIN

@class SearchViewController;
@class ConversationListTopBarViewController;
@class NetworkStatusViewController;
@class ConversationListBottomBarController;
@class ConversationListContentController;
@class ConversationListOnboardingHint;

@interface ConversationListViewController (Private)
@property (nonatomic, nullable) SearchViewController *searchViewController;
@property (nonatomic) ConversationListContentController *listContentController;
@property (nonatomic, weak, readonly) id<UserProfile> userProfile;
@property (nonatomic) ConversationListTopBarViewController *topBarViewController;
@property (nonatomic) NetworkStatusViewController *networkStatusViewController;
@property (nonatomic, readonly) ConversationListBottomBarController *bottomBarController;
@property (nonatomic, nullable) UIView *conversationListContainer;
@property (nonatomic, nullable) ConversationListOnboardingHint *onboardingHint;

@property (nonatomic) NSLayoutConstraint *bottomBarBottomOffset;
@property (nonatomic) NSLayoutConstraint *bottomBarToolTipConstraint;

/// for NetworkStatusViewDelegate
@property (nonatomic) BOOL shouldAnimateNetworkStatusView;

@property (nonatomic) BOOL viewDidAppearCalled;

- (void)removeUserProfileObserver;
- (void)updateBottomBarSeparatorVisibilityWithContentController:(ConversationListContentController *)controller;

///TODO: retire after converted to Swift
- (void)setStateValue: (ConversationListState)newState;

@end

NS_ASSUME_NONNULL_END
