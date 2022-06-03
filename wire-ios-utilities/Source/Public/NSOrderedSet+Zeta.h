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


NS_ASSUME_NONNULL_BEGIN

@interface NSOrderedSet (Zeta)

- (nullable NSObject *)firstObjectNotInSet:(NSSet *)set;

@end




@interface NSMutableOrderedSet (ZMSortedInsert)

/// Inserts the object into a sorted ordered set.
/// Uses bibary search.
- (void)zm_insertObject:(id)object sortedByDescriptors:(NSArray *)descriptors;
- (void)zm_sortUsingComparator:(NSComparator)cmp valueGetter:(id(^)(id))getter;

@end



@interface NSOrderedSet (ZMSorted)

- (nullable id)firstObjectSortedByDescriptors:(NSArray *)descriptors;
- (nullable id)firstObjectSortedByDescriptors:(NSArray *)descriptors notInSet:(nullable NSSet *)forbidden;

@end

NS_ASSUME_NONNULL_END
