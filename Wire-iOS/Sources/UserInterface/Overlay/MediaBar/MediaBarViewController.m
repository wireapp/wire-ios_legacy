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


#import <Classy/Classy.h>

#import "MediaBarViewController.h"
#import "MediaBar.h"
#import "MediaPlaybackManager.h"
#import "Wire-Swift.h"
@import WireExtensionComponents;

#import "Constants.h"



@interface MediaBarViewController ()

@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic, readonly) MediaBar *mediaBarView;

@property (nonatomic) NSObject *mediaPlaybackStateObserver;
@property (nonatomic) NSObject *mediaTitleObserver;

@end

@implementation MediaBarViewController

- (void)dealloc
{
    // Observer must be deallocated before `mediaPlaybackManager`
    self.mediaTitleObserver = nil;
    self.mediaPlaybackStateObserver = nil;
    self.mediaPlaybackManager = nil;
}

- (instancetype)initWithMediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _mediaPlaybackManager = mediaPlaybackManager;
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
    
    self.mediaPlaybackStateObserver = [KeyValueObserver observeObject:self.mediaPlaybackManager
                                                              keyPath:@"activeMediaPlayer.state"
                                                               target:self
                                                             selector:@selector(mediaPlaybackStateChanged:)
                                                              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
    
    self.mediaTitleObserver = [KeyValueObserver observeObject:self.mediaPlaybackManager
                                                      keyPath:@"activeMediaPlayer.title"
                                                       target:self
                                                     selector:@selector(mediaTitleChanged:)
                                                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - MediaPlaybackStateObserver

- (void)mediaPlaybackStateChanged:(NSDictionary *)change
{
    [self updatePlayPauseButton];
}

- (void)mediaTitleChanged:(NSDictionary *)change
{
    if (self.mediaPlaybackManager.activeMediaPlayer) {
        self.mediaBarView.titleLabel.text = [self.mediaPlaybackManager.activeMediaPlayer.title uppercasedWithCurrentLocale];
    }
}

@end
