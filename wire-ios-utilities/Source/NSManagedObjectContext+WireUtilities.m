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
#import <WireUtilities/WireUtilities-Swift.h>
#import "NSManagedObjectContext+WireUtilities.h"
#import <objc/runtime.h>

static char const AssociatedPendingSaveCountKey;
static char const AssociatedDispatchGroupContextKey;
static NSTimeInterval const PerformWarningTimeout = 10;

@implementation NSManagedObjectContext (ZMSGroupQueue)

- (int)pendingSaveCounter;
{
    NSNumber *n = objc_getAssociatedObject(self,  &AssociatedPendingSaveCountKey);
    return [n intValue];
}
- (void)setPendingSaveCounter:(int)newCounter;
{
    objc_setAssociatedObject(self, &AssociatedPendingSaveCountKey, @(newCounter), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (DispatchGroupContext *)dispatchGroupContext
{
    return objc_getAssociatedObject(self, &AssociatedDispatchGroupContextKey);
}

- (void)createDispatchGroups
{
    NSArray<ZMSDispatchGroup *> *groups = [NSMutableArray arrayWithObjects:
                                           [ZMSDispatchGroup groupWithLabel:@"ZMSGroupQueue first"],
                                           // The secondary group gets -performGroupedBlock: added to it, but is not affected by
                                           // -notifyWhenGroupIsEmpty: -- that method needs to add extra blocks to the firstGroup, though.
                                           [ZMSDispatchGroup groupWithLabel:@"ZMSGroupQueue second"],
                                           nil];
    
    DispatchGroupContext *dispatchGroupContext = [[DispatchGroupContext alloc] initWithGroups:groups];
    objc_setAssociatedObject(self, &AssociatedDispatchGroupContextKey, dispatchGroupContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)performGroupedBlock:(dispatch_block_t)block;
{
    NSArray *groups = [self.dispatchGroupContext enterAllExcept:nil];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlock:^{
        [tp resetTime];
        block();
        [self.dispatchGroupContext leaveGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)performGroupedBlockAndWait:(dispatch_block_t)block;
{
    NSArray *groups = [self.dispatchGroupContext enterAllExcept:nil];
    ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:PerformWarningTimeout];
    [self performBlockAndWait:^{
        [tp resetTime];
        block();
        [self.dispatchGroupContext leaveGroups:groups];
        [tp warnIfLongerThanInterval];
    }];
}

- (void)notifyWhenGroupIsEmpty:(dispatch_block_t)block;
{
    // We need to enter & leave all but the first group to make sure that any work added by
    // this method is stil being tracked by the other groups.
    ZMSDispatchGroup *firstGroup = self.dispatchGroup;
    NSArray *groups = [self.dispatchGroupContext enterAllExcept:firstGroup];
    VerifyReturn(firstGroup != nil);
    [firstGroup notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:block];
        [self.dispatchGroupContext leaveGroups:groups];
    }];
}

- (ZMSDispatchGroup *)dispatchGroup;
{
    return self.dispatchGroupContext.groups.firstObject;
}

- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;
{
    NSError *error;
    NSArray *result = [self executeFetchRequest:request error:&error];
    RequireString(result != nil, "Error in fetching: %lu", (long) error.code);
    return result;
}

- (void)addGroup:(ZMSDispatchGroup *)dispatchGroup
{
    [self.dispatchGroupContext addGroup:dispatchGroup];
}

- (NSArray *)allGroups
{
    return self.dispatchGroupContext.groups;
}

- (NSArray *)enterAllGroups
{
    return [self.dispatchGroupContext enterAllExcept:nil];
}

- (void)leaveAllGroups:(NSArray *)groups
{
    [self.dispatchGroupContext leaveGroups:groups];
}

@end
