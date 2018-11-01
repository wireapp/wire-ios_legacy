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

#import "Analytics.h"
#import "Analytics+Internal.h"
#import "ZMUser+Additions.h"
#import "WireSyncEngine+iOS.h"
#import "ZMUser+Additions.h"
#import "AnalyticsDecryptionFailedObserver.h"
#import <avs/AVSFlowManager.h>
#import "Wire-Swift.h"


@class AnalyticsProvider;
static NSString* ZMLogTag ZM_UNUSED = @"Analytics";

NSString * PersistedAttributesKey = @"AnalyticsPersistedEventAttributes";
BOOL UseAnalytics = USE_ANALYTICS;

@interface Analytics ()

@property (nonatomic, strong) AnalyticsSessionSummaryEvent *sessionSummary;
@property (nonatomic, strong) AnalyticsCallingTracker *callingTracker;
@property (nonatomic, strong) AnalyticsDecryptionFailedObserver *decryptionFailedObserver;

@property (nonatomic, strong, readwrite) AnalyticsRegistration *analyticsRegistration;

@end

static Analytics *sharedAnalytics = nil;

@implementation Analytics

@synthesize team = _team;

+ (instancetype)shared
{
    return sharedAnalytics;
}

+ (void)loadSharedWithOptedOut:(BOOL)optedOut
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAnalytics = [[Analytics alloc] initWithOptedOut:optedOut];
    });
}

- (instancetype)initWithOptedOut:(BOOL)optedOut
{
    self = [super init];
    if (self) {
        ZMLogInfo(@"Analytics initWithOptedOut: %lu", (unsigned long)optedOut);
        self.provider = optedOut ? nil : [[AnalyticsProviderFactory shared] analyticsProvider];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSessionDidBecomeAvailable:) name:ZMUserSessionDidBecomeAvailableNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTeam:(Team *)team
{
    _team = team;
    if (nil == team) {
        [self.provider setSuperProperty:@"team.size" value:@"0"];
        [self.provider setSuperProperty:@"team.in_team" value:@(NO)];
    }
    else {
        [self.provider setSuperProperty:@"team.size" value:[NSString stringWithFormat:@"%lu", (unsigned long)[team.members count]]];
        [self.provider setSuperProperty:@"team.in_team" value:@(YES)];
    }
}

- (void)userSessionDidBecomeAvailable:(NSNotification *)note
{
    self.callingTracker                 = [[AnalyticsCallingTracker alloc] initWithAnalytics:self];
    self.decryptionFailedObserver       = [[AnalyticsDecryptionFailedObserver alloc] initWithAnalytics:self];
    self.team = [[ZMUser selfUser] team];
}

- (void)tagEvent:(NSString *)event
{
    [self.provider tagEvent:event attributes:[NSDictionary dictionary]];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes team:(nullable Team *)team
{
    Team *currentTeam = self.team;
    self.team = team;
    [self.provider tagEvent:event attributes:attributes];
    self.team = currentTeam;
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.provider tagEvent:event attributes:attributes];
    });
}

- (NSDictionary<NSString *,id> * _Nullable)persistedAttributesForEvent:(NSString * _Nonnull)event
{
    NSDictionary *persistedAttributes = [[NSUserDefaults standardUserDefaults] objectForKey:PersistedAttributesKey];
    NSDictionary *eventAttributes = persistedAttributes[event];
    return eventAttributes;
}

- (void)setPersistedAttributes:(NSDictionary<NSString *,id> * _Nullable)attributes forEvent:(NSString * _Nonnull)event
{
    NSDictionary *persisted = [[NSUserDefaults standardUserDefaults] objectForKey:PersistedAttributesKey];
    NSMutableDictionary *persistedAttributes = persisted == nil ? [NSMutableDictionary dictionary] : [persisted mutableCopy];
    if (attributes == nil) {
        [persistedAttributes removeObjectForKey:event];
    } else {
        persistedAttributes[event] = attributes;
    }
    [[NSUserDefaults standardUserDefaults] setObject:persistedAttributes forKey:PersistedAttributesKey];
}

@end
