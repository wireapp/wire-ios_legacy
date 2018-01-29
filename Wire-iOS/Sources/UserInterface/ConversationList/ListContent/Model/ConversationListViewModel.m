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


#import "ConversationListViewModel.h"
#import "AggregateArray.h"
#import "WireSyncEngine+iOS.h"
@import WireDataModel;
#import "Wire-Swift.h"

void debugLog (NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void debugLogUpdate (ConversationListChangeInfo *note);


@implementation ConversationListConnectRequestsItem
@end


@interface ConversationListViewModel () <ZMConversationListObserver>

@property (nonatomic, strong) ConversationListConnectRequestsItem *contactRequestsItem;
@property (nonatomic, strong) AggregateArray *aggregatedItems;
@property (nonatomic, readwrite) id selectedItem;

// Local copies of the lists.
@property (nonatomic, copy) NSArray *inbox;
@property (nonatomic, copy) NSArray *conversations;
@property (nonatomic) id pendingConversationListObserverToken;
@property (nonatomic) id conversationListObserverToken;
@property (nonatomic) id clearedConversationListObserverToken;

@end



@implementation ConversationListViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contactRequestsItem = [[ConversationListConnectRequestsItem alloc] init];

        [self updateSection:SectionIndexAll];
        
        [self setupObserversForActiveTeam];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationWillEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
        [self subscribeToTeamsUpdates];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)setupObserversForActiveTeam
{
    ZMUserSession *userSession = [ZMUserSession sharedSession];
    
    if (userSession == nil) {
        return;
    }
    
    self.pendingConversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                                forList:[ZMConversationList pendingConnectionConversationsInUserSession:userSession]
                                                                            userSession:userSession];
    
    self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                         forList:[ZMConversationList conversationsInUserSession:userSession]
                                                                     userSession:userSession];
    
    self.clearedConversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                                forList:[ZMConversationList clearedConversationsInUserSession:userSession]
                                                                            userSession:userSession];
}

/**
 * This updates a specific section in the model, by copying the contents locally.
 * Passing in a value of SectionIndexAll updates all sections. The reason why we need to keep
 * local copies of the lists is that we get separate notifications for each list, 
 * which means that an update to one can render the collection view out of sync with the datasource.
 */
- (void)updateSection:(SectionIndex)sectionIndex
{
    [self updateSection:sectionIndex withItems:nil];
}

- (void)updateSection:(SectionIndex)sectionIndex withItems:(NSArray *)items
{
    if (sectionIndex == SectionIndexAll && items != nil) {
        NSAssert(true, @"Update for all sections with proposed items is not allowed.");
    }
    
    if (sectionIndex == SectionIndexContactRequests || sectionIndex == SectionIndexAll) {
        if ([ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]].count > 0) {
            self.inbox = items ?: @[self.contactRequestsItem];
        }
        else {
            self.inbox = @[];
        }
    }

    if (sectionIndex == SectionIndexConversations || sectionIndex == SectionIndexAll) {
        // Make a new copy of the conversation list
        self.conversations = items ? : [self newConversationList];
    }
    
    
    // Re-create the aggregate array
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:2];
    [sections addObject:self.inbox];
    [sections addObject:self.conversations != nil ? self.conversations : @[]];
    
    self.aggregatedItems = [AggregateArray aggregateArrayWithSections:sections];
}

- (BOOL)selectItem:(id)itemToSelect
{
    if (itemToSelect == nil) {
        self.selectedItem = itemToSelect;
        [self.delegate listViewModel:self didSelectItem:nil];
        return NO;
    }
    
    NSIndexPath *indexPath = [self indexPathForItem:itemToSelect];
    
    // Couldn't find the item
    if (indexPath == nil && [itemToSelect isKindOfClass:[ZMConversation class]]) {
        ZMConversation *conversation = itemToSelect;
        BOOL containedInOtherLists = NO;
        
        if ([[ZMConversationList archivedConversationsInUserSession:[ZMUserSession sharedSession]] containsObject:itemToSelect]) {
            // Check if it's archived, this would mean that the archive is closed but we want to unarchive
            // and select the item
            containedInOtherLists = YES;
            [[ZMUserSession sharedSession] enqueueChanges:^{
                conversation.isArchived = NO;
            } completionHandler:nil];
        }
        else if ([[ZMConversationList clearedConversationsInUserSession:[ZMUserSession sharedSession]] containsObject:itemToSelect]) {
            containedInOtherLists = YES;
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [conversation revealClearedConversation];
            } completionHandler:nil];
        }
        
        if (containedInOtherLists) {
            self.selectedItem = itemToSelect;
            [self.delegate listViewModel:self didSelectItem:itemToSelect];
            
            return YES;
        }
        
        return NO;
    }
    
    self.selectedItem = itemToSelect;
    [self.delegate listViewModel:self didSelectItem:itemToSelect];
    
    return YES;
}

- (NSUInteger)sectionCount
{
    return [self.aggregatedItems numberOfSections];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    return [self.aggregatedItems numberOfItemsInSection:sectionIndex];
}

- (NSArray *)sectionAtIndex:(NSUInteger)sectionIndex
{
    if (sectionIndex >= [self sectionCount]) {
        return nil;
    }
    return [self.aggregatedItems sectionAtIndex:sectionIndex];
}

- (id<NSObject>)itemForIndexPath:(NSIndexPath *)indexPath
{
    return [self.aggregatedItems itemForIndexPath:indexPath];
}

- (NSIndexPath *)indexPathForItem:(id<NSObject>)item
{
    return [self.aggregatedItems indexPathForItem:item];
}

- (BOOL)isConversationAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [self itemForIndexPath:indexPath];
    return [obj isKindOfClass:[ZMConversation class]];
}

- (NSIndexPath *)indexPathForConversation:(id)conversation
{
    if (conversation == nil) {
        return nil;
    }
    
    NSIndexPath *__block result = nil;
    [self.aggregatedItems enumerateItems:^(NSArray *section, NSUInteger sectionIndex, id<NSObject> item, NSUInteger itemIndex, BOOL *stop) {
        if ([item isEqual:conversation]) {
            result = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            *stop = YES;
        }
    }];
    
    return result;
}

- (void)conversationListDidChange:(ConversationListChangeInfo *)change
{
    debugLogUpdate(change);
    
    if (change.conversationList == [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]]) {
        // If the section was empty in certain cases collection view breaks down on the big amount of conversations,
        // so we prefer to do the simple reload instead.

        [self updateConversationListAnimated];
    } else if (change.conversationList == [ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]]) {
        debugLog(@"RELOAD contact requests");
        [self updateSection:SectionIndexContactRequests];
        [self.delegate listViewModel:self didUpdateSectionForReload:SectionIndexContactRequests];
    }
}

- (NSArray *)newConversationList
{
    return [[ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]] copy];
}

- (void)updateConversationListAnimated
{
    if ([self numberOfItemsInSection:SectionIndexConversations] == 0) {
        [self reloadConversationListViewModel];
    } else {
        NSArray *oldConversationList = [self.aggregatedItems sectionAtIndex:SectionIndexConversations];
        NSArray *newConversationList = [self newConversationList];
        if ([oldConversationList isEqualToArray:newConversationList]) {
            return;
        }
        
        ZMOrderedSetState *startState = [[ZMOrderedSetState alloc] initWithOrderedSet:[NSOrderedSet orderedSetWithArray:oldConversationList]];
        ZMOrderedSetState *endState = [[ZMOrderedSetState alloc] initWithOrderedSet:[NSOrderedSet orderedSetWithArray:newConversationList]];
        ZMOrderedSetState *updatedState = [[ZMOrderedSetState alloc] initWithOrderedSet:[NSOrderedSet orderedSet]];
        
        ZMChangedIndexes *changedIndexes = [[ZMChangedIndexes alloc] initWithStartState:startState
                                                                               endState:endState
                                                                           updatedState:updatedState
                                                                               moveType:ZMSetChangeMoveTypeUICollectionView];
        
        if (changedIndexes.requiresReload) {
            [self reloadConversationListViewModel];
        } else {
            // We need to capture the state of `newConversationList` to make sure that we are updating the value
            // of the list to the exact new state.
            // It is important to keep the data source of the collection view consistent, since
            // any inconsistency in the delta update would make it throw an exception.
            dispatch_block_t modelUpdates = ^{ [self updateSection:SectionIndexConversations
                                                         withItems:newConversationList]; };
            [self.delegate listViewModel:self didUpdateSection:SectionIndexConversations usingBlock:modelUpdates withChangedIndexes:changedIndexes];
        }
    }
}

- (void)reloadConversationListViewModel
{
    [self updateSection:SectionIndexAll];
    [self setupObserversForActiveTeam];
    debugLog(@"RELOAD conversation list");
    [self.delegate listViewModelShouldBeReloaded];
}

- (void)applicationWillEnterForeground:(NSNotification *)note
{
    [ZMConversationList refetchAllListsInUserSession:ZMUserSession.sharedSession];
    [self reloadConversationListViewModel];
}

- (void)conversationInsideList:(ZMConversationList *)list didChange:(ConversationChangeInfo *)changeInfo;
{
    if ([self.delegate respondsToSelector:@selector(listViewModel:didUpdateConversationWithChange:)]) {
        [self.delegate listViewModel:self didUpdateConversationWithChange:changeInfo];
    }
}

@end


@implementation ConversationListViewModel (Convenience)

- (id)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemForIndexPath:indexPath];
    [self selectItem:item];
    return item;
}

- (NSIndexPath *)itemAfterIndex:(NSUInteger)index section:(NSUInteger)sectionIndex
{
    NSArray *section = [self sectionAtIndex:sectionIndex];
    
    if (section.count > index + 1) {
        // Select next item in section
        return [NSIndexPath indexPathForItem:index + 1 inSection:sectionIndex];
    }
    else if (index >= section.count) {
        // select last item in previous section
        return [self firstItemInSectionAfter:sectionIndex];
    }
    return nil;
}

- (NSIndexPath *)firstItemInSectionAfter:(NSUInteger)sectionIndex
{
    NSUInteger nextSectionIndex = sectionIndex + 1;
    
    if (nextSectionIndex >= self.sectionCount) {
        // we are at the end, so return nil
        return nil;
    }
    
    NSArray *section = [self sectionAtIndex:nextSectionIndex];
    if (section != nil) {
        
        if (section.count > 0) {
            return [NSIndexPath indexPathForItem:0 inSection:nextSectionIndex];
        }
        else {
            // Recursively move forward
            return [self firstItemInSectionAfter:nextSectionIndex];
        }
    }
    
    return nil;
}

- (NSIndexPath *)itemPreviousToIndex:(NSUInteger)index section:(NSUInteger)sectionIndex
{
    NSArray *section = [self sectionAtIndex:sectionIndex];
    
    if (index > 0 && section.count > index - 1) {
        // Select previous item in section
        return [NSIndexPath indexPathForItem:index-1 inSection:sectionIndex];
    }
    else if (index == 0) {
        // select last item in previous section
        return [self lastItemInSectionPreviousTo:sectionIndex];
    }
    
    return nil;
}

- (NSIndexPath *)lastItemInSectionPreviousTo:(NSUInteger)sectionIndex
{
    NSInteger previousSectionIndex = sectionIndex - 1;
    
    if (previousSectionIndex < 0) {
        // we are at the top, so return nil
        return nil;
    }
    
    NSArray *section = [self sectionAtIndex:previousSectionIndex];
    if (section != nil) {
        if (section.count > 0) {
            return [NSIndexPath indexPathForItem:section.count - 1 inSection:previousSectionIndex];
        }
        else {
            // Recursively move back
            return [self lastItemInSectionPreviousTo:previousSectionIndex];
        }
    }
    
    return nil;
}

@end



void debugLog(NSString *format, ...)
{
    if (DEBUG) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

void debugLogUpdate (ConversationListChangeInfo *change)
{
    if (DEBUG && 0) {
        
        NSUInteger __block movedCount = 0;
        [change enumerateMovedIndexes:^(NSInteger from, NSInteger to) {
            movedCount++;
        }];
        
        debugLog(@"update for list %p (update=%p) (conv=%p, archive=%p, pending=%p), (delete=%lu, insert=%lu, move=%lu, upd=%lu)",
                 change.conversationList,
                 change,
                 [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]],
                 [ZMConversationList archivedConversationsInUserSession:[ZMUserSession sharedSession]],
                 [ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]],
                 (unsigned long)change.deletedIndexes.count,
                 (unsigned long)change.insertedIndexes.count,
                 (unsigned long)movedCount,
                 (unsigned long)change.updatedIndexes.count);
    }
}
