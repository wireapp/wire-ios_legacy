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
@class VoiceChannelOverlay;
@class VoiceChannelCollectionViewLayout;
@class CameraPreviewView;
@class AVSVideoView;


typedef NS_ENUM(NSInteger, VoiceChannelOverlayState) {
    VoiceChannelOverlayStateInvalid,
    VoiceChannelOverlayStateIncomingCall,
    VoiceChannelOverlayStateIncomingCallInactive,
    VoiceChannelOverlayStateJoiningCall,
    VoiceChannelOverlayStateOutgoingCall,
    VoiceChannelOverlayStateConnected,
};

FOUNDATION_EXPORT NSString *StringFromVoiceChannelOverlayState(VoiceChannelOverlayState state);

@interface VoiceChannelOverlay : UIView

@property (nonatomic, readonly) AVSVideoView *videoView;
@property (nonatomic, readonly) CameraPreviewView *cameraPreviewView;
@property (nonatomic) NSTimeInterval callDuration;
@property (nonatomic) ZMConversation *callingConversation;

@property (nonatomic, readonly) UICollectionView *participantsCollectionView;
@property (nonatomic, readonly) VoiceChannelCollectionViewLayout *participantsCollectionViewLayout;

@property (nonatomic, assign, readonly) VoiceChannelOverlayState state;

@property (nonatomic) BOOL muted;
@property (nonatomic) BOOL speakerActive;
@property (nonatomic) BOOL remoteIsSendingVideo;
@property (nonatomic) BOOL incomingVideoActive;
@property (nonatomic) BOOL outgoingVideoActive;
@property (nonatomic) BOOL lowBandwidth;
@property (nonatomic) BOOL controlsHidden;
@property (nonatomic) BOOL hidesSpeakerButton; // Defaults to NO

- (void)transitionToState:(VoiceChannelOverlayState)state;

- (void)setAcceptButtonTarget:(id)target action:(SEL)action;
- (void)setAcceptVideoButtonTarget:(id)target action:(SEL)action;
- (void)setIgnoreButtonTarget:(id)target action:(SEL)action;

- (void)setLeaveButtonTarget:(id)target action:(SEL)action;
- (void)setMuteButtonTarget:(id)target action:(SEL)action;
- (void)setSpeakerButtonTarget:(id)target action:(SEL)action;
- (void)setVideoButtonTarget:(id)target action:(SEL)action;
- (void)setSwitchCameraButtonTarget:(id)target action:(SEL)action;

- (void)animateCameraChangeWithChangeAction:(dispatch_block_t)action completion:(dispatch_block_t)completion;

@end
