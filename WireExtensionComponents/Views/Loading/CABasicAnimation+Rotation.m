//
//  CABasicAnimation+CABasicAnimation_Rotation.m
//  WireExtensionComponents
//
//  Created by Zeta on 17.01.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

#import "CABasicAnimation+Rotation.h"

@implementation CABasicAnimation (Rotation)

+ (CABasicAnimation * _Nonnull)rotateAnimationWithRotationSpeed:(CGFloat)rotationSpeed beginTime:(CGFloat)beginTime delegate:(id<CAAnimationDelegate> _Nullable)delegate
    {
        CABasicAnimation* rotate =  [CABasicAnimation animationWithKeyPath: @"transform.rotation.z"];
        rotate.fillMode = kCAFillModeForwards;
        rotate.delegate = delegate;
        
        // Do a series of 5 quarter turns for a total of a 1.25 turns
        // (2PI is a full turn, so pi/2 is a quarter turn)
        [rotate setToValue: [NSNumber numberWithFloat: M_PI / 2]];
        rotate.repeatCount = HUGE_VALF;
        
        rotate.duration = rotationSpeed / 4;
        rotate.beginTime = beginTime;
        rotate.cumulative = YES;
        rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        
        return rotate;
    }
    
@end
