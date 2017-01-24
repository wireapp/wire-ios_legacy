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


#import "VoiceChannelController.h"

#import <PureLayout/PureLayout.h>

#import "VoiceChannelOverlayController.h"
#import "zmessaging+iOS.h"
#import "VoiceChannelV2+Additions.h"
@import  AudioToolbox;
#import "Wire-Swift.h"


@interface VoiceChannelController () <VoiceChannelStateObserver>

@property (nonatomic) ZMConversation *activeCallConversation;
@property (nonatomic) id voiceChannelObserverToken;

@property (nonatomic) VoiceChannelOverlayController *primaryVoiceChannelOverlay;

@end

@implementation VoiceChannelController

- (void)viewDidLoad
{
    self.view.userInteractionEnabled = NO;
    self.view.hidden = YES;
    
    [super viewDidLoad];
    
    self.voiceChannelObserverToken = [VoiceChannelRouter addStateObserver:self userSession:[ZMUserSession sharedSession]];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)voiceChannelIsJoined
{
    if (self.activeCallConversation == nil) {
        return NO;
    }
    
    VoiceChannelV2State voiceChannelState = self.activeCallConversation.voiceChannel.state;
    return voiceChannelState == VoiceChannelV2StateSelfIsJoiningActiveChannel || voiceChannelState == VoiceChannelV2StateSelfConnectedToActiveChannel;
}

- (BOOL)voiceChannelIsActive
{
    return self.activeCallConversation != nil;
}

- (void)setPrimaryVoiceChannelOverlay:(VoiceChannelOverlayController *)voiceChannelOverlayController
{
    if (_primaryVoiceChannelOverlay == voiceChannelOverlayController) {
        return;
    }

    VoiceChannelOverlayController *previousVoiceChannelOverlayController = _primaryVoiceChannelOverlay;
    _primaryVoiceChannelOverlay = voiceChannelOverlayController;
    
    self.view.userInteractionEnabled = self.primaryVoiceChannelOverlay != nil;
    self.view.hidden = self.primaryVoiceChannelOverlay == nil;
    
    
    BOOL callIsStarting = previousVoiceChannelOverlayController == nil && voiceChannelOverlayController != nil;
    BOOL isVideoCall = voiceChannelOverlayController.conversation.voiceChannel.isVideoCall;
    
    if (callIsStarting && isVideoCall) {
        // If call is starting and is video call, select front camera as default
        NSError *error = nil;
        [voiceChannelOverlayController.conversation.voiceChannel setVideoCaptureDeviceWithDevice:ZMCaptureDeviceFront error:&error];
        
        if (nil != error) {
            DDLogError(@"Cannot set default front camera: %@", error);
        }
    }
    
    [self transitionFromVoiceChannelOverlayController:previousVoiceChannelOverlayController toVoiceChannelOverlayController:voiceChannelOverlayController];
    
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (void)transitionFromVoiceChannelOverlayController:(VoiceChannelOverlayController *)fromController toVoiceChannelOverlayController:(VoiceChannelOverlayController *)toController
{
    if (fromController == toController) {
        return;
    }
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    if (fromController == nil || fromController.parentViewController == nil) {
        
        [self addChildViewController:toController];
        toController.view.frame = self.view.frame;
        [toController.view layoutIfNeeded];
        
        [UIView transitionWithView:self.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.view addSubview:toController.view];
            [self.primaryVoiceChannelOverlay.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        } completion:^(BOOL finished) {
            [toController didMoveToParentViewController:self];
        }];
    }
    else if (toController == nil) {
        [fromController willMoveToParentViewController:nil];
        [UIView transitionWithView:self.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [fromController.view removeFromSuperview];
        } completion:^(BOOL finished) {
            [fromController removeFromParentViewController];
        }];
    }
    else {
        [fromController willMoveToParentViewController:nil];
        [self addChildViewController:toController];
        
        [self transitionFromViewController:fromController toViewController:toController duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.primaryVoiceChannelOverlay.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        } completion:nil];
    }
}

- (void)updateVoiceChannelOverlays
{
    ZMConversation *primaryVoiceChannelConversation = [self primaryVoiceChannelConversation];
    
    if (primaryVoiceChannelConversation != self.primaryVoiceChannelOverlay.conversation) {
        DDLogVoice(@"UI: Active voice channel CHANGED. Creating new overlay controller");
        self.primaryVoiceChannelOverlay = [self voiceChannelOverlayControllerForConversation:primaryVoiceChannelConversation];
    }
}

- (VoiceChannelOverlayController *)voiceChannelOverlayControllerForConversation:(ZMConversation *)conversation
{
    if (conversation == nil) {
        return nil;
    }
    
    VoiceChannelOverlayController *controller = [[VoiceChannelOverlayController alloc] initWithConversation:conversation];
    controller.view.translatesAutoresizingMaskIntoConstraints = NO;
    return controller;
}

- (ZMConversation *)primaryVoiceChannelConversation
{
    NSArray *incomingCallConversations = [[WireCallCenter nonIdleCallConversationsInUserSession:[ZMUserSession sharedSession]] filterWithBlock:^BOOL(ZMConversation *conversation) {
        return conversation.voiceChannel.state == VoiceChannelV2StateIncomingCall;
    }];
    
    if (incomingCallConversations.count > 0) {
        return incomingCallConversations.lastObject;
    }
    else if (self.activeCallConversation) {
        return self.activeCallConversation;
    }
    
    return nil;
}

- (void)updateActiveCallConversation
{
    NSArray *activeCallConversations = [[WireCallCenter nonIdleCallConversationsInUserSession:[ZMUserSession sharedSession]] filterWithBlock:^BOOL(ZMConversation *conversation) {
        return conversation.voiceChannel.state == VoiceChannelV2StateOutgoingCall |
        conversation.voiceChannel.state == VoiceChannelV2StateOutgoingCallInactive |
        conversation.voiceChannel.state == VoiceChannelV2StateSelfIsJoiningActiveChannel |
        conversation.voiceChannel.state == VoiceChannelV2StateSelfConnectedToActiveChannel;
    }];
        
    self.activeCallConversation = activeCallConversations.firstObject;
}

#pragma mark - VoiceChannelStateObserver

- (void)callCenterDidChangeVoiceChannelState:(VoiceChannelV2State)voiceChannelState conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    DDLogVoice(@"SE: Voice channel state change to %d (%@)", voiceChannelState, StringFromVoiceChannelV2State(voiceChannelState));
    [self updateActiveCallConversation];
    [self updateVoiceChannelOverlays];
}

- (void)callCenterDidFailToJoinVoiceChannelWithError:(NSError *)error conversation:(ZMConversation *)conversation
{
    
}

- (void)callCenterDidEndCallWithReason:(VoiceChannelV2CallEndReason)reason conversation:(ZMConversation *)conversation callingProtocol:(enum CallingProtocol)callingProtocol
{
    
}

@end
