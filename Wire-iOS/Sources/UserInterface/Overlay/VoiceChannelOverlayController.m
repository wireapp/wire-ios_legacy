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


#import <PureLayout/PureLayout.h>
#import <AVSFlowManager.h>

#import "VoiceChannelOverlayController.h"
#import "VoiceChannelOverlay.h"
#import "zmessaging+iOS.h"
#import "avs+iOS.h"
#import "ZMVoiceChannel+Additions.h"
#import "Analytics+iOS.h"
#import "VoiceChannelParticipantsController.h"
#import "VoiceChannelCollectionViewLayout.h"
#import "Constants.h"
#import "ZMVoiceChannel+Additions.h"
#import "VoiceUserImageView.h"
#import "CameraPreviewView.h"
#import <AVSVideoView.h>
#import "Settings.h"
#import "Wire-Swift.h"

@interface VoiceChannelOverlayController () <ZMVoiceChannelStateObserver, ZMVoiceChannelParticipantsObserver, AVSMediaManagerClientObserver, UIGestureRecognizerDelegate>

@property (nonatomic) UIVisualEffectView *blurEffectView;
@property (nonatomic) VoiceChannelOverlay *overlayView;
@property (nonatomic) VoiceChannelParticipantsController *participantsController;
@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;
@property (nonatomic) id <ZMVoiceChannelParticipantsObserverOpaqueToken> voiceChannelParticipantsObserverToken;
@property (nonatomic, readwrite) ZMConversation *conversation;
@property (nonatomic) NSDate *callStartedTimestamp;

@property (nonatomic) BOOL outgoingVideoActive;
@property (nonatomic) BOOL outgoingVideoWasActiveBeforeBackgrounding;
@property (nonatomic) BOOL incomingVideoActive;
@property (nonatomic) BOOL remoteIsSendingVideo;
@property (nonatomic) BOOL videoLetterboxed;

@property (nonatomic) BOOL cameraSwitchInProgress;
@end



@implementation VoiceChannelOverlayController

- (void)dealloc
{
    if (self.voiceChannelStateObserverToken != nil) {
        [self.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];
    }
    
    if (self.voiceChannelParticipantsObserverToken != nil) {
        [self.conversation.voiceChannel removeCallParticipantsObserverForToken:self.voiceChannelParticipantsObserverToken];
    }
    
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification removeObserver:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        self.remoteIsSendingVideo = conversation.isVideoCall;
    }
    
    return self;
}

- (void)loadView
{
    VoiceChannelOverlay *overlayView = [[VoiceChannelOverlay alloc] initForAutoLayout];
    [overlayView setAcceptButtonTarget:self         action:@selector(acceptButtonClicked:)];
    [overlayView setAcceptVideoButtonTarget:self    action:@selector(acceptVideoButtonClicked:)];
    [overlayView setIgnoreButtonTarget:self         action:@selector(ignoreButtonClicked:)];
    [overlayView setLeaveButtonTarget:self          action:@selector(leaveButtonClicked:)];
    [overlayView setMuteButtonTarget:self           action:@selector(muteButtonClicked:)];
    [overlayView setSpeakerButtonTarget:self        action:@selector(speakerButtonClicked:)];
    [overlayView setVideoButtonTarget:self          action:@selector(videoButtonClicked:)];
    [overlayView setSwitchCameraButtonTarget:self   action:@selector(switchCameraButtonClicked:)];
    [overlayView setCallingConversation:self.conversation];
    overlayView.hidesSpeakerButton = IS_IPAD;
    self.overlayView = overlayView;
    
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.blurEffectView.contentView addSubview:overlayView];
    
    [self.overlayView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

    self.view = self.blurEffectView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.overlayView.callDuration = 0;
    self.overlayView.remoteIsSendingVideo = self.remoteIsSendingVideo;
    [self.overlayView cas_styleClass];
    
    if (self.voiceChannelStateObserverToken == nil) {
        self.voiceChannelStateObserverToken = [self.conversation.voiceChannel addVoiceChannelStateObserver:self];
    }
    
    if (self.voiceChannelParticipantsObserverToken == nil && self.conversation.conversationType == ZMConversationTypeOneOnOne) {
        self.voiceChannelParticipantsObserverToken = [self.conversation.voiceChannel addCallParticipantsObserver:self];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoReceiveStateUpdated:) name:FlowManagerVideoReceiveStateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (![[Settings sharedSettings] disableAVS]) {
        [AVSMediaManagerClientChangeNotification addObserver:self];
    }
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    doubleTapGestureRecognizer.delegate = self;
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    
    [self updateVoiceChannelOverlayStateWithChangeInfo:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    self.overlayView.muted = mediaManager.microphoneMuted;
    self.overlayView.speakerActive = mediaManager.speakerEnabled;

    self.outgoingVideoActive = self.conversation.isVideoCall;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.overlayView.participantsCollectionViewLayout invalidateLayout];
    } completion:nil];
}

- (void)createParticipantsControllerIfNecessary
{
    if (self.participantsController != nil) {
        return;
    }
    
    self.participantsController = [[VoiceChannelParticipantsController alloc] initWithConversation:self.conversation
                                                                                    collectionView:self.overlayView.participantsCollectionView];
}

- (void)acceptButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Accept button tap");

    [self joinCurrentVoiceChannel];
}

- (void)acceptVideoButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Accept video button tap");

    [self joinCurrentVoiceChannel];
}

- (void)ignoreButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Ignore button tap");
    ZMVoiceChannel *voiceChannel = self.conversation.voiceChannel;
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [voiceChannel ignoreIncomingCall];
    } completionHandler:^{
        [Analytics shared].sessionSummary.incomingCallsMuted++;
    }];
}

- (void)leaveButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Leave button tap");
    ZMVoiceChannel *voiceChannel = self.conversation.voiceChannel;
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [voiceChannel leave];
    }];
}

- (void)muteButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Mute button tap");
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    mediaManager.microphoneMuted = ! mediaManager.microphoneMuted;
    self.overlayView.muted = mediaManager.microphoneMuted;
}

- (void)speakerButtonClicked:(id)sender
{
    DDLogVoice(@"UI: Speaker button tap");
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    mediaManager.speakerEnabled = ! mediaManager.speakerEnabled;
    // The speakerEnabled notification is delayed so we update it immediately
    self.overlayView.speakerActive = mediaManager.speakerEnabled;
}

- (void)videoButtonClicked:(id)sender
{
    __block NSError *error = nil;
    BOOL isActive = [self.conversation.voiceChannel isSendingVideoForParticipant:self.conversation.firstActiveParticipantOtherThanSelf error:&error];
    if (nil != error) {
        DDLogError(@"Cannot get video active state: %@", error);
    }
    
    error = nil;
   
    BOOL newActiveState = !isActive;
    DDLogVoice(@"UI: video from %d to %d", isActive, newActiveState);
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [self.conversation.voiceChannel setVideoSendActive:newActiveState error:&error];
    }
                                completionHandler:^{
                                    self.outgoingVideoActive = newActiveState;
                                    if (nil != error) {
                                        DDLogError(@"Cannot set video send active: %@", error);
                                    }
    }];
    
}

- (void)switchCameraButtonClicked:(id)sender;
{
    if (self.cameraSwitchInProgress) {
        return;
    }
    
    self.cameraSwitchInProgress = YES;
    
    NSString *deviceID = [self.conversation.voiceChannel.currentVideoDeviceID isEqualToString:ZMBackCameraDeviceID] ? ZMFrontCameraDeviceID : ZMBackCameraDeviceID;
    DDLogVoice(@"UI: Switch camera to %@", deviceID);
    
    [self.overlayView animateCameraChangeWithChangeAction:^{
        NSError *error = nil;
        [self.conversation.voiceChannel setVideoCaptureDevice:deviceID error:&error];
        if (nil != error) {
            DDLogError(@"Error switching camera: %@", error);
        }
    }
                                               completion:^() {
                                                   // Intentional delay
                                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                       self.cameraSwitchInProgress = NO;
                                                   });
                                               }];
}

- (void)onDoubleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    self.videoLetterboxed = !self.videoLetterboxed;
}

- (void)updateVoiceChannelOverlayStateWithChangeInfo:(VoiceChannelStateChangeInfo *)changeInfo
{
    ZMVoiceChannelState currentState = self.conversation.voiceChannel.state;
    ZMVoiceChannelState previousState = changeInfo == nil ? ZMVoiceChannelStateInvalid : changeInfo.previousState;
    
    VoiceChannelOverlayState state = [self viewStateForVoiceChannelState:currentState previousVoiceChannelState:previousState];
    [self.overlayView transitionToState:state];
    self.overlayView.speakerActive = [[[AVSProvider shared] mediaManager] isSpeakerEnabled];
}

- (VoiceChannelOverlayState)viewStateForVoiceChannelState:(ZMVoiceChannelState)voiceChannelState previousVoiceChannelState:(ZMVoiceChannelState)previousVoiceChannelState
{
    if (voiceChannelState == ZMVoiceChannelStateIncomingCall) {
        return VoiceChannelOverlayStateIncomingCall;
    }
    
    VoiceChannelOverlayState overlayState;
    switch (voiceChannelState) {
        case ZMVoiceChannelStateIncomingCall:
            overlayState = VoiceChannelOverlayStateIncomingCall;
            break;
            
        case ZMVoiceChannelStateIncomingCallInactive:
            overlayState = VoiceChannelOverlayStateIncomingCallInactive;
            break;
            
        case ZMVoiceChannelStateOutgoingCall:
        case ZMVoiceChannelStateOutgoingCallInactive:
            overlayState = VoiceChannelOverlayStateOutgoingCall;
            break;
            
        case ZMVoiceChannelStateSelfIsJoiningActiveChannel:
            if (previousVoiceChannelState == ZMVoiceChannelStateOutgoingCall || previousVoiceChannelState == ZMVoiceChannelStateOutgoingCallInactive) {
                // Hide the media establishment phase for outgoing calls
                overlayState = VoiceChannelOverlayStateOutgoingCall;
            } else {
                overlayState = VoiceChannelOverlayStateJoiningCall;
            }
            break;
            
        case ZMVoiceChannelStateSelfConnectedToActiveChannel:
            overlayState = VoiceChannelOverlayStateConnected;
            break;
            
        default:
            overlayState = VoiceChannelOverlayStateIncomingCall;
    }
    
    DDLogVoice(@"UI: VoiceChannelState %d (%@) transitioned to overlay state %ld (%@)", voiceChannelState, StringFromZMVoiceChannelState(voiceChannelState), (long)overlayState, StringFromVoiceChannelOverlayState(overlayState));
    
    return overlayState;
}

- (void)leaveConnectedVoiceChannels
{
    NSArray *nonIdleConversations = [[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations];
    [nonIdleConversations enumerateObjectsUsingBlock:^(ZMConversation*  _Nonnull conversation, NSUInteger idx, BOOL * _Nonnull stop) {
        if (conversation.voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel) {
            [conversation.voiceChannel leave];
        }
    }];
}

- (void)joinCurrentVoiceChannel
{
    [self leaveConnectedVoiceChannels];
    [self resetAudioState];
    DDLogVoice(@"UI: Accept button tap");
    [self.conversation acceptIncomingCall];
}

- (void)resetAudioState
{
    // Reset Media Manager mute/speaker state
    AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
    mediaManager.microphoneMuted = NO;
}

- (void)startCallDurationTimer
{
    self.callStartedTimestamp = self.conversation.voiceChannel.callStartDate ? self.conversation.voiceChannel.callStartDate : [NSDate date];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateCallDuration];
    });
}

- (void)updateCallDuration
{
    self.overlayView.callDuration = -[self.callStartedTimestamp timeIntervalSinceNow];
 
    @weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (self != nil) {
            [self updateCallDuration];
        }
    });
}

- (void)setOutgoingVideoActive:(BOOL)outgoingVideoActive
{
    _outgoingVideoActive = outgoingVideoActive;
    self.overlayView.outgoingVideoActive = self.outgoingVideoActive;
}

- (void)setIncomingVideoActive:(BOOL)incomingVideoActive
{
    _incomingVideoActive = incomingVideoActive;
    self.overlayView.incomingVideoActive = self.incomingVideoActive;
}

- (void)setRemoteIsSendingVideo:(BOOL)remoteIsSendingVideo
{
    _remoteIsSendingVideo = remoteIsSendingVideo;
    self.overlayView.remoteIsSendingVideo = self.remoteIsSendingVideo;
}

- (void)setVideoLetterboxed:(BOOL)videoLetterboxed
{
    _videoLetterboxed = videoLetterboxed;
    
    self.overlayView.videoView.shouldFill = !self.videoLetterboxed;
}

#pragma mark - AVSFlowManager Notifications

- (void)videoReceiveStateUpdated:(NSNotification *)note
{
    AVSVideoStateChangeInfo* changeInfo = (AVSVideoStateChangeInfo *)note.object;
    
    self.incomingVideoActive = (changeInfo.state == FLOWMANAGER_VIDEO_RECEIVE_STARTED);
    self.remoteIsSendingVideo = (changeInfo.state == FLOWMANAGER_VIDEO_RECEIVE_STARTED);
    self.overlayView.lowBandwidth = (changeInfo.reason == FLOWMANAGER_VIDEO_BAD_CONNECTION);
    DDLogVoice(@"videoReceiveStateUpdated: incomingVideo = %d, lowBandwidth = %d", self.incomingVideoActive, self.overlayView.lowBandwidth);
}

#pragma mark - ZMVoiceChannelParticipantsObserver

- (void)voiceChannelParticipantsDidChange:(VoiceChannelParticipantsChangeInfo *)info
{
    ZMVoiceChannelParticipantState *state = [info.voiceChannel participantStateForUser:self.conversation.connectedUser];
    
    if (info.otherActiveVideoCallParticipantsChanged) {
        self.remoteIsSendingVideo = state.isSendingVideo;
    }
}

#pragma mark - ZMVoiceChannelStateObserver

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    DDLogVoice(@"SE: Voice channel state did change to %@ (old %@). %@", StringFromZMVoiceChannelState(change.currentState), StringFromZMVoiceChannelState(change.previousState), change);
    
    if (change.currentState == ZMVoiceChannelStateSelfConnectedToActiveChannel && self.callStartedTimestamp == nil && !self.conversation.isVideoCall) {
        [self startCallDurationTimer];
    }
    
    if ((change.currentState == ZMVoiceChannelStateSelfConnectedToActiveChannel ||
        change.currentState == ZMVoiceChannelStateIncomingCall ||
        change.currentState == ZMVoiceChannelStateOutgoingCall)
        && self.conversation.isVideoCall) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    
    if (change.currentState == ZMVoiceChannelStateSelfConnectedToActiveChannel) {
        [self createParticipantsControllerIfNecessary];
    }
    
    [self updateVoiceChannelOverlayStateWithChangeInfo:change];
    
    if (change.currentState == ZMVoiceChannelStateNoActiveUsers || change.currentState == ZMVoiceChannelStateOutgoingCall) {
        
        BOOL otherVoiceChannelPresent = NO;
        
        for (ZMConversation *conversation in [ZMConversationList nonIdleVoiceChannelConversationsInUserSession:[ZMUserSession sharedSession]]) {
            if (! [conversation isEqual:self.conversation]) {
                otherVoiceChannelPresent = YES;
                break;
            }
        }
        if (! otherVoiceChannelPresent || change.currentState == ZMVoiceChannelStateOutgoingCall) {
            [self resetAudioState];
        }
    }
    
    if (change.currentState == ZMVoiceChannelStateNoActiveUsers) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)voiceChannelJoinFailedWithError:(NSError *)error
{
    DDLogVoice(@"SE: Voice channel join failed with error %@", error);
}

#pragma mark - AVSMediaManagerClientObserver

- (void)mediaManagerDidChange:(AVSMediaManagerClientChangeNotification *)notification
{
    if (notification.microphoneMuteChanged) {
        self.overlayView.muted = notification.manager.microphoneMuted;
    }
    
    if (notification.speakerEnableChanged) {
        self.overlayView.speakerActive = notification.manager.speakerEnabled;
    }
}

#pragma mark - Application state

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if (self.conversation.isVideoCall) {
        self.outgoingVideoWasActiveBeforeBackgrounding = self.outgoingVideoActive;
        [[ZMUserSession sharedSession] enqueueChanges:^{
            self.conversation.isSendingVideo = NO;
        }];
    }
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    if (self.conversation.isVideoCall) {
        [[ZMUserSession sharedSession] enqueueChanges:^{
            self.conversation.isSendingVideo = self.outgoingVideoWasActiveBeforeBackgrounding;
        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
