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
#import "MediaBar+Internal.h"

#import "UIImage+ZetaIconsNeue.h"
#import "Constants.h"
#import "Wire-Swift.h"



@implementation MediaBar

- (id)init
{
    self = [super init];
    
    if (self) {
        self.contentView = [[UIView alloc] init];
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
    self.titleLabel = [[UILabel alloc] init];
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


- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 44);
}

@end
