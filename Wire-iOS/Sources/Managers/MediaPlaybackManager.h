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


@import Foundation;
#import "avs+iOS.h"
#import "MediaPlayer.h"



@class AudioTrackPlayer;
@class MediaPlaybackManager;

FOUNDATION_EXPORT NSString *const MediaPlaybackManagerPlayerStateChangedNotification;

/// An object that observes changes in the media playback manager.
@protocol MediaPlaybackManagerChangeObserver

/// A media player did become active.
- (void)mediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager didStartMediaPlayer:(id<MediaPlayer>)mediaPlayer;

/// The media player did become inactive.
- (void)mediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager didRemoveMediaPlayer:(id<MediaPlayer>)mediaPlayer;

@end

/// This object is an interface for AVS to control conversation media playback;
@interface MediaPlaybackManager : NSObject <AVSMedia, MediaPlayerDelegate>

@property (nonatomic, readonly) AudioTrackPlayer *audioTrackPlayer;
@property (nonatomic, weak, readonly) id<MediaPlayer> activeMediaPlayer;
@property (nonatomic, weak) id<MediaPlaybackManagerChangeObserver> changeObserver;

- (instancetype)initWithName:(NSString *)name;

@end
