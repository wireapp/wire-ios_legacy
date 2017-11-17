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



#import <Foundation/Foundation.h>

#import "AnimatedLayer.h"


@class PulseLayer;



FOUNDATION_EXPORT NSString *const VoicePulsingAlphaAnimation;
FOUNDATION_EXPORT NSString *const VoicePulsingScaleAnimation;



@interface AnimationPhase : NSObject

@property (nonatomic, assign) CGFloat toValue;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, copy) NSString *timingFunction;
@property (nonatomic, copy) NSString *layerKeyPathToAnimate; // Key path to animate. Only the first one in an array needs this.

+ (instancetype)animationPhaseWithToValue:(CGFloat)toValue duration:(CGFloat)duration;

@end

@interface VoiceIndicatorLayer : CALayer <AnimatedLayer>

/// Use this method instead of plain addSublayer:
/// @param pulseLayer the new layer
/// @param phases NSDictionary where keys = animation keys, values = array with the AnimationPhase objects
- (void)addSublayer:(PulseLayer *)pulseLayer withAnimationPhases:(NSDictionary *)phases;

// Change the background color for all the circles
#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIColor *circleColor;
#else
@property (nonatomic, strong) NSColor *circleColor;
#endif

- (void)startAnimating;

- (void)stopAnimating;

@end
