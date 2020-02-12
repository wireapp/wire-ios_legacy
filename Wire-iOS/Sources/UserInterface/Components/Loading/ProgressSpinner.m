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

@import QuartzCore;
@import WireCommonComponents;

#import "ProgressSpinner.h"
#import "ProgressSpinner+Internal.h"
#import "Wire-Swift.h"


@implementation ProgressSpinner

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    _iconSize = 32;
    _color = [UIColor whiteColor];
    
    [self createSpinner];
    [self setupConstraints];
    
    self.hidesWhenStopped = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect frame = self.spinner.layer.frame;
    self.spinner.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.spinner.layer.frame = frame;
}

- (void)createSpinner
{
    self.spinner = [[UIImageView alloc] init];
    self.spinner.contentMode = UIViewContentModeCenter;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.spinner];

    [self updateSpinnerIcon];
}

- (CGSize)intrinsicContentSize
{
    return self.spinner.image.size;
}

- (void)setColor:(UIColor *)color
{
    if ([_color isEqual:color]) {
        return;
    }
    _color = color;
    
    [self updateSpinnerIcon];
}

- (void)setIconSize:(CGFloat)iconSize
{
    _iconSize = iconSize;
    [self updateSpinnerIcon];
}

- (void)setHidesWhenStopped:(BOOL)hidesWhenStopped
{
    _hidesWhenStopped = hidesWhenStopped;
    
    self.hidden = hidesWhenStopped && ! self.isAnimationRunning;
}

- (void)setAnimating:(BOOL)animating
{
    if (_animating == animating) {
        return;
    }
    _animating = animating;
    
    if (animating) {
        [self startAnimationInternal];
    } else {
        [self stopAnimationInternal];
    }
}

- (void)stopAnimationInternal
{
    [self.spinner.layer removeAllAnimations];
}

- (void)updateSpinnerIcon
{
    self.spinner.image = [UIImage imageForIcon:WRStyleKitIconSpinner size:self.iconSize color:self.color];
}

- (void)startAnimation:(id)sender
{
    self.animating = YES;
}

- (void)stopAnimation:(id)sender
{
    self.animating = NO;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.hidesWhenStopped) {
        self.hidden = YES;
    }
}

- (void)applicationDidBecomeActive:(id)sender
{
    if (self.animating && ! self.isAnimationRunning) {
        [self startAnimationInternal];
    }
}

- (void)applicationDidEnterBackground:(id)sender
{
    if (self.animating) {
        [self stopAnimationInternal];
    }
}

- (void)didMoveToWindow
{
    if (self.window == nil) {
        // CABasicAnimation delegate is strong so we stop all animations when the view is removed.
        [self stopAnimationInternal];
    } else if (self.animating) {
        [self startAnimationInternal];
    }
}

- (BOOL)isAnimationRunning
{
    return [self.spinner.layer animationForKey:@"rotateAnimation"] != nil;
}

@end
