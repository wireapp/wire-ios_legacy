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


#import "MediaBar.h"

@import PureLayout;
@import WireExtensionComponents;
#import "UIImage+ZetaIconsNeue.h"
#import "Constants.h"
#import "Wire-Swift.h"

@interface MediaBar ()

@property (nonatomic, readwrite) UILabel *titleLabel;
@property (nonatomic) IconButton *playPauseButton;
@property (nonatomic) IconButton *closeButton;
@property (nonatomic) UIView *bottomSeparatorLine;
@property (nonatomic) UIView *contentView;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation MediaBar

- (id)init
{
    self = [super init];
    
    if (self) {
        self.contentView = [[UIView alloc] initForAutoLayout];
        [self addSubview:self.contentView];
        
        [self createTitleLabel];
        [self createPlayPauseButton];
        [self createCloseButton];
        [self createBorderView];

    }
    
    return self;
}

- (void)createTitleLabel
{
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLabel.accessibilityIdentifier = @"playingMediaTitle";
    self.titleLabel.font = UIFont.smallRegularFont;
    self.titleLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    
    [self.contentView addSubview:self.titleLabel];
}

- (void)createPlayPauseButton
{
    self.playPauseButton = [[IconButton alloc] initWithStyle:IconButtonStyleDefault];
    self.playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playPauseButton setIcon:ZetaIconTypeMediaBarPlay withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.contentView addSubview:self.playPauseButton];
}

- (void)createCloseButton
{
    self.closeButton = [[IconButton alloc] initWithStyle:IconButtonStyleDefault];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setIcon:ZetaIconTypeCancel withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.contentView addSubview:self.closeButton];
    self.closeButton.accessibilityIdentifier = @"mediabarCloseButton";
}

- (void)createBorderView
{
    self.bottomSeparatorLine = [[UIView alloc] init];
    self.bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomSeparatorLine.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator];

    [self addSubview:self.bottomSeparatorLine];
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        CGFloat iconSize = 16;
        CGFloat buttonInsets = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 32 : 16;
        [self.contentView autoPinEdgesToSuperviewEdges];
        
        [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.contentView];
        [self.titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.playPauseButton withOffset:8.0f];
        
        [self.playPauseButton autoSetDimensionsToSize:(CGSize) {iconSize, iconSize}];
        [self.playPauseButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.contentView];
        [self.playPauseButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:buttonInsets];
        
        [self.closeButton autoSetDimensionsToSize:(CGSize) {iconSize, iconSize}];
        [self.closeButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.contentView];
        [self.closeButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.titleLabel withOffset:8.0f];
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:buttonInsets];
        
        [self.bottomSeparatorLine autoSetDimension:ALDimensionHeight toSize:0.5f];
        [self.bottomSeparatorLine autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    }
    
    [super updateConstraints];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 44);
}

@end
