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


#import "UserConnectingLayer.h"


static NSString *const kUserConnectingLayerAnimation = @"UserConnectingLayerAnimation";



@interface UserConnectingLayer ()

@property (nonatomic, strong) CAGradientLayer *connectingGradientLayer;
@property (nonatomic, strong) CALayer *connectingSolidLayer;

@end

@implementation UserConnectingLayer

#if TARGET_OS_IPHONE
- (id)initWithCircleColor:(UIColor *)color
#else
- (id)initWithCircleColor:(NSColor *)color
#endif
{
    self = [super init];
    if (self) {
        self.circleContentScale = 1.1;
        self.circleRotationDuration = 2.0;
        
        // done by putting two halves together - one is solid color, the other a simple vertical gradient
        // it is masked into a circle, and then we just rotate the whole thing
        
        self.connectingGradientLayer = [CAGradientLayer layer];
        self.connectingGradientLayer.masksToBounds = YES;
        
        self.connectingSolidLayer = [CALayer layer];
        [self.connectingGradientLayer addSublayer:self.connectingSolidLayer];
        
        [self updateGradientColorWithColor:color];
    }
    return self;
}

#if TARGET_OS_IPHONE
+ (instancetype)userConnectingLayerWithCircleColor:(UIColor *)color;
#else
+ (instancetype)userConnectingLayerWithCircleColor:(NSColor *)color;
#endif
{
    UserConnectingLayer *layer = [[UserConnectingLayer alloc] initWithCircleColor:color];
    return layer;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    CGRect ringBounds = (CGRect){bounds.origin, {bounds.size.width * self.circleContentScale, bounds.size.height * self.circleContentScale}};
    self.connectingGradientLayer.bounds = ringBounds;
    self.connectingGradientLayer.cornerRadius = ringBounds.size.width / 2.0;
    
    CGRect frame = ringBounds;
    frame.size.width /= 2;
#if !(TARGET_OS_IPHONE)
    frame.origin.x = frame.size.width;
#endif
    self.connectingSolidLayer.frame = frame;
}

- (void)setCircleContentScale:(CGFloat)circleContentScale
{
    _circleContentScale = circleContentScale;
    [self setBounds:self.bounds];
}

- (void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    self.connectingGradientLayer.position = position;
}

#if TARGET_OS_IPHONE
- (void)setCircleColor:(UIColor *)circleColor
#else
- (void)setCircleColor:(NSColor *)circleColor
#endif
{
    _circleColor = circleColor;
    [self updateGradientColorWithColor:_circleColor];
}

- (void)startAnimating
{
    if (nil != [self.connectingGradientLayer animationForKey:kUserConnectingLayerAnimation]) {
        // Animation is already running
        return;
    }
    
    CABasicAnimation *rotator = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
#if (TARGET_OS_IPHONE)
    rotator.toValue = @((360 * M_PI) / 180);
    rotator.fromValue = @(0.0);
#else
    rotator.fromValue = @((360 * M_PI) / 180);
    rotator.toValue = @(0.0);
#endif
    rotator.duration = self.circleRotationDuration;
    rotator.autoreverses = NO;
    rotator.repeatCount = INFINITY;
    
    [self addSublayer:self.connectingGradientLayer];
    [self.connectingGradientLayer addAnimation:rotator forKey:kUserConnectingLayerAnimation];
}

- (void)stopAnimating
{
    [self.connectingGradientLayer removeAnimationForKey:kUserConnectingLayerAnimation];
    [self.connectingGradientLayer removeFromSuperlayer];
}

#if TARGET_OS_IPHONE
- (void)updateGradientColorWithColor:(UIColor *)color
#else
- (void)updateGradientColorWithColor:(NSColor *)color
#endif
{
    CGFloat r, g, b, a;
	[color getRed:&r green:&g blue:&b alpha:&a];
#if TARGET_OS_IPHONE
    self.connectingGradientLayer.colors = @[(id)[UIColor colorWithRed:r green:g blue:b alpha:0].CGColor, (id)[UIColor colorWithRed:r green:g blue:b alpha:1].CGColor];
#else
    self.connectingGradientLayer.colors = @[(id)[NSColor colorWithDeviceRed:r green:g blue:b alpha:0].CGColor, (id)[NSColor colorWithDeviceRed:r green:g blue:b alpha:1].CGColor];
#endif
    self.connectingSolidLayer.backgroundColor = color.CGColor;
}

@end
