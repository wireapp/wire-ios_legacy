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

#import "MediaPreviewView.h"
@import WireExtensionComponents;
#import "UIFont+MagicAccess.h"



@interface MediaPreviewView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) IconButton *playButton;
@property (nonatomic) UIImageView *providerImageView;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic) UIView *overlayView;

@end



@implementation MediaPreviewView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    [self setupSubviews];
    [self setupLayout];
}

- (void)setupSubviews
{
    self.previewImageView = [[UIImageView alloc] initForAutoLayout];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.previewImageView.clipsToBounds = YES;
    [self addSubview:self.previewImageView];
    
    self.overlayView = [[UIView alloc] initForAutoLayout];
    self.overlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.48];
    [self addSubview:self.overlayView];
    
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:self.titleLabel];
    
    self.playButton = [[IconButton alloc] initForAutoLayout];
    [self.playButton setIcon:ZetaIconTypePlay withSize:ZetaIconSizeLarge forState:UIControlStateNormal];
    [self addSubview:self.playButton];
    
    self.providerImageView = [[UIImageView alloc] initForAutoLayout];
    self.providerImageView.alpha = 0.4f;
    [self addSubview:self.providerImageView];
}

- (void)setupLayout
{
    [self.previewImageView autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
    
    [self.overlayView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.overlayView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.overlayView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:1.0f];
        [self.overlayView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:1.0f];
    }];
    
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:12.0f];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:24.0f];

    [self.providerImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:15.0f];
    [self.providerImageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:24.0f];

    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.providerImageView autoPinEdge:ALEdgeLeading
                                     toEdge:ALEdgeTrailing ofView:self.titleLabel
                                 withOffset:8.0f relation:NSLayoutRelationGreaterThanOrEqual];
    
    [self.playButton autoCenterInSuperview];
}

@end
