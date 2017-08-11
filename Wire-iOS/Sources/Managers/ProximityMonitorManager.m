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


#import "ProximityMonitorManager.h"
#import "WireSyncEngine+iOS.h"
#import "Constants.h"
#import "ZClientViewController.h"
#import "avs+iOS.h"
#import "Settings.h"
#import "Wire-Swift.h"


@interface ProximityMonitorManager() <VoiceChannelStateObserver, AVSMediaManagerClientObserver>

@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) VoiceChannelV2State lastVoiceChannelState;


@end



@implementation ProximityMonitorManager

- (id)init
{
    self = [super init];
    
    if (self) {
        self.voiceChannelStateObserverToken = [VoiceChannelV3 addStateObserver:self userSession:[ZMUserSession sharedSession]];


        // Wait and then update initial state so that getting the voice channel doesn't affect startup time
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ZMConversation *activeCallConversation = [WireCallCenter activeCallConversationsInUserSession:[ZMUserSession sharedSession]].firstObject;
            self.lastVoiceChannelState = activeCallConversation.voiceChannel.state;
            [self updateProximityMonitorState];
        });
        
        if (![[Settings sharedSettings] disableAVS]) {
            [AVSMediaManagerClientChangeNotification addObserver:self];
        }
    }
    return self;
}

- (void)dealloc
{
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
}

- (void)updateProximityMonitorState
{
    // Don't use proximity monitoring on the ipad
    if (IS_IPAD) {
        return;
    }
    
    if (self.lastVoiceChannelState == VoiceChannelV2StateOutgoingCall) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
    else {
        BOOL isConnectingOrActive = self.lastVoiceChannelState == VoiceChannelV2StateSelfConnectedToActiveChannel ||
                                    self.lastVoiceChannelState == VoiceChannelV2StateSelfIsJoiningActiveChannel ||
                                    self.lastVoiceChannelState == VoiceChannelV2StateOutgoingCallInactive;
        
        if (isConnectingOrActive && [[AVSProvider shared] mediaManager].speakerEnabled == NO) {
            [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        }
        else {
            [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        }
    }
}

#pragma mark - VoiceChannelStateObserver

- (void)callCenterDidChangeVoiceChannelState:(VoiceChannelV2State)voiceChannelState conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    self.lastVoiceChannelState = voiceChannelState;
    [self updateProximityMonitorState];
}

- (void)callCenterDidFailToJoinVoiceChannelWithError:(NSError *)error conversation:(ZMConversation *)conversation
{
    
}

- (void)callCenterDidEndCallWithReason:(VoiceChannelV2CallEndReason)reason conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    
}

#pragma mark - AVSMediaManagerClientObserver

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    if (notification.speakerEnableChanged) {
        [self updateProximityMonitorState];
    }
}

@end
