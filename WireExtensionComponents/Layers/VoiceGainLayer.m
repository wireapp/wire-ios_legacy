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


#import "VoiceGainLayer.h"
#import "PulseLayer.h"
#import "Geometry.h"



@implementation VoiceGainLayer

+ (instancetype)voiceGainLayerWithRingColor:(UIColor *)color
{
    VoiceGainLayer *layer = [VoiceGainLayer layer];
    
    PulseLayer *pulser1 = [PulseLayer layer];
    pulser1.toOpacity = 0.2f;
    pulser1.toContentScale = 1.213f;
    pulser1.backgroundColor = color.CGColor;
    [layer addSublayer:pulser1];
    
    PulseLayer *pulser2 = [PulseLayer layer];
    pulser2.toOpacity = 0.3f;
    pulser2.toContentScale = 1.143f;
    pulser2.backgroundColor = color.CGColor;
    [layer addSublayer:pulser2];
    
    PulseLayer *pulser3 = [PulseLayer layer];
    pulser3.toOpacity = 0.4f;
    pulser3.toContentScale = 1.071;
    pulser3.backgroundColor = color.CGColor;
    [layer addSublayer:pulser3];
    
    return layer;
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    
    for (NSInteger i = 0; i < (NSInteger) self.sublayers.count; i++) {
        PulseLayer *layer = (PulseLayer *)self.sublayers[i];
        // Reset
        layer.position = (CGPoint){self.bounds.size.width / 2.0, self.bounds.size.height / 2.0};
        layer.bounds = (CGRect){CGPointZero, self.bounds.size};
        layer.anchorPoint = (CGPoint){0.5, 0.5};
        
        // Make it big!
        CGFloat scale = layer.toContentScale;
        CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
        
        CGRect transformFrame = CGRectApplyAffineTransform(self.bounds, transform);
        transformFrame = CGRectIntegral(transformFrame);
        transformFrame = CGRectApplyAffineTransform(transformFrame, CGAffineTransformMakeScale(1.0, 1.0));
        
        CGRect resultBounds = (CGRect){CGPointZero, transformFrame.size};
        layer.bounds = resultBounds;
        layer.cornerRadius = 0.5f * CGRectGetWidth(layer.frame);
        
        [self setOpacityForLayer:layer atIndex:i];
    }
}


/// Assumes that all sublayers are PulseLayers.
- (void)setVoiceGain:(CGFloat)voiceGain
{
    // clamp between 0 and 1 and scale up a bit
    CGFloat preScaleFactor = 0.04;
    
    _voiceGain = CGClamp(0, 1, preScaleFactor + (1 - preScaleFactor) * voiceGain);
    
    for (NSInteger i = 0; i < (NSInteger) self.sublayers.count; i++) {
        [self setOpacityForLayer:(PulseLayer *)self.sublayers[i] atIndex:i];
    }
}

- (void)setOpacityForLayer:(PulseLayer *)layer atIndex:(NSInteger)index
{
    CGFloat factor = 1.0 / self.sublayers.count;
    CGFloat topGainForMaximumAlpha = (self.sublayers.count - index) * factor;
    
    CGFloat relativeAlpha = CGClamp(0, 1, self.voiceGain / topGainForMaximumAlpha);
    layer.opacity = relativeAlpha * layer.toOpacity;
}

- (void)updateCircleColor:(UIColor *)color
{
    for (PulseLayer *pulser in self.sublayers) {
        pulser.backgroundColor = color.CGColor;
    }
}

#pragma mark - AnimatedLayer

- (void)startAnimating
{
    
}

- (void)stopAnimating
{
    
}

#if TARGET_OS_IPHONE
- (void)setCircleColor:(UIColor *)circleColor
#else
- (void)setCircleColor:(NSColor *)circleColor
#endif
{
    _circleColor = circleColor;
}

- (void)setValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        [self setVoiceGain:[value floatValue]];
    }
}

@end
