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



#import "AudioTrackPlayer.h"
#import "AudioTrack.h"
#import "AudioPlaylist.h"
@import WireExtensionComponents;

static NSString* EmptyStringIfNil(NSString *string) {
    return string == nil ? @"" : string;
}



@import AVFoundation;
@import MediaPlayer;


@interface AudioTrackPlayer ()

@property (nonatomic) AVPlayer *avPlayer;
@property (nonatomic) NSObject<AudioTrack> *audioTrack;
@property (nonatomic) id<AudioPlaylist> audioPlaylist;
@property (nonatomic) CGFloat progress;
@property (nonatomic) id timeObserverToken;
@property (nonatomic, copy) void (^loadAudioTrackCompletionHandler)(BOOL loaded, NSError *error);
@property (nonatomic) MediaPlayerState state;
@property (nonatomic) id<ZMConversationMessage> sourceMessage;
@property (nonatomic) NSObject *artworkObserver;
@property (nonatomic) NSDictionary *nowPlayingInfo;

@end

@implementation AudioTrackPlayer

- (void)dealloc
{
    self.audioTrack = nil;
    
    [self.avPlayer removeObserver:self forKeyPath:@"status"];
    [self.avPlayer removeObserver:self forKeyPath:@"rate"];
    [self.avPlayer removeObserver:self forKeyPath:@"currentItem"];
    
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self configureRemoteCommandCenter];
    }
    
    return self;
}

- (void)loadTrack:(NSObject<AudioTrack> *)track sourceMessage:(id<ZMConversationMessage>)sourceMessage completionHandler:(void(^)(BOOL loaded, NSError *error))completionHandler
{
    [self loadTrack:track playlist:nil sourceMessage:sourceMessage completionHandler:completionHandler];
}

- (void)loadTrack:(NSObject<AudioTrack> *)track playlist:(id<AudioPlaylist>)playlist sourceMessage:(id<ZMConversationMessage>)sourceMessage completionHandler:(void(^)(BOOL loaded, NSError *error))completionHandler
{
    _progress = 0;
    self.artworkObserver = nil;
    self.audioTrack = track;
    self.audioPlaylist = playlist;
    self.sourceMessage = sourceMessage;
    self.loadAudioTrackCompletionHandler = completionHandler;
    
    if (self.audioTrack.artwork == nil) {
        [self.audioTrack fetchArtwork];
    }
    
    if (self.avPlayer == nil) {
        self.avPlayer = [AVPlayer playerWithURL:track.streamURL];
        [self.avPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
        [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:NULL];
        [self.avPlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld context:NULL];
    } else {

        [self.avPlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:track.streamURL]];

        if (self.avPlayer.status == AVPlayerStatusReadyToPlay) {
            self.loadAudioTrackCompletionHandler(YES, nil);
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    if (self.timeObserverToken != nil) {
        [self.avPlayer removeTimeObserver:self.timeObserverToken];
    }
    
    __weak typeof(self) weakSelf = self;
    self.timeObserverToken = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CMTimeRange itemRange = CMTimeRangeMake(CMTimeMake(0, 1), weakSelf.avPlayer.currentItem.asset.duration);
        CMTimeRange normalizedRange = CMTimeRangeMake(CMTimeMake(0, 1), CMTimeMake(1, 1));
        CMTime normalizedTime = CMTimeMapTimeFromRangeToRange(time, itemRange, normalizedRange);
        weakSelf.progress = CMTimeGetSeconds(normalizedTime);
    }];
}

- (void)configureRemoteCommandCenter
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    ZM_WEAK(self);
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        ZM_STRONG(self);
        if (self.avPlayer.rate > 0) {
            [self pause];
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
    
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        ZM_STRONG(self);
        if (self.audioTrack == nil) {
            return MPRemoteCommandHandlerStatusNoSuchContent;
        }
        
        if (self.avPlayer.rate == 0) {
            [self play];
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        ZM_STRONG(self);
        if ([self skipToNextTrack]) {
           return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusNoSuchContent;
        }
    }];
    
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        ZM_STRONG(self);
        if ([self skipToPreviousTrack]) {
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusNoSuchContent;
        }
    }];
}

- (NSTimeInterval)elapsedTime {
    CMTime time = self.avPlayer.currentTime;
    if (CMTIME_IS_VALID(time)) {
        return time.value / time.timescale;
    }
    return 0;
}

- (CGFloat)duration
{
    return CMTimeGetSeconds(self.avPlayer.currentItem.asset.duration);
}

- (BOOL)isPlaying
{
    return self.avPlayer.rate > 0 && self.avPlayer.error == nil;
}

- (void)play
{
    if (self.state == MediaPlayerStateCompleted) {
        [self.avPlayer seekToTime:CMTimeMake(0, 1)];
    }
    
    [self.avPlayer play];
}

- (void)pause
{
    [self.avPlayer pause];
}

- (void)stop
{
    [self.avPlayer pause];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    self.artworkObserver = nil;
    self.audioTrack = nil;
    _sourceMessage = nil;
}

- (BOOL)skipToNextTrack
{
    id<AudioTrack> nextAudioTrack = nil;
    
    if (self.audioPlaylist != nil && self.audioTrack != nil) {
        NSUInteger indexOfCurrentTrack = [self.audioPlaylist.tracks indexOfObject:self.audioTrack];
        if (self.audioPlaylist.tracks.count > indexOfCurrentTrack + 1) {
            
            for (NSUInteger candidateIndex = indexOfCurrentTrack + 1; candidateIndex < self.audioPlaylist.tracks.count; candidateIndex++) {                
                id<AudioTrack> candidate = [self.audioPlaylist.tracks objectAtIndex:candidateIndex];
                if (! nextAudioTrack.failedToLoad) {
                    nextAudioTrack = candidate;
                    break;
                }
            }
            
        }
    }
    
    if (nextAudioTrack == nil) {
        return NO;
    }
    
    @weakify(self);
    [self loadTrack:nextAudioTrack playlist:self.audioPlaylist sourceMessage:self.sourceMessage completionHandler:^(BOOL loaded, NSError *error) {
        @strongify(self);
        if (loaded) {
            [self play];
        }
    }];
    
    return YES;
}

- (BOOL)skipToPreviousTrack
{
    id<AudioTrack> previousAudioTrack = nil;
    
    if (self.audioPlaylist != nil && self.audioTrack != nil) {
        NSUInteger indexOfCurrentTrack = [self.audioPlaylist.tracks indexOfObject:self.audioTrack];
        if ( (NSInteger)indexOfCurrentTrack - 1 >= 0) {
            previousAudioTrack = [self.audioPlaylist.tracks objectAtIndex:indexOfCurrentTrack - 1];
        }
    }
    
    if (previousAudioTrack == nil) {
        return NO;
    }
    
    @weakify(self);
    [self loadTrack:previousAudioTrack playlist:self.audioPlaylist sourceMessage:self.sourceMessage completionHandler:^(BOOL loaded, NSError *error) {
        @strongify(self);
        if (loaded) {
            [self play];
        }
    }];
    
    return YES;
}

- (NSString *)title
{
    return self.audioTrack.title;
}

+ (NSSet *)keyPathsForValuesAffectingPlaying
{
    return [NSSet setWithObjects:@"avPlayer.rate", nil];
}

+ (NSSet *)keyPathsForValuesAffectingError
{
    return [NSSet setWithObjects:@"avPlayer.error", nil];
}

- (NSError *)error
{
    return self.avPlayer.error;
}

- (void)setAudioTrack:(NSObject<AudioTrack> *)audioTrack
{
    if (_audioTrack == audioTrack) {
        return;
    }
    
    if (_audioTrack != nil) {
        [_audioTrack removeObserver:self forKeyPath:@"status"];
    }
    _audioTrack = audioTrack;
    if (_audioTrack != nil) {
        [_audioTrack addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

#pragma mark - KVO observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.avPlayer.currentItem && [keyPath isEqualToString:@"status"]) {
        if (self.avPlayer.currentItem.status == AVPlayerItemStatusFailed) {
            self.state = MediaPlayerStateError;
            self.audioTrack.failedToLoad = YES;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
            
            if (IsNetworkReachable()) {
                [self skipToNextTrack];
            }
        }
    }
    
    if (object == self.avPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.avPlayer.status == AVPlayerStatusReadyToPlay) {
            self.loadAudioTrackCompletionHandler(YES, nil);
        }
        else if (self.avPlayer.status == AVPlayerStatusFailed) {
            self.loadAudioTrackCompletionHandler(NO, self.avPlayer.error);
        }
    }
    
    if (object == self.avPlayer && [keyPath isEqualToString:@"rate"]) {
        
        if (self.avPlayer.rate > 0) {
            self.state = MediaPlayerStatePlaying;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
        } else if (self.state != MediaPlayerStateCompleted) {
            self.state = MediaPlayerStatePaused;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
        }
        
        [self updateNowPlayingState];
    }
    
    if (object == self.avPlayer && [keyPath isEqualToString:@"currentItem"]) {
     
        if (self.avPlayer.currentItem == nil) {
            [self clearNowPlayingState];
            self.state = MediaPlayerStateCompleted;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
        } else {
            [self populateNowPlayingState];
        }
    }
    
}

- (void)artworkChanged:(NSDictionary *)changed
{
    [self updateNowPlayingArtwork];
}

#pragma mark - MPNowPlayingInfoCenter

- (void)populateNowPlayingState
{
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    
    NSMutableDictionary *nowPlayingInfo =
    [NSMutableDictionary dictionaryWithDictionary:@{ MPMediaItemPropertyTitle : EmptyStringIfNil(self.audioTrack.title),
                                                     MPMediaItemPropertyArtist : EmptyStringIfNil(self.audioTrack.author),
                                                     MPNowPlayingInfoPropertyPlaybackRate : @(self.avPlayer.rate),
                                                     MPMediaItemPropertyPlaybackDuration : @(CMTimeGetSeconds(self.avPlayer.currentItem.asset.duration)) }];
    
    info.nowPlayingInfo = nowPlayingInfo;
    self.nowPlayingInfo = nowPlayingInfo;
    
    self.artworkObserver = [KeyValueObserver observeObject:self.audioTrack keyPath:@"artwork" target:self selector:@selector(artworkChanged:) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)clearNowPlayingState
{
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    info.nowPlayingInfo = nil;
    self.nowPlayingInfo = nil;
}

- (void)updateNowPlayingState
{
    NSMutableDictionary *newInfo = [self.nowPlayingInfo mutableCopy];
    [newInfo setObject:@(self.elapsedTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [newInfo setObject:@(self.avPlayer.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
 
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    info.nowPlayingInfo = newInfo;
    self.nowPlayingInfo = newInfo;
}
        
- (void)updateNowPlayingArtwork
{
    if (self.audioTrack.artwork == nil) {
        return;
    }
    
    NSMutableDictionary *newInfo = [self.nowPlayingInfo mutableCopy];
    [newInfo setObject:[[MPMediaItemArtwork alloc] initWithImage:self.audioTrack.artwork] forKey:MPMediaItemPropertyArtwork];
    
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    info.nowPlayingInfo = newInfo;
    self.nowPlayingInfo = newInfo;
}

#pragma mark AVPlayer notifications

- (void)itemDidPlayToEndTime:(NSNotification *)notification
{
    // AUDIO-557 workaround for AVSMediaManager trying to pause already paused tracks.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (! [self skipToNextTrack]) {
            [self clearNowPlayingState];
            self.state = MediaPlayerStateCompleted;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
        }
    });
}

@end
