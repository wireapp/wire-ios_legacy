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


#import <CoreData/CoreData.h>


extern NSString * const ZMSuggestedUsersForUserDidChange;
extern NSString * const ZMCommonConnectionsForUsersDidChange;
extern NSString * const ZMRemovedSuggestedContactRemoteIdentifiersDidChange;

@interface ZMSuggestedUserCommonConnections : NSObject <NSCoding, NSSecureCoding>
- (instancetype)initWithPayload:(NSDictionary *)payload;
+ (instancetype)emptyEntry;
@property (nonatomic, readonly,getter=isEmpty) BOOL empty;
@property (nonatomic, readonly) NSOrderedSet   *topCommonConnectionsIDs;
@property (nonatomic, readonly) NSUInteger totalCommonConnections;
@end



@interface NSManagedObjectContext (ZMSearchDirectory)

/// Remote identifiers (NSUUID) for your suggested users, ordered by decending relevance.
@property (nonatomic, copy) NSOrderedSet *suggestedUsersForUser;
/// The remote identifiers (NSUUID keys to @c ZMSuggestedUserCommonConnections) of 'people you may want to connect to'.
@property (nonatomic, copy) NSDictionary *commonConnectionsForUsers;
/// The remote identifiers (as NSUUID instances) of 'people you may want to connect to' that have been dismissed, i.e. are supposed to be hidden.
/// These are pushed to the backend and removed from this array once they have been sent. C.f. ZMRemovedSuggestedPeopleTranscoder
@property (nonatomic, copy) NSArray *removedSuggestedContactRemoteIdentifiers;

@end
