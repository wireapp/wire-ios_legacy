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


#import "FlexibleNavigationBar.h"


const CGFloat FlexibleNavigationBarDefaultHeight = 44.0f;


@implementation FlexibleNavigationBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance
{
    self.height = FlexibleNavigationBarDefaultHeight;
}

- (void)setHeight:(CGFloat)height
{
    _height = height;
    [self updateOffsets];
    [self setNeedsLayout];
}

- (void)updateOffsets
{
    [self setTitleVerticalPositionAdjustment: - (self.height - FlexibleNavigationBarDefaultHeight) * 0.5f
                               forBarMetrics:UIBarMetricsDefault];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(self.superview.frame.size.width, self.height);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *subview in self.subviews) {
        subview.frame = CGRectMake(subview.frame.origin.x, (self.height - subview.frame.size.height) / 2.0f,
                                   subview.frame.size.width, subview.frame.size.height);
    }
}

@end
