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


@import WireSystem;
#import "NSOrderedSet+Zeta.h"


@implementation NSOrderedSet (Zeta)

- (nullable NSObject *)firstObjectNotInSet:(NSSet *)set;
{
    NSMutableOrderedSet *copy = [self mutableCopy];
    [copy minusSet:set];
    return copy.firstObject;
}

@end



@implementation NSMutableOrderedSet (ZMSortedInsert)

- (void)zm_insertObject:(id)object sortedByDescriptors:(NSArray *)descriptors;
{
    Require(object != nil);
    Require(descriptors != nil);
    Require(descriptors.count != 0);
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2){
        for (NSSortDescriptor *sd in descriptors) {
            NSComparisonResult const r = [sd compareObject:obj1 toObject:obj2];
            if (r != NSOrderedSame) {
                return r;
            }
        }
        return NSOrderedSame;
    };
    NSRange const range = NSMakeRange(0, self.count);
    NSUInteger const idx = [self indexOfObject:object inSortedRange:range options:NSBinarySearchingInsertionIndex usingComparator:comparator];
    [self insertObject:object atIndex:idx];
}

- (void)zm_sortUsingComparator:(NSComparator)cmp valueGetter:(id(^)(id))getter
{
    [self sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        id value1 = getter(obj1);
        id value2 = getter(obj2);
        
        return cmp(value1, value2);
    }];
}

@end



@implementation NSOrderedSet (ZMSorted)

- (id)firstObjectSortedByDescriptors:(NSArray *)descriptors;
{
    return [self firstObjectSortedByDescriptors:descriptors notInSet:nil];
}

- (id)firstObjectSortedByDescriptors:(NSArray *)descriptors notInSet:(nullable NSSet *)forbidden;
{
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2){
        for (NSSortDescriptor *sd in descriptors) {
            NSComparisonResult const r = [sd compareObject:obj1 toObject:obj2];
            if (r != NSOrderedSame) {
                return r;
            }
        }
        return NSOrderedSame;
    };
    
    id best;
    for (id candidate in self) {
        if ([forbidden containsObject:candidate]) {
            continue;
        }
        if (best == nil) {
            best = candidate;
        } else if (comparator(best, candidate) == NSOrderedDescending) {
            best = candidate;
        }
    }
    return best;
}

@end
