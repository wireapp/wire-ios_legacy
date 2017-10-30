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


#import "Analytics+iOS.h"
#import <avs/AVSFlowManager.h>
#import "Settings.h"
#import "Wire-Swift.h"


static BOOL useConsoleAnalytics = NO;
NSString * const ZMConsoleAnalyticsArgumentKey = @"-ConsoleAnalytics";
static NSString * const ZMEnableConsoleLog = @"ZMEnableAnalyticsLog";
static Analytics *sharedAnalytics = nil;

NSString * LocalyticsAPIKey = @STRINGIZE(ANALYTICS_API_KEY);
NSString * MixpanelAPIKey = @STRINGIZE(MIXPANEL_API_KEY);

@implementation Analytics (iOS)

+ (void)setConsoleAnayltics:(BOOL)shouldUseConsoleAnalytics;
{
    useConsoleAnalytics = shouldUseConsoleAnalytics;
}

+ (instancetype)setupSharedInstanceWithLaunchOptions:(NSDictionary *)launchOptions
{
    if (useConsoleAnalytics || [[NSUserDefaults standardUserDefaults] boolForKey:ZMEnableConsoleLog]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            id <AnalyticsProvider> provider = [[AnalyticsConsoleProvider alloc] init];
            sharedAnalytics = [[Analytics alloc] initWithProvider:provider];
        });
        return sharedAnalytics;
    }

    BOOL useAnalytics = USE_ANALYTICS;
    // Don’t track events in debug configuration.
    if (useAnalytics) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            AnalyticsMixpanelProvider *provider = [[AnalyticsMixpanelProvider alloc] init];
            sharedAnalytics = [[Analytics alloc] initWithProvider:provider];
        });
    }

    sharedAnalytics.isOptedOut = [[TrackingManager shared] disableCrashAndAnalyticsSharing];
    
    return sharedAnalytics;
}

+ (instancetype)shared
{
    return sharedAnalytics;
}

@end
