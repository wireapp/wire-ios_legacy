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

/// Records the passage of time since its creation. It also stores the callstack at creation time.
/// It the environment variable ZM_TIMEPOINTS_CALLSTACK is set, it will record and print any
/// callstack information
@interface ZMSTimePoint : NSObject

/// If not zero, it will call @c warnIfLongerThanInteval with this value on dealloc
@property (nonatomic, readonly) NSTimeInterval warnInterval;
/// Time since creation
@property (nonatomic, readonly) NSTimeInterval elapsedTime;
/// The label associated with this timepoint
@property (nonatomic, readonly) NSString *label;


/// Creates a time point and records the callstack
+ (instancetype)timePointWithInterval:(NSTimeInterval)interval;
/// Creates a time point and records the callstack with a label used to identify the timepoint
+ (instancetype)timePointWithInterval:(NSTimeInterval)interval label:(NSString *)label;

/// Resets the creation time, but not the callstack
- (void)resetTime;


/// Prints a warning if the current elapsed time since cration is greater than warnInterval
/// If the environment variable ZM_TIMEPOINTS_CALLSTACK is set, it will print the callstack information
/// @returns true if the current elapsed time was greater than the interval
- (BOOL)warnIfLongerThanInterval;

@end
