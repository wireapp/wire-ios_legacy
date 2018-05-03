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


@import MediaPlayer;
@import WireSystem;

#import "MediaPlaybackManager.h"
#import "MediaPlayer.h"
#import "AudioTrackPlayer.h"
#import "KeyValueObserver.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

NSString *const MediaPlaybackManagerPlayerStateChangedNotification = @"MediaPlaybackManagerPlayerStateChangedNotification";


@interface MediaPlaybackManager ()

@property (nonatomic) id<MediaPlayer> activeMediaPlayer;
@property (nonatomic) AudioTrackPlayer *audioTrackPlayer;

@property (nonatomic, retain) NSObject *titleObserver;

@end

@implementation MediaPlaybackManager

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self) {
        self.name = name;
        self.audioTrackPlayer = [[AudioTrackPlayer alloc] init];
        self.audioTrackPlayer.mediaPlayerDelegate = self;
        self.titleObserver = nil;
    }
    
    return self;
}

#pragma mark - AVSMedia

@synthesize delegate = _delegate;
@synthesize volume = _volume;
@synthesize recordingMuted = _recordingMuted;
@synthesize looping = _looping;
@synthesize name = _name;

- (void)play
{
    // AUDIO-557 workaround for AVSMediaManager calling play after we say we started to play.
    if (self.activeMediaPlayer.state != MediaPlayerStatePlaying) {
        [self.activeMediaPlayer play];
    }
}

- (void)pause
{
    // AUDIO-557 workaround for AVSMediaManager calling pause after we say we are paused.
    if (self.activeMediaPlayer.state == MediaPlayerStatePlaying) {
        [self.activeMediaPlayer pause];
    }
}

- (void)stop
{
    // AUDIO-557 workaround for AVSMediaManager calling stop after we say we are stopped.
    if (self.activeMediaPlayer.state != MediaPlayerStateCompleted) {
        [self.activeMediaPlayer stop];
    }
}

- (void)resume
{
    [self.activeMediaPlayer play];
}

- (void)reset {
    [self.audioTrackPlayer stop];
    
    self.audioTrackPlayer = [[AudioTrackPlayer alloc] init];
    self.audioTrackPlayer.mediaPlayerDelegate = self;
}

- (BOOL)looping
{
    return NO;
}

- (void)setPlaybackMuted:(BOOL)playbackMuted
{
    if (playbackMuted) {
        [self.activeMediaPlayer pause];
    }
}

- (BOOL)playbackMuted
{
    return NO;
}

#pragma mark - MediaPlayer delegate

- (void)mediaPlayer:(id<MediaPlayer>)mediaPlayer didChangeToState:(MediaPlayerState)state
{
    ZMLogDebug(@"mediaPlayer changed state: %@", @(state));
    [self.changeObserver activeMediaPlayerStateDidChange];

    switch (state) {
        case MediaPlayerStatePlaying:
            if (self.activeMediaPlayer != mediaPlayer) {
                [self.activeMediaPlayer pause];
            }
            
            if ([self.delegate respondsToSelector:@selector(didStartPlayingMedia:)]) {
                [self.delegate didStartPlayingMedia:self];
            }
            
            self.activeMediaPlayer = mediaPlayer;
            [self startObservingMediaPlayerChanges];
            break;
            
        case MediaPlayerStatePaused:
            if ([self.delegate respondsToSelector:@selector(didPausePlayingMedia:)]) {
                [self.delegate didPausePlayingMedia:self];
            }
            break;
            
        case MediaPlayerStateCompleted:
            if (self.activeMediaPlayer == mediaPlayer) {
                self.activeMediaPlayer = nil;
            }

            [self stopObservingMediaPlayerChanges:mediaPlayer];

            if ([self.delegate respondsToSelector:@selector(didFinishPlayingMedia:)]) {
                [self.delegate didFinishPlayingMedia:self]; // this interfers with the audio session
            }
            break;
        case MediaPlayerStateError:
            if ([self.delegate respondsToSelector:@selector(didFinishPlayingMedia:)]) {
                [self.delegate didFinishPlayingMedia:self]; // this interfers with the audio session
            }
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MediaPlaybackManagerPlayerStateChangedNotification
                                                        object:mediaPlayer];
}

#pragma mark - Active Media Player State

- (void)startObservingMediaPlayerChanges
{
    self.titleObserver = [KeyValueObserver observeObject:self.activeMediaPlayer
                                                 keyPath:@"title"
                                                  target:self
                                                selector:@selector(activeMediaPlayerTitleChanged:)
                                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)stopObservingMediaPlayerChanges:(id<MediaPlayer>)mediaPlayer
{
    self.titleObserver = nil;
}

- (void)activeMediaPlayerTitleChanged:(NSDictionary *)change
{
    [self.changeObserver activeMediaPlayerTitleDidChange];
}

@end
