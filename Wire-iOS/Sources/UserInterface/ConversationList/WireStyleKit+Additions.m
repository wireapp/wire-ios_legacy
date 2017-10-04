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
    [bezierPath moveToPoint: CGPointMake(21.5, 0.94)];
    [bezierPath addLineToPoint: CGPointMake(31, 6.43)];
    [bezierPath addCurveToPoint: CGPointMake(34.5, 12.5) controlPoint1: CGPointMake(33.17, 7.69) controlPoint2: CGPointMake(34.5, 10)];
    [bezierPath addLineToPoint: CGPointMake(34.5, 23.5)];
    [bezierPath addCurveToPoint: CGPointMake(31, 29.57) controlPoint1: CGPointMake(34.5, 26) controlPoint2: CGPointMake(33.17, 28.31)];
    [bezierPath addLineToPoint: CGPointMake(21.5, 35.06)];
    [bezierPath addCurveToPoint: CGPointMake(14.5, 35.06) controlPoint1: CGPointMake(19.34, 36.31) controlPoint2: CGPointMake(16.66, 36.31)];
    [bezierPath addLineToPoint: CGPointMake(5, 29.57)];
    [bezierPath addCurveToPoint: CGPointMake(1.5, 23.5) controlPoint1: CGPointMake(2.83, 28.31) controlPoint2: CGPointMake(1.5, 26)];
    [bezierPath addLineToPoint: CGPointMake(1.5, 12.5)];
    [bezierPath addCurveToPoint: CGPointMake(5, 6.43) controlPoint1: CGPointMake(1.5, 10) controlPoint2: CGPointMake(2.83, 7.69)];
    [bezierPath addLineToPoint: CGPointMake(14.5, 0.94)];
    [bezierPath addCurveToPoint: CGPointMake(21.5, 0.94) controlPoint1: CGPointMake(16.66, -0.31) controlPoint2: CGPointMake(19.34, -0.31)];
    [bezierPath addLineToPoint: CGPointMake(21.5, 0.94)];
    [bezierPath closePath];
           
    return bezierPath;
}

@end
