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
#import <WireSystem/WireSystem.h>

@class DispatchGroupContext;

@interface NSManagedObjectContext (ZMSGroupQueue) <ZMSGroupQueue>

@property (nonatomic, readonly, null_unspecified ) DispatchGroupContext *dispatchGroupContext;

- (void)createDispatchGroups;

/// Schedules a notification block to be submitted to the receiver's
/// queue once all blocks associated with the receiver's group have completed.
///
/// If no blocks are associated with the receiver's group (i.e. the group is empty)
/// then the notification block will be submitted immediately.
///
/// The receiver's group will be empty at the time the notification block is submitted to
/// the receiver's queue.
///
/// @sa  dispatch_group_notify()
- (void)notifyWhenGroupIsEmpty:(dispatch_block_t _Null_unspecified )block ZM_NON_NULL(1);

/// Adds a group to the receiver. All blocks associated with the receiver's group will
/// also be associated with this group.
///
/// This is used for testing. It is not thread safe.
- (void)addGroup:(ZMSDispatchGroup *_Null_unspecified)dispatchGroup ZM_NON_NULL(1);

/// List of all groups associated with this context
- (NSArray *_Null_unspecified)allGroups;

/// Performs a block and wait for completion.
/// @note: The block is not retained after its execution. This means that if the queue
/// is not running (e.g. blocked by a deadlock), the block and all its captured variables
/// will be retained, otherwise it will eventually be released.
/// @attention: Be *very careful* not to create deadlocks.
- (void)performGroupedBlockAndWait:(dispatch_block_t _Null_unspecified )block ZM_NON_NULL(1);

/// Executes a fetch request and asserts in case of error
/// For generic requests in Swift please refer to `func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T]`
- (nonnull NSArray *)executeFetchRequestOrAssert:(nonnull NSFetchRequest *)request;

- (NSArray *_Null_unspecified)enterAllGroups;
- (void)leaveAllGroups:(NSArray *_Null_unspecified)groups;

@property (nonatomic) int pendingSaveCounter;

@end
