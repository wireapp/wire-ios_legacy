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


#import "ZMSTimePoint.h"
#import "ZMSLogging.h"

@interface ZMSTimePoint ()

@property (nonatomic) NSTimeInterval warnInterval;
@property (nonatomic) NSArray<NSString *> *callstack;
@property (nonatomic) NSDate *timePoint;
@property (nonatomic) NSString *label;

@end


@implementation ZMSTimePoint

+ (BOOL)timePointEnabled {
    return NSProcessInfo.processInfo.environment[@"ZM_TIMEPOINTS_CALLSTACK"].boolValue;
}

+ (instancetype)timePointWithInterval:(NSTimeInterval)interval label:(NSString *)label {

    ZMSTimePoint *tp = [[ZMSTimePoint alloc] init];
    if([self timePointEnabled]) {
        tp.callstack = [self filteredCallstack];
    }
    tp.warnInterval = interval;
    tp.timePoint = [NSDate date];
    tp.label = label;
    return tp;
}

/// Returns the current callstack, minus entry relative to this class
+ (NSArray<NSString *>*)filteredCallstack {
    
    NSArray *callstack = [NSThread callStackSymbols];
    NSString *thisClassStaticMethod = [NSString stringWithFormat:@"+[%@ ", self];
    NSMutableArray *finalArray = [NSMutableArray array];
    [callstack enumerateObjectsUsingBlock:^(NSString*  _Nonnull entry, NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
        if(![entry containsString:thisClassStaticMethod]) {
            [finalArray addObject:entry];
        }
    }];
    return finalArray;
}

+ (instancetype)timePointWithInterval:(NSTimeInterval)interval {
    return [self timePointWithInterval:interval label:nil];
}

- (void)resetTime {
    self.timePoint = [NSDate date];
}


- (NSTimeInterval)elapsedTime {
    return - [self.timePoint timeIntervalSinceNow];
}

- (BOOL)warnIfLongerThanInterval {
    NSTimeInterval now = [self elapsedTime];
    if(now > self.warnInterval && [[self class] timePointEnabled]) {
        ZMLogWarn(@"Time point (%@) warning threshold: %@ seconds elapsed\nCall stack:\n%@", self.label, @(now), [self.callstack componentsJoinedByString:@"\n"]);
    }
    return now > self.warnInterval;
}

@end
