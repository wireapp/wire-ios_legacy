//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
