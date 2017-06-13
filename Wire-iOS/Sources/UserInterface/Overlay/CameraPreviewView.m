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


#import "CameraPreviewView.h"
@import PureLayout;
#import "UIImage+ZetaIconsNeue.h"
#import "IconButton.h"

@interface CameraPreviewView ()
@property (nonatomic) UIView *videoFeedContainer;
@property (nonatomic) UIView *videoFeedOuterContainer;
@property (nonatomic) IconButton *switchCameraButton;
@property (nonatomic) UIImageView *mutedPreviewOverlay;
@end

@implementation CameraPreviewView

- (instancetype)initWithWidth:(CGFloat)width
{
    self = [super init];
    if (nil != self) {
        
        self.videoFeedOuterContainer = [[UIView alloc] initForAutoLayout];
        self.videoFeedOuterContainer.layer.masksToBounds = YES;
        [self addSubview:self.videoFeedOuterContainer];
        
        self.videoFeedContainer = [[UIView alloc] initForAutoLayout];
        self.videoFeedContainer.backgroundColor = [UIColor grayColor];
        [self.videoFeedOuterContainer addSubview:self.videoFeedContainer];
        
        self.mutedPreviewOverlay = [[UIImageView alloc] initForAutoLayout];
        UIImage *image = [UIImage imageForIcon:ZetaIconTypeMicrophoneWithStrikethrough iconSize:ZetaIconSizeTiny color:[UIColor whiteColor]];
        [self.mutedPreviewOverlay setImage:image];
        [self.mutedPreviewOverlay setContentMode:UIViewContentModeCenter];
        self.mutedPreviewOverlay.hidden = YES;
        [self.videoFeedOuterContainer addSubview:self.mutedPreviewOverlay];

        self.switchCameraButton = [IconButton iconButtonDefault];
        self.switchCameraButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.switchCameraButton setIcon:ZetaIconTypeCameraSwitch withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        self.switchCameraButton.accessibilityIdentifier = @"SwitchCameraButton";
        [self addSubview:self.switchCameraButton];
        
        self.videoFeedOuterContainer.layer.cornerRadius = width / 2.0f;
        [self.videoFeedOuterContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        
        [self.videoFeedContainer autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
        [self.videoFeedContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.mutedPreviewOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        
        [self.switchCameraButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.videoFeedOuterContainer];
        [self.switchCameraButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.videoFeedOuterContainer withOffset:12];
        [self.switchCameraButton autoSetDimension:ALDimensionWidth toSize:24];
        [self.switchCameraButton autoSetDimension:ALDimensionHeight toSize:24];
        [self.switchCameraButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    }
    return self;
}

@end
