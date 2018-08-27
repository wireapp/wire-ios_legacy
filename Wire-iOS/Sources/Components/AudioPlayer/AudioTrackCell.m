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


@import PureLayout;
@import WireExtensionComponents;

#import "AudioTrackCell.h"
#import "AudioTrackView.h"
#import "IconButton.h"
#import "AudioTrack.h"


@implementation AudioTrackCell

- (void)prepareForReuse
{
    [self.audioTrackView.playPauseButton setIcon:ZetaIconTypePlay withSize:ZetaIconSizeLarge forState:UIControlStateNormal];
    self.audioTrackView.progress = 0;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _audioTrackView = [[AudioTrackView alloc] initForAutoLayout];
        [self.contentView addSubview:self.audioTrackView];
        [self.audioTrackView.playPauseButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
        [self.audioTrackView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    
    return self;
}

- (void)setAudioTrack:(id<AudioTrack>)audioTrack
{
    _audioTrack = audioTrack;
    
    self.artworkObserver = [KeyValueObserver observeObject:self.audioTrack keyPath:@"artwork" target:self selector:@selector(artworkChanged:) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
    
    if (self.audioTrack.artwork == nil) {
        [self.audioTrack fetchArtwork];
    } else {
        [self updateArtwork];
    }
    
    self.audioTrackView.failedToLoad = self.audioTrack.failedToLoad || self.audioTrack == nil;
}

- (void)updateArtwork
{
    self.audioTrackView.artworkImageView.image = self.audioTrack.artwork;
}

- (void)artworkChanged:(NSDictionary *)change
{
    [self updateArtwork];
}

- (IBAction)playPause:(id)sender
{
    [self.delegate audioTrackCell:self didPlayPauseTrack:self.audioTrack];
}

@end
