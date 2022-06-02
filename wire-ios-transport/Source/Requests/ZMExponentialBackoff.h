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
@import WireSystem;
@import WireUtilities;



@interface ZMExponentialBackoff : NSObject <TearDownCapable>

- (instancetype)initWithGroup:(ZMSDispatchGroup *)group workQueue:(NSOperationQueue *)workQueue;

/// Run the given block with exponential backoff.
///
/// This must be called on the workQueue, since the block will be executed synchronously when there's no wait. If there's a wait, the block will get enqueued onto the workQueue;
///
/// For each subsequent call an additional (exponentially growing) wait / delay will be inserted before running the block. If this method gets called while a block is already waiting, the waiting call 'wins' and the subsequent call will be ignored.
- (void)performBlock:(dispatch_block_t)block;

- (void)cancelAllBlocks;
- (void)tearDown; /// Must be called on the work queue

/// Resets the backoff such that the next call to -performBlock: will execute that block immediately.
- (void)resetBackoff;

- (void)reduceBackoff;
- (void)increaseBackoff;

/// This is exposed for testing.
@property (atomic) NSInteger maximumBackoffCounter;

@end
