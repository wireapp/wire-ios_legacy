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


#import "VoiceUserImageView.h"

#import <PureLayout/PureLayout.h>

#import "VoiceIndicatorLayer+MagicInit.h"
#import "VoiceGainLayer+MagicInit.h"
#import "WAZUIMagic.h"
#import "CALayer+EasyAnimation.h"
#import "UIColor+WAZExtensions.h"

@import WireExtensionComponents;

@interface VoiceUserImageView ()

@property (nonatomic) VoiceIndicatorLayer *voicePrebakedAnimationLayer;
@property (nonatomic) VoiceGainLayer *voiceGainLayer;
@property (nonatomic) UserConnectingLayer *userConnectingLayer;
@property (nonatomic) UIImageView *groupIconImageView;

@property (nonatomic) BOOL initialVoiceUserImageViewConstraintsCreated;

@end

@implementation VoiceUserImageView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.voiceGainLayer.frame = self.bounds;
    self.voicePrebakedAnimationLayer.frame = self.bounds;
    self.userConnectingLayer.frame = self.bounds;
    
    // The scale is calculated based on image diameter + stroke
    CGFloat diameter = self.bounds.size.width;
    self.userConnectingLayer.circleContentScale = (diameter + 2 * 2) / diameter;
}

- (void)setVoiceGain:(CGFloat)voiceGain
{
    _voiceGain = voiceGain;
    self.voiceGainLayer.voiceGain = voiceGain;
}

- (void)setState:(VoiceUserImageViewState)state
{
    [CALayer performWithoutAnimations:^{
        
        // clean up old state
        switch (self.state) {
            case VoiceUserImageViewStateConnecting:
                [self.userConnectingLayer stopAnimating];
                [self.userConnectingLayer removeFromSuperlayer];
                break;
                
            case VoiceUserImageViewStateConnectingGroup:
                [self.groupIconImageView removeFromSuperview];
                break;
                
            case VoiceUserImageViewStateTalking:
                [self.voiceGainLayer removeFromSuperlayer];
                break;
                
            default:
                break;
        }
        
        _state = state;
        
        switch (self.state) {
                
            case VoiceUserImageViewStateConnecting:
                
                if (! self.userConnectingLayer) {
                    self.userConnectingLayer = [UserConnectingLayer userConnectingLayerWithCircleColor:[(id)self.user accentColor]];
                    self.userConnectingLayer.circleRotationDuration = [WAZUIMagic floatForIdentifier:@"voice_overlay.connecting_animation_rotation_duration"];
                }
                
                [self.layer insertSublayer:self.userConnectingLayer atIndex:0];
                self.userConnectingLayer.circleColor = [(id)self.user accentColor];
                [self.userConnectingLayer startAnimating];
                break;
                
                
            case VoiceUserImageViewStateConnectingGroup:
                if (! self.groupIconImageView) {
                    self.groupIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"group-icon.png"]];
                    self.groupIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
                }
                
                [self addSubview:self.groupIconImageView];
                [self.groupIconImageView autoCenterInSuperview];
                [self.groupIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
                [self.groupIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
                break;
                
            case VoiceUserImageViewStateTalking:
                if (! self.voiceGainLayer.superlayer) {
                    
                    if (! self.voiceGainLayer) {
                        self.voiceGainLayer = [VoiceGainLayer voiceGainLayerWithRingColor:UIColor.whiteColor];
                        self.voiceGainLayer.frame = self.bounds;
                    }
                    
                    [self.layer insertSublayer:self.voiceGainLayer atIndex:0];
                }
                break;
                
                default:
                break;
        }
    }];
}

- (void)updateVoiceGainLayerColor
{
    ZMAccentColor value = [self.user accentColorValue];
    [self.voiceGainLayer updateCircleColor:[UIColor colorForZMAccentColor:value]];
    self.userConnectingLayer.circleColor = [(id)self.user accentColor];
}

- (void)setUser:(id<ZMBareUser, ZMSearchableUser, AccentColorProvider>)user
{
    [super setUser:user];
    
    [self updateVoiceGainLayerColor];
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    [super userDidChange:note];
    
    if (note.accentColorValueChanged) {
       [self updateVoiceGainLayerColor];
    }
}

@end
