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
#import "ZMConversationList.h"

@class NSManagedObjectContext;
@class NSFetchRequest;
@class ZMConversation;


@interface ZMConversationList ()

@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

- (instancetype)initWithAllConversations:(NSArray *)conversations
                      filteringPredicate:(NSPredicate *)filteringPredicate
                                     moc:(NSManagedObjectContext *)moc
                            description:(NSString *)description;

- (instancetype)initWithAllConversations:(NSArray *)conversations
                      filteringPredicate:(NSPredicate *)filteringPredicate
                                     moc:(NSManagedObjectContext *)moc
                             description:(NSString *)description
                                   label:(Label *)label NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)cnt NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end


@protocol ZMConversationListObserver;
@interface ZMConversationList (ZMUpdates)

- (BOOL)predicateMatchesConversation:(ZMConversation *)conversation;
- (BOOL)sortingIsAffectedByConversationKeys:(NSSet *)conversationKeys;
- (void)removeConversations:(NSSet *)conversations;
- (void)insertConversations:(NSSet *)conversations;
- (void)resortConversation:(ZMConversation *)conversation;

@end

