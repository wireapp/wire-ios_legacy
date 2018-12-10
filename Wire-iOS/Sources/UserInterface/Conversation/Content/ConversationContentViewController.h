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
#import "Constants.h"
#import "ConversationMessageWindowTableViewAdapter.h"

@class ZMConversation;
@class ConversationMediaController;
@class UpsideDownTableView;
@class UserSearchResultsViewController;

/// The main conversation view controller
@interface ConversationContentViewController : UIViewController

@property (nonatomic, weak) id <ConversationContentViewControllerDelegate> delegate;
@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic) CGFloat bottomMargin;
@property (nonatomic, readonly) BOOL isScrolledToBottom;
@property (nonatomic, weak) ConversationMediaController *mediaController;
@property (nonatomic) UpsideDownTableView *tableView;
@property (nonatomic) UIView *bottomContainer;
@property (nonatomic) NSArray<NSString *> *searchQueries;
@property (nonatomic) UserSearchResultsViewController *mentionsSearchResultsViewController;
@property (nonatomic, readonly) ConversationMessageWindowTableViewAdapter *conversationMessageWindowTableViewAdapter;

- (instancetype)initWithConversation:(ZMConversation *)conversation;
- (instancetype)initWithConversation:(ZMConversation *)conversation message:(id<ZMConversationMessage>)message NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (void)updateTableViewHeaderView;
- (BOOL)displaysMessage:(id<ZMConversationMessage>)message;
- (void)highlightMessage:(id<ZMConversationMessage>)message;

@end

@interface ConversationContentViewController (EditMessages)

- (void)editLastMessage;
- (void)didFinishEditingMessage:(id<ZMConversationMessage>)message;

@end
