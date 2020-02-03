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


/// Private material for conversationContentViewController.

#import "ConversationContentViewController.h"

@import WireSyncEngine;

NS_ASSUME_NONNULL_BEGIN

@class MessagePresenter;
@class FLAnimatedImageView;
@class ConversationTableViewDataSource;
@class DeletionDialogPresenter;
@class UserConnectionViewController;
@protocol SelectableView;
@protocol ZMUserSessionInterface;

@interface ConversationContentViewController ()

/// The cell whose tools are expanded in the UI. Setting this automatically triggers the expanding in the UI.
@property (nonatomic, strong, readwrite, nullable) id<ZMConversationMessage> messageWithExpandedTools;

@property (nonatomic) MessagePresenter* messagePresenter;

@property (nonatomic, nullable) id<ZMConversationMessage> expectedMessageToShow;
@property (nonatomic, copy, nullable) void (^onMessageShown)(UIView *);
@property (nonatomic, nullable, weak) UITableViewCell<SelectableView> *pinchImageCell;

@property (nonatomic, nullable) FLAnimatedImageView *pinchImageView;
@property (nonatomic, nullable) UIView *dimView;
@property (nonatomic) CGPoint initialPinchLocation;

@property (nonatomic) DeletionDialogPresenter *deletionDialogPresenter;

@property (nonatomic, nullable) id<ZMUserSessionInterface> session;

@property (nonatomic) UserConnectionViewController *connectionViewController;

@property (nonatomic, assign) BOOL wasScrolledToBottomAtStartOfUpdate;
@property (nonatomic, nullable) NSObject *activeMediaPlayerObserver;
@property (nonatomic, nullable) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) NSMutableDictionary *cachedRowHeights;
@property (nonatomic) BOOL hasDoneInitialLayout;
@property (nonatomic) BOOL onScreen;
@property (nonatomic, nullable) id<ZMConversationMessage> messageVisibleOnLoad;
@property (nonatomic, readwrite) ZMConversation *conversation;


- (void)removeHighlightsAndMenu;
- (void)setConversationHeaderView:(UIView *)headerView;
- (void)updateVisibleMessagesWindow;

@end

NS_ASSUME_NONNULL_END
