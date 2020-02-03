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
#import "AudioTrackPlayer+Private.h"

#import "UIImage+ImageUtilities.h"

@import WireCommonComponents;
@import WireUtilities;
@import WireSyncEngine;
#import "Wire-Swift.h"

@import AVFoundation;
@import MediaPlayer;

@implementation AudioTrackPlayer

- (void)dealloc
{
    self.audioTrack = nil;
    
    [self.avPlayer removeObserver:self forKeyPath:@"status"];
    [self.avPlayer removeObserver:self forKeyPath:@"rate"];
    [self.avPlayer removeObserver:self forKeyPath:@"currentItem"];
    
    [self setIsRemoteCommandCenterEnabled:NO];
}

- (void)loadTrack:(NSObject<AudioTrack> *)track sourceMessage:(id<ZMConversationMessage>)sourceMessage completionHandler:(void(^)(BOOL loaded, NSError *error))completionHandler
{
    _progress = 0;
    self.audioTrack = track;
    self.sourceMessage = sourceMessage;
    self.loadAudioTrackCompletionHandler = completionHandler;
    
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
    
    ZMUserSession *userSession = [ZMUserSession sharedSession];
    if (userSession != nil) {
        self.messageObserverToken = [MessageChangeInfo addObserver:self forMessage:sourceMessage userSession:[ZMUserSession sharedSession]];
    }
}

- (void)setIsRemoteCommandCenterEnabled:(BOOL)enabled
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    if (!enabled) {
        [commandCenter.playCommand removeTarget:self.playHandler];
        [commandCenter.pauseCommand removeTarget:self.pauseHandler];
        [commandCenter.nextTrackCommand removeTarget:self.nextTrackHandler];
        [commandCenter.previousTrackCommand removeTarget:self.previousTrackHandler];
        return;
    }
    
    ZM_WEAK(self);
    self.pauseHandler = [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        ZM_STRONG(self);
        if (self.avPlayer.rate > 0) {
            [self pause];
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];

    self.playHandler = [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
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
    self.audioTrack = nil;
    self.messageObserverToken = nil;
    _sourceMessage = nil;
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

#pragma mark - ZMMessageObserver

- (void)messageDidChange:(MessageChangeInfo *)changeInfo
{
    if (changeInfo.message.hasBeenDeleted) {
        [self stop];
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
            [self setIsRemoteCommandCenterEnabled:NO];
            [self clearNowPlayingState];
            self.state = MediaPlayerStateCompleted;
            [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
        } else {
            [self setIsRemoteCommandCenterEnabled:YES];
            [self populateNowPlayingState];
        }
    }
    
}

#pragma mark - MPNowPlayingInfoCenter

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
        
#pragma mark AVPlayer notifications

- (void)itemDidPlayToEndTime:(NSNotification *)notification
{
    // AUDIO-557 workaround for AVSMediaManager trying to pause already paused tracks.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self clearNowPlayingState];
        self.state = MediaPlayerStateCompleted;
        [self.mediaPlayerDelegate mediaPlayer:self didChangeToState:self.state];
    });
}

@end
