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


#import "Application+runDuration.h"

NSString *const ApplicationTimerKey = @"ApplicationTimerKey";


@implementation UIApplication (runDuration)

- (void)setupRunDurationCalculation
{
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:60.0f target:self selector:@selector(tick) userInfo:nil repeats:YES];
    t.tolerance = 60.0f;
}

- (void)tick
{
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:ApplicationTimerKey];
    [[NSUserDefaults standardUserDefaults] setObject:@([num intValue] + 1) forKey:ApplicationTimerKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval)lastApplicationRunDuration
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:ApplicationTimerKey] intValue] * 60.0f;
}

- (void)resetRunDuration
{
    [[NSUserDefaults standardUserDefaults] setObject:@(0) forKey:ApplicationTimerKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
