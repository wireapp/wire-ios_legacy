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


#import <Foundation/Foundation.h>

#import "zmessaging+iOS.h"

@class AnalyticsTracker;
@protocol ConversationCellDelegate;

@interface ConversationMessageWindowTableViewAdapter : NSObject <UITableViewDataSource>

@property (nonatomic) id<ZMConversationMessage> lastUnreadMessage;
@property (nonatomic) id<ZMConversationMessage> selectedMessage;
@property (nonatomic) id<ZMConversationMessage> editingMessage;
@property (nonatomic) AnalyticsTracker *analyticsTracker;
@property (nonatomic, weak) id<ConversationCellDelegate> conversationCellDelegate;
@property (nonatomic) NSArray<NSString *> *searchQueries;

- (instancetype)initWithTableView:(UITableView *)tableView messageWindow:(ZMConversationMessageWindow *)messageWindow;
- (void)expandMessageWindow;
- (void)reconfigureVisibleCellsWithDeletedIndexPaths:(NSSet<NSIndexPath *>*)deletedIndexPaths;
@end
