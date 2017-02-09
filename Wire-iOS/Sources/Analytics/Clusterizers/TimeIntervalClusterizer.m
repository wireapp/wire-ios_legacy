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


#import "TimeIntervalClusterizer.h"

IntRange DefaultTimeIntervalRangesRanges[] = {{1,1}, {2, 5}, {6, 10}, {11, 20}, {21, 30}, {31, 60}, {61, 120}, {121, 180}, {181, 300}, {301, 600}, {601, 1200}, {1201, 1800}, {1801, 2400}, {2401, 3000}, {3001, 3600}};
RangeSet DefaultTimeIntervalRanges = {DefaultTimeIntervalRangesRanges, 15};


IntRange VideoMessageTimeIntervalRangesRanges[] = {{0,0}, {1, 10}, {11, 30}, {31, 60}, {61, 300}, {301, 900}, {901, 1800}};
RangeSet VideoMessageTimeIntervalRanges = {VideoMessageTimeIntervalRangesRanges, 7};

IntRange MessageEditTimeIntervalRangesRanges[] = {{0,0}, {1, 60}, {61, 300}, {601, 1800}, {1801, 3600}, {3601, 86400}};
RangeSet MessageEditTimeIntervalRanges = {MessageEditTimeIntervalRangesRanges, 6};

IntRange CallSetupTimeIntervalRangesRanges[] = {{0,0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 10}, {11, 30}};
RangeSet CallSetupTimeIntervalRanges = {CallSetupTimeIntervalRangesRanges, 7};


@implementation TimeIntervalClusterizer

+ (instancetype)defaultClusterizer
{
    static TimeIntervalClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [TimeIntervalClusterizer new];
        clusterizer.rangeSet = DefaultTimeIntervalRanges;
    });

    return clusterizer;
}

+ (instancetype)videoDurationClusterizer
{
    static TimeIntervalClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [TimeIntervalClusterizer new];
        clusterizer.rangeSet = VideoMessageTimeIntervalRanges;
    });
    
    return clusterizer;
}

+ (instancetype)messageEditDurationClusterizer
{
    static TimeIntervalClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [TimeIntervalClusterizer new];
        clusterizer.rangeSet = MessageEditTimeIntervalRanges;
    });
    
    return clusterizer;
}

+ (instancetype)callSetupDurationClusterizer
{
    static TimeIntervalClusterizer *clusterizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clusterizer = [TimeIntervalClusterizer new];
        clusterizer.rangeSet = CallSetupTimeIntervalRanges;
    });
    
    return clusterizer;
}

- (NSString *)clusterizeTimeInterval:(NSTimeInterval)ti
{
    return [self clusterizeInteger:roundf(ti)];
}

@end
