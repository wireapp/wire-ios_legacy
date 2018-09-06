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



#import "MediaBarViewController.h"
#import "MediaBar.h"
#import "MediaPlaybackManager.h"
#import "Wire-Swift.h"
@import WireExtensionComponents;
@import WireSyncEngine;

#import "Constants.h"



@interface MediaBarViewController () <MediaPlaybackManagerChangeObserver>

@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic, readonly) MediaBar *mediaBarView;

@end

@implementation MediaBarViewController

- (instancetype)initWithMediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _mediaPlaybackManager = mediaPlaybackManager;
        _mediaPlaybackManager.changeObserver = self;
    }
    
    return self;
}

- (void)loadView
{
    self.view = [[MediaBar alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mediaBarView.playPauseButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.mediaBarView.closeButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    
    [self updatePlayPauseButton];
}

- (MediaBar *)mediaBarView
{
    return (MediaBar *)self.view;
}

- (void)updateTitleLabel
{
    self.mediaBarView.titleLabel.text = [self.mediaPlaybackManager.activeMediaPlayer.title uppercasedWithCurrentLocale];
}

- (void)updatePlayPauseButton
{
    ZetaIconType playPauseIcon = ZetaIconTypeMediaBarPlay;
    NSString *accessibilityIdentifier = @"mediaBarPlayButton";
    
    if (self.mediaPlaybackManager.activeMediaPlayer.state == MediaPlayerStatePlaying) {
        playPauseIcon = ZetaIconTypeMediaBarPause;
        accessibilityIdentifier = @"mediaBarPauseButton";
    }
    
    [self.mediaBarView.playPauseButton setIcon:playPauseIcon withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.mediaBarView.playPauseButton.accessibilityIdentifier = accessibilityIdentifier;
}

#pragma mark - Actions

- (IBAction)playPause:(id)sender
{
    if (self.mediaPlaybackManager.activeMediaPlayer.state == MediaPlayerStatePlaying) {
        [self.mediaPlaybackManager pause];
    } else {
        [self.mediaPlaybackManager play];
    }
}

- (IBAction)stop:(id)sender
{
    [self.mediaPlaybackManager stop];
}

#pragma mark - MediaPlaybackManagerChangeObserver

- (void)activeMediaPlayerTitleDidChange
{
    if (self.mediaPlaybackManager.activeMediaPlayer) {
        self.mediaBarView.titleLabel.text = [self.mediaPlaybackManager.activeMediaPlayer.title uppercasedWithCurrentLocale];
    }
}

- (void)activeMediaPlayerStateDidChange
{
    [self updatePlayPauseButton];
}

@end
