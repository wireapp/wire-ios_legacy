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
#import "WireSyncEngine+iOS.h"


@class ConversationListViewModel;
@class ConversationListConnectRequestsItem;

typedef NS_ENUM(NSUInteger, SectionIndex) {
    SectionIndexContactRequests = 0,
    SectionIndexConversations = 1,
    SectionIndexAll = INT_MAX,
};


@protocol ConversationListViewModelDelegate <NSObject>

- (void)listViewModelShouldBeReloaded;
- (void)listViewModel:(ConversationListViewModel *)model didUpdateSectionForReload:(NSUInteger)section;
/// Delegate MUST call the updateBlock in appropriate place (e.g. collectionView performBatchUpdates:) to update the model.
- (void)listViewModel:(ConversationListViewModel *)model didUpdateSection:(NSUInteger)section usingBlock:(dispatch_block_t)updateBlock withChangedIndexes:(ZMChangedIndexes *)changedIndexes;
- (void)listViewModel:(ConversationListViewModel *)model didSelectItem:(id)item;
- (void)listViewModel:(ConversationListViewModel *)model didUpdateConversationWithChange:(ConversationChangeInfo *)change;
@end

// Placeholder for conversation requests item
@interface ConversationListConnectRequestsItem : NSObject
@end

/** 
 * Provides a "view model" for the conversation list.
 */
@interface ConversationListViewModel : NSObject

@property (nonatomic, readonly) NSUInteger sectionCount;
@property (nonatomic, readonly) ConversationListConnectRequestsItem *contactRequestsItem;

@property (nonatomic, readonly) id selectedItem;

@property (nonatomic, weak) id<ConversationListViewModelDelegate> delegate;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex;
- (NSArray *)sectionAtIndex:(NSUInteger)sectionIndex;

- (id<NSObject>)itemForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItem:(id<NSObject>)item;

- (BOOL)isConversationAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForConversation:(id)conversation;

- (BOOL)selectItem:(id)itemToSelect;

- (void)updateSection:(SectionIndex)sectionIndex;
- (void)updateConversationListAnimated;
- (void)reloadConversationListViewModel;
@end


@interface ConversationListViewModel (Convenience)

// Select the item at an index path
- (id)selectItemAtIndexPath:(NSIndexPath *)indexPath;

// Search for previous items
- (NSIndexPath *)itemPreviousToIndex:(NSUInteger)index section:(NSUInteger)sectionIndex;

// Search for next items
- (NSIndexPath *)itemAfterIndex:(NSUInteger)index section:(NSUInteger)sectionIndex;

@end
