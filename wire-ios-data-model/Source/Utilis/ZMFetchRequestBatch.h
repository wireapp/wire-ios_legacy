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
#import <CoreData/CoreData.h>

@class ZMMessage;
@class ZMConversation;


typedef NSDictionary <NSUUID *, NSSet <ZMMessage *> *> ZMMessageMapping;
typedef NSDictionary <NSUUID *, ZMConversation *> ZMConversationMapping;


@interface ZMFetchRequestBatchResult : NSObject

@property (nonatomic, readonly) ZMMessageMapping *messagesByNonce;
@property (nonatomic, readonly) ZMConversationMapping *conversationsByRemoteIdentifier;

- (void)addMessages:(NSArray <ZMMessage *>*)messages;

@end



/// A batch used to fetch as many messages and conversations
/// as possible using the least number of fetch requests
@interface ZMFetchRequestBatch : NSObject

/// Sets containing the current NSUUIDs for messages and conversations to fetch
@property (nonatomic, readonly) NSMutableSet *noncesToFetch;
@property (nonatomic, readonly) NSMutableSet *remoteIdentifiersToFetch;

/// Adds a the given set of message nonces to the batch fetch request
- (void)addNoncesToPrefetchMessages:(NSSet <NSUUID *>*)nonces;

/// Adds a the given set of conversation remote identifiers to the batch fetch request
- (void)addConversationRemoteIdentifiersToPrefetchConversations:(NSSet <NSUUID *>*)identifiers;

- (ZMFetchRequestBatchResult *)executeInManagedObjectContext:(NSManagedObjectContext *)moc;

@end



@interface NSManagedObjectContext (ZMFetchRequestBatch)

- (ZMFetchRequestBatchResult *)executeFetchRequestBatchOrAssert:(ZMFetchRequestBatch *)fetchRequestbatch;

@end
