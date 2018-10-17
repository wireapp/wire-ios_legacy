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


#import "AvatarImageView.h"
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>

@interface AvatarImageView ()

@property (nonatomic) RoundedView *containerView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *initials;

@end

@implementation AvatarImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)setup
{
    _shape = AvatarImageViewShapeCircle;
    [self createContainerView];
    [self createImageView];
    [self createInitials];

    self.showInitials = YES;
    [self createConstraints];
    [self updateCornerRadius];
}

- (void)setShape:(AvatarImageViewShape)shape
{
    _shape = shape;
    [self updateCornerRadius];
}

- (void)updateCornerRadius
{
    switch (self.shape) {
        case AvatarImageViewShapeRectangle: {
            [self.containerView toggleRectangle];
            return;
        }
        case AvatarImageViewShapeCircle: {
            [self.containerView toggleCircle];
            return;
        }
        case AvatarImageViewShapeRoundedRelative: {
            [self.containerView setRelativeCornerRadiusWithMultiplier:(CGFloat)1/6 dimension:MaskDimensionHeight];
            return;
        }
    }
}

- (void)createContainerView
{
    self.containerView = [RoundedView new];
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];
}

- (void)createImageView
{
    self.imageView = [UIImageView new];
    self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
    self.imageView.opaque = NO;
    [self.containerView addSubview:self.imageView];
}

- (void)createInitials
{
    self.initials = [UILabel new];
    self.initials.opaque = NO;
    [self.containerView addSubview:self.initials];
}

- (void)createConstraints
{
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.initials.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // containerView
      [self.containerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
      [self.containerView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [self.containerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
      [self.containerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
      [self.containerView.widthAnchor constraintEqualToAnchor:self.containerView.heightAnchor],

      // imageView
      [self.imageView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
      [self.imageView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
      [self.imageView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
      [self.imageView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],

      // initials
      [self.initials.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
      [self.initials.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor]
      ];

    [NSLayoutConstraint activateConstraints:constraints];
}

- (BOOL)showInitials
{
    return self.initials.isHidden;
}

- (void)setShowInitials:(BOOL)showInitials
{
    self.initials.hidden = !showInitials;
}

@end
