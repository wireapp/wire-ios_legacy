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


#import <UIKit/UIKit.h>

@class ZMUser;
@class ZMConversation;
@class VoiceChannelOverlay_Old;
@class VoiceChannelCollectionViewLayout;
@class CameraPreviewView;
@class AVSVideoView;
@class AVSVideoPreview;
@class IconLabelButton;
@class UserImageView;
@class CameraPreviewView;

typedef NS_ENUM(NSInteger, VoiceChannelOverlayState) {
    VoiceChannelOverlayStateInvalid,
    VoiceChannelOverlayStateIncomingCall,
    VoiceChannelOverlayStateIncomingCallInactive,
    VoiceChannelOverlayStateIncomingCallDegraded,
    VoiceChannelOverlayStateJoiningCall,
    VoiceChannelOverlayStateOutgoingCall,
    VoiceChannelOverlayStateOutgoingCallDegraded,
    VoiceChannelOverlayStateConnected,
};

FOUNDATION_EXPORT NSString *StringFromVoiceChannelOverlayState(VoiceChannelOverlayState state);

@interface VoiceChannelOverlay_Old : UIView

@property (nonatomic) NSTimeInterval callDuration;
@property (nonatomic) ZMConversation *callingConversation;

@property (nonatomic, assign) VoiceChannelOverlayState state;

@property (nonatomic) BOOL muted;
@property (nonatomic) BOOL speakerActive;
@property (nonatomic) BOOL remoteIsSendingVideo;
@property (nonatomic) BOOL incomingVideoActive;
@property (nonatomic) BOOL outgoingVideoActive;
@property (nonatomic) BOOL lowBandwidth;
@property (nonatomic) BOOL controlsHidden;
@property (nonatomic) BOOL hidesSpeakerButton; // Defaults to NO


- (void)setAcceptButtonTarget:(id)target action:(SEL)action;
- (void)setAcceptVideoButtonTarget:(id)target action:(SEL)action;
- (void)setIgnoreButtonTarget:(id)target action:(SEL)action;

- (void)setLeaveButtonTarget:(id)target action:(SEL)action;
- (void)setMuteButtonTarget:(id)target action:(SEL)action;
- (void)setSpeakerButtonTarget:(id)target action:(SEL)action;
- (void)setVideoButtonTarget:(id)target action:(SEL)action;
- (void)setSwitchCameraButtonTarget:(id)target action:(SEL)action;


// Views that need to be visible from Swift
- (void)updateStatusLabelText;
- (void)updateCallingUserImage;

@property (nonatomic) ZMUser *selfUser;

@property (nonatomic) CameraPreviewView *cameraPreviewView;

@property (nonatomic) UICollectionView *participantsCollectionView;
@property (nonatomic) VoiceChannelCollectionViewLayout *participantsCollectionViewLayout;

@property (nonatomic) AVSVideoPreview *videoPreview;
@property (nonatomic) AVSVideoView *videoView;

@property (nonatomic) UIView *contentContainer;
@property (nonatomic) UIView *avatarContainer;

@property (nonatomic) NSLayoutConstraint *cameraPreviewCenterHorisontally;
@property (nonatomic) CGFloat cameraPreviewInitialPositionX;

@property (nonatomic) UIView *shadow;
@property (nonatomic) UIView *videoNotAvailableBackground;

@property (nonatomic) UILabel *topStatusLabel;
@property (nonatomic) UILabel *centerStatusLabel;
@property (nonatomic) NSLayoutConstraint *statusLabelToTopUserImageInset;
@property (nonatomic) NSDateComponentsFormatter *callDurationFormatter;

@property (nonatomic) UserImageView *callingUserImage;
@property (nonatomic) UserImageView *callingTopUserImage;

@property (nonatomic) IconLabelButton *acceptButton;
@property (nonatomic) IconLabelButton *acceptVideoButton;
@property (nonatomic) IconLabelButton *ignoreButton;
@property (nonatomic) IconLabelButton *leaveButton;
@property (nonatomic) NSLayoutConstraint *leaveButtonPinRightConstraint;
@property (nonatomic) IconLabelButton *muteButton;
@property (nonatomic) IconLabelButton *speakerButton;
@property (nonatomic) IconLabelButton *videoButton;

@end
