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


#import "PageControl.h"

@implementation PageControl

#pragma mark - Init

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.dotDiameter = 5.0f;
    self.dotDistance = 4.0f;
}

#pragma mark - Properties

- (void)setDotDiameter:(CGFloat)dotDiameter
{
    _dotDiameter = dotDiameter;
    [self invalidateIntrinsicContentSize];
}

- (void)setDotDistance:(CGFloat)dotDistance
{
    _dotDistance = dotDistance;
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    CGSize parentSize = [super intrinsicContentSize];
    CGFloat width = self.numberOfPages * self.dotDiameter + (self.numberOfPages - 1) * self.dotDistance;
    return CGSizeMake(width, parentSize.height);
}

- (void)layoutSubviews
{
    for (NSInteger i = 0; i < self.numberOfPages; i++) {
        
        CGRect dotRect = CGRectMake(i * (self.dotDistance + self.dotDiameter),
                                    (self.frame.size.height - self.dotDiameter) * 0.5f,
                                    self.dotDiameter, self.dotDiameter);
        UIView *dotView = self.subviews[i];
        dotView.frame = dotRect;
        dotView.layer.cornerRadius = self.dotDiameter * 0.5f;
    }
}

@end
