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


#import "GapLoadingBar.h"
#import "GapLayer.h"
#import "WAZUIMagic.h"
#import "CAMediaTimingFunction+AdditionalEquations.h"

static NSString *GapLoadingAnimationKey = @"gapLoadingAnimation";

@interface GapLoadingBar ()

@property (nonatomic, strong) GapLayer *gapLayer;
@property (nonatomic, assign) CGFloat gapSize;
@property (nonatomic, assign) NSTimeInterval animationDuration;

@end

@implementation GapLoadingBar

+ (instancetype)barWithDefaultGapSizeAndAnimationDuration
{
    CGFloat gapSize = [WAZUIMagic cgFloatForIdentifier:@"system_status_bar.loading_gap_size"];
    CGFloat animationDuration = [WAZUIMagic cgFloatForIdentifier:@"system_status_bar.loading_gap_animation_duration"];
    
    return [[GapLoadingBar alloc] initWithGapSize:gapSize animationDuration:animationDuration];
}

- (instancetype)initWithGapSize:(CGFloat)gapSize animationDuration:(NSTimeInterval)duration
{
    self = [super init];
    if (self) {
        self.gapSize = gapSize;
        self.animationDuration = duration;
        
        [self setupGapLoadingBar];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupGapLoadingBar
{
    self.gapLayer = [GapLayer layer];
    self.gapLayer.gapSize = self.gapSize;
    self.layer.mask = self.gapLayer;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gapLayer.bounds = (CGRect) {CGPointZero, self.bounds.size};
    self.gapLayer.position = (CGPoint) {self.bounds.size.width / 2, self.bounds.size.height / 2};
    
    // restart animation
    if (self.animating) {
        [self startAnimation];
    }
}

- (void)applicationDidBecomeActive:(id)sender
{
    if (self.animating && ! self.isAnimationRunning) {
        [self startAnimation];
    }
}

- (void)applicationDidEnterBackground:(id)sender
{
    if (self.animating) {
        [self stopAnimation];
    }
}

- (BOOL)isAnimationRunning
{
    return [self.gapLayer animationForKey:GapLoadingAnimationKey] != nil;
}

- (void)startAnimation
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(gapPosition))];
    anim.fromValue = @(- self.gapSize);
    anim.toValue = @(self.bounds.size.width + self.gapSize);
    anim.removedOnCompletion = NO;
    anim.autoreverses = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.repeatCount = HUGE_VALF;
    
    anim.duration = self.animationDuration;
    anim.timingFunction = [CAMediaTimingFunction easeInOutQuart];
    [self.gapLayer addAnimation:anim forKey:GapLoadingAnimationKey];
}

- (void)stopAnimation
{
    [self.gapLayer removeAnimationForKey:GapLoadingAnimationKey];
}

- (void)setAnimating:(BOOL)animating
{
    if (_animating  == animating) {
        return;
    }
    
    _animating = animating;
    
    if (self.animating) {
        [self startAnimation];
    } else {
        [self stopAnimation];
    }
}

@end
