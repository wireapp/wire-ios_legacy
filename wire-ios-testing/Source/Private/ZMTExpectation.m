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
#import "ZMTExpectation.h"



@implementation ZMTExpectation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)fulfill;
{
    dispatch_semaphore_signal(self.semaphore);
}

- (void)stopObserving;
{
}

- (BOOL)waitUntil:(NSDate *)date;
{
    static NSTimeInterval SLEEP_TIME = 0.01;
    while (0. < [date timeIntervalSinceNow]) {
        if (0 == dispatch_semaphore_wait(self.semaphore, dispatch_walltime(NULL, NSEC_PER_MSEC))) {
            [self stopObserving];
            return YES;
        }
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:SLEEP_TIME]]) {
            [NSThread sleepForTimeInterval:SLEEP_TIME];
        }
    }
    [self stopObserving];
    return dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW) == 0;
}

@end



@implementation ZMTNotificationExpectation

- (void)dealloc
{
    [self stopObserving];
}

- (void)stopObserving;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observe:(NSNotification *)note;
{
    if (self.handler) {
        if (! self.handler(note)) {
            return;
        }
    }
    [self fulfill];
    [self stopObserving];
}

@end



@implementation ZMTKeyValueObservingExpectation

- (void)dealloc
{
    [self stopObserving];
}

- (void)stopObserving;
{
    [self.object removeObserver:self forKeyPath:self.keyPath context:(__bridge void *) self];
    self.object = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NOT_USED(change);
    NOT_USED(object);
    NOT_USED(keyPath);
    if (context == (__bridge void *) self) {
        [self fulfill];
        [self stopObserving];
    }
}

@end


