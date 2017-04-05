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


#import "AnalyticsConversationListObserver.h"

#import "Analytics.h"
#import <WireSyncEngine/WireSyncEngine.h>
#import "ZMUser+Additions.h"

#import "SessionObjectCache.h"

#import "avs+iOS.h"
#import "Wire-Swift.h"


#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#endif




const NSTimeInterval PermantentConversationListObserverObservationTime = 10.0f;
const NSTimeInterval PermantentConversationListObserverObservationFinalTime = 20.0f;



@interface AnalyticsConversationListObserver () <ZMConversationListObserver>

@property (nonatomic, strong) NSDate *observationStartDate;
@property (nonatomic, strong) Analytics *analytics;
@property (nonatomic) id conversationListObserverToken;

@end



@implementation AnalyticsConversationListObserver

- (instancetype)initWithAnalytics:(Analytics *)analytics
{
    self = [super init];
    if (self) {

        self.analytics = analytics;
    }
    return self;
}

- (void)setObserving:(BOOL)observing
{
    if (_observing == observing) {
        return;
    }

    _observing = observing;

    if (self.observing) {
        self.observationStartDate = [NSDate date];

        self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self forList:[SessionObjectCache sharedCache].allConversations];

        [self performSelector:@selector(probablyReceivedFullConversationList)
                   withObject:nil
                   afterDelay:PermantentConversationListObserverObservationFinalTime];
    } else {
        if (self.conversationListObserverToken != nil) {
            [ConversationListChangeInfo removeObserver:self.conversationListObserverToken forList:[SessionObjectCache sharedCache].allConversations];
        }
    }
}

- (void)probablyReceivedFullConversationList
{
    NSUInteger groupConvCount = 0;
    NSUInteger connectionCount = 0;
    
    for (ZMConversation *conversation in [SessionObjectCache sharedCache].allConversations) {
        
        if (conversation.conversationType == ZMConversationTypeOneOnOne) {
            connectionCount++;
        }
        else if (conversation.conversationType == ZMConversationTypeGroup) {
            groupConvCount ++;
        }
    }
    
    ZMAccentColor accentColor = [ZMUser selfUser].accentColorValue;
    NSString *networkType = @"";

    // Get network type: either wifi, 2G, 3G or 4G
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    
    NSString *currentNetworkType = networkInfo.currentRadioAccessTechnology;
    
    if ([currentNetworkType isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [currentNetworkType isEqualToString:CTRadioAccessTechnologyEdge] ||
        [currentNetworkType isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        networkType = @"2G";
    }
    else if ([currentNetworkType isEqualToString:CTRadioAccessTechnologyHSDPA] ||
             [currentNetworkType isEqualToString:CTRadioAccessTechnologyHSUPA] ||
             [currentNetworkType isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        networkType = @"3G";
    }
    else if ([currentNetworkType isEqualToString:CTRadioAccessTechnologyLTE]) {
        networkType = @"4G";
    }
    else if ([NetworkStatus sharedStatus].reachability == ServerReachabilityOK){
        networkType = @"wifi";
    }
    
    NSString *soundIntensityType = @"";
    
    switch ([[AVSProvider shared] mediaManager].intensityLevel) {
        case AVSIntensityLevelFull:
            soundIntensityType = @"alwaysPlay";
            break;
        case AVSIntensityLevelSome:
            soundIntensityType = @"firstMessageOnly";
            break;
        case AVSIntensityLevelNone:
            soundIntensityType = @"neverPlay";
            break;
        default:
            break;
    }

    [self.analytics sendCustomDimensionsWithNumberOfContacts:connectionCount
                                          groupConversations:groupConvCount
                                                 accentColor:accentColor
                                                 networkType:networkType
                                   notificationConfiguration:soundIntensityType];

    self.observing = NO;
}

#pragma mark - ZMConversationListObserver

- (void)conversationListDidChange:(ConversationListChangeInfo *)change
{
    NSTimeInterval timeFromStart = [NSDate timeIntervalSinceReferenceDate] - [self.observationStartDate timeIntervalSinceReferenceDate];

    if (timeFromStart > PermantentConversationListObserverObservationTime) {
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(probablyReceivedFullConversationList) object:nil];
        [self probablyReceivedFullConversationList];
    }
}

@end
