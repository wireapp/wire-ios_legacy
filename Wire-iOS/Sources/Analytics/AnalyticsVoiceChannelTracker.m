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


#import "AnalyticsVoiceChannelTracker.h"
#import "Analytics.h"
#import "WireSyncEngine+iOS.h"
#import "DeveloperMenuState.h"


@interface AnalyticsVoiceChannelTracker () <VoiceChannelStateObserver>

@property (nonatomic) BOOL initiatedCall;
@property (nonatomic) BOOL isVideoCall;
@property (nonatomic) NSDate *callEstablishedDate;
@property (nonatomic) NSDate *callAnsweredDate;

@property (nonatomic) Analytics *analytics;
@property (nonatomic) id voiceChannelStateObserverToken;

@end



@implementation AnalyticsVoiceChannelTracker

- (instancetype)initWithAnalytics:(Analytics *)analytics
{
    self = [super init];
    
    if (self) {
        self.analytics = analytics;
        self.voiceChannelStateObserverToken = [VoiceChannelV3 addStateObserver:self userSession:[ZMUserSession sharedSession]];
    }
    
    return self;
}


#pragma mark - VoiceChannelStateObserver

- (void)callCenterDidChangeVoiceChannelState:(VoiceChannelV2State)voiceChannelState conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    if (voiceChannelState == VoiceChannelV2StateOutgoingCall) {
        self.initiatedCall = YES;
        self.isVideoCall = conversation.voiceChannel.isVideoCall;
        [self.analytics tagInitiatedCallInConversation:conversation video:self.isVideoCall callingProtocol:callingProtocol];
    }
    else if (voiceChannelState == VoiceChannelV2StateIncomingCall) {
        self.initiatedCall = NO;
        self.isVideoCall = conversation.voiceChannel.isVideoCall;
        [self.analytics tagReceivedCallInConversation:conversation video:self.isVideoCall callingProtocol:callingProtocol];
    }
    else if (voiceChannelState == VoiceChannelV2StateSelfIsJoiningActiveChannel) {
        self.callAnsweredDate = [NSDate date];
        [self.analytics tagJoinedCallInConversation:conversation video:self.isVideoCall initiatedCall:self.initiatedCall callingProtocol:callingProtocol];
    }
    else if (voiceChannelState == VoiceChannelV2StateSelfConnectedToActiveChannel && nil == self.callEstablishedDate) {
        self.callEstablishedDate = [NSDate date];
        NSTimeInterval setupDuration = [self.callEstablishedDate timeIntervalSinceDate:self.callAnsweredDate];
        [self.analytics tagEstablishedCallInConversation:conversation video:self.isVideoCall initiatedCall:self.initiatedCall setupDuration:setupDuration callingProtocol:callingProtocol];
    }
}

- (void)callCenterDidFailToJoinVoiceChannelWithError:(NSError *)error conversation:(ZMConversation *)conversation
{
    
}

- (void)callCenterDidEndCallWithReason:(VoiceChannelV2CallEndReason)reason conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    if (reason == VoiceChannelV2CallEndReasonInputOutputError && [DeveloperMenuState developerMenuEnabled]) {
        UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Calling error"
                                                       message:@"AVS I/O error"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [view show];
    }
    [self.analytics tagEndedCallInConversation:conversation
                                         video:self.isVideoCall
                                 initiatedCall:self.initiatedCall
                                      duration:-[self.callEstablishedDate timeIntervalSinceNow]
                                        reason:reason
                               callingProtocol:callingProtocol];
    self.callAnsweredDate = nil;
    self.callEstablishedDate = nil;
}

@end
