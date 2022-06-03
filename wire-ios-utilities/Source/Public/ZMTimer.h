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


@class ZMTimer;

@protocol ZMTimerClient

- (void)timerDidFire:(ZMTimer *)timer;

@end

typedef NS_ENUM(NSUInteger, ZMTimerState) {
    ZMTimerStateNotStarted,
    ZMTimerStateStarted,
    ZMTimerStateFinished
};

@interface ZMTimer : NSObject

@property (nonatomic) NSDictionary *userInfo;

@property (nonatomic, readonly) ZMTimerState state;
@property (nonatomic, readonly, weak) id<ZMTimerClient> target;

+ (instancetype)timerWithTarget:(id<ZMTimerClient>)target;
+ (instancetype)timerWithTarget:(id<ZMTimerClient>)target operationQueue:(NSOperationQueue *)queue;

- (void)fireAtDate:(NSDate *)date;
- (void)fireAfterTimeInterval:(NSTimeInterval)interval;
- (void)cancel;

@end
