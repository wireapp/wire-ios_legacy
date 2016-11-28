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



@interface SoundEventListener () <ZMVoiceChannelStateObserver, ZMVoiceChannelParticipantsObserver, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver, ZMCallEndObserver>

@property (nonatomic) id <ZMNewUnreadMessageObserverOpaqueToken> unreadMessageObserverToken;
@property (nonatomic) id <ZMNewUnreadKnockMessageObserverOpaqueToken> unreadKnockMessageObserverToken;
@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;
@property (nonatomic) id <ZMVoiceChannelParticipantsObserverOpaqueToken> callParticipantsToken;
@property (nonatomic) ZMConversation *currentlyActiveVoiceChannelConversation;
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
        self.voiceChannelStateObserverToken = [ZMVoiceChannel addGlobalVoiceChannelStateObserver:self inUserSession:[ZMUserSession sharedSession]];
        self.unreadMessageObserverToken = [ZMMessageNotification addNewMessagesObserver:self inUserSession:[ZMUserSession sharedSession]];
        self.unreadKnockMessageObserverToken = [ZMMessageNotification addNewKnocksObserver:self inUserSession:[ZMUserSession sharedSession]];
        [ZMCallEndedNotification addCallEndObserver:self];
        
        self.watchDog = [[SoundEventRulesWatchDog alloc] initWithIgnoreTime:SoundEventListenerIgnoreTimeForPushStart];
        self.watchDog.startIgnoreDate = [NSDate date];
        [ZMUserSession addInitalSyncCompletionObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    if (self.currentlyActiveVoiceChannelConversation != nil) {
        [ZMVoiceChannel removeCallParticipantsObserverForToken:self.callParticipantsToken inConversation:self.currentlyActiveVoiceChannelConversation];
    }
    [ZMVoiceChannel removeGlobalVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken inUserSession:[ZMUserSession sharedSession]];
    [ZMMessageNotification removeNewMessagesObserverForToken:self.unreadMessageObserverToken inUserSession:[ZMUserSession sharedSession]];
    [ZMMessageNotification removeNewKnocksObserverForToken:self.unreadKnockMessageObserverToken inUserSession:[ZMUserSession sharedSession]];
    [ZMCallEndedNotification removeCallEndObserver:self];
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

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    ZMVoiceChannelState state = change.currentState;
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    
    [self changeObservedVoiceChannelConversation: change.voiceChannel];
    switch (state) {
            
        case ZMVoiceChannelStateOutgoingCall: {
            if (change.voiceChannel.conversation.isVideoCall) { // FIXME
                [mediaManager playSound:MediaManagerSoundRingingFromMeVideoSound];
            }
            else {
                [mediaManager playSound:MediaManagerSoundRingingFromMeSound];
            }
            break;
        }
        case ZMVoiceChannelStateOutgoingCallInactive: {
            [mediaManager stopSound:MediaManagerSoundRingingFromMeSound];
            [mediaManager stopSound:MediaManagerSoundRingingFromMeVideoSound];
            break;
        }
        case ZMVoiceChannelStateSelfConnectedToActiveChannel: {
            if (change.previousState == ZMVoiceChannelStateDeviceTransferReady) {
                [mediaManager playSound:MediaManagerSoundTransferVoiceToHereSound];
            }
            else {
                [mediaManager playSound:MediaManagerSoundUserJoinsVoiceChannelSound];
            }
            break;
        }
        case ZMVoiceChannelStateNoActiveUsers: {
            if ((change.previousState == ZMVoiceChannelStateSelfConnectedToActiveChannel) ||
                (change.previousState == ZMVoiceChannelStateOutgoingCall)) {
                [mediaManager playSound:MediaManagerSoundUserLeavesVoiceChannelSound];
            }
            break;
        }
        case ZMVoiceChannelStateIncomingCall: {
            if (![ZMUserSession useCallKit] && ! change.voiceChannel.conversation.isSilenced) {
                
                BOOL otherVoiceChannelIsActive = NO;
                
                for (ZMConversation *conv in [ZMConversationList activeCallConversationsInUserSession:[ZMUserSession sharedSession]]) {
                    // If other voice channel is active
                    if (conv.voiceChannel != change.voiceChannel && conv.voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel) {
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
        case ZMVoiceChannelStateIncomingCallInactive: {
            [mediaManager stopSound:MediaManagerSoundRingingFromThemInCallSound];
            [mediaManager stopSound:MediaManagerSoundRingingFromThemSound];
            break;
        }
        case ZMVoiceChannelStateSelfIsJoiningActiveChannel: {
            
            if (change.previousState == ZMVoiceChannelStateDeviceTransferReady) {
                [mediaManager playSound:MediaManagerSoundTransferVoiceToHereSound];
            }
            break;
        }
        case ZMVoiceChannelStateDeviceTransferReady:
        case ZMVoiceChannelStateInvalid: {
            break;
        }
    }
    if ((state != ZMVoiceChannelStateOutgoingCall) &&
        (state != ZMVoiceChannelStateIncomingCall) &&
        !(state == ZMVoiceChannelStateSelfIsJoiningActiveChannel && change.previousState == ZMVoiceChannelStateOutgoingCall)) // Hide connecting phase
    {
        [mediaManager stopSound:MediaManagerSoundRingingFromThemInCallSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromMeSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromMeVideoSound];
        [mediaManager stopSound:MediaManagerSoundRingingFromThemSound];
    }
}

- (void)changeObservedVoiceChannelConversation:(id<VoiceChannel>)voiceChannel
{
    if (voiceChannel.conversation == self.currentlyActiveVoiceChannelConversation) {
        if (voiceChannel.state == ZMVoiceChannelStateNoActiveUsers) {
            [self unregisterAsCallParticipantObserver];
        }
    } else {
        if (voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel) {
            [self unregisterAsCallParticipantObserver];
//            self.callParticipantsToken = [ZMVoiceChannel addCallParticipantsObserver:self inConversation:voiceChannel.conversation voiceChannel:voiceChannel]; // FIXME
            self.currentlyActiveVoiceChannelConversation = voiceChannel.conversation;
        }
    }
}

- (void)unregisterAsCallParticipantObserver
{
    [ZMVoiceChannel removeCallParticipantsObserverForToken:self.callParticipantsToken inConversation:self.currentlyActiveVoiceChannelConversation];
    self.currentlyActiveVoiceChannelConversation = nil;
}

- (void)didEndCall:(ZMCallEndedNotification *)note
{
    if (note.reason == ZMVoiceChannelCallEndReasonDisconnected) {
        AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
        [mediaManager stopSound:MediaManagerSoundCallDropped];
    }
}

- (void)voiceChannelParticipantsDidChange:(VoiceChannelParticipantsChangeInfo *)change
{
    if (change.insertedIndexes.count > 0 || change.deletedIndexes.count > 0) {
        
        if (change.insertedIndexes.count > 0) {
            [[[AVSProvider shared] mediaManager] stopSound:MediaManagerSoundSomeoneJoinsVoiceChannelSound];
        }
        else if (change.deletedIndexes.count > 0) {
            [[[AVSProvider shared] mediaManager] stopSound:MediaManagerSoundSomeoneLeavesVoiceChannelSound];
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
