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
#import "ZMTimer.h"


@interface ZMTimer ()

@property (nonatomic, weak) id<ZMTimerClient> target;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) dispatch_source_t timer;
@property (nonatomic, readwrite) ZMTimerState state;

@end




@implementation ZMTimer


- (instancetype)initWithTarget:(id<ZMTimerClient>)target
{
    return [self initWithTarget:target operationQueue:nil];
}

- (instancetype)initWithTarget:(id<ZMTimerClient>)target operationQueue:(NSOperationQueue *)queue
{
    self = [super init];
    if (self) {
        self.target = target;
        self.queue = queue;
        self.state = ZMTimerStateNotStarted;
    }
    return self;
    
}

- (void)dealloc
{
    RequireString(self.state == ZMTimerStateFinished || self.state == ZMTimerStateNotStarted, "ZMTimer was not cleaned up correctly");
}

+ (instancetype)timerWithTarget:(id<ZMTimerClient>)target;
{
    return [[self alloc] initWithTarget:target];
}


+ (instancetype)timerWithTarget:(id<ZMTimerClient>)target operationQueue:(NSOperationQueue *)queue;
{
    return [[self alloc] initWithTarget:target operationQueue:queue];
}

- (void)fireAtDate:(NSDate *)date;
{
    NSTimeInterval interval = [date timeIntervalSinceNow];
    [self fireAfterTimeInterval:interval];
}

- (void)fireAfterTimeInterval:(NSTimeInterval)interval;
{
    RequireString(self.state == ZMTimerStateNotStarted, "Cannot reuse a ZMTimer");
    
    self.timer = [self setUpDispatchTimerWithInterval:interval];
    
    dispatch_source_set_event_handler(self.timer, ^{
        RequireString(self.state == ZMTimerStateStarted, "A ZMTimer that was not started was finished");
        self.state = ZMTimerStateFinished;
        if (self.target == nil) {
            return;
        }
        self.timer = nil;
        [self notifyClientOnCorrectQueue];
    });
    self.state = ZMTimerStateStarted;
    dispatch_resume(self.timer);
}

- (void)cancel
{
//    RequireString(self.state == ZMTimerStateStarted, @"A ZMTimer that was not started was cancelled");
    self.state = ZMTimerStateFinished;
    
    dispatch_source_t s = self.timer;
    self.timer = nil;
    if (s) {
        dispatch_source_cancel(s);
    }
}

- (void)notifyClientOnCorrectQueue
{
    if(self.queue != nil) {
        [self.queue addOperationWithBlock:^{
            [self notifyClient];
        }];
    }
    else {
        [self notifyClient];
    }
}

- (void)notifyClient
{
    id strongTarget = self.target;
    if (strongTarget == nil) {
        return;
    }
    
    [strongTarget timerDidFire:self];
}

- (dispatch_source_t)setUpDispatchTimerWithInterval:(NSTimeInterval)interval
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    RequireString(timer != nil, "Unable to create timer");
    
    int64_t intervalInNSec = (int64_t) (interval * (double)NSEC_PER_SEC);
    
    uint64_t leeway = (1ull * NSEC_PER_SEC) / 10;
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, intervalInNSec), DISPATCH_TIME_FOREVER, leeway);

    return timer;
}

@end
