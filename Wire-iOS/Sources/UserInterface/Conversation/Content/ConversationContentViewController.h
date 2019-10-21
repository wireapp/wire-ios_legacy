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
#import "ConversationContentViewControllerDelegate.h"


@class ZMConversation;
@class ConversationMediaController;
@class UpsideDownTableView;
@class UserSearchResultsViewController;
@class ConversationTableViewDataSource;
@class MediaPlaybackManager;

@protocol ZMUserSessionInterface;

/// The main conversation view controller
@interface ConversationContentViewController : UIViewController

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, weak, nullable) id <ConversationContentViewControllerDelegate> delegate;
@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic) CGFloat bottomMargin;
@property (nonatomic, readonly) BOOL isScrolledToBottom;
@property (nonatomic, weak, nullable) ConversationMediaController *mediaController;
@property (nonatomic, nonnull) UpsideDownTableView *tableView;
@property (nonatomic) UIView *bottomContainer;
@property (nonatomic) NSArray<NSString *> *searchQueries;
@property (nonatomic) UserSearchResultsViewController *mentionsSearchResultsViewController;
@property (nonatomic, nullable) ConversationTableViewDataSource* dataSource;

- (instancetype)initWithConversation:(ZMConversation *)conversation
                mediaPlaybackManager:(MediaPlaybackManager * _Nullable)mediaPlaybackManager
                             session:(id<ZMUserSessionInterface> _Nullable)session;
- (instancetype)initWithConversation:(ZMConversation *)conversation
                             message:(id<ZMConversationMessage>)message
                mediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager
                             session:(id<ZMUserSessionInterface>) session NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (void)updateTableViewHeaderView;
- (void)highlightMessage:(id<ZMConversationMessage>)message;

@end

@interface ConversationContentViewController (EditMessages)

- (void)didFinishEditingMessage:(id<ZMConversationMessage>)message;
NS_ASSUME_NONNULL_END

@end
