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

@class ZMMessage;


@interface ZMMessageTimer : NSObject <TearDownCapable>

@property (nonatomic, readonly) BOOL hasMessageTimersRunning;
@property (nonatomic, readonly) NSUInteger runningTimersCount;
@property (nonatomic, weak, readonly) NSManagedObjectContext *moc;

///  The block to be executed when the timer fires. The block is executed in a performBlock of the specified context. The message returned from this block is guaranteed to exist.
@property (nonatomic, copy) void(^timerCompletionBlock)(ZMMessage *, NSDictionary*);

/// Creates an object that can create timers for messages. It handles timer creation, firing and teardown
/// @managedObjectContext The context on which changes are supposed to be performed on timer firing.
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;



/// Starts a new timer if there is no existing one
/// @param fireDate The date at which the timer should fire
/// @param userInfo Additional info that should be added to the timer
- (void)startTimerForMessageIfNeeded:(ZMMessage*)message fireDate:(NSDate *)fireDate userInfo:(NSDictionary *)userInfo;


/// Stops an existing timer
- (void)stopTimerForMessage:(ZMMessage *)message;

/// You need to call tearDown, otherwise the object will never be deallocated
- (void)tearDown;

/// Returns YES if there is a timer for this message
- (BOOL)isTimerRunningForMessage:(ZMMessage *)message;

/// Returns the timer created for this message
- (ZMTimer *)timerForMessage:(ZMMessage *)message;

@end
