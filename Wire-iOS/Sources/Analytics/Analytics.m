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
#import "Analytics+SessionEvents.h"
#import "AnalyticsConversationListObserver.h"
#import "AnalyticsConversationVerifiedObserver.h"
#import "AnalyticsDecryptionFailedObserver.h"

#import "AnalyticsOptEvent.h"

#import "ZMUser+Additions.h"

#import "WireSyncEngine+iOS.h"

#import "ZMUser+Additions.h"
#import "DefaultIntegerClusterizer.h"

#import <avs/AVSFlowManager.h>

#import "Wire-Swift.h"


@class AnalyticsProvider;
static NSString* ZMLogTag ZM_UNUSED = @"Analytics";

NSString * MixpanelAPIKey = @STRINGIZE(MIXPANEL_API_KEY);
NSString * PersistedAttributesKey = @"AnalyticsPersistedEventAttributes";
BOOL UseAnalytics = USE_ANALYTICS;

@interface Analytics ()

@property (nonatomic, strong, nullable) id<AnalyticsProvider> provider;
@property (nonatomic, strong) AnalyticsSessionSummaryEvent *sessionSummary;
@property (nonatomic, strong) AnalyticsCallingTracker *callingTracker;
@property (nonatomic, strong, readwrite) AnalyticsRegistration *analyticsRegistration;
@property (nonatomic, strong) AnalyticsConversationListObserver *conversationListObserver;
@property (nonatomic, strong) AnalyticsConversationVerifiedObserver *conversationVerifiedObserver;
@property (nonatomic, strong) AnalyticsDecryptionFailedObserver *decryptionFailedObserver;
@property (nonatomic, strong) AnalyticsFileTransferObserver *fileTransferObserver;

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

- (BOOL)isOptedOut
{
    return self.provider.isOptedOut;
}

- (void)setIsOptedOut:(BOOL)isOptedOut
{
    if (isOptedOut && self.provider.isOptedOut) {
        return;
    }
    
    AnalyticsOptEvent *optEvent = [AnalyticsOptEvent eventForAnalyticsOptedOut:isOptedOut];
    if (isOptedOut) {
        [self tagEventObject:optEvent source:AnalyticsEventSourceUI];
        self.provider.isOptedOut = isOptedOut;
        self.provider = nil;
    }
    else {
        self.provider = [[AnalyticsProviderFactory shared] analyticsProvider];
        self.team = [[ZMUser selfUser] team];
        [self tagEventObject:optEvent source:AnalyticsEventSourceUI];
    }
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

- (void)setObservingConversationList:(BOOL)observingConversationList
{
    _observingConversationList = observingConversationList;
    self.conversationListObserver.observing = observingConversationList;
}

- (void)userSessionDidBecomeAvailable:(NSNotification *)note
{
    self.callingTracker                 = [[AnalyticsCallingTracker alloc] initWithAnalytics:self];
    self.conversationListObserver       = [[AnalyticsConversationListObserver alloc] initWithAnalytics:self];
    self.decryptionFailedObserver       = [[AnalyticsDecryptionFailedObserver alloc] initWithAnalytics:self];
    self.fileTransferObserver           = [[AnalyticsFileTransferObserver alloc] init];
    self.conversationVerifiedObserver   = [[AnalyticsConversationVerifiedObserver alloc] initWithAnalytics:self];
    
    self.team = [[ZMUser selfUser] team];
}

- (void)tagEvent:(NSString *)event
{
    [self.provider tagEvent:event attributes:[NSDictionary dictionary]];
}

- (void)tagEvent:(NSString *)event source:(AnalyticsEventSource)source
{
    [self tagEvent:event attributes:[NSDictionary dictionary] source:source];
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

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes source:(AnalyticsEventSource)source
{
    if (source != AnalyticsEventSourceUnspecified) {
        
        NSMutableDictionary *newAttrs = nil;
        
        if (attributes != nil) {
            newAttrs = [NSMutableDictionary dictionaryWithDictionary:attributes];
        }
        else {
            newAttrs = [[NSMutableDictionary alloc] init];
        }
        
        [newAttrs setObject:[[self class] eventSourceToString:source] forKey:@"source"];
        attributes = newAttrs;
    }
    
    [self.provider tagEvent:event attributes:attributes];
}


- (void)tagEventObject:(AnalyticsEvent *)event
{
    [self tagEventObject:event source:AnalyticsEventSourceUnspecified];
}

- (void)tagEventObject:(AnalyticsEvent *)event source:(AnalyticsEventSource)source
{
    NSString *tag = [event eventTag];
    
    NSAssert(tag != nil, @"analytics event object returned nil tag");
    
    [self tagEvent:tag attributes:[event attributesDump] source:source];
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

- (void)sendCustomDimensionsWithNumberOfContacts:(NSUInteger)contacts
                              groupConversations:(NSUInteger)groupConv
{
    IntRange r[] = {{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 10}, {11, 20}, {21, 30}, {31, 40}, {41, 50}, {51, 60}};
    RangeSet rSet = {r, 10};
    
    DefaultIntegerClusterizer *clusterizer = [DefaultIntegerClusterizer new];
    clusterizer.rangeSet = rSet;
    
    [self.provider setSuperProperty:@"contacts" value:@(contacts).stringValue];
    [self.provider setSuperProperty:@"group_conversations" value:[clusterizer clusterizeInteger:(int) groupConv]];
}

+ (NSString *)eventSourceToString:(AnalyticsEventSource) source
{
    
    NSString *result = nil;
    
    switch (source) {
            
        case AnalyticsEventSourceUnspecified:
            result = @"unspecified";
            break;
            
        case AnalyticsEventSourceMenu:
            result = @"menu";
            break;
            
        case AnalyticsEventSourceShortcut:
            result = @"shortcut";
            break;
            
        case AnalyticsEventSourceUI:
            result = @"UI";
            break;
    }
    
    return result;
}

@end
