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
    [[[AVSProvider shared] mediaManager] playSound:MediaManagerSoundAlert];
}

static NSDictionary *MediaManagerSoundConfig = nil;

@implementation AVSMediaManager (Additions)

+ (NSURL *)URLForSound:(NSString *)soundName
{
    assert(MediaManagerSoundConfig != nil);
    
    NSDictionary *sound = MediaManagerSoundConfig[@"sounds"][soundName];
    
    NSString *path = sound[@"path"];
    NSString *format = sound[@"format"];
    NSString *audioDir = @"audio-notifications";
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:path ofType:format inDirectory:audioDir];
    
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    assert(soundURL != nil);
    
    return soundURL;
}

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
            DDLogError(@"Couldn't load sound config file: %@", path);
            return;
        }
        
        MediaManagerSoundConfig = soundConfig;
    }
    
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    
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

@end
