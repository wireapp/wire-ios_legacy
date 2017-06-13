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


#import "GiphyNavigationBar.h"
#import "IconButton.h"
#import "UIView+Borders.h"

@import PureLayout;



@implementation GiphyNavigationBar

- (instancetype)init
{
    self = [super init];
    
    if (self) {
    
        [self createButtons];
        [self createConstrains];
    }
    
    return self;
}

- (void)createButtons
{
    self.leftButton = [IconButton iconButtonCircular];
    self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftButton.accessibilityIdentifier = @"leftButton";

    self.rightButton = [IconButton iconButtonCircular];
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightButton.accessibilityIdentifier = @"rightButton";

    self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.centerButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.centerButton.accessibilityIdentifier = @"centerButton";
    
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.centerButton];
}

- (void)createConstrains
{
    [self.leftButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(16, 16, 16, 0) excludingEdge:ALEdgeRight];
    [self.leftButton autoSetDimensionsToSize:CGSizeMake(32,32)];

    [self.rightButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(16, 0, 16, 16) excludingEdge:ALEdgeLeft];
    [self.rightButton autoSetDimensionsToSize:CGSizeMake(32,32)];
    
    [self.centerButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    [self.centerButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16];
    [self.centerButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.leftButton withOffset:8];
    [self.centerButton autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.rightButton withOffset:-8];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 64);
}

@end
