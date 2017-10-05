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


#import "VoiceChannelParticipantCell.h"

@import PureLayout;

#import "VoiceUserImageView.h"
#import "WAZUIMagicIOS.h"
#import "Wire-Swift.h"

#import "CAMediaTimingFunction+AdditionalEquations.h"

@interface CustomAnimationLayer : CALayer

@end

@implementation CustomAnimationLayer

- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key
{
    if ([anim isKindOfClass:[CABasicAnimation class]]) {
        CABasicAnimation *originalAnimation = (CABasicAnimation *)anim;
        
        if ([originalAnimation.keyPath isEqualToString:NSStringFromSelector(@selector(opacity))]) {
            originalAnimation.timingFunction = [CAMediaTimingFunction easeOutExpo];
            originalAnimation.duration = 0.55f;
        }
        else if ([originalAnimation.keyPath isEqualToString:NSStringFromSelector(@selector(position))]) {
            if ([originalAnimation.fromValue CGPointValue].y < [originalAnimation.toValue CGPointValue].y) { // coming in
                originalAnimation.timingFunction = [CAMediaTimingFunction easeInOutExpo];
                originalAnimation.duration = 0.55f;
            }
            else if ([originalAnimation.fromValue CGPointValue].y > [originalAnimation.toValue CGPointValue].y) { // going out                
                originalAnimation.timingFunction = [CAMediaTimingFunction easeOutExpo];
                originalAnimation.duration = 0.55f;
            }
            
        }
    }
    
    
    [super addAnimation:anim forKey:key];
} 

@end


@interface VoiceChannelParticipantCell ()

@property (nonatomic) VoiceUserImageView *userImage;
@property (nonatomic) UILabel *nameLabel;

@end



@implementation VoiceChannelParticipantCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userImage = [[VoiceUserImageView alloc] initWithMagicPrefix:@"voice_overlay.user_image_view"];
        self.userImage.userSession = [ZMUserSession sharedSession];
        self.userImage.translatesAutoresizingMaskIntoConstraints = NO;
        self.userImage.state = VoiceUserImageViewStateTalking;
        [self.contentView addSubview:self.userImage];
        
        self.nameLabel = [[UILabel alloc] initForAutoLayout];
        self.nameLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
        [self.contentView addSubview:self.nameLabel];
        
        [self createInitialConstraints];
    }
    
    return self;
}

+ (Class)layerClass
{
    return CustomAnimationLayer.class;
}

- (void)createInitialConstraints
{
    [self.userImage autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.userImage];
    [self.userImage autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(6, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [self.nameLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
}

- (void)updateVoiceGain:(CGFloat)voiceGain
{
    self.userImage.voiceGain = voiceGain;
}

@end
