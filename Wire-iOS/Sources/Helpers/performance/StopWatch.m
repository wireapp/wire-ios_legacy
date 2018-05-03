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

#import "StopWatch.h"
#import <mach/mach_time.h>

static NSString* ZMLogTag ZM_UNUSED = @"UI";

static StopWatch *stopWatch;



@interface StopWatch ()

@property (nonatomic) NSMutableDictionary *eventDictionary;

@end


@implementation StopWatch

+ (instancetype)stopWatch
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stopWatch = [[StopWatch alloc] init];
    });
    
    return stopWatch;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.eventDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (StopWatchEvent *)startEvent:(NSString *)eventName
{
    
    if (eventName != nil && self.eventDictionary[eventName] == nil) {
    
        StopWatchEvent *event = [StopWatchEvent eventWithName:eventName];
        event.state = StopWatchEventStateStarted;
        self.eventDictionary[eventName] = event;
        
        return event;
    }
    
    return nil;
}

- (StopWatchEvent *)stopEvent:(NSString *)eventName
{
    if (eventName != nil && self.eventDictionary[eventName] != nil) {
        
        StopWatchEvent *event = self.eventDictionary[eventName];
        event.state = StopWatchEventStateStopped;
        return event;
    }
    
    return nil;
}

- (StopWatchEvent *)restartEvent:(NSString *)eventName
{
    if (eventName != nil && self.eventDictionary[eventName] != nil) {
        
        StopWatchEvent *event = self.eventDictionary[eventName];
        event.state = StopWatchEventStateStopped;
        event.state = StopWatchEventStateUndefined;
        event.state = StopWatchEventStateStarted;
        return event;
    }
    else {
        return [self startEvent:eventName];
    }
    
    return nil;
}

@end


@interface StopWatchEvent ()

@property (nonatomic, readwrite) NSUInteger startTime;
@property (nonatomic, readwrite) NSUInteger stopTime;
@property (nonatomic, copy, readwrite) NSString *name;

@end


@implementation StopWatchEvent

+ (instancetype)eventWithName:(NSString *) name
{
    StopWatchEvent *event = [[StopWatchEvent alloc] initWithName:name];
    return event;
}

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.name = name;
        self.state = StopWatchEventStateUndefined;
    }
    return self;
}

- (void)setState:(StopWatchEventState)state
{
    switch (state) {
        case StopWatchEventStateUndefined:
            self.startTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
            self.stopTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
            _state = state;
            break;
        case StopWatchEventStateStarted:
        {
            if (_state == StopWatchEventStateStarted) {
                
                ZMLogWarn(@"Trying to start event %@, but %@ was already started. %s %d %s %s",
                      self.name,
                      self.name,
                      __FILE__,
                      __LINE__,
                      __PRETTY_FUNCTION__,
                      __FUNCTION__);
            }
            else {
                
                self.startTime = [self uptimeInMilliseconds];
                self.stopTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
                _state = state;
            }
        }
            break;
        case StopWatchEventStateStopped:
        {
            if (_state == StopWatchEventStateUndefined) {
                ZMLogError(@"Trying to stop event %@, but %@ was never started. %s %d %s %s",
                      self.name,
                      self.name,
                      __FILE__,
                      __LINE__,
                      __PRETTY_FUNCTION__,
                      __FUNCTION__);
            }
            else if (_state == StopWatchEventStateStopped) {
                ZMLogWarn(@"Trying to stop event %@, but %@ was already stopped. %s %d %s %s",
                      self.name,
                      self.name,
                      __FILE__,
                      __LINE__,
                      __PRETTY_FUNCTION__,
                      __FUNCTION__);
            }
            else if (_state == StopWatchEventStateStarted) {
                
                self.stopTime = [self uptimeInMilliseconds];
                _state = state;
            }
        }
            break;
    }
}

- (NSUInteger)elapsedTime
{
    NSUInteger res = self.stopTime - self.startTime;
    return res;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%p - Name: %@\tState: %lu\t StartTime:%lu\t StopTime:%lu", self, self.name, (unsigned long)self.state, (unsigned long)self.startTime, (unsigned long)self.stopTime];
}

- (NSUInteger)uptimeInMilliseconds
{
    const int64_t kOneMillion = 1000 * 1000;
    static mach_timebase_info_data_t s_timebase_info;
    
    if (s_timebase_info.denom == 0) {
        (void) mach_timebase_info(&s_timebase_info);
    }
    
    // mach_absolute_time() returns billionth of seconds,
    // so divide by one million to get milliseconds
    
    uint64_t abs_time = mach_absolute_time();
    uint64_t numer = (abs_time * s_timebase_info.numer);
    uint64_t demon = (kOneMillion * s_timebase_info.denom);
    uint64_t result = numer/demon;
    return (NSUInteger)result;
}

@end
