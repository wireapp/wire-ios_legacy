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


@class ZMSDispatchGroup;

/// Similar to a dispatch queue or NSOperationQueue
@protocol ZMSGroupQueue <NSObject>

/// Submits a block to the receiver's private queue and associates it with the
/// receiver's group.
///
/// This will use @c -performBlock: internally and hence encapsulates
/// an autorelease pool and a call to @c -processPendingChanges
///
/// @sa -performBlock:
- (void)performGroupedBlock:(dispatch_block_t)block ZM_NON_NULL(1);

/// The underlying dispatch group that is used for @c -performGroupedBlock:
///
/// It can be used to associate a block with the receiver without running it on the
/// receiver's queue.
@property (nonatomic, readonly) ZMSDispatchGroup *dispatchGroup;

@end
