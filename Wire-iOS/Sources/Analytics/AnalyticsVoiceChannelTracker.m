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
#import "zmessaging+iOS.h"
#import <ZMCDataModel/ZMVoiceChannelNotifications.h>



@interface AnalyticsVoiceChannelTracker () <ZMVoiceChannelStateObserver, ZMCallEndObserver>

@property (nonatomic) BOOL initiatedCall;
@property (nonatomic) BOOL isVideoCall;
@property (nonatomic) NSDate *callEstablishedDate;

@property (nonatomic) Analytics *analytics;
@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;

@end



@implementation AnalyticsVoiceChannelTracker

- (instancetype)initWithAnalytics:(Analytics *)analytics
{
    self = [super init];
    
    if (self) {
        self.analytics = analytics;
        self.voiceChannelStateObserverToken = [ZMVoiceChannel addGlobalVoiceChannelStateObserver:self inUserSession:[ZMUserSession sharedSession]];
        [ZMCallEndedNotification addCallEndObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
    [ZMVoiceChannel removeGlobalVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken inUserSession:[ZMUserSession sharedSession]];
    [ZMCallEndedNotification removeCallEndObserver:self];
}

#pragma mark - VoiceChannelStateObserver

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    ZMVoiceChannelState currentState = change.currentState;
    ZMVoiceChannelState previousState = change.previousState;
    ZMConversation *conversation = change.voiceChannel.conversation;
    
    if (currentState == ZMVoiceChannelStateOutgoingCall) {
        self.initiatedCall = YES;
        self.isVideoCall = conversation.isVideoCall;
        [self.analytics tagInitiatedCallInConversation:conversation video:self.isVideoCall];
    }
    else if (currentState == ZMVoiceChannelStateIncomingCall) {
        self.isVideoCall = conversation.isVideoCall;
        [self.analytics tagReceivedCallInConversation:conversation video:self.isVideoCall];
    }
    else if (currentState == ZMVoiceChannelStateSelfIsJoiningActiveChannel) {
        self.initiatedCall = (previousState == ZMVoiceChannelStateOutgoingCall || previousState == ZMVoiceChannelStateOutgoingCallInactive);
        [self.analytics tagJoinedCallInConversation:conversation video:self.isVideoCall initiatedCall:self.initiatedCall];
    }
    else if (currentState == ZMVoiceChannelStateSelfConnectedToActiveChannel && nil == self.callEstablishedDate) {
        self.callEstablishedDate = [NSDate date];
        [self.analytics tagEstablishedCallInConversation:conversation video:self.isVideoCall initiatedCall:self.initiatedCall];
    }
}

#pragma mark - ZMCallEndObserver

- (void)didEndCall:(ZMCallEndedNotification *)note
{
    [self.analytics tagEndedCallInConversation:note.conversation
                                         video:self.isVideoCall
                                 initiatedCall:self.initiatedCall
                                      duration:-[self.callEstablishedDate timeIntervalSinceNow]
                                        reason:note.reason];
    self.callEstablishedDate = nil;
}

@end
