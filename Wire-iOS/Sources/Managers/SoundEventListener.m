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


#import "SoundEventListener.h"

#import "WireSyncEngine+iOS.h"
#import "avs+iOS.h"
#import "ZClientViewController.h"
#import "SoundEventRulesWatchDog.h"
#import "AppDelegate.h"
#import "Wire-Swift.h"

@import AVFoundation;

static NSTimeInterval const SoundEventListenerIgnoreTimeForPushStart = 2.0;



@interface SoundEventListener () <VoiceChannelStateObserver, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver>


@property (nonatomic) id unreadMessageObserverToken;
@property (nonatomic) id unreadKnockMessageObserverToken;
@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id initialSyncObserverToken;

@property (nonatomic) ZMConversation *currentlyActiveVoiceChannelConversation;
@property (nonatomic) NSMutableDictionary<NSManagedObjectID *, NSNumber *> *previousVoiceChannelState;
@property (nonatomic) SoundEventRulesWatchDog *watchDog;

@end

@interface SoundEventListener (ShutterWatchDog) <ZMInitialSyncCompletionObserver>

- (void)applicationWillEnterForeground:(NSNotification *)application;

@end


@implementation SoundEventListener

- (id)init
{
    self = [super init];
    if (self) {
        self.voiceChannelStateObserverToken = [VoiceChannelV3 addStateObserver:self userSession:[ZMUserSession sharedSession]];
        self.unreadMessageObserverToken = [NewUnreadMessagesChangeInfo addNewMessageObserver:self forUserSession:[ZMUserSession sharedSession]];
        self.unreadKnockMessageObserverToken = [NewUnreadKnockMessagesChangeInfo addNewKnockObserver:self forUserSession:[ZMUserSession sharedSession]];
        
        self.watchDog = [[SoundEventRulesWatchDog alloc] initWithIgnoreTime:SoundEventListenerIgnoreTimeForPushStart];
        self.watchDog.startIgnoreDate = [NSDate date];
        self.previousVoiceChannelState = [[NSMutableDictionary alloc] init];
        self.initialSyncObserverToken = [ZMUserSession addInitialSyncCompletionObserver:self userSession:[ZMUserSession sharedSession]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveNewUnreadMessages:(NewUnreadMessagesChangeInfo *)change
{
    for (id<ZMConversationMessage>message in change.messages) {
        // Rules:
        // * Not silenced
        // * Only play regular message sound if it's not from the self user
        // * If this is the first message in the conversation, don't play the sound
        // * Message is new (recently sent)
        BOOL messageWorthNotifying = ([Message isNormalMessage:message] || [Message isSystemMessage:message]);
        BOOL isTimelyMessage = [[NSDate date] timeIntervalSinceDate:message.serverTimestamp] <= (0.5f);
        
        if (message.conversation.isSilenced || [message.sender isSelfUser] || (message.conversation.messages.count == 1) || ! messageWorthNotifying || ! isTimelyMessage) {
            continue;
        }
        
        NSUInteger lastReadMessageIndex = [message.conversation.messages indexOfObject:message.conversation.lastReadMessage];
        NSUInteger messageAfterLastReadMessageIndex;
        if (lastReadMessageIndex == NSNotFound) {
            messageAfterLastReadMessageIndex = 0;
        } else {
            messageAfterLastReadMessageIndex = lastReadMessageIndex + 1;
        }
        
        BOOL messageIsMessageAfterLastReadMessage = NO;
        if (messageAfterLastReadMessageIndex < message.conversation.messages.count) {
            id<ZMConversationMessage>messageAfterLastReadMessage = message.conversation.messages[messageAfterLastReadMessageIndex];
            if ([message isEqual:messageAfterLastReadMessage]) {
                messageIsMessageAfterLastReadMessage = YES;
            }
        }
        
        if (messageIsMessageAfterLastReadMessage) {
            // We play the first_message sound for first message after the last
            // read message
            [self playSoundIfAllowed:MediaManagerSoundFirstMessageReceivedSound];
        }
        else {
            [self playSoundIfAllowed:MediaManagerSoundMessageReceivedSound];
        }
    }
}

- (void)playSoundIfAllowed:(NSString *)soundName
{
    if (soundName.length == 0) {
        return;
    }
    if (! self.watchDog.outputAllowed) {
        DDLogDebug(@"initial sync not completed yet. Sound '%@' will not be played", soundName);
        return;
    }
    
    if ([AVAudioSession sharedInstance].category == AVAudioSessionCategoryPlayAndRecord) {
        DDLogDebug(@"Recording in progress");
        return;
    }

    [[[AVSProvider shared] mediaManager] playSound:soundName];
}

- (void)didReceiveNewUnreadKnockMessages:(NewUnreadKnockMessagesChangeInfo *)change
{
    for (id<ZMConversationMessage>message in change.messages) {
        if (message.conversation.isSilenced) {
            continue;
        }
        
        BOOL isTimelyMessage = [[NSDate date] timeIntervalSinceDate:message.serverTimestamp] <= (0.5f);
        
        if ([Message isKnockMessage:message] && isTimelyMessage) {
            
            if (! [message.sender isSelfUser]) {
                [self playSoundIfAllowed:MediaManagerSoundIncomingKnockSound];
            }
        }
    }
}

- (void)callCenterDidChangeVoiceChannelState:(VoiceChannelV2State)voiceChannelState conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    VoiceChannelV2State state = voiceChannelState;
    VoiceChannelV2State previousState = self.previousVoiceChannelState[conversation.objectID].integerValue ?: VoiceChannelV2StateInvalid;
    self.previousVoiceChannelState[conversation.objectID] = @(voiceChannelState);
    
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    
    switch (state) {
            
        case VoiceChannelV2StateOutgoingCall: {
            if (conversation.voiceChannel.isVideoCall) {
                [mediaManager playSound:MediaManagerSoundRingingFromMeVideoSound];
            }
            else {
                [mediaManager playSound:MediaManagerSoundRingingFromMeSound];
            }
            break;
        }
        case VoiceChannelV2StateOutgoingCallInactive: {
            [mediaManager stopSound:MediaManagerSoundRingingFromMeSound];
            [mediaManager stopSound:MediaManagerSoundRingingFromMeVideoSound];
            break;
        }
        case VoiceChannelV2StateSelfConnectedToActiveChannel: {
            [mediaManager playSound:MediaManagerSoundUserJoinsVoiceChannelSound];
            break;
        }
        case VoiceChannelV2StateIncomingCall: {
            if (![ZMUserSession useCallKit] && ! conversation.isSilenced) {
                
                BOOL otherVoiceChannelIsActive = NO;
                
                for (ZMConversation *activeCallConversation in [WireCallCenter activeCallConversationsInUserSession:[ZMUserSession sharedSession]]) {
                    if (conversation != activeCallConversation) {
                        otherVoiceChannelIsActive = YES;
                        break;
                    }
                }
                                
                if (otherVoiceChannelIsActive) {
                    [mediaManager playSound:MediaManagerSoundRingingFromThemInCallSound];
                }
                else {                    
                    [mediaManager playSound:MediaManagerSoundRingingFromThemSound];
                }
            }
            break;
        }
        case VoiceChannelV2StateIncomingCallInactive: {
            [mediaManager stopSound:MediaManagerSoundRingingFromThemInCallSound];
            [mediaManager stopSound:MediaManagerSoundRingingFromThemSound];
            break;
        }
        case VoiceChannelV2StateIncomingCallDegraded:
        case VoiceChannelV2StateOutgoingCallDegraded:
        case VoiceChannelV2StateNoActiveUsers:
        case VoiceChannelV2StateSelfIsJoiningActiveChannel:
        case VoiceChannelV2StateSelfIsJoiningActiveChannelDegraded:
        case VoiceChannelV2StateEstablishedDataChannel:
        case VoiceChannelV2StateDeviceTransferReady:
        case VoiceChannelV2StateInvalid: {
            break;
        }
    }
    if ((state != VoiceChannelV2StateOutgoingCall) &&
        (state != VoiceChannelV2StateIncomingCall) &&
        !(state == VoiceChannelV2StateSelfIsJoiningActiveChannel && previousState == VoiceChannelV2StateOutgoingCall)) // Hide connecting phase
    {
        [mediaManager stopSound:MediaManagerSoundRingingFromThemInCallSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromMeSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromMeVideoSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromThemSound];
    }
}

- (void)callCenterDidFailToJoinVoiceChannelWithError:(NSError *)error conversation:(ZMConversation *)conversation
{

}

- (void)callCenterDidEndCallWithReason:(VoiceChannelV2CallEndReason)reason conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    
    if (reason == VoiceChannelV2CallEndReasonRequested || reason == VoiceChannelV2CallEndReasonRequestedSelf) {
        [mediaManager playSound:MediaManagerSoundUserLeavesVoiceChannelSound];
    } else {
        [mediaManager playSound:MediaManagerSoundCallDropped];
    }
}

@end



@implementation SoundEventListener (ShutterWatchDog)

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    self.watchDog.startIgnoreDate = [NSDate date];
    // Check if need to ignore any sounds till SE is handling the initial sync
    self.watchDog.muted = ([ZMUserSession sharedSession].networkState == ZMNetworkStateOnlineSynchronizing);
    // In case of push notification start we ignore any sounds for a certain time
    if ([AppDelegate sharedAppDelegate].launchType == ApplicationLaunchPush) {
        self.watchDog.ignoreTime = SoundEventListenerIgnoreTimeForPushStart;
    } else {
        self.watchDog.ignoreTime = 0.0;
    }
}

- (void)initialSyncCompleted
{
    // SE is done with the syncing, we can go on with the playing of the sounds again
    self.watchDog.muted = NO;
}

@end
