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

#import "zmessaging+iOS.h"
#import "avs+iOS.h"
#import "ZClientViewController.h"
#import "ZMUserSession+Additions.h"
#import "SoundEventRulesWatchDog.h"
#import "AppDelegate.h"
#import "Wire-Swift.h"

@import AVFoundation;

static NSTimeInterval const SoundEventListenerIgnoreTimeForPushStart = 2.0;



@interface SoundEventListener () <VoiceChannelStateObserver, VoiceChannelParticipantObserver, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver>


@property (nonatomic) id unreadMessageObserverToken;
@property (nonatomic) id unreadKnockMessageObserverToken;
@property (nonatomic) id voiceChannelStateObserverToken;
@property (nonatomic) id callParticipantsToken;

@property (nonatomic) ZMConversation *currentlyActiveVoiceChannelConversation;
@property (nonatomic) NSMutableDictionary<NSUUID *, NSNumber *> *previousVoiceChannelState;
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
        self.voiceChannelStateObserverToken = [VoiceChannelRouter addStateObserver:self userSession:[ZMUserSession sharedSession]];
        self.unreadMessageObserverToken = [NewUnreadMessagesChangeInfo addNewMessageObserver:self];
        self.unreadKnockMessageObserverToken = [NewUnreadKnockMessagesChangeInfo addNewKnockObserver:self];
        
        self.watchDog = [[SoundEventRulesWatchDog alloc] initWithIgnoreTime:SoundEventListenerIgnoreTimeForPushStart];
        self.watchDog.startIgnoreDate = [NSDate date];
        self.previousVoiceChannelState = [[NSMutableDictionary alloc] init];
        [ZMUserSession addInitalSyncCompletionObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [ZMUserSession removeInitalSyncCompletionObserver:self];
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
    VoiceChannelV2State previousState = self.previousVoiceChannelState[conversation.remoteIdentifier].integerValue ?: VoiceChannelV2StateInvalid;
    self.previousVoiceChannelState[conversation.remoteIdentifier] = @(voiceChannelState);
    
    [self changeObservedVoiceChannelConversation: conversation.voiceChannel];
    
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
            if (previousState == VoiceChannelV2StateDeviceTransferReady) {
                [mediaManager playSound:MediaManagerSoundTransferVoiceToHereSound];
            }
            else {
                [mediaManager playSound:MediaManagerSoundUserJoinsVoiceChannelSound];
            }
            break;
        }
        case VoiceChannelV2StateNoActiveUsers: {
            if ((previousState == VoiceChannelV2StateSelfConnectedToActiveChannel) ||
                (previousState == VoiceChannelV2StateOutgoingCall)) {
                [mediaManager playSound:MediaManagerSoundUserLeavesVoiceChannelSound];
            }
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
        case VoiceChannelV2StateSelfIsJoiningActiveChannel: {
            
            if (previousState == VoiceChannelV2StateDeviceTransferReady) {
                [mediaManager playSound:MediaManagerSoundTransferVoiceToHereSound];
            }
            break;
        }
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
    if (reason == VoiceChannelV2CallEndReasonDisconnected) {
        AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
        [mediaManager stopSound:MediaManagerSoundCallDropped];
    }
}

- (void)changeObservedVoiceChannelConversation:(VoiceChannelRouter *)voiceChannel
{
    if (voiceChannel.conversation == self.currentlyActiveVoiceChannelConversation) {
        if (voiceChannel.state == VoiceChannelV2StateNoActiveUsers) {
            self.callParticipantsToken = nil;
        }
    } else {
        if (voiceChannel.state == VoiceChannelV2StateSelfConnectedToActiveChannel) {
            self.callParticipantsToken = [voiceChannel addParticipantObserver:self];
        }
    }
}

- (void)voiceChannelParticipantsDidChange:(SetChangeInfo *)changeInfo
{
    if (changeInfo.insertedIndexes.count > 0 || changeInfo.deletedIndexes.count > 0) {
        
        if (changeInfo.insertedIndexes.count > 0) {
            [[[AVSProvider shared] mediaManager] playSound:MediaManagerSoundSomeoneJoinsVoiceChannelSound];
        }
        else if (changeInfo.deletedIndexes.count > 0) {
            [[[AVSProvider shared] mediaManager] playSound:MediaManagerSoundSomeoneLeavesVoiceChannelSound];
        }
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

- (void)initialSyncCompleted:(NSNotification *)notification
{
    // SE is done with the syncing, we can go on with the playing of the sounds again
    self.watchDog.muted = NO;
}

@end
