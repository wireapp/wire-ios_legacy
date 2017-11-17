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



#import "VoiceIndicatorLayer.h"
#import "PulseLayer.h"

#if TARGET_OS_MAC
#import <QuartzCore/QuartzCore.h>
#endif



NSString *const VoicePulsingAlphaAnimation = @"VoicePulsingAlphaAnimation";
NSString *const VoicePulsingScaleAnimation = @"VoicePulsingScaleAnimation";


@interface AnimationPhase ()

@property (nonatomic, assign) int durationInSteps;

@end


@implementation AnimationPhase

- (id)init
{
    if (self = [super init]) {
        self.timingFunction = kCAMediaTimingFunctionDefault;
    }
    return self;
}

+ (instancetype)animationPhaseWithToValue:(CGFloat)toValue duration:(CGFloat)duration
{
    AnimationPhase *phase = [[AnimationPhase alloc] init];
    phase.duration = duration;
    phase.toValue = toValue;

    return phase;
}

@end



@interface VoiceIndicatorLayer ()

@property (nonatomic, strong) NSMutableArray *pulseLayers;
@property (nonatomic, strong) NSMutableArray *animationPhases; // Array of dictionaries of arrays. For each layer, contains animation phases keyed by the animation key

@end

@implementation VoiceIndicatorLayer

- (id)init
{
    if (self = [super init]) {
        self.pulseLayers = [NSMutableArray array];
        self.animationPhases = [NSMutableArray array];
    }
    return self;
}

- (void)addSublayer:(CALayer *)layer
{
    [super addSublayer:layer];

    if ([layer isKindOfClass:[PulseLayer class]]) {
        [self.pulseLayers addObject:layer];
    }
}

- (void)addSublayer:(PulseLayer *)pulseLayer withAnimationPhases:(NSDictionary *)phases
{
    [self addSublayer:pulseLayer];
    [self.animationPhases addObject:phases];
}


- (void)layoutSublayers
{
    [super layoutSublayers];

    BOOL boundsHasChanged = NO;
    const CGRect bounds = [self bounds];
    
    PulseLayer *first = [self.pulseLayers firstObject];
    if (! CGRectEqualToRect(bounds, first.bounds)) {
        boundsHasChanged = YES;
    }

    for (PulseLayer *layer in self.pulseLayers) {
        // Reset
        layer.position = (CGPoint){bounds.size.width / 2.0, bounds.size.height / 2.0};
        layer.bounds = (CGRect){CGPointZero, bounds.size};
        layer.anchorPoint = (CGPoint){0.5, 0.5};

        // Make it big!
        CGFloat scale = layer.toContentScale;
        CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);

        CGRect transformFrame = CGRectApplyAffineTransform(bounds, transform);
        transformFrame = CGRectIntegral(transformFrame);
        transformFrame = CGRectApplyAffineTransform(transformFrame, CGAffineTransformMakeScale(1.0, 1.0));

        CGRect resultBounds = (CGRect){CGPointZero, transformFrame.size};
        layer.bounds = resultBounds;
        layer.cornerRadius = 0.5f * CGRectGetWidth(layer.frame);
    }
    
    if (boundsHasChanged && [self isAnimating]) {
        [self stopAnimating];
        [self startAnimating];
    }
}

#if TARGET_OS_IPHONE
- (void)setCircleColor:(UIColor *)color;
#else
- (void)setCircleColor:(NSColor *)color;
#endif
{
    for (PulseLayer *layer in self.pulseLayers) {
        layer.backgroundColor = color.CGColor;
    }
}

- (void)startAnimating
{
    // Check if we are animating already
    if ([self.pulseLayers count] > 0) {
        PulseLayer *pulseLayer = [self.pulseLayers firstObject];
        if ([pulseLayer animationForKey:VoicePulsingAlphaAnimation]) {
            return;
        }
    }

    for (PulseLayer *layer in self.pulseLayers) {
        NSUInteger index = [self.pulseLayers indexOfObject:layer];
        
        NSDictionary *animationDict = self.animationPhases[index];
        for (NSString *animationKey in [animationDict allKeys]) {
            NSArray *phases = animationDict[animationKey];
            CAAnimation *animation = [self animationWithPhases:phases];
            animation.repeatCount = CGFLOAT_MAX;
            [layer addAnimation:animation forKey:animationKey];
        }
    }
}

- (void)stopAnimating
{
    for (PulseLayer *pulseLayer in self.pulseLayers) {
        [pulseLayer removeAnimationForKey:VoicePulsingAlphaAnimation];
        [pulseLayer removeAnimationForKey:VoicePulsingScaleAnimation];
    }
}

- (CAAnimation *)animationWithPhases:(NSArray *)phases
{
    CGFloat totalDuration = 0.0;
    for (AnimationPhase *phase in phases) {
        totalDuration += phase.duration;
    }
    
    NSString *keyPath = ((AnimationPhase *)phases[0]).layerKeyPathToAnimate;
    NSString *animationKeyPath = keyPath;
    if ([animationKeyPath isEqualToString:@"scale"]) { animationKeyPath = @"transform"; }

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:animationKeyPath];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:phases.count];
    NSMutableArray *timings = [NSMutableArray arrayWithCapacity:phases.count];
    NSMutableArray *keyTimes = [NSMutableArray arrayWithCapacity:phases.count];
    
    CGFloat currentDuration = 0;
    for (AnimationPhase *phase in phases) {
        [keyTimes addObject:@(currentDuration / totalDuration)];
        [timings addObject:[CAMediaTimingFunction functionWithName:phase.timingFunction]];
        
        if ([keyPath isEqualToString:@"scale"]) {
            [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(phase.toValue, phase.toValue, 1)]];
            
        } else {
            [values addObject:@(phase.toValue)];
        }

        currentDuration += phase.duration;
    }
    
    animation.values = values;
    animation.keyTimes = keyTimes;
    animation.timingFunctions = timings;
    animation.duration = totalDuration;
    animation.calculationMode = kCAAnimationLinear;

    return animation;
}

- (BOOL)isAnimating
{
    PulseLayer *layer = [self.pulseLayers firstObject];
    CAAnimation *animation = [layer animationForKey:VoicePulsingAlphaAnimation];
    
    return (nil == animation) ? NO: YES;
}

@end
