//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import "WireStyleKit+Additions.h"

@implementation WireStyleKit (Additions)

+ (UIBezierPath *)pathForTeamSelection
{
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(17.98, 0.88)];
    [bezierPath addLineToPoint: CGPointMake(25.49, 5.17)];
    [bezierPath addCurveToPoint: CGPointMake(29, 11.2) controlPoint1: CGPointMake(27.54, 6.34) controlPoint2: CGPointMake(29, 8.85)];
    [bezierPath addLineToPoint: CGPointMake(29, 19.8)];
    [bezierPath addCurveToPoint: CGPointMake(25.49, 25.83) controlPoint1: CGPointMake(29, 22.16) controlPoint2: CGPointMake(27.55, 24.65)];
    [bezierPath addLineToPoint: CGPointMake(17.98, 30.12)];
    [bezierPath addCurveToPoint: CGPointMake(11.02, 30.12) controlPoint1: CGPointMake(15.94, 31.29) controlPoint2: CGPointMake(13.06, 31.29)];
    [bezierPath addLineToPoint: CGPointMake(3.51, 25.83)];
    [bezierPath addCurveToPoint: CGPointMake(0, 19.8) controlPoint1: CGPointMake(1.46, 24.66) controlPoint2: CGPointMake(0, 22.15)];
    [bezierPath addLineToPoint: CGPointMake(0, 11.2)];
    [bezierPath addCurveToPoint: CGPointMake(3.51, 5.17) controlPoint1: CGPointMake(0, 8.84) controlPoint2: CGPointMake(1.45, 6.35)];
    [bezierPath addLineToPoint: CGPointMake(11.02, 0.88)];
    [bezierPath addCurveToPoint: CGPointMake(17.98, 0.88) controlPoint1: CGPointMake(13.06, -0.29) controlPoint2: CGPointMake(15.94, -0.29)];
    [bezierPath closePath];
    
    [bezierPath applyTransform:CGAffineTransformMakeTranslation(0.5, -.5)];
    
    return bezierPath;
}

@end
