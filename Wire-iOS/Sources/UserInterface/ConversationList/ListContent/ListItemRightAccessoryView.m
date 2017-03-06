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


#import "ListItemRightAccessoryView.h"
#import <PureLayout/PureLayout.h>

@import WireExtensionComponents;
#import "UIImage+ZetaIconsNeue.h"
#import "WAZUIMagicIOS.h"
#import "AppDelegate.h"
#import "MediaPlaybackManager.h"

#import "avs+iOS.h"
#import "MediaPlayer.h"
#import <Classy/Classy.h>

#import "Wire-Swift.h"


@interface ListItemRightAccessoryView ()

@property (nonatomic, strong) IconButton *mediaButton;
@property (nonatomic, strong) IconButton *muteVoiceButton;
@property (nonatomic, strong) UIImageView *silencedIcon;
@property (nonatomic) Button *joinCallButton;

@end



@implementation ListItemRightAccessoryView

- (void)setAccessoryType:(ConversationListRightAccessoryType)accessoryType
{
    if (_accessoryType == accessoryType) {
        return;
    }
    
    _accessoryType = accessoryType;
    
    [self hideAll];
    
    switch (accessoryType) {
        case ConversationListRightAccessorySilencedIcon:
            [self showSilencedIcon];
            break;
            
        case ConversationListRightAccessoryMuteVoiceButton:
            [self showMuteButton];
            break;
            
        case ConversationListRightAccessoryMediaButton:
            [self showMediaButton];
            break;

        case ConversationListRightAccessoryJoinCall:
            [self showJoinCallButton];
            break;

        case ConversationListRightAccessoryNone:
            break;
    }
}

- (void)hideAll
{
    [self.muteVoiceButton setHidden:YES];
    [self.silencedIcon setHidden:YES];
    [self.mediaButton setHidden:YES];
    [self.joinCallButton setHidden:YES];
}

- (void)showMuteButton
{
    if (! self.muteVoiceButton) {
        self.muteVoiceButton = [IconButton iconButtonCircularLight];
        self.muteVoiceButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.muteVoiceButton setIcon:ZetaIconTypeMicrophoneWithStrikethrough withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self addSubview:self.muteVoiceButton];
        self.muteVoiceButton.accessibilityIdentifier = @"MuteVoiceButton";
        [self.muteVoiceButton addTarget:self action:@selector(muteVoiceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.muteVoiceButton autoSetDimensionsToSize:CGSizeMake(28.0f, 28.0f)];
        [self.muteVoiceButton autoCenterInSuperview];
    }
    [self.muteVoiceButton setHidden:NO];
    [self updateMuteButtonState];
}

- (void)showSilencedIcon
{
    if (! self.silencedIcon) {
        UIImage *image = [UIImage imageForIcon:ZetaIconTypeBellWithStrikethrough iconSize:ZetaIconSizeTiny color:[UIColor whiteColor]];
        self.silencedIcon = [[UIImageView alloc] initWithImage:image];
        self.silencedIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.silencedIcon];

        [self.silencedIcon autoSetDimensionsToSize:image.size];
        [self.silencedIcon autoCenterInSuperview];
        self.silencedIcon.accessibilityIdentifier = @"silenceConversationIcon";
    }
    
    [self.silencedIcon setHidden:NO];
}

- (void)showMediaButton
{
    if (! self.mediaButton) {
        self.mediaButton = [[IconButton alloc] initForAutoLayout];
        [self.mediaButton setIcon:[self iconForMediaPlayerState] withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self.mediaButton setIconColor:[UIColor colorWithMagicIdentifier:@"media_bar.list_font_color"] forState:UIControlStateNormal];
        
        [self addSubview:self.mediaButton];
        self.mediaButton.accessibilityLabel = @"mediaCellButton";
        
        [self.mediaButton addTarget:self action:@selector(mediaButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.mediaButton autoSetDimensionsToSize:CGSizeMake(28.0, 28.0)];
        [self.mediaButton autoCenterInSuperview];
    }
    
    [self updateMediaButtonState];
    [self.mediaButton setHidden:NO];
}

- (void)showJoinCallButton
{
    if (!self.joinCallButton) {
        self.joinCallButton = [Button buttonWithStyle:ButtonStyleFullMonochrome];
        self.joinCallButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.joinCallButton setTitle:NSLocalizedString(@"Join", nil) forState:UIControlStateNormal];
        self.joinCallButton.accessibilityLabel = @"joinCallButton";
        [self addSubview:self.joinCallButton];
        [self.joinCallButton addTarget:self action:@selector(joinCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.joinCallButton autoCenterInSuperview];
    }

    self.joinCallButton.hidden = NO;
    [self updateCallButtonCornerRadius];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (nil != self.joinCallButton) {
        [self updateCallButtonCornerRadius];
    }
}

- (void)updateButtonStates
{
    [self updateMediaButtonState];
    [self updateMuteButtonState];
}

- (void)muteVoiceButtonTapped:(id)sender
{
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    mediaManager.microphoneMuted = ! mediaManager.microphoneMuted;
    
    [self updateMuteButtonState];
}

- (void)mediaButtonTapped:(id)sender
{
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    
    if (mediaPlaybackManager.activeMediaPlayer.state == MediaPlayerStatePlaying) {
        [mediaPlaybackManager pause];
    } else {
        [mediaPlaybackManager play];
    }
    
    [self updateMediaButtonState];
}

- (void)joinCallButtonTapped:(Button *)sender
{
    [self.delegate accessoryViewWantsToJoinCall:self];
}

- (void)updateMuteButtonState
{
    if (nil != self.muteVoiceButton && !self.muteVoiceButton.hidden) {
        BOOL muted = [[AVSProvider shared] mediaManager].isMicrophoneMuted;
        self.muteVoiceButton.selected = muted;
    }
}

- (void)updateMediaButtonState
{
    if (self.accessoryType == ConversationListRightAccessoryMediaButton) {
        [self.mediaButton setIcon:[self iconForMediaPlayerState] withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    }
}

- (ZetaIconType)iconForMediaPlayerState
{
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    return mediaPlaybackManager.activeMediaPlayer.state == MediaPlayerStatePlaying ? ZetaIconTypePause : ZetaIconTypePlay;
}

- (void)updateCallButtonCornerRadius
{
    self.joinCallButton.layer.cornerRadius = CGRectGetMidY(self.joinCallButton.bounds);
}

@end
