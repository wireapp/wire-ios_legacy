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


#import "AnalyticsBase.h"
#import "AnalyticsLocalyticsProvider.h"
#import "Analytics+SessionEvents.h"
#import "Analytics+Metrics.h"
#import "AnalyticsVoiceChannelTracker.h"
#import "AnalyticsConversationListObserver.h"
#import "AnalyticsConversationVerifiedObserver.h"
#import "AnalyticsDecryptionFailedObserver.h"

#import "AnalyticsOptEvent.h"

#import "SessionObjectCache.h"
#import "ZMUser+Additions.h"
#import "AppController.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import "zmessaging+iOS.h"
#else
#import "zmessaging+OS_X.h"
#endif

#import "ZMUser+Additions.h"
#import "DefaultIntegerClusterizer.h"

#import <NSObject+ObjectMap.h>
#import <CocoaSecurity/CocoaSecurity.h>
#import <avs/AVSFlowManager.h>

#import "Wire-Swift.h"


static NSString *const AnalyticsUserDefaultsDisabledKey = @"AnalyticsUserDefaultsDisabledKey";

@interface Analytics (Serialization)

- (void)saveSessionStartDate:(NSDate *)startDate;
- (NSDate *)loadSessionStartDate;

- (void)saveSessionBackgroundedDate:(NSDate *)date;
- (NSDate *)loadSessionBackgroundedDate;

- (void)saveSessionSummary;
- (BOOL)loadSessionSummary;

@end



@interface Analytics ()

@property (readonly, nonatomic) id<AnalyticsProvider> activeProvider;
@property (nonatomic, strong) id<AnalyticsProvider> provider;
@property (nonatomic, strong) AnalyticsSessionSummaryEvent *sessionSummary;
@property (nonatomic, strong) AnalyticsVoiceChannelTracker *voiceChannelTracker;
@property (nonatomic, strong, readwrite) AnalyticsRegistration *analyticsRegistration;
@property (nonatomic, strong) AnalyticsConversationListObserver *conversationListObserver;
@property (nonatomic, strong) AnalyticsConversationVerifiedObserver *conversationVerifiedObserver;
@property (nonatomic, strong) AnalyticsDecryptionFailedObserver *decryptionFailedObserver;
@property (nonatomic, strong) AnalyticsFileTransferObserver *fileTransferObserver;

@end



@implementation Analytics

@synthesize disabled = _disabled;

- (instancetype)initWithProvider:(id<AnalyticsProvider>)provider
{
    self = [super init];
    if (self) {
        
        self.provider = provider;
        [Analytics updateAVSMetricsSettingsWithActiveProvider:self.provider];

        NSNumber *isDisabledNumber = [[NSUserDefaults standardUserDefaults] valueForKey:AnalyticsUserDefaultsDisabledKey];
        _disabled = (isDisabledNumber == nil) ? NO : isDisabledNumber.boolValue;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackingIdentifierChanged:) name:ZMUserSessionTrackingIdentifierDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSessionDidBecomeAvailable:) name:ZMUserSessionDidBecomeAvailableNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDisabled:(BOOL)disabled
{
    _disabled = disabled;
    DDLogDebug(@"Analytics toggled %@", disabled ? @"DISABLED" : @"ENABLED");

    [[NSUserDefaults standardUserDefaults] setBool:disabled forKey:AnalyticsUserDefaultsDisabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isOptedOut
{
    return self.activeProvider.isOptedOut;
}

- (void)setIsOptedOut:(BOOL)isOptedOut
{
    AnalyticsOptEvent *optEvent = [AnalyticsOptEvent eventForAnalyticsOptedOut:isOptedOut];
    if (isOptedOut) {
        [self tagEventObject:optEvent source:AnalyticsEventSourceUI];
    }
    
    self.activeProvider.isOptedOut = isOptedOut;

    if (! isOptedOut) {
        [self tagEventObject:optEvent source:AnalyticsEventSourceUI];
    }

    [Analytics updateAVSMetricsSettingsWithActiveProvider:self.activeProvider];
}

- (id<AnalyticsProvider>)activeProvider
{
    return self.disabled ? nil : self.provider;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self saveSessionBackgroundedDate:[NSDate new]];
    [self saveSessionSummary];
}

- (void)setObservingConversationList:(BOOL)observingConversationList
{
    _observingConversationList = observingConversationList;
    self.conversationListObserver.observing = observingConversationList;
}

- (void)trackingIdentifierChanged:(NSNotification *)note
{
    [self setTrackingIDFromUserSession];
}

- (void)userSessionDidBecomeAvailable:(NSNotification *)note
{
    self.voiceChannelTracker            = [[AnalyticsVoiceChannelTracker alloc] initWithAnalytics:self];
    self.conversationListObserver       = [[AnalyticsConversationListObserver alloc] initWithAnalytics:self];
    self.decryptionFailedObserver       = [[AnalyticsDecryptionFailedObserver alloc] initWithAnalytics:self];
    self.fileTransferObserver           = [[AnalyticsFileTransferObserver alloc] init];
    self.conversationVerifiedObserver   = [[AnalyticsConversationVerifiedObserver alloc] initWithAnalytics:self];
    
    [self setTrackingIDFromUserSession];
}

- (void)setTrackingIDFromUserSession
{
    NSString *trackingID = [ZMUserSession sharedSession].trackingIdentifier;
    if (trackingID.length > 0) {
        [self.activeProvider setCustomerID:trackingID];
    }
}

- (void)tagScreen:(NSString *)screen
{
    [self.activeProvider tagScreen:screen];
}

- (void)tagEvent:(NSString *)event
{
    [self.activeProvider tagEvent:event];
}

- (void)tagEvent:(NSString *)event source:(AnalyticsEventSource)source
{
    [self tagEvent:event attributes:nil source:source];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes
{    
    [self.activeProvider tagEvent:event attributes:attributes];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes source:(AnalyticsEventSource)source
{
    [self tagEvent:event attributes:attributes source:source customerValueIncrease:nil];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes source:(AnalyticsEventSource)source customerValueIncrease:(NSNumber *)customerValueIncrease
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
    
    [self.activeProvider tagEvent:event attributes:attributes customerValueIncrease:customerValueIncrease];
}

- (void)tagEventObject:(AnalyticsEvent *)event
{
    [self tagEventObject:event source:AnalyticsEventSourceUnspecified];
}

- (void)tagEventObject:(AnalyticsEvent *)event source:(AnalyticsEventSource)source
{
    NSString *tag = [event eventTag];
    
    NSAssert(tag != nil, @"analytics event object returned nil tag");
    
    [self tagEvent:tag attributes:[event attributesDump] source:source customerValueIncrease:[event customerValueIncrease]];
}


- (void)sendCustomDimensionsWithNumberOfContacts:(NSUInteger)contacts
                              groupConversations:(NSUInteger)groupConv
                                     accentColor:(NSInteger)accent
                                     networkType:(NSString *)networkType
                       notificationConfiguration:(NSString*)config
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.dateFormat = @"EEEE";
    NSString *dayString = [dateFormatter stringFromDate:[NSDate date]];
    
    [self.activeProvider setCustomDimension:0 value:dayString];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.locale = [[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
    timeFormatter.dateFormat = @"H";
    NSString *timeString = [timeFormatter stringFromDate:[NSDate date]];
    
    [self.activeProvider setCustomDimension:1 value:timeString];
    
    IntRange r[] = {{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 10}, {11, 20}, {21, 30}, {31, 40}, {41, 50}, {51, 60}};
    RangeSet rSet = {r, 10};
    
    DefaultIntegerClusterizer *clusterizer = [DefaultIntegerClusterizer new];
    clusterizer.rangeSet = rSet;
    
    [self.activeProvider setCustomDimension:2 value:[clusterizer clusterizeInteger:(int) contacts]];
    [self.activeProvider setCustomDimension:3 value:[clusterizer clusterizeInteger:(int) groupConv]];
    
    NSString *composedConfigKey = [NSString stringWithFormat:@"%ld_%@_%@", (long)accent, config, networkType];
    
    [self.activeProvider setCustomDimension:4 value:composedConfigKey];
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
