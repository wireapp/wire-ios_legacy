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


#import "AnimatedListMenuView.h"

@import PureLayout;



@interface DotView : UIView

@end

@implementation DotView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 2.0;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.bounds.size.width / 2;
}

@end


@interface AnimatedListMenuView ()

@property (nonatomic) DotView *leftDotView;
@property (nonatomic) DotView *centerDotView;
@property (nonatomic) DotView *rightDotView;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) NSLayoutConstraint *centerToRightDistanceConstraint;
@property (nonatomic) NSLayoutConstraint *leftToCenterDistanceConstraint;

@end

@implementation AnimatedListMenuView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.leftDotView = [[DotView alloc] initForAutoLayout];
        [self addSubview:self.leftDotView];
        
        self.centerDotView = [[DotView alloc] initForAutoLayout];
        [self addSubview:self.centerDotView];
        
        self.rightDotView = [[DotView alloc] initForAutoLayout];
        [self addSubview:self.rightDotView];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress
{
    if (_progress == progress) {
        return;
    }
    _progress = MIN(1, MAX(0, progress));
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated
{
    [self setProgress:progress];
    
    self.centerToRightDistanceConstraint.constant = [self centerToRightDistanceForProgress:self.progress];
    self.leftToCenterDistanceConstraint.constant = [self leftToCenterDistanceForProgress:self.progress];

    if (animated) {
        [self setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25f animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (! self.initialConstraintsCreated) {
        const CGFloat dotWidth = 4;
        const CGSize dotSize = (CGSize){dotWidth, dotWidth};
        
        [self.leftDotView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.centerDotView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.rightDotView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        [self.leftDotView autoSetDimensionsToSize:dotSize];
        [self.centerDotView autoSetDimensionsToSize:dotSize];
        [self.rightDotView autoSetDimensionsToSize:dotSize];
        
        [self.rightDotView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:8];
        self.centerToRightDistanceConstraint = [self.centerDotView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.rightDotView withOffset:[self centerToRightDistanceForProgress:self.progress]];
        self.leftToCenterDistanceConstraint = [self.leftDotView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.centerDotView withOffset:[self leftToCenterDistanceForProgress:self.progress]];
        
        self.initialConstraintsCreated = YES;
    }
}

- (CGFloat)centerToRightDistanceForProgress:(CGFloat)progress
{
    return -(4 + (10 * (1 - progress)));
}

- (CGFloat)leftToCenterDistanceForProgress:(CGFloat)progress
{
    return -(4 + (20 * (1 - progress)));
}

@end
