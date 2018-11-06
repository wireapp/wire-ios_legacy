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
#import "AnimatedListMenuView+Internal.h"
#import "Wire-Swift.h"

@implementation MenuDotView

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

@end

@implementation AnimatedListMenuView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.leftDotView = [[MenuDotView alloc] init];
        [self addSubview:self.leftDotView];
        
        self.centerDotView = [[MenuDotView alloc] init];
        [self addSubview:self.centerDotView];
        
        self.rightDotView = [[MenuDotView alloc] init];
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

@end
