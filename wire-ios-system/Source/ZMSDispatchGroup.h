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

@interface ZMSDispatchGroup : NSObject

@property (nonatomic, readonly, copy) NSString* label;

+ (instancetype)groupWithLabel:(NSString *)label;
+ (instancetype)groupWithDispatchGroup:(dispatch_group_t)group label:(NSString *)label;

- (void)enter;
- (void)leave;
- (void)notifyOnQueue:(dispatch_queue_t)queue block:(dispatch_block_t)block;
- (long)waitWithTimeout:(dispatch_time_t)timeout;
- (long)waitForInterval:(NSTimeInterval)timeout;
- (void)asyncOnQueue:(dispatch_queue_t)queue block:(dispatch_block_t)block;

@end
