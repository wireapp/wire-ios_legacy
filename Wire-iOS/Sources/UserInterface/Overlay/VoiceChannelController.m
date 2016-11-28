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
#import "ZMVoiceChannel+Additions.h"
@import  AudioToolbox;
#import "Wire-Swift.h"


@interface VoiceChannelController () <ZMVoiceChannelStateObserver, ZMConversationListObserver>

@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;
@property (nonatomic) id <ZMConversationListObserverOpaqueToken> conversationListObserverToken;
@property (nonatomic) ZMConversation *activeCallConversation;

@property (nonatomic) VoiceChannelOverlayController *primaryVoiceChannelOverlay;

@end

@implementation VoiceChannelController

- (void)dealloc
{
    [ZMVoiceChannel removeGlobalVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken inUserSession:[ZMUserSession sharedSession]];
}

- (void)viewDidLoad
{
    self.view.userInteractionEnabled = NO;
    self.view.hidden = YES;
    
    [super viewDidLoad];
    
    if (self.voiceChannelStateObserverToken == nil) {
        self.voiceChannelStateObserverToken = [ZMVoiceChannel addGlobalVoiceChannelStateObserver:self inUserSession:[ZMUserSession sharedSession]];
    }
    
    self.conversationListObserverToken = [[[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations] addConversationListObserver:self];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)voiceChannelIsJoined
{
    NSArray *nonIdleConversations = [[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations];
    NSArray *activeCallConversations = [nonIdleConversations objectsAtIndexes:[nonIdleConversations indexesOfObjectsPassingTest:^BOOL(ZMConversation *conversation, NSUInteger idx, BOOL *stop) {
        return conversation.voiceChannel.state == ZMVoiceChannelStateSelfIsJoiningActiveChannel ||
               conversation.voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel;
    }]];
    
    return activeCallConversations.count > 0;
}

- (BOOL)voiceChannelIsActive
{
    NSArray *nonIdleConversations = [[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations];
    NSArray *activeCallConversations = [nonIdleConversations objectsAtIndexes:[nonIdleConversations indexesOfObjectsPassingTest:^BOOL(ZMConversation *conversation, NSUInteger idx, BOOL *stop) {
        return conversation.voiceChannel.state != ZMVoiceChannelStateNoActiveUsers && 
               conversation.voiceChannel.state != ZMVoiceChannelStateInvalid;
    }]];
    
    return activeCallConversations.count > 0;
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
    // If call is starting and is video call, select front camera as default
    if (callIsStarting && isVideoCall) {
        
        // FIXME
//        NSError* cameraSetError = nil;
//        [voiceChannelOverlayController.conversation.voiceChannel setVideoCaptureDevice:ZMFrontCameraDeviceID error:&cameraSetError];
//        if (nil != cameraSetError) {
//            DDLogError(@"Cannot set default front camera: %@", cameraSetError);
//        }
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
    NSArray *nonIdleConversations = [[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations];
    NSArray *incomingCallConversations = [nonIdleConversations objectsAtIndexes:[nonIdleConversations indexesOfObjectsPassingTest:^BOOL(ZMConversation *conversation, NSUInteger idx, BOOL *stop) {
        return conversation.voiceChannel.state == ZMVoiceChannelStateIncomingCall;
    }]];
    
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
    NSArray *nonIdleConversations = [[SessionObjectCache sharedCache] nonIdleVoiceChannelConversations];
    NSArray *activeCallConversations = [nonIdleConversations objectsAtIndexes:[nonIdleConversations indexesOfObjectsPassingTest:^BOOL(ZMConversation *conversation, NSUInteger idx, BOOL *stop) {
        return conversation.voiceChannel.state == ZMVoiceChannelStateOutgoingCall |
        conversation.voiceChannel.state == ZMVoiceChannelStateOutgoingCallInactive |
        conversation.voiceChannel.state == ZMVoiceChannelStateSelfIsJoiningActiveChannel |
        conversation.voiceChannel.state == ZMVoiceChannelStateSelfConnectedToActiveChannel;
    }]];
    
    self.activeCallConversation = activeCallConversations.firstObject;
}

#pragma mark - ZMVoiceChannelStateObserver

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)info
{
    DDLogVoice(@"SE: Voice channel state change from %d (%@) to %d (%@)", info.previousState, StringFromZMVoiceChannelState(info.previousState), info.currentState, StringFromZMVoiceChannelState(info.currentState));
    [self updateActiveCallConversation];
    [self updateVoiceChannelOverlays];
}

#pragma mark - ZMConversationListObserver

- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo
{
    [self updateActiveCallConversation];
    [self updateVoiceChannelOverlays];
}

@end
