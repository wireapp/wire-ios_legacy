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


#import "AVSMediaManager+Additions.h"
#import <avs/AVSMediaManager+Client.h>
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

NSString *const MediaManagerSoundOutgoingKnockSound = @"ping_from_me";
NSString *const MediaManagerSoundIncomingKnockSound = @"ping_from_them";
NSString *const MediaManagerSoundUserLeavesVoiceChannelSound = @"talk_later";
NSString *const MediaManagerSoundMessageReceivedSound = @"new_message";
NSString *const MediaManagerSoundFirstMessageReceivedSound = @"first_message";
NSString *const MediaManagerSoundSomeoneJoinsVoiceChannelSound = @"talk";
NSString *const MediaManagerSoundReadyToTalkSound = @"ready_to_talk";
NSString *const MediaManagerSoundTransferVoiceToHereSound = @"pull_voice";
NSString *const MediaManagerSoundUserJoinsVoiceChannelSound = @"ready_to_talk";
NSString *const MediaManagerSoundRingingFromMeSound = @"ringing_from_me";
NSString *const MediaManagerSoundRingingFromMeVideoSound = @"ringing_from_me_video";
NSString *const MediaManagerSoundRingingFromThemSound = @"ringing_from_them";
NSString *const MediaManagerSoundRingingFromThemInCallSound = @"ringing_from_them_incall";
NSString *const MediaManagerSoundCallDropped = @"call_drop";
NSString *const MediaManagerSoundAlert = @"alert";
NSString *const MediaManagerSoundCamera = @"camera";
NSString *const MediaManagerSoundSomeoneLeavesVoiceChannelSound = @"talk_later";

void MediaManagerPlayAlert(void) {
    [AVSMediaManager.sharedInstance playSound:MediaManagerSoundAlert];
}

static NSDictionary *MediaManagerSoundConfig = nil;

@implementation AVSMediaManager (Additions)

// Configure default sounds
- (void)configureDefaultSounds
{
    NSString *audioDir = @"audio-notifications";
    
    if (MediaManagerSoundConfig == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MediaManagerConfig"
                                                         ofType:@"plist"
                                                    inDirectory:audioDir];
        
        NSDictionary *soundConfig = [NSDictionary dictionaryWithContentsOfFile:path];
        
        if (! soundConfig) {
            ZMLogError(@"Couldn't load sound config file: %@", path);
            return;
        }
        
        MediaManagerSoundConfig = soundConfig;
    }
    
    AVSMediaManager *mediaManager = AVSMediaManager.sharedInstance;
    
    // Unregister all previous custom sounds
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundFirstMessageReceivedSound];
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundMessageReceivedSound];
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundRingingFromThemInCallSound];
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundRingingFromThemSound];
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundOutgoingKnockSound];
    [mediaManager registerUrl:nil forMedia:MediaManagerSoundIncomingKnockSound];
    
    [mediaManager registerMediaFromConfiguration:MediaManagerSoundConfig
                                     inDirectory:audioDir];
}

- (void)configureSounds
{
    [self configureDefaultSounds];
    // Configure customizable sounds
    [self configureCustomSounds];
}

- (void)enableCallingAudioSessionForVideoCall:(BOOL)isVideoCall
{
    NSString *mode = isVideoCall ? AVAudioSessionModeVideoChat : AVAudioSessionModeVoiceChat;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setMode:mode error:nil];
}

- (void)disableCallingAudioSession
{
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
}

@end
