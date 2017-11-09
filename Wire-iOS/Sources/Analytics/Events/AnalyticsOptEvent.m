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


#import "AnalyticsOptEvent.h"

@interface AnalyticsOptEvent ()
@property (assign, nonatomic) BOOL optedOut;
@end

@implementation AnalyticsOptEvent

+ (instancetype)eventForAnalyticsOptedOut:(BOOL)optedOut
{
    return [[self alloc] initWithAnalyticsOptedOut:optedOut];
}

- (instancetype)initWithAnalyticsOptedOut:(BOOL)optedOut
{
    self = [super init];
    if (self) {
        self.optedOut = optedOut;
    }
    return self;
}

- (NSString *)eventTag
{
    return self.optedOut ? @"settings.opted_out_tracking" : @"settings.opted_in_tracking";
}

- (NSDictionary *)attributesDump
{
    return @{};
}

@end
