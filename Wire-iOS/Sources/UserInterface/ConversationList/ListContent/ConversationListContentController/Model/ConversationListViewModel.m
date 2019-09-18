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
#import "WireSyncEngine+iOS.h"
@import WireDataModel;
#import "Wire-Swift.h"

void debugLog (NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@implementation ConversationListConnectRequestsItem ///TODO: remove?
@end


@implementation ConversationListViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contactRequestsItem = [[ConversationListConnectRequestsItem alloc] init];

        [self updateAllSections];
        [self setupObserversForListReloading];
        [self setupObserversForActiveTeam];
        [self subscribeToTeamsUpdates];
    }
    return self;
}

- (void)setupObserversForListReloading
{
    ZMUserSession *userSession = [ZMUserSession sharedSession];
    
    if (userSession == nil) {
        return;
    }
    
    self.conversationListsReloadObserverToken = [ConversationListChangeInfo addConversationListReloadObserver:self userSession:userSession];
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

- (NSArray *)newConversationList
{
    return [[ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]] copy];
}


- (void)reloadConversationListViewModel
{
    [self updateAllSections];
    [self setupObserversForActiveTeam];
    debugLog(@"RELOAD conversation list");
    [self.delegate listViewModelShouldBeReloaded];
}

- (void)conversationListsDidReload
{
    [self reloadConversationListViewModel];
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
