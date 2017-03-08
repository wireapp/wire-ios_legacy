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


#import <zmessaging/zmessaging.h>
#import "ZMSnapshotTestCase.h"
#import "MockConversation.h"
#import "VoiceChannelOverlay.h"
#import "Wire_iOS_Tests-Swift.h"
#import "Wire-Swift.h"

@import Classy;

@interface VoiceChannelOverlayTests : ZMSnapshotTestCase

@property (nonatomic) MockConversation *conversation;
@property (nonatomic, copy) void (^configurationBlock)(UIView *, BOOL);

@end

@implementation VoiceChannelOverlayTests

- (void)setUp
{
    [super setUp];
    self.conversation = [[MockConversation alloc] init];
    self.conversation.conversationType = ZMConversationTypeOneOnOne;
    self.conversation.displayName = @"John Doe";
    self.conversation.connectedUser = [[MockUser mockUsers] lastObject];
    
    self.configurationBlock = ^(UIView *view, BOOL isPad) {
        ((VoiceChannelOverlay *)view).hidesSpeakerButton = isPad;
    };
}

- (VoiceChannelOverlay *)voiceChannelOverlayForState:(VoiceChannelOverlayState)state conversation:(MockConversation *)conversation selfUntrusted:(BOOL)untrusted
{
    VoiceChannelOverlay *voiceChannelOverlay = [[VoiceChannelOverlay alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    MockUser *selfUser = [MockUser mockSelfUser];
    selfUser.untrusted = untrusted;
    voiceChannelOverlay.selfUser = (ZMUser *)selfUser;
    voiceChannelOverlay.callingConversation = (ZMConversation *)conversation;
    [voiceChannelOverlay transitionToState:state];
    [CASStyler.defaultStyler styleItem:voiceChannelOverlay];
    voiceChannelOverlay.backgroundColor = [UIColor darkGrayColor];
    return voiceChannelOverlay;
}

- (VoiceChannelOverlay *)voiceChannelOverlayForState:(VoiceChannelOverlayState)state conversation:(MockConversation *)conversation
{
    return [self voiceChannelOverlayForState:state conversation:conversation selfUntrusted:NO];
}

- (void)testIncomingAudioCall
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateIncomingCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOutgoingAudioCall
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateOutgoingCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOutgoingAudioCallDegraded
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateOutgoingCallDegraded conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOutgoingAudioCallDegradedSelfUntrustedDevices
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateOutgoingCallDegraded conversation:self.conversation selfUntrusted: YES];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testIncomingAudioCallDegraded
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateIncomingCallDegraded conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testIncomingAudioCallDegradedSelfUntrustedDevices
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateIncomingCallDegraded conversation:self.conversation selfUntrusted: YES];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testIncomingVideoCall
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateIncomingCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOutgoingVideoCall
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateOutgoingCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testConnectingAudioCall
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateJoiningCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testConnectingVideoCall
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateJoiningCall conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testConnectingVideoCallVideoConnected
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateJoiningCall conversation:self.conversation];
    voiceChannelOverlay.incomingVideoActive = YES;
    voiceChannelOverlay.outgoingVideoActive = YES;
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOngoingAudioCall
{
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateConnected conversation:self.conversation];
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOngoingVideoCall
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateConnected conversation:self.conversation];
    voiceChannelOverlay.remoteIsSendingVideo = YES;
    voiceChannelOverlay.incomingVideoActive = YES;
    voiceChannelOverlay.outgoingVideoActive = YES;
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOngoingVideoCallWithoutIncomingVideo
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateConnected conversation:self.conversation];
    voiceChannelOverlay.remoteIsSendingVideo = NO;
    voiceChannelOverlay.incomingVideoActive = NO;
    voiceChannelOverlay.outgoingVideoActive = YES;
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

- (void)testOngoingVideoCallWithoutOutgoingVideo
{
    self.conversation.voiceChannel = [[MockVoiceChannel alloc] initWithVideoCall:YES];
    
    VoiceChannelOverlay *voiceChannelOverlay = [self voiceChannelOverlayForState:VoiceChannelOverlayStateConnected conversation:self.conversation];
    voiceChannelOverlay.remoteIsSendingVideo = YES;
    voiceChannelOverlay.incomingVideoActive = YES;
    voiceChannelOverlay.outgoingVideoActive = NO;
    ZMVerifyViewInAllDeviceSizesWithBlock(voiceChannelOverlay, self.configurationBlock);
}

@end
