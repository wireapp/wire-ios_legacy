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


@interface VoiceChannelOverlay_Old ()




@property (nonatomic) BOOL videoViewFullScreen;
@end



@implementation VoiceChannelOverlay_Old

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

- (void)updateStatusLabelText
{
    NSAttributedString *statusText = [self attributedStatus];
    if (statusText != nil) {
        self.topStatusLabel.attributedText = statusText;
    }
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
