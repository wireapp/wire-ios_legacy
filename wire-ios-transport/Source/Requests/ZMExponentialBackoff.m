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


#import "ZMExponentialBackoff.h"
#import "ZMTLogging.h"

@import WireSystem;

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK_LOW_LEVEL;



@interface ZMExponentialBackoff ()

@property (nonatomic, readonly) ZMSDispatchGroup *group;
@property (nonatomic, readonly) NSOperationQueue *workQueue;
@property (nonatomic, readonly) NSMutableArray *blocks;
@property (nonatomic) NSInteger backOffCounter;
@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) NSTimeInterval timeInterval;
@property (nonatomic) BOOL needsTearDown;

@end

static int suspendCount;

#define LogResume() \
	ZMLogDebug(@"RSRSRSRS Back-off resume    suspend count = %d   %@", --suspendCount, NSStringFromSelector(_cmd));
#define LogSuspend() \
	ZMLogDebug(@"RSRSRSRS Back-off suspend   suspend count = %d   %@", ++suspendCount, NSStringFromSelector(_cmd));


@implementation ZMExponentialBackoff

ZM_EMPTY_ASSERTING_INIT()

- (instancetype)initWithGroup:(ZMSDispatchGroup *)group workQueue:(NSOperationQueue *)workQueue;
{
    self = [super init];
    if (self) {
        _group = group;
        _workQueue = workQueue;
        _blocks = [NSMutableArray array];
        self.maximumBackoffCounter = 9;
        self.needsTearDown = YES;
    }
    return self;
}

- (void)dealloc
{
    Require(! self.needsTearDown);
}

- (void)performBlock:(dispatch_block_t)block;
{
    if (self.timer == nil) {
        ZMLogDebug(@"No back-off.");
        block();
    } else {
        [self.blocks addObject:[block copy]];
        ZMLogDebug(@"Back-off active. Delaying. (%u)", (unsigned) self.blocks.count);
        if (self.blocks.count == 1) {
            dispatch_resume(self.timer);
            LogResume();
        }
    }
}

- (void)cancelAllBlocks;
{
    BOOL const wasSuspended = (self.blocks.count == 0);
    [self.blocks removeAllObjects];
    if (! wasSuspended) {
        dispatch_suspend(self.timer);
        LogSuspend();
    }
}

- (void)tearDown;
{
    BOOL const wasSuspended = (self.blocks.count == 0);
    [self cancelAllBlocks];
    if (self.timer != nil) {
        if (wasSuspended) {
            dispatch_resume(self.timer);
            LogResume();
        }
        ZMLogDebug(@"Back-off cancel & release timer.");
        dispatch_source_cancel(self.timer);
        self.timer = nil; // Break reference loop
    }
    self.needsTearDown = NO;
}

- (void)runAllBlocks;
{
    ZMLogDebug(@"Back-off was disabled. Running all (%u).", (unsigned) self.blocks.count);
    BOOL const wasSuspended = (self.blocks.count == 0);
    NSArray *blocks = [self.blocks copy];
    [self.blocks removeAllObjects];
    for (dispatch_block_t b in blocks) {
        b();
    }
    if (! wasSuspended) {
        dispatch_suspend(self.timer);
        LogSuspend();
    }
}

- (void)resetBackoff;
{
    if (0 != self.backOffCounter) {
        self.backOffCounter = 0;
        self.timeInterval = self.calculateNewTimeInterval;
        ZMLogInfo(@"Resetting back-off to level %ld interval %g ms", (long)self.backOffCounter, self.timeInterval * 1000.);
    }
}

- (void)reduceBackoff;
{
    NSInteger const oldCounter = self.backOffCounter;
    self.backOffCounter -= MIN(MAX(0, self.backOffCounter), 2);
    if (oldCounter != self.backOffCounter) {
        self.timeInterval = self.calculateNewTimeInterval;
        ZMLogInfo(@"Reducing back-off to level %ld interval %g ms", (long)self.backOffCounter, self.timeInterval * 1000.);
    }
}

- (void)increaseBackoff;
{
    NSInteger const oldCounter = self.backOffCounter;
    self.backOffCounter = MIN(self.backOffCounter + 1, self.maximumBackoffCounter);
    if (oldCounter != self.backOffCounter) {
        self.timeInterval = self.calculateNewTimeInterval;
        ZMLogInfo(@"Increasing back-off to level %ld interval %g ms", (long)self.backOffCounter, self.timeInterval * 1000.);
    }
}

- (NSTimeInterval)calculateNewTimeInterval;
{
    if (self.backOffCounter < 1) {
        return 0;
    }
    NSTimeInterval const baseBackoffInternal = 0.025;
    int const backOffCounter = (int) self.backOffCounter;
    NSTimeInterval delay1 = baseBackoffInternal * pow(2., backOffCounter - 1);
    NSTimeInterval delay2 = baseBackoffInternal * pow(2., backOffCounter);
    NSTimeInterval delay = delay1 + (delay2 - delay1) * (arc4random() / (double) UINT32_MAX);
    return delay;
}

- (void)timerFired;
{
    [self.workQueue addOperationWithBlock:^{
        dispatch_block_t block = self.blocks.firstObject;
        if (block != nil) {
            [self.blocks removeObjectAtIndex:0];
            ZMLogDebug(@"-> Back-off timer fired. Executing block, %u remaining.", (unsigned) self.blocks.count);
            if (self.blocks.count == 0) {
                dispatch_suspend(self.timer);
                LogSuspend();
            }
            block();
        }
    }];
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval;
{
    if (timeInterval == _timeInterval) {
        return;
    }
    _timeInterval = timeInterval;
    ZMLogDebug(@"Setting time interval to %g ms. %u blocks.", 1000. * _timeInterval, (unsigned) self.blocks.count);
    
    if ((timeInterval <= 0) && (self.timer != nil)) {
        [self runAllBlocks];
        dispatch_resume(self.timer);
        LogResume();
        ZMLogDebug(@"Back-off cancel & release timer.");
        dispatch_source_cancel(self.timer);
        self.timer = nil;
        return;
    }
    
    if (self.timer == nil) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        Require(self.timer != nil);
        __weak ZMExponentialBackoff *weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            ZMExponentialBackoff *backoff = weakSelf;
            [backoff timerFired];
        });
        suspendCount = 0;
        LogSuspend();
    } else if (self.blocks.count != 0) {
        dispatch_suspend(self.timer);
        LogSuspend();
    }
    
    {
        // Convert the time interval to milliseconds:
        int64_t nanoseconds = (int64_t) (timeInterval * (double) NSEC_PER_SEC);
        // Set the leeway to 1/4th of the interval, but at least 1 ms.
        uint64_t leeway = MAX((uint64_t) (fabs(timeInterval * (double) NSEC_PER_SEC) * 0.25), NSEC_PER_MSEC);
        
        dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, nanoseconds);
        dispatch_source_set_timer(self.timer, start, (uint64_t) nanoseconds, leeway);
    }
    if (self.blocks.count != 0) {
        dispatch_resume(self.timer);
        LogResume();
    }
}

@end
