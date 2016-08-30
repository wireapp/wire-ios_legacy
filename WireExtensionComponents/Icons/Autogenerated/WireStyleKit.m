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

#import "WireStyleKit.h"


@implementation WireStyleKit

#pragma mark Cache

static UIColor* _fillColor10 = nil;

static UIImage* _imageOfOngoingcall = nil;
static UIImage* _imageOfShieldverified = nil;
static UIImage* _imageOfShieldnotverified = nil;

#pragma mark Initialization

+ (void)initialize
{
    // Colors Initialization
    _fillColor10 = [UIColor colorWithRed: 0.067 green: 0.084 blue: 0.078 alpha: 1];

}

#pragma mark Colors

+ (UIColor*)fillColor10 { return _fillColor10; }

#pragma mark Drawing Methods

+ (void)drawIcon_0x100_32ptWithColor: (UIColor*)color
{

    //// Add Drawing
    UIBezierPath* addPath = [UIBezierPath bezierPath];
    [addPath moveToPoint: CGPointMake(0, 28)];
    [addPath addLineToPoint: CGPointMake(0, 36)];
    [addPath addLineToPoint: CGPointMake(28, 36)];
    [addPath addLineToPoint: CGPointMake(28, 64)];
    [addPath addLineToPoint: CGPointMake(36, 64)];
    [addPath addLineToPoint: CGPointMake(36, 36)];
    [addPath addLineToPoint: CGPointMake(64, 36)];
    [addPath addLineToPoint: CGPointMake(64, 28)];
    [addPath addLineToPoint: CGPointMake(36, 28)];
    [addPath addLineToPoint: CGPointMake(36, 0)];
    [addPath addLineToPoint: CGPointMake(28, 0)];
    [addPath addLineToPoint: CGPointMake(28, 28)];
    [addPath addLineToPoint: CGPointMake(0, 28)];
    [addPath closePath];
    addPath.miterLimit = 4;

    addPath.usesEvenOddFillRule = YES;

    [color setFill];
    [addPath fill];
}

+ (void)drawIcon_0x102_32ptWithColor: (UIColor*)color
{

    //// Remove Drawing
    UIBezierPath* removePath = [UIBezierPath bezierPath];
    [removePath moveToPoint: CGPointMake(22.64, 55.86)];
    [removePath addLineToPoint: CGPointMake(63.98, 13.71)];
    [removePath addLineToPoint: CGPointMake(58.32, 8)];
    [removePath addLineToPoint: CGPointMake(22.64, 44.44)];
    [removePath addLineToPoint: CGPointMake(5.66, 27.32)];
    [removePath addLineToPoint: CGPointMake(0, 33.03)];
    [removePath addLineToPoint: CGPointMake(22.64, 55.86)];
    [removePath closePath];
    removePath.miterLimit = 4;

    removePath.usesEvenOddFillRule = YES;

    [color setFill];
    [removePath fill];
}

+ (void)drawIcon_0x104_32ptWithColor: (UIColor*)color
{

    //// Block Drawing
    UIBezierPath* blockPath = [UIBezierPath bezierPath];
    [blockPath moveToPoint: CGPointMake(32, 64)];
    [blockPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [blockPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [blockPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [blockPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [blockPath closePath];
    [blockPath moveToPoint: CGPointMake(51.56, 18.09)];
    [blockPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(54.36, 22.02) controlPoint2: CGPointMake(56, 26.82)];
    [blockPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(56, 45.25) controlPoint2: CGPointMake(45.25, 56)];
    [blockPath addCurveToPoint: CGPointMake(18.09, 51.56) controlPoint1: CGPointMake(26.82, 56) controlPoint2: CGPointMake(22.02, 54.36)];
    [blockPath addLineToPoint: CGPointMake(50.83, 18.83)];
    [blockPath addLineToPoint: CGPointMake(51.56, 18.09)];
    [blockPath addLineToPoint: CGPointMake(51.56, 18.09)];
    [blockPath closePath];
    [blockPath moveToPoint: CGPointMake(45.91, 12.44)];
    [blockPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(41.98, 9.64) controlPoint2: CGPointMake(37.18, 8)];
    [blockPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [blockPath addCurveToPoint: CGPointMake(12.44, 45.91) controlPoint1: CGPointMake(8, 37.18) controlPoint2: CGPointMake(9.64, 41.98)];
    [blockPath addLineToPoint: CGPointMake(45.17, 13.17)];
    [blockPath addLineToPoint: CGPointMake(45.91, 12.44)];
    [blockPath addLineToPoint: CGPointMake(45.91, 12.44)];
    [blockPath closePath];
    blockPath.miterLimit = 4;

    blockPath.usesEvenOddFillRule = YES;

    [color setFill];
    [blockPath fill];
}

+ (void)drawIcon_0x105_32ptWithColor: (UIColor*)color
{

    //// Path Drawing
    UIBezierPath* pathPath = [UIBezierPath bezierPath];
    [pathPath moveToPoint: CGPointMake(64, 32)];
    [pathPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(64, 14.33) controlPoint2: CGPointMake(49.67, 0)];
    [pathPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 0) controlPoint2: CGPointMake(0, 14.33)];
    [pathPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(0, 49.67) controlPoint2: CGPointMake(14.33, 64)];
    [pathPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 64) controlPoint2: CGPointMake(64, 49.67)];
    [pathPath closePath];
    [pathPath moveToPoint: CGPointMake(4, 32)];
    [pathPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(4, 16.54) controlPoint2: CGPointMake(16.54, 4)];
    [pathPath addCurveToPoint: CGPointMake(60, 32) controlPoint1: CGPointMake(47.46, 4) controlPoint2: CGPointMake(60, 16.54)];
    [pathPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(60, 47.46) controlPoint2: CGPointMake(47.46, 60)];
    [pathPath addCurveToPoint: CGPointMake(4, 32) controlPoint1: CGPointMake(16.54, 60) controlPoint2: CGPointMake(4, 47.46)];
    [pathPath closePath];
    [pathPath moveToPoint: CGPointMake(20, 30)];
    [pathPath addCurveToPoint: CGPointMake(18, 32) controlPoint1: CGPointMake(18.9, 30) controlPoint2: CGPointMake(18, 30.9)];
    [pathPath addCurveToPoint: CGPointMake(20, 34) controlPoint1: CGPointMake(18, 33.1) controlPoint2: CGPointMake(18.9, 34)];
    [pathPath addLineToPoint: CGPointMake(44, 34)];
    [pathPath addCurveToPoint: CGPointMake(46, 32) controlPoint1: CGPointMake(45.1, 34) controlPoint2: CGPointMake(46, 33.1)];
    [pathPath addCurveToPoint: CGPointMake(44, 30) controlPoint1: CGPointMake(46, 30.9) controlPoint2: CGPointMake(45.1, 30)];
    [pathPath addLineToPoint: CGPointMake(20, 30)];
    [pathPath closePath];
    pathPath.miterLimit = 4;

    pathPath.usesEvenOddFillRule = YES;

    [color setFill];
    [pathPath fill];
}

+ (void)drawIcon_0x120_32ptWithColor: (UIColor*)color
{

    //// Flip Drawing
    UIBezierPath* flipPath = [UIBezierPath bezierPath];
    [flipPath moveToPoint: CGPointMake(36, 16.19)];
    [flipPath addCurveToPoint: CGPointMake(64, 40) controlPoint1: CGPointMake(51.79, 17.66) controlPoint2: CGPointMake(64, 27.76)];
    [flipPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 53.25) controlPoint2: CGPointMake(49.67, 64)];
    [flipPath addCurveToPoint: CGPointMake(0, 40) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 53.25)];
    [flipPath addCurveToPoint: CGPointMake(12, 21.26) controlPoint1: CGPointMake(0, 32.42) controlPoint2: CGPointMake(4.68, 25.66)];
    [flipPath addLineToPoint: CGPointMake(12, 21.26)];
    [flipPath addLineToPoint: CGPointMake(12, 31.3)];
    [flipPath addCurveToPoint: CGPointMake(8, 40) controlPoint1: CGPointMake(9.46, 33.87) controlPoint2: CGPointMake(8, 36.9)];
    [flipPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 48.25) controlPoint2: CGPointMake(18.33, 56)];
    [flipPath addCurveToPoint: CGPointMake(56, 40) controlPoint1: CGPointMake(45.67, 56) controlPoint2: CGPointMake(56, 48.25)];
    [flipPath addCurveToPoint: CGPointMake(36, 24.23) controlPoint1: CGPointMake(56, 32.57) controlPoint2: CGPointMake(47.64, 25.56)];
    [flipPath addLineToPoint: CGPointMake(36, 40)];
    [flipPath addLineToPoint: CGPointMake(20, 20)];
    [flipPath addLineToPoint: CGPointMake(36, 0)];
    [flipPath addLineToPoint: CGPointMake(36, 16.19)];
    [flipPath addLineToPoint: CGPointMake(36, 16.19)];
    [flipPath closePath];
    flipPath.miterLimit = 4;

    flipPath.usesEvenOddFillRule = YES;

    [color setFill];
    [flipPath fill];
}

+ (void)drawIcon_0x125_32ptWithColor: (UIColor*)color
{

    //// More Drawing
    UIBezierPath* morePath = [UIBezierPath bezierPath];
    [morePath moveToPoint: CGPointMake(8, 40)];
    [morePath addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(12.42, 40) controlPoint2: CGPointMake(16, 36.42)];
    [morePath addCurveToPoint: CGPointMake(8, 24) controlPoint1: CGPointMake(16, 27.58) controlPoint2: CGPointMake(12.42, 24)];
    [morePath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(3.58, 24) controlPoint2: CGPointMake(0, 27.58)];
    [morePath addCurveToPoint: CGPointMake(8, 40) controlPoint1: CGPointMake(0, 36.42) controlPoint2: CGPointMake(3.58, 40)];
    [morePath addLineToPoint: CGPointMake(8, 40)];
    [morePath closePath];
    [morePath moveToPoint: CGPointMake(56, 40)];
    [morePath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(60.42, 40) controlPoint2: CGPointMake(64, 36.42)];
    [morePath addCurveToPoint: CGPointMake(56, 24) controlPoint1: CGPointMake(64, 27.58) controlPoint2: CGPointMake(60.42, 24)];
    [morePath addCurveToPoint: CGPointMake(48, 32) controlPoint1: CGPointMake(51.58, 24) controlPoint2: CGPointMake(48, 27.58)];
    [morePath addCurveToPoint: CGPointMake(56, 40) controlPoint1: CGPointMake(48, 36.42) controlPoint2: CGPointMake(51.58, 40)];
    [morePath addLineToPoint: CGPointMake(56, 40)];
    [morePath closePath];
    [morePath moveToPoint: CGPointMake(32, 40)];
    [morePath addCurveToPoint: CGPointMake(40, 32) controlPoint1: CGPointMake(36.42, 40) controlPoint2: CGPointMake(40, 36.42)];
    [morePath addCurveToPoint: CGPointMake(32, 24) controlPoint1: CGPointMake(40, 27.58) controlPoint2: CGPointMake(36.42, 24)];
    [morePath addCurveToPoint: CGPointMake(24, 32) controlPoint1: CGPointMake(27.58, 24) controlPoint2: CGPointMake(24, 27.58)];
    [morePath addCurveToPoint: CGPointMake(32, 40) controlPoint1: CGPointMake(24, 36.42) controlPoint2: CGPointMake(27.58, 40)];
    [morePath addLineToPoint: CGPointMake(32, 40)];
    [morePath closePath];
    morePath.miterLimit = 4;

    morePath.usesEvenOddFillRule = YES;

    [color setFill];
    [morePath fill];
}

+ (void)drawIcon_0x137_32ptWithColor: (UIColor*)color
{

    //// Ping Drawing
    UIBezierPath* pingPath = [UIBezierPath bezierPath];
    [pingPath moveToPoint: CGPointMake(23.8, 17.09)];
    [pingPath addCurveToPoint: CGPointMake(28.78, 19.97) controlPoint1: CGPointMake(24.38, 19.26) controlPoint2: CGPointMake(26.61, 20.55)];
    [pingPath addCurveToPoint: CGPointMake(31.65, 14.99) controlPoint1: CGPointMake(30.94, 19.38) controlPoint2: CGPointMake(32.23, 17.15)];
    [pingPath addLineToPoint: CGPointMake(28.44, 3.01)];
    [pingPath addCurveToPoint: CGPointMake(23.46, 0.14) controlPoint1: CGPointMake(27.86, 0.85) controlPoint2: CGPointMake(25.63, -0.44)];
    [pingPath addCurveToPoint: CGPointMake(20.59, 5.12) controlPoint1: CGPointMake(21.29, 0.72) controlPoint2: CGPointMake(20.01, 2.95)];
    [pingPath addLineToPoint: CGPointMake(23.8, 17.09)];
    [pingPath addLineToPoint: CGPointMake(23.8, 17.09)];
    [pingPath addLineToPoint: CGPointMake(23.8, 17.09)];
    [pingPath closePath];
    [pingPath moveToPoint: CGPointMake(40.2, 46.91)];
    [pingPath addCurveToPoint: CGPointMake(35.22, 44.04) controlPoint1: CGPointMake(39.62, 44.74) controlPoint2: CGPointMake(37.39, 43.45)];
    [pingPath addCurveToPoint: CGPointMake(32.35, 49.01) controlPoint1: CGPointMake(33.06, 44.62) controlPoint2: CGPointMake(31.77, 46.85)];
    [pingPath addLineToPoint: CGPointMake(35.56, 60.99)];
    [pingPath addCurveToPoint: CGPointMake(40.54, 63.86) controlPoint1: CGPointMake(36.14, 63.15) controlPoint2: CGPointMake(38.37, 64.44)];
    [pingPath addCurveToPoint: CGPointMake(43.41, 58.88) controlPoint1: CGPointMake(42.71, 63.28) controlPoint2: CGPointMake(43.99, 61.05)];
    [pingPath addLineToPoint: CGPointMake(40.2, 46.91)];
    [pingPath addLineToPoint: CGPointMake(40.2, 46.91)];
    [pingPath addLineToPoint: CGPointMake(40.2, 46.91)];
    [pingPath closePath];
    [pingPath moveToPoint: CGPointMake(14.99, 31.65)];
    [pingPath addCurveToPoint: CGPointMake(19.97, 28.78) controlPoint1: CGPointMake(17.15, 32.23) controlPoint2: CGPointMake(19.38, 30.94)];
    [pingPath addCurveToPoint: CGPointMake(17.09, 23.8) controlPoint1: CGPointMake(20.55, 26.61) controlPoint2: CGPointMake(19.26, 24.38)];
    [pingPath addLineToPoint: CGPointMake(5.12, 20.59)];
    [pingPath addCurveToPoint: CGPointMake(0.14, 23.46) controlPoint1: CGPointMake(2.95, 20.01) controlPoint2: CGPointMake(0.72, 21.29)];
    [pingPath addCurveToPoint: CGPointMake(3.01, 28.44) controlPoint1: CGPointMake(-0.44, 25.63) controlPoint2: CGPointMake(0.85, 27.86)];
    [pingPath addLineToPoint: CGPointMake(14.99, 31.65)];
    [pingPath addLineToPoint: CGPointMake(14.99, 31.65)];
    [pingPath addLineToPoint: CGPointMake(14.99, 31.65)];
    [pingPath closePath];
    [pingPath moveToPoint: CGPointMake(49.01, 32.35)];
    [pingPath addCurveToPoint: CGPointMake(44.04, 35.22) controlPoint1: CGPointMake(46.85, 31.77) controlPoint2: CGPointMake(44.62, 33.06)];
    [pingPath addCurveToPoint: CGPointMake(46.91, 40.2) controlPoint1: CGPointMake(43.45, 37.39) controlPoint2: CGPointMake(44.74, 39.62)];
    [pingPath addLineToPoint: CGPointMake(58.88, 43.41)];
    [pingPath addCurveToPoint: CGPointMake(63.86, 40.54) controlPoint1: CGPointMake(61.05, 43.99) controlPoint2: CGPointMake(63.28, 42.71)];
    [pingPath addCurveToPoint: CGPointMake(60.99, 35.56) controlPoint1: CGPointMake(64.44, 38.37) controlPoint2: CGPointMake(63.15, 36.14)];
    [pingPath addLineToPoint: CGPointMake(49.01, 32.35)];
    [pingPath addLineToPoint: CGPointMake(49.01, 32.35)];
    [pingPath addLineToPoint: CGPointMake(49.01, 32.35)];
    [pingPath closePath];
    [pingPath moveToPoint: CGPointMake(23.19, 46.56)];
    [pingPath addCurveToPoint: CGPointMake(23.19, 40.81) controlPoint1: CGPointMake(24.78, 44.97) controlPoint2: CGPointMake(24.78, 42.4)];
    [pingPath addCurveToPoint: CGPointMake(17.44, 40.81) controlPoint1: CGPointMake(21.6, 39.22) controlPoint2: CGPointMake(19.03, 39.22)];
    [pingPath addLineToPoint: CGPointMake(8.68, 49.57)];
    [pingPath addCurveToPoint: CGPointMake(8.68, 55.32) controlPoint1: CGPointMake(7.09, 51.16) controlPoint2: CGPointMake(7.09, 53.74)];
    [pingPath addCurveToPoint: CGPointMake(14.43, 55.32) controlPoint1: CGPointMake(10.26, 56.91) controlPoint2: CGPointMake(12.84, 56.91)];
    [pingPath addLineToPoint: CGPointMake(23.19, 46.56)];
    [pingPath addLineToPoint: CGPointMake(23.19, 46.56)];
    [pingPath addLineToPoint: CGPointMake(23.19, 46.56)];
    [pingPath closePath];
    [pingPath moveToPoint: CGPointMake(40.81, 17.44)];
    [pingPath addCurveToPoint: CGPointMake(40.81, 23.19) controlPoint1: CGPointMake(39.22, 19.03) controlPoint2: CGPointMake(39.22, 21.6)];
    [pingPath addCurveToPoint: CGPointMake(46.56, 23.19) controlPoint1: CGPointMake(42.4, 24.78) controlPoint2: CGPointMake(44.97, 24.78)];
    [pingPath addLineToPoint: CGPointMake(55.32, 14.43)];
    [pingPath addCurveToPoint: CGPointMake(55.32, 8.68) controlPoint1: CGPointMake(56.91, 12.84) controlPoint2: CGPointMake(56.91, 10.26)];
    [pingPath addCurveToPoint: CGPointMake(49.57, 8.68) controlPoint1: CGPointMake(53.74, 7.09) controlPoint2: CGPointMake(51.16, 7.09)];
    [pingPath addLineToPoint: CGPointMake(40.81, 17.44)];
    [pingPath addLineToPoint: CGPointMake(40.81, 17.44)];
    [pingPath addLineToPoint: CGPointMake(40.81, 17.44)];
    [pingPath closePath];
    pingPath.miterLimit = 4;

    pingPath.usesEvenOddFillRule = YES;

    [color setFill];
    [pingPath fill];
}

+ (void)drawIcon_0x143_32ptWithColor: (UIColor*)color
{

    //// Camera Drawing
    UIBezierPath* cameraPath = [UIBezierPath bezierPath];
    [cameraPath moveToPoint: CGPointMake(18.29, 8)];
    [cameraPath addLineToPoint: CGPointMake(19.16, 3.94)];
    [cameraPath addCurveToPoint: CGPointMake(23.96, 0) controlPoint1: CGPointMake(19.62, 1.76) controlPoint2: CGPointMake(21.8, 0)];
    [cameraPath addLineToPoint: CGPointMake(40.04, 0)];
    [cameraPath addCurveToPoint: CGPointMake(44.84, 3.94) controlPoint1: CGPointMake(42.23, 0) controlPoint2: CGPointMake(44.37, 1.74)];
    [cameraPath addLineToPoint: CGPointMake(45.71, 8)];
    [cameraPath addLineToPoint: CGPointMake(56.02, 8)];
    [cameraPath addCurveToPoint: CGPointMake(64, 16.02) controlPoint1: CGPointMake(60.43, 8) controlPoint2: CGPointMake(64, 11.59)];
    [cameraPath addLineToPoint: CGPointMake(64, 55.98)];
    [cameraPath addCurveToPoint: CGPointMake(56.02, 64) controlPoint1: CGPointMake(64, 60.41) controlPoint2: CGPointMake(60.42, 64)];
    [cameraPath addLineToPoint: CGPointMake(7.98, 64)];
    [cameraPath addCurveToPoint: CGPointMake(0, 55.98) controlPoint1: CGPointMake(3.57, 64) controlPoint2: CGPointMake(0, 60.41)];
    [cameraPath addLineToPoint: CGPointMake(0, 16.02)];
    [cameraPath addCurveToPoint: CGPointMake(7.98, 8) controlPoint1: CGPointMake(0, 11.59) controlPoint2: CGPointMake(3.58, 8)];
    [cameraPath addLineToPoint: CGPointMake(18.29, 8)];
    [cameraPath addLineToPoint: CGPointMake(18.29, 8)];
    [cameraPath closePath];
    [cameraPath moveToPoint: CGPointMake(32, 16)];
    [cameraPath addCurveToPoint: CGPointMake(52, 36) controlPoint1: CGPointMake(43.04, 16) controlPoint2: CGPointMake(52, 24.95)];
    [cameraPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(52, 47.05) controlPoint2: CGPointMake(43.04, 56)];
    [cameraPath addCurveToPoint: CGPointMake(12, 36) controlPoint1: CGPointMake(20.95, 56) controlPoint2: CGPointMake(12, 47.05)];
    [cameraPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(12, 24.95) controlPoint2: CGPointMake(20.95, 16)];
    [cameraPath closePath];
    [cameraPath moveToPoint: CGPointMake(32, 48)];
    [cameraPath addCurveToPoint: CGPointMake(44, 36) controlPoint1: CGPointMake(38.63, 48) controlPoint2: CGPointMake(44, 42.63)];
    [cameraPath addCurveToPoint: CGPointMake(32, 24) controlPoint1: CGPointMake(44, 29.37) controlPoint2: CGPointMake(38.63, 24)];
    [cameraPath addCurveToPoint: CGPointMake(20, 36) controlPoint1: CGPointMake(25.37, 24) controlPoint2: CGPointMake(20, 29.37)];
    [cameraPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(20, 42.63) controlPoint2: CGPointMake(25.37, 48)];
    [cameraPath closePath];
    cameraPath.miterLimit = 4;

    cameraPath.usesEvenOddFillRule = YES;

    [color setFill];
    [cameraPath fill];
}

+ (void)drawIcon_0x144_32ptWithColor: (UIColor*)color
{

    //// Shutter Drawing
    UIBezierPath* shutterPath = [UIBezierPath bezierPath];
    [shutterPath moveToPoint: CGPointMake(32, 56)];
    [shutterPath addLineToPoint: CGPointMake(32, 56)];
    [shutterPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 56) controlPoint2: CGPointMake(56, 45.25)];
    [shutterPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(56, 18.75) controlPoint2: CGPointMake(45.25, 8)];
    [shutterPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [shutterPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [shutterPath addLineToPoint: CGPointMake(32, 56)];
    [shutterPath addLineToPoint: CGPointMake(32, 56)];
    [shutterPath closePath];
    [shutterPath moveToPoint: CGPointMake(32, 64)];
    [shutterPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [shutterPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [shutterPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [shutterPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [shutterPath closePath];
    [shutterPath moveToPoint: CGPointMake(32, 52)];
    [shutterPath addCurveToPoint: CGPointMake(52, 32) controlPoint1: CGPointMake(43.05, 52) controlPoint2: CGPointMake(52, 43.05)];
    [shutterPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(52, 20.95) controlPoint2: CGPointMake(43.05, 12)];
    [shutterPath addCurveToPoint: CGPointMake(12, 32) controlPoint1: CGPointMake(20.95, 12) controlPoint2: CGPointMake(12, 20.95)];
    [shutterPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(12, 43.05) controlPoint2: CGPointMake(20.95, 52)];
    [shutterPath closePath];
    shutterPath.miterLimit = 4;

    shutterPath.usesEvenOddFillRule = YES;

    [color setFill];
    [shutterPath fill];
}

+ (void)drawIcon_0x145_32ptWithColor: (UIColor*)color
{

    //// Picture Drawing
    UIBezierPath* picturePath = [UIBezierPath bezierPath];
    [picturePath moveToPoint: CGPointMake(0, 4)];
    [picturePath addCurveToPoint: CGPointMake(4, -0) controlPoint1: CGPointMake(0, 1.79) controlPoint2: CGPointMake(1.78, -0)];
    [picturePath addLineToPoint: CGPointMake(60, -0)];
    [picturePath addCurveToPoint: CGPointMake(64, 4) controlPoint1: CGPointMake(62.21, -0) controlPoint2: CGPointMake(64, 1.78)];
    [picturePath addLineToPoint: CGPointMake(64, 60)];
    [picturePath addCurveToPoint: CGPointMake(60, 64) controlPoint1: CGPointMake(64, 62.21) controlPoint2: CGPointMake(62.22, 64)];
    [picturePath addLineToPoint: CGPointMake(4, 64)];
    [picturePath addCurveToPoint: CGPointMake(0, 60) controlPoint1: CGPointMake(1.79, 64) controlPoint2: CGPointMake(0, 62.22)];
    [picturePath addLineToPoint: CGPointMake(0, 4)];
    [picturePath closePath];
    [picturePath moveToPoint: CGPointMake(56, 8)];
    [picturePath addLineToPoint: CGPointMake(8, 8)];
    [picturePath addLineToPoint: CGPointMake(8, 44.08)];
    [picturePath addLineToPoint: CGPointMake(24, 36)];
    [picturePath addLineToPoint: CGPointMake(56, 49.95)];
    [picturePath addLineToPoint: CGPointMake(56, 8)];
    [picturePath closePath];
    [picturePath moveToPoint: CGPointMake(40, 32)];
    [picturePath addCurveToPoint: CGPointMake(48, 24) controlPoint1: CGPointMake(44.42, 32) controlPoint2: CGPointMake(48, 28.42)];
    [picturePath addCurveToPoint: CGPointMake(40, 16) controlPoint1: CGPointMake(48, 19.58) controlPoint2: CGPointMake(44.42, 16)];
    [picturePath addCurveToPoint: CGPointMake(32, 24) controlPoint1: CGPointMake(35.58, 16) controlPoint2: CGPointMake(32, 19.58)];
    [picturePath addCurveToPoint: CGPointMake(40, 32) controlPoint1: CGPointMake(32, 28.42) controlPoint2: CGPointMake(35.58, 32)];
    [picturePath closePath];
    picturePath.miterLimit = 4;

    picturePath.usesEvenOddFillRule = YES;

    [color setFill];
    [picturePath fill];
}

+ (void)drawIcon_0x150_32ptWithColor: (UIColor*)color
{

    //// Chat Drawing
    UIBezierPath* chatPath = [UIBezierPath bezierPath];
    [chatPath moveToPoint: CGPointMake(39.2, 52)];
    [chatPath addLineToPoint: CGPointMake(39.99, 52)];
    [chatPath addCurveToPoint: CGPointMake(64, 27.98) controlPoint1: CGPointMake(53.29, 52) controlPoint2: CGPointMake(64, 41.25)];
    [chatPath addLineToPoint: CGPointMake(64, 24.02)];
    [chatPath addCurveToPoint: CGPointMake(39.99, 0) controlPoint1: CGPointMake(64, 10.77) controlPoint2: CGPointMake(53.25, 0)];
    [chatPath addLineToPoint: CGPointMake(24.01, 0)];
    [chatPath addCurveToPoint: CGPointMake(0, 24.02) controlPoint1: CGPointMake(10.71, 0) controlPoint2: CGPointMake(0, 10.75)];
    [chatPath addLineToPoint: CGPointMake(0, 27.98)];
    [chatPath addCurveToPoint: CGPointMake(24.01, 52) controlPoint1: CGPointMake(0, 41.23) controlPoint2: CGPointMake(10.75, 52)];
    [chatPath addLineToPoint: CGPointMake(24.8, 52)];
    [chatPath addLineToPoint: CGPointMake(32, 64)];
    [chatPath addLineToPoint: CGPointMake(39.2, 52)];
    [chatPath addLineToPoint: CGPointMake(39.2, 52)];
    [chatPath closePath];
    chatPath.usesEvenOddFillRule = YES;

    [color setFill];
    [chatPath fill];
}

+ (void)drawIcon_0x158_32ptWithColor: (UIColor*)color
{

    //// Speaker Drawing
    UIBezierPath* speakerPath = [UIBezierPath bezierPath];
    [speakerPath moveToPoint: CGPointMake(2.06, 48.08)];
    [speakerPath addCurveToPoint: CGPointMake(0, 45.74) controlPoint1: CGPointMake(0.77, 48.08) controlPoint2: CGPointMake(0, 46.89)];
    [speakerPath addLineToPoint: CGPointMake(0, 18.55)];
    [speakerPath addCurveToPoint: CGPointMake(2.06, 16.06) controlPoint1: CGPointMake(0, 17.37) controlPoint2: CGPointMake(0.85, 16.06)];
    [speakerPath addLineToPoint: CGPointMake(20.11, 16.06)];
    [speakerPath addLineToPoint: CGPointMake(40, 0)];
    [speakerPath addLineToPoint: CGPointMake(40, 64)];
    [speakerPath addLineToPoint: CGPointMake(20.11, 48.08)];
    [speakerPath addLineToPoint: CGPointMake(2.06, 48.08)];
    [speakerPath addLineToPoint: CGPointMake(2.06, 48.08)];
    [speakerPath closePath];
    [speakerPath moveToPoint: CGPointMake(48, 40)];
    [speakerPath addLineToPoint: CGPointMake(48, 48)];
    [speakerPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(56.84, 48) controlPoint2: CGPointMake(64, 40.84)];
    [speakerPath addCurveToPoint: CGPointMake(48, 16) controlPoint1: CGPointMake(64, 23.16) controlPoint2: CGPointMake(56.84, 16)];
    [speakerPath addLineToPoint: CGPointMake(48, 24)];
    [speakerPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(52.42, 24) controlPoint2: CGPointMake(56, 27.58)];
    [speakerPath addCurveToPoint: CGPointMake(48, 40) controlPoint1: CGPointMake(56, 36.42) controlPoint2: CGPointMake(52.42, 40)];
    [speakerPath closePath];
    speakerPath.miterLimit = 4;

    speakerPath.usesEvenOddFillRule = YES;

    [color setFill];
    [speakerPath fill];
}

+ (void)drawIcon_0x162_32ptWithColor: (UIColor*)color
{

    //// Silence Drawing
    UIBezierPath* silencePath = [UIBezierPath bezierPath];
    [silencePath moveToPoint: CGPointMake(8.81, 42.95)];
    [silencePath addLineToPoint: CGPointMake(15.73, 12.92)];
    [silencePath addLineToPoint: CGPointMake(15.85, 12.92)];
    [silencePath addCurveToPoint: CGPointMake(31.89, 0) controlPoint1: CGPointMake(16.85, 5.64) controlPoint2: CGPointMake(23.65, 0)];
    [silencePath addCurveToPoint: CGPointMake(47.93, 12.92) controlPoint1: CGPointMake(40.13, 0) controlPoint2: CGPointMake(46.94, 5.64)];
    [silencePath addLineToPoint: CGPointMake(48.06, 12.92)];
    [silencePath addLineToPoint: CGPointMake(48.68, 15.63)];
    [silencePath addLineToPoint: CGPointMake(55.86, 10.71)];
    [silencePath addLineToPoint: CGPointMake(59.18, 8.43)];
    [silencePath addLineToPoint: CGPointMake(63.78, 15.01)];
    [silencePath addLineToPoint: CGPointMake(60.46, 17.29)];
    [silencePath addLineToPoint: CGPointMake(7.92, 53.29)];
    [silencePath addLineToPoint: CGPointMake(4.6, 55.57)];
    [silencePath addLineToPoint: CGPointMake(0, 48.99)];
    [silencePath addLineToPoint: CGPointMake(3.32, 46.71)];
    [silencePath addLineToPoint: CGPointMake(8.81, 42.95)];
    [silencePath addLineToPoint: CGPointMake(8.81, 42.95)];
    [silencePath closePath];
    [silencePath moveToPoint: CGPointMake(27.32, 48)];
    [silencePath addLineToPoint: CGPointMake(56.14, 48)];
    [silencePath addLineToPoint: CGPointMake(52.21, 30.94)];
    [silencePath addLineToPoint: CGPointMake(27.32, 48)];
    [silencePath addLineToPoint: CGPointMake(27.32, 48)];
    [silencePath closePath];
    [silencePath moveToPoint: CGPointMake(39.97, 56)];
    [silencePath addCurveToPoint: CGPointMake(31.89, 64) controlPoint1: CGPointMake(39.97, 60.42) controlPoint2: CGPointMake(36.36, 64)];
    [silencePath addCurveToPoint: CGPointMake(23.81, 56) controlPoint1: CGPointMake(27.43, 64) controlPoint2: CGPointMake(23.81, 60.42)];
    [silencePath addLineToPoint: CGPointMake(39.97, 56)];
    [silencePath addLineToPoint: CGPointMake(39.97, 56)];
    [silencePath closePath];
    silencePath.miterLimit = 4;

    silencePath.usesEvenOddFillRule = YES;

    [color setFill];
    [silencePath fill];
}

+ (void)drawIcon_0x177_32ptWithColor: (UIColor*)color
{

    //// Edit Drawing
    UIBezierPath* editPath = [UIBezierPath bezierPath];
    [editPath moveToPoint: CGPointMake(58.22, 19.38)];
    [editPath addLineToPoint: CGPointMake(61.2, 16.4)];
    [editPath addCurveToPoint: CGPointMake(61.18, 2.83) controlPoint1: CGPointMake(64.94, 12.67) controlPoint2: CGPointMake(64.93, 6.59)];
    [editPath addCurveToPoint: CGPointMake(47.61, 2.81) controlPoint1: CGPointMake(57.4, -0.95) controlPoint2: CGPointMake(51.35, -0.93)];
    [editPath addLineToPoint: CGPointMake(44.62, 5.79)];
    [editPath addLineToPoint: CGPointMake(58.22, 19.38)];
    [editPath addLineToPoint: CGPointMake(58.22, 19.38)];
    [editPath addLineToPoint: CGPointMake(58.22, 19.38)];
    [editPath closePath];
    [editPath moveToPoint: CGPointMake(55.39, 22.21)];
    [editPath addLineToPoint: CGPointMake(16.99, 60.6)];
    [editPath addLineToPoint: CGPointMake(0, 64)];
    [editPath addLineToPoint: CGPointMake(3.4, 47.01)];
    [editPath addLineToPoint: CGPointMake(41.8, 8.62)];
    [editPath addLineToPoint: CGPointMake(55.39, 22.21)];
    [editPath addLineToPoint: CGPointMake(55.39, 22.21)];
    [editPath closePath];
    [editPath moveToPoint: CGPointMake(16, 54.4)];
    [editPath addLineToPoint: CGPointMake(8, 56)];
    [editPath addLineToPoint: CGPointMake(9.6, 48)];
    [editPath addLineToPoint: CGPointMake(16, 54.4)];
    [editPath addLineToPoint: CGPointMake(16, 54.4)];
    [editPath closePath];
    editPath.miterLimit = 4;

    editPath.usesEvenOddFillRule = YES;

    [color setFill];
    [editPath fill];
}

+ (void)drawIcon_0x193_32ptWithColor: (UIColor*)color
{

    //// Flash Drawing
    UIBezierPath* flashPath = [UIBezierPath bezierPath];
    [flashPath moveToPoint: CGPointMake(28, 36)];
    [flashPath addLineToPoint: CGPointMake(12, 36)];
    [flashPath addLineToPoint: CGPointMake(36, 0)];
    [flashPath addLineToPoint: CGPointMake(36, 28)];
    [flashPath addLineToPoint: CGPointMake(52, 28)];
    [flashPath addLineToPoint: CGPointMake(28, 64)];
    [flashPath addLineToPoint: CGPointMake(28, 36)];
    [flashPath closePath];
    flashPath.miterLimit = 4;

    flashPath.usesEvenOddFillRule = YES;

    [color setFill];
    [flashPath fill];
}

+ (void)drawIcon_0x194_32ptWithColor: (UIColor*)color
{

    //// Flash-off Drawing
    UIBezierPath* flashoffPath = [UIBezierPath bezierPath];
    [flashoffPath moveToPoint: CGPointMake(35.93, 24.37)];
    [flashoffPath addLineToPoint: CGPointMake(35.93, 0)];
    [flashoffPath addLineToPoint: CGPointMake(11.68, 36)];
    [flashoffPath addLineToPoint: CGPointMake(18.95, 36)];
    [flashoffPath addLineToPoint: CGPointMake(3.32, 46.71)];
    [flashoffPath addLineToPoint: CGPointMake(0, 48.99)];
    [flashoffPath addLineToPoint: CGPointMake(4.6, 55.57)];
    [flashoffPath addLineToPoint: CGPointMake(7.92, 53.29)];
    [flashoffPath addLineToPoint: CGPointMake(60.46, 17.29)];
    [flashoffPath addLineToPoint: CGPointMake(63.78, 15.01)];
    [flashoffPath addLineToPoint: CGPointMake(59.18, 8.43)];
    [flashoffPath addLineToPoint: CGPointMake(55.86, 10.71)];
    [flashoffPath addLineToPoint: CGPointMake(35.93, 24.37)];
    [flashoffPath addLineToPoint: CGPointMake(35.93, 24.37)];
    [flashoffPath closePath];
    [flashoffPath moveToPoint: CGPointMake(48.32, 33.61)];
    [flashoffPath addLineToPoint: CGPointMake(27.85, 64)];
    [flashoffPath addLineToPoint: CGPointMake(27.85, 47.63)];
    [flashoffPath addLineToPoint: CGPointMake(48.32, 33.61)];
    [flashoffPath addLineToPoint: CGPointMake(48.32, 33.61)];
    [flashoffPath closePath];
    flashoffPath.miterLimit = 4;

    flashoffPath.usesEvenOddFillRule = YES;

    [color setFill];
    [flashoffPath fill];
}

+ (void)drawIcon_0x195_32ptWithColor: (UIColor*)color
{

    //// Flash-auto Drawing
    UIBezierPath* flashautoPath = [UIBezierPath bezierPath];
    [flashautoPath moveToPoint: CGPointMake(28, 36)];
    [flashautoPath addLineToPoint: CGPointMake(12, 36)];
    [flashautoPath addLineToPoint: CGPointMake(36, 0)];
    [flashautoPath addLineToPoint: CGPointMake(36, 28)];
    [flashautoPath addLineToPoint: CGPointMake(52, 28)];
    [flashautoPath addLineToPoint: CGPointMake(28, 64)];
    [flashautoPath addLineToPoint: CGPointMake(28, 36)];
    [flashautoPath closePath];
    [flashautoPath moveToPoint: CGPointMake(52, 44)];
    [flashautoPath addLineToPoint: CGPointMake(64, 64)];
    [flashautoPath addLineToPoint: CGPointMake(40, 64)];
    [flashautoPath addLineToPoint: CGPointMake(52, 44)];
    [flashautoPath closePath];
    flashautoPath.miterLimit = 4;

    flashautoPath.usesEvenOddFillRule = YES;

    [color setFill];
    [flashautoPath fill];
}

+ (void)drawIcon_0x197_32ptWithColor: (UIColor*)color
{

    //// Download Drawing
    UIBezierPath* downloadPath = [UIBezierPath bezierPath];
    [downloadPath moveToPoint: CGPointMake(0, 56)];
    [downloadPath addLineToPoint: CGPointMake(64, 56)];
    [downloadPath addLineToPoint: CGPointMake(64, 64)];
    [downloadPath addLineToPoint: CGPointMake(0, 64)];
    [downloadPath addLineToPoint: CGPointMake(0, 56)];
    [downloadPath addLineToPoint: CGPointMake(0, 56)];
    [downloadPath addLineToPoint: CGPointMake(0, 56)];
    [downloadPath closePath];
    [downloadPath moveToPoint: CGPointMake(28, 0)];
    [downloadPath addLineToPoint: CGPointMake(36, 0)];
    [downloadPath addLineToPoint: CGPointMake(36, 28)];
    [downloadPath addLineToPoint: CGPointMake(52, 28)];
    [downloadPath addLineToPoint: CGPointMake(32, 44)];
    [downloadPath addLineToPoint: CGPointMake(12, 28)];
    [downloadPath addLineToPoint: CGPointMake(28, 28)];
    [downloadPath addLineToPoint: CGPointMake(28, 0)];
    [downloadPath closePath];
    downloadPath.miterLimit = 4;

    downloadPath.usesEvenOddFillRule = YES;

    [color setFill];
    [downloadPath fill];
}

+ (void)drawIcon_0x205_32ptWithColor: (UIColor*)color
{

    //// Path Drawing
    UIBezierPath* pathPath = [UIBezierPath bezierPath];
    [pathPath moveToPoint: CGPointMake(29, 62)];
    [pathPath addCurveToPoint: CGPointMake(27, 60) controlPoint1: CGPointMake(29, 60.9) controlPoint2: CGPointMake(28.1, 60)];
    [pathPath addLineToPoint: CGPointMake(4, 60)];
    [pathPath addLineToPoint: CGPointMake(4, 4)];
    [pathPath addLineToPoint: CGPointMake(27, 4)];
    [pathPath addCurveToPoint: CGPointMake(29, 2) controlPoint1: CGPointMake(28.1, 4) controlPoint2: CGPointMake(29, 3.1)];
    [pathPath addCurveToPoint: CGPointMake(27, 0) controlPoint1: CGPointMake(29, 0.89) controlPoint2: CGPointMake(28.1, 0)];
    [pathPath addLineToPoint: CGPointMake(2, 0)];
    [pathPath addCurveToPoint: CGPointMake(0, 2) controlPoint1: CGPointMake(0.9, 0) controlPoint2: CGPointMake(0, 0.89)];
    [pathPath addLineToPoint: CGPointMake(0, 62)];
    [pathPath addCurveToPoint: CGPointMake(2, 64) controlPoint1: CGPointMake(0, 63.1) controlPoint2: CGPointMake(0.9, 64)];
    [pathPath addLineToPoint: CGPointMake(27, 64)];
    [pathPath addCurveToPoint: CGPointMake(29, 62) controlPoint1: CGPointMake(28.1, 64) controlPoint2: CGPointMake(29, 63.1)];
    [pathPath closePath];
    [pathPath moveToPoint: CGPointMake(45, 17)];
    [pathPath addCurveToPoint: CGPointMake(45.59, 18.41) controlPoint1: CGPointMake(45, 17.51) controlPoint2: CGPointMake(45.2, 18.02)];
    [pathPath addLineToPoint: CGPointMake(57.17, 30)];
    [pathPath addLineToPoint: CGPointMake(17, 30)];
    [pathPath addCurveToPoint: CGPointMake(15, 32) controlPoint1: CGPointMake(15.9, 30) controlPoint2: CGPointMake(15, 30.9)];
    [pathPath addCurveToPoint: CGPointMake(17, 34) controlPoint1: CGPointMake(15, 33.1) controlPoint2: CGPointMake(15.9, 34)];
    [pathPath addLineToPoint: CGPointMake(57.17, 34)];
    [pathPath addLineToPoint: CGPointMake(45.59, 45.59)];
    [pathPath addCurveToPoint: CGPointMake(45, 47) controlPoint1: CGPointMake(45.2, 45.98) controlPoint2: CGPointMake(45, 46.49)];
    [pathPath addCurveToPoint: CGPointMake(45.59, 48.41) controlPoint1: CGPointMake(45, 47.51) controlPoint2: CGPointMake(45.2, 48.02)];
    [pathPath addCurveToPoint: CGPointMake(48.41, 48.41) controlPoint1: CGPointMake(46.37, 49.2) controlPoint2: CGPointMake(47.63, 49.2)];
    [pathPath addLineToPoint: CGPointMake(63.41, 33.41)];
    [pathPath addCurveToPoint: CGPointMake(63.42, 33.41) controlPoint1: CGPointMake(63.42, 33.41) controlPoint2: CGPointMake(63.42, 33.41)];
    [pathPath addCurveToPoint: CGPointMake(63.66, 33.11) controlPoint1: CGPointMake(63.51, 33.32) controlPoint2: CGPointMake(63.59, 33.22)];
    [pathPath addCurveToPoint: CGPointMake(63.75, 32.96) controlPoint1: CGPointMake(63.7, 33.06) controlPoint2: CGPointMake(63.72, 33.01)];
    [pathPath addCurveToPoint: CGPointMake(63.85, 32.76) controlPoint1: CGPointMake(63.78, 32.89) controlPoint2: CGPointMake(63.82, 32.83)];
    [pathPath addCurveToPoint: CGPointMake(63.91, 32.57) controlPoint1: CGPointMake(63.87, 32.7) controlPoint2: CGPointMake(63.89, 32.63)];
    [pathPath addCurveToPoint: CGPointMake(63.96, 32.39) controlPoint1: CGPointMake(63.93, 32.51) controlPoint2: CGPointMake(63.95, 32.45)];
    [pathPath addCurveToPoint: CGPointMake(64, 32.02) controlPoint1: CGPointMake(63.98, 32.27) controlPoint2: CGPointMake(64, 32.15)];
    [pathPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(64, 32.02) controlPoint2: CGPointMake(64, 32.01)];
    [pathPath addCurveToPoint: CGPointMake(64, 31.98) controlPoint1: CGPointMake(64, 31.99) controlPoint2: CGPointMake(64, 31.98)];
    [pathPath addCurveToPoint: CGPointMake(63.96, 31.61) controlPoint1: CGPointMake(64, 31.85) controlPoint2: CGPointMake(63.98, 31.73)];
    [pathPath addCurveToPoint: CGPointMake(63.91, 31.43) controlPoint1: CGPointMake(63.95, 31.55) controlPoint2: CGPointMake(63.93, 31.49)];
    [pathPath addCurveToPoint: CGPointMake(63.85, 31.24) controlPoint1: CGPointMake(63.89, 31.37) controlPoint2: CGPointMake(63.87, 31.3)];
    [pathPath addCurveToPoint: CGPointMake(63.75, 31.04) controlPoint1: CGPointMake(63.82, 31.17) controlPoint2: CGPointMake(63.78, 31.11)];
    [pathPath addCurveToPoint: CGPointMake(63.66, 30.89) controlPoint1: CGPointMake(63.72, 30.99) controlPoint2: CGPointMake(63.7, 30.94)];
    [pathPath addCurveToPoint: CGPointMake(63.42, 30.6) controlPoint1: CGPointMake(63.59, 30.78) controlPoint2: CGPointMake(63.51, 30.69)];
    [pathPath addCurveToPoint: CGPointMake(63.41, 30.59) controlPoint1: CGPointMake(63.42, 30.59) controlPoint2: CGPointMake(63.42, 30.59)];
    [pathPath addLineToPoint: CGPointMake(48.41, 15.59)];
    [pathPath addCurveToPoint: CGPointMake(45.59, 15.59) controlPoint1: CGPointMake(47.63, 14.8) controlPoint2: CGPointMake(46.37, 14.8)];
    [pathPath addCurveToPoint: CGPointMake(45, 17) controlPoint1: CGPointMake(45.2, 15.98) controlPoint2: CGPointMake(45, 16.49)];
    [pathPath closePath];
    pathPath.miterLimit = 4;

    pathPath.usesEvenOddFillRule = YES;

    [color setFill];
    [pathPath fill];
}

+ (void)drawIcon_0x212_32ptWithColor: (UIColor*)color
{

    //// Archive Drawing
    UIBezierPath* archivePath = [UIBezierPath bezierPath];
    [archivePath moveToPoint: CGPointMake(0, 20)];
    [archivePath addLineToPoint: CGPointMake(0, 36)];
    [archivePath addLineToPoint: CGPointMake(64, 36)];
    [archivePath addLineToPoint: CGPointMake(64, 20)];
    [archivePath addLineToPoint: CGPointMake(40, 20)];
    [archivePath addLineToPoint: CGPointMake(40, 28)];
    [archivePath addLineToPoint: CGPointMake(24, 28)];
    [archivePath addLineToPoint: CGPointMake(24, 20)];
    [archivePath addLineToPoint: CGPointMake(0, 20)];
    [archivePath closePath];
    [archivePath moveToPoint: CGPointMake(0, 44)];
    [archivePath addLineToPoint: CGPointMake(0, 60)];
    [archivePath addLineToPoint: CGPointMake(64, 60)];
    [archivePath addLineToPoint: CGPointMake(64, 44)];
    [archivePath addLineToPoint: CGPointMake(40, 44)];
    [archivePath addLineToPoint: CGPointMake(40, 52)];
    [archivePath addLineToPoint: CGPointMake(24, 52)];
    [archivePath addLineToPoint: CGPointMake(24, 44)];
    [archivePath addLineToPoint: CGPointMake(0, 44)];
    [archivePath closePath];
    [archivePath moveToPoint: CGPointMake(64, 4)];
    [archivePath addLineToPoint: CGPointMake(64, 12)];
    [archivePath addLineToPoint: CGPointMake(0, 12)];
    [archivePath addLineToPoint: CGPointMake(0, 4)];
    [archivePath addLineToPoint: CGPointMake(64, 4)];
    [archivePath closePath];
    archivePath.miterLimit = 4;

    archivePath.usesEvenOddFillRule = YES;

    [color setFill];
    [archivePath fill];
}

+ (void)drawIcon_0x198_32ptWithColor: (UIColor*)color
{

    //// Share Drawing
    UIBezierPath* sharePath = [UIBezierPath bezierPath];
    [sharePath moveToPoint: CGPointMake(0, 56)];
    [sharePath addLineToPoint: CGPointMake(64, 56)];
    [sharePath addLineToPoint: CGPointMake(64, 64)];
    [sharePath addLineToPoint: CGPointMake(0, 64)];
    [sharePath addLineToPoint: CGPointMake(0, 56)];
    [sharePath addLineToPoint: CGPointMake(0, 56)];
    [sharePath addLineToPoint: CGPointMake(0, 56)];
    [sharePath addLineToPoint: CGPointMake(0, 56)];
    [sharePath closePath];
    [sharePath moveToPoint: CGPointMake(28, 44)];
    [sharePath addLineToPoint: CGPointMake(36, 44)];
    [sharePath addLineToPoint: CGPointMake(36, 16)];
    [sharePath addLineToPoint: CGPointMake(52, 16)];
    [sharePath addLineToPoint: CGPointMake(32, 0)];
    [sharePath addLineToPoint: CGPointMake(12, 16)];
    [sharePath addLineToPoint: CGPointMake(28, 16)];
    [sharePath addLineToPoint: CGPointMake(28, 44)];
    [sharePath closePath];
    sharePath.miterLimit = 4;

    sharePath.usesEvenOddFillRule = YES;

    [color setFill];
    [sharePath fill];
}

+ (void)drawIcon_0x160_32ptWithColor: (UIColor*)color
{

    //// Mute Drawing
    UIBezierPath* mutePath = [UIBezierPath bezierPath];
    [mutePath moveToPoint: CGPointMake(12.82, 57.93)];
    [mutePath addCurveToPoint: CGPointMake(31.89, 64) controlPoint1: CGPointMake(18.16, 61.74) controlPoint2: CGPointMake(24.75, 64)];
    [mutePath addCurveToPoint: CGPointMake(55.98, 53.5) controlPoint1: CGPointMake(41.47, 64) controlPoint2: CGPointMake(50.07, 59.94)];
    [mutePath addLineToPoint: CGPointMake(50.26, 47.84)];
    [mutePath addLineToPoint: CGPointMake(50.26, 47.84)];
    [mutePath addCurveToPoint: CGPointMake(31.89, 56) controlPoint1: CGPointMake(45.82, 52.83) controlPoint2: CGPointMake(39.24, 56)];
    [mutePath addCurveToPoint: CGPointMake(20.03, 53) controlPoint1: CGPointMake(27.58, 56) controlPoint2: CGPointMake(23.53, 54.91)];
    [mutePath addLineToPoint: CGPointMake(12.82, 57.93)];
    [mutePath addLineToPoint: CGPointMake(12.82, 57.93)];
    [mutePath addLineToPoint: CGPointMake(12.82, 57.93)];
    [mutePath closePath];
    [mutePath moveToPoint: CGPointMake(47.98, 33.84)];
    [mutePath addCurveToPoint: CGPointMake(31.89, 48) controlPoint1: CGPointMake(47.16, 41.76) controlPoint2: CGPointMake(40.29, 48)];
    [mutePath addCurveToPoint: CGPointMake(27.99, 47.54) controlPoint1: CGPointMake(30.55, 48) controlPoint2: CGPointMake(29.24, 47.84)];
    [mutePath addLineToPoint: CGPointMake(47.98, 33.84)];
    [mutePath addLineToPoint: CGPointMake(47.98, 33.84)];
    [mutePath addLineToPoint: CGPointMake(47.98, 33.84)];
    [mutePath closePath];
    [mutePath moveToPoint: CGPointMake(48.06, 16.06)];
    [mutePath addLineToPoint: CGPointMake(48.06, 15.74)];
    [mutePath addCurveToPoint: CGPointMake(31.89, 0) controlPoint1: CGPointMake(48.06, 7.08) controlPoint2: CGPointMake(40.84, 0)];
    [mutePath addCurveToPoint: CGPointMake(15.73, 15.74) controlPoint1: CGPointMake(22.95, 0) controlPoint2: CGPointMake(15.73, 7.08)];
    [mutePath addLineToPoint: CGPointMake(15.73, 32.27)];
    [mutePath addCurveToPoint: CGPointMake(16.67, 37.57) controlPoint1: CGPointMake(15.73, 34.12) controlPoint2: CGPointMake(16.06, 35.91)];
    [mutePath addLineToPoint: CGPointMake(3.32, 46.71)];
    [mutePath addLineToPoint: CGPointMake(0, 48.99)];
    [mutePath addLineToPoint: CGPointMake(4.6, 55.57)];
    [mutePath addLineToPoint: CGPointMake(7.92, 53.29)];
    [mutePath addLineToPoint: CGPointMake(60.46, 17.29)];
    [mutePath addLineToPoint: CGPointMake(63.78, 15.01)];
    [mutePath addLineToPoint: CGPointMake(59.18, 8.43)];
    [mutePath addLineToPoint: CGPointMake(55.86, 10.71)];
    [mutePath addLineToPoint: CGPointMake(48.06, 16.06)];
    [mutePath addLineToPoint: CGPointMake(48.06, 16.06)];
    [mutePath addLineToPoint: CGPointMake(48.06, 16.06)];
    [mutePath closePath];
    mutePath.miterLimit = 4;

    mutePath.usesEvenOddFillRule = YES;

    [color setFill];
    [mutePath fill];
}

+ (void)drawIcon_0x101_32ptWithColor: (UIColor*)color
{

    //// Remove Drawing
    UIBezierPath* removePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 28, 64, 8)];
    [color setFill];
    [removePath fill];
}

+ (void)drawIcon_0x215_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(48, 8.15)];
    [bezierPath addLineToPoint: CGPointMake(40, 8.15)];
    [bezierPath addLineToPoint: CGPointMake(40, 16.29)];
    [bezierPath addLineToPoint: CGPointMake(48, 16.29)];
    [bezierPath addLineToPoint: CGPointMake(48, 24.44)];
    [bezierPath addLineToPoint: CGPointMake(56, 24.44)];
    [bezierPath addLineToPoint: CGPointMake(56, 16.29)];
    [bezierPath addLineToPoint: CGPointMake(64, 16.29)];
    [bezierPath addLineToPoint: CGPointMake(64, 8.15)];
    [bezierPath addLineToPoint: CGPointMake(56, 8.15)];
    [bezierPath addLineToPoint: CGPointMake(56, 0)];
    [bezierPath addLineToPoint: CGPointMake(48, 0)];
    [bezierPath addLineToPoint: CGPointMake(48, 8.15)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(37.7, 43.05)];
    [bezierPath addCurveToPoint: CGPointMake(48, 53.53) controlPoint1: CGPointMake(43.39, 43.05) controlPoint2: CGPointMake(48, 47.76)];
    [bezierPath addLineToPoint: CGPointMake(48, 57.96)];
    [bezierPath addCurveToPoint: CGPointMake(24, 64) controlPoint1: CGPointMake(40.84, 61.82) controlPoint2: CGPointMake(32.67, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 57.96) controlPoint1: CGPointMake(15.33, 64) controlPoint2: CGPointMake(7.16, 61.82)];
    [bezierPath addLineToPoint: CGPointMake(0, 53.53)];
    [bezierPath addCurveToPoint: CGPointMake(10.3, 43.05) controlPoint1: CGPointMake(0, 47.74) controlPoint2: CGPointMake(4.6, 43.05)];
    [bezierPath addLineToPoint: CGPointMake(11.63, 43.05)];
    [bezierPath addCurveToPoint: CGPointMake(24, 46.55) controlPoint1: CGPointMake(15.24, 45.27) controlPoint2: CGPointMake(19.48, 46.55)];
    [bezierPath addCurveToPoint: CGPointMake(36.37, 43.05) controlPoint1: CGPointMake(28.52, 46.55) controlPoint2: CGPointMake(32.76, 45.27)];
    [bezierPath addLineToPoint: CGPointMake(37.7, 43.05)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(24, 36.08)];
    [bezierPath addCurveToPoint: CGPointMake(37.72, 22.11) controlPoint1: CGPointMake(31.58, 36.08) controlPoint2: CGPointMake(37.72, 29.83)];
    [bezierPath addCurveToPoint: CGPointMake(24, 8.15) controlPoint1: CGPointMake(37.72, 14.4) controlPoint2: CGPointMake(31.58, 8.15)];
    [bezierPath addCurveToPoint: CGPointMake(10.29, 22.11) controlPoint1: CGPointMake(16.43, 8.15) controlPoint2: CGPointMake(10.29, 14.4)];
    [bezierPath addCurveToPoint: CGPointMake(24, 36.08) controlPoint1: CGPointMake(10.29, 29.83) controlPoint2: CGPointMake(16.43, 36.08)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;

    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x216_32ptWithColor: (UIColor*)color
{

    //// Add Drawing
    UIBezierPath* addPath = [UIBezierPath bezierPath];
    [addPath moveToPoint: CGPointMake(32, 64)];
    [addPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [addPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [addPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [addPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [addPath closePath];
    [addPath moveToPoint: CGPointMake(12, 28)];
    [addPath addLineToPoint: CGPointMake(12, 36)];
    [addPath addLineToPoint: CGPointMake(28, 36)];
    [addPath addLineToPoint: CGPointMake(28, 52)];
    [addPath addLineToPoint: CGPointMake(36, 52)];
    [addPath addLineToPoint: CGPointMake(36, 36)];
    [addPath addLineToPoint: CGPointMake(52, 36)];
    [addPath addLineToPoint: CGPointMake(52, 28)];
    [addPath addLineToPoint: CGPointMake(36, 28)];
    [addPath addLineToPoint: CGPointMake(36, 12)];
    [addPath addLineToPoint: CGPointMake(28, 12)];
    [addPath addLineToPoint: CGPointMake(28, 28)];
    [addPath addLineToPoint: CGPointMake(12, 28)];
    [addPath closePath];
    addPath.miterLimit = 4;

    addPath.usesEvenOddFillRule = YES;

    [color setFill];
    [addPath fill];
}

+ (void)drawIcon_0x172_32ptWithColor: (UIColor*)color
{

    //// Email Drawing
    UIBezierPath* emailPath = [UIBezierPath bezierPath];
    [emailPath moveToPoint: CGPointMake(63.98, 56)];
    [emailPath addLineToPoint: CGPointMake(0.04, 56)];
    [emailPath addLineToPoint: CGPointMake(0.04, 16.27)];
    [emailPath addLineToPoint: CGPointMake(32.01, 43.7)];
    [emailPath addLineToPoint: CGPointMake(63.98, 16.27)];
    [emailPath addLineToPoint: CGPointMake(63.98, 56)];
    [emailPath closePath];
    [emailPath moveToPoint: CGPointMake(32.05, 35.43)];
    [emailPath addLineToPoint: CGPointMake(64.02, 8)];
    [emailPath addLineToPoint: CGPointMake(0, 8)];
    [emailPath addLineToPoint: CGPointMake(32.05, 35.43)];
    [emailPath addLineToPoint: CGPointMake(32.05, 35.43)];
    [emailPath closePath];
    emailPath.miterLimit = 4;

    emailPath.usesEvenOddFillRule = YES;

    [color setFill];
    [emailPath fill];
}

+ (void)drawIcon_0x217_32ptWithColor: (UIColor*)color
{

    //// Added Drawing
    UIBezierPath* addedPath = [UIBezierPath bezierPath];
    [addedPath moveToPoint: CGPointMake(0, 32)];
    [addedPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [addedPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [addedPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [addedPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [addedPath closePath];
    [addedPath moveToPoint: CGPointMake(26.63, 51.43)];
    [addedPath addLineToPoint: CGPointMake(54.88, 23.46)];
    [addedPath addLineToPoint: CGPointMake(49.22, 17.8)];
    [addedPath addLineToPoint: CGPointMake(26.63, 40.12)];
    [addedPath addLineToPoint: CGPointMake(14.58, 28.31)];
    [addedPath addLineToPoint: CGPointMake(8.92, 33.97)];
    [addedPath addLineToPoint: CGPointMake(26.63, 51.43)];
    [addedPath closePath];
    addedPath.miterLimit = 4;

    addedPath.usesEvenOddFillRule = YES;

    [color setFill];
    [addedPath fill];
}

+ (void)drawIcon_0x117_32ptWithColor: (UIColor*)color
{

    //// Resend Drawing
    UIBezierPath* resendPath = [UIBezierPath bezierPath];
    [resendPath moveToPoint: CGPointMake(54.63, 9.37)];
    [resendPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(48.84, 3.58) controlPoint2: CGPointMake(40.84, 0)];
    [resendPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 0) controlPoint2: CGPointMake(0, 14.33)];
    [resendPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(0, 49.67) controlPoint2: CGPointMake(14.33, 64)];
    [resendPath addCurveToPoint: CGPointMake(62.99, 40) controlPoint1: CGPointMake(46.91, 64) controlPoint2: CGPointMake(59.44, 53.8)];
    [resendPath addLineToPoint: CGPointMake(62.99, 40)];
    [resendPath addLineToPoint: CGPointMake(54.63, 40)];
    [resendPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(51.34, 49.32) controlPoint2: CGPointMake(42.45, 56)];
    [resendPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 56) controlPoint2: CGPointMake(8, 45.25)];
    [resendPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(8, 18.75) controlPoint2: CGPointMake(18.75, 8)];
    [resendPath addCurveToPoint: CGPointMake(48.97, 15.03) controlPoint1: CGPointMake(38.63, 8) controlPoint2: CGPointMake(44.63, 10.69)];
    [resendPath addLineToPoint: CGPointMake(36, 28)];
    [resendPath addLineToPoint: CGPointMake(64, 28)];
    [resendPath addLineToPoint: CGPointMake(64, 0)];
    [resendPath addLineToPoint: CGPointMake(54.63, 9.37)];
    [resendPath addLineToPoint: CGPointMake(54.63, 9.37)];
    [resendPath closePath];
    resendPath.miterLimit = 4;

    resendPath.usesEvenOddFillRule = YES;

    [color setFill];
    [resendPath fill];
}

+ (void)drawIcon_0x179_32ptWithColor: (UIColor*)color
{

    //// Sketch Drawing
    UIBezierPath* sketchPath = [UIBezierPath bezierPath];
    [sketchPath moveToPoint: CGPointMake(54.83, 39.53)];
    [sketchPath addCurveToPoint: CGPointMake(32.28, 43.38) controlPoint1: CGPointMake(50.56, 38.77) controlPoint2: CGPointMake(46.28, 39.53)];
    [sketchPath addCurveToPoint: CGPointMake(29.94, 44.15) controlPoint1: CGPointMake(31.5, 43.77) controlPoint2: CGPointMake(30.72, 43.77)];
    [sketchPath addCurveToPoint: CGPointMake(12.06, 47.23) controlPoint1: CGPointMake(21, 46.46) controlPoint2: CGPointMake(15.94, 47.23)];
    [sketchPath addCurveToPoint: CGPointMake(8.56, 44.92) controlPoint1: CGPointMake(8.56, 47.23) controlPoint2: CGPointMake(8.17, 46.84)];
    [sketchPath addCurveToPoint: CGPointMake(8.94, 44.92) controlPoint1: CGPointMake(8.56, 45.31) controlPoint2: CGPointMake(8.56, 45.31)];
    [sketchPath addCurveToPoint: CGPointMake(13.61, 43.38) controlPoint1: CGPointMake(10.11, 44.54) controlPoint2: CGPointMake(11.67, 43.77)];
    [sketchPath addCurveToPoint: CGPointMake(30.33, 39.92) controlPoint1: CGPointMake(17.5, 42.23) controlPoint2: CGPointMake(21.39, 41.46)];
    [sketchPath addCurveToPoint: CGPointMake(31.89, 39.53) controlPoint1: CGPointMake(31.11, 39.92) controlPoint2: CGPointMake(31.11, 39.92)];
    [sketchPath addCurveToPoint: CGPointMake(50.94, 35.69) controlPoint1: CGPointMake(42, 38) controlPoint2: CGPointMake(46.67, 36.84)];
    [sketchPath addCurveToPoint: CGPointMake(61.83, 25.69) controlPoint1: CGPointMake(58.33, 33.38) controlPoint2: CGPointMake(62.22, 30.69)];
    [sketchPath addCurveToPoint: CGPointMake(49, 19.92) controlPoint1: CGPointMake(61.44, 20.69) controlPoint2: CGPointMake(57.17, 19.92)];
    [sketchPath addCurveToPoint: CGPointMake(30.33, 21.46) controlPoint1: CGPointMake(44.72, 19.92) controlPoint2: CGPointMake(39.67, 20.3)];
    [sketchPath addCurveToPoint: CGPointMake(29.17, 21.46) controlPoint1: CGPointMake(29.56, 21.46) controlPoint2: CGPointMake(29.56, 21.46)];
    [sketchPath addCurveToPoint: CGPointMake(15.17, 22.99) controlPoint1: CGPointMake(22.17, 22.61) controlPoint2: CGPointMake(18.28, 22.99)];
    [sketchPath addCurveToPoint: CGPointMake(30.33, 19.53) controlPoint1: CGPointMake(18.67, 22.22) controlPoint2: CGPointMake(23.33, 21.07)];
    [sketchPath addCurveToPoint: CGPointMake(34.61, 18.76) controlPoint1: CGPointMake(31.11, 19.53) controlPoint2: CGPointMake(32.28, 19.15)];
    [sketchPath addCurveToPoint: CGPointMake(38.89, 17.99) controlPoint1: CGPointMake(36.17, 18.38) controlPoint2: CGPointMake(37.72, 18.38)];
    [sketchPath addCurveToPoint: CGPointMake(59.11, 7.22) controlPoint1: CGPointMake(55.61, 14.53) controlPoint2: CGPointMake(60.28, 12.99)];
    [sketchPath addCurveToPoint: CGPointMake(34.61, 1.07) controlPoint1: CGPointMake(57.94, 1.84) controlPoint2: CGPointMake(49.39, 0.68)];
    [sketchPath addCurveToPoint: CGPointMake(3.5, 6.45) controlPoint1: CGPointMake(22.17, 1.84) controlPoint2: CGPointMake(10.11, 3.76)];
    [sketchPath addCurveToPoint: CGPointMake(1.56, 11.84) controlPoint1: CGPointMake(1.56, 7.61) controlPoint2: CGPointMake(0.78, 9.92)];
    [sketchPath addCurveToPoint: CGPointMake(7, 13.76) controlPoint1: CGPointMake(2.33, 13.76) controlPoint2: CGPointMake(4.67, 14.53)];
    [sketchPath addCurveToPoint: CGPointMake(35, 9.15) controlPoint1: CGPointMake(12.44, 11.45) controlPoint2: CGPointMake(23.33, 9.53)];
    [sketchPath addCurveToPoint: CGPointMake(43.94, 9.15) controlPoint1: CGPointMake(38.11, 9.15) controlPoint2: CGPointMake(41.22, 9.15)];
    [sketchPath addCurveToPoint: CGPointMake(37.33, 10.68) controlPoint1: CGPointMake(42, 9.53) controlPoint2: CGPointMake(40.06, 9.92)];
    [sketchPath addCurveToPoint: CGPointMake(33.06, 11.07) controlPoint1: CGPointMake(36.17, 10.68) controlPoint2: CGPointMake(34.61, 10.68)];
    [sketchPath addCurveToPoint: CGPointMake(28.78, 11.84) controlPoint1: CGPointMake(30.72, 11.45) controlPoint2: CGPointMake(29.94, 11.84)];
    [sketchPath addCurveToPoint: CGPointMake(0, 25.3) controlPoint1: CGPointMake(6.61, 16.45) controlPoint2: CGPointMake(0, 18.38)];
    [sketchPath addCurveToPoint: CGPointMake(12.06, 31.07) controlPoint1: CGPointMake(0, 30.69) controlPoint2: CGPointMake(3.89, 31.46)];
    [sketchPath addCurveToPoint: CGPointMake(30.33, 29.15) controlPoint1: CGPointMake(16.33, 31.07) controlPoint2: CGPointMake(19.83, 30.69)];
    [sketchPath addCurveToPoint: CGPointMake(31.5, 29.15) controlPoint1: CGPointMake(31.11, 29.15) controlPoint2: CGPointMake(31.11, 29.15)];
    [sketchPath addCurveToPoint: CGPointMake(49.39, 27.61) controlPoint1: CGPointMake(40.44, 27.99) controlPoint2: CGPointMake(45.5, 27.61)];
    [sketchPath addCurveToPoint: CGPointMake(50.94, 27.61) controlPoint1: CGPointMake(49.78, 27.61) controlPoint2: CGPointMake(50.56, 27.61)];
    [sketchPath addCurveToPoint: CGPointMake(48.61, 28.38) controlPoint1: CGPointMake(50.17, 27.99) controlPoint2: CGPointMake(49.78, 27.99)];
    [sketchPath addCurveToPoint: CGPointMake(30.33, 32.23) controlPoint1: CGPointMake(44.72, 29.53) controlPoint2: CGPointMake(40.06, 30.3)];
    [sketchPath addCurveToPoint: CGPointMake(28.78, 32.61) controlPoint1: CGPointMake(29.56, 32.23) controlPoint2: CGPointMake(29.56, 32.23)];
    [sketchPath addCurveToPoint: CGPointMake(0.78, 44.15) controlPoint1: CGPointMake(7, 35.69) controlPoint2: CGPointMake(1.56, 37.23)];
    [sketchPath addCurveToPoint: CGPointMake(12.06, 55.31) controlPoint1: CGPointMake(-0.39, 51.46) controlPoint2: CGPointMake(4.67, 55.31)];
    [sketchPath addCurveToPoint: CGPointMake(31.89, 51.84) controlPoint1: CGPointMake(16.72, 55.31) controlPoint2: CGPointMake(22.56, 54.15)];
    [sketchPath addCurveToPoint: CGPointMake(34.22, 51.08) controlPoint1: CGPointMake(32.67, 51.84) controlPoint2: CGPointMake(33.06, 51.46)];
    [sketchPath addCurveToPoint: CGPointMake(50.17, 47.23) controlPoint1: CGPointMake(42.78, 48.77) controlPoint2: CGPointMake(47.44, 47.61)];
    [sketchPath addCurveToPoint: CGPointMake(49.39, 47.61) controlPoint1: CGPointMake(49.78, 47.23) controlPoint2: CGPointMake(49.78, 47.61)];
    [sketchPath addCurveToPoint: CGPointMake(27.61, 54.92) controlPoint1: CGPointMake(43.17, 51.08) controlPoint2: CGPointMake(33.44, 54.15)];
    [sketchPath addCurveToPoint: CGPointMake(24.11, 59.54) controlPoint1: CGPointMake(25.28, 55.31) controlPoint2: CGPointMake(24.11, 57.23)];
    [sketchPath addCurveToPoint: CGPointMake(28.78, 63) controlPoint1: CGPointMake(24.5, 61.85) controlPoint2: CGPointMake(26.44, 63)];
    [sketchPath addCurveToPoint: CGPointMake(52.89, 54.92) controlPoint1: CGPointMake(35.39, 61.85) controlPoint2: CGPointMake(45.89, 58.38)];
    [sketchPath addCurveToPoint: CGPointMake(61.06, 48.38) controlPoint1: CGPointMake(57.17, 52.61) controlPoint2: CGPointMake(59.89, 50.69)];
    [sketchPath addCurveToPoint: CGPointMake(54.83, 39.53) controlPoint1: CGPointMake(63.78, 43.38) controlPoint2: CGPointMake(60.28, 40.3)];
    [sketchPath closePath];
    sketchPath.miterLimit = 4;

    [color setFill];
    [sketchPath fill];
}

+ (void)drawIcon_0x219_32ptWithColor: (UIColor*)color
{

    //// Gif Drawing
    UIBezierPath* gifPath = [UIBezierPath bezierPath];
    [gifPath moveToPoint: CGPointMake(0, 19.56)];
    [gifPath addCurveToPoint: CGPointMake(1.02, 14.51) controlPoint1: CGPointMake(0, 17.65) controlPoint2: CGPointMake(0.34, 15.97)];
    [gifPath addCurveToPoint: CGPointMake(3.69, 10.89) controlPoint1: CGPointMake(1.69, 13.05) controlPoint2: CGPointMake(2.59, 11.84)];
    [gifPath addCurveToPoint: CGPointMake(7.42, 8.73) controlPoint1: CGPointMake(4.8, 9.94) controlPoint2: CGPointMake(6.04, 9.22)];
    [gifPath addCurveToPoint: CGPointMake(11.59, 8) controlPoint1: CGPointMake(8.8, 8.24) controlPoint2: CGPointMake(10.19, 8)];
    [gifPath addCurveToPoint: CGPointMake(15.76, 8.73) controlPoint1: CGPointMake(12.99, 8) controlPoint2: CGPointMake(14.38, 8.24)];
    [gifPath addCurveToPoint: CGPointMake(19.48, 10.89) controlPoint1: CGPointMake(17.13, 9.22) controlPoint2: CGPointMake(18.38, 9.94)];
    [gifPath addCurveToPoint: CGPointMake(22.16, 14.51) controlPoint1: CGPointMake(20.59, 11.84) controlPoint2: CGPointMake(21.48, 13.05)];
    [gifPath addCurveToPoint: CGPointMake(23.18, 19.56) controlPoint1: CGPointMake(22.84, 15.97) controlPoint2: CGPointMake(23.18, 17.65)];
    [gifPath addLineToPoint: CGPointMake(23.18, 21.95)];
    [gifPath addLineToPoint: CGPointMake(16.26, 21.95)];
    [gifPath addLineToPoint: CGPointMake(16.26, 19.56)];
    [gifPath addCurveToPoint: CGPointMake(14.87, 15.94) controlPoint1: CGPointMake(16.26, 17.92) controlPoint2: CGPointMake(15.8, 16.71)];
    [gifPath addCurveToPoint: CGPointMake(11.59, 14.78) controlPoint1: CGPointMake(13.95, 15.16) controlPoint2: CGPointMake(12.85, 14.78)];
    [gifPath addCurveToPoint: CGPointMake(8.3, 15.94) controlPoint1: CGPointMake(10.32, 14.78) controlPoint2: CGPointMake(9.23, 15.16)];
    [gifPath addCurveToPoint: CGPointMake(6.91, 19.56) controlPoint1: CGPointMake(7.38, 16.71) controlPoint2: CGPointMake(6.91, 17.92)];
    [gifPath addLineToPoint: CGPointMake(6.91, 44.53)];
    [gifPath addCurveToPoint: CGPointMake(8.3, 48.15) controlPoint1: CGPointMake(6.91, 46.17) controlPoint2: CGPointMake(7.38, 47.38)];
    [gifPath addCurveToPoint: CGPointMake(11.59, 49.32) controlPoint1: CGPointMake(9.23, 48.93) controlPoint2: CGPointMake(10.32, 49.32)];
    [gifPath addCurveToPoint: CGPointMake(14.87, 48.15) controlPoint1: CGPointMake(12.85, 49.32) controlPoint2: CGPointMake(13.95, 48.93)];
    [gifPath addCurveToPoint: CGPointMake(16.26, 44.53) controlPoint1: CGPointMake(15.8, 47.38) controlPoint2: CGPointMake(16.26, 46.17)];
    [gifPath addLineToPoint: CGPointMake(16.26, 35.63)];
    [gifPath addLineToPoint: CGPointMake(10.77, 35.63)];
    [gifPath addLineToPoint: CGPointMake(10.77, 29.65)];
    [gifPath addLineToPoint: CGPointMake(23.18, 29.65)];
    [gifPath addLineToPoint: CGPointMake(23.18, 44.53)];
    [gifPath addCurveToPoint: CGPointMake(22.16, 49.62) controlPoint1: CGPointMake(23.18, 46.48) controlPoint2: CGPointMake(22.84, 48.18)];
    [gifPath addCurveToPoint: CGPointMake(19.48, 53.2) controlPoint1: CGPointMake(21.48, 51.05) controlPoint2: CGPointMake(20.59, 52.25)];
    [gifPath addCurveToPoint: CGPointMake(15.76, 55.36) controlPoint1: CGPointMake(18.38, 54.15) controlPoint2: CGPointMake(17.13, 54.87)];
    [gifPath addCurveToPoint: CGPointMake(11.59, 56.09) controlPoint1: CGPointMake(14.38, 55.85) controlPoint2: CGPointMake(12.99, 56.09)];
    [gifPath addCurveToPoint: CGPointMake(7.42, 55.36) controlPoint1: CGPointMake(10.19, 56.09) controlPoint2: CGPointMake(8.8, 55.85)];
    [gifPath addCurveToPoint: CGPointMake(3.69, 53.2) controlPoint1: CGPointMake(6.04, 54.87) controlPoint2: CGPointMake(4.8, 54.15)];
    [gifPath addCurveToPoint: CGPointMake(1.02, 49.62) controlPoint1: CGPointMake(2.59, 52.25) controlPoint2: CGPointMake(1.69, 51.05)];
    [gifPath addCurveToPoint: CGPointMake(0, 44.53) controlPoint1: CGPointMake(0.34, 48.18) controlPoint2: CGPointMake(0, 46.48)];
    [gifPath addLineToPoint: CGPointMake(0, 19.56)];
    [gifPath closePath];
    [gifPath moveToPoint: CGPointMake(29.48, 8.4)];
    [gifPath addLineToPoint: CGPointMake(36.39, 8.4)];
    [gifPath addLineToPoint: CGPointMake(36.39, 55.69)];
    [gifPath addLineToPoint: CGPointMake(29.48, 55.69)];
    [gifPath addLineToPoint: CGPointMake(29.48, 8.4)];
    [gifPath closePath];
    [gifPath moveToPoint: CGPointMake(43.1, 8.4)];
    [gifPath addLineToPoint: CGPointMake(63.7, 8.4)];
    [gifPath addLineToPoint: CGPointMake(63.7, 14.78)];
    [gifPath addLineToPoint: CGPointMake(50.01, 14.78)];
    [gifPath addLineToPoint: CGPointMake(50.01, 29.12)];
    [gifPath addLineToPoint: CGPointMake(61.94, 29.12)];
    [gifPath addLineToPoint: CGPointMake(61.94, 35.5)];
    [gifPath addLineToPoint: CGPointMake(50.01, 35.5)];
    [gifPath addLineToPoint: CGPointMake(50.01, 55.69)];
    [gifPath addLineToPoint: CGPointMake(43.1, 55.69)];
    [gifPath addLineToPoint: CGPointMake(43.1, 8.4)];
    [gifPath closePath];
    gifPath.miterLimit = 4;

    gifPath.usesEvenOddFillRule = YES;

    [color setFill];
    [gifPath fill];
}

+ (void)drawIcon_0x116_32ptWithColor: (UIColor*)color
{

    //// Undo Drawing
    UIBezierPath* undoPath = [UIBezierPath bezierPath];
    [undoPath moveToPoint: CGPointMake(9.37, 9.37)];
    [undoPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(15.16, 3.58) controlPoint2: CGPointMake(23.16, 0)];
    [undoPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [undoPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [undoPath addCurveToPoint: CGPointMake(1.01, 40) controlPoint1: CGPointMake(17.09, 64) controlPoint2: CGPointMake(4.56, 53.8)];
    [undoPath addLineToPoint: CGPointMake(1.01, 40)];
    [undoPath addLineToPoint: CGPointMake(9.37, 40)];
    [undoPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(12.66, 49.32) controlPoint2: CGPointMake(21.55, 56)];
    [undoPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 56) controlPoint2: CGPointMake(56, 45.25)];
    [undoPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(56, 18.75) controlPoint2: CGPointMake(45.25, 8)];
    [undoPath addCurveToPoint: CGPointMake(15.03, 15.03) controlPoint1: CGPointMake(25.37, 8) controlPoint2: CGPointMake(19.37, 10.69)];
    [undoPath addLineToPoint: CGPointMake(28, 28)];
    [undoPath addLineToPoint: CGPointMake(0, 28)];
    [undoPath addLineToPoint: CGPointMake(0, 0)];
    [undoPath addLineToPoint: CGPointMake(9.37, 9.37)];
    [undoPath addLineToPoint: CGPointMake(9.37, 9.37)];
    [undoPath closePath];
    undoPath.miterLimit = 4;

    undoPath.usesEvenOddFillRule = YES;

    [color setFill];
    [undoPath fill];
}

+ (void)drawIcon_0x126_24ptWithColor: (UIColor*)color
{

    //// Path-3 Drawing
    UIBezierPath* path3Path = [UIBezierPath bezierPath];
    [path3Path moveToPoint: CGPointMake(38.85, 38.85)];
    [path3Path addCurveToPoint: CGPointMake(9.15, 38.85) controlPoint1: CGPointMake(30.65, 47.05) controlPoint2: CGPointMake(17.35, 47.05)];
    [path3Path addCurveToPoint: CGPointMake(9.15, 9.15) controlPoint1: CGPointMake(0.95, 30.65) controlPoint2: CGPointMake(0.95, 17.35)];
    [path3Path addCurveToPoint: CGPointMake(33.05, 5.05) controlPoint1: CGPointMake(15.49, 2.81) controlPoint2: CGPointMake(25.09, 1.24)];
    [path3Path addCurveToPoint: CGPointMake(35.05, 4.34) controlPoint1: CGPointMake(33.8, 5.4) controlPoint2: CGPointMake(34.69, 5.09)];
    [path3Path addCurveToPoint: CGPointMake(34.34, 2.34) controlPoint1: CGPointMake(35.41, 3.59) controlPoint2: CGPointMake(35.09, 2.7)];
    [path3Path addCurveToPoint: CGPointMake(7.03, 7.03) controlPoint1: CGPointMake(25.24, -2.01) controlPoint2: CGPointMake(14.28, -0.22)];
    [path3Path addCurveToPoint: CGPointMake(7.03, 40.97) controlPoint1: CGPointMake(-2.34, 16.4) controlPoint2: CGPointMake(-2.34, 31.6)];
    [path3Path addCurveToPoint: CGPointMake(40.97, 40.97) controlPoint1: CGPointMake(16.4, 50.34) controlPoint2: CGPointMake(31.6, 50.34)];
    [path3Path addCurveToPoint: CGPointMake(45.66, 13.66) controlPoint1: CGPointMake(48.21, 33.72) controlPoint2: CGPointMake(50.01, 22.77)];
    [path3Path addCurveToPoint: CGPointMake(43.66, 12.96) controlPoint1: CGPointMake(45.31, 12.92) controlPoint2: CGPointMake(44.41, 12.6)];
    [path3Path addCurveToPoint: CGPointMake(42.96, 14.96) controlPoint1: CGPointMake(42.92, 13.31) controlPoint2: CGPointMake(42.6, 14.21)];
    [path3Path addCurveToPoint: CGPointMake(38.85, 38.85) controlPoint1: CGPointMake(46.76, 22.92) controlPoint2: CGPointMake(45.19, 32.51)];
    [path3Path closePath];
    path3Path.miterLimit = 4;

    path3Path.usesEvenOddFillRule = YES;

    [color setFill];
    [path3Path fill];
}

+ (void)drawIcon_0x128_8ptWithColor: (UIColor*)color
{

    //// Path Drawing
    UIBezierPath* pathPath = [UIBezierPath bezierPath];
    [pathPath moveToPoint: CGPointMake(7, 12)];
    [pathPath addLineToPoint: CGPointMake(9, 12)];
    [pathPath addLineToPoint: CGPointMake(9, 0)];
    [pathPath addLineToPoint: CGPointMake(7, 0)];
    [pathPath addLineToPoint: CGPointMake(7, 12)];
    [pathPath closePath];
    [pathPath moveToPoint: CGPointMake(9, 15)];
    [pathPath addCurveToPoint: CGPointMake(8, 14) controlPoint1: CGPointMake(9, 14.45) controlPoint2: CGPointMake(8.55, 14)];
    [pathPath addCurveToPoint: CGPointMake(7, 15) controlPoint1: CGPointMake(7.45, 14) controlPoint2: CGPointMake(7, 14.45)];
    [pathPath addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(7, 15.55) controlPoint2: CGPointMake(7.45, 16)];
    [pathPath addCurveToPoint: CGPointMake(9, 15) controlPoint1: CGPointMake(8.55, 16) controlPoint2: CGPointMake(9, 15.55)];
    [pathPath closePath];
    pathPath.miterLimit = 4;

    pathPath.usesEvenOddFillRule = YES;

    [color setFill];
    [pathPath fill];
}

+ (void)drawIcon_0x126_32ptWithColor: (UIColor*)color
{

    //// Spinner Drawing
    UIBezierPath* spinnerPath = [UIBezierPath bezierPath];
    [spinnerPath moveToPoint: CGPointMake(54.24, 22.96)];
    [spinnerPath addLineToPoint: CGPointMake(60.25, 16.95)];
    [spinnerPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(62.64, 21.44) controlPoint2: CGPointMake(64, 26.56)];
    [spinnerPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [spinnerPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [spinnerPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [spinnerPath addCurveToPoint: CGPointMake(49.56, 5.24) controlPoint1: CGPointMake(38.48, 0) controlPoint2: CGPointMake(44.51, 1.93)];
    [spinnerPath addLineToPoint: CGPointMake(49.56, 5.24)];
    [spinnerPath addLineToPoint: CGPointMake(43.74, 11.06)];
    [spinnerPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(40.27, 9.11) controlPoint2: CGPointMake(36.26, 8)];
    [spinnerPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [spinnerPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [spinnerPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 56) controlPoint2: CGPointMake(56, 45.25)];
    [spinnerPath addCurveToPoint: CGPointMake(54.24, 22.96) controlPoint1: CGPointMake(56, 28.8) controlPoint2: CGPointMake(55.38, 25.75)];
    [spinnerPath addLineToPoint: CGPointMake(54.24, 22.96)];
    [spinnerPath closePath];
    spinnerPath.miterLimit = 4;

    spinnerPath.usesEvenOddFillRule = YES;

    [color setFill];
    [spinnerPath fill];
}

+ (void)drawIcon_0x165_32ptWithColor: (UIColor*)color
{

    //// Pending Drawing
    UIBezierPath* pendingPath = [UIBezierPath bezierPath];
    [pendingPath moveToPoint: CGPointMake(32, 56)];
    [pendingPath addLineToPoint: CGPointMake(32, 56)];
    [pendingPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 56) controlPoint2: CGPointMake(56, 45.25)];
    [pendingPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(56, 18.75) controlPoint2: CGPointMake(45.25, 8)];
    [pendingPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [pendingPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [pendingPath addLineToPoint: CGPointMake(32, 56)];
    [pendingPath addLineToPoint: CGPointMake(32, 56)];
    [pendingPath closePath];
    [pendingPath moveToPoint: CGPointMake(32, 64)];
    [pendingPath addLineToPoint: CGPointMake(32, 64)];
    [pendingPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [pendingPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [pendingPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [pendingPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [pendingPath addLineToPoint: CGPointMake(32, 64)];
    [pendingPath addLineToPoint: CGPointMake(32, 64)];
    [pendingPath closePath];
    [pendingPath moveToPoint: CGPointMake(36, 12)];
    [pendingPath addCurveToPoint: CGPointMake(36, 28) controlPoint1: CGPointMake(36, 12) controlPoint2: CGPointMake(36, 21.02)];
    [pendingPath addLineToPoint: CGPointMake(48, 28)];
    [pendingPath addLineToPoint: CGPointMake(48, 36)];
    [pendingPath addLineToPoint: CGPointMake(28, 36)];
    [pendingPath addLineToPoint: CGPointMake(28, 28)];
    [pendingPath addCurveToPoint: CGPointMake(28, 12) controlPoint1: CGPointMake(28, 21.02) controlPoint2: CGPointMake(28, 12)];
    [pendingPath addLineToPoint: CGPointMake(36, 12)];
    [pendingPath addLineToPoint: CGPointMake(36, 12)];
    [pendingPath closePath];
    [color setFill];
    [pendingPath fill];
}

+ (void)drawIcon_0x187_32ptWithColor: (UIColor*)color
{

    //// Card Drawing
    UIBezierPath* cardPath = [UIBezierPath bezierPath];
    [cardPath moveToPoint: CGPointMake(0, 16.02)];
    [cardPath addCurveToPoint: CGPointMake(7.98, 8) controlPoint1: CGPointMake(0, 11.59) controlPoint2: CGPointMake(3.58, 8)];
    [cardPath addLineToPoint: CGPointMake(56.02, 8)];
    [cardPath addCurveToPoint: CGPointMake(64, 16.02) controlPoint1: CGPointMake(60.43, 8) controlPoint2: CGPointMake(64, 11.59)];
    [cardPath addLineToPoint: CGPointMake(64, 55.98)];
    [cardPath addCurveToPoint: CGPointMake(56.02, 64) controlPoint1: CGPointMake(64, 60.41) controlPoint2: CGPointMake(60.42, 64)];
    [cardPath addLineToPoint: CGPointMake(7.98, 64)];
    [cardPath addCurveToPoint: CGPointMake(0, 55.98) controlPoint1: CGPointMake(3.57, 64) controlPoint2: CGPointMake(0, 60.41)];
    [cardPath addLineToPoint: CGPointMake(0, 16.02)];
    [cardPath addLineToPoint: CGPointMake(0, 16.02)];
    [cardPath addLineToPoint: CGPointMake(0, 16.02)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(24, 12)];
    [cardPath addLineToPoint: CGPointMake(40, 12)];
    [cardPath addLineToPoint: CGPointMake(40, 16)];
    [cardPath addLineToPoint: CGPointMake(24, 16)];
    [cardPath addLineToPoint: CGPointMake(24, 12)];
    [cardPath addLineToPoint: CGPointMake(24, 12)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(8, 24)];
    [cardPath addLineToPoint: CGPointMake(28, 24)];
    [cardPath addLineToPoint: CGPointMake(28, 44)];
    [cardPath addLineToPoint: CGPointMake(8, 44)];
    [cardPath addLineToPoint: CGPointMake(8, 24)];
    [cardPath addLineToPoint: CGPointMake(8, 24)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(56, 24)];
    [cardPath addLineToPoint: CGPointMake(36, 24)];
    [cardPath addLineToPoint: CGPointMake(36, 32)];
    [cardPath addLineToPoint: CGPointMake(56, 32)];
    [cardPath addLineToPoint: CGPointMake(56, 24)];
    [cardPath addLineToPoint: CGPointMake(56, 24)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(56, 36)];
    [cardPath addLineToPoint: CGPointMake(36, 36)];
    [cardPath addLineToPoint: CGPointMake(36, 44)];
    [cardPath addLineToPoint: CGPointMake(56, 44)];
    [cardPath addLineToPoint: CGPointMake(56, 36)];
    [cardPath addLineToPoint: CGPointMake(56, 36)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(56, 48)];
    [cardPath addLineToPoint: CGPointMake(8, 48)];
    [cardPath addLineToPoint: CGPointMake(8, 56)];
    [cardPath addLineToPoint: CGPointMake(56, 56)];
    [cardPath addLineToPoint: CGPointMake(56, 48)];
    [cardPath closePath];
    [cardPath moveToPoint: CGPointMake(24, 0)];
    [cardPath addLineToPoint: CGPointMake(40, 0)];
    [cardPath addLineToPoint: CGPointMake(40, 8)];
    [cardPath addLineToPoint: CGPointMake(24, 8)];
    [cardPath addLineToPoint: CGPointMake(24, 0)];
    [cardPath closePath];
    cardPath.miterLimit = 4;

    cardPath.usesEvenOddFillRule = YES;

    [color setFill];
    [cardPath fill];
}

+ (void)drawIcon_0x163_32ptWithColor: (UIColor*)color
{

    //// Search Drawing
    UIBezierPath* searchPath = [UIBezierPath bezierPath];
    [searchPath moveToPoint: CGPointMake(49.92, 28.98)];
    [searchPath addCurveToPoint: CGPointMake(28.96, 8) controlPoint1: CGPointMake(49.92, 17.39) controlPoint2: CGPointMake(40.54, 8)];
    [searchPath addCurveToPoint: CGPointMake(8, 28.98) controlPoint1: CGPointMake(17.38, 8) controlPoint2: CGPointMake(8, 17.39)];
    [searchPath addCurveToPoint: CGPointMake(28.96, 49.96) controlPoint1: CGPointMake(8, 40.57) controlPoint2: CGPointMake(17.38, 49.96)];
    [searchPath addCurveToPoint: CGPointMake(41.51, 45.78) controlPoint1: CGPointMake(33.67, 49.96) controlPoint2: CGPointMake(38.02, 48.41)];
    [searchPath addLineToPoint: CGPointMake(51.77, 56)];
    [searchPath addLineToPoint: CGPointMake(56, 51.76)];
    [searchPath addLineToPoint: CGPointMake(45.75, 41.54)];
    [searchPath addCurveToPoint: CGPointMake(49.92, 28.98) controlPoint1: CGPointMake(48.37, 38.04) controlPoint2: CGPointMake(49.92, 33.69)];
    [searchPath closePath];
    [searchPath moveToPoint: CGPointMake(29, 44)];
    [searchPath addCurveToPoint: CGPointMake(44, 29) controlPoint1: CGPointMake(37.28, 44) controlPoint2: CGPointMake(44, 37.28)];
    [searchPath addCurveToPoint: CGPointMake(29, 14) controlPoint1: CGPointMake(44, 20.72) controlPoint2: CGPointMake(37.28, 14)];
    [searchPath addCurveToPoint: CGPointMake(14, 29) controlPoint1: CGPointMake(20.72, 14) controlPoint2: CGPointMake(14, 20.72)];
    [searchPath addCurveToPoint: CGPointMake(29, 44) controlPoint1: CGPointMake(14, 37.28) controlPoint2: CGPointMake(20.72, 44)];
    [searchPath closePath];
    searchPath.miterLimit = 4;

    searchPath.usesEvenOddFillRule = YES;

    [color setFill];
    [searchPath fill];
}

+ (void)drawIcon_0x221_32ptWithColor: (UIColor*)color
{

    //// Theme Drawing
    UIBezierPath* themePath = [UIBezierPath bezierPath];
    [themePath moveToPoint: CGPointMake(32, 48)];
    [themePath addCurveToPoint: CGPointMake(48, 32) controlPoint1: CGPointMake(40.84, 48) controlPoint2: CGPointMake(48, 40.84)];
    [themePath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(48, 23.16) controlPoint2: CGPointMake(40.84, 16)];
    [themePath addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(23.16, 16) controlPoint2: CGPointMake(16, 23.16)];
    [themePath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(16, 40.84) controlPoint2: CGPointMake(23.16, 48)];
    [themePath addLineToPoint: CGPointMake(32, 48)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(28, 4)];
    [themePath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(28, 1.79) controlPoint2: CGPointMake(29.78, 0)];
    [themePath addCurveToPoint: CGPointMake(36, 4) controlPoint1: CGPointMake(34.21, 0) controlPoint2: CGPointMake(36, 1.77)];
    [themePath addLineToPoint: CGPointMake(36, 8)];
    [themePath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(36, 10.21) controlPoint2: CGPointMake(34.22, 12)];
    [themePath addCurveToPoint: CGPointMake(28, 8) controlPoint1: CGPointMake(29.79, 12) controlPoint2: CGPointMake(28, 10.23)];
    [themePath addLineToPoint: CGPointMake(28, 4)];
    [themePath addLineToPoint: CGPointMake(28, 4)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(28, 56)];
    [themePath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(28, 53.79) controlPoint2: CGPointMake(29.78, 52)];
    [themePath addCurveToPoint: CGPointMake(36, 56) controlPoint1: CGPointMake(34.21, 52) controlPoint2: CGPointMake(36, 53.77)];
    [themePath addLineToPoint: CGPointMake(36, 60)];
    [themePath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(36, 62.21) controlPoint2: CGPointMake(34.22, 64)];
    [themePath addCurveToPoint: CGPointMake(28, 60) controlPoint1: CGPointMake(29.79, 64) controlPoint2: CGPointMake(28, 62.23)];
    [themePath addLineToPoint: CGPointMake(28, 56)];
    [themePath addLineToPoint: CGPointMake(28, 56)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(4, 36)];
    [themePath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(1.79, 36) controlPoint2: CGPointMake(0, 34.22)];
    [themePath addCurveToPoint: CGPointMake(4, 28) controlPoint1: CGPointMake(0, 29.79) controlPoint2: CGPointMake(1.77, 28)];
    [themePath addLineToPoint: CGPointMake(8, 28)];
    [themePath addCurveToPoint: CGPointMake(12, 32) controlPoint1: CGPointMake(10.21, 28) controlPoint2: CGPointMake(12, 29.78)];
    [themePath addCurveToPoint: CGPointMake(8, 36) controlPoint1: CGPointMake(12, 34.21) controlPoint2: CGPointMake(10.23, 36)];
    [themePath addLineToPoint: CGPointMake(4, 36)];
    [themePath addLineToPoint: CGPointMake(4, 36)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(56, 36)];
    [themePath addCurveToPoint: CGPointMake(52, 32) controlPoint1: CGPointMake(53.79, 36) controlPoint2: CGPointMake(52, 34.22)];
    [themePath addCurveToPoint: CGPointMake(56, 28) controlPoint1: CGPointMake(52, 29.79) controlPoint2: CGPointMake(53.77, 28)];
    [themePath addLineToPoint: CGPointMake(60, 28)];
    [themePath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(62.21, 28) controlPoint2: CGPointMake(64, 29.78)];
    [themePath addCurveToPoint: CGPointMake(60, 36) controlPoint1: CGPointMake(64, 34.21) controlPoint2: CGPointMake(62.23, 36)];
    [themePath addLineToPoint: CGPointMake(56, 36)];
    [themePath addLineToPoint: CGPointMake(56, 36)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(9.37, 15.03)];
    [themePath addCurveToPoint: CGPointMake(9.37, 9.37) controlPoint1: CGPointMake(7.81, 13.47) controlPoint2: CGPointMake(7.8, 10.95)];
    [themePath addCurveToPoint: CGPointMake(15.03, 9.37) controlPoint1: CGPointMake(10.93, 7.81) controlPoint2: CGPointMake(13.45, 7.8)];
    [themePath addLineToPoint: CGPointMake(17.86, 12.2)];
    [themePath addCurveToPoint: CGPointMake(17.86, 17.86) controlPoint1: CGPointMake(19.42, 13.76) controlPoint2: CGPointMake(19.43, 16.28)];
    [themePath addCurveToPoint: CGPointMake(12.2, 17.86) controlPoint1: CGPointMake(16.3, 19.42) controlPoint2: CGPointMake(13.78, 19.43)];
    [themePath addLineToPoint: CGPointMake(9.37, 15.03)];
    [themePath addLineToPoint: CGPointMake(9.37, 15.03)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(46.14, 51.8)];
    [themePath addCurveToPoint: CGPointMake(46.14, 46.14) controlPoint1: CGPointMake(44.58, 50.24) controlPoint2: CGPointMake(44.57, 47.72)];
    [themePath addCurveToPoint: CGPointMake(51.8, 46.14) controlPoint1: CGPointMake(47.7, 44.58) controlPoint2: CGPointMake(50.22, 44.57)];
    [themePath addLineToPoint: CGPointMake(54.63, 48.97)];
    [themePath addCurveToPoint: CGPointMake(54.63, 54.63) controlPoint1: CGPointMake(56.19, 50.53) controlPoint2: CGPointMake(56.2, 53.05)];
    [themePath addCurveToPoint: CGPointMake(48.97, 54.63) controlPoint1: CGPointMake(53.07, 56.19) controlPoint2: CGPointMake(50.55, 56.2)];
    [themePath addLineToPoint: CGPointMake(46.14, 51.8)];
    [themePath addLineToPoint: CGPointMake(46.14, 51.8)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(15.03, 54.63)];
    [themePath addCurveToPoint: CGPointMake(9.37, 54.63) controlPoint1: CGPointMake(13.47, 56.19) controlPoint2: CGPointMake(10.95, 56.2)];
    [themePath addCurveToPoint: CGPointMake(9.37, 48.97) controlPoint1: CGPointMake(7.81, 53.07) controlPoint2: CGPointMake(7.8, 50.55)];
    [themePath addLineToPoint: CGPointMake(12.2, 46.14)];
    [themePath addCurveToPoint: CGPointMake(17.86, 46.14) controlPoint1: CGPointMake(13.76, 44.58) controlPoint2: CGPointMake(16.28, 44.57)];
    [themePath addCurveToPoint: CGPointMake(17.86, 51.8) controlPoint1: CGPointMake(19.42, 47.7) controlPoint2: CGPointMake(19.43, 50.22)];
    [themePath addLineToPoint: CGPointMake(15.03, 54.63)];
    [themePath addLineToPoint: CGPointMake(15.03, 54.63)];
    [themePath closePath];
    [themePath moveToPoint: CGPointMake(51.8, 17.86)];
    [themePath addCurveToPoint: CGPointMake(46.14, 17.86) controlPoint1: CGPointMake(50.24, 19.42) controlPoint2: CGPointMake(47.72, 19.43)];
    [themePath addCurveToPoint: CGPointMake(46.14, 12.2) controlPoint1: CGPointMake(44.58, 16.3) controlPoint2: CGPointMake(44.57, 13.78)];
    [themePath addLineToPoint: CGPointMake(48.97, 9.37)];
    [themePath addCurveToPoint: CGPointMake(54.63, 9.37) controlPoint1: CGPointMake(50.53, 7.81) controlPoint2: CGPointMake(53.05, 7.8)];
    [themePath addCurveToPoint: CGPointMake(54.63, 15.03) controlPoint1: CGPointMake(56.19, 10.93) controlPoint2: CGPointMake(56.2, 13.45)];
    [themePath addLineToPoint: CGPointMake(51.8, 17.86)];
    [themePath addLineToPoint: CGPointMake(51.8, 17.86)];
    [themePath closePath];
    themePath.miterLimit = 4;

    themePath.usesEvenOddFillRule = YES;

    [color setFill];
    [themePath fill];
}

+ (void)drawInviteWithColor: (UIColor*)color
{

    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(27.9, 30.82)];
    [bezier2Path addLineToPoint: CGPointMake(34.13, 33.27)];
    [bezier2Path addCurveToPoint: CGPointMake(36, 31.94) controlPoint1: CGPointMake(35.16, 33.67) controlPoint2: CGPointMake(36, 33.08)];
    [bezier2Path addLineToPoint: CGPointMake(36, 7.45)];
    [bezier2Path addCurveToPoint: CGPointMake(34.13, 6.13) controlPoint1: CGPointMake(36, 6.31) controlPoint2: CGPointMake(35.16, 5.72)];
    [bezier2Path addLineToPoint: CGPointMake(10, 15.61)];
    [bezier2Path addLineToPoint: CGPointMake(5.9, 14.21)];
    [bezier2Path addCurveToPoint: CGPointMake(4, 15.59) controlPoint1: CGPointMake(4.83, 13.85) controlPoint2: CGPointMake(4, 14.47)];
    [bezier2Path addLineToPoint: CGPointMake(4, 23.8)];
    [bezier2Path addCurveToPoint: CGPointMake(5.9, 25.18) controlPoint1: CGPointMake(4, 24.91) controlPoint2: CGPointMake(4.85, 25.54)];
    [bezier2Path addLineToPoint: CGPointMake(10, 23.78)];
    [bezier2Path addLineToPoint: CGPointMake(14, 25.36)];
    [bezier2Path addLineToPoint: CGPointMake(14, 29.92)];
    [bezier2Path addCurveToPoint: CGPointMake(18.01, 34) controlPoint1: CGPointMake(14, 32.19) controlPoint2: CGPointMake(15.8, 34)];
    [bezier2Path addLineToPoint: CGPointMake(23.99, 34)];
    [bezier2Path addCurveToPoint: CGPointMake(27.9, 30.82) controlPoint1: CGPointMake(25.92, 34) controlPoint2: CGPointMake(27.5, 32.64)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(16, 26.14)];
    [bezier2Path addLineToPoint: CGPointMake(16, 29.92)];
    [bezier2Path addCurveToPoint: CGPointMake(18.01, 31.96) controlPoint1: CGPointMake(16, 31.05) controlPoint2: CGPointMake(16.89, 31.96)];
    [bezier2Path addLineToPoint: CGPointMake(23.99, 31.96)];
    [bezier2Path addCurveToPoint: CGPointMake(25.99, 30.07) controlPoint1: CGPointMake(25.06, 31.96) controlPoint2: CGPointMake(25.92, 31.13)];
    [bezier2Path addLineToPoint: CGPointMake(16, 26.14)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;

    [color setFill];
    [bezier2Path fill];
}

+ (void)drawIcon_0x222_32ptWithColor: (UIColor*)color
{

    //// Hung up Drawing
    UIBezierPath* hungUpPath = [UIBezierPath bezierPath];
    [hungUpPath moveToPoint: CGPointMake(0, 50.85)];
    [hungUpPath addLineToPoint: CGPointMake(0, 50.85)];
    [hungUpPath addCurveToPoint: CGPointMake(13.51, 63.67) controlPoint1: CGPointMake(0, 56.04) controlPoint2: CGPointMake(5.84, 61.44)];
    [hungUpPath addCurveToPoint: CGPointMake(15.87, 62.61) controlPoint1: CGPointMake(15.3, 64.19) controlPoint2: CGPointMake(15.15, 64.26)];
    [hungUpPath addCurveToPoint: CGPointMake(20.11, 53.32) controlPoint1: CGPointMake(16.87, 60.36) controlPoint2: CGPointMake(18.06, 57.76)];
    [hungUpPath addCurveToPoint: CGPointMake(22.67, 47.63) controlPoint1: CGPointMake(21.04, 51.23) controlPoint2: CGPointMake(21.99, 49.12)];
    [hungUpPath addCurveToPoint: CGPointMake(23.18, 46.16) controlPoint1: CGPointMake(23.08, 46.7) controlPoint2: CGPointMake(23.18, 46.37)];
    [hungUpPath addCurveToPoint: CGPointMake(22.9, 45.61) controlPoint1: CGPointMake(23.18, 46.05) controlPoint2: CGPointMake(23.11, 45.89)];
    [hungUpPath addCurveToPoint: CGPointMake(22.36, 45.03) controlPoint1: CGPointMake(22.77, 45.45) controlPoint2: CGPointMake(22.64, 45.31)];
    [hungUpPath addLineToPoint: CGPointMake(18.73, 41.4)];
    [hungUpPath addLineToPoint: CGPointMake(16.21, 38.89)];
    [hungUpPath addLineToPoint: CGPointMake(18.03, 35.83)];
    [hungUpPath addCurveToPoint: CGPointMake(25.83, 25.81) controlPoint1: CGPointMake(20.04, 32.47) controlPoint2: CGPointMake(22.62, 29.01)];
    [hungUpPath addCurveToPoint: CGPointMake(35.82, 18.02) controlPoint1: CGPointMake(29.05, 22.59) controlPoint2: CGPointMake(32.53, 19.98)];
    [hungUpPath addLineToPoint: CGPointMake(38.86, 16.21)];
    [hungUpPath addLineToPoint: CGPointMake(41.38, 18.69)];
    [hungUpPath addLineToPoint: CGPointMake(45.09, 22.36)];
    [hungUpPath addCurveToPoint: CGPointMake(47.61, 22.7) controlPoint1: CGPointMake(46.1, 23.38) controlPoint2: CGPointMake(46.07, 23.38)];
    [hungUpPath addCurveToPoint: CGPointMake(53.27, 20.12) controlPoint1: CGPointMake(48.89, 22.13) controlPoint2: CGPointMake(50.66, 21.33)];
    [hungUpPath addCurveToPoint: CGPointMake(62.7, 15.82) controlPoint1: CGPointMake(57.77, 18.05) controlPoint2: CGPointMake(60.38, 16.86)];
    [hungUpPath addCurveToPoint: CGPointMake(64, 14.93) controlPoint1: CGPointMake(63.87, 15.32) controlPoint2: CGPointMake(64, 15.21)];
    [hungUpPath addCurveToPoint: CGPointMake(63.69, 13.51) controlPoint1: CGPointMake(64, 14.71) controlPoint2: CGPointMake(63.91, 14.29)];
    [hungUpPath addCurveToPoint: CGPointMake(50.78, 0) controlPoint1: CGPointMake(61.45, 5.78) controlPoint2: CGPointMake(56.01, -0.05)];
    [hungUpPath addCurveToPoint: CGPointMake(17.84, 17.87) controlPoint1: CGPointMake(42.62, 0.08) controlPoint2: CGPointMake(28.55, 7.17)];
    [hungUpPath addCurveToPoint: CGPointMake(0, 50.73) controlPoint1: CGPointMake(7.16, 28.54) controlPoint2: CGPointMake(0.08, 42.59)];
    [hungUpPath addLineToPoint: CGPointMake(0, 50.85)];
    [hungUpPath addLineToPoint: CGPointMake(0, 50.85)];
    [hungUpPath closePath];
    hungUpPath.miterLimit = 4;

    hungUpPath.usesEvenOddFillRule = YES;

    [color setFill];
    [hungUpPath fill];
}

+ (void)drawIcon_0x123_32ptWithColor: (UIColor*)color
{

    //// Undo Drawing
    UIBezierPath* undoPath = [UIBezierPath bezierPath];
    [undoPath moveToPoint: CGPointMake(14, 38)];
    [undoPath addCurveToPoint: CGPointMake(20, 32) controlPoint1: CGPointMake(17.31, 38) controlPoint2: CGPointMake(20, 35.31)];
    [undoPath addCurveToPoint: CGPointMake(14, 26) controlPoint1: CGPointMake(20, 28.69) controlPoint2: CGPointMake(17.31, 26)];
    [undoPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(10.69, 26) controlPoint2: CGPointMake(8, 28.69)];
    [undoPath addCurveToPoint: CGPointMake(14, 38) controlPoint1: CGPointMake(8, 35.31) controlPoint2: CGPointMake(10.69, 38)];
    [undoPath addLineToPoint: CGPointMake(14, 38)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(50, 38)];
    [undoPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(53.31, 38) controlPoint2: CGPointMake(56, 35.31)];
    [undoPath addCurveToPoint: CGPointMake(50, 26) controlPoint1: CGPointMake(56, 28.69) controlPoint2: CGPointMake(53.31, 26)];
    [undoPath addCurveToPoint: CGPointMake(44, 32) controlPoint1: CGPointMake(46.69, 26) controlPoint2: CGPointMake(44, 28.69)];
    [undoPath addCurveToPoint: CGPointMake(50, 38) controlPoint1: CGPointMake(44, 35.31) controlPoint2: CGPointMake(46.69, 38)];
    [undoPath addLineToPoint: CGPointMake(50, 38)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(32, 38)];
    [undoPath addCurveToPoint: CGPointMake(38, 32) controlPoint1: CGPointMake(35.31, 38) controlPoint2: CGPointMake(38, 35.31)];
    [undoPath addCurveToPoint: CGPointMake(32, 26) controlPoint1: CGPointMake(38, 28.69) controlPoint2: CGPointMake(35.31, 26)];
    [undoPath addCurveToPoint: CGPointMake(26, 32) controlPoint1: CGPointMake(28.69, 26) controlPoint2: CGPointMake(26, 28.69)];
    [undoPath addCurveToPoint: CGPointMake(32, 38) controlPoint1: CGPointMake(26, 35.31) controlPoint2: CGPointMake(28.69, 38)];
    [undoPath addLineToPoint: CGPointMake(32, 38)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(14, 20)];
    [undoPath addCurveToPoint: CGPointMake(20, 14) controlPoint1: CGPointMake(17.31, 20) controlPoint2: CGPointMake(20, 17.31)];
    [undoPath addCurveToPoint: CGPointMake(14, 8) controlPoint1: CGPointMake(20, 10.69) controlPoint2: CGPointMake(17.31, 8)];
    [undoPath addCurveToPoint: CGPointMake(8, 14) controlPoint1: CGPointMake(10.69, 8) controlPoint2: CGPointMake(8, 10.69)];
    [undoPath addCurveToPoint: CGPointMake(14, 20) controlPoint1: CGPointMake(8, 17.31) controlPoint2: CGPointMake(10.69, 20)];
    [undoPath addLineToPoint: CGPointMake(14, 20)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(50, 20)];
    [undoPath addCurveToPoint: CGPointMake(56, 14) controlPoint1: CGPointMake(53.31, 20) controlPoint2: CGPointMake(56, 17.31)];
    [undoPath addCurveToPoint: CGPointMake(50, 8) controlPoint1: CGPointMake(56, 10.69) controlPoint2: CGPointMake(53.31, 8)];
    [undoPath addCurveToPoint: CGPointMake(44, 14) controlPoint1: CGPointMake(46.69, 8) controlPoint2: CGPointMake(44, 10.69)];
    [undoPath addCurveToPoint: CGPointMake(50, 20) controlPoint1: CGPointMake(44, 17.31) controlPoint2: CGPointMake(46.69, 20)];
    [undoPath addLineToPoint: CGPointMake(50, 20)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(32, 20)];
    [undoPath addCurveToPoint: CGPointMake(38, 14) controlPoint1: CGPointMake(35.31, 20) controlPoint2: CGPointMake(38, 17.31)];
    [undoPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(38, 10.69) controlPoint2: CGPointMake(35.31, 8)];
    [undoPath addCurveToPoint: CGPointMake(26, 14) controlPoint1: CGPointMake(28.69, 8) controlPoint2: CGPointMake(26, 10.69)];
    [undoPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(26, 17.31) controlPoint2: CGPointMake(28.69, 20)];
    [undoPath addLineToPoint: CGPointMake(32, 20)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(14, 56)];
    [undoPath addCurveToPoint: CGPointMake(20, 50) controlPoint1: CGPointMake(17.31, 56) controlPoint2: CGPointMake(20, 53.31)];
    [undoPath addCurveToPoint: CGPointMake(14, 44) controlPoint1: CGPointMake(20, 46.69) controlPoint2: CGPointMake(17.31, 44)];
    [undoPath addCurveToPoint: CGPointMake(8, 50) controlPoint1: CGPointMake(10.69, 44) controlPoint2: CGPointMake(8, 46.69)];
    [undoPath addCurveToPoint: CGPointMake(14, 56) controlPoint1: CGPointMake(8, 53.31) controlPoint2: CGPointMake(10.69, 56)];
    [undoPath addLineToPoint: CGPointMake(14, 56)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(50, 56)];
    [undoPath addCurveToPoint: CGPointMake(56, 50) controlPoint1: CGPointMake(53.31, 56) controlPoint2: CGPointMake(56, 53.31)];
    [undoPath addCurveToPoint: CGPointMake(50, 44) controlPoint1: CGPointMake(56, 46.69) controlPoint2: CGPointMake(53.31, 44)];
    [undoPath addCurveToPoint: CGPointMake(44, 50) controlPoint1: CGPointMake(46.69, 44) controlPoint2: CGPointMake(44, 46.69)];
    [undoPath addCurveToPoint: CGPointMake(50, 56) controlPoint1: CGPointMake(44, 53.31) controlPoint2: CGPointMake(46.69, 56)];
    [undoPath addLineToPoint: CGPointMake(50, 56)];
    [undoPath closePath];
    [undoPath moveToPoint: CGPointMake(32, 56)];
    [undoPath addCurveToPoint: CGPointMake(38, 50) controlPoint1: CGPointMake(35.31, 56) controlPoint2: CGPointMake(38, 53.31)];
    [undoPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(38, 46.69) controlPoint2: CGPointMake(35.31, 44)];
    [undoPath addCurveToPoint: CGPointMake(26, 50) controlPoint1: CGPointMake(28.69, 44) controlPoint2: CGPointMake(26, 46.69)];
    [undoPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(26, 53.31) controlPoint2: CGPointMake(28.69, 56)];
    [undoPath addLineToPoint: CGPointMake(32, 56)];
    [undoPath closePath];
    [color setFill];
    [undoPath fill];
}

+ (void)drawIcon_0x128_32ptWithColor: (UIColor*)color
{

    //// Error Drawing
    UIBezierPath* errorPath = [UIBezierPath bezierPath];
    [errorPath moveToPoint: CGPointMake(36, 4)];
    [errorPath addLineToPoint: CGPointMake(36, 44)];
    [errorPath addLineToPoint: CGPointMake(28, 44)];
    [errorPath addLineToPoint: CGPointMake(28, 4)];
    [errorPath addLineToPoint: CGPointMake(36, 4)];
    [errorPath closePath];
    [errorPath moveToPoint: CGPointMake(36, 52)];
    [errorPath addLineToPoint: CGPointMake(36, 60)];
    [errorPath addLineToPoint: CGPointMake(28, 60)];
    [errorPath addLineToPoint: CGPointMake(28, 52)];
    [errorPath addLineToPoint: CGPointMake(36, 52)];
    [errorPath closePath];
    errorPath.miterLimit = 4;

    errorPath.usesEvenOddFillRule = YES;

    [color setFill];
    [errorPath fill];
}

+ (void)drawIcon_0x113_32ptWithColor: (UIColor*)color
{

    //// Down Drawing
    UIBezierPath* downPath = [UIBezierPath bezierPath];
    [downPath moveToPoint: CGPointMake(32.16, 52.07)];
    [downPath addLineToPoint: CGPointMake(62.31, 21.62)];
    [downPath addLineToPoint: CGPointMake(56.74, 16)];
    [downPath addLineToPoint: CGPointMake(32.16, 40.82)];
    [downPath addLineToPoint: CGPointMake(7.57, 16)];
    [downPath addLineToPoint: CGPointMake(2, 21.62)];
    [downPath addLineToPoint: CGPointMake(32.16, 52.07)];
    [downPath closePath];
    downPath.miterLimit = 4;

    downPath.usesEvenOddFillRule = YES;

    [color setFill];
    [downPath fill];
}

+ (void)drawIcon_0x121_32ptWithColor: (UIColor*)color
{

    //// List Drawing
    UIBezierPath* listPath = [UIBezierPath bezierPath];
    [listPath moveToPoint: CGPointMake(0, 28)];
    [listPath addLineToPoint: CGPointMake(64, 28)];
    [listPath addLineToPoint: CGPointMake(64, 36)];
    [listPath addLineToPoint: CGPointMake(0, 36)];
    [listPath addLineToPoint: CGPointMake(0, 28)];
    [listPath addLineToPoint: CGPointMake(0, 28)];
    [listPath closePath];
    [listPath moveToPoint: CGPointMake(0, 4)];
    [listPath addLineToPoint: CGPointMake(64, 4)];
    [listPath addLineToPoint: CGPointMake(64, 12)];
    [listPath addLineToPoint: CGPointMake(0, 12)];
    [listPath addLineToPoint: CGPointMake(0, 4)];
    [listPath addLineToPoint: CGPointMake(0, 4)];
    [listPath closePath];
    [listPath moveToPoint: CGPointMake(0, 52)];
    [listPath addLineToPoint: CGPointMake(64, 52)];
    [listPath addLineToPoint: CGPointMake(64, 60)];
    [listPath addLineToPoint: CGPointMake(0, 60)];
    [listPath addLineToPoint: CGPointMake(0, 52)];
    [listPath addLineToPoint: CGPointMake(0, 52)];
    [listPath closePath];
    listPath.miterLimit = 4;

    listPath.usesEvenOddFillRule = YES;

    [color setFill];
    [listPath fill];
}

+ (void)drawIcon_0x111_32ptWithColor: (UIColor*)color
{

    //// Back Drawing
    UIBezierPath* backPath = [UIBezierPath bezierPath];
    [backPath moveToPoint: CGPointMake(45.22, 36.27)];
    [backPath addLineToPoint: CGPointMake(25.01, 56.22)];
    [backPath addLineToPoint: CGPointMake(30.47, 61.6)];
    [backPath addLineToPoint: CGPointMake(60, 32.45)];
    [backPath addLineToPoint: CGPointMake(30.47, 3.29)];
    [backPath addLineToPoint: CGPointMake(25.01, 8.68)];
    [backPath addLineToPoint: CGPointMake(45.25, 28.65)];
    [backPath addLineToPoint: CGPointMake(6, 28.65)];
    [backPath addLineToPoint: CGPointMake(6, 36.27)];
    [backPath addLineToPoint: CGPointMake(45.22, 36.27)];
    [backPath addLineToPoint: CGPointMake(45.22, 36.27)];
    [backPath closePath];
    backPath.miterLimit = 4;

    backPath.usesEvenOddFillRule = YES;

    [color setFill];
    [backPath fill];
}

+ (void)drawIcon_0x226_32ptWithColor: (UIColor*)color
{

    //// Video Drawing
    UIBezierPath* videoPath = [UIBezierPath bezierPath];
    [videoPath moveToPoint: CGPointMake(48, 15.36)];
    [videoPath addCurveToPoint: CGPointMake(40.65, 8) controlPoint1: CGPointMake(48, 11.28) controlPoint2: CGPointMake(44.71, 8)];
    [videoPath addLineToPoint: CGPointMake(7.36, 8)];
    [videoPath addCurveToPoint: CGPointMake(0, 15.36) controlPoint1: CGPointMake(3.29, 8) controlPoint2: CGPointMake(0, 11.3)];
    [videoPath addLineToPoint: CGPointMake(0, 48.64)];
    [videoPath addCurveToPoint: CGPointMake(7.36, 56) controlPoint1: CGPointMake(0, 52.72) controlPoint2: CGPointMake(3.29, 56)];
    [videoPath addLineToPoint: CGPointMake(40.65, 56)];
    [videoPath addCurveToPoint: CGPointMake(48, 48.64) controlPoint1: CGPointMake(44.71, 56) controlPoint2: CGPointMake(48, 52.7)];
    [videoPath addLineToPoint: CGPointMake(48, 38.99)];
    [videoPath addLineToPoint: CGPointMake(60.88, 47.66)];
    [videoPath addCurveToPoint: CGPointMake(64, 45.99) controlPoint1: CGPointMake(62.21, 48.55) controlPoint2: CGPointMake(64, 47.6)];
    [videoPath addLineToPoint: CGPointMake(64, 18.01)];
    [videoPath addCurveToPoint: CGPointMake(60.88, 16.34) controlPoint1: CGPointMake(64, 16.4) controlPoint2: CGPointMake(62.21, 15.45)];
    [videoPath addLineToPoint: CGPointMake(48, 25)];
    [videoPath addLineToPoint: CGPointMake(48, 15.36)];
    [videoPath closePath];
    videoPath.miterLimit = 4;

    videoPath.usesEvenOddFillRule = YES;

    [color setFill];
    [videoPath fill];
}

+ (void)drawIcon_0x131_32ptWithColor: (UIColor*)color
{

    //// Play Drawing
    UIBezierPath* playPath = [UIBezierPath bezierPath];
    [playPath moveToPoint: CGPointMake(16, 62.31)];
    [playPath addLineToPoint: CGPointMake(64, 32.16)];
    [playPath addLineToPoint: CGPointMake(16, 2)];
    [playPath addLineToPoint: CGPointMake(16, 62.31)];
    [playPath closePath];
    playPath.miterLimit = 4;

    playPath.usesEvenOddFillRule = YES;

    [color setFill];
    [playPath fill];
}

+ (void)drawIcon_0x164_32ptWithColor: (UIColor*)color
{

    //// Settings Drawing
    UIBezierPath* settingsPath = [UIBezierPath bezierPath];
    [settingsPath moveToPoint: CGPointMake(11.32, 44.19)];
    [settingsPath addCurveToPoint: CGPointMake(8.76, 38) controlPoint1: CGPointMake(10.19, 42.28) controlPoint2: CGPointMake(9.32, 40.2)];
    [settingsPath addLineToPoint: CGPointMake(0, 38)];
    [settingsPath addLineToPoint: CGPointMake(0, 26)];
    [settingsPath addLineToPoint: CGPointMake(8.76, 26)];
    [settingsPath addCurveToPoint: CGPointMake(11.32, 19.81) controlPoint1: CGPointMake(9.32, 23.8) controlPoint2: CGPointMake(10.19, 21.72)];
    [settingsPath addLineToPoint: CGPointMake(5.13, 13.62)];
    [settingsPath addLineToPoint: CGPointMake(13.62, 5.13)];
    [settingsPath addLineToPoint: CGPointMake(19.81, 11.32)];
    [settingsPath addCurveToPoint: CGPointMake(26, 8.76) controlPoint1: CGPointMake(21.72, 10.19) controlPoint2: CGPointMake(23.8, 9.32)];
    [settingsPath addLineToPoint: CGPointMake(26, 0)];
    [settingsPath addLineToPoint: CGPointMake(38, 0)];
    [settingsPath addLineToPoint: CGPointMake(38, 8.76)];
    [settingsPath addCurveToPoint: CGPointMake(44.19, 11.32) controlPoint1: CGPointMake(40.2, 9.32) controlPoint2: CGPointMake(42.28, 10.19)];
    [settingsPath addLineToPoint: CGPointMake(50.38, 5.13)];
    [settingsPath addLineToPoint: CGPointMake(58.87, 13.62)];
    [settingsPath addLineToPoint: CGPointMake(52.68, 19.81)];
    [settingsPath addCurveToPoint: CGPointMake(55.24, 26) controlPoint1: CGPointMake(53.81, 21.72) controlPoint2: CGPointMake(54.68, 23.8)];
    [settingsPath addLineToPoint: CGPointMake(64, 26)];
    [settingsPath addLineToPoint: CGPointMake(64, 38)];
    [settingsPath addLineToPoint: CGPointMake(55.24, 38)];
    [settingsPath addCurveToPoint: CGPointMake(52.68, 44.19) controlPoint1: CGPointMake(54.68, 40.2) controlPoint2: CGPointMake(53.81, 42.28)];
    [settingsPath addLineToPoint: CGPointMake(58.87, 50.38)];
    [settingsPath addLineToPoint: CGPointMake(50.38, 58.87)];
    [settingsPath addLineToPoint: CGPointMake(44.19, 52.68)];
    [settingsPath addCurveToPoint: CGPointMake(38, 55.24) controlPoint1: CGPointMake(42.28, 53.81) controlPoint2: CGPointMake(40.2, 54.68)];
    [settingsPath addLineToPoint: CGPointMake(38, 64)];
    [settingsPath addLineToPoint: CGPointMake(26, 64)];
    [settingsPath addLineToPoint: CGPointMake(26, 55.24)];
    [settingsPath addCurveToPoint: CGPointMake(19.81, 52.68) controlPoint1: CGPointMake(23.8, 54.68) controlPoint2: CGPointMake(21.72, 53.81)];
    [settingsPath addLineToPoint: CGPointMake(13.62, 58.87)];
    [settingsPath addLineToPoint: CGPointMake(5.13, 50.38)];
    [settingsPath addLineToPoint: CGPointMake(11.32, 44.19)];
    [settingsPath addLineToPoint: CGPointMake(11.32, 44.19)];
    [settingsPath closePath];
    [settingsPath moveToPoint: CGPointMake(32, 48)];
    [settingsPath addCurveToPoint: CGPointMake(48, 32) controlPoint1: CGPointMake(40.84, 48) controlPoint2: CGPointMake(48, 40.84)];
    [settingsPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(48, 23.16) controlPoint2: CGPointMake(40.84, 16)];
    [settingsPath addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(23.16, 16) controlPoint2: CGPointMake(16, 23.16)];
    [settingsPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(16, 40.84) controlPoint2: CGPointMake(23.16, 48)];
    [settingsPath addLineToPoint: CGPointMake(32, 48)];
    [settingsPath closePath];
    settingsPath.miterLimit = 4;

    settingsPath.usesEvenOddFillRule = YES;

    [color setFill];
    [settingsPath fill];
}

+ (void)drawIcon_0x132_32ptWithColor: (UIColor*)color
{

    //// Pause Drawing
    UIBezierPath* pausePath = [UIBezierPath bezierPath];
    [pausePath moveToPoint: CGPointMake(16, 0)];
    [pausePath addLineToPoint: CGPointMake(24, 0)];
    [pausePath addLineToPoint: CGPointMake(24, 64)];
    [pausePath addLineToPoint: CGPointMake(16, 64)];
    [pausePath addLineToPoint: CGPointMake(16, 0)];
    [pausePath addLineToPoint: CGPointMake(16, 0)];
    [pausePath closePath];
    [pausePath moveToPoint: CGPointMake(40, 0)];
    [pausePath addLineToPoint: CGPointMake(48, 0)];
    [pausePath addLineToPoint: CGPointMake(48, 64)];
    [pausePath addLineToPoint: CGPointMake(40, 64)];
    [pausePath addLineToPoint: CGPointMake(40, 0)];
    [pausePath addLineToPoint: CGPointMake(40, 0)];
    [pausePath closePath];
    pausePath.miterLimit = 4;

    pausePath.usesEvenOddFillRule = YES;

    [color setFill];
    [pausePath fill];
}

+ (void)drawIcon_0x1420_28ptWithColor: (UIColor*)color
{

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0, 0, 56, 56)];
    [color setFill];
    [ovalPath fill];


    //// Contact Drawing
    UIBezierPath* contactPath = [UIBezierPath bezierPath];
    [contactPath moveToPoint: CGPointMake(35.22, 32)];
    [contactPath addLineToPoint: CGPointMake(35.99, 32)];
    [contactPath addCurveToPoint: CGPointMake(42, 38) controlPoint1: CGPointMake(39.31, 32) controlPoint2: CGPointMake(42, 34.69)];
    [contactPath addLineToPoint: CGPointMake(42, 40.54)];
    [contactPath addLineToPoint: CGPointMake(42, 40.54)];
    [contactPath addCurveToPoint: CGPointMake(28, 44) controlPoint1: CGPointMake(37.82, 42.75) controlPoint2: CGPointMake(33.06, 44)];
    [contactPath addCurveToPoint: CGPointMake(14, 40.54) controlPoint1: CGPointMake(22.94, 44) controlPoint2: CGPointMake(18.18, 42.75)];
    [contactPath addLineToPoint: CGPointMake(14, 38)];
    [contactPath addCurveToPoint: CGPointMake(20.01, 32) controlPoint1: CGPointMake(14, 34.69) controlPoint2: CGPointMake(16.68, 32)];
    [contactPath addLineToPoint: CGPointMake(20.78, 32)];
    [contactPath addCurveToPoint: CGPointMake(28, 34) controlPoint1: CGPointMake(22.89, 33.27) controlPoint2: CGPointMake(25.36, 34)];
    [contactPath addCurveToPoint: CGPointMake(35.22, 32) controlPoint1: CGPointMake(30.64, 34) controlPoint2: CGPointMake(33.11, 33.27)];
    [contactPath addLineToPoint: CGPointMake(35.22, 32)];
    [contactPath closePath];
    [contactPath moveToPoint: CGPointMake(28, 28)];
    [contactPath addCurveToPoint: CGPointMake(36, 20) controlPoint1: CGPointMake(32.42, 28) controlPoint2: CGPointMake(36, 24.42)];
    [contactPath addCurveToPoint: CGPointMake(28, 12) controlPoint1: CGPointMake(36, 15.58) controlPoint2: CGPointMake(32.42, 12)];
    [contactPath addCurveToPoint: CGPointMake(20, 20) controlPoint1: CGPointMake(23.58, 12) controlPoint2: CGPointMake(20, 15.58)];
    [contactPath addCurveToPoint: CGPointMake(28, 28) controlPoint1: CGPointMake(20, 24.42) controlPoint2: CGPointMake(23.58, 28)];
    [contactPath closePath];
    contactPath.miterLimit = 4;

    contactPath.usesEvenOddFillRule = YES;

    [UIColor.whiteColor setFill];
    [contactPath fill];
}

+ (void)drawIcon_0x110_32ptWithColor: (UIColor*)color
{

    //// Back Drawing
    UIBezierPath* backPath = [UIBezierPath bezierPath];
    [backPath moveToPoint: CGPointMake(19.78, 36.27)];
    [backPath addLineToPoint: CGPointMake(39.99, 56.22)];
    [backPath addLineToPoint: CGPointMake(34.53, 61.6)];
    [backPath addLineToPoint: CGPointMake(5, 32.45)];
    [backPath addLineToPoint: CGPointMake(34.53, 3.29)];
    [backPath addLineToPoint: CGPointMake(39.99, 8.68)];
    [backPath addLineToPoint: CGPointMake(19.75, 28.65)];
    [backPath addLineToPoint: CGPointMake(59, 28.65)];
    [backPath addLineToPoint: CGPointMake(59, 36.27)];
    [backPath addLineToPoint: CGPointMake(19.78, 36.27)];
    [backPath addLineToPoint: CGPointMake(19.78, 36.27)];
    [backPath closePath];
    backPath.miterLimit = 4;

    backPath.usesEvenOddFillRule = YES;

    [color setFill];
    [backPath fill];
}

+ (void)drawIcon_0x103_32ptWithColor: (UIColor*)color
{

    //// Close Drawing
    UIBezierPath* closePath = [UIBezierPath bezierPath];
    [closePath moveToPoint: CGPointMake(11.52, 58)];
    [closePath addLineToPoint: CGPointMake(32, 37.52)];
    [closePath addLineToPoint: CGPointMake(52.48, 58)];
    [closePath addLineToPoint: CGPointMake(58, 52.48)];
    [closePath addLineToPoint: CGPointMake(37.52, 32)];
    [closePath addLineToPoint: CGPointMake(58, 11.52)];
    [closePath addLineToPoint: CGPointMake(52.48, 6)];
    [closePath addLineToPoint: CGPointMake(32, 26.48)];
    [closePath addLineToPoint: CGPointMake(11.52, 6)];
    [closePath addLineToPoint: CGPointMake(6, 11.52)];
    [closePath addLineToPoint: CGPointMake(26.48, 32)];
    [closePath addLineToPoint: CGPointMake(6, 52.48)];
    [closePath addLineToPoint: CGPointMake(11.52, 58)];
    [closePath closePath];
    closePath.miterLimit = 4;

    closePath.usesEvenOddFillRule = YES;

    [color setFill];
    [closePath fill];
}

+ (void)drawIcon_0x211_32ptWithColor: (UIColor*)color
{

    //// Call Drawing
    UIBezierPath* callPath = [UIBezierPath bezierPath];
    [callPath moveToPoint: CGPointMake(50.85, 64)];
    [callPath addLineToPoint: CGPointMake(50.85, 64)];
    [callPath addCurveToPoint: CGPointMake(63.67, 50.49) controlPoint1: CGPointMake(56.04, 64) controlPoint2: CGPointMake(61.44, 58.16)];
    [callPath addCurveToPoint: CGPointMake(62.61, 48.13) controlPoint1: CGPointMake(64.19, 48.7) controlPoint2: CGPointMake(64.26, 48.85)];
    [callPath addCurveToPoint: CGPointMake(53.32, 43.89) controlPoint1: CGPointMake(60.36, 47.13) controlPoint2: CGPointMake(57.76, 45.94)];
    [callPath addCurveToPoint: CGPointMake(47.63, 41.33) controlPoint1: CGPointMake(51.23, 42.96) controlPoint2: CGPointMake(49.12, 42.01)];
    [callPath addCurveToPoint: CGPointMake(46.16, 40.82) controlPoint1: CGPointMake(46.7, 40.92) controlPoint2: CGPointMake(46.37, 40.82)];
    [callPath addCurveToPoint: CGPointMake(45.61, 41.1) controlPoint1: CGPointMake(46.05, 40.82) controlPoint2: CGPointMake(45.89, 40.89)];
    [callPath addCurveToPoint: CGPointMake(45.03, 41.64) controlPoint1: CGPointMake(45.45, 41.23) controlPoint2: CGPointMake(45.31, 41.36)];
    [callPath addLineToPoint: CGPointMake(41.4, 45.27)];
    [callPath addLineToPoint: CGPointMake(38.89, 47.79)];
    [callPath addLineToPoint: CGPointMake(35.83, 45.97)];
    [callPath addCurveToPoint: CGPointMake(25.81, 38.17) controlPoint1: CGPointMake(32.47, 43.96) controlPoint2: CGPointMake(29.01, 41.38)];
    [callPath addCurveToPoint: CGPointMake(18.02, 28.18) controlPoint1: CGPointMake(22.59, 34.95) controlPoint2: CGPointMake(19.98, 31.47)];
    [callPath addLineToPoint: CGPointMake(16.21, 25.14)];
    [callPath addLineToPoint: CGPointMake(18.69, 22.62)];
    [callPath addLineToPoint: CGPointMake(22.36, 18.91)];
    [callPath addCurveToPoint: CGPointMake(22.7, 16.39) controlPoint1: CGPointMake(23.38, 17.9) controlPoint2: CGPointMake(23.38, 17.93)];
    [callPath addCurveToPoint: CGPointMake(20.12, 10.73) controlPoint1: CGPointMake(22.13, 15.11) controlPoint2: CGPointMake(21.33, 13.34)];
    [callPath addCurveToPoint: CGPointMake(15.82, 1.3) controlPoint1: CGPointMake(18.05, 6.23) controlPoint2: CGPointMake(16.86, 3.62)];
    [callPath addCurveToPoint: CGPointMake(14.93, 0) controlPoint1: CGPointMake(15.32, 0.13) controlPoint2: CGPointMake(15.21, 0)];
    [callPath addCurveToPoint: CGPointMake(13.51, 0.31) controlPoint1: CGPointMake(14.71, 0) controlPoint2: CGPointMake(14.29, 0.09)];
    [callPath addCurveToPoint: CGPointMake(0, 13.22) controlPoint1: CGPointMake(5.78, 2.55) controlPoint2: CGPointMake(-0.05, 7.99)];
    [callPath addCurveToPoint: CGPointMake(17.87, 46.16) controlPoint1: CGPointMake(0.08, 21.38) controlPoint2: CGPointMake(7.17, 35.45)];
    [callPath addCurveToPoint: CGPointMake(50.73, 64) controlPoint1: CGPointMake(28.54, 56.84) controlPoint2: CGPointMake(42.59, 63.92)];
    [callPath addLineToPoint: CGPointMake(50.85, 64)];
    [callPath closePath];
    callPath.miterLimit = 4;

    callPath.usesEvenOddFillRule = YES;

    [color setFill];
    [callPath fill];
}

+ (void)drawIcon_0x1000_28ptWithColor: (UIColor*)color
{

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0, 0, 56, 56)];
    [color setFill];
    [ovalPath fill];


    //// Add Drawing
    UIBezierPath* addPath = [UIBezierPath bezierPath];
    [addPath moveToPoint: CGPointMake(12, 26)];
    [addPath addLineToPoint: CGPointMake(12, 30)];
    [addPath addLineToPoint: CGPointMake(26, 30)];
    [addPath addLineToPoint: CGPointMake(26, 44)];
    [addPath addLineToPoint: CGPointMake(30, 44)];
    [addPath addLineToPoint: CGPointMake(30, 30)];
    [addPath addLineToPoint: CGPointMake(44, 30)];
    [addPath addLineToPoint: CGPointMake(44, 26)];
    [addPath addLineToPoint: CGPointMake(30, 26)];
    [addPath addLineToPoint: CGPointMake(30, 12)];
    [addPath addLineToPoint: CGPointMake(26, 12)];
    [addPath addLineToPoint: CGPointMake(26, 26)];
    [addPath addLineToPoint: CGPointMake(12, 26)];
    [addPath closePath];
    addPath.miterLimit = 4;

    addPath.usesEvenOddFillRule = YES;

    [UIColor.whiteColor setFill];
    [addPath fill];
}

+ (void)drawIcon_0x142_32ptWithColor: (UIColor*)color
{

    //// Contacts Drawing
    UIBezierPath* contactsPath = [UIBezierPath bezierPath];
    [contactsPath moveToPoint: CGPointMake(46.43, 40)];
    [contactsPath addLineToPoint: CGPointMake(47.99, 40)];
    [contactsPath addCurveToPoint: CGPointMake(60, 52) controlPoint1: CGPointMake(54.62, 40) controlPoint2: CGPointMake(60, 45.39)];
    [contactsPath addLineToPoint: CGPointMake(60, 57.08)];
    [contactsPath addLineToPoint: CGPointMake(60, 57.08)];
    [contactsPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(51.64, 61.5) controlPoint2: CGPointMake(42.11, 64)];
    [contactsPath addCurveToPoint: CGPointMake(4, 57.08) controlPoint1: CGPointMake(21.89, 64) controlPoint2: CGPointMake(12.36, 61.5)];
    [contactsPath addLineToPoint: CGPointMake(4, 52)];
    [contactsPath addCurveToPoint: CGPointMake(16.01, 40) controlPoint1: CGPointMake(4, 45.37) controlPoint2: CGPointMake(9.37, 40)];
    [contactsPath addLineToPoint: CGPointMake(17.57, 40)];
    [contactsPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(21.78, 42.54) controlPoint2: CGPointMake(26.72, 44)];
    [contactsPath addCurveToPoint: CGPointMake(46.43, 40) controlPoint1: CGPointMake(37.28, 44) controlPoint2: CGPointMake(42.22, 42.54)];
    [contactsPath addLineToPoint: CGPointMake(46.43, 40)];
    [contactsPath closePath];
    [contactsPath moveToPoint: CGPointMake(32, 32)];
    [contactsPath addCurveToPoint: CGPointMake(48, 16) controlPoint1: CGPointMake(40.84, 32) controlPoint2: CGPointMake(48, 24.84)];
    [contactsPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(48, 7.16) controlPoint2: CGPointMake(40.84, 0)];
    [contactsPath addCurveToPoint: CGPointMake(16, 16) controlPoint1: CGPointMake(23.16, 0) controlPoint2: CGPointMake(16, 7.16)];
    [contactsPath addCurveToPoint: CGPointMake(32, 32) controlPoint1: CGPointMake(16, 24.84) controlPoint2: CGPointMake(23.16, 32)];
    [contactsPath closePath];
    contactsPath.miterLimit = 4;

    contactsPath.usesEvenOddFillRule = YES;

    [color setFill];
    [contactsPath fill];
}

+ (void)drawIcon_0x152_32ptWithColor: (UIColor*)color
{

    //// File Drawing
    UIBezierPath* filePath = [UIBezierPath bezierPath];
    [filePath moveToPoint: CGPointMake(11.96, 0)];
    [filePath addCurveToPoint: CGPointMake(8, 4) controlPoint1: CGPointMake(9.77, 0) controlPoint2: CGPointMake(8, 1.78)];
    [filePath addLineToPoint: CGPointMake(8, 60)];
    [filePath addCurveToPoint: CGPointMake(12.01, 64) controlPoint1: CGPointMake(8, 62.21) controlPoint2: CGPointMake(9.82, 64)];
    [filePath addLineToPoint: CGPointMake(51.99, 64)];
    [filePath addCurveToPoint: CGPointMake(56, 60.02) controlPoint1: CGPointMake(54.2, 64) controlPoint2: CGPointMake(56, 62.18)];
    [filePath addLineToPoint: CGPointMake(56, 24)];
    [filePath addLineToPoint: CGPointMake(40.11, 24)];
    [filePath addCurveToPoint: CGPointMake(31.99, 15.98) controlPoint1: CGPointMake(35.62, 24) controlPoint2: CGPointMake(31.99, 20.45)];
    [filePath addLineToPoint: CGPointMake(31.99, 0)];
    [filePath addLineToPoint: CGPointMake(11.96, 0)];
    [filePath closePath];
    [filePath moveToPoint: CGPointMake(56, 20)];
    [filePath addLineToPoint: CGPointMake(41.43, 20)];
    [filePath addCurveToPoint: CGPointMake(36, 14.95) controlPoint1: CGPointMake(38.61, 20) controlPoint2: CGPointMake(36.32, 17.78)];
    [filePath addLineToPoint: CGPointMake(36, 0)];
    [filePath addLineToPoint: CGPointMake(56, 20)];
    [filePath closePath];
    filePath.usesEvenOddFillRule = YES;

    [color setFill];
    [filePath fill];
}

+ (void)drawIcon_0x185_32ptWithColor: (UIColor*)color
{

    //// View Drawing
    UIBezierPath* viewPath = [UIBezierPath bezierPath];
    [viewPath moveToPoint: CGPointMake(64, 32)];
    [viewPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(59.34, 18.02) controlPoint2: CGPointMake(46.77, 8)];
    [viewPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(17.23, 8) controlPoint2: CGPointMake(4.66, 18.02)];
    [viewPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(4.66, 45.98) controlPoint2: CGPointMake(17.23, 56)];
    [viewPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(46.77, 56) controlPoint2: CGPointMake(59.34, 45.98)];
    [viewPath addLineToPoint: CGPointMake(64, 32)];
    [viewPath closePath];
    [viewPath moveToPoint: CGPointMake(32, 44)];
    [viewPath addCurveToPoint: CGPointMake(44, 32) controlPoint1: CGPointMake(38.63, 44) controlPoint2: CGPointMake(44, 38.63)];
    [viewPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(44, 25.37) controlPoint2: CGPointMake(38.63, 20)];
    [viewPath addCurveToPoint: CGPointMake(20, 32) controlPoint1: CGPointMake(25.37, 20) controlPoint2: CGPointMake(20, 25.37)];
    [viewPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(20, 38.63) controlPoint2: CGPointMake(25.37, 44)];
    [viewPath addLineToPoint: CGPointMake(32, 44)];
    [viewPath closePath];
    viewPath.miterLimit = 4;

    viewPath.usesEvenOddFillRule = YES;

    [color setFill];
    [viewPath fill];
}

+ (void)drawIcon_0x146_32ptWithColor: (UIColor*)color
{

    //// Movie Drawing
    UIBezierPath* moviePath = [UIBezierPath bezierPath];
    [moviePath moveToPoint: CGPointMake(44, 64)];
    [moviePath addLineToPoint: CGPointMake(20, 64)];
    [moviePath addCurveToPoint: CGPointMake(16, 60) controlPoint1: CGPointMake(20, 61.79) controlPoint2: CGPointMake(18.21, 60)];
    [moviePath addCurveToPoint: CGPointMake(12, 64) controlPoint1: CGPointMake(13.79, 60) controlPoint2: CGPointMake(12, 61.79)];
    [moviePath addLineToPoint: CGPointMake(8, 64)];
    [moviePath addLineToPoint: CGPointMake(8, 0)];
    [moviePath addLineToPoint: CGPointMake(12, 0)];
    [moviePath addCurveToPoint: CGPointMake(16, 4) controlPoint1: CGPointMake(12, 2.21) controlPoint2: CGPointMake(13.79, 4)];
    [moviePath addCurveToPoint: CGPointMake(20, 0) controlPoint1: CGPointMake(18.21, 4) controlPoint2: CGPointMake(20, 2.21)];
    [moviePath addLineToPoint: CGPointMake(44, 0)];
    [moviePath addCurveToPoint: CGPointMake(48, 4) controlPoint1: CGPointMake(44, 2.21) controlPoint2: CGPointMake(45.79, 4)];
    [moviePath addCurveToPoint: CGPointMake(52, 0) controlPoint1: CGPointMake(50.21, 4) controlPoint2: CGPointMake(52, 2.21)];
    [moviePath addLineToPoint: CGPointMake(56, 0)];
    [moviePath addLineToPoint: CGPointMake(56, 64)];
    [moviePath addLineToPoint: CGPointMake(52, 64)];
    [moviePath addCurveToPoint: CGPointMake(48, 60) controlPoint1: CGPointMake(52, 61.79) controlPoint2: CGPointMake(50.21, 60)];
    [moviePath addCurveToPoint: CGPointMake(44, 64) controlPoint1: CGPointMake(45.79, 60) controlPoint2: CGPointMake(44, 61.79)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(16, 20)];
    [moviePath addCurveToPoint: CGPointMake(20, 16) controlPoint1: CGPointMake(18.21, 20) controlPoint2: CGPointMake(20, 18.21)];
    [moviePath addCurveToPoint: CGPointMake(16, 12) controlPoint1: CGPointMake(20, 13.79) controlPoint2: CGPointMake(18.21, 12)];
    [moviePath addCurveToPoint: CGPointMake(12, 16) controlPoint1: CGPointMake(13.79, 12) controlPoint2: CGPointMake(12, 13.79)];
    [moviePath addCurveToPoint: CGPointMake(16, 20) controlPoint1: CGPointMake(12, 18.21) controlPoint2: CGPointMake(13.79, 20)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(16, 36)];
    [moviePath addCurveToPoint: CGPointMake(20, 32) controlPoint1: CGPointMake(18.21, 36) controlPoint2: CGPointMake(20, 34.21)];
    [moviePath addCurveToPoint: CGPointMake(16, 28) controlPoint1: CGPointMake(20, 29.79) controlPoint2: CGPointMake(18.21, 28)];
    [moviePath addCurveToPoint: CGPointMake(12, 32) controlPoint1: CGPointMake(13.79, 28) controlPoint2: CGPointMake(12, 29.79)];
    [moviePath addCurveToPoint: CGPointMake(16, 36) controlPoint1: CGPointMake(12, 34.21) controlPoint2: CGPointMake(13.79, 36)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(16, 52)];
    [moviePath addCurveToPoint: CGPointMake(20, 48) controlPoint1: CGPointMake(18.21, 52) controlPoint2: CGPointMake(20, 50.21)];
    [moviePath addCurveToPoint: CGPointMake(16, 44) controlPoint1: CGPointMake(20, 45.79) controlPoint2: CGPointMake(18.21, 44)];
    [moviePath addCurveToPoint: CGPointMake(12, 48) controlPoint1: CGPointMake(13.79, 44) controlPoint2: CGPointMake(12, 45.79)];
    [moviePath addCurveToPoint: CGPointMake(16, 52) controlPoint1: CGPointMake(12, 50.21) controlPoint2: CGPointMake(13.79, 52)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(48, 20)];
    [moviePath addCurveToPoint: CGPointMake(52, 16) controlPoint1: CGPointMake(50.21, 20) controlPoint2: CGPointMake(52, 18.21)];
    [moviePath addCurveToPoint: CGPointMake(48, 12) controlPoint1: CGPointMake(52, 13.79) controlPoint2: CGPointMake(50.21, 12)];
    [moviePath addCurveToPoint: CGPointMake(44, 16) controlPoint1: CGPointMake(45.79, 12) controlPoint2: CGPointMake(44, 13.79)];
    [moviePath addCurveToPoint: CGPointMake(48, 20) controlPoint1: CGPointMake(44, 18.21) controlPoint2: CGPointMake(45.79, 20)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(48, 36)];
    [moviePath addCurveToPoint: CGPointMake(52, 32) controlPoint1: CGPointMake(50.21, 36) controlPoint2: CGPointMake(52, 34.21)];
    [moviePath addCurveToPoint: CGPointMake(48, 28) controlPoint1: CGPointMake(52, 29.79) controlPoint2: CGPointMake(50.21, 28)];
    [moviePath addCurveToPoint: CGPointMake(44, 32) controlPoint1: CGPointMake(45.79, 28) controlPoint2: CGPointMake(44, 29.79)];
    [moviePath addCurveToPoint: CGPointMake(48, 36) controlPoint1: CGPointMake(44, 34.21) controlPoint2: CGPointMake(45.79, 36)];
    [moviePath closePath];
    [moviePath moveToPoint: CGPointMake(48, 52)];
    [moviePath addCurveToPoint: CGPointMake(52, 48) controlPoint1: CGPointMake(50.21, 52) controlPoint2: CGPointMake(52, 50.21)];
    [moviePath addCurveToPoint: CGPointMake(48, 44) controlPoint1: CGPointMake(52, 45.79) controlPoint2: CGPointMake(50.21, 44)];
    [moviePath addCurveToPoint: CGPointMake(44, 48) controlPoint1: CGPointMake(45.79, 44) controlPoint2: CGPointMake(44, 45.79)];
    [moviePath addCurveToPoint: CGPointMake(48, 52) controlPoint1: CGPointMake(44, 50.21) controlPoint2: CGPointMake(45.79, 52)];
    [moviePath closePath];
    moviePath.usesEvenOddFillRule = YES;

    [color setFill];
    [moviePath fill];
}

+ (void)drawIcon_0x227_32ptWithColor: (UIColor*)color
{

    //// Shutter Drawing
    UIBezierPath* shutterPath = [UIBezierPath bezierPath];
    [shutterPath moveToPoint: CGPointMake(32, 60)];
    [shutterPath addLineToPoint: CGPointMake(32, 60)];
    [shutterPath addCurveToPoint: CGPointMake(60, 32) controlPoint1: CGPointMake(47.46, 60) controlPoint2: CGPointMake(60, 47.46)];
    [shutterPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(60, 16.54) controlPoint2: CGPointMake(47.46, 4)];
    [shutterPath addCurveToPoint: CGPointMake(4, 32) controlPoint1: CGPointMake(16.54, 4) controlPoint2: CGPointMake(4, 16.54)];
    [shutterPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(4, 47.46) controlPoint2: CGPointMake(16.54, 60)];
    [shutterPath addLineToPoint: CGPointMake(32, 60)];
    [shutterPath closePath];
    [shutterPath moveToPoint: CGPointMake(32, 64)];
    [shutterPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [shutterPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [shutterPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [shutterPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [shutterPath closePath];
    [shutterPath moveToPoint: CGPointMake(32, 56)];
    [shutterPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 56) controlPoint2: CGPointMake(56, 45.25)];
    [shutterPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(56, 18.75) controlPoint2: CGPointMake(45.25, 8)];
    [shutterPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [shutterPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [shutterPath closePath];
    shutterPath.miterLimit = 4;

    shutterPath.usesEvenOddFillRule = YES;

    [color setFill];
    [shutterPath fill];
}

+ (void)drawIcon_0x159_32ptWithColor: (UIColor*)color
{

    //// Microphone Drawing
    UIBezierPath* microphonePath = [UIBezierPath bezierPath];
    [microphonePath moveToPoint: CGPointMake(50.3, 47.84)];
    [microphonePath addLineToPoint: CGPointMake(56, 53.5)];
    [microphonePath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(50.11, 59.94) controlPoint2: CGPointMake(41.55, 64)];
    [microphonePath addCurveToPoint: CGPointMake(8, 53.5) controlPoint1: CGPointMake(22.45, 64) controlPoint2: CGPointMake(13.89, 59.94)];
    [microphonePath addLineToPoint: CGPointMake(8, 53.5)];
    [microphonePath addLineToPoint: CGPointMake(13.7, 47.84)];
    [microphonePath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(18.13, 52.83) controlPoint2: CGPointMake(24.68, 56)];
    [microphonePath addCurveToPoint: CGPointMake(50.3, 47.84) controlPoint1: CGPointMake(39.32, 56) controlPoint2: CGPointMake(45.87, 52.83)];
    [microphonePath addLineToPoint: CGPointMake(50.3, 47.84)];
    [microphonePath closePath];
    [microphonePath moveToPoint: CGPointMake(32, 48)];
    [microphonePath addCurveToPoint: CGPointMake(48.1, 32.27) controlPoint1: CGPointMake(40.91, 48) controlPoint2: CGPointMake(48.1, 40.92)];
    [microphonePath addLineToPoint: CGPointMake(48.1, 15.74)];
    [microphonePath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(48.1, 7.08) controlPoint2: CGPointMake(40.91, 0)];
    [microphonePath addCurveToPoint: CGPointMake(15.9, 15.74) controlPoint1: CGPointMake(23.09, 0) controlPoint2: CGPointMake(15.9, 7.08)];
    [microphonePath addLineToPoint: CGPointMake(15.9, 32.27)];
    [microphonePath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(15.9, 40.92) controlPoint2: CGPointMake(23.09, 48)];
    [microphonePath addLineToPoint: CGPointMake(32, 48)];
    [microphonePath closePath];
    [color setFill];
    [microphonePath fill];
}

+ (void)drawIcon_0x228_32ptWithColor: (UIColor*)color
{

    //// Stop Drawing
    UIBezierPath* stopPath = [UIBezierPath bezierPathWithRect: CGRectMake(8, 8, 48, 48)];
    [color setFill];
    [stopPath fill];
}

+ (void)drawIcon_0x154_32ptWithColor: (UIColor*)color
{

    //// Attachment Drawing
    UIBezierPath* attachmentPath = [UIBezierPath bezierPath];
    [attachmentPath moveToPoint: CGPointMake(10.53, 30.8)];
    [attachmentPath addLineToPoint: CGPointMake(29.48, 11.68)];
    [attachmentPath addCurveToPoint: CGPointMake(48.42, 11.68) controlPoint1: CGPointMake(34.7, 6.41) controlPoint2: CGPointMake(43.2, 6.41)];
    [attachmentPath addCurveToPoint: CGPointMake(48.42, 30.8) controlPoint1: CGPointMake(53.65, 16.96) controlPoint2: CGPointMake(53.66, 25.51)];
    [attachmentPath addLineToPoint: CGPointMake(43.01, 36.26)];
    [attachmentPath addLineToPoint: CGPointMake(25.41, 54.02)];
    [attachmentPath addCurveToPoint: CGPointMake(14.59, 54.01) controlPoint1: CGPointMake(22.43, 57.03) controlPoint2: CGPointMake(17.58, 57.03)];
    [attachmentPath addCurveToPoint: CGPointMake(14.59, 43.09) controlPoint1: CGPointMake(11.6, 51) controlPoint2: CGPointMake(11.6, 46.11)];
    [attachmentPath addLineToPoint: CGPointMake(20.01, 37.62)];
    [attachmentPath addLineToPoint: CGPointMake(37.62, 19.85)];
    [attachmentPath addCurveToPoint: CGPointMake(40.3, 19.87) controlPoint1: CGPointMake(38.36, 19.11) controlPoint2: CGPointMake(39.54, 19.11)];
    [attachmentPath addCurveToPoint: CGPointMake(40.32, 22.58) controlPoint1: CGPointMake(41.06, 20.64) controlPoint2: CGPointMake(41.06, 21.84)];
    [attachmentPath addLineToPoint: CGPointMake(21.33, 41.75)];
    [attachmentPath addCurveToPoint: CGPointMake(21.33, 47.21) controlPoint1: CGPointMake(19.84, 43.26) controlPoint2: CGPointMake(19.84, 45.71)];
    [attachmentPath addCurveToPoint: CGPointMake(26.74, 47.21) controlPoint1: CGPointMake(22.83, 48.72) controlPoint2: CGPointMake(25.25, 48.72)];
    [attachmentPath addLineToPoint: CGPointMake(45.74, 28.04)];
    [attachmentPath addCurveToPoint: CGPointMake(45.71, 14.41) controlPoint1: CGPointMake(49.47, 24.27) controlPoint2: CGPointMake(49.45, 18.18)];
    [attachmentPath addCurveToPoint: CGPointMake(32.21, 14.39) controlPoint1: CGPointMake(41.97, 10.63) controlPoint2: CGPointMake(35.94, 10.62)];
    [attachmentPath addLineToPoint: CGPointMake(14.6, 32.16)];
    [attachmentPath addLineToPoint: CGPointMake(9.18, 37.63)];
    [attachmentPath addCurveToPoint: CGPointMake(9.18, 59.48) controlPoint1: CGPointMake(3.2, 43.66) controlPoint2: CGPointMake(3.2, 53.44)];
    [attachmentPath addCurveToPoint: CGPointMake(30.83, 59.48) controlPoint1: CGPointMake(15.15, 65.5) controlPoint2: CGPointMake(24.85, 65.51)];
    [attachmentPath addLineToPoint: CGPointMake(48.42, 41.73)];
    [attachmentPath addLineToPoint: CGPointMake(53.83, 36.26)];
    [attachmentPath addCurveToPoint: CGPointMake(53.83, 6.22) controlPoint1: CGPointMake(62.06, 27.96) controlPoint2: CGPointMake(62.05, 14.52)];
    [attachmentPath addCurveToPoint: CGPointMake(24.07, 6.22) controlPoint1: CGPointMake(45.62, -2.07) controlPoint2: CGPointMake(32.28, -2.08)];
    [attachmentPath addLineToPoint: CGPointMake(5.12, 25.34)];
    [attachmentPath addCurveToPoint: CGPointMake(5.12, 30.8) controlPoint1: CGPointMake(3.63, 26.85) controlPoint2: CGPointMake(3.63, 29.29)];
    [attachmentPath addCurveToPoint: CGPointMake(10.53, 30.8) controlPoint1: CGPointMake(6.62, 32.31) controlPoint2: CGPointMake(9.04, 32.31)];
    [attachmentPath addLineToPoint: CGPointMake(10.53, 30.8)];
    [attachmentPath closePath];
    attachmentPath.miterLimit = 4;

    attachmentPath.usesEvenOddFillRule = YES;

    [color setFill];
    [attachmentPath fill];
}

+ (void)drawIcon_0x148_32ptWithColor: (UIColor*)color
{

    //// Location Drawing
    UIBezierPath* locationPath = [UIBezierPath bezierPath];
    [locationPath moveToPoint: CGPointMake(56, 24)];
    [locationPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(56, 10.75) controlPoint2: CGPointMake(45.25, 0)];
    [locationPath addCurveToPoint: CGPointMake(8, 24) controlPoint1: CGPointMake(18.75, 0) controlPoint2: CGPointMake(8, 10.75)];
    [locationPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(8, 48) controlPoint2: CGPointMake(32, 64)];
    [locationPath addCurveToPoint: CGPointMake(56, 24) controlPoint1: CGPointMake(32, 64) controlPoint2: CGPointMake(56, 48)];
    [locationPath addLineToPoint: CGPointMake(56, 24)];
    [locationPath closePath];
    [locationPath moveToPoint: CGPointMake(32, 36)];
    [locationPath addCurveToPoint: CGPointMake(44, 24) controlPoint1: CGPointMake(38.63, 36) controlPoint2: CGPointMake(44, 30.63)];
    [locationPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(44, 17.37) controlPoint2: CGPointMake(38.63, 12)];
    [locationPath addCurveToPoint: CGPointMake(20, 24) controlPoint1: CGPointMake(25.37, 12) controlPoint2: CGPointMake(20, 17.37)];
    [locationPath addCurveToPoint: CGPointMake(32, 36) controlPoint1: CGPointMake(20, 30.63) controlPoint2: CGPointMake(25.37, 36)];
    [locationPath addLineToPoint: CGPointMake(32, 36)];
    [locationPath closePath];
    locationPath.usesEvenOddFillRule = YES;

    [color setFill];
    [locationPath fill];
}

+ (void)drawIcon_0x229_32ptWithColor: (UIColor*)color
{

    //// Record Drawing
    UIBezierPath* recordPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0, 0, 64, 64)];
    [color setFill];
    [recordPath fill];
}

+ (void)drawIcon_0x230_32ptWithColor: (UIColor*)color
{

    //// Stop Drawing
    UIBezierPath* stopPath = [UIBezierPath bezierPath];
    [stopPath moveToPoint: CGPointMake(0, 7.98)];
    [stopPath addCurveToPoint: CGPointMake(7.98, 0) controlPoint1: CGPointMake(0, 3.57) controlPoint2: CGPointMake(3.58, 0)];
    [stopPath addLineToPoint: CGPointMake(56.02, 0)];
    [stopPath addCurveToPoint: CGPointMake(64, 7.98) controlPoint1: CGPointMake(60.43, 0) controlPoint2: CGPointMake(64, 3.58)];
    [stopPath addLineToPoint: CGPointMake(64, 56.02)];
    [stopPath addCurveToPoint: CGPointMake(56.02, 64) controlPoint1: CGPointMake(64, 60.43) controlPoint2: CGPointMake(60.42, 64)];
    [stopPath addLineToPoint: CGPointMake(7.98, 64)];
    [stopPath addCurveToPoint: CGPointMake(0, 56.02) controlPoint1: CGPointMake(3.57, 64) controlPoint2: CGPointMake(0, 60.42)];
    [stopPath addLineToPoint: CGPointMake(0, 7.98)];
    [stopPath closePath];
    stopPath.usesEvenOddFillRule = YES;

    [color setFill];
    [stopPath fill];
}

+ (void)drawIcon_0x149_32ptWithColor: (UIColor*)color
{

    //// Locate Drawing
    UIBezierPath* locatePath = [UIBezierPath bezierPath];
    [locatePath moveToPoint: CGPointMake(0, 34)];
    [locatePath addLineToPoint: CGPointMake(60, 4)];
    [locatePath addLineToPoint: CGPointMake(30, 64)];
    [locatePath addLineToPoint: CGPointMake(22.5, 41.5)];
    [locatePath addLineToPoint: CGPointMake(0, 34)];
    [locatePath closePath];
    locatePath.usesEvenOddFillRule = YES;

    [color setFill];
    [locatePath fill];
}

+ (void)drawIcon_0x240_32ptWithColor: (UIColor*)color
{

    //// Helium Drawing
    UIBezierPath* heliumPath = [UIBezierPath bezierPath];
    [heliumPath moveToPoint: CGPointMake(32, 0)];
    [heliumPath addCurveToPoint: CGPointMake(8, 22) controlPoint1: CGPointMake(16.83, 0) controlPoint2: CGPointMake(8, 7.64)];
    [heliumPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(8, 36.36) controlPoint2: CGPointMake(18.75, 52)];
    [heliumPath addCurveToPoint: CGPointMake(56, 22) controlPoint1: CGPointMake(45.25, 52) controlPoint2: CGPointMake(56, 36.36)];
    [heliumPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(56, 7.64) controlPoint2: CGPointMake(47.17, 0)];
    [heliumPath closePath];
    [heliumPath moveToPoint: CGPointMake(26.47, 60.65)];
    [heliumPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(26.47, 60.65) controlPoint2: CGPointMake(28, 56)];
    [heliumPath addCurveToPoint: CGPointMake(37.56, 60.7) controlPoint1: CGPointMake(36, 56) controlPoint2: CGPointMake(37.56, 60.7)];
    [heliumPath addCurveToPoint: CGPointMake(36.17, 64) controlPoint1: CGPointMake(38.49, 62.52) controlPoint2: CGPointMake(37.91, 64)];
    [heliumPath addLineToPoint: CGPointMake(27.83, 64)];
    [heliumPath addCurveToPoint: CGPointMake(26.47, 60.65) controlPoint1: CGPointMake(26.13, 64) controlPoint2: CGPointMake(25.47, 62.46)];
    [heliumPath closePath];
    heliumPath.usesEvenOddFillRule = YES;

    [color setFill];
    [heliumPath fill];
}

+ (void)drawIcon_0x244_32ptWithColor: (UIColor*)color
{

    //// Cathedral Drawing
    UIBezierPath* cathedralPath = [UIBezierPath bezierPath];
    [cathedralPath moveToPoint: CGPointMake(8, 28)];
    [cathedralPath addLineToPoint: CGPointMake(0, 32)];
    [cathedralPath addLineToPoint: CGPointMake(0, 64)];
    [cathedralPath addLineToPoint: CGPointMake(8, 64)];
    [cathedralPath addLineToPoint: CGPointMake(8, 28)];
    [cathedralPath addLineToPoint: CGPointMake(8, 28)];
    [cathedralPath addLineToPoint: CGPointMake(8, 28)];
    [cathedralPath closePath];
    [cathedralPath moveToPoint: CGPointMake(52, 16)];
    [cathedralPath addLineToPoint: CGPointMake(32, 0)];
    [cathedralPath addLineToPoint: CGPointMake(12, 16)];
    [cathedralPath addLineToPoint: CGPointMake(12, 64)];
    [cathedralPath addLineToPoint: CGPointMake(24, 64)];
    [cathedralPath addLineToPoint: CGPointMake(24, 48)];
    [cathedralPath addCurveToPoint: CGPointMake(32, 40) controlPoint1: CGPointMake(24, 43.58) controlPoint2: CGPointMake(27.55, 40)];
    [cathedralPath addCurveToPoint: CGPointMake(40, 48) controlPoint1: CGPointMake(36.42, 40) controlPoint2: CGPointMake(40, 43.55)];
    [cathedralPath addLineToPoint: CGPointMake(40, 64)];
    [cathedralPath addLineToPoint: CGPointMake(52, 64)];
    [cathedralPath addLineToPoint: CGPointMake(52, 16)];
    [cathedralPath addLineToPoint: CGPointMake(52, 16)];
    [cathedralPath closePath];
    [cathedralPath moveToPoint: CGPointMake(56, 28)];
    [cathedralPath addLineToPoint: CGPointMake(64, 32)];
    [cathedralPath addLineToPoint: CGPointMake(64, 64)];
    [cathedralPath addLineToPoint: CGPointMake(56, 64)];
    [cathedralPath addLineToPoint: CGPointMake(56, 28)];
    [cathedralPath addLineToPoint: CGPointMake(56, 28)];
    [cathedralPath closePath];
    [cathedralPath moveToPoint: CGPointMake(32, 28)];
    [cathedralPath addCurveToPoint: CGPointMake(36, 24) controlPoint1: CGPointMake(34.21, 28) controlPoint2: CGPointMake(36, 26.21)];
    [cathedralPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(36, 21.79) controlPoint2: CGPointMake(34.21, 20)];
    [cathedralPath addCurveToPoint: CGPointMake(28, 24) controlPoint1: CGPointMake(29.79, 20) controlPoint2: CGPointMake(28, 21.79)];
    [cathedralPath addCurveToPoint: CGPointMake(32, 28) controlPoint1: CGPointMake(28, 26.21) controlPoint2: CGPointMake(29.79, 28)];
    [cathedralPath addLineToPoint: CGPointMake(32, 28)];
    [cathedralPath closePath];
    cathedralPath.usesEvenOddFillRule = YES;

    [color setFill];
    [cathedralPath fill];
}

+ (void)drawIcon_0x246_32ptWithColor: (UIColor*)color
{

    //// Robot Drawing
    UIBezierPath* robotPath = [UIBezierPath bezierPath];
    [robotPath moveToPoint: CGPointMake(32, 12)];
    [robotPath addCurveToPoint: CGPointMake(8.33, 32) controlPoint1: CGPointMake(20.13, 12) controlPoint2: CGPointMake(10.24, 20.65)];
    [robotPath addLineToPoint: CGPointMake(6, 32)];
    [robotPath addCurveToPoint: CGPointMake(0, 38) controlPoint1: CGPointMake(2.66, 32) controlPoint2: CGPointMake(0, 34.69)];
    [robotPath addCurveToPoint: CGPointMake(6, 44) controlPoint1: CGPointMake(0, 41.34) controlPoint2: CGPointMake(2.69, 44)];
    [robotPath addLineToPoint: CGPointMake(8, 44)];
    [robotPath addLineToPoint: CGPointMake(8, 64)];
    [robotPath addLineToPoint: CGPointMake(56, 64)];
    [robotPath addLineToPoint: CGPointMake(56, 44)];
    [robotPath addLineToPoint: CGPointMake(58, 44)];
    [robotPath addCurveToPoint: CGPointMake(64, 38) controlPoint1: CGPointMake(61.34, 44) controlPoint2: CGPointMake(64, 41.31)];
    [robotPath addCurveToPoint: CGPointMake(58, 32) controlPoint1: CGPointMake(64, 34.66) controlPoint2: CGPointMake(61.31, 32)];
    [robotPath addLineToPoint: CGPointMake(55.67, 32)];
    [robotPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(53.76, 20.67) controlPoint2: CGPointMake(43.89, 12)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(12, 14.4)];
    [robotPath addCurveToPoint: CGPointMake(14, 12.4) controlPoint1: CGPointMake(13.1, 14.4) controlPoint2: CGPointMake(14, 13.5)];
    [robotPath addCurveToPoint: CGPointMake(12, 10.4) controlPoint1: CGPointMake(14, 11.3) controlPoint2: CGPointMake(13.1, 10.4)];
    [robotPath addCurveToPoint: CGPointMake(10, 12.4) controlPoint1: CGPointMake(10.9, 10.4) controlPoint2: CGPointMake(10, 11.3)];
    [robotPath addCurveToPoint: CGPointMake(12, 14.4) controlPoint1: CGPointMake(10, 13.5) controlPoint2: CGPointMake(10.9, 14.4)];
    [robotPath addLineToPoint: CGPointMake(12, 14.4)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(52, 14)];
    [robotPath addCurveToPoint: CGPointMake(54, 12) controlPoint1: CGPointMake(53.1, 14) controlPoint2: CGPointMake(54, 13.1)];
    [robotPath addCurveToPoint: CGPointMake(52, 10) controlPoint1: CGPointMake(54, 10.9) controlPoint2: CGPointMake(53.1, 10)];
    [robotPath addCurveToPoint: CGPointMake(50, 12) controlPoint1: CGPointMake(50.9, 10) controlPoint2: CGPointMake(50, 10.9)];
    [robotPath addCurveToPoint: CGPointMake(52, 14) controlPoint1: CGPointMake(50, 13.1) controlPoint2: CGPointMake(50.9, 14)];
    [robotPath addLineToPoint: CGPointMake(52, 14)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(60, 8)];
    [robotPath addCurveToPoint: CGPointMake(64, 4) controlPoint1: CGPointMake(62.21, 8) controlPoint2: CGPointMake(64, 6.21)];
    [robotPath addCurveToPoint: CGPointMake(60, 0) controlPoint1: CGPointMake(64, 1.79) controlPoint2: CGPointMake(62.21, 0)];
    [robotPath addCurveToPoint: CGPointMake(56, 4) controlPoint1: CGPointMake(57.79, 0) controlPoint2: CGPointMake(56, 1.79)];
    [robotPath addCurveToPoint: CGPointMake(60, 8) controlPoint1: CGPointMake(56, 6.21) controlPoint2: CGPointMake(57.79, 8)];
    [robotPath addLineToPoint: CGPointMake(60, 8)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(4, 8)];
    [robotPath addCurveToPoint: CGPointMake(8, 4) controlPoint1: CGPointMake(6.21, 8) controlPoint2: CGPointMake(8, 6.21)];
    [robotPath addCurveToPoint: CGPointMake(4, 0) controlPoint1: CGPointMake(8, 1.79) controlPoint2: CGPointMake(6.21, 0)];
    [robotPath addCurveToPoint: CGPointMake(0, 4) controlPoint1: CGPointMake(1.79, 0) controlPoint2: CGPointMake(0, 1.79)];
    [robotPath addCurveToPoint: CGPointMake(4, 8) controlPoint1: CGPointMake(0, 6.21) controlPoint2: CGPointMake(1.79, 8)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(22, 44)];
    [robotPath addCurveToPoint: CGPointMake(28, 38) controlPoint1: CGPointMake(25.31, 44) controlPoint2: CGPointMake(28, 41.31)];
    [robotPath addCurveToPoint: CGPointMake(22, 32) controlPoint1: CGPointMake(28, 34.69) controlPoint2: CGPointMake(25.31, 32)];
    [robotPath addCurveToPoint: CGPointMake(16, 38) controlPoint1: CGPointMake(18.69, 32) controlPoint2: CGPointMake(16, 34.69)];
    [robotPath addCurveToPoint: CGPointMake(22, 44) controlPoint1: CGPointMake(16, 41.31) controlPoint2: CGPointMake(18.69, 44)];
    [robotPath closePath];
    [robotPath moveToPoint: CGPointMake(42, 44)];
    [robotPath addCurveToPoint: CGPointMake(48, 38) controlPoint1: CGPointMake(45.31, 44) controlPoint2: CGPointMake(48, 41.31)];
    [robotPath addCurveToPoint: CGPointMake(42, 32) controlPoint1: CGPointMake(48, 34.69) controlPoint2: CGPointMake(45.31, 32)];
    [robotPath addCurveToPoint: CGPointMake(36, 38) controlPoint1: CGPointMake(38.69, 32) controlPoint2: CGPointMake(36, 34.69)];
    [robotPath addCurveToPoint: CGPointMake(42, 44) controlPoint1: CGPointMake(36, 41.31) controlPoint2: CGPointMake(38.69, 44)];
    [robotPath closePath];
    robotPath.usesEvenOddFillRule = YES;

    [color setFill];
    [robotPath fill];
}

+ (void)drawIcon_0x245_32ptWithColor: (UIColor*)color
{

    //// Alien Drawing
    UIBezierPath* alienPath = [UIBezierPath bezierPath];
    [alienPath moveToPoint: CGPointMake(32, 64)];
    [alienPath addCurveToPoint: CGPointMake(60, 24) controlPoint1: CGPointMake(36.07, 64) controlPoint2: CGPointMake(60, 41.67)];
    [alienPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(60, 6.33) controlPoint2: CGPointMake(45.25, 0)];
    [alienPath addCurveToPoint: CGPointMake(4, 24) controlPoint1: CGPointMake(18.75, 0) controlPoint2: CGPointMake(4, 6.33)];
    [alienPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(4, 41.67) controlPoint2: CGPointMake(27.93, 64)];
    [alienPath closePath];
    [alienPath moveToPoint: CGPointMake(17.38, 37.76)];
    [alienPath addCurveToPoint: CGPointMake(27.56, 37.55) controlPoint1: CGPointMake(21.56, 40.83) controlPoint2: CGPointMake(26.11, 40.73)];
    [alienPath addCurveToPoint: CGPointMake(22.62, 26.24) controlPoint1: CGPointMake(29, 34.36) controlPoint2: CGPointMake(26.79, 29.3)];
    [alienPath addCurveToPoint: CGPointMake(12.44, 26.45) controlPoint1: CGPointMake(18.44, 23.17) controlPoint2: CGPointMake(13.89, 23.27)];
    [alienPath addCurveToPoint: CGPointMake(17.38, 37.76) controlPoint1: CGPointMake(11, 29.64) controlPoint2: CGPointMake(13.21, 34.7)];
    [alienPath closePath];
    [alienPath moveToPoint: CGPointMake(36.44, 37.55)];
    [alienPath addCurveToPoint: CGPointMake(41.38, 26.24) controlPoint1: CGPointMake(35, 34.36) controlPoint2: CGPointMake(37.21, 29.3)];
    [alienPath addCurveToPoint: CGPointMake(51.56, 26.45) controlPoint1: CGPointMake(45.56, 23.17) controlPoint2: CGPointMake(50.11, 23.27)];
    [alienPath addCurveToPoint: CGPointMake(46.62, 37.76) controlPoint1: CGPointMake(53, 29.64) controlPoint2: CGPointMake(50.79, 34.7)];
    [alienPath addCurveToPoint: CGPointMake(36.44, 37.55) controlPoint1: CGPointMake(42.44, 40.83) controlPoint2: CGPointMake(37.89, 40.73)];
    [alienPath closePath];
    alienPath.usesEvenOddFillRule = YES;

    [color setFill];
    [alienPath fill];
}

+ (void)drawIcon_0x242_32ptWithColor: (UIColor*)color
{

    //// Jellyfish Drawing
    UIBezierPath* jellyfishPath = [UIBezierPath bezierPath];
    [jellyfishPath moveToPoint: CGPointMake(4.28, 32.01)];
    [jellyfishPath addCurveToPoint: CGPointMake(4, 28.01) controlPoint1: CGPointMake(4.1, 30.7) controlPoint2: CGPointMake(4, 29.37)];
    [jellyfishPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(4, 12.54) controlPoint2: CGPointMake(16.54, 0)];
    [jellyfishPath addCurveToPoint: CGPointMake(60, 28.01) controlPoint1: CGPointMake(47.46, 0) controlPoint2: CGPointMake(60, 12.54)];
    [jellyfishPath addCurveToPoint: CGPointMake(59.72, 32.01) controlPoint1: CGPointMake(60, 29.37) controlPoint2: CGPointMake(59.9, 30.7)];
    [jellyfishPath addLineToPoint: CGPointMake(4.28, 32.01)];
    [jellyfishPath closePath];
    [jellyfishPath moveToPoint: CGPointMake(36.08, 36.01)];
    [jellyfishPath addLineToPoint: CGPointMake(36.08, 60)];
    [jellyfishPath addCurveToPoint: CGPointMake(32.08, 64) controlPoint1: CGPointMake(36.08, 62.21) controlPoint2: CGPointMake(34.29, 64)];
    [jellyfishPath addCurveToPoint: CGPointMake(28.08, 60) controlPoint1: CGPointMake(29.87, 64) controlPoint2: CGPointMake(28.08, 62.21)];
    [jellyfishPath addLineToPoint: CGPointMake(28.08, 36.01)];
    [jellyfishPath addLineToPoint: CGPointMake(36.08, 36.01)];
    [jellyfishPath closePath];
    [jellyfishPath moveToPoint: CGPointMake(48.06, 36.01)];
    [jellyfishPath addCurveToPoint: CGPointMake(48.57, 41.9) controlPoint1: CGPointMake(48.14, 38.48) controlPoint2: CGPointMake(48.31, 40.48)];
    [jellyfishPath addCurveToPoint: CGPointMake(51.53, 49.04) controlPoint1: CGPointMake(49.01, 44.32) controlPoint2: CGPointMake(50.06, 46.73)];
    [jellyfishPath addCurveToPoint: CGPointMake(53.83, 52.11) controlPoint1: CGPointMake(52.26, 50.18) controlPoint2: CGPointMake(53.05, 51.21)];
    [jellyfishPath addCurveToPoint: CGPointMake(54.76, 53.12) controlPoint1: CGPointMake(54.28, 52.64) controlPoint2: CGPointMake(54.61, 52.98)];
    [jellyfishPath addCurveToPoint: CGPointMake(54.9, 58.78) controlPoint1: CGPointMake(56.36, 54.65) controlPoint2: CGPointMake(56.42, 57.18)];
    [jellyfishPath addCurveToPoint: CGPointMake(49.24, 58.92) controlPoint1: CGPointMake(53.37, 60.38) controlPoint2: CGPointMake(50.84, 60.44)];
    [jellyfishPath addCurveToPoint: CGPointMake(44.8, 53.35) controlPoint1: CGPointMake(48.07, 57.8) controlPoint2: CGPointMake(46.43, 55.9)];
    [jellyfishPath addCurveToPoint: CGPointMake(40.7, 43.34) controlPoint1: CGPointMake(42.8, 50.23) controlPoint2: CGPointMake(41.35, 46.89)];
    [jellyfishPath addCurveToPoint: CGPointMake(40.05, 36.01) controlPoint1: CGPointMake(40.35, 41.44) controlPoint2: CGPointMake(40.14, 38.97)];
    [jellyfishPath addLineToPoint: CGPointMake(48.06, 36.01)];
    [jellyfishPath addLineToPoint: CGPointMake(48.06, 36.01)];
    [jellyfishPath closePath];
    [jellyfishPath moveToPoint: CGPointMake(23.95, 36.01)];
    [jellyfishPath addCurveToPoint: CGPointMake(23.3, 43.34) controlPoint1: CGPointMake(23.86, 38.97) controlPoint2: CGPointMake(23.65, 41.44)];
    [jellyfishPath addCurveToPoint: CGPointMake(19.2, 53.35) controlPoint1: CGPointMake(22.65, 46.89) controlPoint2: CGPointMake(21.2, 50.23)];
    [jellyfishPath addCurveToPoint: CGPointMake(14.76, 58.92) controlPoint1: CGPointMake(17.57, 55.9) controlPoint2: CGPointMake(15.93, 57.8)];
    [jellyfishPath addCurveToPoint: CGPointMake(9.1, 58.78) controlPoint1: CGPointMake(13.16, 60.44) controlPoint2: CGPointMake(10.63, 60.38)];
    [jellyfishPath addCurveToPoint: CGPointMake(9.24, 53.12) controlPoint1: CGPointMake(7.58, 57.18) controlPoint2: CGPointMake(7.64, 54.65)];
    [jellyfishPath addCurveToPoint: CGPointMake(10.17, 52.11) controlPoint1: CGPointMake(9.39, 52.98) controlPoint2: CGPointMake(9.72, 52.64)];
    [jellyfishPath addCurveToPoint: CGPointMake(12.47, 49.04) controlPoint1: CGPointMake(10.95, 51.21) controlPoint2: CGPointMake(11.74, 50.18)];
    [jellyfishPath addCurveToPoint: CGPointMake(15.43, 41.9) controlPoint1: CGPointMake(13.94, 46.73) controlPoint2: CGPointMake(14.99, 44.32)];
    [jellyfishPath addCurveToPoint: CGPointMake(15.94, 36.01) controlPoint1: CGPointMake(15.69, 40.48) controlPoint2: CGPointMake(15.86, 38.48)];
    [jellyfishPath addLineToPoint: CGPointMake(23.95, 36.01)];
    [jellyfishPath closePath];
    jellyfishPath.usesEvenOddFillRule = YES;

    [color setFill];
    [jellyfishPath fill];
}

+ (void)drawIcon_0x247_32ptWithColor: (UIColor*)color
{

    //// Reverse Drawing
    UIBezierPath* reversePath = [UIBezierPath bezierPath];
    [reversePath moveToPoint: CGPointMake(46.43, 24)];
    [reversePath addLineToPoint: CGPointMake(47.99, 24)];
    [reversePath addCurveToPoint: CGPointMake(60, 12) controlPoint1: CGPointMake(54.62, 24) controlPoint2: CGPointMake(60, 18.61)];
    [reversePath addLineToPoint: CGPointMake(60, 6.92)];
    [reversePath addLineToPoint: CGPointMake(60, 6.92)];
    [reversePath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(51.64, 2.5) controlPoint2: CGPointMake(42.11, 0)];
    [reversePath addCurveToPoint: CGPointMake(4, 6.92) controlPoint1: CGPointMake(21.89, 0) controlPoint2: CGPointMake(12.36, 2.5)];
    [reversePath addLineToPoint: CGPointMake(4, 12)];
    [reversePath addCurveToPoint: CGPointMake(16.01, 24) controlPoint1: CGPointMake(4, 18.63) controlPoint2: CGPointMake(9.37, 24)];
    [reversePath addLineToPoint: CGPointMake(17.57, 24)];
    [reversePath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(21.78, 21.46) controlPoint2: CGPointMake(26.72, 20)];
    [reversePath addCurveToPoint: CGPointMake(46.43, 24) controlPoint1: CGPointMake(37.28, 20) controlPoint2: CGPointMake(42.22, 21.46)];
    [reversePath addLineToPoint: CGPointMake(46.43, 24)];
    [reversePath addLineToPoint: CGPointMake(46.43, 24)];
    [reversePath closePath];
    [reversePath moveToPoint: CGPointMake(32, 32)];
    [reversePath addCurveToPoint: CGPointMake(48, 48) controlPoint1: CGPointMake(40.84, 32) controlPoint2: CGPointMake(48, 39.16)];
    [reversePath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(48, 56.84) controlPoint2: CGPointMake(40.84, 64)];
    [reversePath addCurveToPoint: CGPointMake(16, 48) controlPoint1: CGPointMake(23.16, 64) controlPoint2: CGPointMake(16, 56.84)];
    [reversePath addCurveToPoint: CGPointMake(32, 32) controlPoint1: CGPointMake(16, 39.16) controlPoint2: CGPointMake(23.16, 32)];
    [reversePath addLineToPoint: CGPointMake(32, 32)];
    [reversePath closePath];
    reversePath.usesEvenOddFillRule = YES;

    [color setFill];
    [reversePath fill];
}

+ (void)drawIcon_0x243_32ptWithColor: (UIColor*)color
{

    //// Hare Drawing
    UIBezierPath* harePath = [UIBezierPath bezierPath];
    [harePath moveToPoint: CGPointMake(4, 6.75)];
    [harePath addCurveToPoint: CGPointMake(0, 10.75) controlPoint1: CGPointMake(1.79, 6.75) controlPoint2: CGPointMake(0, 8.54)];
    [harePath addCurveToPoint: CGPointMake(2.77, 14.55) controlPoint1: CGPointMake(0, 12.53) controlPoint2: CGPointMake(1.16, 14.03)];
    [harePath addCurveToPoint: CGPointMake(0.69, 29.88) controlPoint1: CGPointMake(0.26, 18.35) controlPoint2: CGPointMake(-0.81, 23.48)];
    [harePath addCurveToPoint: CGPointMake(22.24, 48) controlPoint1: CGPointMake(4.78, 40.63) controlPoint2: CGPointMake(13.33, 41.21)];
    [harePath addCurveToPoint: CGPointMake(35.74, 64) controlPoint1: CGPointMake(31.91, 55.37) controlPoint2: CGPointMake(35.74, 64)];
    [harePath addLineToPoint: CGPointMake(48.06, 61.47)];
    [harePath addLineToPoint: CGPointMake(48.03, 59.8)];
    [harePath addCurveToPoint: CGPointMake(46.23, 57.41) controlPoint1: CGPointMake(48.01, 58.63) controlPoint2: CGPointMake(47.21, 57.61)];
    [harePath addLineToPoint: CGPointMake(39.25, 55.97)];
    [harePath addCurveToPoint: CGPointMake(39.25, 49.23) controlPoint1: CGPointMake(39.25, 55.97) controlPoint2: CGPointMake(39.25, 50.99)];
    [harePath addCurveToPoint: CGPointMake(51.96, 40.63) controlPoint1: CGPointMake(45.43, 46.44) controlPoint2: CGPointMake(51.96, 40.63)];
    [harePath addCurveToPoint: CGPointMake(62.03, 39.65) controlPoint1: CGPointMake(55.73, 42.64) controlPoint2: CGPointMake(59.66, 42.42)];
    [harePath addCurveToPoint: CGPointMake(59.56, 22.34) controlPoint1: CGPointMake(65.43, 35.67) controlPoint2: CGPointMake(64.32, 27.92)];
    [harePath addCurveToPoint: CGPointMake(56.12, 19.24) controlPoint1: CGPointMake(58.49, 21.08) controlPoint2: CGPointMake(57.33, 20.04)];
    [harePath addCurveToPoint: CGPointMake(38.61, 0) controlPoint1: CGPointMake(51.17, 11.39) controlPoint2: CGPointMake(43.19, 0)];
    [harePath addCurveToPoint: CGPointMake(48, 17.4) controlPoint1: CGPointMake(34.42, 6.09) controlPoint2: CGPointMake(45.16, 15.16)];
    [harePath addCurveToPoint: CGPointMake(44.79, 19.45) controlPoint1: CGPointMake(46.77, 17.74) controlPoint2: CGPointMake(45.67, 18.42)];
    [harePath addCurveToPoint: CGPointMake(42.91, 23.95) controlPoint1: CGPointMake(43.75, 20.66) controlPoint2: CGPointMake(43.14, 22.22)];
    [harePath addCurveToPoint: CGPointMake(18.11, 6.69) controlPoint1: CGPointMake(37.85, 17.31) controlPoint2: CGPointMake(32.3, 6.69)];
    [harePath addCurveToPoint: CGPointMake(7.85, 9.62) controlPoint1: CGPointMake(14.56, 6.69) controlPoint2: CGPointMake(10.92, 7.68)];
    [harePath addCurveToPoint: CGPointMake(4, 6.75) controlPoint1: CGPointMake(7.36, 7.96) controlPoint2: CGPointMake(5.82, 6.75)];
    [harePath closePath];
    [harePath moveToPoint: CGPointMake(9.57, 59.75)];
    [harePath addLineToPoint: CGPointMake(20.39, 50.75)];
    [harePath addCurveToPoint: CGPointMake(26.61, 57.11) controlPoint1: CGPointMake(20.39, 50.75) controlPoint2: CGPointMake(24.72, 53.11)];
    [harePath addLineToPoint: CGPointMake(11.55, 63.35)];
    [harePath addCurveToPoint: CGPointMake(8.94, 62.33) controlPoint1: CGPointMake(10.63, 63.71) controlPoint2: CGPointMake(9.45, 63.23)];
    [harePath addLineToPoint: CGPointMake(9.1, 62.62)];
    [harePath addCurveToPoint: CGPointMake(9.57, 59.75) controlPoint1: CGPointMake(8.59, 61.69) controlPoint2: CGPointMake(8.83, 60.38)];
    [harePath closePath];
    [harePath moveToPoint: CGPointMake(53.99, 30.6)];
    [harePath addCurveToPoint: CGPointMake(56.96, 27.54) controlPoint1: CGPointMake(55.63, 30.6) controlPoint2: CGPointMake(56.96, 29.23)];
    [harePath addCurveToPoint: CGPointMake(53.99, 24.48) controlPoint1: CGPointMake(56.96, 25.85) controlPoint2: CGPointMake(55.63, 24.48)];
    [harePath addCurveToPoint: CGPointMake(51.03, 27.54) controlPoint1: CGPointMake(52.36, 24.48) controlPoint2: CGPointMake(51.03, 25.85)];
    [harePath addCurveToPoint: CGPointMake(53.99, 30.6) controlPoint1: CGPointMake(51.03, 29.23) controlPoint2: CGPointMake(52.36, 30.6)];
    [harePath closePath];
    harePath.usesEvenOddFillRule = YES;

    [color setFill];
    [harePath fill];
}

+ (void)drawIcon_0x139_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(64, 28)];
    [bezierPath addLineToPoint: CGPointMake(64, 0)];
    [bezierPath addLineToPoint: CGPointMake(36, 0)];
    [bezierPath addLineToPoint: CGPointMake(36, 8)];
    [bezierPath addLineToPoint: CGPointMake(50.36, 8)];
    [bezierPath addLineToPoint: CGPointMake(32.02, 26.29)];
    [bezierPath addLineToPoint: CGPointMake(37.68, 31.94)];
    [bezierPath addLineToPoint: CGPointMake(56, 13.67)];
    [bezierPath addLineToPoint: CGPointMake(56, 28)];
    [bezierPath addLineToPoint: CGPointMake(64, 28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(0, 36)];
    [bezierPath addLineToPoint: CGPointMake(0, 64)];
    [bezierPath addLineToPoint: CGPointMake(28, 64)];
    [bezierPath addLineToPoint: CGPointMake(28, 56)];
    [bezierPath addLineToPoint: CGPointMake(13.64, 56)];
    [bezierPath addLineToPoint: CGPointMake(32.19, 37.5)];
    [bezierPath addLineToPoint: CGPointMake(26.53, 31.85)];
    [bezierPath addLineToPoint: CGPointMake(8, 50.33)];
    [bezierPath addLineToPoint: CGPointMake(8, 36)];
    [bezierPath addLineToPoint: CGPointMake(0, 36)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;

    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x186_32ptWithColor: (UIColor*)color
{

    //// Delete Drawing
    UIBezierPath* deletePath = [UIBezierPath bezierPath];
    [deletePath moveToPoint: CGPointMake(24, 8)];
    [deletePath addLineToPoint: CGPointMake(8.03, 8)];
    [deletePath addCurveToPoint: CGPointMake(4, 12) controlPoint1: CGPointMake(5.8, 8) controlPoint2: CGPointMake(4, 9.79)];
    [deletePath addLineToPoint: CGPointMake(4, 16)];
    [deletePath addLineToPoint: CGPointMake(60, 16)];
    [deletePath addLineToPoint: CGPointMake(60, 12)];
    [deletePath addCurveToPoint: CGPointMake(55.97, 8) controlPoint1: CGPointMake(60, 9.78) controlPoint2: CGPointMake(58.2, 8)];
    [deletePath addLineToPoint: CGPointMake(40, 8)];
    [deletePath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(40, 3.55) controlPoint2: CGPointMake(36.42, 0)];
    [deletePath addCurveToPoint: CGPointMake(24, 8) controlPoint1: CGPointMake(27.55, 0) controlPoint2: CGPointMake(24, 3.58)];
    [deletePath addLineToPoint: CGPointMake(24, 8)];
    [deletePath closePath];
    [deletePath moveToPoint: CGPointMake(8, 24)];
    [deletePath addLineToPoint: CGPointMake(56, 24)];
    [deletePath addLineToPoint: CGPointMake(52.8, 56)];
    [deletePath addCurveToPoint: CGPointMake(44, 64) controlPoint1: CGPointMake(52.36, 60.42) controlPoint2: CGPointMake(48.45, 64)];
    [deletePath addLineToPoint: CGPointMake(20, 64)];
    [deletePath addCurveToPoint: CGPointMake(11.2, 56) controlPoint1: CGPointMake(15.58, 64) controlPoint2: CGPointMake(11.65, 60.45)];
    [deletePath addLineToPoint: CGPointMake(8, 24)];
    [deletePath addLineToPoint: CGPointMake(8, 24)];
    [deletePath closePath];
    deletePath.usesEvenOddFillRule = YES;

    [color setFill];
    [deletePath fill];
}

+ (void)drawIcon_0x231_32ptWithColor: (UIColor*)color
{

    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(25.32, 13.28)];
    [bezier2Path addCurveToPoint: CGPointMake(9.29, 13.29) controlPoint1: CGPointMake(20.91, 8.91) controlPoint2: CGPointMake(13.71, 8.91)];
    [bezier2Path addCurveToPoint: CGPointMake(6.01, 23.2) controlPoint1: CGPointMake(6.97, 15.59) controlPoint2: CGPointMake(5.87, 18.66)];
    [bezier2Path addCurveToPoint: CGPointMake(19.83, 44.78) controlPoint1: CGPointMake(6.01, 30.08) controlPoint2: CGPointMake(11.07, 37.56)];
    [bezier2Path addCurveToPoint: CGPointMake(30.12, 52.05) controlPoint1: CGPointMake(23.08, 47.46) controlPoint2: CGPointMake(26.6, 49.91)];
    [bezier2Path addCurveToPoint: CGPointMake(33.5, 54.01) controlPoint1: CGPointMake(31.35, 52.8) controlPoint2: CGPointMake(32.49, 53.45)];
    [bezier2Path addCurveToPoint: CGPointMake(34.68, 54.63) controlPoint1: CGPointMake(34.09, 54.33) controlPoint2: CGPointMake(34.5, 54.54)];
    [bezier2Path addLineToPoint: CGPointMake(29.32, 54.63)];
    [bezier2Path addCurveToPoint: CGPointMake(30.5, 54.01) controlPoint1: CGPointMake(29.5, 54.54) controlPoint2: CGPointMake(29.91, 54.33)];
    [bezier2Path addCurveToPoint: CGPointMake(33.88, 52.05) controlPoint1: CGPointMake(31.51, 53.45) controlPoint2: CGPointMake(32.65, 52.8)];
    [bezier2Path addCurveToPoint: CGPointMake(44.18, 44.77) controlPoint1: CGPointMake(37.4, 49.91) controlPoint2: CGPointMake(40.92, 47.46)];
    [bezier2Path addCurveToPoint: CGPointMake(58, 23.17) controlPoint1: CGPointMake(52.93, 37.55) controlPoint2: CGPointMake(58, 30.08)];
    [bezier2Path addCurveToPoint: CGPointMake(54.71, 13.29) controlPoint1: CGPointMake(58.02, 18.45) controlPoint2: CGPointMake(56.96, 15.52)];
    [bezier2Path addCurveToPoint: CGPointMake(38.68, 13.28) controlPoint1: CGPointMake(50.29, 8.91) controlPoint2: CGPointMake(43.09, 8.9)];
    [bezier2Path addLineToPoint: CGPointMake(36.22, 15.71)];
    [bezier2Path addLineToPoint: CGPointMake(32, 19.9)];
    [bezier2Path addLineToPoint: CGPointMake(27.78, 15.71)];
    [bezier2Path addLineToPoint: CGPointMake(25.32, 13.28)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(32, 11.45)];
    [bezier2Path addLineToPoint: CGPointMake(34.46, 9.02)];
    [bezier2Path addCurveToPoint: CGPointMake(58.93, 9.03) controlPoint1: CGPointMake(41.21, 2.32) controlPoint2: CGPointMake(52.18, 2.34)];
    [bezier2Path addCurveToPoint: CGPointMake(64, 23.2) controlPoint1: CGPointMake(62.34, 12.41) controlPoint2: CGPointMake(64.03, 16.85)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(64, 44) controlPoint2: CGPointMake(32, 60)];
    [bezier2Path addCurveToPoint: CGPointMake(0.01, 23.2) controlPoint1: CGPointMake(32, 60) controlPoint2: CGPointMake(-0, 44)];
    [bezier2Path addCurveToPoint: CGPointMake(5.07, 9.03) controlPoint1: CGPointMake(-0.18, 17.24) controlPoint2: CGPointMake(1.51, 12.55)];
    [bezier2Path addCurveToPoint: CGPointMake(29.54, 9.02) controlPoint1: CGPointMake(11.83, 2.32) controlPoint2: CGPointMake(22.8, 2.33)];
    [bezier2Path addLineToPoint: CGPointMake(32, 11.45)];
    [bezier2Path closePath];
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawIcon_0x232_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(29.54, 10.02)];
    [bezierPath addCurveToPoint: CGPointMake(5.07, 10.03) controlPoint1: CGPointMake(22.8, 3.33) controlPoint2: CGPointMake(11.83, 3.32)];
    [bezierPath addCurveToPoint: CGPointMake(0.01, 24.2) controlPoint1: CGPointMake(1.51, 13.55) controlPoint2: CGPointMake(-0.18, 18.24)];
    [bezierPath addCurveToPoint: CGPointMake(32, 61) controlPoint1: CGPointMake(-0, 45) controlPoint2: CGPointMake(32, 61)];
    [bezierPath addCurveToPoint: CGPointMake(64, 24.2) controlPoint1: CGPointMake(32, 61) controlPoint2: CGPointMake(64, 45)];
    [bezierPath addCurveToPoint: CGPointMake(58.93, 10.03) controlPoint1: CGPointMake(64.03, 17.85) controlPoint2: CGPointMake(62.34, 13.41)];
    [bezierPath addCurveToPoint: CGPointMake(34.46, 10.02) controlPoint1: CGPointMake(52.18, 3.34) controlPoint2: CGPointMake(41.21, 3.32)];
    [bezierPath addLineToPoint: CGPointMake(32, 12.45)];
    [bezierPath addLineToPoint: CGPointMake(29.54, 10.02)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;

    [color setFill];
    [bezierPath fill];
}

+ (void)drawMissedcallWithAccent: (UIColor*)accent
{
    //// Color Declarations
    UIColor* accentopacity64 = [accent colorWithAlphaComponent: 0.64];
    UIColor* accentopacity32 = [accent colorWithAlphaComponent: 0.32];

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(1, 1, 38, 38)];
    [accentopacity32 setStroke];
    ovalPath.lineWidth = 1;
    [ovalPath stroke];


    //// Oval 2 Drawing
    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(5, 5, 30, 30)];
    [accentopacity64 setStroke];
    oval2Path.lineWidth = 1;
    [oval2Path stroke];


    //// Oval 3 Drawing
    UIBezierPath* oval3Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(9, 9, 22, 22)];
    [accent setStroke];
    oval3Path.lineWidth = 1;
    [oval3Path stroke];
}

+ (void)drawYoutubeWithColor: (UIColor*)color
{

    //// logo-youtube Drawing
    UIBezierPath* logoyoutubePath = [UIBezierPath bezierPath];
    [logoyoutubePath moveToPoint: CGPointMake(63.62, 5.61)];
    [logoyoutubePath addCurveToPoint: CGPointMake(62.12, 1.94) controlPoint1: CGPointMake(63.62, 5.61) controlPoint2: CGPointMake(63.25, 3.06)];
    [logoyoutubePath addCurveToPoint: CGPointMake(58.32, 0.37) controlPoint1: CGPointMake(60.68, 0.47) controlPoint2: CGPointMake(59.06, 0.46)];
    [logoyoutubePath addCurveToPoint: CGPointMake(45.07, 0) controlPoint1: CGPointMake(53.02, 0) controlPoint2: CGPointMake(45.07, 0)];
    [logoyoutubePath addLineToPoint: CGPointMake(45.05, 0)];
    [logoyoutubePath addCurveToPoint: CGPointMake(31.8, 0.37) controlPoint1: CGPointMake(45.05, 0) controlPoint2: CGPointMake(37.1, 0)];
    [logoyoutubePath addCurveToPoint: CGPointMake(28.01, 1.94) controlPoint1: CGPointMake(31.06, 0.46) controlPoint2: CGPointMake(29.45, 0.47)];
    [logoyoutubePath addCurveToPoint: CGPointMake(26.5, 5.61) controlPoint1: CGPointMake(26.87, 3.06) controlPoint2: CGPointMake(26.5, 5.61)];
    [logoyoutubePath addCurveToPoint: CGPointMake(26.12, 11.59) controlPoint1: CGPointMake(26.5, 5.61) controlPoint2: CGPointMake(26.12, 8.6)];
    [logoyoutubePath addLineToPoint: CGPointMake(26.12, 14.4)];
    [logoyoutubePath addCurveToPoint: CGPointMake(26.5, 20.38) controlPoint1: CGPointMake(26.12, 17.39) controlPoint2: CGPointMake(26.5, 20.38)];
    [logoyoutubePath addCurveToPoint: CGPointMake(28.01, 24.05) controlPoint1: CGPointMake(26.5, 20.38) controlPoint2: CGPointMake(26.87, 22.93)];
    [logoyoutubePath addCurveToPoint: CGPointMake(32.18, 25.63) controlPoint1: CGPointMake(29.45, 25.52) controlPoint2: CGPointMake(31.34, 25.47)];
    [logoyoutubePath addCurveToPoint: CGPointMake(45.06, 26) controlPoint1: CGPointMake(35.21, 25.91) controlPoint2: CGPointMake(45.06, 26)];
    [logoyoutubePath addCurveToPoint: CGPointMake(58.32, 25.61) controlPoint1: CGPointMake(45.06, 26) controlPoint2: CGPointMake(53.02, 25.99)];
    [logoyoutubePath addCurveToPoint: CGPointMake(62.12, 24.05) controlPoint1: CGPointMake(59.06, 25.53) controlPoint2: CGPointMake(60.68, 25.52)];
    [logoyoutubePath addCurveToPoint: CGPointMake(63.62, 20.38) controlPoint1: CGPointMake(63.25, 22.93) controlPoint2: CGPointMake(63.62, 20.38)];
    [logoyoutubePath addCurveToPoint: CGPointMake(64, 14.4) controlPoint1: CGPointMake(63.62, 20.38) controlPoint2: CGPointMake(64, 17.39)];
    [logoyoutubePath addLineToPoint: CGPointMake(64, 11.59)];
    [logoyoutubePath addCurveToPoint: CGPointMake(63.62, 5.61) controlPoint1: CGPointMake(64, 8.6) controlPoint2: CGPointMake(63.62, 5.61)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(56.26, 11.96)];
    [logoyoutubePath addCurveToPoint: CGPointMake(57.35, 10.48) controlPoint1: CGPointMake(56.26, 10.8) controlPoint2: CGPointMake(56.58, 10.48)];
    [logoyoutubePath addCurveToPoint: CGPointMake(58.42, 11.97) controlPoint1: CGPointMake(58.11, 10.48) controlPoint2: CGPointMake(58.42, 10.82)];
    [logoyoutubePath addLineToPoint: CGPointMake(58.42, 13.33)];
    [logoyoutubePath addLineToPoint: CGPointMake(56.26, 13.33)];
    [logoyoutubePath addLineToPoint: CGPointMake(56.26, 11.96)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(60.83, 15.2)];
    [logoyoutubePath addLineToPoint: CGPointMake(60.83, 12.65)];
    [logoyoutubePath addCurveToPoint: CGPointMake(60.08, 9.73) controlPoint1: CGPointMake(60.83, 11.33) controlPoint2: CGPointMake(60.56, 10.35)];
    [logoyoutubePath addCurveToPoint: CGPointMake(57.37, 8.43) controlPoint1: CGPointMake(59.44, 8.88) controlPoint2: CGPointMake(58.52, 8.43)];
    [logoyoutubePath addCurveToPoint: CGPointMake(54.62, 9.73) controlPoint1: CGPointMake(56.2, 8.43) controlPoint2: CGPointMake(55.29, 8.88)];
    [logoyoutubePath addCurveToPoint: CGPointMake(53.85, 12.71) controlPoint1: CGPointMake(54.13, 10.35) controlPoint2: CGPointMake(53.85, 11.38)];
    [logoyoutubePath addLineToPoint: CGPointMake(53.85, 17.06)];
    [logoyoutubePath addCurveToPoint: CGPointMake(54.65, 19.93) controlPoint1: CGPointMake(53.85, 18.38) controlPoint2: CGPointMake(54.16, 19.31)];
    [logoyoutubePath addCurveToPoint: CGPointMake(57.43, 21.2) controlPoint1: CGPointMake(55.31, 20.78) controlPoint2: CGPointMake(56.23, 21.2)];
    [logoyoutubePath addCurveToPoint: CGPointMake(60.21, 19.85) controlPoint1: CGPointMake(58.63, 21.2) controlPoint2: CGPointMake(59.57, 20.76)];
    [logoyoutubePath addCurveToPoint: CGPointMake(60.74, 18.5) controlPoint1: CGPointMake(60.49, 19.46) controlPoint2: CGPointMake(60.67, 19)];
    [logoyoutubePath addCurveToPoint: CGPointMake(60.83, 17.04) controlPoint1: CGPointMake(60.77, 18.28) controlPoint2: CGPointMake(60.83, 17.77)];
    [logoyoutubePath addLineToPoint: CGPointMake(60.83, 16.69)];
    [logoyoutubePath addLineToPoint: CGPointMake(58.42, 16.69)];
    [logoyoutubePath addCurveToPoint: CGPointMake(58.4, 18.25) controlPoint1: CGPointMake(58.42, 17.59) controlPoint2: CGPointMake(58.42, 18.13)];
    [logoyoutubePath addCurveToPoint: CGPointMake(57.37, 19.15) controlPoint1: CGPointMake(58.27, 18.85) controlPoint2: CGPointMake(57.94, 19.15)];
    [logoyoutubePath addCurveToPoint: CGPointMake(56.26, 17.43) controlPoint1: CGPointMake(56.58, 19.15) controlPoint2: CGPointMake(56.25, 18.58)];
    [logoyoutubePath addLineToPoint: CGPointMake(56.26, 15.2)];
    [logoyoutubePath addLineToPoint: CGPointMake(60.83, 15.2)];
    [logoyoutubePath addLineToPoint: CGPointMake(60.83, 15.2)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(49.92, 17.43)];
    [logoyoutubePath addCurveToPoint: CGPointMake(48.96, 19.15) controlPoint1: CGPointMake(49.92, 18.68) controlPoint2: CGPointMake(49.62, 19.15)];
    [logoyoutubePath addCurveToPoint: CGPointMake(47.76, 18.59) controlPoint1: CGPointMake(48.58, 19.15) controlPoint2: CGPointMake(48.14, 18.96)];
    [logoyoutubePath addLineToPoint: CGPointMake(47.76, 11.05)];
    [logoyoutubePath addCurveToPoint: CGPointMake(48.96, 10.48) controlPoint1: CGPointMake(48.15, 10.67) controlPoint2: CGPointMake(48.58, 10.48)];
    [logoyoutubePath addCurveToPoint: CGPointMake(49.92, 12.09) controlPoint1: CGPointMake(49.62, 10.48) controlPoint2: CGPointMake(49.92, 10.84)];
    [logoyoutubePath addLineToPoint: CGPointMake(49.92, 17.43)];
    [logoyoutubePath addLineToPoint: CGPointMake(49.92, 17.43)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(50.18, 8.41)];
    [logoyoutubePath addCurveToPoint: CGPointMake(47.76, 9.81) controlPoint1: CGPointMake(49.34, 8.41) controlPoint2: CGPointMake(48.5, 8.91)];
    [logoyoutubePath addLineToPoint: CGPointMake(47.76, 4.38)];
    [logoyoutubePath addLineToPoint: CGPointMake(45.48, 4.38)];
    [logoyoutubePath addLineToPoint: CGPointMake(45.48, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(47.76, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(47.76, 19.79)];
    [logoyoutubePath addCurveToPoint: CGPointMake(50.18, 21.2) controlPoint1: CGPointMake(48.53, 20.72) controlPoint2: CGPointMake(49.37, 21.2)];
    [logoyoutubePath addCurveToPoint: CGPointMake(52.07, 19.8) controlPoint1: CGPointMake(51.1, 21.2) controlPoint2: CGPointMake(51.77, 20.72)];
    [logoyoutubePath addCurveToPoint: CGPointMake(52.33, 17.31) controlPoint1: CGPointMake(52.23, 19.27) controlPoint2: CGPointMake(52.33, 18.46)];
    [logoyoutubePath addLineToPoint: CGPointMake(52.33, 12.34)];
    [logoyoutubePath addCurveToPoint: CGPointMake(52.02, 9.85) controlPoint1: CGPointMake(52.33, 11.16) controlPoint2: CGPointMake(52.17, 10.35)];
    [logoyoutubePath addCurveToPoint: CGPointMake(50.18, 8.41) controlPoint1: CGPointMake(51.71, 8.92) controlPoint2: CGPointMake(51.1, 8.41)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(34.44, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(31.91, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(31.91, 6.74)];
    [logoyoutubePath addLineToPoint: CGPointMake(29.24, 6.74)];
    [logoyoutubePath addLineToPoint: CGPointMake(29.24, 4.38)];
    [logoyoutubePath addLineToPoint: CGPointMake(37.23, 4.38)];
    [logoyoutubePath addLineToPoint: CGPointMake(37.23, 6.74)];
    [logoyoutubePath addLineToPoint: CGPointMake(34.44, 6.74)];
    [logoyoutubePath addLineToPoint: CGPointMake(34.44, 21.04)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(43.58, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(41.17, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(41.17, 19.67)];
    [logoyoutubePath addCurveToPoint: CGPointMake(38.63, 21.22) controlPoint1: CGPointMake(40.25, 20.7) controlPoint2: CGPointMake(39.48, 21.22)];
    [logoyoutubePath addCurveToPoint: CGPointMake(37.12, 20.26) controlPoint1: CGPointMake(37.89, 21.22) controlPoint2: CGPointMake(37.38, 20.88)];
    [logoyoutubePath addCurveToPoint: CGPointMake(36.85, 18.43) controlPoint1: CGPointMake(36.96, 19.88) controlPoint2: CGPointMake(36.85, 19.29)];
    [logoyoutubePath addLineToPoint: CGPointMake(36.85, 8.6)];
    [logoyoutubePath addLineToPoint: CGPointMake(39.26, 8.6)];
    [logoyoutubePath addLineToPoint: CGPointMake(39.26, 17.81)];
    [logoyoutubePath addLineToPoint: CGPointMake(39.26, 18.68)];
    [logoyoutubePath addCurveToPoint: CGPointMake(39.78, 19.15) controlPoint1: CGPointMake(39.32, 19.03) controlPoint2: CGPointMake(39.47, 19.15)];
    [logoyoutubePath addCurveToPoint: CGPointMake(41.17, 18.06) controlPoint1: CGPointMake(40.24, 19.15) controlPoint2: CGPointMake(40.66, 18.76)];
    [logoyoutubePath addLineToPoint: CGPointMake(41.17, 8.6)];
    [logoyoutubePath addLineToPoint: CGPointMake(43.58, 8.6)];
    [logoyoutubePath addLineToPoint: CGPointMake(43.58, 21.04)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(24.17, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(21.76, 21.04)];
    [logoyoutubePath addLineToPoint: CGPointMake(21.76, 19.67)];
    [logoyoutubePath addCurveToPoint: CGPointMake(19.23, 21.22) controlPoint1: CGPointMake(20.84, 20.7) controlPoint2: CGPointMake(20.07, 21.22)];
    [logoyoutubePath addCurveToPoint: CGPointMake(17.71, 20.26) controlPoint1: CGPointMake(18.48, 21.22) controlPoint2: CGPointMake(17.97, 20.88)];
    [logoyoutubePath addCurveToPoint: CGPointMake(17.45, 18.43) controlPoint1: CGPointMake(17.56, 19.88) controlPoint2: CGPointMake(17.45, 19.29)];
    [logoyoutubePath addLineToPoint: CGPointMake(17.45, 8.48)];
    [logoyoutubePath addLineToPoint: CGPointMake(19.86, 8.48)];
    [logoyoutubePath addLineToPoint: CGPointMake(19.86, 17.81)];
    [logoyoutubePath addLineToPoint: CGPointMake(19.86, 18.68)];
    [logoyoutubePath addCurveToPoint: CGPointMake(20.37, 19.15) controlPoint1: CGPointMake(19.91, 19.03) controlPoint2: CGPointMake(20.06, 19.15)];
    [logoyoutubePath addCurveToPoint: CGPointMake(21.76, 18.06) controlPoint1: CGPointMake(20.83, 19.15) controlPoint2: CGPointMake(21.25, 18.76)];
    [logoyoutubePath addLineToPoint: CGPointMake(21.76, 8.48)];
    [logoyoutubePath addLineToPoint: CGPointMake(24.17, 8.48)];
    [logoyoutubePath addLineToPoint: CGPointMake(24.17, 21.04)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(13.26, 17.31)];
    [logoyoutubePath addCurveToPoint: CGPointMake(12.24, 19.17) controlPoint1: CGPointMake(13.39, 18.55) controlPoint2: CGPointMake(12.99, 19.17)];
    [logoyoutubePath addCurveToPoint: CGPointMake(11.23, 17.31) controlPoint1: CGPointMake(11.5, 19.17) controlPoint2: CGPointMake(11.1, 18.55)];
    [logoyoutubePath addLineToPoint: CGPointMake(11.23, 12.34)];
    [logoyoutubePath addCurveToPoint: CGPointMake(12.24, 10.51) controlPoint1: CGPointMake(11.1, 11.09) controlPoint2: CGPointMake(11.5, 10.51)];
    [logoyoutubePath addCurveToPoint: CGPointMake(13.26, 12.34) controlPoint1: CGPointMake(12.99, 10.51) controlPoint2: CGPointMake(13.39, 11.09)];
    [logoyoutubePath addLineToPoint: CGPointMake(13.26, 17.31)];
    [logoyoutubePath addLineToPoint: CGPointMake(13.26, 17.31)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(15.67, 12.58)];
    [logoyoutubePath addCurveToPoint: CGPointMake(14.91, 9.6) controlPoint1: CGPointMake(15.67, 11.24) controlPoint2: CGPointMake(15.39, 10.23)];
    [logoyoutubePath addCurveToPoint: CGPointMake(12.24, 8.39) controlPoint1: CGPointMake(14.27, 8.74) controlPoint2: CGPointMake(13.26, 8.39)];
    [logoyoutubePath addCurveToPoint: CGPointMake(9.58, 9.6) controlPoint1: CGPointMake(11.1, 8.39) controlPoint2: CGPointMake(10.22, 8.74)];
    [logoyoutubePath addCurveToPoint: CGPointMake(8.82, 12.6) controlPoint1: CGPointMake(9.09, 10.23) controlPoint2: CGPointMake(8.82, 11.25)];
    [logoyoutubePath addLineToPoint: CGPointMake(8.82, 17.06)];
    [logoyoutubePath addCurveToPoint: CGPointMake(9.55, 19.95) controlPoint1: CGPointMake(8.82, 18.4) controlPoint2: CGPointMake(9.06, 19.32)];
    [logoyoutubePath addCurveToPoint: CGPointMake(12.24, 21.26) controlPoint1: CGPointMake(10.19, 20.8) controlPoint2: CGPointMake(11.23, 21.26)];
    [logoyoutubePath addCurveToPoint: CGPointMake(14.96, 19.95) controlPoint1: CGPointMake(13.26, 21.26) controlPoint2: CGPointMake(14.32, 20.8)];
    [logoyoutubePath addCurveToPoint: CGPointMake(15.67, 17.06) controlPoint1: CGPointMake(15.45, 19.32) controlPoint2: CGPointMake(15.67, 18.4)];
    [logoyoutubePath addLineToPoint: CGPointMake(15.67, 12.58)];
    [logoyoutubePath closePath];
    [logoyoutubePath moveToPoint: CGPointMake(6.3, 14.57)];
    [logoyoutubePath addLineToPoint: CGPointMake(6.3, 21.22)];
    [logoyoutubePath addLineToPoint: CGPointMake(3.5, 21.22)];
    [logoyoutubePath addLineToPoint: CGPointMake(3.5, 14.57)];
    [logoyoutubePath addCurveToPoint: CGPointMake(0, 4.9) controlPoint1: CGPointMake(3.5, 14.57) controlPoint2: CGPointMake(0.6, 6.42)];
    [logoyoutubePath addLineToPoint: CGPointMake(2.94, 4.9)];
    [logoyoutubePath addLineToPoint: CGPointMake(4.9, 11.27)];
    [logoyoutubePath addLineToPoint: CGPointMake(6.86, 4.9)];
    [logoyoutubePath addLineToPoint: CGPointMake(9.8, 4.9)];
    [logoyoutubePath addLineToPoint: CGPointMake(6.3, 14.57)];
    [logoyoutubePath closePath];
    logoyoutubePath.miterLimit = 4;

    logoyoutubePath.usesEvenOddFillRule = YES;

    [color setFill];
    [logoyoutubePath fill];
}

+ (void)drawMissedcalllastWithAccent: (UIColor*)accent
{
    //// Color Declarations
    UIColor* accentopacity64 = [accent colorWithAlphaComponent: 0.64];
    UIColor* accentopacity32 = [accent colorWithAlphaComponent: 0.32];

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(1, 1, 38, 38)];
    [accentopacity32 setStroke];
    ovalPath.lineWidth = 1;
    [ovalPath stroke];


    //// Oval 2 Drawing
    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(5, 5, 30, 30)];
    [accentopacity64 setStroke];
    oval2Path.lineWidth = 1;
    [oval2Path stroke];


    //// Text Drawing
    UIBezierPath* textPath = [UIBezierPath bezierPath];
    [textPath moveToPoint: CGPointMake(17.02, 10)];
    [textPath addCurveToPoint: CGPointMake(16.51, 10.11) controlPoint1: CGPointMake(16.85, 10) controlPoint2: CGPointMake(16.68, 10.04)];
    [textPath addLineToPoint: CGPointMake(15.11, 10.72)];
    [textPath addCurveToPoint: CGPointMake(11.6, 16.02) controlPoint1: CGPointMake(12.87, 11.74) controlPoint2: CGPointMake(11.6, 13.81)];
    [textPath addCurveToPoint: CGPointMake(12.43, 19.07) controlPoint1: CGPointMake(11.6, 17.04) controlPoint2: CGPointMake(11.87, 18.08)];
    [textPath addLineToPoint: CGPointMake(16.97, 26.99)];
    [textPath addCurveToPoint: CGPointMake(21.97, 30) controlPoint1: CGPointMake(18.09, 28.94) controlPoint2: CGPointMake(19.99, 30)];
    [textPath addCurveToPoint: CGPointMake(25.47, 28.82) controlPoint1: CGPointMake(23.16, 30) controlPoint2: CGPointMake(24.38, 29.62)];
    [textPath addLineToPoint: CGPointMake(26.7, 27.91)];
    [textPath addCurveToPoint: CGPointMake(27.23, 26.85) controlPoint1: CGPointMake(27.04, 27.65) controlPoint2: CGPointMake(27.23, 27.26)];
    [textPath addCurveToPoint: CGPointMake(26.97, 26.07) controlPoint1: CGPointMake(27.23, 26.58) controlPoint2: CGPointMake(27.14, 26.31)];
    [textPath addLineToPoint: CGPointMake(24.72, 22.96)];
    [textPath addCurveToPoint: CGPointMake(23.66, 22.42) controlPoint1: CGPointMake(24.46, 22.6) controlPoint2: CGPointMake(24.06, 22.42)];
    [textPath addCurveToPoint: CGPointMake(22.89, 22.64) controlPoint1: CGPointMake(23.39, 22.42) controlPoint2: CGPointMake(23.13, 22.49)];
    [textPath addCurveToPoint: CGPointMake(21.53, 23.29) controlPoint1: CGPointMake(22.89, 22.64) controlPoint2: CGPointMake(22.25, 23.29)];
    [textPath addCurveToPoint: CGPointMake(20.39, 22.51) controlPoint1: CGPointMake(21.14, 23.29) controlPoint2: CGPointMake(20.73, 23.1)];
    [textPath addLineToPoint: CGPointMake(17.93, 18.2)];
    [textPath addCurveToPoint: CGPointMake(17.68, 17.37) controlPoint1: CGPointMake(17.75, 17.89) controlPoint2: CGPointMake(17.68, 17.61)];
    [textPath addCurveToPoint: CGPointMake(19.07, 15.94) controlPoint1: CGPointMake(17.68, 16.33) controlPoint2: CGPointMake(19.07, 15.94)];
    [textPath addCurveToPoint: CGPointMake(19.83, 14.73) controlPoint1: CGPointMake(19.55, 15.72) controlPoint2: CGPointMake(19.83, 15.23)];
    [textPath addCurveToPoint: CGPointMake(19.72, 14.19) controlPoint1: CGPointMake(19.83, 14.55) controlPoint2: CGPointMake(19.79, 14.37)];
    [textPath addLineToPoint: CGPointMake(18.22, 10.78)];
    [textPath addCurveToPoint: CGPointMake(17.02, 10) controlPoint1: CGPointMake(18, 10.29) controlPoint2: CGPointMake(17.52, 10)];
    [textPath closePath];
    [textPath moveToPoint: CGPointMake(17.01, 11.25)];
    [textPath addLineToPoint: CGPointMake(17.07, 11.29)];
    [textPath addLineToPoint: CGPointMake(18.57, 14.7)];
    [textPath addLineToPoint: CGPointMake(18.56, 14.79)];
    [textPath addCurveToPoint: CGPointMake(16.43, 17.38) controlPoint1: CGPointMake(17.98, 14.99) controlPoint2: CGPointMake(16.43, 15.67)];
    [textPath addCurveToPoint: CGPointMake(16.84, 18.82) controlPoint1: CGPointMake(16.43, 17.79) controlPoint2: CGPointMake(16.53, 18.28)];
    [textPath addLineToPoint: CGPointMake(19.31, 23.13)];
    [textPath addCurveToPoint: CGPointMake(21.53, 24.54) controlPoint1: CGPointMake(20.01, 24.36) controlPoint2: CGPointMake(21, 24.54)];
    [textPath addCurveToPoint: CGPointMake(23.62, 23.67) controlPoint1: CGPointMake(22.5, 24.54) controlPoint2: CGPointMake(23.28, 23.97)];
    [textPath addLineToPoint: CGPointMake(23.71, 23.69)];
    [textPath addLineToPoint: CGPointMake(25.96, 26.81)];
    [textPath addCurveToPoint: CGPointMake(25.95, 26.91) controlPoint1: CGPointMake(25.99, 26.84) controlPoint2: CGPointMake(25.98, 26.89)];
    [textPath addLineToPoint: CGPointMake(24.73, 27.82)];
    [textPath addCurveToPoint: CGPointMake(21.97, 28.75) controlPoint1: CGPointMake(23.89, 28.43) controlPoint2: CGPointMake(22.94, 28.75)];
    [textPath addCurveToPoint: CGPointMake(18.05, 26.37) controlPoint1: CGPointMake(20.37, 28.75) controlPoint2: CGPointMake(18.91, 27.86)];
    [textPath addLineToPoint: CGPointMake(13.52, 18.45)];
    [textPath addCurveToPoint: CGPointMake(12.85, 16.02) controlPoint1: CGPointMake(13.08, 17.67) controlPoint2: CGPointMake(12.85, 16.84)];
    [textPath addCurveToPoint: CGPointMake(13.07, 14.65) controlPoint1: CGPointMake(12.85, 15.56) controlPoint2: CGPointMake(12.92, 15.1)];
    [textPath addCurveToPoint: CGPointMake(15.62, 11.86) controlPoint1: CGPointMake(13.47, 13.42) controlPoint2: CGPointMake(14.37, 12.43)];
    [textPath addLineToPoint: CGPointMake(17.01, 11.25)];
    [textPath closePath];
    [accent setFill];
    [textPath fill];
}

+ (void)drawVimeoWithColor: (UIColor*)color
{

    //// logo-vimeo Drawing
    UIBezierPath* logovimeoPath = [UIBezierPath bezierPath];
    [logovimeoPath moveToPoint: CGPointMake(26.16, 0.76)];
    [logovimeoPath addCurveToPoint: CGPointMake(26.7, 2.16) controlPoint1: CGPointMake(26.55, 1.22) controlPoint2: CGPointMake(26.73, 1.69)];
    [logovimeoPath addCurveToPoint: CGPointMake(25.65, 4.18) controlPoint1: CGPointMake(26.68, 2.86) controlPoint2: CGPointMake(26.32, 3.54)];
    [logovimeoPath addCurveToPoint: CGPointMake(22.95, 5.27) controlPoint1: CGPointMake(24.89, 4.91) controlPoint2: CGPointMake(23.99, 5.27)];
    [logovimeoPath addCurveToPoint: CGPointMake(20.63, 3.17) controlPoint1: CGPointMake(21.35, 5.27) controlPoint2: CGPointMake(20.57, 4.57)];
    [logovimeoPath addCurveToPoint: CGPointMake(21.16, 1.83) controlPoint1: CGPointMake(20.65, 2.71) controlPoint2: CGPointMake(20.82, 2.27)];
    [logovimeoPath addCurveToPoint: CGPointMake(21.91, 1.07) controlPoint1: CGPointMake(21.35, 1.58) controlPoint2: CGPointMake(21.61, 1.32)];
    [logovimeoPath addCurveToPoint: CGPointMake(22.28, 0.8) controlPoint1: CGPointMake(22.04, 0.97) controlPoint2: CGPointMake(22.16, 0.88)];
    [logovimeoPath addCurveToPoint: CGPointMake(24.68, 0.07) controlPoint1: CGPointMake(23.02, 0.31) controlPoint2: CGPointMake(23.81, 0.07)];
    [logovimeoPath addCurveToPoint: CGPointMake(26.16, 0.76) controlPoint1: CGPointMake(25.27, 0.07) controlPoint2: CGPointMake(25.76, 0.3)];
    [logovimeoPath closePath];
    [logovimeoPath moveToPoint: CGPointMake(62.03, 11.58)];
    [logovimeoPath addCurveToPoint: CGPointMake(60.62, 12.11) controlPoint1: CGPointMake(61.57, 11.58) controlPoint2: CGPointMake(61.1, 11.76)];
    [logovimeoPath addCurveToPoint: CGPointMake(59.47, 13.32) controlPoint1: CGPointMake(60.24, 12.4) controlPoint2: CGPointMake(59.85, 12.8)];
    [logovimeoPath addCurveToPoint: CGPointMake(58.12, 16.66) controlPoint1: CGPointMake(58.59, 14.48) controlPoint2: CGPointMake(58.15, 15.59)];
    [logovimeoPath addCurveToPoint: CGPointMake(58.12, 17.2) controlPoint1: CGPointMake(58.1, 16.66) controlPoint2: CGPointMake(58.1, 16.84)];
    [logovimeoPath addCurveToPoint: CGPointMake(61.7, 14.9) controlPoint1: CGPointMake(59.49, 16.7) controlPoint2: CGPointMake(60.69, 15.93)];
    [logovimeoPath addCurveToPoint: CGPointMake(62.96, 12.71) controlPoint1: CGPointMake(62.51, 14) controlPoint2: CGPointMake(62.93, 13.27)];
    [logovimeoPath addCurveToPoint: CGPointMake(62.03, 11.58) controlPoint1: CGPointMake(62.99, 11.96) controlPoint2: CGPointMake(62.68, 11.58)];
    [logovimeoPath closePath];
    [logovimeoPath moveToPoint: CGPointMake(16.05, 7.48)];
    [logovimeoPath addCurveToPoint: CGPointMake(18.78, 10.54) controlPoint1: CGPointMake(17.79, 7.53) controlPoint2: CGPointMake(18.7, 8.55)];
    [logovimeoPath addCurveToPoint: CGPointMake(20.04, 9.4) controlPoint1: CGPointMake(19.42, 9.96) controlPoint2: CGPointMake(20.04, 9.4)];
    [logovimeoPath addCurveToPoint: CGPointMake(22.74, 7.72) controlPoint1: CGPointMake(21.25, 8.33) controlPoint2: CGPointMake(22.15, 7.77)];
    [logovimeoPath addCurveToPoint: CGPointMake(24.78, 8.53) controlPoint1: CGPointMake(23.67, 7.63) controlPoint2: CGPointMake(24.35, 7.9)];
    [logovimeoPath addCurveToPoint: CGPointMake(25.27, 10.99) controlPoint1: CGPointMake(25.22, 9.17) controlPoint2: CGPointMake(25.38, 9.98)];
    [logovimeoPath addCurveToPoint: CGPointMake(24.09, 17.5) controlPoint1: CGPointMake(24.9, 12.7) controlPoint2: CGPointMake(24.51, 14.87)];
    [logovimeoPath addCurveToPoint: CGPointMake(25.4, 19.31) controlPoint1: CGPointMake(24.06, 18.71) controlPoint2: CGPointMake(24.5, 19.31)];
    [logovimeoPath addCurveToPoint: CGPointMake(27.51, 18.06) controlPoint1: CGPointMake(25.79, 19.31) controlPoint2: CGPointMake(26.49, 18.9)];
    [logovimeoPath addCurveToPoint: CGPointMake(27.85, 15.94) controlPoint1: CGPointMake(27.61, 17.44) controlPoint2: CGPointMake(27.71, 16.75)];
    [logovimeoPath addCurveToPoint: CGPointMake(28.24, 12.89) controlPoint1: CGPointMake(28.09, 14.63) controlPoint2: CGPointMake(28.22, 13.62)];
    [logovimeoPath addCurveToPoint: CGPointMake(27.86, 12.13) controlPoint1: CGPointMake(28.3, 12.39) controlPoint2: CGPointMake(28.17, 12.13)];
    [logovimeoPath addCurveToPoint: CGPointMake(26.43, 12.99) controlPoint1: CGPointMake(27.69, 12.13) controlPoint2: CGPointMake(27.22, 12.42)];
    [logovimeoPath addLineToPoint: CGPointMake(25.42, 11.85)];
    [logovimeoPath addCurveToPoint: CGPointMake(28.07, 9.4) controlPoint1: CGPointMake(25.56, 11.74) controlPoint2: CGPointMake(26.44, 10.92)];
    [logovimeoPath addCurveToPoint: CGPointMake(28.67, 8.87) controlPoint1: CGPointMake(28.28, 9.21) controlPoint2: CGPointMake(28.48, 9.03)];
    [logovimeoPath addCurveToPoint: CGPointMake(30.48, 7.72) controlPoint1: CGPointMake(29.53, 8.12) controlPoint2: CGPointMake(30.13, 7.74)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.25, 8.62) controlPoint1: CGPointMake(31.21, 7.66) controlPoint2: CGPointMake(31.8, 7.96)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.86, 10.16) controlPoint1: CGPointMake(32.56, 9.08) controlPoint2: CGPointMake(32.77, 9.59)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.93, 10.92) controlPoint1: CGPointMake(32.9, 10.4) controlPoint2: CGPointMake(32.93, 10.66)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.84, 11.72) controlPoint1: CGPointMake(32.93, 11.2) controlPoint2: CGPointMake(32.9, 11.47)];
    [logovimeoPath addCurveToPoint: CGPointMake(33.86, 10.46) controlPoint1: CGPointMake(33.14, 11.26) controlPoint2: CGPointMake(33.48, 10.84)];
    [logovimeoPath addCurveToPoint: CGPointMake(34.32, 10.03) controlPoint1: CGPointMake(34, 10.31) controlPoint2: CGPointMake(34.16, 10.17)];
    [logovimeoPath addCurveToPoint: CGPointMake(38.66, 8.14) controlPoint1: CGPointMake(35.61, 8.91) controlPoint2: CGPointMake(37.06, 8.28)];
    [logovimeoPath addCurveToPoint: CGPointMake(41.62, 9.11) controlPoint1: CGPointMake(40.04, 8.02) controlPoint2: CGPointMake(41.02, 8.35)];
    [logovimeoPath addCurveToPoint: CGPointMake(42.29, 11.76) controlPoint1: CGPointMake(42.09, 9.73) controlPoint2: CGPointMake(42.32, 10.61)];
    [logovimeoPath addCurveToPoint: CGPointMake(42.92, 11.22) controlPoint1: CGPointMake(42.49, 11.6) controlPoint2: CGPointMake(42.7, 11.41)];
    [logovimeoPath addCurveToPoint: CGPointMake(44.82, 9.4) controlPoint1: CGPointMake(43.57, 10.46) controlPoint2: CGPointMake(44.2, 9.85)];
    [logovimeoPath addCurveToPoint: CGPointMake(48.07, 8.14) controlPoint1: CGPointMake(45.86, 8.64) controlPoint2: CGPointMake(46.95, 8.22)];
    [logovimeoPath addCurveToPoint: CGPointMake(50.98, 9.1) controlPoint1: CGPointMake(49.42, 8.02) controlPoint2: CGPointMake(50.39, 8.35)];
    [logovimeoPath addCurveToPoint: CGPointMake(51.66, 11.75) controlPoint1: CGPointMake(51.49, 9.72) controlPoint2: CGPointMake(51.71, 10.6)];
    [logovimeoPath addCurveToPoint: CGPointMake(51.09, 15.17) controlPoint1: CGPointMake(51.63, 12.53) controlPoint2: CGPointMake(51.44, 13.68)];
    [logovimeoPath addCurveToPoint: CGPointMake(50.96, 15.72) controlPoint1: CGPointMake(51.04, 15.36) controlPoint2: CGPointMake(51, 15.55)];
    [logovimeoPath addCurveToPoint: CGPointMake(50.56, 17.76) controlPoint1: CGPointMake(50.69, 16.88) controlPoint2: CGPointMake(50.56, 17.56)];
    [logovimeoPath addCurveToPoint: CGPointMake(50.73, 18.98) controlPoint1: CGPointMake(50.53, 18.35) controlPoint2: CGPointMake(50.59, 18.75)];
    [logovimeoPath addCurveToPoint: CGPointMake(51.74, 19.31) controlPoint1: CGPointMake(50.87, 19.2) controlPoint2: CGPointMake(51.21, 19.31)];
    [logovimeoPath addCurveToPoint: CGPointMake(52.81, 18.84) controlPoint1: CGPointMake(51.98, 19.31) controlPoint2: CGPointMake(52.34, 19.16)];
    [logovimeoPath addCurveToPoint: CGPointMake(52.75, 17.74) controlPoint1: CGPointMake(52.76, 18.49) controlPoint2: CGPointMake(52.75, 18.12)];
    [logovimeoPath addCurveToPoint: CGPointMake(55.79, 11.25) controlPoint1: CGPointMake(52.78, 15.46) controlPoint2: CGPointMake(53.79, 13.3)];
    [logovimeoPath addLineToPoint: CGPointMake(55.87, 11.17)];
    [logovimeoPath addCurveToPoint: CGPointMake(56.48, 10.59) controlPoint1: CGPointMake(56.07, 10.97) controlPoint2: CGPointMake(56.27, 10.77)];
    [logovimeoPath addCurveToPoint: CGPointMake(63.55, 7.87) controlPoint1: CGPointMake(58.52, 8.78) controlPoint2: CGPointMake(60.88, 7.87)];
    [logovimeoPath addCurveToPoint: CGPointMake(67.94, 11.24) controlPoint1: CGPointMake(66.31, 7.87) controlPoint2: CGPointMake(67.77, 9)];
    [logovimeoPath addCurveToPoint: CGPointMake(65.58, 15.66) controlPoint1: CGPointMake(68.05, 12.67) controlPoint2: CGPointMake(67.26, 14.14)];
    [logovimeoPath addCurveToPoint: CGPointMake(58.78, 18.81) controlPoint1: CGPointMake(63.78, 17.31) controlPoint2: CGPointMake(61.51, 18.36)];
    [logovimeoPath addCurveToPoint: CGPointMake(61.06, 19.86) controlPoint1: CGPointMake(59.29, 19.51) controlPoint2: CGPointMake(60.05, 19.86)];
    [logovimeoPath addCurveToPoint: CGPointMake(67.69, 18.32) controlPoint1: CGPointMake(63.09, 19.86) controlPoint2: CGPointMake(65.3, 19.35)];
    [logovimeoPath addCurveToPoint: CGPointMake(68, 18.18) controlPoint1: CGPointMake(67.79, 18.27) controlPoint2: CGPointMake(67.9, 18.23)];
    [logovimeoPath addCurveToPoint: CGPointMake(67.96, 17.66) controlPoint1: CGPointMake(67.98, 18.01) controlPoint2: CGPointMake(67.97, 17.84)];
    [logovimeoPath addCurveToPoint: CGPointMake(69.61, 12.18) controlPoint1: CGPointMake(67.84, 15.7) controlPoint2: CGPointMake(68.39, 13.88)];
    [logovimeoPath addCurveToPoint: CGPointMake(70.58, 11.01) controlPoint1: CGPointMake(69.9, 11.78) controlPoint2: CGPointMake(70.22, 11.39)];
    [logovimeoPath addCurveToPoint: CGPointMake(78.21, 7.64) controlPoint1: CGPointMake(72.6, 8.76) controlPoint2: CGPointMake(75.14, 7.64)];
    [logovimeoPath addCurveToPoint: CGPointMake(82.68, 9.62) controlPoint1: CGPointMake(80.18, 7.64) controlPoint2: CGPointMake(81.67, 8.3)];
    [logovimeoPath addCurveToPoint: CGPointMake(83.99, 14.29) controlPoint1: CGPointMake(83.64, 10.82) controlPoint2: CGPointMake(84.07, 12.38)];
    [logovimeoPath addCurveToPoint: CGPointMake(81.12, 20.99) controlPoint1: CGPointMake(83.88, 16.87) controlPoint2: CGPointMake(82.92, 19.1)];
    [logovimeoPath addCurveToPoint: CGPointMake(74.41, 23.81) controlPoint1: CGPointMake(79.32, 22.87) controlPoint2: CGPointMake(77.08, 23.81)];
    [logovimeoPath addCurveToPoint: CGPointMake(69.35, 21.66) controlPoint1: CGPointMake(72.19, 23.81) controlPoint2: CGPointMake(70.5, 23.09)];
    [logovimeoPath addCurveToPoint: CGPointMake(68.68, 20.6) controlPoint1: CGPointMake(69.09, 21.33) controlPoint2: CGPointMake(68.87, 20.98)];
    [logovimeoPath addCurveToPoint: CGPointMake(67.73, 21.16) controlPoint1: CGPointMake(68.38, 20.78) controlPoint2: CGPointMake(68.06, 20.97)];
    [logovimeoPath addCurveToPoint: CGPointMake(58.66, 23.73) controlPoint1: CGPointMake(64.75, 22.87) controlPoint2: CGPointMake(61.72, 23.73)];
    [logovimeoPath addCurveToPoint: CGPointMake(53.76, 21.45) controlPoint1: CGPointMake(56.38, 23.73) controlPoint2: CGPointMake(54.75, 22.97)];
    [logovimeoPath addCurveToPoint: CGPointMake(53.56, 21.12) controlPoint1: CGPointMake(53.69, 21.34) controlPoint2: CGPointMake(53.62, 21.24)];
    [logovimeoPath addLineToPoint: CGPointMake(53.47, 21.2)];
    [logovimeoPath addCurveToPoint: CGPointMake(47.82, 23.65) controlPoint1: CGPointMake(51.59, 22.83) controlPoint2: CGPointMake(49.7, 23.65)];
    [logovimeoPath addCurveToPoint: CGPointMake(45.16, 20.61) controlPoint1: CGPointMake(45.99, 23.65) controlPoint2: CGPointMake(45.1, 22.64)];
    [logovimeoPath addCurveToPoint: CGPointMake(45.69, 17.37) controlPoint1: CGPointMake(45.19, 19.71) controlPoint2: CGPointMake(45.36, 18.63)];
    [logovimeoPath addCurveToPoint: CGPointMake(46.21, 14.42) controlPoint1: CGPointMake(46.01, 16.11) controlPoint2: CGPointMake(46.19, 15.12)];
    [logovimeoPath addCurveToPoint: CGPointMake(46.22, 14.26) controlPoint1: CGPointMake(46.22, 14.36) controlPoint2: CGPointMake(46.22, 14.31)];
    [logovimeoPath addCurveToPoint: CGPointMake(45.24, 12.82) controlPoint1: CGPointMake(46.21, 13.3) controlPoint2: CGPointMake(45.88, 12.82)];
    [logovimeoPath addCurveToPoint: CGPointMake(43.95, 13.56) controlPoint1: CGPointMake(44.85, 12.82) controlPoint2: CGPointMake(44.42, 13.07)];
    [logovimeoPath addCurveToPoint: CGPointMake(42.62, 15.43) controlPoint1: CGPointMake(43.53, 14) controlPoint2: CGPointMake(43.09, 14.62)];
    [logovimeoPath addCurveToPoint: CGPointMake(40.88, 20.74) controlPoint1: CGPointMake(41.54, 17.26) controlPoint2: CGPointMake(40.96, 19.03)];
    [logovimeoPath addCurveToPoint: CGPointMake(41.24, 23.53) controlPoint1: CGPointMake(40.82, 21.96) controlPoint2: CGPointMake(40.94, 22.88)];
    [logovimeoPath addCurveToPoint: CGPointMake(37.11, 22.56) controlPoint1: CGPointMake(39.27, 23.59) controlPoint2: CGPointMake(37.9, 23.26)];
    [logovimeoPath addCurveToPoint: CGPointMake(36.15, 19.48) controlPoint1: CGPointMake(36.41, 21.94) controlPoint2: CGPointMake(36.09, 20.92)];
    [logovimeoPath addCurveToPoint: CGPointMake(36.56, 16.78) controlPoint1: CGPointMake(36.17, 18.58) controlPoint2: CGPointMake(36.31, 17.68)];
    [logovimeoPath addCurveToPoint: CGPointMake(36.97, 14.38) controlPoint1: CGPointMake(36.81, 15.88) controlPoint2: CGPointMake(36.95, 15.08)];
    [logovimeoPath addCurveToPoint: CGPointMake(35.83, 12.82) controlPoint1: CGPointMake(37.03, 13.34) controlPoint2: CGPointMake(36.65, 12.82)];
    [logovimeoPath addCurveToPoint: CGPointMake(33.55, 15.22) controlPoint1: CGPointMake(35.13, 12.82) controlPoint2: CGPointMake(34.37, 13.62)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.2, 20.24) controlPoint1: CGPointMake(32.74, 16.82) controlPoint2: CGPointMake(32.29, 18.5)];
    [logovimeoPath addCurveToPoint: CGPointMake(32.5, 23.53) controlPoint1: CGPointMake(32.14, 21.81) controlPoint2: CGPointMake(32.25, 22.91)];
    [logovimeoPath addCurveToPoint: CGPointMake(28.39, 22.31) controlPoint1: CGPointMake(30.57, 23.59) controlPoint2: CGPointMake(29.2, 23.18)];
    [logovimeoPath addCurveToPoint: CGPointMake(27.61, 20.76) controlPoint1: CGPointMake(28.02, 21.91) controlPoint2: CGPointMake(27.76, 21.39)];
    [logovimeoPath addCurveToPoint: CGPointMake(27.13, 21.2) controlPoint1: CGPointMake(27.45, 20.91) controlPoint2: CGPointMake(27.29, 21.06)];
    [logovimeoPath addCurveToPoint: CGPointMake(21.47, 23.65) controlPoint1: CGPointMake(25.24, 22.83) controlPoint2: CGPointMake(23.36, 23.65)];
    [logovimeoPath addCurveToPoint: CGPointMake(19.47, 22.81) controlPoint1: CGPointMake(20.6, 23.65) controlPoint2: CGPointMake(19.93, 23.37)];
    [logovimeoPath addCurveToPoint: CGPointMake(18.82, 20.61) controlPoint1: CGPointMake(19, 22.24) controlPoint2: CGPointMake(18.79, 21.51)];
    [logovimeoPath addCurveToPoint: CGPointMake(19.68, 16.32) controlPoint1: CGPointMake(18.84, 19.69) controlPoint2: CGPointMake(19.13, 18.25)];
    [logovimeoPath addCurveToPoint: CGPointMake(20.5, 13.2) controlPoint1: CGPointMake(20.23, 14.38) controlPoint2: CGPointMake(20.5, 13.34)];
    [logovimeoPath addCurveToPoint: CGPointMake(19.74, 12.1) controlPoint1: CGPointMake(20.5, 12.47) controlPoint2: CGPointMake(20.25, 12.1)];
    [logovimeoPath addCurveToPoint: CGPointMake(18.44, 12.89) controlPoint1: CGPointMake(19.58, 12.1) controlPoint2: CGPointMake(19.15, 12.36)];
    [logovimeoPath addCurveToPoint: CGPointMake(14.95, 18.75) controlPoint1: CGPointMake(17.91, 14.48) controlPoint2: CGPointMake(16.74, 16.44)];
    [logovimeoPath addCurveToPoint: CGPointMake(8.46, 23.73) controlPoint1: CGPointMake(12.39, 22.07) controlPoint2: CGPointMake(10.23, 23.73)];
    [logovimeoPath addCurveToPoint: CGPointMake(5.68, 20.69) controlPoint1: CGPointMake(7.37, 23.73) controlPoint2: CGPointMake(6.44, 22.72)];
    [logovimeoPath addLineToPoint: CGPointMake(4.17, 15.13)];
    [logovimeoPath addCurveToPoint: CGPointMake(2.36, 12.1) controlPoint1: CGPointMake(3.61, 13.11) controlPoint2: CGPointMake(3, 12.1)];
    [logovimeoPath addCurveToPoint: CGPointMake(0.88, 12.99) controlPoint1: CGPointMake(2.22, 12.1) controlPoint2: CGPointMake(1.73, 12.4)];
    [logovimeoPath addLineToPoint: CGPointMake(0, 11.85)];
    [logovimeoPath addCurveToPoint: CGPointMake(2.74, 9.4) controlPoint1: CGPointMake(0.93, 11.03) controlPoint2: CGPointMake(1.84, 10.22)];
    [logovimeoPath addCurveToPoint: CGPointMake(5.53, 7.72) controlPoint1: CGPointMake(3.98, 8.33) controlPoint2: CGPointMake(4.91, 7.77)];
    [logovimeoPath addCurveToPoint: CGPointMake(8.23, 10.71) controlPoint1: CGPointMake(6.99, 7.57) controlPoint2: CGPointMake(7.89, 8.57)];
    [logovimeoPath addCurveToPoint: CGPointMake(8.98, 15.02) controlPoint1: CGPointMake(8.59, 13.02) controlPoint2: CGPointMake(8.84, 14.46)];
    [logovimeoPath addCurveToPoint: CGPointMake(10.38, 17.89) controlPoint1: CGPointMake(9.41, 16.93) controlPoint2: CGPointMake(9.87, 17.89)];
    [logovimeoPath addCurveToPoint: CGPointMake(12.15, 16.03) controlPoint1: CGPointMake(10.77, 17.89) controlPoint2: CGPointMake(11.36, 17.27)];
    [logovimeoPath addCurveToPoint: CGPointMake(13.41, 13.19) controlPoint1: CGPointMake(12.93, 14.79) controlPoint2: CGPointMake(13.36, 13.84)];
    [logovimeoPath addCurveToPoint: CGPointMake(12.15, 11.58) controlPoint1: CGPointMake(13.53, 12.12) controlPoint2: CGPointMake(13.1, 11.58)];
    [logovimeoPath addCurveToPoint: CGPointMake(10.76, 11.89) controlPoint1: CGPointMake(11.7, 11.58) controlPoint2: CGPointMake(11.23, 11.68)];
    [logovimeoPath addCurveToPoint: CGPointMake(13.33, 8.12) controlPoint1: CGPointMake(11.31, 10.07) controlPoint2: CGPointMake(12.17, 8.82)];
    [logovimeoPath addCurveToPoint: CGPointMake(16.05, 7.48) controlPoint1: CGPointMake(14.1, 7.66) controlPoint2: CGPointMake(15.01, 7.45)];
    [logovimeoPath closePath];
    [logovimeoPath moveToPoint: CGPointMake(77.87, 11.09)];
    [logovimeoPath addCurveToPoint: CGPointMake(74.57, 13.04) controlPoint1: CGPointMake(76.56, 11.09) controlPoint2: CGPointMake(75.46, 11.74)];
    [logovimeoPath addCurveToPoint: CGPointMake(74.33, 13.41) controlPoint1: CGPointMake(74.49, 13.16) controlPoint2: CGPointMake(74.41, 13.28)];
    [logovimeoPath addCurveToPoint: CGPointMake(73.06, 17.47) controlPoint1: CGPointMake(73.54, 14.68) controlPoint2: CGPointMake(73.12, 16.03)];
    [logovimeoPath addCurveToPoint: CGPointMake(73.44, 19.33) controlPoint1: CGPointMake(73.04, 18.17) controlPoint2: CGPointMake(73.16, 18.79)];
    [logovimeoPath addCurveToPoint: CGPointMake(74.75, 20.26) controlPoint1: CGPointMake(73.75, 19.95) controlPoint2: CGPointMake(74.19, 20.26)];
    [logovimeoPath addCurveToPoint: CGPointMake(78, 18.02) controlPoint1: CGPointMake(76.02, 20.26) controlPoint2: CGPointMake(77.1, 19.51)];
    [logovimeoPath addCurveToPoint: CGPointMake(79.22, 14.13) controlPoint1: CGPointMake(78.76, 16.78) controlPoint2: CGPointMake(79.17, 15.48)];
    [logovimeoPath addCurveToPoint: CGPointMake(78.91, 12.04) controlPoint1: CGPointMake(79.25, 13.37) controlPoint2: CGPointMake(79.15, 12.67)];
    [logovimeoPath addCurveToPoint: CGPointMake(77.87, 11.09) controlPoint1: CGPointMake(78.67, 11.41) controlPoint2: CGPointMake(78.32, 11.09)];
    [logovimeoPath closePath];
    [color setFill];
    [logovimeoPath fill];
}

+ (void)drawOngoingcall
{
    //// Color Declarations
    UIColor* fillColor9 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    UIColor* black16 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.16];
    UIColor* fillColor12 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.4];

    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(9, 18)];
        [bezierPath addCurveToPoint: CGPointMake(18, 9) controlPoint1: CGPointMake(13.97, 18) controlPoint2: CGPointMake(18, 13.97)];
        [bezierPath addCurveToPoint: CGPointMake(9, 0) controlPoint1: CGPointMake(18, 4.03) controlPoint2: CGPointMake(13.97, 0)];
        [bezierPath addCurveToPoint: CGPointMake(0, 9) controlPoint1: CGPointMake(4.03, 0) controlPoint2: CGPointMake(0, 4.03)];
        [bezierPath addCurveToPoint: CGPointMake(9, 18) controlPoint1: CGPointMake(0, 13.97) controlPoint2: CGPointMake(4.03, 18)];
        [bezierPath closePath];
        bezierPath.usesEvenOddFillRule = YES;

        [black16 setFill];
        [bezierPath fill];


        //// Oval Drawing
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(6, 6, 6, 6)];
        [fillColor9 setFill];
        [ovalPath fill];


        //// Oval 2 Drawing
        UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(3, 3, 12, 12)];
        [fillColor12 setFill];
        [oval2Path fill];
    }
}

+ (void)drawJoinongoingcallWithColor: (UIColor*)color
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Group 2
    {
        //// Group 3
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, 0.32);
            CGContextBeginTransparencyLayer(context, NULL);

            //// Clip Clip
            UIBezierPath* clipPath = [UIBezierPath bezierPath];
            [clipPath moveToPoint: CGPointMake(9, 18)];
            [clipPath addCurveToPoint: CGPointMake(18, 9) controlPoint1: CGPointMake(13.97, 18) controlPoint2: CGPointMake(18, 13.97)];
            [clipPath addCurveToPoint: CGPointMake(9, 0) controlPoint1: CGPointMake(18, 4.03) controlPoint2: CGPointMake(13.97, 0)];
            [clipPath addCurveToPoint: CGPointMake(0, 9) controlPoint1: CGPointMake(4.03, 0) controlPoint2: CGPointMake(0, 4.03)];
            [clipPath addCurveToPoint: CGPointMake(9, 18) controlPoint1: CGPointMake(0, 13.97) controlPoint2: CGPointMake(4.03, 18)];
            [clipPath closePath];
            clipPath.usesEvenOddFillRule = YES;

            [clipPath addClip];


            //// Bezier Drawing
            UIBezierPath* bezierPath = [UIBezierPath bezierPath];
            [bezierPath moveToPoint: CGPointMake(9, 18)];
            [bezierPath addCurveToPoint: CGPointMake(18, 9) controlPoint1: CGPointMake(13.97, 18) controlPoint2: CGPointMake(18, 13.97)];
            [bezierPath addCurveToPoint: CGPointMake(9, 0) controlPoint1: CGPointMake(18, 4.03) controlPoint2: CGPointMake(13.97, 0)];
            [bezierPath addCurveToPoint: CGPointMake(0, 9) controlPoint1: CGPointMake(4.03, 0) controlPoint2: CGPointMake(0, 4.03)];
            [bezierPath addCurveToPoint: CGPointMake(9, 18) controlPoint1: CGPointMake(0, 13.97) controlPoint2: CGPointMake(4.03, 18)];
            [bezierPath closePath];
            [color setStroke];
            bezierPath.lineWidth = 2;
            [bezierPath stroke];


            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }


        //// Group 4
        {
            CGContextSaveGState(context);
            CGContextSetAlpha(context, 0.72);
            CGContextBeginTransparencyLayer(context, NULL);

            //// Clip Clip 2
            UIBezierPath* clip2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(3, 3, 12, 12)];
            [clip2Path addClip];


            //// Oval Drawing
            UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(3, 3, 12, 12)];
            [color setStroke];
            ovalPath.lineWidth = 2;
            [ovalPath stroke];


            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }


        //// Group 5
        {
            CGContextSaveGState(context);
            CGContextBeginTransparencyLayer(context, NULL);

            //// Clip Clip 3
            UIBezierPath* clip3Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(6, 6, 6, 6)];
            [clip3Path addClip];


            //// Oval 3 Drawing
            UIBezierPath* oval3Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(6, 6, 6, 6)];
            [color setStroke];
            oval3Path.lineWidth = 2;
            [oval3Path stroke];


            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
    }
}

+ (void)drawLogoWithColor: (UIColor*)color
{

    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(256.09, 140.1)];
    [bezier2Path addCurveToPoint: CGPointMake(188.37, 208) controlPoint1: CGPointMake(256.09, 177.6) controlPoint2: CGPointMake(225.88, 208)];
    [bezier2Path addCurveToPoint: CGPointMake(147.85, 194.6) controlPoint1: CGPointMake(173.26, 208) controlPoint2: CGPointMake(159.16, 203)];
    [bezier2Path addCurveToPoint: CGPointMake(168.06, 140) controlPoint1: CGPointMake(160.46, 179.9) controlPoint2: CGPointMake(168.06, 160.9)];
    [bezier2Path addLineToPoint: CGPointMake(168.06, 32)];
    [bezier2Path addCurveToPoint: CGPointMake(136.05, 0) controlPoint1: CGPointMake(168.06, 14.4) controlPoint2: CGPointMake(153.66, 0)];
    [bezier2Path addCurveToPoint: CGPointMake(104.04, 32) controlPoint1: CGPointMake(118.44, 0) controlPoint2: CGPointMake(104.04, 14.3)];
    [bezier2Path addLineToPoint: CGPointMake(104.04, 140.1)];
    [bezier2Path addCurveToPoint: CGPointMake(124.75, 194.7) controlPoint1: CGPointMake(104.04, 160.9) controlPoint2: CGPointMake(112.04, 180)];
    [bezier2Path addCurveToPoint: CGPointMake(84.23, 208) controlPoint1: CGPointMake(113.44, 203) controlPoint2: CGPointMake(99.34, 208)];
    [bezier2Path addCurveToPoint: CGPointMake(16.01, 140.1) controlPoint1: CGPointMake(46.72, 208) controlPoint2: CGPointMake(16.01, 177.5)];
    [bezier2Path addLineToPoint: CGPointMake(16.01, 8.2)];
    [bezier2Path addLineToPoint: CGPointMake(0, 8.2)];
    [bezier2Path addLineToPoint: CGPointMake(0, 140.1)];
    [bezier2Path addCurveToPoint: CGPointMake(84.33, 224) controlPoint1: CGPointMake(0, 186.3) controlPoint2: CGPointMake(38.01, 224)];
    [bezier2Path addCurveToPoint: CGPointMake(136.55, 205.9) controlPoint1: CGPointMake(103.94, 224) controlPoint2: CGPointMake(122.14, 217.2)];
    [bezier2Path addCurveToPoint: CGPointMake(188.27, 224) controlPoint1: CGPointMake(150.86, 217.2) controlPoint2: CGPointMake(168.66, 224)];
    [bezier2Path addCurveToPoint: CGPointMake(272, 140.1) controlPoint1: CGPointMake(234.59, 224) controlPoint2: CGPointMake(272, 186.4)];
    [bezier2Path addLineToPoint: CGPointMake(272, 8.2)];
    [bezier2Path addLineToPoint: CGPointMake(255.99, 8.2)];
    [bezier2Path addLineToPoint: CGPointMake(255.99, 140.1)];
    [bezier2Path addLineToPoint: CGPointMake(256.09, 140.1)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(136.05, 183.8)];
    [bezier2Path addCurveToPoint: CGPointMake(120.04, 140.1) controlPoint1: CGPointMake(126.05, 172) controlPoint2: CGPointMake(120.04, 156.7)];
    [bezier2Path addLineToPoint: CGPointMake(120.04, 32)];
    [bezier2Path addCurveToPoint: CGPointMake(136.05, 16) controlPoint1: CGPointMake(120.04, 23.2) controlPoint2: CGPointMake(127.25, 16)];
    [bezier2Path addCurveToPoint: CGPointMake(152.06, 32) controlPoint1: CGPointMake(144.85, 16) controlPoint2: CGPointMake(152.06, 23.2)];
    [bezier2Path addLineToPoint: CGPointMake(152.06, 140.1)];
    [bezier2Path addCurveToPoint: CGPointMake(136.05, 183.8) controlPoint1: CGPointMake(152.06, 156.7) controlPoint2: CGPointMake(146.05, 171.9)];
    [bezier2Path closePath];
    bezier2Path.miterLimit = 4;

    [color setFill];
    [bezier2Path fill];
}

+ (void)drawWireWithColor: (UIColor*)color
{

    //// Logo 2 Drawing
    UIBezierPath* logo2Path = [UIBezierPath bezierPath];
    [logo2Path moveToPoint: CGPointMake(42.72, 41.02)];
    [logo2Path addCurveToPoint: CGPointMake(39.11, 31.27) controlPoint1: CGPointMake(40.47, 38.38) controlPoint2: CGPointMake(39.11, 34.98)];
    [logo2Path addLineToPoint: CGPointMake(39.11, 7.14)];
    [logo2Path addCurveToPoint: CGPointMake(42.73, 3.57) controlPoint1: CGPointMake(39.11, 5.17) controlPoint2: CGPointMake(40.74, 3.57)];
    [logo2Path addCurveToPoint: CGPointMake(46.34, 7.14) controlPoint1: CGPointMake(44.72, 3.57) controlPoint2: CGPointMake(46.34, 5.17)];
    [logo2Path addLineToPoint: CGPointMake(46.34, 31.27)];
    [logo2Path addCurveToPoint: CGPointMake(42.72, 41.02) controlPoint1: CGPointMake(46.34, 34.98) controlPoint2: CGPointMake(44.97, 38.38)];
    [logo2Path addLineToPoint: CGPointMake(42.72, 41.02)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(69.83, 31.27)];
    [logo2Path addCurveToPoint: CGPointMake(54.55, 46.43) controlPoint1: CGPointMake(69.83, 39.63) controlPoint2: CGPointMake(63.02, 46.43)];
    [logo2Path addCurveToPoint: CGPointMake(45.4, 43.45) controlPoint1: CGPointMake(51.13, 46.43) controlPoint2: CGPointMake(47.95, 45.31)];
    [logo2Path addCurveToPoint: CGPointMake(49.95, 31.27) controlPoint1: CGPointMake(48.25, 40.17) controlPoint2: CGPointMake(49.95, 35.92)];
    [logo2Path addLineToPoint: CGPointMake(49.96, 7.14)];
    [logo2Path addCurveToPoint: CGPointMake(42.73, 0) controlPoint1: CGPointMake(49.96, 3.2) controlPoint2: CGPointMake(46.72, 0)];
    [logo2Path addCurveToPoint: CGPointMake(35.5, 7.14) controlPoint1: CGPointMake(38.74, 0) controlPoint2: CGPointMake(35.5, 3.2)];
    [logo2Path addLineToPoint: CGPointMake(35.49, 31.27)];
    [logo2Path addCurveToPoint: CGPointMake(40.16, 43.45) controlPoint1: CGPointMake(35.49, 35.92) controlPoint2: CGPointMake(37.31, 40.17)];
    [logo2Path addCurveToPoint: CGPointMake(31.01, 46.43) controlPoint1: CGPointMake(37.61, 45.31) controlPoint2: CGPointMake(34.43, 46.43)];
    [logo2Path addCurveToPoint: CGPointMake(15.61, 31.27) controlPoint1: CGPointMake(22.54, 46.43) controlPoint2: CGPointMake(15.61, 39.63)];
    [logo2Path addLineToPoint: CGPointMake(15.61, 1.83)];
    [logo2Path addLineToPoint: CGPointMake(12, 1.83)];
    [logo2Path addLineToPoint: CGPointMake(12, 31.27)];
    [logo2Path addCurveToPoint: CGPointMake(31.05, 50) controlPoint1: CGPointMake(12, 41.6) controlPoint2: CGPointMake(20.59, 50)];
    [logo2Path addCurveToPoint: CGPointMake(42.84, 45.95) controlPoint1: CGPointMake(35.49, 50) controlPoint2: CGPointMake(39.6, 48.48)];
    [logo2Path addCurveToPoint: CGPointMake(54.53, 50) controlPoint1: CGPointMake(46.07, 48.48) controlPoint2: CGPointMake(50.09, 50)];
    [logo2Path addCurveToPoint: CGPointMake(73.45, 31.27) controlPoint1: CGPointMake(64.99, 50) controlPoint2: CGPointMake(73.45, 41.6)];
    [logo2Path addLineToPoint: CGPointMake(73.45, 1.83)];
    [logo2Path addLineToPoint: CGPointMake(69.83, 1.83)];
    [logo2Path addLineToPoint: CGPointMake(69.83, 31.27)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(84.3, 49.05)];
    [logo2Path addLineToPoint: CGPointMake(87.91, 49.05)];
    [logo2Path addLineToPoint: CGPointMake(87.91, 1.73)];
    [logo2Path addLineToPoint: CGPointMake(84.3, 1.73)];
    [logo2Path addLineToPoint: CGPointMake(84.3, 49.05)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(119.55, 0.91)];
    [logo2Path addCurveToPoint: CGPointMake(102.37, 9.89) controlPoint1: CGPointMake(112.42, 0.91) controlPoint2: CGPointMake(106.12, 4.47)];
    [logo2Path addLineToPoint: CGPointMake(102.37, 1.73)];
    [logo2Path addLineToPoint: CGPointMake(98.75, 1.73)];
    [logo2Path addLineToPoint: CGPointMake(98.75, 49.05)];
    [logo2Path addLineToPoint: CGPointMake(102.37, 49.05)];
    [logo2Path addLineToPoint: CGPointMake(102.37, 21.45)];
    [logo2Path addLineToPoint: CGPointMake(102.37, 21.45)];
    [logo2Path addCurveToPoint: CGPointMake(119.55, 4.48) controlPoint1: CGPointMake(102.37, 12.09) controlPoint2: CGPointMake(110.08, 4.48)];
    [logo2Path addLineToPoint: CGPointMake(119.55, 0.91)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(126.33, 38.98)];
    [logo2Path addCurveToPoint: CGPointMake(127.55, 10.62) controlPoint1: CGPointMake(119.3, 30.74) controlPoint2: CGPointMake(119.7, 18.38)];
    [logo2Path addCurveToPoint: CGPointMake(156.25, 9.41) controlPoint1: CGPointMake(135.4, 2.87) controlPoint2: CGPointMake(147.92, 2.46)];
    [logo2Path addLineToPoint: CGPointMake(126.33, 38.98)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(161.37, 9.4)];
    [logo2Path addCurveToPoint: CGPointMake(160.14, 8.1) controlPoint1: CGPointMake(160.98, 8.96) controlPoint2: CGPointMake(160.57, 8.52)];
    [logo2Path addCurveToPoint: CGPointMake(125, 8.1) controlPoint1: CGPointMake(150.45, -1.48) controlPoint2: CGPointMake(134.68, -1.48)];
    [logo2Path addCurveToPoint: CGPointMake(125, 42.82) controlPoint1: CGPointMake(115.31, 17.67) controlPoint2: CGPointMake(115.31, 33.25)];
    [logo2Path addCurveToPoint: CGPointMake(160.13, 42.82) controlPoint1: CGPointMake(134.68, 52.39) controlPoint2: CGPointMake(150.44, 52.39)];
    [logo2Path addLineToPoint: CGPointMake(157.58, 40.3)];
    [logo2Path addCurveToPoint: CGPointMake(128.88, 41.5) controlPoint1: CGPointMake(149.73, 48.05) controlPoint2: CGPointMake(137.22, 48.45)];
    [logo2Path addLineToPoint: CGPointMake(143.84, 26.72)];
    [logo2Path addLineToPoint: CGPointMake(161.37, 9.4)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(164.71, 2.14)];
    [logo2Path addLineToPoint: CGPointMake(165.98, 2.14)];
    [logo2Path addLineToPoint: CGPointMake(165.98, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(166.36, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(166.36, 2.14)];
    [logo2Path addLineToPoint: CGPointMake(167.63, 2.14)];
    [logo2Path addLineToPoint: CGPointMake(167.63, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(164.71, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(164.71, 2.14)];
    [logo2Path closePath];
    [logo2Path moveToPoint: CGPointMake(171.43, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(170.17, 4.89)];
    [logo2Path addLineToPoint: CGPointMake(168.92, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(168.33, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(168.33, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(168.69, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(168.69, 2.17)];
    [logo2Path addLineToPoint: CGPointMake(169.99, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(170.34, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(171.63, 2.18)];
    [logo2Path addLineToPoint: CGPointMake(171.63, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(172, 5.36)];
    [logo2Path addLineToPoint: CGPointMake(172, 1.79)];
    [logo2Path addLineToPoint: CGPointMake(171.43, 1.79)];
    [logo2Path closePath];
    logo2Path.miterLimit = 4;

    logo2Path.usesEvenOddFillRule = YES;

    [color setFill];
    [logo2Path fill];
}

+ (void)drawShieldverified
{
    //// Color Declarations
    UIColor* e2EE = [UIColor colorWithRed: 0 green: 0.588 blue: 0.941 alpha: 1];
    UIColor* black24 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.24];

    //// path-1 Drawing
    UIBezierPath* path1Path = [UIBezierPath bezierPath];
    [path1Path moveToPoint: CGPointMake(15, 1.87)];
    [path1Path addLineToPoint: CGPointMake(8, 0)];
    [path1Path addLineToPoint: CGPointMake(1, 2)];
    [path1Path addLineToPoint: CGPointMake(1, 8)];
    [path1Path addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(1, 12) controlPoint2: CGPointMake(4.01, 15.1)];
    [path1Path addCurveToPoint: CGPointMake(15, 8) controlPoint1: CGPointMake(12.03, 15.1) controlPoint2: CGPointMake(15, 12)];
    [path1Path addLineToPoint: CGPointMake(15, 1.87)];
    [path1Path closePath];
    path1Path.miterLimit = 4;

    path1Path.usesEvenOddFillRule = YES;

    [e2EE setFill];
    [path1Path fill];


    //// Shadow Drawing
    UIBezierPath* shadowPath = [UIBezierPath bezierPath];
    [shadowPath moveToPoint: CGPointMake(15, 1.87)];
    [shadowPath addLineToPoint: CGPointMake(8, 0)];
    [shadowPath addLineToPoint: CGPointMake(8, 16)];
    [shadowPath addCurveToPoint: CGPointMake(15, 8) controlPoint1: CGPointMake(12.03, 15.09) controlPoint2: CGPointMake(15, 12)];
    [shadowPath addLineToPoint: CGPointMake(15, 1.87)];
    [shadowPath closePath];
    shadowPath.miterLimit = 4;

    shadowPath.usesEvenOddFillRule = YES;

    [black24 setFill];
    [shadowPath fill];
}

+ (void)drawShieldnotverified
{
    //// Color Declarations
    UIColor* e2EE = [UIColor colorWithRed: 0 green: 0.588 blue: 0.941 alpha: 1];

    //// Path Drawing
    UIBezierPath* pathPath = [UIBezierPath bezierPath];
    [pathPath moveToPoint: CGPointMake(15, 1.87)];
    [pathPath addLineToPoint: CGPointMake(15, 8)];
    [pathPath addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(15, 12) controlPoint2: CGPointMake(12.03, 15.1)];
    [pathPath addCurveToPoint: CGPointMake(1, 8) controlPoint1: CGPointMake(4.01, 15.1) controlPoint2: CGPointMake(1, 12)];
    [pathPath addLineToPoint: CGPointMake(1, 2)];
    [pathPath addLineToPoint: CGPointMake(8, 0)];
    [pathPath addLineToPoint: CGPointMake(15, 1.87)];
    [pathPath addLineToPoint: CGPointMake(15, 1.87)];
    [pathPath closePath];
    [pathPath moveToPoint: CGPointMake(8, 0.83)];
    [pathPath addLineToPoint: CGPointMake(1.8, 2.6)];
    [pathPath addLineToPoint: CGPointMake(1.8, 8)];
    [pathPath addCurveToPoint: CGPointMake(8, 15.18) controlPoint1: CGPointMake(1.8, 11.43) controlPoint2: CGPointMake(4.32, 14.28)];
    [pathPath addLineToPoint: CGPointMake(8, 0.83)];
    [pathPath addLineToPoint: CGPointMake(8, 0.83)];
    [pathPath addLineToPoint: CGPointMake(8, 0.83)];
    [pathPath closePath];
    pathPath.miterLimit = 4;

    pathPath.usesEvenOddFillRule = YES;

    [e2EE setFill];
    [pathPath fill];
}

+ (void)drawMentionsWithFrame: (CGRect)frame backgroundColor: (UIColor*)backgroundColor
{
    //// Color Declarations
    UIColor* black40 = [backgroundColor colorWithAlphaComponent: 0.4];


    //// Subframes
    CGRect frame2 = CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 12) * 1.00000 + 0.5), 16, 12);


    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMinY(frame) + 1)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 25, CGRectGetMinY(frame) + 1)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 32) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 11.7, CGRectGetMinY(frame) + 1) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 45.3)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 25, CGRectGetMaxY(frame) - 8) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 18.7) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 11.7, CGRectGetMaxY(frame) - 8)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 1, CGRectGetMinY(frame2) + 0.33333 * CGRectGetHeight(frame2))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 8, CGRectGetMinY(frame2) + 0.91667 * CGRectGetHeight(frame2))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 15, CGRectGetMinY(frame2) + 0.33333 * CGRectGetHeight(frame2))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMaxY(frame) - 8)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 32) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 11.7, CGRectGetMaxY(frame) - 8) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 18.7)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMinY(frame) + 1) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 45.3) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 11.7, CGRectGetMinY(frame) + 1)];
    [bezierPath closePath];
    bezierPath.miterLimit = 4;

    [black40 setFill];
    [bezierPath fill];


    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMinY(frame))];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 24.28, CGRectGetMinY(frame))];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 32.13) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 10.82, CGRectGetMinY(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 45.91)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 24.28, CGRectGetMaxY(frame) - 7.25) controlPoint1: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 18.34) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 10.82, CGRectGetMaxY(frame) - 7.25)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 0.92, CGRectGetMinY(frame2) + 0.39545 * CGRectGetHeight(frame2))];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 8, CGRectGetMinY(frame2) + 1.00000 * CGRectGetHeight(frame2))];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 15.08, CGRectGetMinY(frame2) + 0.39545 * CGRectGetHeight(frame2))];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMaxY(frame) - 7.25)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 32.13) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 10.82, CGRectGetMaxY(frame) - 7.25) controlPoint2: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 18.34)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMinY(frame)) controlPoint1: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 45.91) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 10.82, CGRectGetMinY(frame))];
    [bezier2Path closePath];
    bezier2Path.miterLimit = 4;

    [black40 setFill];
    [bezier2Path fill];
}

+ (void)drawTabWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0, 8.5)];
    [bezierPath addLineToPoint: CGPointMake(1, 8.5)];
    [bezierPath addLineToPoint: CGPointMake(9, 0.5)];
    [bezierPath addLineToPoint: CGPointMake(17, 8.5)];
    [bezierPath addLineToPoint: CGPointMake(18, 8.5)];
    bezierPath.lineJoinStyle = kCGLineJoinRound;

    [color setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];
}

#pragma mark Generated Images

+ (UIImage*)imageOfIcon_0x100_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x100_32ptWithColor: color];

    UIImage* imageOfIcon_0x100_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x100_32pt;
}

+ (UIImage*)imageOfIcon_0x102_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x102_32ptWithColor: color];

    UIImage* imageOfIcon_0x102_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x102_32pt;
}

+ (UIImage*)imageOfIcon_0x104_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x104_32ptWithColor: color];

    UIImage* imageOfIcon_0x104_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x104_32pt;
}

+ (UIImage*)imageOfIcon_0x120_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x120_32ptWithColor: color];

    UIImage* imageOfIcon_0x120_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x120_32pt;
}

+ (UIImage*)imageOfIcon_0x125_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x125_32ptWithColor: color];

    UIImage* imageOfIcon_0x125_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x125_32pt;
}

+ (UIImage*)imageOfIcon_0x137_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x137_32ptWithColor: color];

    UIImage* imageOfIcon_0x137_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x137_32pt;
}

+ (UIImage*)imageOfIcon_0x143_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x143_32ptWithColor: color];

    UIImage* imageOfIcon_0x143_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x143_32pt;
}

+ (UIImage*)imageOfIcon_0x144_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x144_32ptWithColor: color];

    UIImage* imageOfIcon_0x144_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x144_32pt;
}

+ (UIImage*)imageOfIcon_0x145_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x145_32ptWithColor: color];

    UIImage* imageOfIcon_0x145_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x145_32pt;
}

+ (UIImage*)imageOfIcon_0x150_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x150_32ptWithColor: color];

    UIImage* imageOfIcon_0x150_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x150_32pt;
}

+ (UIImage*)imageOfIcon_0x158_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x158_32ptWithColor: color];

    UIImage* imageOfIcon_0x158_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x158_32pt;
}

+ (UIImage*)imageOfIcon_0x162_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x162_32ptWithColor: color];

    UIImage* imageOfIcon_0x162_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x162_32pt;
}

+ (UIImage*)imageOfIcon_0x177_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x177_32ptWithColor: color];

    UIImage* imageOfIcon_0x177_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x177_32pt;
}

+ (UIImage*)imageOfIcon_0x193_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x193_32ptWithColor: color];

    UIImage* imageOfIcon_0x193_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x193_32pt;
}

+ (UIImage*)imageOfIcon_0x194_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x194_32ptWithColor: color];

    UIImage* imageOfIcon_0x194_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x194_32pt;
}

+ (UIImage*)imageOfIcon_0x195_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x195_32ptWithColor: color];

    UIImage* imageOfIcon_0x195_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x195_32pt;
}

+ (UIImage*)imageOfIcon_0x197_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x197_32ptWithColor: color];

    UIImage* imageOfIcon_0x197_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x197_32pt;
}

+ (UIImage*)imageOfIcon_0x205_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x205_32ptWithColor: color];

    UIImage* imageOfIcon_0x205_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x205_32pt;
}

+ (UIImage*)imageOfIcon_0x212_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x212_32ptWithColor: color];

    UIImage* imageOfIcon_0x212_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x212_32pt;
}

+ (UIImage*)imageOfIcon_0x198_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x198_32ptWithColor: color];

    UIImage* imageOfIcon_0x198_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x198_32pt;
}

+ (UIImage*)imageOfIcon_0x217_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x217_32ptWithColor: color];

    UIImage* imageOfIcon_0x217_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x217_32pt;
}

+ (UIImage*)imageOfIcon_0x117_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x117_32ptWithColor: color];

    UIImage* imageOfIcon_0x117_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x117_32pt;
}

+ (UIImage*)imageOfIcon_0x126_24ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(48, 48), NO, 0.0f);
    [WireStyleKit drawIcon_0x126_24ptWithColor: color];

    UIImage* imageOfIcon_0x126_24pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x126_24pt;
}

+ (UIImage*)imageOfIcon_0x128_8ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0f);
    [WireStyleKit drawIcon_0x128_8ptWithColor: color];

    UIImage* imageOfIcon_0x128_8pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x128_8pt;
}

+ (UIImage*)imageOfIcon_0x163_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x163_32ptWithColor: color];

    UIImage* imageOfIcon_0x163_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x163_32pt;
}

+ (UIImage*)imageOfIcon_0x221_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x221_32ptWithColor: color];

    UIImage* imageOfIcon_0x221_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x221_32pt;
}

+ (UIImage*)imageOfInviteWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0f);
    [WireStyleKit drawInviteWithColor: color];

    UIImage* imageOfInvite = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfInvite;
}

+ (UIImage*)imageOfIcon_0x123_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x123_32ptWithColor: color];

    UIImage* imageOfIcon_0x123_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x123_32pt;
}

+ (UIImage*)imageOfIcon_0x128_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x128_32ptWithColor: color];

    UIImage* imageOfIcon_0x128_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x128_32pt;
}

+ (UIImage*)imageOfIcon_0x113_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x113_32ptWithColor: color];

    UIImage* imageOfIcon_0x113_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x113_32pt;
}

+ (UIImage*)imageOfIcon_0x121_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x121_32ptWithColor: color];

    UIImage* imageOfIcon_0x121_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x121_32pt;
}

+ (UIImage*)imageOfIcon_0x111_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x111_32ptWithColor: color];

    UIImage* imageOfIcon_0x111_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x111_32pt;
}

+ (UIImage*)imageOfIcon_0x226_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x226_32ptWithColor: color];

    UIImage* imageOfIcon_0x226_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x226_32pt;
}

+ (UIImage*)imageOfIcon_0x164_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x164_32ptWithColor: color];

    UIImage* imageOfIcon_0x164_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x164_32pt;
}

+ (UIImage*)imageOfIcon_0x1420_28ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(56, 56), NO, 0.0f);
    [WireStyleKit drawIcon_0x1420_28ptWithColor: color];

    UIImage* imageOfIcon_0x1420_28pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x1420_28pt;
}

+ (UIImage*)imageOfIcon_0x110_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x110_32ptWithColor: color];

    UIImage* imageOfIcon_0x110_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x110_32pt;
}

+ (UIImage*)imageOfIcon_0x103_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x103_32ptWithColor: color];

    UIImage* imageOfIcon_0x103_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x103_32pt;
}

+ (UIImage*)imageOfIcon_0x211_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x211_32ptWithColor: color];

    UIImage* imageOfIcon_0x211_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x211_32pt;
}

+ (UIImage*)imageOfIcon_0x1000_28ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(56, 56), NO, 0.0f);
    [WireStyleKit drawIcon_0x1000_28ptWithColor: color];

    UIImage* imageOfIcon_0x1000_28pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x1000_28pt;
}

+ (UIImage*)imageOfIcon_0x142_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x142_32ptWithColor: color];

    UIImage* imageOfIcon_0x142_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x142_32pt;
}

+ (UIImage*)imageOfIcon_0x152_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x152_32ptWithColor: color];

    UIImage* imageOfIcon_0x152_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x152_32pt;
}

+ (UIImage*)imageOfIcon_0x146_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x146_32ptWithColor: color];

    UIImage* imageOfIcon_0x146_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x146_32pt;
}

+ (UIImage*)imageOfIcon_0x227_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x227_32ptWithColor: color];

    UIImage* imageOfIcon_0x227_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x227_32pt;
}

+ (UIImage*)imageOfIcon_0x159_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x159_32ptWithColor: color];

    UIImage* imageOfIcon_0x159_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x159_32pt;
}

+ (UIImage*)imageOfIcon_0x228_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x228_32ptWithColor: color];

    UIImage* imageOfIcon_0x228_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x228_32pt;
}

+ (UIImage*)imageOfIcon_0x154_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x154_32ptWithColor: color];

    UIImage* imageOfIcon_0x154_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x154_32pt;
}

+ (UIImage*)imageOfIcon_0x148_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x148_32ptWithColor: color];

    UIImage* imageOfIcon_0x148_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x148_32pt;
}

+ (UIImage*)imageOfIcon_0x229_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x229_32ptWithColor: color];

    UIImage* imageOfIcon_0x229_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x229_32pt;
}

+ (UIImage*)imageOfIcon_0x230_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x230_32ptWithColor: color];

    UIImage* imageOfIcon_0x230_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x230_32pt;
}

+ (UIImage*)imageOfIcon_0x149_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x149_32ptWithColor: color];

    UIImage* imageOfIcon_0x149_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x149_32pt;
}

+ (UIImage*)imageOfIcon_0x240_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x240_32ptWithColor: color];

    UIImage* imageOfIcon_0x240_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x240_32pt;
}

+ (UIImage*)imageOfIcon_0x244_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x244_32ptWithColor: color];

    UIImage* imageOfIcon_0x244_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x244_32pt;
}

+ (UIImage*)imageOfIcon_0x246_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x246_32ptWithColor: color];

    UIImage* imageOfIcon_0x246_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x246_32pt;
}

+ (UIImage*)imageOfIcon_0x245_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x245_32ptWithColor: color];

    UIImage* imageOfIcon_0x245_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x245_32pt;
}

+ (UIImage*)imageOfIcon_0x242_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x242_32ptWithColor: color];

    UIImage* imageOfIcon_0x242_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x242_32pt;
}

+ (UIImage*)imageOfIcon_0x247_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x247_32ptWithColor: color];

    UIImage* imageOfIcon_0x247_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x247_32pt;
}

+ (UIImage*)imageOfIcon_0x243_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x243_32ptWithColor: color];

    UIImage* imageOfIcon_0x243_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x243_32pt;
}

+ (UIImage*)imageOfIcon_0x139_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x139_32ptWithColor: color];

    UIImage* imageOfIcon_0x139_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x139_32pt;
}

+ (UIImage*)imageOfIcon_0x231_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x231_32ptWithColor: color];

    UIImage* imageOfIcon_0x231_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x231_32pt;
}

+ (UIImage*)imageOfIcon_0x232_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0.0f);
    [WireStyleKit drawIcon_0x232_32ptWithColor: color];

    UIImage* imageOfIcon_0x232_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x232_32pt;
}

+ (UIImage*)imageOfMissedcallWithAccent: (UIColor*)accent
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0f);
    [WireStyleKit drawMissedcallWithAccent: accent];

    UIImage* imageOfMissedcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfMissedcall;
}

+ (UIImage*)imageOfYoutubeWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 26), NO, 0.0f);
    [WireStyleKit drawYoutubeWithColor: color];

    UIImage* imageOfYoutube = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfYoutube;
}

+ (UIImage*)imageOfMissedcalllastWithAccent: (UIColor*)accent
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0.0f);
    [WireStyleKit drawMissedcalllastWithAccent: accent];

    UIImage* imageOfMissedcalllast = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfMissedcalllast;
}

+ (UIImage*)imageOfVimeoWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(84, 24), NO, 0.0f);
    [WireStyleKit drawVimeoWithColor: color];

    UIImage* imageOfVimeo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfVimeo;
}

+ (UIImage*)imageOfOngoingcall
{
    if (_imageOfOngoingcall)
        return _imageOfOngoingcall;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0.0f);
    [WireStyleKit drawOngoingcall];

    _imageOfOngoingcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfOngoingcall;
}

+ (UIImage*)imageOfJoinongoingcallWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0.0f);
    [WireStyleKit drawJoinongoingcallWithColor: color];

    UIImage* imageOfJoinongoingcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfJoinongoingcall;
}

+ (UIImage*)imageOfLogoWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(272, 224), NO, 0.0f);
    [WireStyleKit drawLogoWithColor: color];

    UIImage* imageOfLogo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfLogo;
}

+ (UIImage*)imageOfWireWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(174, 50), NO, 0.0f);
    [WireStyleKit drawWireWithColor: color];

    UIImage* imageOfWire = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfWire;
}

+ (UIImage*)imageOfShieldverified
{
    if (_imageOfShieldverified)
        return _imageOfShieldverified;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0f);
    [WireStyleKit drawShieldverified];

    _imageOfShieldverified = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfShieldverified;
}

+ (UIImage*)imageOfShieldnotverified
{
    if (_imageOfShieldnotverified)
        return _imageOfShieldnotverified;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0.0f);
    [WireStyleKit drawShieldnotverified];

    _imageOfShieldnotverified = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfShieldnotverified;
}

+ (UIImage*)imageOfTabWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 9), NO, 0.0f);
    [WireStyleKit drawTabWithColor: color];

    UIImage* imageOfTab = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfTab;
}

#pragma mark Customization Infrastructure

- (void)setOngoingcallTargets: (NSArray*)ongoingcallTargets
{
    _ongoingcallTargets = ongoingcallTargets;

    for (id target in self.ongoingcallTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfOngoingcall];
}

- (void)setShieldverifiedTargets: (NSArray*)shieldverifiedTargets
{
    _shieldverifiedTargets = shieldverifiedTargets;

    for (id target in self.shieldverifiedTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfShieldverified];
}

- (void)setShieldnotverifiedTargets: (NSArray*)shieldnotverifiedTargets
{
    _shieldnotverifiedTargets = shieldnotverifiedTargets;

    for (id target in self.shieldnotverifiedTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfShieldnotverified];
}


@end
