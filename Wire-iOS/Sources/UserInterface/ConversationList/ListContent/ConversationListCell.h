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


#import "SwipeMenuCollectionCell.h"

@class ZMConversation;
@class ConversationListItemView;
@protocol ConversationListCellDelegate;

static const CGFloat MaxVisualDrawerOffsetRevealDistance = 21;

@interface ConversationListCell : SwipeMenuCollectionCell

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic, readonly) ConversationListItemView *itemView;
@property (nonatomic, weak) id <ConversationListCellDelegate> delegate;
- (void)updateAppearance;
- (CGSize)sizeInCollectionViewSize:(CGSize)collectionViewSize;
+ (void)invalidateCachedCellSize;
@end

@protocol ConversationListCellDelegate <NSObject>

- (void)conversationListCellOverscrolled:(ConversationListCell *)cell;
- (void)conversationListCellJoinCallButtonTapped:(ConversationListCell *)cell;

@end
