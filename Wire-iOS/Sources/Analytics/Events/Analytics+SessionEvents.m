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


#import "Analytics+SessionEvents.h"
#import "TimeIntervalClusterizer.h"


NSString *ApplicationLaunchTypeToString(ApplicationLaunchType type);




@implementation Analytics (SessionEvents)

- (void)tagAppLaunchWithType:(ApplicationLaunchType)type
{
    [self tagEvent:@"appLaunch" attributes:@{@"mechanism" : ApplicationLaunchTypeToString(type)}];
}

- (void)tagApplicationError:(NSString *)error timeInSession:(NSTimeInterval)time
{
    [self tagEvent:@"App Error" attributes:@{@"error" : error,
                                             @"timeInSession_clusterized" : [[TimeIntervalClusterizer defaultClusterizer] clusterizeTimeInterval:time],
                                             @"timeInSession" : @(time)}];
}

- (void)tagAppException:(NSString *)error screen:(NSString *)screen timeInSession:(NSTimeInterval)time
{
    [self tagEvent:@"App Exception" attributes:@{@"exception" : error,
                                                 @"screen" : screen,
                                                 @"timeInSession_clusterized" : [[TimeIntervalClusterizer defaultClusterizer] clusterizeTimeInterval:time],
                                                 @"timeInSession" : @(time)}];
}

@end



NSString *ApplicationLaunchTypeToString(ApplicationLaunchType type) {
    NSString *trackedLaunchMechanism;
    
    switch (type) {
        case ApplicationLaunchDirect:
            trackedLaunchMechanism = @"direct";
            break;
        case ApplicationLaunchPush:
            trackedLaunchMechanism = @"push";
            break;
        case ApplicationLaunchURL:
            trackedLaunchMechanism = @"url";
            break;
        case ApplicationLaunchRegistration:
            trackedLaunchMechanism = @"registration";
            break;
        case ApplicationLaunchPasswordReset:
            trackedLaunchMechanism = @"passwordReset";
            break;
        case ApplicationLaunchUnknown:
            trackedLaunchMechanism = @"unknown";
            break;
        default:
            trackedLaunchMechanism = @"<undefined>";
            break;
    }
    return trackedLaunchMechanism;
}
