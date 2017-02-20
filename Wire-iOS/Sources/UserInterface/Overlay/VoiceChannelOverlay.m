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


@import QuartzCore;
#import <PureLayout/PureLayout.h>
@import Classy;
@import WireExtensionComponents;
#import <avs/AVSVideoView.h>
#import <avs/AVSVideoPreview.h>

#import "VoiceChannelOverlay.h"
#import "VoiceChannelOverlayController.h"
#import "VoiceChannelCollectionViewLayout.h"
#import "UserImageView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "NSAttributedString+Wire.h"
#import "Constants.h"
#import "Analytics+iOS.h"
#import "UIColor+Mixing.h"
#import "WireStyleKit.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "RBBAnimation.h"
#import "CameraPreviewView.h"
#import "Wire-Swift.h"
#import "Settings.h"

NSString *const VoiceChannelOverlayVideoFeedPositionKey = @"VideoFeedPosition";

static const CGFloat CameraPreviewContainerSize = 72.0f;
static const CGFloat GroupCallAvatarSize = 120.0f;
static const CGFloat GroupCallAvatarLabelHeight = 30.0f;


NSString *StringFromVoiceChannelOverlayState(VoiceChannelOverlayState state)
{
    if (VoiceChannelOverlayStateInvalid == state) {
        return @"OverlayInvalid";
    }
    if (VoiceChannelOverlayStateIncomingCall == state) {
        return @"OverlayIncomingCall";
    }
    else if (VoiceChannelOverlayStateIncomingCallInactive == state) {
        return @"OverlayIncomingCallInactive";
    }
    else if (VoiceChannelOverlayStateJoiningCall == state) {
        return @"OverlayJoiningCall";
    }
    else if (VoiceChannelOverlayStateOutgoingCall == state) {
        return @"OverlayOutgoingCall";
    }
    else if (VoiceChannelOverlayStateConnected == state) {
        return @"OverlayConnected";
    }
    return @"unknown";
}

static NSString *NotNilString(NSString *string) {
    if (! string) {
        return @"";
    }
    return string;
}


@interface VoiceChannelOverlay () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) AVSVideoView *videoView;
@property (nonatomic) CameraPreviewView *cameraPreviewView;

@property (nonatomic) UICollectionView *participantsCollectionView;
@property (nonatomic) VoiceChannelCollectionViewLayout *participantsCollectionViewLayout;


@property (nonatomic) BOOL videoViewFullScreen;
@end



@implementation VoiceChannelOverlay

- (void)dealloc
{
    [self cancelHideControlsAfterElapsedTime];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupVoiceOverlay];
        [self createConstraints];
    }
    
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL pointInside = [super pointInside:point withEvent:event];
    if (pointInside && self.incomingVideoActive) {
        if (! self.controlsHidden) {
            [self hideControlsAfterElapsedTime];
        }
    }
    return pointInside;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self backgroundWasTapped];
}

- (void)setupVoiceOverlay
{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    self.callDurationFormatter = [[NSDateComponentsFormatter alloc] init];
    self.callDurationFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorNone;
    self.callDurationFormatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    if (![[Settings sharedSettings] disableAVS]) {
        self.videoView = [[AVSVideoView alloc] initForAutoLayout];
        self.videoView.shouldFill = YES;
        self.videoView.userInteractionEnabled = NO;
        self.videoView.backgroundColor = [UIColor colorWithPatternImage:[UIImage dot:9]];
        [self addSubview:self.videoView];
    }

    _videoViewFullScreen = YES;
    
    self.shadow = [[UIView alloc] initForAutoLayout];
    self.shadow.userInteractionEnabled = NO;
    self.shadow.backgroundColor = [UIColor colorWithWhite:0 alpha:0.40];
    [self addSubview:self.shadow];
    
    self.videoNotAvailableBackground = [[UIView alloc] initForAutoLayout];
    self.videoNotAvailableBackground.userInteractionEnabled = NO;
    self.videoNotAvailableBackground.backgroundColor = [UIColor blackColor];
    [self addSubview:self.videoNotAvailableBackground];
    
    self.contentContainer = [[UIView alloc] initForAutoLayout];
    self.contentContainer.layoutMargins = UIEdgeInsetsMake(48, 32, 40, 32);
    [self addSubview:self.contentContainer];
    
    self.avatarContainer = [[UIView alloc] initForAutoLayout];
    [self.contentContainer addSubview:self.avatarContainer];
    
    self.callingUserImage = [[UserImageView alloc] initForAutoLayout];
    self.callingUserImage.suggestedImageSize = UserImageViewSizeBig;
    self.callingUserImage.accessibilityIdentifier = @"CallingUsersImage";
    [self.avatarContainer addSubview:self.callingUserImage];
    
    self.callingTopUserImage = [[UserImageView alloc] initForAutoLayout];
    self.callingTopUserImage.suggestedImageSize = UserImageViewSizeSmall;
    self.callingTopUserImage.accessibilityIdentifier = @"CallingTopUsersImage";
    [self.contentContainer addSubview:self.callingTopUserImage];
    
    self.participantsCollectionViewLayout = [[VoiceChannelCollectionViewLayout alloc] init];
    self.participantsCollectionViewLayout.itemSize = CGSizeMake(GroupCallAvatarSize, GroupCallAvatarSize + GroupCallAvatarLabelHeight);
    self.participantsCollectionViewLayout.minimumInteritemSpacing = 24;
    self.participantsCollectionViewLayout.minimumLineSpacing = 24;
    self.participantsCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.participantsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.participantsCollectionViewLayout];
    self.participantsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.participantsCollectionView.alwaysBounceHorizontal = YES;
    self.participantsCollectionView.backgroundColor = [UIColor clearColor];
    self.participantsCollectionView.delegate = self;
    [self addSubview:self.participantsCollectionView];
    
    self.acceptButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.acceptButton.iconButton setIcon:ZetaIconTypePhone withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.acceptButton.subtitleLabel.text = NSLocalizedString(@"voice.accept_button.title", @"");
    self.acceptButton.accessibilityIdentifier = @"AcceptButton";
    [self.contentContainer addSubview:self.acceptButton];

    self.acceptVideoButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.acceptVideoButton.iconButton setIcon:ZetaIconTypeVideoCall withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.acceptVideoButton.subtitleLabel.text = NSLocalizedString(@"voice.accept_button.title", @"");
    self.acceptVideoButton.accessibilityIdentifier = @"AcceptVideoButton";
    [self.contentContainer addSubview:self.acceptVideoButton];
    
    self.ignoreButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.ignoreButton.iconButton setIcon:ZetaIconTypeEndCall withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.ignoreButton.subtitleLabel.text = NSLocalizedString(@"voice.decline_button.title", @"");
    self.ignoreButton.accessibilityIdentifier = @"IgnoreButton";
    [self.contentContainer addSubview:self.ignoreButton];
    
    self.leaveButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.leaveButton.iconButton setIcon:ZetaIconTypeEndCall withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.leaveButton.subtitleLabel.text = NSLocalizedString(@"voice.hang_up_button.title", @"");
    self.leaveButton.accessibilityIdentifier = @"LeaveCallButton";
    [self.contentContainer addSubview:self.leaveButton];
    
    self.muteButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.muteButton.iconButton setIcon:ZetaIconTypeMicrophoneWithStrikethrough withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.muteButton.subtitleLabel.text = NSLocalizedString(@"voice.mute_button.title", @"");
    self.muteButton.accessibilityIdentifier = @"CallMuteButton";
    [self.contentContainer addSubview:self.muteButton];
    
    self.videoButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.videoButton.iconButton setIcon:ZetaIconTypeVideoCall withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.videoButton.subtitleLabel.text = NSLocalizedString(@"voice.video_button.title", @"");
    self.videoButton.accessibilityIdentifier = @"CallVideoButton";
    [self.contentContainer addSubview:self.videoButton];
    
    self.speakerButton = [[IconLabelButton alloc] initForAutoLayout];
    [self.speakerButton.iconButton setIcon:ZetaIconTypeSpeaker withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    self.speakerButton.subtitleLabel.text = NSLocalizedString(@"voice.speaker_button.title", @"");
    self.speakerButton.accessibilityIdentifier = @"CallSpeakerButton";
    [self.contentContainer addSubview:self.speakerButton];
    
    self.topStatusLabel = [[UILabel alloc] initForAutoLayout];
    self.topStatusLabel.accessibilityIdentifier = @"CallStatusLabel";
    self.topStatusLabel.textAlignment = NSTextAlignmentCenter;
    [self.topStatusLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.topStatusLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.topStatusLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.topStatusLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    self.topStatusLabel.numberOfLines = 0;
    [self.contentContainer addSubview:self.topStatusLabel];
    
    self.centerStatusLabel = [[UILabel alloc] initForAutoLayout];
    self.centerStatusLabel.accessibilityIdentifier = @"CenterStatusLabel";
    self.centerStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.centerStatusLabel.numberOfLines = 2;
    self.centerStatusLabel.text = [NSLocalizedString(@"voice.status.video_not_available", nil) uppercasedWithCurrentLocale];
    [self.contentContainer addSubview:self.centerStatusLabel];
    
    self.cameraPreviewView = [[CameraPreviewView alloc] initWithWidth:CameraPreviewContainerSize];
    [self addSubview:self.cameraPreviewView];
    
    [self setupCameraFeedPanGestureRecognizer];

}

- (void)setupCameraFeedPanGestureRecognizer
{
    UIPanGestureRecognizer *videoFeedPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onCameraPreviewPan:)];
    [self.cameraPreviewView addGestureRecognizer:videoFeedPan];
}

- (void)setVideoViewFullScreen:(BOOL)videoViewFullScreen
{
    [self createVideoPreviewIfNeeded];

    if (_videoViewFullScreen == videoViewFullScreen) {
        return;
    }
    DDLogVoice(@"videoViewFullScreen: %d -> %d", _videoViewFullScreen, videoViewFullScreen);
    _videoViewFullScreen = videoViewFullScreen;
    if (_videoViewFullScreen) {
        self.videoPreview.frame = self.bounds;
        [self insertSubview:self.videoPreview aboveSubview:self.videoView];
    }
    else {
        self.videoPreview.frame = self.cameraPreviewView.videoFeedContainer.bounds;
        [self.cameraPreviewView.videoFeedContainer addSubview:self.videoPreview];
    }
}

- (void)createVideoPreviewIfNeeded
{
    if (![[Settings sharedSettings] disableAVS] && nil == self.videoPreview) {
        // Preview view is moving from one subview to another. We cannot use constraints because renderer break if the view
        // is removed from hierarchy and immediately being added to the new superview (we need that to reapply constraints)
        // therefore we use @c autoresizingMask here
        self.videoPreview = [[AVSVideoPreview alloc] initWithFrame:self.bounds];
        self.videoPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.videoPreview.userInteractionEnabled = NO;
        self.videoPreview.backgroundColor = [UIColor clearColor];
        [self insertSubview:self.videoPreview aboveSubview:self.videoView];
    }
}

- (void)setLowBandwidth:(BOOL)lowBandwidth
{
    DDLogVoice(@"Low bandwidth: %d -> %d", _lowBandwidth, lowBandwidth);
    _lowBandwidth = lowBandwidth;
    self.centerStatusLabel.text = [NSLocalizedString(_lowBandwidth ? @"voice.status.low_connection" : @"voice.status.video_not_available", nil) uppercasedWithCurrentLocale];
}

- (void)setHidesSpeakerButton:(BOOL)hidesSpeakerButton
{
    _hidesSpeakerButton = hidesSpeakerButton;
    [self updateVisibleViewsForCurrentState];
}

- (void)transitionToState:(VoiceChannelOverlayState)state
{
    if (_state == state) {
        return;
    }
    
    _state = state;
    
    [self updateVisibleViewsForCurrentState];
}

- (void)updateVisibleViewsForCurrentStateAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.20 animations:^{
            [self updateVisibleViewsForCurrentState];
        }];
    }
    else {
        [self updateVisibleViewsForCurrentState];
    }
}

- (void)updateVisibleViewsForCurrentState
{
    [self updateStatusLabelText];
    [self updateCallingUserImage];
    
    [self showAppearingViewsForState:self.state];
    [self hideDisappearingViewsForState:self.state];
    
    BOOL connected = self.state == VoiceChannelOverlayStateConnected;
    
    self.muteButton.enabled = connected;
    self.videoButton.enabled = connected;
    self.videoButton.selected = self.videoButton.enabled && self.outgoingVideoActive;

    if (self.callingConversation.voiceChannel.isVideoCall) {
        self.videoViewFullScreen = ! connected;
    } else {
        self.videoView.hidden = YES;
        self.videoPreview.hidden = YES;
    }
    
    self.cameraPreviewView.mutedPreviewOverlay.hidden = !self.outgoingVideoActive || !self.muted;
}

- (void)updateStatusLabelText
{
    NSAttributedString *statusText = [self attributedStatus];
    if (statusText != nil) {
        self.topStatusLabel.attributedText = statusText;
    }
}

- (void)hideDisappearingViewsForState:(VoiceChannelOverlayState)state
{
    NSSet *hiddenViews = [self hiddenViewsForState:state];
    
    for (UIView *hiddenView in hiddenViews) {
        hiddenView.alpha = 0;
    }
    
    DDLogVoice(@"hidden views: %@", hiddenViews);
}

- (void)showAppearingViewsForState:(VoiceChannelOverlayState)state
{
    NSSet *visibleViews = [self visibleViewsForState:state];
    
    for (UIView *visibleView in visibleViews) {
        visibleView.alpha = 1;
    }
    
    DDLogVoice(@"visible views: %@", visibleViews);
}

- (void)updateCallingUserImage
{
    ZMUser *callingUser = nil;
    
    if (self.callingConversation.conversationType == ZMConversationTypeOneOnOne) {
        callingUser = self.callingConversation.firstActiveParticipantOtherThanSelf;
    }
    else if (self.state == VoiceChannelOverlayStateOutgoingCall) {
        callingUser = [ZMUser selfUser];
    }
    else {
        callingUser = self.callingConversation.firstActiveCallingParticipantOtherThanSelf;
    }
    
    self.callingUserImage.user = callingUser;
    self.callingTopUserImage.user = callingUser;
}

- (NSSet *)allOverlayViews
{
    return [NSSet setWithArray:@[self.callingUserImage, self.callingTopUserImage, self.topStatusLabel, self.centerStatusLabel, self.acceptButton, self.acceptVideoButton, self.ignoreButton, self.speakerButton, self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView, self.shadow, self.videoNotAvailableBackground, self.participantsCollectionView]];
}

- (NSSet *)visibleViewsForStateInVideoCall:(VoiceChannelOverlayState)state
{
    DDLogVoice(@"visibleViewsForStateInVideoCall: state = %ld, outgoingVideoActive = %d, incomingVideoActive = %d, remoteIsSendingVideo = %d, controlsHidden = %d, hidesSpeakerButton = %d", (long)state, self.outgoingVideoActive, self.incomingVideoActive, self.remoteIsSendingVideo, self.controlsHidden, self.hidesSpeakerButton);
    NSArray *visibleViews;
    switch (state) {
            
        case VoiceChannelOverlayStateInvalid:
            visibleViews = @[];
            break;
            
        case VoiceChannelOverlayStateOutgoingCall:
            visibleViews = @[self.shadow, self.callingTopUserImage, self.topStatusLabel, self.muteButton, self.leaveButton, self.videoButton];
            break;
            
        case VoiceChannelOverlayStateIncomingCall:
            visibleViews = @[self.shadow, self.callingTopUserImage, self.topStatusLabel, self.acceptVideoButton, self.ignoreButton];
            break;
            
        case VoiceChannelOverlayStateIncomingCallInactive:
            visibleViews = @[];
            break;
            
        case VoiceChannelOverlayStateJoiningCall:
            visibleViews = @[self.callingTopUserImage, self.topStatusLabel, self.muteButton, self.leaveButton, self.videoButton];
            break;
            
        case VoiceChannelOverlayStateConnected:
            visibleViews = @[self.muteButton, self.leaveButton, self.videoButton, self.cameraPreviewView];
            break;
    }

    NSMutableArray *mutableVisibleViews = [visibleViews mutableCopy];

    if (self.hidesSpeakerButton || self.outgoingVideoActive) {
        [mutableVisibleViews removeObject:self.speakerButton];
    }
    
    if (state == VoiceChannelOverlayStateConnected) {
        if (! self.remoteIsSendingVideo) {
            [mutableVisibleViews addObjectsFromArray:@[self.centerStatusLabel, self.videoNotAvailableBackground]];
        }
        else if (self.incomingVideoActive) {
            if (self.controlsHidden) {
                mutableVisibleViews = [NSMutableArray arrayWithArray:@[self.cameraPreviewView]];
            }
            else {
                [mutableVisibleViews removeObjectsInArray:@[self.callingUserImage, self.callingTopUserImage, self.topStatusLabel]];
                [mutableVisibleViews addObject:self.shadow];
            }
        }
        
        if (! self.outgoingVideoActive) {
            [mutableVisibleViews removeObject:self.cameraPreviewView];
        }
    }
    
    return [NSSet setWithArray:mutableVisibleViews];
}

- (NSSet *)visibleViewsForStateInAudioCall:(VoiceChannelOverlayState)state
{
    NSArray *visibleViews;
    switch (state) {
            
        case VoiceChannelOverlayStateInvalid:
            visibleViews = @[];
            break;
            
        case VoiceChannelOverlayStateOutgoingCall:
            visibleViews = @[self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            break;
            
        case VoiceChannelOverlayStateIncomingCall:
            visibleViews = @[self.callingUserImage, self.topStatusLabel, self.acceptButton, self.ignoreButton];
            break;
            
        case VoiceChannelOverlayStateIncomingCallInactive:
            visibleViews = @[];
            break;
            
        case VoiceChannelOverlayStateJoiningCall:
            visibleViews = @[self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            break;
            
        case VoiceChannelOverlayStateConnected:
            if (self.callingConversation.conversationType == ZMConversationTypeGroup) {
                visibleViews = @[self.participantsCollectionView, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            } else {
                visibleViews = @[self.callingUserImage, self.topStatusLabel, self.speakerButton, self.muteButton, self.leaveButton];
            }
            break;
    }
    NSMutableArray *mutableVisibleViews = [visibleViews mutableCopy];

    if (self.hidesSpeakerButton) {
        [mutableVisibleViews removeObject:self.speakerButton];
    }
    
    return [NSSet setWithArray:mutableVisibleViews];
}

- (void)updateViewsStateAndLayoutForVisibleViews:(NSSet *)visibleViews
{
    if ([visibleViews containsObject:self.callingTopUserImage]) {
        self.topStatusLabel.textAlignment = NSTextAlignmentLeft;
        self.statusLabelToTopUserImageInset.active = YES;
    }
    else {
        self.topStatusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabelToTopUserImageInset.active = NO;
    }
    
    if ([visibleViews containsObject:self.cameraPreviewView]) {
        self.cameraPreviewCenterHorisontally.constant = self.cameraPreviewPosition.x;
    }
    
    if (self.callingConversation.voiceChannel.isVideoCall) {
        self.leaveButtonPinRightConstraint.active = NO;
    }
    else {
        self.leaveButtonPinRightConstraint.active = self.hidesSpeakerButton;
    }
}

- (NSSet *)visibleViewsForState:(VoiceChannelOverlayState)state
{
    NSSet *visibleViews = nil;
    
    // Construct visible views list based on:
    // Voice channel state & is video / group call
    if (self.callingConversation.voiceChannel.isVideoCall) {
        visibleViews = [self visibleViewsForStateInVideoCall:state];
    }
    else {
        visibleViews = [self visibleViewsForStateInAudioCall:state];
    }

    // (Extra) Update
    [self updateViewsStateAndLayoutForVisibleViews:visibleViews];
    
    return visibleViews;
}

- (NSSet *)hiddenViewsForState:(VoiceChannelOverlayState)state
{
    NSSet *visibleViews = [self visibleViewsForState:state];
    NSMutableSet *hiddenViews = [[self allOverlayViews] mutableCopy];
    [hiddenViews minusSet:visibleViews];
    
    return hiddenViews;
}

- (NSAttributedString *)attributedStatus
{
    NSString *conversationName = self.callingConversation.displayName;
    
    switch (self.state) {
        
        case VoiceChannelOverlayStateInvalid:
        case VoiceChannelOverlayStateIncomingCallInactive:
            return nil;
            
        case VoiceChannelOverlayStateIncomingCall: {
            if (self.callingConversation.conversationType == ZMConversationTypeOneOnOne) {
                NSString *statusText = NSLocalizedString(@"voice.status.one_to_one.incoming", nil);
                statusText = [statusText lowercasedWithCurrentLocale];
                return [self labelTextWithFormat:statusText name:conversationName];
            } else {
                NSString *statusText = NSLocalizedString(@"voice.status.group_call.incoming", nil);
                statusText = [statusText lowercasedWithCurrentLocale];
                return [self labelTextWithFormat:statusText name:conversationName];
            }
            break;
        }
            
        case VoiceChannelOverlayStateOutgoingCall: {
            NSString *statusText = NSLocalizedString(@"voice.status.one_to_one.outgoing", nil);
            statusText = [statusText lowercasedWithCurrentLocale];
            return [self labelTextWithFormat:statusText name:conversationName];
            break;
        }
            
        case VoiceChannelOverlayStateJoiningCall: {
            NSString *statusText = NSLocalizedString(@"voice.status.joining", nil);
            statusText = [statusText lowercasedWithCurrentLocale];
            return [self labelTextWithFormat:statusText name:conversationName];
            break;
        }
            
        case VoiceChannelOverlayStateConnected: {
            NSString *statusText = [NSString stringWithFormat:@"%%@\n%@", [self.callDurationFormatter stringFromTimeInterval:self.callDuration]];
            return [self labelTextWithFormat:statusText name:conversationName];
            break;
        }
    }
}

#pragma mark - Camera preview position storage

- (CGPoint)normalizedCameraPreviewPositionFromPosition:(CGPoint)position
{
    CGPoint center = CGPointZero;

    if (position.x < - 0) {
        center = [self cameraLeftPosition];
    }
    else {
        center = [self cameraRightPosition];
    }
    
    return center;
}

- (CGPoint)cameraRightPosition
{
    const CGFloat inset = 24.0f;
    CGFloat sideInset = (self.bounds.size.width - inset) / 2.0f;
    
    return CGPointMake(sideInset, 0);
}

- (CGPoint)cameraLeftPosition
{
    const CGFloat inset = 24.0f;
    CGFloat sideInset = (self.bounds.size.width - inset) / 2.0f;
    
    return CGPointMake(- sideInset, 0);
}

- (CGPoint)cameraPreviewPosition
{
    NSString *positionString = [[NSUserDefaults standardUserDefaults] objectForKey:VoiceChannelOverlayVideoFeedPositionKey];
    if (positionString.length == 0) {
        return [self cameraRightPosition];
    }
    return CGPointFromString(positionString);
}

- (void)setCameraPreviewPosition:(CGPoint)position
{
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(position) forKey:VoiceChannelOverlayVideoFeedPositionKey];
}

#pragma mark - Message formating

- (NSDictionary *)baseAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.paragraphSpacingBefore = 8;
    
    return @{ NSParagraphStyleAttributeName : paragraphStyle };
}

- (NSDictionary *)messageAttributes
{
    UIFont *statusFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    NSMutableDictionary *attributes = [@{ NSFontAttributeName : statusFont } mutableCopy];
    [attributes addEntriesFromDictionary:self.baseAttributes];
    return attributes;
}

- (NSDictionary *)nameAttributes
{
    UIFont *nameFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"];
    NSMutableDictionary *attributes = [@{ NSFontAttributeName : nameFont } mutableCopy];
    [attributes addEntriesFromDictionary:self.baseAttributes];
    return attributes;
}

- (NSAttributedString *)labelTextWithFormat:(NSString*)format name:(NSString *)name
{
    if (name.length == 0 || format.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSAttributedString *attributedName = [[NSAttributedString alloc] initWithString:NotNilString(name) attributes:self.nameAttributes];
    return [NSAttributedString attributedStringWithDefaultAttributes:self.messageAttributes format:format, attributedName];
}

- (void)setCallDuration:(NSTimeInterval)callDuration
{
    callDuration = round(callDuration);
    
    if (_callDuration == callDuration) {
        return;
    }
    
    _callDuration = callDuration;
    
    [self updateStatusLabelText];
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    self.muteButton.selected = muted;
    self.cameraPreviewView.mutedPreviewOverlay.hidden = !self.outgoingVideoActive || !muted;
}

- (void)setSpeakerActive:(BOOL)speakerActive
{
    _speakerActive = speakerActive;
    self.speakerButton.selected = speakerActive;
}

- (void)setRemoteIsSendingVideo:(BOOL)remoteIsSendingVideo
{
    _remoteIsSendingVideo = remoteIsSendingVideo;
    [self updateVisibleViewsForCurrentState];
}

- (void)setIncomingVideoActive:(BOOL)incomingVideoActive
{
    _incomingVideoActive = incomingVideoActive;
    
    [self updateVisibleViewsForCurrentState];
    [self hideControlsAfterElapsedTime];
}

- (void)setOutgoingVideoActive:(BOOL)outgoingVideoActive;
{
    _outgoingVideoActive = outgoingVideoActive;
    
    [self updateVisibleViewsForCurrentState];
}

- (void)setAcceptButtonTarget:(id)target action:(SEL)action
{
    [self.acceptButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setAcceptVideoButtonTarget:(id)target action:(SEL)action
{
    [self.acceptVideoButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setIgnoreButtonTarget:(id)target action:(SEL)action
{
    [self.ignoreButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setLeaveButtonTarget:(id)target action:(SEL)action
{
    [self.leaveButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setMuteButtonTarget:(id)target action:(SEL)action
{
    [self.muteButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setSpeakerButtonTarget:(id)target action:(SEL)action
{
    [self.speakerButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setVideoButtonTarget:(id)target action:(SEL)action
{
    [self.videoButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setSwitchCameraButtonTarget:(id)target action:(SEL)action;
{
    [self.cameraPreviewView.switchCameraButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)animateCameraChangeWithChangeAction:(dispatch_block_t)action completion:(dispatch_block_t)completion
{
    UIView *snapshot = [self.cameraPreviewView.videoFeedOuterContainer snapshotViewAfterScreenUpdates:YES];
    [self.cameraPreviewView addSubview:snapshot];
    if (action) {
        action();
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.cameraPreviewView.switchCameraButton.layer.transform = CATransform3DRotate(CATransform3DRotate(self.cameraPreviewView.switchCameraButton.layer.transform, M_PI, 0, 1, 0), M_PI, 1, 0, 0);
        [UIView transitionWithView:self.cameraPreviewView
                          duration:0.8f
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{

                            [snapshot removeFromSuperview];
                        }
                        completion:^(BOOL finished) {
                            if (completion) {
                                completion();
                            }
                        }];
    });
}

#pragma mark - Hiding Controls

- (void)hideControls
{
    self.controlsHidden = YES;
    [self updateVisibleViewsForCurrentStateAnimated:YES];
}

- (void)hideControlsAfterElapsedTime
{
    [self cancelHideControlsAfterElapsedTime];
    [self performSelector:@selector(hideControls) withObject:nil afterDelay:4];
}

- (void)cancelHideControlsAfterElapsedTime
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls) object:nil];
}

#pragma mark - Tap

- (void)backgroundWasTapped
{
    self.controlsHidden = ! self.controlsHidden;
    [self updateVisibleViewsForCurrentStateAnimated:YES];
    
    if (! self.controlsHidden) {
        [self hideControlsAfterElapsedTime];
    }
}

#pragma mark - UICollectionViewDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    NSInteger numberOfItems = [self.participantsCollectionView numberOfItemsInSection:0];
    CGFloat contentWidth = numberOfItems * self.participantsCollectionViewLayout.itemSize.width + (MAX(numberOfItems - 1, 0)) * self.participantsCollectionViewLayout.minimumLineSpacing;
    CGFloat frameWidth = self.participantsCollectionView.frame.size.width;
    
    
    UIEdgeInsets contentInsets;
    if (contentWidth < frameWidth) {
        // Align content in center of frame
        CGFloat horizontalInset = frameWidth - contentWidth;
        contentInsets = UIEdgeInsetsMake(0, horizontalInset / 2, 0, horizontalInset / 2);
    } else {
        contentInsets = UIEdgeInsetsMake(0, 24, 0, 24);
    }
    
    return contentInsets;
}

#pragma mark - Camera preview pan

- (void)onCameraPreviewPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint offset = [panGestureRecognizer translationInView:self];
    CGFloat newPositionX = self.cameraPreviewInitialPositionX + offset.x;
    const CGFloat dragThreshold = 180.0f;
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.cameraPreviewInitialPositionX = self.cameraPreviewCenterHorisontally.constant;
            break;
            
        case UIGestureRecognizerStateChanged:
            self.cameraPreviewCenterHorisontally.constant = newPositionX;
            [self layoutIfNeeded];
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.7f animations:^() {
                CGPoint endPosition = CGPointZero;
                
                // camera was on the left
                if (self.cameraPreviewInitialPositionX < 0) {
                    if (fabs(offset.x) > dragThreshold) {
                        // move to new position
                        endPosition = [self cameraRightPosition];
                    }
                    else {
                        // bounce back
                        endPosition = [self cameraLeftPosition];
                    }
                }
                else { // camera was on the right
                    if (fabs(offset.x) > dragThreshold) {
                        // move to new position
                        endPosition = [self cameraLeftPosition];
                    }
                    else {
                        // bounce back
                        endPosition = [self cameraRightPosition];
                    }
                }
                self.cameraPreviewPosition = endPosition;
                self.cameraPreviewCenterHorisontally.constant = endPosition.x;
                [self layoutIfNeeded];
            }];
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            
            break;
            
        default:
            break;
    }
}

@end
