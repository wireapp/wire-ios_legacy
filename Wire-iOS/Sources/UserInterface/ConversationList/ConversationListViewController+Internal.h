//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

@class PermissionDeniedViewController;
@class ConversationActionController;
@class ArchivedListViewController;

@interface ConversationListViewController ()

@property (nonatomic, nonnull) UILabel *noConversationLabel;
@property (nonatomic, nullable) PermissionDeniedViewController *pushPermissionDeniedViewController;
@property (nonatomic, nullable) ConversationActionController *actionsController;
@property (nonatomic) BOOL viewDidAppearCalled;

@property (readwrite, nonatomic, nonnull) UIView *contentContainer;

@property (nonatomic, nonnull) id userObserverToken;
@property (nonatomic, nonnull) id allConversationsObserverToken;
@property (nonatomic, nonnull) id connectionRequestsObserverToken;
@property (nonatomic, nonnull) id initialSyncObserverToken;

@property (nonatomic) ZMConversation *selectedConversation;
@property (nonatomic) ConversationListState state;

@property (nonatomic, weak) id<UserProfile> userProfile;
@property (nonatomic) NSObject *userProfileObserverToken;

@property (nonatomic) ConversationListContentController *listContentController;
@property (nonatomic) ConversationListBottomBarController *bottomBarController;

@property (nonatomic) ConversationListTopBarViewController *topBarViewController;
@property (nonatomic) NetworkStatusViewController *networkStatusViewController;

/// for NetworkStatusViewDelegate
@property (nonatomic) BOOL shouldAnimateNetworkStatusView;

@property (nonatomic, nullable) UIView *conversationListContainer;
@property (nonatomic) ConversationListOnboardingHint *onboardingHint;

@property (nonatomic) NSLayoutConstraint *bottomBarBottomOffset;
@property (nonatomic) NSLayoutConstraint *bottomBarToolTipConstraint;

@property (nonatomic) CGFloat contentControllerBottomInset;

- (ArchivedListViewController * _Nonnull)createArchivedListViewController;
- (void)updateBottomBarSeparatorVisibilityWithContentController:(ConversationListContentController * _Nonnull)controller;
- (void)setSelectedConversation:(ZMConversation * _Nonnull)conversation;
- (void)requestSuggestedHandlesIfNeeded;

@end
