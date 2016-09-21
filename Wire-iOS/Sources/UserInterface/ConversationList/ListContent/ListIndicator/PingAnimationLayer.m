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


#import "PingAnimationLayer.h"
#import "ZetaIconTypes.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIColor+WAZExtensions.h"
#import "CAMediaTimingFunction+AdditionalEquations.h"
#import "WAZUIMagicIOS.h"



@interface PingAnimationLayer () <CAAnimationDelegate>

@property (nonatomic, strong) CALayer *pingImageLayer;

@end



@implementation PingAnimationLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupWithColor:[UIColor accentColor]];
    }
    return self;
}

- (instancetype)initWithColor:(UIColor *)color
{
    self = [super init];
    if (self) {
        [self setupWithColor:color];
    }
    return self;
}

- (void)setupWithColor:(UIColor *)color
{
    _color = color;
    
    CGFloat radius = [WAZUIMagic cgFloatForIdentifier:@"list.ping_indicator_radius"];
    self.bounds = CGRectMake(0, 0, radius * 2, radius *2);
    self.pingImageLayer = [CALayer layer];
    self.pingImageLayer.contents = (id)[self image];
    [self addSublayer:self.pingImageLayer];
}

- (void)layoutSublayers
{
    self.pingImageLayer.frame = self.bounds;
}


- (void)setColor:(UIColor *)color
{
    _color = color;
    self.pingImageLayer.contents = (id)[self image];
}

- (CGImageRef)image
{
    UIImage *image = [UIImage imageForIcon:ZetaIconTypePing fontSize:20 color:self.color];
    return image.CGImage;
}

- (void)startAnimating
{
    CAAnimation *blinkAnimation = [self blinkAnimation:3];
            
    if (blinkAnimation) {
        [self.pingImageLayer addAnimation:blinkAnimation forKey:@"blinkAnimation"];
    }
}

- (void)stopAnimating
{
    [self.pingImageLayer removeAllAnimations];
}

- (CAAnimationGroup *)blinkAnimation:(NSUInteger)repetitions
{
    CAAnimationGroup *blinkGroup = [CAAnimationGroup animation];
    blinkGroup.beginTime = CACurrentMediaTime() + 0.05f;
    blinkGroup.repeatCount = 1;
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.timingFunction = [CAMediaTimingFunction easeOutQuart];
    fadeOutAnimation.fromValue = @(1);
    fadeOutAnimation.toValue = @(0);
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.removedOnCompletion = YES;
    fadeOutAnimation.duration = 0.7f;
    fadeOutAnimation.repeatCount = repetitions;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.timingFunction = [CAMediaTimingFunction easeOutExpo];
    scaleAnimation.fromValue = @(1);
    scaleAnimation.toValue = @(1.8);
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = YES;
    scaleAnimation.duration = 0.7f;
    scaleAnimation.repeatCount = repetitions;
    
    CABasicAnimation *scaleBackAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleBackAnimation.toValue = @(1);
    scaleBackAnimation.duration = 0.01;
    scaleBackAnimation.fillMode = kCAFillModeForwards;
    scaleBackAnimation.removedOnCompletion = YES;
    scaleBackAnimation.beginTime = repetitions * fadeOutAnimation.duration;
    scaleBackAnimation.repeatCount = 1;
    
    CABasicAnimation *trace = [CABasicAnimation animationWithKeyPath:@"opacity"];
    trace.timingFunction = [CAMediaTimingFunction easeOutQuart];
    trace.fromValue = @(0);
    trace.toValue = @(1);
    trace.fillMode = kCAFillModeForwards;
    trace.removedOnCompletion = YES;
    trace.duration = 0.55f;
    trace.beginTime = repetitions * fadeOutAnimation.duration;
    trace.repeatCount = 1;
    
    [blinkGroup setAnimations:@[fadeOutAnimation, scaleAnimation, scaleBackAnimation, trace]];
    
    blinkGroup.duration = trace.duration + fadeOutAnimation.duration * repetitions + 0.05f + scaleBackAnimation.duration;
    blinkGroup.delegate = self;
    
    return blinkGroup;
}

- (void)animationDidStart:(CAAnimation *)anim
{
    DDLogDebug(@"animation did Start");
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    DDLogDebug(@"animation did stop");
}

@end
