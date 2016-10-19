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


@interface AnalyticsLocalyticsProvider () <LLAnalyticsDelegate>

@property (nonatomic, copy) ResumeHandlerBlock resumeHandler;

@end



@implementation AnalyticsLocalyticsProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createSession];
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

- (void)createSession
{
    [Localytics setAnalyticsDelegate:self];
    [Localytics setLoggingEnabled:[DeveloperMenuState developerMenuEnabled]];

    [Localytics integrate:@STRINGIZE(ANALYTICS_API_KEY)];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [Localytics openSession];
    }
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

- (void)close
{
    [Localytics dismissCurrentInAppMessage];
    [Localytics closeSession];
}

- (void)resumeWithHandler:(ResumeHandlerBlock)resumeHandler
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        self.resumeHandler = resumeHandler;
        [Localytics openSession];
    }
}

- (void)upload
{
    [Localytics upload];
}

- (void)setCustomDimension:(int)dimension value:(NSString *)value
{
    [Localytics setValue:value forCustomDimension:dimension];
}

- (void)setPushToken:(NSData *)token
{
    [Localytics setPushToken:token];
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo
{
    [Localytics handleNotification:userInfo];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [Localytics handleTestModeURL:url];
}

- (void)localyticsSessionWillOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume
{
    if (self.resumeHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resumeHandler(isResume);
        });
    }
}

@end
