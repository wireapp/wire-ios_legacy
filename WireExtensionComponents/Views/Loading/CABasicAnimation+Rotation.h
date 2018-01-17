//
//  CABasicAnimation+CABasicAnimation_Rotation.h
//  WireExtensionComponents
//
//  Created by Zeta on 17.01.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CABasicAnimation (Rotation)
    
+ (CABasicAnimation * _Nonnull)rotateAnimationWithRotationSpeed:(CGFloat)rotationSpeed beginTime:(CGFloat)beginTime delegate:(id<CAAnimationDelegate> _Nullable)delegate;
@end
