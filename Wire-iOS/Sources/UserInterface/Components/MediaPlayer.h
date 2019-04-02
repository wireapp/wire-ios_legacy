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


#import <Foundation/Foundation.h>



/// These enums represent the state of the current media in the player.
typedef NS_ENUM(NSInteger, MediaPlayerState)
{
    MediaPlayerStateReady = 0,
    MediaPlayerStatePlaying,
    MediaPlayerStatePaused,
    MediaPlayerStateCompleted,
    MediaPlayerStateError
};

@protocol ZMConversationMessage;

@protocol MediaPlayer;


@protocol MediaPlayerDelegate <NSObject>

- (void)mediaPlayer:(_Nonnull id<MediaPlayer>)mediaPlayer didChangeToState:(MediaPlayerState)state;

@end


@protocol MediaPlayer <NSObject>

@property (nonatomic, readonly, nullable) NSString *title;
@property (nonatomic, readonly, nullable) id<ZMConversationMessage>sourceMessage;
@property (nonatomic, readonly) MediaPlayerState state;

- (void)play;
- (void)pause;
- (void)stop;

@end
