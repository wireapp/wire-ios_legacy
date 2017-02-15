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


#import "AnalyticsLocalyticsProvider.h"
#import <Localytics/Localytics.h>
#import "DefaultIntegerClusterizer.h"
#import "DeveloperMenuState.h"




@implementation AnalyticsLocalyticsProvider

- (instancetype)initWithLaunchOptions:(NSDictionary *)launchOptions
{
    self = [super init];
    if (self) {
        [self createSessionWithLaunchOptions:launchOptions];
    }
    return self;
}

- (void)setIsOptedOut:(BOOL)optedOut
{
    if (self.isOptedOut == optedOut) {
        return;
    }
    
    [Localytics setOptedOut:optedOut];
}

- (BOOL)isOptedOut
{
    return [Localytics isOptedOut];
}

- (void)createSessionWithLaunchOptions:(NSDictionary *)launchOptions
{
    [Localytics setLoggingEnabled:DeveloperMenuState.developerMenuEnabled];
    [Localytics autoIntegrate:@STRINGIZE(ANALYTICS_API_KEY) launchOptions:launchOptions];
}

- (void)setCustomerID:(NSString *)customerID
{
    [Localytics setCustomerId:customerID];
}

- (void)tagScreen:(NSString *)screen
{
    [Localytics tagScreen:screen];
}

- (void)tagEvent:(NSString *)event
{
    [Localytics tagEvent:event];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes
{
    [Localytics tagEvent:event attributes:attributes];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes
    customerValueIncrease:(NSNumber *)customerValueIncrease
{
    [Localytics tagEvent:event attributes:attributes customerValueIncrease:customerValueIncrease];
}


- (void)setCustomDimension:(int)dimension value:(NSString *)value
{
    [Localytics setValue:value forCustomDimension:dimension];
}

@end
