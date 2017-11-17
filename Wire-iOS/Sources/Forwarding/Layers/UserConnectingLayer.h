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


#import <QuartzCore/QuartzCore.h>

#import "AnimatedLayer.h"

@interface UserConnectingLayer : CALayer <AnimatedLayer>

/// The scale for the connecting ring. Default is 1.1
@property (nonatomic, assign) CGFloat circleContentScale;
/// The duration for the connecting ring animation. Default is 2.0
@property (nonatomic, assign) CGFloat circleRotationDuration;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIColor *circleColor;
#else
@property (nonatomic, strong) NSColor *circleColor;
#endif

#if TARGET_OS_IPHONE
+ (instancetype)userConnectingLayerWithCircleColor:(UIColor *)color;
#else
+ (instancetype)userConnectingLayerWithCircleColor:(NSColor *)color;
#endif

@end
