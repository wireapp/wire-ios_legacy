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
    [color setFill];
    [sketchPath fill];
}

+ (void)drawIcon_0x219_32ptWithColor: (UIColor*)color
{

    //// GIF Drawing
    UIBezierPath* gIFPath = [UIBezierPath bezierPath];
    [gIFPath moveToPoint: CGPointMake(48, 36)];
    [gIFPath addLineToPoint: CGPointMake(48, 56)];
    [gIFPath addLineToPoint: CGPointMake(40, 56)];
    [gIFPath addLineToPoint: CGPointMake(40, 8)];
    [gIFPath addLineToPoint: CGPointMake(46, 8)];
    [gIFPath addLineToPoint: CGPointMake(64, 8)];
    [gIFPath addLineToPoint: CGPointMake(64, 16)];
    [gIFPath addLineToPoint: CGPointMake(48, 16)];
    [gIFPath addLineToPoint: CGPointMake(48, 28)];
    [gIFPath addLineToPoint: CGPointMake(60, 28)];
    [gIFPath addLineToPoint: CGPointMake(60, 36)];
    [gIFPath addLineToPoint: CGPointMake(48, 36)];
    [gIFPath closePath];
    [gIFPath moveToPoint: CGPointMake(28, 8)];
    [gIFPath addLineToPoint: CGPointMake(36, 8)];
    [gIFPath addLineToPoint: CGPointMake(36, 56)];
    [gIFPath addLineToPoint: CGPointMake(28, 56)];
    [gIFPath addLineToPoint: CGPointMake(28, 8)];
    [gIFPath closePath];
    [gIFPath moveToPoint: CGPointMake(20, 28)];
    [gIFPath addLineToPoint: CGPointMake(24, 28)];
    [gIFPath addLineToPoint: CGPointMake(24, 44.79)];
    [gIFPath addCurveToPoint: CGPointMake(12, 56.8) controlPoint1: CGPointMake(24, 51.42) controlPoint2: CGPointMake(18.61, 56.8)];
    [gIFPath addCurveToPoint: CGPointMake(0, 44.79) controlPoint1: CGPointMake(5.37, 56.8) controlPoint2: CGPointMake(0, 51.4)];
    [gIFPath addLineToPoint: CGPointMake(0, 19.21)];
    [gIFPath addCurveToPoint: CGPointMake(12, 7.2) controlPoint1: CGPointMake(0, 12.58) controlPoint2: CGPointMake(5.39, 7.2)];
    [gIFPath addCurveToPoint: CGPointMake(24, 19.21) controlPoint1: CGPointMake(18.63, 7.2) controlPoint2: CGPointMake(24, 12.6)];
    [gIFPath addLineToPoint: CGPointMake(24, 20)];
    [gIFPath addLineToPoint: CGPointMake(16, 20)];
    [gIFPath addLineToPoint: CGPointMake(16, 19.21)];
    [gIFPath addCurveToPoint: CGPointMake(12, 15.2) controlPoint1: CGPointMake(16, 17.01) controlPoint2: CGPointMake(14.2, 15.2)];
    [gIFPath addCurveToPoint: CGPointMake(8, 19.21) controlPoint1: CGPointMake(9.8, 15.2) controlPoint2: CGPointMake(8, 17)];
    [gIFPath addLineToPoint: CGPointMake(8, 44.79)];
    [gIFPath addCurveToPoint: CGPointMake(12, 48.8) controlPoint1: CGPointMake(8, 46.99) controlPoint2: CGPointMake(9.8, 48.8)];
    [gIFPath addCurveToPoint: CGPointMake(16, 44.79) controlPoint1: CGPointMake(14.2, 48.8) controlPoint2: CGPointMake(16, 47)];
    [gIFPath addLineToPoint: CGPointMake(16, 36)];
    [gIFPath addLineToPoint: CGPointMake(12, 36)];
    [gIFPath addLineToPoint: CGPointMake(12, 28)];
    [gIFPath addLineToPoint: CGPointMake(20, 28)];
    [gIFPath closePath];
    gIFPath.usesEvenOddFillRule = YES;
    [color setFill];
    [gIFPath fill];
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
    cardPath.usesEvenOddFillRule = YES;
    [color setFill];
    [cardPath fill];
}

+ (void)drawIcon_0x163_32ptWithColor: (UIColor*)color
{

    //// Search Drawing
    UIBezierPath* searchPath = [UIBezierPath bezierPath];
    [searchPath moveToPoint: CGPointMake(55.9, 27.97)];
    [searchPath addCurveToPoint: CGPointMake(27.95, 0) controlPoint1: CGPointMake(55.9, 12.52) controlPoint2: CGPointMake(43.38, 0)];
    [searchPath addCurveToPoint: CGPointMake(0, 27.97) controlPoint1: CGPointMake(12.51, 0) controlPoint2: CGPointMake(0, 12.52)];
    [searchPath addCurveToPoint: CGPointMake(27.95, 55.95) controlPoint1: CGPointMake(0, 43.42) controlPoint2: CGPointMake(12.51, 55.95)];
    [searchPath addCurveToPoint: CGPointMake(44.69, 50.38) controlPoint1: CGPointMake(34.23, 55.95) controlPoint2: CGPointMake(40.02, 53.87)];
    [searchPath addLineToPoint: CGPointMake(58.35, 64)];
    [searchPath addLineToPoint: CGPointMake(64, 58.35)];
    [searchPath addLineToPoint: CGPointMake(50.33, 44.73)];
    [searchPath addCurveToPoint: CGPointMake(55.9, 27.97) controlPoint1: CGPointMake(53.83, 40.06) controlPoint2: CGPointMake(55.9, 34.26)];
    [searchPath closePath];
    [searchPath moveToPoint: CGPointMake(28, 48)];
    [searchPath addCurveToPoint: CGPointMake(48, 28) controlPoint1: CGPointMake(39.05, 48) controlPoint2: CGPointMake(48, 39.05)];
    [searchPath addCurveToPoint: CGPointMake(28, 8) controlPoint1: CGPointMake(48, 16.95) controlPoint2: CGPointMake(39.05, 8)];
    [searchPath addCurveToPoint: CGPointMake(8, 28) controlPoint1: CGPointMake(16.95, 8) controlPoint2: CGPointMake(8, 16.95)];
    [searchPath addCurveToPoint: CGPointMake(28, 48) controlPoint1: CGPointMake(8, 39.05) controlPoint2: CGPointMake(16.95, 48)];
    [searchPath closePath];
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
    callPath.usesEvenOddFillRule = YES;
    [color setFill];
    [callPath fill];
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

    //// Record Drawing
    UIBezierPath* recordPath = [UIBezierPath bezierPath];
    [recordPath moveToPoint: CGPointMake(32, 64)];
    [recordPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [recordPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [recordPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [recordPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [recordPath closePath];
    [recordPath moveToPoint: CGPointMake(32, 58)];
    [recordPath addCurveToPoint: CGPointMake(58, 32) controlPoint1: CGPointMake(46.36, 58) controlPoint2: CGPointMake(58, 46.36)];
    [recordPath addCurveToPoint: CGPointMake(32, 6) controlPoint1: CGPointMake(58, 17.64) controlPoint2: CGPointMake(46.36, 6)];
    [recordPath addCurveToPoint: CGPointMake(6, 32) controlPoint1: CGPointMake(17.64, 6) controlPoint2: CGPointMake(6, 17.64)];
    [recordPath addCurveToPoint: CGPointMake(32, 58) controlPoint1: CGPointMake(6, 46.36) controlPoint2: CGPointMake(17.64, 58)];
    [recordPath closePath];
    [recordPath moveToPoint: CGPointMake(32, 55)];
    [recordPath addCurveToPoint: CGPointMake(55, 32) controlPoint1: CGPointMake(44.7, 55) controlPoint2: CGPointMake(55, 44.7)];
    [recordPath addCurveToPoint: CGPointMake(32, 9) controlPoint1: CGPointMake(55, 19.3) controlPoint2: CGPointMake(44.7, 9)];
    [recordPath addCurveToPoint: CGPointMake(9, 32) controlPoint1: CGPointMake(19.3, 9) controlPoint2: CGPointMake(9, 19.3)];
    [recordPath addCurveToPoint: CGPointMake(32, 55) controlPoint1: CGPointMake(9, 44.7) controlPoint2: CGPointMake(19.3, 55)];
    [recordPath closePath];
    recordPath.usesEvenOddFillRule = YES;
    [color setFill];
    [recordPath fill];
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

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(64, 44.94)];
    [bezierPath addLineToPoint: CGPointMake(64, 64)];
    [bezierPath addLineToPoint: CGPointMake(0, 64)];
    [bezierPath addLineToPoint: CGPointMake(0, 32)];
    [bezierPath addCurveToPoint: CGPointMake(12, 20.13) controlPoint1: CGPointMake(0, 26.53) controlPoint2: CGPointMake(5.22, 21.05)];
    [bezierPath addLineToPoint: CGPointMake(12, 14)];
    [bezierPath addLineToPoint: CGPointMake(12, 4)];
    [bezierPath addLineToPoint: CGPointMake(28, 10)];
    [bezierPath addLineToPoint: CGPointMake(16, 14.5)];
    [bezierPath addLineToPoint: CGPointMake(16, 20.13)];
    [bezierPath addCurveToPoint: CGPointMake(28, 32) controlPoint1: CGPointMake(22.78, 21.05) controlPoint2: CGPointMake(28, 26.53)];
    [bezierPath addLineToPoint: CGPointMake(28, 32.18)];
    [bezierPath addCurveToPoint: CGPointMake(48, 48) controlPoint1: CGPointMake(28.25, 36.32) controlPoint2: CGPointMake(37.11, 48)];
    [bezierPath addCurveToPoint: CGPointMake(60, 44) controlPoint1: CGPointMake(52.5, 48) controlPoint2: CGPointMake(56.66, 46.51)];
    [bezierPath addLineToPoint: CGPointMake(60, 44)];
    [bezierPath addCurveToPoint: CGPointMake(64, 40) controlPoint1: CGPointMake(61.52, 42.86) controlPoint2: CGPointMake(62.86, 41.52)];
    [bezierPath addLineToPoint: CGPointMake(64, 44.94)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(60, 48.79)];
    [bezierPath addLineToPoint: CGPointMake(60, 60)];
    [bezierPath addLineToPoint: CGPointMake(52, 60)];
    [bezierPath addLineToPoint: CGPointMake(52, 51.67)];
    [bezierPath addCurveToPoint: CGPointMake(60, 48.79) controlPoint1: CGPointMake(54.87, 51.19) controlPoint2: CGPointMake(57.57, 50.19)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(48, 52)];
    [bezierPath addLineToPoint: CGPointMake(48, 60)];
    [bezierPath addLineToPoint: CGPointMake(40, 60)];
    [bezierPath addLineToPoint: CGPointMake(40, 50.63)];
    [bezierPath addCurveToPoint: CGPointMake(48, 52) controlPoint1: CGPointMake(42.5, 51.52) controlPoint2: CGPointMake(45.19, 52)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(36, 48.79)];
    [bezierPath addLineToPoint: CGPointMake(36, 60)];
    [bezierPath addLineToPoint: CGPointMake(28, 60)];
    [bezierPath addLineToPoint: CGPointMake(28, 41.27)];
    [bezierPath addCurveToPoint: CGPointMake(36, 48.79) controlPoint1: CGPointMake(30.05, 44.35) controlPoint2: CGPointMake(32.79, 46.93)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(24, 32)];
    [bezierPath addLineToPoint: CGPointMake(24, 60)];
    [bezierPath addLineToPoint: CGPointMake(16, 60)];
    [bezierPath addLineToPoint: CGPointMake(16, 24.2)];
    [bezierPath addCurveToPoint: CGPointMake(24, 32) controlPoint1: CGPointMake(19.92, 25) controlPoint2: CGPointMake(23.03, 28.08)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(12, 24.2)];
    [bezierPath addLineToPoint: CGPointMake(12, 60)];
    [bezierPath addLineToPoint: CGPointMake(4, 60)];
    [bezierPath addLineToPoint: CGPointMake(4, 32)];
    [bezierPath addCurveToPoint: CGPointMake(12, 24.2) controlPoint1: CGPointMake(4.97, 28.08) controlPoint2: CGPointMake(8.08, 25)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
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

+ (void)drawIcon_0x183_32ptWithColor: (UIColor*)color
{

    //// Like Drawing
    UIBezierPath* likePath = [UIBezierPath bezierPath];
    [likePath moveToPoint: CGPointMake(25.32, 13.28)];
    [likePath addCurveToPoint: CGPointMake(9.29, 13.29) controlPoint1: CGPointMake(20.91, 8.91) controlPoint2: CGPointMake(13.71, 8.91)];
    [likePath addCurveToPoint: CGPointMake(6.01, 23.2) controlPoint1: CGPointMake(6.97, 15.59) controlPoint2: CGPointMake(5.87, 18.66)];
    [likePath addCurveToPoint: CGPointMake(19.83, 44.78) controlPoint1: CGPointMake(6.01, 30.08) controlPoint2: CGPointMake(11.07, 37.56)];
    [likePath addCurveToPoint: CGPointMake(30.12, 52.05) controlPoint1: CGPointMake(23.08, 47.46) controlPoint2: CGPointMake(26.6, 49.91)];
    [likePath addCurveToPoint: CGPointMake(33.5, 54.01) controlPoint1: CGPointMake(31.35, 52.8) controlPoint2: CGPointMake(32.49, 53.45)];
    [likePath addCurveToPoint: CGPointMake(34.68, 54.63) controlPoint1: CGPointMake(34.09, 54.33) controlPoint2: CGPointMake(34.5, 54.54)];
    [likePath addLineToPoint: CGPointMake(29.32, 54.63)];
    [likePath addCurveToPoint: CGPointMake(30.5, 54.01) controlPoint1: CGPointMake(29.5, 54.54) controlPoint2: CGPointMake(29.91, 54.33)];
    [likePath addCurveToPoint: CGPointMake(33.88, 52.05) controlPoint1: CGPointMake(31.51, 53.45) controlPoint2: CGPointMake(32.65, 52.8)];
    [likePath addCurveToPoint: CGPointMake(44.18, 44.77) controlPoint1: CGPointMake(37.4, 49.91) controlPoint2: CGPointMake(40.92, 47.46)];
    [likePath addCurveToPoint: CGPointMake(58, 23.17) controlPoint1: CGPointMake(52.93, 37.55) controlPoint2: CGPointMake(58, 30.08)];
    [likePath addCurveToPoint: CGPointMake(54.71, 13.29) controlPoint1: CGPointMake(58.02, 18.45) controlPoint2: CGPointMake(56.96, 15.52)];
    [likePath addCurveToPoint: CGPointMake(38.68, 13.28) controlPoint1: CGPointMake(50.29, 8.91) controlPoint2: CGPointMake(43.09, 8.9)];
    [likePath addLineToPoint: CGPointMake(36.22, 15.71)];
    [likePath addLineToPoint: CGPointMake(32, 19.9)];
    [likePath addLineToPoint: CGPointMake(27.78, 15.71)];
    [likePath addLineToPoint: CGPointMake(25.32, 13.28)];
    [likePath closePath];
    [likePath moveToPoint: CGPointMake(32, 11.45)];
    [likePath addLineToPoint: CGPointMake(34.46, 9.02)];
    [likePath addCurveToPoint: CGPointMake(58.93, 9.03) controlPoint1: CGPointMake(41.21, 2.32) controlPoint2: CGPointMake(52.18, 2.34)];
    [likePath addCurveToPoint: CGPointMake(64, 23.2) controlPoint1: CGPointMake(62.34, 12.41) controlPoint2: CGPointMake(64.03, 16.85)];
    [likePath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(64, 44) controlPoint2: CGPointMake(32, 60)];
    [likePath addCurveToPoint: CGPointMake(0.01, 23.2) controlPoint1: CGPointMake(32, 60) controlPoint2: CGPointMake(-0, 44)];
    [likePath addCurveToPoint: CGPointMake(5.07, 9.03) controlPoint1: CGPointMake(-0.18, 17.24) controlPoint2: CGPointMake(1.51, 12.55)];
    [likePath addCurveToPoint: CGPointMake(29.54, 9.02) controlPoint1: CGPointMake(11.83, 2.32) controlPoint2: CGPointMake(22.8, 2.33)];
    [likePath addLineToPoint: CGPointMake(32, 11.45)];
    [likePath closePath];
    [color setFill];
    [likePath fill];
}

+ (void)drawIcon_0x184_32ptWithColor: (UIColor*)color
{

    //// Liked Drawing
    UIBezierPath* likedPath = [UIBezierPath bezierPath];
    [likedPath moveToPoint: CGPointMake(29.54, 10.02)];
    [likedPath addCurveToPoint: CGPointMake(5.07, 10.03) controlPoint1: CGPointMake(22.8, 3.33) controlPoint2: CGPointMake(11.83, 3.32)];
    [likedPath addCurveToPoint: CGPointMake(0.01, 24.2) controlPoint1: CGPointMake(1.51, 13.55) controlPoint2: CGPointMake(-0.18, 18.24)];
    [likedPath addCurveToPoint: CGPointMake(32, 61) controlPoint1: CGPointMake(-0, 45) controlPoint2: CGPointMake(32, 61)];
    [likedPath addCurveToPoint: CGPointMake(64, 24.2) controlPoint1: CGPointMake(32, 61) controlPoint2: CGPointMake(64, 45)];
    [likedPath addCurveToPoint: CGPointMake(58.93, 10.03) controlPoint1: CGPointMake(64.03, 17.85) controlPoint2: CGPointMake(62.34, 13.41)];
    [likedPath addCurveToPoint: CGPointMake(34.46, 10.02) controlPoint1: CGPointMake(52.18, 3.34) controlPoint2: CGPointMake(41.21, 3.32)];
    [likedPath addLineToPoint: CGPointMake(32, 12.45)];
    [likedPath addLineToPoint: CGPointMake(29.54, 10.02)];
    [likedPath closePath];
    likedPath.usesEvenOddFillRule = YES;
    [color setFill];
    [likedPath fill];
}

+ (void)drawIcon_0x188_32ptWithColor: (UIColor*)color
{

    //// Devices Drawing
    UIBezierPath* devicesPath = [UIBezierPath bezierPath];
    [devicesPath moveToPoint: CGPointMake(43.99, 0)];
    [devicesPath addLineToPoint: CGPointMake(4.01, 0)];
    [devicesPath addCurveToPoint: CGPointMake(0, 4) controlPoint1: CGPointMake(1.82, 0) controlPoint2: CGPointMake(0, 1.79)];
    [devicesPath addLineToPoint: CGPointMake(0, 60)];
    [devicesPath addCurveToPoint: CGPointMake(4.01, 64) controlPoint1: CGPointMake(0, 62.22) controlPoint2: CGPointMake(1.8, 64)];
    [devicesPath addLineToPoint: CGPointMake(60.01, 64)];
    [devicesPath addCurveToPoint: CGPointMake(64, 60.02) controlPoint1: CGPointMake(62.19, 64) controlPoint2: CGPointMake(64, 62.22)];
    [devicesPath addLineToPoint: CGPointMake(64, 23.98)];
    [devicesPath addCurveToPoint: CGPointMake(60.01, 20) controlPoint1: CGPointMake(64, 21.78) controlPoint2: CGPointMake(62.21, 20)];
    [devicesPath addLineToPoint: CGPointMake(48, 20)];
    [devicesPath addLineToPoint: CGPointMake(48, 4)];
    [devicesPath addCurveToPoint: CGPointMake(43.99, 0) controlPoint1: CGPointMake(48, 1.78) controlPoint2: CGPointMake(46.2, 0)];
    [devicesPath addLineToPoint: CGPointMake(43.99, 0)];
    [devicesPath closePath];
    [devicesPath moveToPoint: CGPointMake(40, 20)];
    [devicesPath addLineToPoint: CGPointMake(40, 10)];
    [devicesPath addCurveToPoint: CGPointMake(38, 8) controlPoint1: CGPointMake(40, 8.92) controlPoint2: CGPointMake(39.1, 8)];
    [devicesPath addLineToPoint: CGPointMake(10, 8)];
    [devicesPath addCurveToPoint: CGPointMake(8, 10) controlPoint1: CGPointMake(8.92, 8) controlPoint2: CGPointMake(8, 8.9)];
    [devicesPath addLineToPoint: CGPointMake(8, 54)];
    [devicesPath addCurveToPoint: CGPointMake(10, 56) controlPoint1: CGPointMake(8, 55.08) controlPoint2: CGPointMake(8.9, 56)];
    [devicesPath addLineToPoint: CGPointMake(32, 56)];
    [devicesPath addLineToPoint: CGPointMake(32, 23.98)];
    [devicesPath addCurveToPoint: CGPointMake(36.01, 20) controlPoint1: CGPointMake(32, 21.78) controlPoint2: CGPointMake(33.75, 20)];
    [devicesPath addLineToPoint: CGPointMake(40, 20)];
    [devicesPath closePath];
    [devicesPath moveToPoint: CGPointMake(24, 52)];
    [devicesPath addCurveToPoint: CGPointMake(28, 48) controlPoint1: CGPointMake(26.21, 52) controlPoint2: CGPointMake(28, 50.21)];
    [devicesPath addCurveToPoint: CGPointMake(24, 44) controlPoint1: CGPointMake(28, 45.79) controlPoint2: CGPointMake(26.21, 44)];
    [devicesPath addCurveToPoint: CGPointMake(20, 48) controlPoint1: CGPointMake(21.79, 44) controlPoint2: CGPointMake(20, 45.79)];
    [devicesPath addCurveToPoint: CGPointMake(24, 52) controlPoint1: CGPointMake(20, 50.21) controlPoint2: CGPointMake(21.79, 52)];
    [devicesPath closePath];
    [devicesPath moveToPoint: CGPointMake(48, 60)];
    [devicesPath addCurveToPoint: CGPointMake(52, 56) controlPoint1: CGPointMake(50.21, 60) controlPoint2: CGPointMake(52, 58.21)];
    [devicesPath addCurveToPoint: CGPointMake(48, 52) controlPoint1: CGPointMake(52, 53.79) controlPoint2: CGPointMake(50.21, 52)];
    [devicesPath addCurveToPoint: CGPointMake(44, 56) controlPoint1: CGPointMake(45.79, 52) controlPoint2: CGPointMake(44, 53.79)];
    [devicesPath addCurveToPoint: CGPointMake(48, 60) controlPoint1: CGPointMake(44, 58.21) controlPoint2: CGPointMake(45.79, 60)];
    [devicesPath closePath];
    devicesPath.usesEvenOddFillRule = YES;
    [color setFill];
    [devicesPath fill];
}

+ (void)drawIcon_0x135_32ptWithColor: (UIColor*)color
{

    //// Options Drawing
    UIBezierPath* optionsPath = [UIBezierPath bezierPath];
    [optionsPath moveToPoint: CGPointMake(38.93, 60)];
    [optionsPath addLineToPoint: CGPointMake(60, 60)];
    [optionsPath addCurveToPoint: CGPointMake(64, 56) controlPoint1: CGPointMake(62.22, 60) controlPoint2: CGPointMake(64, 58.21)];
    [optionsPath addCurveToPoint: CGPointMake(60, 52) controlPoint1: CGPointMake(64, 53.78) controlPoint2: CGPointMake(62.21, 52)];
    [optionsPath addLineToPoint: CGPointMake(38.93, 52)];
    [optionsPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(37.55, 49.61) controlPoint2: CGPointMake(34.96, 48)];
    [optionsPath addCurveToPoint: CGPointMake(25.07, 52) controlPoint1: CGPointMake(29.04, 48) controlPoint2: CGPointMake(26.45, 49.61)];
    [optionsPath addLineToPoint: CGPointMake(4, 52)];
    [optionsPath addCurveToPoint: CGPointMake(0, 56) controlPoint1: CGPointMake(1.78, 52) controlPoint2: CGPointMake(0, 53.79)];
    [optionsPath addCurveToPoint: CGPointMake(4, 60) controlPoint1: CGPointMake(0, 58.22) controlPoint2: CGPointMake(1.79, 60)];
    [optionsPath addLineToPoint: CGPointMake(25.07, 60)];
    [optionsPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(26.45, 62.39) controlPoint2: CGPointMake(29.04, 64)];
    [optionsPath addCurveToPoint: CGPointMake(38.93, 60) controlPoint1: CGPointMake(34.96, 64) controlPoint2: CGPointMake(37.55, 62.39)];
    [optionsPath addLineToPoint: CGPointMake(38.93, 60)];
    [optionsPath addLineToPoint: CGPointMake(38.93, 60)];
    [optionsPath closePath];
    [optionsPath moveToPoint: CGPointMake(26.93, 36)];
    [optionsPath addLineToPoint: CGPointMake(60, 36)];
    [optionsPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(62.22, 36) controlPoint2: CGPointMake(64, 34.21)];
    [optionsPath addCurveToPoint: CGPointMake(60, 28) controlPoint1: CGPointMake(64, 29.78) controlPoint2: CGPointMake(62.21, 28)];
    [optionsPath addLineToPoint: CGPointMake(26.93, 28)];
    [optionsPath addCurveToPoint: CGPointMake(20, 24) controlPoint1: CGPointMake(25.55, 25.61) controlPoint2: CGPointMake(22.96, 24)];
    [optionsPath addCurveToPoint: CGPointMake(13.07, 28) controlPoint1: CGPointMake(17.04, 24) controlPoint2: CGPointMake(14.45, 25.61)];
    [optionsPath addLineToPoint: CGPointMake(4, 28)];
    [optionsPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(1.78, 28) controlPoint2: CGPointMake(0, 29.79)];
    [optionsPath addCurveToPoint: CGPointMake(4, 36) controlPoint1: CGPointMake(0, 34.22) controlPoint2: CGPointMake(1.79, 36)];
    [optionsPath addLineToPoint: CGPointMake(13.07, 36)];
    [optionsPath addCurveToPoint: CGPointMake(20, 40) controlPoint1: CGPointMake(14.45, 38.39) controlPoint2: CGPointMake(17.04, 40)];
    [optionsPath addCurveToPoint: CGPointMake(26.93, 36) controlPoint1: CGPointMake(22.96, 40) controlPoint2: CGPointMake(25.55, 38.39)];
    [optionsPath addLineToPoint: CGPointMake(26.93, 36)];
    [optionsPath addLineToPoint: CGPointMake(26.93, 36)];
    [optionsPath closePath];
    [optionsPath moveToPoint: CGPointMake(50.93, 12)];
    [optionsPath addLineToPoint: CGPointMake(60, 12)];
    [optionsPath addCurveToPoint: CGPointMake(64, 8) controlPoint1: CGPointMake(62.22, 12) controlPoint2: CGPointMake(64, 10.21)];
    [optionsPath addCurveToPoint: CGPointMake(60, 4) controlPoint1: CGPointMake(64, 5.78) controlPoint2: CGPointMake(62.21, 4)];
    [optionsPath addLineToPoint: CGPointMake(50.93, 4)];
    [optionsPath addCurveToPoint: CGPointMake(44, 0) controlPoint1: CGPointMake(49.55, 1.61) controlPoint2: CGPointMake(46.96, 0)];
    [optionsPath addCurveToPoint: CGPointMake(37.07, 4) controlPoint1: CGPointMake(41.04, 0) controlPoint2: CGPointMake(38.45, 1.61)];
    [optionsPath addLineToPoint: CGPointMake(4, 4)];
    [optionsPath addCurveToPoint: CGPointMake(0, 8) controlPoint1: CGPointMake(1.78, 4) controlPoint2: CGPointMake(0, 5.79)];
    [optionsPath addCurveToPoint: CGPointMake(4, 12) controlPoint1: CGPointMake(0, 10.22) controlPoint2: CGPointMake(1.79, 12)];
    [optionsPath addLineToPoint: CGPointMake(37.07, 12)];
    [optionsPath addCurveToPoint: CGPointMake(44, 16) controlPoint1: CGPointMake(38.45, 14.39) controlPoint2: CGPointMake(41.04, 16)];
    [optionsPath addCurveToPoint: CGPointMake(50.93, 12) controlPoint1: CGPointMake(46.96, 16) controlPoint2: CGPointMake(49.55, 14.39)];
    [optionsPath addLineToPoint: CGPointMake(50.93, 12)];
    [optionsPath addLineToPoint: CGPointMake(50.93, 12)];
    [optionsPath closePath];
    optionsPath.usesEvenOddFillRule = YES;
    [color setFill];
    [optionsPath fill];
}

+ (void)drawIcon_0x134_32ptWithColor: (UIColor*)color
{

    //// Advanced Drawing
    UIBezierPath* advancedPath = [UIBezierPath bezierPath];
    [advancedPath moveToPoint: CGPointMake(26.1, 29.58)];
    [advancedPath addLineToPoint: CGPointMake(23.37, 32.3)];
    [advancedPath addLineToPoint: CGPointMake(21.99, 30.92)];
    [advancedPath addLineToPoint: CGPointMake(19.22, 33.69)];
    [advancedPath addLineToPoint: CGPointMake(21.99, 36.46)];
    [advancedPath addLineToPoint: CGPointMake(4.15, 54.3)];
    [advancedPath addLineToPoint: CGPointMake(0, 61.23)];
    [advancedPath addLineToPoint: CGPointMake(2.77, 64)];
    [advancedPath addLineToPoint: CGPointMake(9.69, 59.84)];
    [advancedPath addLineToPoint: CGPointMake(27.52, 42)];
    [advancedPath addLineToPoint: CGPointMake(30.29, 44.76)];
    [advancedPath addLineToPoint: CGPointMake(33.06, 42)];
    [advancedPath addLineToPoint: CGPointMake(31.68, 40.61)];
    [advancedPath addLineToPoint: CGPointMake(34.12, 38.16)];
    [advancedPath addLineToPoint: CGPointMake(57.17, 62.82)];
    [advancedPath addCurveToPoint: CGPointMake(62.83, 62.83) controlPoint1: CGPointMake(58.74, 64.4) controlPoint2: CGPointMake(61.26, 64.39)];
    [advancedPath addCurveToPoint: CGPointMake(63.96, 59.41) controlPoint1: CGPointMake(63.76, 61.89) controlPoint2: CGPointMake(64.14, 60.61)];
    [advancedPath addCurveToPoint: CGPointMake(62.82, 57.17) controlPoint1: CGPointMake(63.83, 58.59) controlPoint2: CGPointMake(63.45, 57.8)];
    [advancedPath addLineToPoint: CGPointMake(41.11, 33.94)];
    [advancedPath addLineToPoint: CGPointMake(61.64, 13.39)];
    [advancedPath addCurveToPoint: CGPointMake(61.66, 2.3) controlPoint1: CGPointMake(64.74, 10.29) controlPoint2: CGPointMake(64.72, 5.36)];
    [advancedPath addCurveToPoint: CGPointMake(50.57, 2.31) controlPoint1: CGPointMake(58.58, -0.78) controlPoint2: CGPointMake(53.64, -0.75)];
    [advancedPath addLineToPoint: CGPointMake(30.41, 22.49)];
    [advancedPath addLineToPoint: CGPointMake(22.61, 14.14)];
    [advancedPath addLineToPoint: CGPointMake(33.92, 2.83)];
    [advancedPath addLineToPoint: CGPointMake(19.79, 0)];
    [advancedPath addLineToPoint: CGPointMake(14.13, 5.66)];
    [advancedPath addCurveToPoint: CGPointMake(8.48, 5.66) controlPoint1: CGPointMake(12.56, 4.09) controlPoint2: CGPointMake(10.04, 4.1)];
    [advancedPath addCurveToPoint: CGPointMake(8.48, 11.31) controlPoint1: CGPointMake(6.91, 7.23) controlPoint2: CGPointMake(6.92, 9.75)];
    [advancedPath addLineToPoint: CGPointMake(0, 19.8)];
    [advancedPath addLineToPoint: CGPointMake(8.48, 28.29)];
    [advancedPath addLineToPoint: CGPointMake(16.96, 19.8)];
    [advancedPath addLineToPoint: CGPointMake(24.76, 28.14)];
    [advancedPath addLineToPoint: CGPointMake(24.83, 28.21)];
    [advancedPath addLineToPoint: CGPointMake(26.1, 29.58)];
    [advancedPath addLineToPoint: CGPointMake(26.1, 29.58)];
    [advancedPath closePath];
    advancedPath.usesEvenOddFillRule = YES;
    [color setFill];
    [advancedPath fill];
}

+ (void)drawIcon_0x127_32ptWithColor: (UIColor*)color
{

    //// Support Drawing
    UIBezierPath* supportPath = [UIBezierPath bezierPath];
    [supportPath moveToPoint: CGPointMake(45.32, 56.63)];
    [supportPath addCurveToPoint: CGPointMake(56.63, 45.32) controlPoint1: CGPointMake(50.1, 54.04) controlPoint2: CGPointMake(54.04, 50.1)];
    [supportPath addLineToPoint: CGPointMake(47.46, 36.14)];
    [supportPath addCurveToPoint: CGPointMake(48, 32) controlPoint1: CGPointMake(47.81, 34.82) controlPoint2: CGPointMake(48, 33.43)];
    [supportPath addCurveToPoint: CGPointMake(47.46, 27.86) controlPoint1: CGPointMake(48, 30.57) controlPoint2: CGPointMake(47.81, 29.18)];
    [supportPath addLineToPoint: CGPointMake(56.63, 18.68)];
    [supportPath addCurveToPoint: CGPointMake(45.32, 7.37) controlPoint1: CGPointMake(54.04, 13.9) controlPoint2: CGPointMake(50.1, 9.96)];
    [supportPath addLineToPoint: CGPointMake(36.14, 16.54)];
    [supportPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(34.82, 16.19) controlPoint2: CGPointMake(33.43, 16)];
    [supportPath addCurveToPoint: CGPointMake(27.86, 16.54) controlPoint1: CGPointMake(30.57, 16) controlPoint2: CGPointMake(29.18, 16.19)];
    [supportPath addLineToPoint: CGPointMake(27.86, 16.54)];
    [supportPath addLineToPoint: CGPointMake(18.68, 7.37)];
    [supportPath addCurveToPoint: CGPointMake(7.37, 18.68) controlPoint1: CGPointMake(13.9, 9.96) controlPoint2: CGPointMake(9.96, 13.9)];
    [supportPath addLineToPoint: CGPointMake(16.54, 27.86)];
    [supportPath addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(16.19, 29.18) controlPoint2: CGPointMake(16, 30.57)];
    [supportPath addCurveToPoint: CGPointMake(16.54, 36.14) controlPoint1: CGPointMake(16, 33.43) controlPoint2: CGPointMake(16.19, 34.82)];
    [supportPath addLineToPoint: CGPointMake(16.54, 36.14)];
    [supportPath addLineToPoint: CGPointMake(7.37, 45.32)];
    [supportPath addCurveToPoint: CGPointMake(18.68, 56.63) controlPoint1: CGPointMake(9.96, 50.1) controlPoint2: CGPointMake(13.9, 54.04)];
    [supportPath addLineToPoint: CGPointMake(27.86, 47.46)];
    [supportPath addLineToPoint: CGPointMake(27.86, 47.46)];
    [supportPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(29.18, 47.81) controlPoint2: CGPointMake(30.57, 48)];
    [supportPath addCurveToPoint: CGPointMake(36.14, 47.46) controlPoint1: CGPointMake(33.43, 48) controlPoint2: CGPointMake(34.82, 47.81)];
    [supportPath addLineToPoint: CGPointMake(45.32, 56.63)];
    [supportPath addLineToPoint: CGPointMake(45.32, 56.63)];
    [supportPath closePath];
    [supportPath moveToPoint: CGPointMake(32, 64)];
    [supportPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [supportPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [supportPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [supportPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [supportPath addLineToPoint: CGPointMake(32, 64)];
    [supportPath closePath];
    [supportPath moveToPoint: CGPointMake(32, 48)];
    [supportPath addLineToPoint: CGPointMake(32, 48)];
    [supportPath addCurveToPoint: CGPointMake(48, 32) controlPoint1: CGPointMake(40.84, 48) controlPoint2: CGPointMake(48, 40.84)];
    [supportPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(48, 23.16) controlPoint2: CGPointMake(40.84, 16)];
    [supportPath addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(23.16, 16) controlPoint2: CGPointMake(16, 23.16)];
    [supportPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(16, 40.84) controlPoint2: CGPointMake(23.16, 48)];
    [supportPath addLineToPoint: CGPointMake(32, 48)];
    [supportPath addLineToPoint: CGPointMake(32, 48)];
    [supportPath addLineToPoint: CGPointMake(32, 48)];
    [supportPath addLineToPoint: CGPointMake(32, 48)];
    [supportPath closePath];
    [supportPath moveToPoint: CGPointMake(32, 52)];
    [supportPath addLineToPoint: CGPointMake(32, 52)];
    [supportPath addCurveToPoint: CGPointMake(12, 32) controlPoint1: CGPointMake(20.95, 52) controlPoint2: CGPointMake(12, 43.05)];
    [supportPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(12, 20.95) controlPoint2: CGPointMake(20.95, 12)];
    [supportPath addCurveToPoint: CGPointMake(52, 32) controlPoint1: CGPointMake(43.05, 12) controlPoint2: CGPointMake(52, 20.95)];
    [supportPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(52, 43.05) controlPoint2: CGPointMake(43.05, 52)];
    [supportPath addLineToPoint: CGPointMake(32, 52)];
    [supportPath addLineToPoint: CGPointMake(32, 52)];
    [supportPath addLineToPoint: CGPointMake(32, 52)];
    [supportPath addLineToPoint: CGPointMake(32, 52)];
    [supportPath closePath];
    [color setFill];
    [supportPath fill];
}

+ (void)drawIcon_0x202_32ptWithColor: (UIColor*)color
{

    //// w-symbol Drawing
    UIBezierPath* wsymbolPath = [UIBezierPath bezierPath];
    [wsymbolPath moveToPoint: CGPointMake(43.56, 59.4)];
    [wsymbolPath addCurveToPoint: CGPointMake(64, 38.88) controlPoint1: CGPointMake(54.82, 59.4) controlPoint2: CGPointMake(64, 50.2)];
    [wsymbolPath addLineToPoint: CGPointMake(64, 9.76)];
    [wsymbolPath addLineToPoint: CGPointMake(64, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(62, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(58.47, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(56.47, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(56.47, 9.76)];
    [wsymbolPath addLineToPoint: CGPointMake(56.47, 38.88)];
    [wsymbolPath addCurveToPoint: CGPointMake(43.56, 51.87) controlPoint1: CGPointMake(56.47, 46.08) controlPoint2: CGPointMake(50.73, 51.87)];
    [wsymbolPath addCurveToPoint: CGPointMake(35.84, 49.36) controlPoint1: CGPointMake(40.69, 51.87) controlPoint2: CGPointMake(38.01, 50.99)];
    [wsymbolPath addLineToPoint: CGPointMake(36.18, 52.24)];
    [wsymbolPath addCurveToPoint: CGPointMake(41.06, 38.88) controlPoint1: CGPointMake(39.3, 48.52) controlPoint2: CGPointMake(41.06, 43.81)];
    [wsymbolPath addLineToPoint: CGPointMake(41.06, 15.06)];
    [wsymbolPath addCurveToPoint: CGPointMake(32, 6) controlPoint1: CGPointMake(41.06, 10.07) controlPoint2: CGPointMake(36.98, 6)];
    [wsymbolPath addCurveToPoint: CGPointMake(22.94, 15.06) controlPoint1: CGPointMake(27.01, 6) controlPoint2: CGPointMake(22.94, 10.07)];
    [wsymbolPath addLineToPoint: CGPointMake(22.94, 38.88)];
    [wsymbolPath addCurveToPoint: CGPointMake(28.01, 52.27) controlPoint1: CGPointMake(22.94, 43.86) controlPoint2: CGPointMake(24.75, 48.5)];
    [wsymbolPath addLineToPoint: CGPointMake(28.36, 49.33)];
    [wsymbolPath addCurveToPoint: CGPointMake(20.53, 51.87) controlPoint1: CGPointMake(26.11, 50.94) controlPoint2: CGPointMake(23.33, 51.87)];
    [wsymbolPath addCurveToPoint: CGPointMake(7.53, 38.88) controlPoint1: CGPointMake(13.4, 51.87) controlPoint2: CGPointMake(7.53, 46.03)];
    [wsymbolPath addLineToPoint: CGPointMake(7.53, 9.76)];
    [wsymbolPath addLineToPoint: CGPointMake(7.53, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(5.53, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(2, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(0, 7.76)];
    [wsymbolPath addLineToPoint: CGPointMake(0, 9.76)];
    [wsymbolPath addLineToPoint: CGPointMake(0, 38.88)];
    [wsymbolPath addCurveToPoint: CGPointMake(20.62, 59.4) controlPoint1: CGPointMake(0, 50.2) controlPoint2: CGPointMake(9.26, 59.4)];
    [wsymbolPath addCurveToPoint: CGPointMake(33.4, 55.01) controlPoint1: CGPointMake(25.28, 59.4) controlPoint2: CGPointMake(29.78, 57.82)];
    [wsymbolPath addLineToPoint: CGPointMake(30.92, 54.99)];
    [wsymbolPath addCurveToPoint: CGPointMake(43.56, 59.4) controlPoint1: CGPointMake(34.46, 57.82) controlPoint2: CGPointMake(38.89, 59.4)];
    [wsymbolPath addLineToPoint: CGPointMake(43.56, 59.4)];
    [wsymbolPath closePath];
    [wsymbolPath moveToPoint: CGPointMake(33.53, 15.06)];
    [wsymbolPath addLineToPoint: CGPointMake(33.53, 38.88)];
    [wsymbolPath addCurveToPoint: CGPointMake(30.46, 47.21) controlPoint1: CGPointMake(33.53, 41.92) controlPoint2: CGPointMake(32.43, 44.84)];
    [wsymbolPath addLineToPoint: CGPointMake(33.51, 47.19)];
    [wsymbolPath addCurveToPoint: CGPointMake(30.47, 38.88) controlPoint1: CGPointMake(31.56, 44.92) controlPoint2: CGPointMake(30.47, 42.01)];
    [wsymbolPath addLineToPoint: CGPointMake(30.47, 15.06)];
    [wsymbolPath addCurveToPoint: CGPointMake(32, 13.53) controlPoint1: CGPointMake(30.47, 14.22) controlPoint2: CGPointMake(31.16, 13.53)];
    [wsymbolPath addCurveToPoint: CGPointMake(33.53, 15.06) controlPoint1: CGPointMake(32.83, 13.53) controlPoint2: CGPointMake(33.53, 14.22)];
    [wsymbolPath addLineToPoint: CGPointMake(33.53, 15.06)];
    [wsymbolPath closePath];
    [color setFill];
    [wsymbolPath fill];
}

+ (void)drawIcon_0x235_32ptWithColor: (UIColor*)color
{

    //// Send Drawing
    UIBezierPath* sendPath = [UIBezierPath bezierPath];
    [sendPath moveToPoint: CGPointMake(8, 54.06)];
    [sendPath addCurveToPoint: CGPointMake(16.2, 59.08) controlPoint1: CGPointMake(8, 59.19) controlPoint2: CGPointMake(11.67, 61.4)];
    [sendPath addLineToPoint: CGPointMake(60.62, 36.21)];
    [sendPath addCurveToPoint: CGPointMake(60.62, 27.77) controlPoint1: CGPointMake(65.11, 33.9) controlPoint2: CGPointMake(65.15, 30.11)];
    [sendPath addLineToPoint: CGPointMake(16.2, 4.91)];
    [sendPath addCurveToPoint: CGPointMake(8, 9.93) controlPoint1: CGPointMake(11.71, 2.6) controlPoint2: CGPointMake(8, 4.83)];
    [sendPath addLineToPoint: CGPointMake(8, 32)];
    [sendPath addLineToPoint: CGPointMake(50, 32)];
    [sendPath addLineToPoint: CGPointMake(8, 39)];
    [sendPath addLineToPoint: CGPointMake(8, 54.06)];
    [sendPath closePath];
    sendPath.usesEvenOddFillRule = YES;
    [color setFill];
    [sendPath fill];
}

+ (void)drawIcon_0x237_32ptWithColor: (UIColor*)color
{

    //// Emoji Drawing
    UIBezierPath* emojiPath = [UIBezierPath bezierPath];
    [emojiPath moveToPoint: CGPointMake(32, 64)];
    [emojiPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [emojiPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [emojiPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [emojiPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [emojiPath closePath];
    [emojiPath moveToPoint: CGPointMake(32, 58)];
    [emojiPath addCurveToPoint: CGPointMake(58, 32) controlPoint1: CGPointMake(46.36, 58) controlPoint2: CGPointMake(58, 46.36)];
    [emojiPath addCurveToPoint: CGPointMake(32, 6) controlPoint1: CGPointMake(58, 17.64) controlPoint2: CGPointMake(46.36, 6)];
    [emojiPath addCurveToPoint: CGPointMake(6, 32) controlPoint1: CGPointMake(17.64, 6) controlPoint2: CGPointMake(6, 17.64)];
    [emojiPath addCurveToPoint: CGPointMake(32, 58) controlPoint1: CGPointMake(6, 46.36) controlPoint2: CGPointMake(17.64, 58)];
    [emojiPath closePath];
    [emojiPath moveToPoint: CGPointMake(51.6, 36)];
    [emojiPath addLineToPoint: CGPointMake(12.4, 36)];
    [emojiPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(14.25, 45.13) controlPoint2: CGPointMake(22.32, 52)];
    [emojiPath addCurveToPoint: CGPointMake(51.6, 36) controlPoint1: CGPointMake(41.68, 52) controlPoint2: CGPointMake(49.75, 45.13)];
    [emojiPath closePath];
    [emojiPath moveToPoint: CGPointMake(45.9, 40)];
    [emojiPath addCurveToPoint: CGPointMake(18.17, 40.06) controlPoint1: CGPointMake(35.15, 40) controlPoint2: CGPointMake(18.17, 40.06)];
    [emojiPath addCurveToPoint: CGPointMake(21.42, 44) controlPoint1: CGPointMake(19.04, 41.54) controlPoint2: CGPointMake(20.14, 42.87)];
    [emojiPath addLineToPoint: CGPointMake(42.58, 44)];
    [emojiPath addCurveToPoint: CGPointMake(45.9, 40) controlPoint1: CGPointMake(44.94, 41.93) controlPoint2: CGPointMake(45.9, 40)];
    [emojiPath closePath];
    [emojiPath moveToPoint: CGPointMake(40, 28)];
    [emojiPath addCurveToPoint: CGPointMake(44, 24) controlPoint1: CGPointMake(42.21, 28) controlPoint2: CGPointMake(44, 26.21)];
    [emojiPath addCurveToPoint: CGPointMake(40, 20) controlPoint1: CGPointMake(44, 21.79) controlPoint2: CGPointMake(42.21, 20)];
    [emojiPath addCurveToPoint: CGPointMake(36, 24) controlPoint1: CGPointMake(37.79, 20) controlPoint2: CGPointMake(36, 21.79)];
    [emojiPath addCurveToPoint: CGPointMake(40, 28) controlPoint1: CGPointMake(36, 26.21) controlPoint2: CGPointMake(37.79, 28)];
    [emojiPath closePath];
    [emojiPath moveToPoint: CGPointMake(24, 28)];
    [emojiPath addCurveToPoint: CGPointMake(28, 24) controlPoint1: CGPointMake(26.21, 28) controlPoint2: CGPointMake(28, 26.21)];
    [emojiPath addCurveToPoint: CGPointMake(24, 20) controlPoint1: CGPointMake(28, 21.79) controlPoint2: CGPointMake(26.21, 20)];
    [emojiPath addCurveToPoint: CGPointMake(20, 24) controlPoint1: CGPointMake(21.79, 20) controlPoint2: CGPointMake(20, 21.79)];
    [emojiPath addCurveToPoint: CGPointMake(24, 28) controlPoint1: CGPointMake(20, 26.21) controlPoint2: CGPointMake(21.79, 28)];
    [emojiPath closePath];
    emojiPath.usesEvenOddFillRule = YES;
    [color setFill];
    [emojiPath fill];
}

+ (void)drawIcon_0x236_32ptWithColor: (UIColor*)color
{

    //// Keyboard Drawing
    UIBezierPath* keyboardPath = [UIBezierPath bezierPath];
    [keyboardPath moveToPoint: CGPointMake(32, 16)];
    [keyboardPath addLineToPoint: CGPointMake(48, 16)];
    [keyboardPath addLineToPoint: CGPointMake(48, 8)];
    [keyboardPath addLineToPoint: CGPointMake(8, 8)];
    [keyboardPath addLineToPoint: CGPointMake(8, 16)];
    [keyboardPath addLineToPoint: CGPointMake(24, 16)];
    [keyboardPath addLineToPoint: CGPointMake(24, 56)];
    [keyboardPath addLineToPoint: CGPointMake(32, 56)];
    [keyboardPath addLineToPoint: CGPointMake(32, 16)];
    [keyboardPath closePath];
    [keyboardPath moveToPoint: CGPointMake(60, 0)];
    [keyboardPath addLineToPoint: CGPointMake(64, 0)];
    [keyboardPath addLineToPoint: CGPointMake(64, 64)];
    [keyboardPath addLineToPoint: CGPointMake(60, 64)];
    [keyboardPath addLineToPoint: CGPointMake(60, 0)];
    [keyboardPath closePath];
    keyboardPath.usesEvenOddFillRule = YES;
    [color setFill];
    [keyboardPath fill];
}

+ (void)drawIcon_0x238_32ptWithColor: (UIColor*)color
{

    //// Backspace Drawing
    UIBezierPath* backspacePath = [UIBezierPath bezierPath];
    [backspacePath moveToPoint: CGPointMake(1.16, 35.85)];
    [backspacePath addCurveToPoint: CGPointMake(1.16, 30.15) controlPoint1: CGPointMake(-0.39, 34.27) controlPoint2: CGPointMake(-0.38, 31.71)];
    [backspacePath addLineToPoint: CGPointMake(20.23, 10.88)];
    [backspacePath addCurveToPoint: CGPointMake(24.78, 9) controlPoint1: CGPointMake(21.26, 9.84) controlPoint2: CGPointMake(23.3, 9)];
    [backspacePath addLineToPoint: CGPointMake(54.7, 9)];
    [backspacePath addCurveToPoint: CGPointMake(64, 18.31) controlPoint1: CGPointMake(59.84, 9) controlPoint2: CGPointMake(64, 13.18)];
    [backspacePath addLineToPoint: CGPointMake(64, 47.69)];
    [backspacePath addCurveToPoint: CGPointMake(54.7, 57) controlPoint1: CGPointMake(64, 52.83) controlPoint2: CGPointMake(59.83, 57)];
    [backspacePath addLineToPoint: CGPointMake(24.78, 57)];
    [backspacePath addCurveToPoint: CGPointMake(20.23, 55.12) controlPoint1: CGPointMake(23.29, 57) controlPoint2: CGPointMake(21.25, 56.15)];
    [backspacePath addLineToPoint: CGPointMake(1.16, 35.85)];
    [backspacePath closePath];
    [backspacePath moveToPoint: CGPointMake(42.05, 32.94)];
    [backspacePath addLineToPoint: CGPointMake(50.06, 24.91)];
    [backspacePath addCurveToPoint: CGPointMake(50.05, 21.96) controlPoint1: CGPointMake(50.85, 24.12) controlPoint2: CGPointMake(50.87, 22.78)];
    [backspacePath addCurveToPoint: CGPointMake(47.1, 21.95) controlPoint1: CGPointMake(49.23, 21.13) controlPoint2: CGPointMake(47.91, 21.13)];
    [backspacePath addLineToPoint: CGPointMake(39.08, 29.97)];
    [backspacePath addLineToPoint: CGPointMake(31.07, 21.95)];
    [backspacePath addCurveToPoint: CGPointMake(28.12, 21.96) controlPoint1: CGPointMake(30.28, 21.15) controlPoint2: CGPointMake(28.94, 21.14)];
    [backspacePath addCurveToPoint: CGPointMake(28.11, 24.91) controlPoint1: CGPointMake(27.29, 22.78) controlPoint2: CGPointMake(27.3, 24.1)];
    [backspacePath addLineToPoint: CGPointMake(36.12, 32.94)];
    [backspacePath addLineToPoint: CGPointMake(28.11, 40.96)];
    [backspacePath addCurveToPoint: CGPointMake(28.12, 43.92) controlPoint1: CGPointMake(27.32, 41.75) controlPoint2: CGPointMake(27.3, 43.1)];
    [backspacePath addCurveToPoint: CGPointMake(31.07, 43.93) controlPoint1: CGPointMake(28.94, 44.74) controlPoint2: CGPointMake(30.26, 44.74)];
    [backspacePath addLineToPoint: CGPointMake(39.08, 35.9)];
    [backspacePath addLineToPoint: CGPointMake(47.1, 43.93)];
    [backspacePath addCurveToPoint: CGPointMake(50.05, 43.92) controlPoint1: CGPointMake(47.89, 44.72) controlPoint2: CGPointMake(49.23, 44.74)];
    [backspacePath addCurveToPoint: CGPointMake(50.06, 40.96) controlPoint1: CGPointMake(50.87, 43.09) controlPoint2: CGPointMake(50.87, 41.77)];
    [backspacePath addLineToPoint: CGPointMake(42.05, 32.94)];
    [backspacePath closePath];
    [backspacePath moveToPoint: CGPointMake(5.81, 34.9)];
    [backspacePath addCurveToPoint: CGPointMake(5.81, 31.1) controlPoint1: CGPointMake(4.77, 33.85) controlPoint2: CGPointMake(4.77, 32.15)];
    [backspacePath addLineToPoint: CGPointMake(22.55, 14.19)];
    [backspacePath addCurveToPoint: CGPointMake(24.82, 13.24) controlPoint1: CGPointMake(23.07, 13.66) controlPoint2: CGPointMake(24.06, 13.24)];
    [backspacePath addLineToPoint: CGPointMake(54.49, 13.24)];
    [backspacePath addCurveToPoint: CGPointMake(59.81, 18.57) controlPoint1: CGPointMake(57.43, 13.24) controlPoint2: CGPointMake(59.81, 15.65)];
    [backspacePath addLineToPoint: CGPointMake(59.81, 47.43)];
    [backspacePath addCurveToPoint: CGPointMake(54.49, 52.76) controlPoint1: CGPointMake(59.81, 50.38) controlPoint2: CGPointMake(57.43, 52.76)];
    [backspacePath addLineToPoint: CGPointMake(24.82, 52.76)];
    [backspacePath addCurveToPoint: CGPointMake(22.55, 51.81) controlPoint1: CGPointMake(24.09, 52.76) controlPoint2: CGPointMake(23.08, 52.35)];
    [backspacePath addLineToPoint: CGPointMake(5.81, 34.9)];
    [backspacePath closePath];
    backspacePath.usesEvenOddFillRule = YES;
    [color setFill];
    [backspacePath fill];
}

+ (void)drawIcon_0x250_32ptWithColor: (UIColor*)color
{

    //// Flower Drawing
    UIBezierPath* flowerPath = [UIBezierPath bezierPath];
    [flowerPath moveToPoint: CGPointMake(39.73, 13.34)];
    [flowerPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(38.82, 5.66) controlPoint2: CGPointMake(35.7, 0)];
    [flowerPath addCurveToPoint: CGPointMake(24.27, 13.34) controlPoint1: CGPointMake(28.3, 0) controlPoint2: CGPointMake(25.18, 5.66)];
    [flowerPath addCurveToPoint: CGPointMake(9.37, 9.37) controlPoint1: CGPointMake(18.19, 8.55) controlPoint2: CGPointMake(11.99, 6.75)];
    [flowerPath addCurveToPoint: CGPointMake(13.34, 24.27) controlPoint1: CGPointMake(6.75, 11.99) controlPoint2: CGPointMake(8.55, 18.19)];
    [flowerPath addLineToPoint: CGPointMake(13.34, 24.27)];
    [flowerPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(5.66, 25.18) controlPoint2: CGPointMake(0, 28.3)];
    [flowerPath addCurveToPoint: CGPointMake(13.34, 39.73) controlPoint1: CGPointMake(0, 35.7) controlPoint2: CGPointMake(5.66, 38.82)];
    [flowerPath addCurveToPoint: CGPointMake(9.37, 54.63) controlPoint1: CGPointMake(8.55, 45.81) controlPoint2: CGPointMake(6.75, 52.01)];
    [flowerPath addCurveToPoint: CGPointMake(24.27, 50.66) controlPoint1: CGPointMake(11.99, 57.25) controlPoint2: CGPointMake(18.19, 55.45)];
    [flowerPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(25.18, 58.34) controlPoint2: CGPointMake(28.3, 64)];
    [flowerPath addCurveToPoint: CGPointMake(39.73, 50.66) controlPoint1: CGPointMake(35.7, 64) controlPoint2: CGPointMake(38.82, 58.34)];
    [flowerPath addCurveToPoint: CGPointMake(54.63, 54.63) controlPoint1: CGPointMake(45.81, 55.45) controlPoint2: CGPointMake(52.01, 57.25)];
    [flowerPath addCurveToPoint: CGPointMake(50.66, 39.73) controlPoint1: CGPointMake(57.25, 52.01) controlPoint2: CGPointMake(55.45, 45.81)];
    [flowerPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(58.34, 38.82) controlPoint2: CGPointMake(64, 35.7)];
    [flowerPath addCurveToPoint: CGPointMake(50.66, 24.27) controlPoint1: CGPointMake(64, 28.3) controlPoint2: CGPointMake(58.34, 25.18)];
    [flowerPath addCurveToPoint: CGPointMake(54.63, 9.37) controlPoint1: CGPointMake(55.45, 18.19) controlPoint2: CGPointMake(57.25, 11.99)];
    [flowerPath addCurveToPoint: CGPointMake(39.73, 13.34) controlPoint1: CGPointMake(52.01, 6.75) controlPoint2: CGPointMake(45.81, 8.55)];
    [flowerPath addLineToPoint: CGPointMake(39.73, 13.34)];
    [flowerPath addLineToPoint: CGPointMake(39.73, 13.34)];
    [flowerPath closePath];
    [flowerPath moveToPoint: CGPointMake(32, 44)];
    [flowerPath addCurveToPoint: CGPointMake(44, 32) controlPoint1: CGPointMake(38.63, 44) controlPoint2: CGPointMake(44, 38.63)];
    [flowerPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(44, 25.37) controlPoint2: CGPointMake(38.63, 20)];
    [flowerPath addCurveToPoint: CGPointMake(20, 32) controlPoint1: CGPointMake(25.37, 20) controlPoint2: CGPointMake(20, 25.37)];
    [flowerPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(20, 38.63) controlPoint2: CGPointMake(25.37, 44)];
    [flowerPath addLineToPoint: CGPointMake(32, 44)];
    [flowerPath closePath];
    flowerPath.usesEvenOddFillRule = YES;
    [color setFill];
    [flowerPath fill];
}

+ (void)drawIcon_0x251_32ptWithColor: (UIColor*)color
{

    //// Cake Drawing
    UIBezierPath* cakePath = [UIBezierPath bezierPath];
    [cakePath moveToPoint: CGPointMake(52, 28)];
    [cakePath addLineToPoint: CGPointMake(52, 16)];
    [cakePath addLineToPoint: CGPointMake(44, 16)];
    [cakePath addLineToPoint: CGPointMake(44, 28)];
    [cakePath addLineToPoint: CGPointMake(36, 28)];
    [cakePath addLineToPoint: CGPointMake(36, 12)];
    [cakePath addLineToPoint: CGPointMake(28, 12)];
    [cakePath addLineToPoint: CGPointMake(28, 28)];
    [cakePath addLineToPoint: CGPointMake(20, 28)];
    [cakePath addLineToPoint: CGPointMake(20, 16)];
    [cakePath addLineToPoint: CGPointMake(12, 16)];
    [cakePath addLineToPoint: CGPointMake(12, 28)];
    [cakePath addLineToPoint: CGPointMake(7.98, 28)];
    [cakePath addCurveToPoint: CGPointMake(0, 35.99) controlPoint1: CGPointMake(3.58, 28) controlPoint2: CGPointMake(0, 31.58)];
    [cakePath addLineToPoint: CGPointMake(0, 42.98)];
    [cakePath addCurveToPoint: CGPointMake(16, 48) controlPoint1: CGPointMake(4.54, 46.14) controlPoint2: CGPointMake(10.05, 48)];
    [cakePath addCurveToPoint: CGPointMake(32, 42.98) controlPoint1: CGPointMake(21.95, 48) controlPoint2: CGPointMake(27.46, 46.14)];
    [cakePath addCurveToPoint: CGPointMake(48, 48) controlPoint1: CGPointMake(36.54, 46.14) controlPoint2: CGPointMake(42.05, 48)];
    [cakePath addCurveToPoint: CGPointMake(64, 43.7) controlPoint1: CGPointMake(53.95, 48) controlPoint2: CGPointMake(59.46, 46.14)];
    [cakePath addLineToPoint: CGPointMake(64, 35.99)];
    [cakePath addCurveToPoint: CGPointMake(56.02, 28) controlPoint1: CGPointMake(64, 31.58) controlPoint2: CGPointMake(60.43, 28)];
    [cakePath addLineToPoint: CGPointMake(52, 28)];
    [cakePath closePath];
    [cakePath moveToPoint: CGPointMake(13.17, 12.49)];
    [cakePath addCurveToPoint: CGPointMake(18.83, 12.49) controlPoint1: CGPointMake(14.73, 14.05) controlPoint2: CGPointMake(17.27, 14.05)];
    [cakePath addCurveToPoint: CGPointMake(18.83, 6.83) controlPoint1: CGPointMake(20.39, 10.92) controlPoint2: CGPointMake(20.39, 8.39)];
    [cakePath addLineToPoint: CGPointMake(16, 4)];
    [cakePath addLineToPoint: CGPointMake(13.17, 6.83)];
    [cakePath addCurveToPoint: CGPointMake(13.17, 12.49) controlPoint1: CGPointMake(11.61, 8.39) controlPoint2: CGPointMake(11.61, 10.92)];
    [cakePath closePath];
    [cakePath moveToPoint: CGPointMake(45.17, 12.49)];
    [cakePath addCurveToPoint: CGPointMake(50.83, 12.49) controlPoint1: CGPointMake(46.73, 14.05) controlPoint2: CGPointMake(49.27, 14.05)];
    [cakePath addCurveToPoint: CGPointMake(50.83, 6.83) controlPoint1: CGPointMake(52.39, 10.92) controlPoint2: CGPointMake(52.39, 8.39)];
    [cakePath addLineToPoint: CGPointMake(48, 4)];
    [cakePath addLineToPoint: CGPointMake(45.17, 6.83)];
    [cakePath addCurveToPoint: CGPointMake(45.17, 12.49) controlPoint1: CGPointMake(43.61, 8.39) controlPoint2: CGPointMake(43.61, 10.92)];
    [cakePath closePath];
    [cakePath moveToPoint: CGPointMake(29.17, 8.49)];
    [cakePath addCurveToPoint: CGPointMake(34.83, 8.49) controlPoint1: CGPointMake(30.73, 10.05) controlPoint2: CGPointMake(33.27, 10.05)];
    [cakePath addCurveToPoint: CGPointMake(34.83, 2.83) controlPoint1: CGPointMake(36.39, 6.92) controlPoint2: CGPointMake(36.39, 4.39)];
    [cakePath addLineToPoint: CGPointMake(32, 0)];
    [cakePath addLineToPoint: CGPointMake(29.17, 2.83)];
    [cakePath addCurveToPoint: CGPointMake(29.17, 8.49) controlPoint1: CGPointMake(27.61, 4.39) controlPoint2: CGPointMake(27.61, 6.92)];
    [cakePath closePath];
    [cakePath moveToPoint: CGPointMake(64, 47.72)];
    [cakePath addLineToPoint: CGPointMake(64, 64)];
    [cakePath addLineToPoint: CGPointMake(0, 64)];
    [cakePath addLineToPoint: CGPointMake(0, 47.72)];
    [cakePath addCurveToPoint: CGPointMake(16, 52) controlPoint1: CGPointMake(4.71, 50.44) controlPoint2: CGPointMake(10.17, 52)];
    [cakePath addCurveToPoint: CGPointMake(32, 47.72) controlPoint1: CGPointMake(21.83, 52) controlPoint2: CGPointMake(27.29, 50.44)];
    [cakePath addCurveToPoint: CGPointMake(48, 52) controlPoint1: CGPointMake(36.71, 50.44) controlPoint2: CGPointMake(42.17, 52)];
    [cakePath addCurveToPoint: CGPointMake(64, 47.72) controlPoint1: CGPointMake(53.83, 52) controlPoint2: CGPointMake(59.29, 50.44)];
    [cakePath addLineToPoint: CGPointMake(64, 47.72)];
    [cakePath closePath];
    cakePath.usesEvenOddFillRule = YES;
    [color setFill];
    [cakePath fill];
}

+ (void)drawIcon_0x252_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(64, 45.01)];
    [bezierPath addLineToPoint: CGPointMake(64, 32)];
    [bezierPath addLineToPoint: CGPointMake(57.94, 7.75)];
    [bezierPath addCurveToPoint: CGPointMake(47.97, 0) controlPoint1: CGPointMake(56.87, 3.47) controlPoint2: CGPointMake(52.39, 0)];
    [bezierPath addLineToPoint: CGPointMake(16.03, 0)];
    [bezierPath addCurveToPoint: CGPointMake(6.06, 7.75) controlPoint1: CGPointMake(11.6, 0) controlPoint2: CGPointMake(7.13, 3.49)];
    [bezierPath addLineToPoint: CGPointMake(0, 32)];
    [bezierPath addLineToPoint: CGPointMake(0, 45.01)];
    [bezierPath addLineToPoint: CGPointMake(0, 57.98)];
    [bezierPath addCurveToPoint: CGPointMake(6, 64) controlPoint1: CGPointMake(0, 61.33) controlPoint2: CGPointMake(2.69, 64)];
    [bezierPath addCurveToPoint: CGPointMake(12, 57.98) controlPoint1: CGPointMake(9.34, 64) controlPoint2: CGPointMake(12, 61.31)];
    [bezierPath addLineToPoint: CGPointMake(12, 52)];
    [bezierPath addLineToPoint: CGPointMake(52, 52)];
    [bezierPath addLineToPoint: CGPointMake(52, 57.98)];
    [bezierPath addCurveToPoint: CGPointMake(58, 64) controlPoint1: CGPointMake(52, 61.33) controlPoint2: CGPointMake(54.69, 64)];
    [bezierPath addCurveToPoint: CGPointMake(64, 57.98) controlPoint1: CGPointMake(61.34, 64) controlPoint2: CGPointMake(64, 61.31)];
    [bezierPath addLineToPoint: CGPointMake(64, 45.01)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(9, 24)];
    [bezierPath addLineToPoint: CGPointMake(55, 24)];
    [bezierPath addLineToPoint: CGPointMake(51.87, 9.91)];
    [bezierPath addCurveToPoint: CGPointMake(47.01, 6) controlPoint1: CGPointMake(51.39, 7.75) controlPoint2: CGPointMake(49.22, 6)];
    [bezierPath addLineToPoint: CGPointMake(16.99, 6)];
    [bezierPath addCurveToPoint: CGPointMake(12.13, 9.91) controlPoint1: CGPointMake(14.79, 6) controlPoint2: CGPointMake(12.62, 7.73)];
    [bezierPath addLineToPoint: CGPointMake(9, 24)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(14, 44)];
    [bezierPath addCurveToPoint: CGPointMake(20, 38) controlPoint1: CGPointMake(17.31, 44) controlPoint2: CGPointMake(20, 41.31)];
    [bezierPath addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(20, 34.69) controlPoint2: CGPointMake(17.31, 32)];
    [bezierPath addCurveToPoint: CGPointMake(8, 38) controlPoint1: CGPointMake(10.69, 32) controlPoint2: CGPointMake(8, 34.69)];
    [bezierPath addCurveToPoint: CGPointMake(14, 44) controlPoint1: CGPointMake(8, 41.31) controlPoint2: CGPointMake(10.69, 44)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(50, 44)];
    [bezierPath addCurveToPoint: CGPointMake(56, 38) controlPoint1: CGPointMake(53.31, 44) controlPoint2: CGPointMake(56, 41.31)];
    [bezierPath addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(56, 34.69) controlPoint2: CGPointMake(53.31, 32)];
    [bezierPath addCurveToPoint: CGPointMake(44, 38) controlPoint1: CGPointMake(46.69, 32) controlPoint2: CGPointMake(44, 34.69)];
    [bezierPath addCurveToPoint: CGPointMake(50, 44) controlPoint1: CGPointMake(44, 41.31) controlPoint2: CGPointMake(46.69, 44)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x253_32ptWithColor: (UIColor*)color
{

    //// Ball Drawing
    UIBezierPath* ballPath = [UIBezierPath bezierPath];
    [ballPath moveToPoint: CGPointMake(34.14, 29.86)];
    [ballPath addLineToPoint: CGPointMake(44.95, 29.86)];
    [ballPath addCurveToPoint: CGPointMake(54.06, 8.72) controlPoint1: CGPointMake(45.46, 21.71) controlPoint2: CGPointMake(48.84, 14.35)];
    [ballPath addCurveToPoint: CGPointMake(34.14, 0) controlPoint1: CGPointMake(48.79, 3.72) controlPoint2: CGPointMake(41.85, 0.51)];
    [ballPath addLineToPoint: CGPointMake(34.14, 29.86)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(29.86, 29.86)];
    [ballPath addLineToPoint: CGPointMake(29.86, 0)];
    [ballPath addCurveToPoint: CGPointMake(9.93, 8.72) controlPoint1: CGPointMake(22.15, 0.51) controlPoint2: CGPointMake(15.2, 3.72)];
    [ballPath addCurveToPoint: CGPointMake(19.05, 29.86) controlPoint1: CGPointMake(15.16, 14.35) controlPoint2: CGPointMake(18.54, 21.71)];
    [ballPath addLineToPoint: CGPointMake(29.86, 29.86)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(14.76, 29.86)];
    [ballPath addCurveToPoint: CGPointMake(7.03, 11.85) controlPoint1: CGPointMake(14.27, 22.95) controlPoint2: CGPointMake(11.42, 16.68)];
    [ballPath addCurveToPoint: CGPointMake(0, 29.86) controlPoint1: CGPointMake(2.99, 16.84) controlPoint2: CGPointMake(0.45, 23.06)];
    [ballPath addLineToPoint: CGPointMake(14.76, 29.86)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(64, 29.86)];
    [ballPath addCurveToPoint: CGPointMake(56.97, 11.85) controlPoint1: CGPointMake(63.55, 23.06) controlPoint2: CGPointMake(61.01, 16.84)];
    [ballPath addCurveToPoint: CGPointMake(49.23, 29.86) controlPoint1: CGPointMake(52.58, 16.68) controlPoint2: CGPointMake(49.72, 22.95)];
    [ballPath addLineToPoint: CGPointMake(64, 29.86)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(29.86, 34.14)];
    [ballPath addLineToPoint: CGPointMake(19.05, 34.14)];
    [ballPath addCurveToPoint: CGPointMake(9.93, 55.28) controlPoint1: CGPointMake(18.54, 42.29) controlPoint2: CGPointMake(15.16, 49.65)];
    [ballPath addCurveToPoint: CGPointMake(29.86, 64) controlPoint1: CGPointMake(15.2, 60.28) controlPoint2: CGPointMake(22.15, 63.49)];
    [ballPath addLineToPoint: CGPointMake(29.86, 34.14)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(44.95, 34.14)];
    [ballPath addLineToPoint: CGPointMake(34.14, 34.14)];
    [ballPath addLineToPoint: CGPointMake(34.14, 64)];
    [ballPath addCurveToPoint: CGPointMake(54.06, 55.28) controlPoint1: CGPointMake(41.85, 63.49) controlPoint2: CGPointMake(48.79, 60.28)];
    [ballPath addCurveToPoint: CGPointMake(44.95, 34.14) controlPoint1: CGPointMake(48.84, 49.65) controlPoint2: CGPointMake(45.46, 42.29)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(0, 34.14)];
    [ballPath addCurveToPoint: CGPointMake(7.03, 52.15) controlPoint1: CGPointMake(0.45, 40.94) controlPoint2: CGPointMake(2.99, 47.17)];
    [ballPath addCurveToPoint: CGPointMake(14.76, 34.14) controlPoint1: CGPointMake(11.42, 47.32) controlPoint2: CGPointMake(14.27, 41.05)];
    [ballPath addLineToPoint: CGPointMake(0, 34.14)];
    [ballPath closePath];
    [ballPath moveToPoint: CGPointMake(49.23, 34.14)];
    [ballPath addCurveToPoint: CGPointMake(56.97, 52.15) controlPoint1: CGPointMake(49.72, 41.05) controlPoint2: CGPointMake(52.58, 47.32)];
    [ballPath addCurveToPoint: CGPointMake(64, 34.14) controlPoint1: CGPointMake(61.01, 47.17) controlPoint2: CGPointMake(63.55, 40.94)];
    [ballPath addLineToPoint: CGPointMake(49.23, 34.14)];
    [ballPath closePath];
    ballPath.usesEvenOddFillRule = YES;
    [color setFill];
    [ballPath fill];
}

+ (void)drawIcon_0x254_32ptWithColor: (UIColor*)color
{

    //// Crown Drawing
    UIBezierPath* crownPath = [UIBezierPath bezierPath];
    [crownPath moveToPoint: CGPointMake(30.21, 7.58)];
    [crownPath addLineToPoint: CGPointMake(19.3, 29.39)];
    [crownPath addLineToPoint: CGPointMake(7.01, 18.63)];
    [crownPath addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(7.63, 17.93) controlPoint2: CGPointMake(8, 17.01)];
    [crownPath addCurveToPoint: CGPointMake(4, 12) controlPoint1: CGPointMake(8, 13.79) controlPoint2: CGPointMake(6.21, 12)];
    [crownPath addCurveToPoint: CGPointMake(0, 16) controlPoint1: CGPointMake(1.79, 12) controlPoint2: CGPointMake(0, 13.79)];
    [crownPath addCurveToPoint: CGPointMake(4, 20) controlPoint1: CGPointMake(0, 18.21) controlPoint2: CGPointMake(1.79, 20)];
    [crownPath addLineToPoint: CGPointMake(4, 37.33)];
    [crownPath addLineToPoint: CGPointMake(4, 56)];
    [crownPath addLineToPoint: CGPointMake(60, 56)];
    [crownPath addLineToPoint: CGPointMake(60, 37.33)];
    [crownPath addLineToPoint: CGPointMake(60, 20)];
    [crownPath addCurveToPoint: CGPointMake(64, 16) controlPoint1: CGPointMake(62.21, 20) controlPoint2: CGPointMake(64, 18.21)];
    [crownPath addCurveToPoint: CGPointMake(60, 12) controlPoint1: CGPointMake(64, 13.79) controlPoint2: CGPointMake(62.21, 12)];
    [crownPath addCurveToPoint: CGPointMake(56, 16) controlPoint1: CGPointMake(57.79, 12) controlPoint2: CGPointMake(56, 13.79)];
    [crownPath addCurveToPoint: CGPointMake(56.99, 18.63) controlPoint1: CGPointMake(56, 17.01) controlPoint2: CGPointMake(56.37, 17.93)];
    [crownPath addLineToPoint: CGPointMake(44.7, 29.39)];
    [crownPath addLineToPoint: CGPointMake(33.79, 7.58)];
    [crownPath addCurveToPoint: CGPointMake(36, 4) controlPoint1: CGPointMake(35.1, 6.92) controlPoint2: CGPointMake(36, 5.57)];
    [crownPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(36, 1.79) controlPoint2: CGPointMake(34.21, 0)];
    [crownPath addCurveToPoint: CGPointMake(28, 4) controlPoint1: CGPointMake(29.79, 0) controlPoint2: CGPointMake(28, 1.79)];
    [crownPath addCurveToPoint: CGPointMake(30.21, 7.58) controlPoint1: CGPointMake(28, 5.57) controlPoint2: CGPointMake(28.9, 6.92)];
    [crownPath addLineToPoint: CGPointMake(30.21, 7.58)];
    [crownPath closePath];
    [crownPath moveToPoint: CGPointMake(4, 60)];
    [crownPath addLineToPoint: CGPointMake(60, 60)];
    [crownPath addLineToPoint: CGPointMake(60, 64)];
    [crownPath addLineToPoint: CGPointMake(4, 64)];
    [crownPath addLineToPoint: CGPointMake(4, 60)];
    [crownPath closePath];
    [crownPath moveToPoint: CGPointMake(32, 48)];
    [crownPath addCurveToPoint: CGPointMake(36, 44) controlPoint1: CGPointMake(34.21, 48) controlPoint2: CGPointMake(36, 46.21)];
    [crownPath addCurveToPoint: CGPointMake(32, 40) controlPoint1: CGPointMake(36, 41.79) controlPoint2: CGPointMake(34.21, 40)];
    [crownPath addCurveToPoint: CGPointMake(28, 44) controlPoint1: CGPointMake(29.79, 40) controlPoint2: CGPointMake(28, 41.79)];
    [crownPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(28, 46.21) controlPoint2: CGPointMake(29.79, 48)];
    [crownPath closePath];
    [crownPath moveToPoint: CGPointMake(16, 48)];
    [crownPath addCurveToPoint: CGPointMake(20, 44) controlPoint1: CGPointMake(18.21, 48) controlPoint2: CGPointMake(20, 46.21)];
    [crownPath addCurveToPoint: CGPointMake(16, 40) controlPoint1: CGPointMake(20, 41.79) controlPoint2: CGPointMake(18.21, 40)];
    [crownPath addCurveToPoint: CGPointMake(12, 44) controlPoint1: CGPointMake(13.79, 40) controlPoint2: CGPointMake(12, 41.79)];
    [crownPath addCurveToPoint: CGPointMake(16, 48) controlPoint1: CGPointMake(12, 46.21) controlPoint2: CGPointMake(13.79, 48)];
    [crownPath closePath];
    [crownPath moveToPoint: CGPointMake(48, 48)];
    [crownPath addCurveToPoint: CGPointMake(52, 44) controlPoint1: CGPointMake(50.21, 48) controlPoint2: CGPointMake(52, 46.21)];
    [crownPath addCurveToPoint: CGPointMake(48, 40) controlPoint1: CGPointMake(52, 41.79) controlPoint2: CGPointMake(50.21, 40)];
    [crownPath addCurveToPoint: CGPointMake(44, 44) controlPoint1: CGPointMake(45.79, 40) controlPoint2: CGPointMake(44, 41.79)];
    [crownPath addCurveToPoint: CGPointMake(48, 48) controlPoint1: CGPointMake(44, 46.21) controlPoint2: CGPointMake(45.79, 48)];
    [crownPath closePath];
    crownPath.usesEvenOddFillRule = YES;
    [color setFill];
    [crownPath fill];
}

+ (void)drawIcon_0x255_32ptWithColor: (UIColor*)color
{

    //// Symbol Drawing
    UIBezierPath* symbolPath = [UIBezierPath bezierPath];
    [symbolPath moveToPoint: CGPointMake(27.55, 24.23)];
    [symbolPath addLineToPoint: CGPointMake(26.04, 0)];
    [symbolPath addLineToPoint: CGPointMake(37.96, 0)];
    [symbolPath addLineToPoint: CGPointMake(36.45, 24.23)];
    [symbolPath addLineToPoint: CGPointMake(56.54, 10.8)];
    [symbolPath addLineToPoint: CGPointMake(62.5, 21.2)];
    [symbolPath addLineToPoint: CGPointMake(40.91, 32)];
    [symbolPath addLineToPoint: CGPointMake(62.5, 42.8)];
    [symbolPath addLineToPoint: CGPointMake(56.54, 53.2)];
    [symbolPath addLineToPoint: CGPointMake(36.45, 39.77)];
    [symbolPath addLineToPoint: CGPointMake(37.96, 64)];
    [symbolPath addLineToPoint: CGPointMake(26.04, 64)];
    [symbolPath addLineToPoint: CGPointMake(27.55, 39.77)];
    [symbolPath addLineToPoint: CGPointMake(7.46, 53.2)];
    [symbolPath addLineToPoint: CGPointMake(1.5, 42.8)];
    [symbolPath addLineToPoint: CGPointMake(23.09, 32)];
    [symbolPath addLineToPoint: CGPointMake(1.5, 21.2)];
    [symbolPath addLineToPoint: CGPointMake(7.46, 10.8)];
    [symbolPath addLineToPoint: CGPointMake(27.55, 24.23)];
    [symbolPath addLineToPoint: CGPointMake(27.55, 24.23)];
    [symbolPath closePath];
    symbolPath.usesEvenOddFillRule = YES;
    [color setFill];
    [symbolPath fill];
}

+ (void)drawIcon_0x256_32ptWithColor: (UIColor*)color
{

    //// Flag Drawing
    UIBezierPath* flagPath = [UIBezierPath bezierPath];
    [flagPath moveToPoint: CGPointMake(8.23, 6.46)];
    [flagPath addCurveToPoint: CGPointMake(32, 5.89) controlPoint1: CGPointMake(13.43, 4.99) controlPoint2: CGPointMake(22.72, 3.24)];
    [flagPath addCurveToPoint: CGPointMake(60, 3.89) controlPoint1: CGPointMake(46, 9.89) controlPoint2: CGPointMake(60, 3.89)];
    [flagPath addLineToPoint: CGPointMake(64, 39.89)];
    [flagPath addCurveToPoint: CGPointMake(36, 41.89) controlPoint1: CGPointMake(64, 39.89) controlPoint2: CGPointMake(50, 45.89)];
    [flagPath addCurveToPoint: CGPointMake(11.41, 42.7) controlPoint1: CGPointMake(26.2, 39.1) controlPoint2: CGPointMake(16.41, 41.19)];
    [flagPath addLineToPoint: CGPointMake(13.21, 63.3)];
    [flagPath addLineToPoint: CGPointMake(5.24, 64)];
    [flagPath addLineToPoint: CGPointMake(0.02, 4.34)];
    [flagPath addCurveToPoint: CGPointMake(3.65, 0.02) controlPoint1: CGPointMake(-0.18, 2.15) controlPoint2: CGPointMake(1.44, 0.21)];
    [flagPath addCurveToPoint: CGPointMake(7.99, 3.65) controlPoint1: CGPointMake(5.85, -0.18) controlPoint2: CGPointMake(7.79, 1.44)];
    [flagPath addLineToPoint: CGPointMake(8.23, 6.46)];
    [flagPath addLineToPoint: CGPointMake(8.23, 6.46)];
    [flagPath closePath];
    flagPath.usesEvenOddFillRule = YES;
    [color setFill];
    [flagPath fill];
}

+ (void)drawIcon_0x124_32ptWithColor: (UIColor*)color
{

    //// More Drawing
    UIBezierPath* morePath = [UIBezierPath bezierPath];
    [morePath moveToPoint: CGPointMake(8, 64)];
    [morePath addCurveToPoint: CGPointMake(16, 56) controlPoint1: CGPointMake(12.42, 64) controlPoint2: CGPointMake(16, 60.42)];
    [morePath addCurveToPoint: CGPointMake(8, 48) controlPoint1: CGPointMake(16, 51.58) controlPoint2: CGPointMake(12.42, 48)];
    [morePath addCurveToPoint: CGPointMake(0, 56) controlPoint1: CGPointMake(3.58, 48) controlPoint2: CGPointMake(0, 51.58)];
    [morePath addCurveToPoint: CGPointMake(8, 64) controlPoint1: CGPointMake(0, 60.42) controlPoint2: CGPointMake(3.58, 64)];
    [morePath addLineToPoint: CGPointMake(8, 64)];
    [morePath closePath];
    [morePath moveToPoint: CGPointMake(56, 64)];
    [morePath addCurveToPoint: CGPointMake(64, 56) controlPoint1: CGPointMake(60.42, 64) controlPoint2: CGPointMake(64, 60.42)];
    [morePath addCurveToPoint: CGPointMake(56, 48) controlPoint1: CGPointMake(64, 51.58) controlPoint2: CGPointMake(60.42, 48)];
    [morePath addCurveToPoint: CGPointMake(48, 56) controlPoint1: CGPointMake(51.58, 48) controlPoint2: CGPointMake(48, 51.58)];
    [morePath addCurveToPoint: CGPointMake(56, 64) controlPoint1: CGPointMake(48, 60.42) controlPoint2: CGPointMake(51.58, 64)];
    [morePath addLineToPoint: CGPointMake(56, 64)];
    [morePath closePath];
    [morePath moveToPoint: CGPointMake(32, 64)];
    [morePath addCurveToPoint: CGPointMake(40, 56) controlPoint1: CGPointMake(36.42, 64) controlPoint2: CGPointMake(40, 60.42)];
    [morePath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(40, 51.58) controlPoint2: CGPointMake(36.42, 48)];
    [morePath addCurveToPoint: CGPointMake(24, 56) controlPoint1: CGPointMake(27.58, 48) controlPoint2: CGPointMake(24, 51.58)];
    [morePath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(24, 60.42) controlPoint2: CGPointMake(27.58, 64)];
    [morePath addLineToPoint: CGPointMake(32, 64)];
    [morePath closePath];
    morePath.usesEvenOddFillRule = YES;
    [color setFill];
    [morePath fill];
}

+ (void)drawIcon_0x239_32ptWithColor: (UIColor*)color
{

    //// Hourglass Drawing
    UIBezierPath* hourglassPath = [UIBezierPath bezierPath];
    [hourglassPath moveToPoint: CGPointMake(28, 32)];
    [hourglassPath addCurveToPoint: CGPointMake(32, 36) controlPoint1: CGPointMake(28, 34.21) controlPoint2: CGPointMake(29.79, 36)];
    [hourglassPath addCurveToPoint: CGPointMake(36, 32) controlPoint1: CGPointMake(34.21, 36) controlPoint2: CGPointMake(36, 34.21)];
    [hourglassPath addLineToPoint: CGPointMake(28, 32)];
    [hourglassPath closePath];
    [hourglassPath moveToPoint: CGPointMake(36, 32)];
    [hourglassPath addCurveToPoint: CGPointMake(40.45, 41.21) controlPoint1: CGPointMake(36, 36.02) controlPoint2: CGPointMake(37.46, 38.58)];
    [hourglassPath addCurveToPoint: CGPointMake(43.21, 43.62) controlPoint1: CGPointMake(40.69, 41.4) controlPoint2: CGPointMake(42.7, 43.12)];
    [hourglassPath addCurveToPoint: CGPointMake(47.86, 56) controlPoint1: CGPointMake(45.86, 46.19) controlPoint2: CGPointMake(47.41, 49.68)];
    [hourglassPath addLineToPoint: CGPointMake(16.14, 56)];
    [hourglassPath addCurveToPoint: CGPointMake(20.79, 43.62) controlPoint1: CGPointMake(16.59, 49.68) controlPoint2: CGPointMake(18.14, 46.19)];
    [hourglassPath addCurveToPoint: CGPointMake(23.55, 41.21) controlPoint1: CGPointMake(21.3, 43.12) controlPoint2: CGPointMake(23.31, 41.4)];
    [hourglassPath addCurveToPoint: CGPointMake(28, 32) controlPoint1: CGPointMake(26.54, 38.58) controlPoint2: CGPointMake(28, 36.02)];
    [hourglassPath addLineToPoint: CGPointMake(36, 32)];
    [hourglassPath closePath];
    [hourglassPath moveToPoint: CGPointMake(47.86, 8)];
    [hourglassPath addCurveToPoint: CGPointMake(47.37, 12) controlPoint1: CGPointMake(47.75, 9.48) controlPoint2: CGPointMake(47.6, 10.81)];
    [hourglassPath addLineToPoint: CGPointMake(16.63, 12)];
    [hourglassPath addCurveToPoint: CGPointMake(16.14, 8) controlPoint1: CGPointMake(16.4, 10.81) controlPoint2: CGPointMake(16.25, 9.48)];
    [hourglassPath addLineToPoint: CGPointMake(47.86, 8)];
    [hourglassPath closePath];
    [hourglassPath moveToPoint: CGPointMake(51.87, 8)];
    [hourglassPath addLineToPoint: CGPointMake(56, 8)];
    [hourglassPath addLineToPoint: CGPointMake(56, 4)];
    [hourglassPath addCurveToPoint: CGPointMake(51.99, 0) controlPoint1: CGPointMake(56, 1.78) controlPoint2: CGPointMake(54.2, 0)];
    [hourglassPath addLineToPoint: CGPointMake(12.01, 0)];
    [hourglassPath addCurveToPoint: CGPointMake(8, 4) controlPoint1: CGPointMake(9.82, 0) controlPoint2: CGPointMake(8, 1.79)];
    [hourglassPath addLineToPoint: CGPointMake(8, 8)];
    [hourglassPath addLineToPoint: CGPointMake(12.13, 8)];
    [hourglassPath addCurveToPoint: CGPointMake(24, 32) controlPoint1: CGPointMake(13.44, 26.81) controlPoint2: CGPointMake(24, 23.24)];
    [hourglassPath addCurveToPoint: CGPointMake(12.13, 56) controlPoint1: CGPointMake(24, 40.76) controlPoint2: CGPointMake(13.44, 37.19)];
    [hourglassPath addLineToPoint: CGPointMake(12.13, 56)];
    [hourglassPath addLineToPoint: CGPointMake(8, 56)];
    [hourglassPath addLineToPoint: CGPointMake(8, 60)];
    [hourglassPath addCurveToPoint: CGPointMake(12.01, 64) controlPoint1: CGPointMake(8, 62.22) controlPoint2: CGPointMake(9.8, 64)];
    [hourglassPath addLineToPoint: CGPointMake(51.99, 64)];
    [hourglassPath addCurveToPoint: CGPointMake(56, 60) controlPoint1: CGPointMake(54.18, 64) controlPoint2: CGPointMake(56, 62.21)];
    [hourglassPath addLineToPoint: CGPointMake(56, 56)];
    [hourglassPath addLineToPoint: CGPointMake(51.87, 56)];
    [hourglassPath addLineToPoint: CGPointMake(51.87, 56)];
    [hourglassPath addCurveToPoint: CGPointMake(40, 32) controlPoint1: CGPointMake(50.56, 37.19) controlPoint2: CGPointMake(40, 40.76)];
    [hourglassPath addCurveToPoint: CGPointMake(51.87, 8) controlPoint1: CGPointMake(40, 23.24) controlPoint2: CGPointMake(50.56, 26.81)];
    [hourglassPath addLineToPoint: CGPointMake(51.87, 8)];
    [hourglassPath closePath];
    hourglassPath.usesEvenOddFillRule = YES;
    [color setFill];
    [hourglassPath fill];
}

+ (void)drawSecondWithColor: (UIColor*)color
{
    //// Color Declarations
    UIColor* color40 = [color colorWithAlphaComponent: 0.4];

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPath];
    [ovalPath moveToPoint: CGPointMake(55.72, 35.66)];
    [ovalPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(53.96, 47.18) controlPoint2: CGPointMake(44.01, 56)];
    [ovalPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 56) controlPoint2: CGPointMake(8, 45.25)];
    [ovalPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(8, 18.75) controlPoint2: CGPointMake(18.75, 8)];
    [ovalPath addCurveToPoint: CGPointMake(48.78, 14.84) controlPoint1: CGPointMake(38.53, 8) controlPoint2: CGPointMake(44.45, 10.61)];
    [ovalPath addCurveToPoint: CGPointMake(47.81, 15.3) controlPoint1: CGPointMake(48.45, 14.98) controlPoint2: CGPointMake(48.13, 15.13)];
    [ovalPath addCurveToPoint: CGPointMake(32, 9) controlPoint1: CGPointMake(43.69, 11.39) controlPoint2: CGPointMake(38.12, 9)];
    [ovalPath addCurveToPoint: CGPointMake(9, 32) controlPoint1: CGPointMake(19.3, 9) controlPoint2: CGPointMake(9, 19.3)];
    [ovalPath addCurveToPoint: CGPointMake(32, 55) controlPoint1: CGPointMake(9, 44.7) controlPoint2: CGPointMake(19.3, 55)];
    [ovalPath addCurveToPoint: CGPointMake(54.68, 35.87) controlPoint1: CGPointMake(43.38, 55) controlPoint2: CGPointMake(52.83, 46.73)];
    [ovalPath addCurveToPoint: CGPointMake(55.72, 35.66) controlPoint1: CGPointMake(55.03, 35.82) controlPoint2: CGPointMake(55.38, 35.75)];
    [ovalPath addLineToPoint: CGPointMake(55.72, 35.66)];
    [ovalPath closePath];
    [color40 setFill];
    [ovalPath fill];


    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(49.16, 23.14)];
    [bezier2Path addCurveToPoint: CGPointMake(51.88, 25.86) controlPoint1: CGPointMake(49.16, 24.59) controlPoint2: CGPointMake(50.03, 25.44)];
    [bezier2Path addLineToPoint: CGPointMake(53.58, 26.26)];
    [bezier2Path addCurveToPoint: CGPointMake(54.91, 27.35) controlPoint1: CGPointMake(54.49, 26.46) controlPoint2: CGPointMake(54.91, 26.8)];
    [bezier2Path addCurveToPoint: CGPointMake(53.04, 28.54) controlPoint1: CGPointMake(54.91, 28.06) controlPoint2: CGPointMake(54.14, 28.54)];
    [bezier2Path addCurveToPoint: CGPointMake(51.07, 27.41) controlPoint1: CGPointMake(51.95, 28.54) controlPoint2: CGPointMake(51.28, 28.12)];
    [bezier2Path addLineToPoint: CGPointMake(48.91, 27.41)];
    [bezier2Path addCurveToPoint: CGPointMake(52.99, 30.19) controlPoint1: CGPointMake(49.08, 29.16) controlPoint2: CGPointMake(50.59, 30.19)];
    [bezier2Path addCurveToPoint: CGPointMake(57.09, 27.12) controlPoint1: CGPointMake(55.39, 30.19) controlPoint2: CGPointMake(57.09, 28.96)];
    [bezier2Path addCurveToPoint: CGPointMake(54.4, 24.5) controlPoint1: CGPointMake(57.09, 25.7) controlPoint2: CGPointMake(56.23, 24.91)];
    [bezier2Path addLineToPoint: CGPointMake(52.7, 24.11)];
    [bezier2Path addCurveToPoint: CGPointMake(51.28, 23.01) controlPoint1: CGPointMake(51.73, 23.89) controlPoint2: CGPointMake(51.28, 23.56)];
    [bezier2Path addCurveToPoint: CGPointMake(53.02, 21.84) controlPoint1: CGPointMake(51.28, 22.32) controlPoint2: CGPointMake(52.02, 21.84)];
    [bezier2Path addCurveToPoint: CGPointMake(54.84, 22.95) controlPoint1: CGPointMake(54.04, 21.84) controlPoint2: CGPointMake(54.68, 22.27)];
    [bezier2Path addLineToPoint: CGPointMake(56.88, 22.95)];
    [bezier2Path addCurveToPoint: CGPointMake(53.01, 20.19) controlPoint1: CGPointMake(56.73, 21.2) controlPoint2: CGPointMake(55.29, 20.19)];
    [bezier2Path addCurveToPoint: CGPointMake(49.16, 23.14) controlPoint1: CGPointMake(50.74, 20.19) controlPoint2: CGPointMake(49.16, 21.4)];
    [bezier2Path addLineToPoint: CGPointMake(49.16, 23.14)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawMinuteWithColor: (UIColor*)color
{
    //// Color Declarations
    UIColor* color40 = [color colorWithAlphaComponent: 0.4];

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 56)];
    [bezierPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 56) controlPoint2: CGPointMake(8, 45.25)];
    [bezierPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(8, 18.75) controlPoint2: CGPointMake(18.75, 8)];
    [bezierPath addCurveToPoint: CGPointMake(48.78, 14.84) controlPoint1: CGPointMake(38.53, 8) controlPoint2: CGPointMake(44.45, 10.61)];
    [bezierPath addCurveToPoint: CGPointMake(47.81, 15.3) controlPoint1: CGPointMake(48.45, 14.98) controlPoint2: CGPointMake(48.13, 15.13)];
    [bezierPath addCurveToPoint: CGPointMake(32, 9) controlPoint1: CGPointMake(43.69, 11.39) controlPoint2: CGPointMake(38.12, 9)];
    [bezierPath addCurveToPoint: CGPointMake(9, 32) controlPoint1: CGPointMake(19.3, 9) controlPoint2: CGPointMake(9, 19.3)];
    [bezierPath addCurveToPoint: CGPointMake(32, 55) controlPoint1: CGPointMake(9, 44.7) controlPoint2: CGPointMake(19.3, 55)];
    [bezierPath addCurveToPoint: CGPointMake(54.68, 35.87) controlPoint1: CGPointMake(43.38, 55) controlPoint2: CGPointMake(52.83, 46.73)];
    [bezierPath addCurveToPoint: CGPointMake(55.72, 35.66) controlPoint1: CGPointMake(55.03, 35.82) controlPoint2: CGPointMake(55.38, 35.75)];
    [bezierPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(53.96, 47.18) controlPoint2: CGPointMake(44.01, 56)];
    [bezierPath closePath];
    [color40 setFill];
    [bezierPath fill];


    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(46.18, 30)];
    [bezier2Path addLineToPoint: CGPointMake(48.36, 30)];
    [bezier2Path addLineToPoint: CGPointMake(48.36, 24.16)];
    [bezier2Path addCurveToPoint: CGPointMake(50.24, 22.09) controlPoint1: CGPointMake(48.36, 22.98) controlPoint2: CGPointMake(49.16, 22.09)];
    [bezier2Path addCurveToPoint: CGPointMake(51.98, 23.79) controlPoint1: CGPointMake(51.31, 22.09) controlPoint2: CGPointMake(51.98, 22.73)];
    [bezier2Path addLineToPoint: CGPointMake(51.98, 30)];
    [bezier2Path addLineToPoint: CGPointMake(54.1, 30)];
    [bezier2Path addLineToPoint: CGPointMake(54.1, 24.01)];
    [bezier2Path addCurveToPoint: CGPointMake(55.98, 22.09) controlPoint1: CGPointMake(54.1, 22.92) controlPoint2: CGPointMake(54.85, 22.09)];
    [bezier2Path addCurveToPoint: CGPointMake(57.74, 23.94) controlPoint1: CGPointMake(57.15, 22.09) controlPoint2: CGPointMake(57.74, 22.71)];
    [bezier2Path addLineToPoint: CGPointMake(57.74, 30)];
    [bezier2Path addLineToPoint: CGPointMake(59.91, 30)];
    [bezier2Path addLineToPoint: CGPointMake(59.91, 23.39)];
    [bezier2Path addCurveToPoint: CGPointMake(56.82, 20.19) controlPoint1: CGPointMake(59.91, 21.4) controlPoint2: CGPointMake(58.75, 20.19)];
    [bezier2Path addCurveToPoint: CGPointMake(53.91, 21.94) controlPoint1: CGPointMake(55.49, 20.19) controlPoint2: CGPointMake(54.38, 20.89)];
    [bezier2Path addLineToPoint: CGPointMake(53.76, 21.94)];
    [bezier2Path addCurveToPoint: CGPointMake(51.1, 20.19) controlPoint1: CGPointMake(53.35, 20.86) controlPoint2: CGPointMake(52.43, 20.19)];
    [bezier2Path addCurveToPoint: CGPointMake(48.43, 21.94) controlPoint1: CGPointMake(49.83, 20.19) controlPoint2: CGPointMake(48.84, 20.84)];
    [bezier2Path addLineToPoint: CGPointMake(48.28, 21.94)];
    [bezier2Path addLineToPoint: CGPointMake(48.28, 20.38)];
    [bezier2Path addLineToPoint: CGPointMake(46.18, 20.38)];
    [bezier2Path addLineToPoint: CGPointMake(46.18, 30)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawHourWithColor: (UIColor*)color
{
    //// Color Declarations
    UIColor* color40 = [color colorWithAlphaComponent: 0.4];

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(50.83, 30)];
    [bezierPath addLineToPoint: CGPointMake(53, 30)];
    [bezierPath addLineToPoint: CGPointMake(53, 24.42)];
    [bezierPath addCurveToPoint: CGPointMake(55.24, 22.11) controlPoint1: CGPointMake(53, 23.04) controlPoint2: CGPointMake(53.8, 22.11)];
    [bezierPath addCurveToPoint: CGPointMake(57.17, 24.31) controlPoint1: CGPointMake(56.5, 22.11) controlPoint2: CGPointMake(57.17, 22.85)];
    [bezierPath addLineToPoint: CGPointMake(57.17, 30)];
    [bezierPath addLineToPoint: CGPointMake(59.35, 30)];
    [bezierPath addLineToPoint: CGPointMake(59.35, 23.79)];
    [bezierPath addCurveToPoint: CGPointMake(56.05, 20.21) controlPoint1: CGPointMake(59.35, 21.51) controlPoint2: CGPointMake(58.1, 20.21)];
    [bezierPath addCurveToPoint: CGPointMake(53.13, 21.94) controlPoint1: CGPointMake(54.61, 20.21) controlPoint2: CGPointMake(53.58, 20.86)];
    [bezierPath addLineToPoint: CGPointMake(52.97, 21.94)];
    [bezierPath addLineToPoint: CGPointMake(52.97, 16.67)];
    [bezierPath addLineToPoint: CGPointMake(50.83, 16.67)];
    [bezierPath addLineToPoint: CGPointMake(50.83, 30)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];


    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(46.86, 13.15)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(42.77, 9.93) controlPoint2: CGPointMake(37.61, 8)];
    [bezier2Path addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [bezier2Path addCurveToPoint: CGPointMake(55.72, 35.66) controlPoint1: CGPointMake(44.01, 56) controlPoint2: CGPointMake(53.96, 47.18)];
    [bezier2Path addCurveToPoint: CGPointMake(54.68, 35.87) controlPoint1: CGPointMake(55.38, 35.75) controlPoint2: CGPointMake(55.03, 35.82)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 55) controlPoint1: CGPointMake(52.83, 46.73) controlPoint2: CGPointMake(43.38, 55)];
    [bezier2Path addCurveToPoint: CGPointMake(9, 32) controlPoint1: CGPointMake(19.3, 55) controlPoint2: CGPointMake(9, 44.7)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 9) controlPoint1: CGPointMake(9, 19.3) controlPoint2: CGPointMake(19.3, 9)];
    [bezier2Path addCurveToPoint: CGPointMake(45.89, 13.67) controlPoint1: CGPointMake(37.22, 9) controlPoint2: CGPointMake(42.03, 10.74)];
    [bezier2Path addCurveToPoint: CGPointMake(46.86, 13.15) controlPoint1: CGPointMake(46.21, 13.48) controlPoint2: CGPointMake(46.53, 13.31)];
    [bezier2Path addLineToPoint: CGPointMake(46.86, 13.15)];
    [bezier2Path closePath];
    [color40 setFill];
    [bezier2Path fill];
}

+ (void)drawDayWithColor: (UIColor*)color
{
    //// Color Declarations
    UIColor* color40 = [color colorWithAlphaComponent: 0.4];

    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(46.86, 13.15)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(42.77, 9.93) controlPoint2: CGPointMake(37.61, 8)];
    [bezier2Path addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(8, 45.25) controlPoint2: CGPointMake(18.75, 56)];
    [bezier2Path addCurveToPoint: CGPointMake(55.72, 35.66) controlPoint1: CGPointMake(44.01, 56) controlPoint2: CGPointMake(53.96, 47.18)];
    [bezier2Path addCurveToPoint: CGPointMake(54.68, 35.87) controlPoint1: CGPointMake(55.38, 35.75) controlPoint2: CGPointMake(55.03, 35.82)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 55) controlPoint1: CGPointMake(52.83, 46.73) controlPoint2: CGPointMake(43.38, 55)];
    [bezier2Path addCurveToPoint: CGPointMake(9, 32) controlPoint1: CGPointMake(19.3, 55) controlPoint2: CGPointMake(9, 44.7)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 9) controlPoint1: CGPointMake(9, 19.3) controlPoint2: CGPointMake(19.3, 9)];
    [bezier2Path addCurveToPoint: CGPointMake(45.89, 13.67) controlPoint1: CGPointMake(37.22, 9) controlPoint2: CGPointMake(42.03, 10.74)];
    [bezier2Path addCurveToPoint: CGPointMake(46.86, 13.15) controlPoint1: CGPointMake(46.21, 13.48) controlPoint2: CGPointMake(46.53, 13.31)];
    [bezier2Path addLineToPoint: CGPointMake(46.86, 13.15)];
    [bezier2Path closePath];
    [color40 setFill];
    [bezier2Path fill];


    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(53.13, 30)];
    [bezier3Path addCurveToPoint: CGPointMake(56.09, 28.34) controlPoint1: CGPointMake(54.45, 30) controlPoint2: CGPointMake(55.55, 29.38)];
    [bezier3Path addLineToPoint: CGPointMake(56.23, 28.34)];
    [bezier3Path addLineToPoint: CGPointMake(56.23, 29.84)];
    [bezier3Path addLineToPoint: CGPointMake(58.32, 29.84)];
    [bezier3Path addLineToPoint: CGPointMake(58.32, 16.67)];
    [bezier3Path addLineToPoint: CGPointMake(56.16, 16.67)];
    [bezier3Path addLineToPoint: CGPointMake(56.16, 21.85)];
    [bezier3Path addLineToPoint: CGPointMake(56.02, 21.85)];
    [bezier3Path addCurveToPoint: CGPointMake(53.13, 20.18) controlPoint1: CGPointMake(55.51, 20.81) controlPoint2: CGPointMake(54.44, 20.18)];
    [bezier3Path addCurveToPoint: CGPointMake(49.22, 25.08) controlPoint1: CGPointMake(50.74, 20.18) controlPoint2: CGPointMake(49.22, 22.08)];
    [bezier3Path addCurveToPoint: CGPointMake(53.13, 30) controlPoint1: CGPointMake(49.22, 28.11) controlPoint2: CGPointMake(50.73, 30)];
    [bezier3Path addLineToPoint: CGPointMake(53.13, 30)];
    [bezier3Path closePath];
    [bezier3Path moveToPoint: CGPointMake(53.8, 22.02)];
    [bezier3Path addCurveToPoint: CGPointMake(56.19, 25.09) controlPoint1: CGPointMake(55.28, 22.02) controlPoint2: CGPointMake(56.19, 23.2)];
    [bezier3Path addCurveToPoint: CGPointMake(53.8, 28.17) controlPoint1: CGPointMake(56.19, 27) controlPoint2: CGPointMake(55.29, 28.17)];
    [bezier3Path addCurveToPoint: CGPointMake(51.43, 25.09) controlPoint1: CGPointMake(52.33, 28.17) controlPoint2: CGPointMake(51.43, 27.01)];
    [bezier3Path addCurveToPoint: CGPointMake(53.8, 22.02) controlPoint1: CGPointMake(51.43, 23.18) controlPoint2: CGPointMake(52.33, 22.02)];
    [bezier3Path addLineToPoint: CGPointMake(53.8, 22.02)];
    [bezier3Path closePath];
    bezier3Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier3Path fill];
}

+ (void)drawIcon_0x737_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 60)];
    [bezierPath addCurveToPoint: CGPointMake(60, 32) controlPoint1: CGPointMake(47.46, 60) controlPoint2: CGPointMake(60, 47.46)];
    [bezierPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(60, 16.54) controlPoint2: CGPointMake(47.46, 4)];
    [bezierPath addCurveToPoint: CGPointMake(4, 32) controlPoint1: CGPointMake(16.54, 4) controlPoint2: CGPointMake(4, 16.54)];
    [bezierPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(4, 47.46) controlPoint2: CGPointMake(16.54, 60)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [bezierPath addCurveToPoint: CGPointMake(32, -0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, -0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, -0) controlPoint2: CGPointMake(64, 14.33)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(22, 24)];
    [bezierPath addCurveToPoint: CGPointMake(24, 22) controlPoint1: CGPointMake(23.1, 24) controlPoint2: CGPointMake(24, 23.1)];
    [bezierPath addCurveToPoint: CGPointMake(22, 20) controlPoint1: CGPointMake(24, 20.9) controlPoint2: CGPointMake(23.1, 20)];
    [bezierPath addCurveToPoint: CGPointMake(20, 22) controlPoint1: CGPointMake(20.9, 20) controlPoint2: CGPointMake(20, 20.9)];
    [bezierPath addCurveToPoint: CGPointMake(22, 24) controlPoint1: CGPointMake(20, 23.1) controlPoint2: CGPointMake(20.9, 24)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(22, 28)];
    [bezierPath addCurveToPoint: CGPointMake(16, 22) controlPoint1: CGPointMake(18.69, 28) controlPoint2: CGPointMake(16, 25.31)];
    [bezierPath addCurveToPoint: CGPointMake(22, 16) controlPoint1: CGPointMake(16, 18.69) controlPoint2: CGPointMake(18.69, 16)];
    [bezierPath addCurveToPoint: CGPointMake(28, 22) controlPoint1: CGPointMake(25.31, 16) controlPoint2: CGPointMake(28, 18.69)];
    [bezierPath addCurveToPoint: CGPointMake(22, 28) controlPoint1: CGPointMake(28, 25.31) controlPoint2: CGPointMake(25.31, 28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(42, 24)];
    [bezierPath addCurveToPoint: CGPointMake(44, 22) controlPoint1: CGPointMake(43.1, 24) controlPoint2: CGPointMake(44, 23.1)];
    [bezierPath addCurveToPoint: CGPointMake(42, 20) controlPoint1: CGPointMake(44, 20.9) controlPoint2: CGPointMake(43.1, 20)];
    [bezierPath addCurveToPoint: CGPointMake(40, 22) controlPoint1: CGPointMake(40.9, 20) controlPoint2: CGPointMake(40, 20.9)];
    [bezierPath addCurveToPoint: CGPointMake(42, 24) controlPoint1: CGPointMake(40, 23.1) controlPoint2: CGPointMake(40.9, 24)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(42, 28)];
    [bezierPath addCurveToPoint: CGPointMake(36, 22) controlPoint1: CGPointMake(38.69, 28) controlPoint2: CGPointMake(36, 25.31)];
    [bezierPath addCurveToPoint: CGPointMake(42, 16) controlPoint1: CGPointMake(36, 18.69) controlPoint2: CGPointMake(38.69, 16)];
    [bezierPath addCurveToPoint: CGPointMake(48, 22) controlPoint1: CGPointMake(45.31, 16) controlPoint2: CGPointMake(48, 18.69)];
    [bezierPath addCurveToPoint: CGPointMake(42, 28) controlPoint1: CGPointMake(48, 25.31) controlPoint2: CGPointMake(45.31, 28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 52)];
    [bezierPath addCurveToPoint: CGPointMake(16.14, 40) controlPoint1: CGPointMake(24.17, 52) controlPoint2: CGPointMake(17.64, 46.85)];
    [bezierPath addLineToPoint: CGPointMake(47.86, 40)];
    [bezierPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(46.36, 46.85) controlPoint2: CGPointMake(39.83, 52)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(52.8, 36)];
    [bezierPath addLineToPoint: CGPointMake(47.86, 36)];
    [bezierPath addLineToPoint: CGPointMake(16.14, 36)];
    [bezierPath addLineToPoint: CGPointMake(11.2, 36)];
    [bezierPath addLineToPoint: CGPointMake(12.26, 40.86)];
    [bezierPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(14.19, 49.64) controlPoint2: CGPointMake(22.49, 56)];
    [bezierPath addCurveToPoint: CGPointMake(51.73, 40.86) controlPoint1: CGPointMake(41.51, 56) controlPoint2: CGPointMake(49.81, 49.64)];
    [bezierPath addLineToPoint: CGPointMake(52.8, 36)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x654_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(4.68, 29.63)];
    [bezierPath addCurveToPoint: CGPointMake(4.68, 26.12) controlPoint1: CGPointMake(3.71, 28.66) controlPoint2: CGPointMake(3.71, 27.09)];
    [bezierPath addLineToPoint: CGPointMake(24.69, 6.06)];
    [bezierPath addCurveToPoint: CGPointMake(53.89, 6.06) controlPoint1: CGPointMake(32.75, -2.02) controlPoint2: CGPointMake(45.83, -2.02)];
    [bezierPath addCurveToPoint: CGPointMake(53.89, 35.36) controlPoint1: CGPointMake(61.97, 14.15) controlPoint2: CGPointMake(61.97, 27.26)];
    [bezierPath addLineToPoint: CGPointMake(48.17, 41.1)];
    [bezierPath addLineToPoint: CGPointMake(29.58, 59.72)];
    [bezierPath addCurveToPoint: CGPointMake(8.97, 59.72) controlPoint1: CGPointMake(23.89, 65.43) controlPoint2: CGPointMake(14.66, 65.42)];
    [bezierPath addCurveToPoint: CGPointMake(8.96, 39.01) controlPoint1: CGPointMake(3.26, 54) controlPoint2: CGPointMake(3.26, 44.73)];
    [bezierPath addLineToPoint: CGPointMake(14.69, 33.28)];
    [bezierPath addLineToPoint: CGPointMake(33.29, 14.63)];
    [bezierPath addCurveToPoint: CGPointMake(45.31, 14.65) controlPoint1: CGPointMake(36.61, 11.3) controlPoint2: CGPointMake(41.98, 11.31)];
    [bezierPath addCurveToPoint: CGPointMake(45.34, 26.74) controlPoint1: CGPointMake(48.65, 18) controlPoint2: CGPointMake(48.67, 23.4)];
    [bezierPath addLineToPoint: CGPointMake(25.27, 46.85)];
    [bezierPath addCurveToPoint: CGPointMake(21.8, 46.85) controlPoint1: CGPointMake(24.31, 47.82) controlPoint2: CGPointMake(22.76, 47.82)];
    [bezierPath addCurveToPoint: CGPointMake(21.8, 43.34) controlPoint1: CGPointMake(20.84, 45.89) controlPoint2: CGPointMake(20.84, 44.31)];
    [bezierPath addLineToPoint: CGPointMake(41.87, 23.23)];
    [bezierPath addCurveToPoint: CGPointMake(41.85, 18.17) controlPoint1: CGPointMake(43.27, 21.82) controlPoint2: CGPointMake(43.25, 19.58)];
    [bezierPath addCurveToPoint: CGPointMake(36.76, 18.14) controlPoint1: CGPointMake(40.43, 16.75) controlPoint2: CGPointMake(38.17, 16.74)];
    [bezierPath addLineToPoint: CGPointMake(18.15, 36.79)];
    [bezierPath addLineToPoint: CGPointMake(12.43, 42.53)];
    [bezierPath addCurveToPoint: CGPointMake(12.43, 56.2) controlPoint1: CGPointMake(8.66, 46.31) controlPoint2: CGPointMake(8.66, 52.43)];
    [bezierPath addCurveToPoint: CGPointMake(26.12, 56.21) controlPoint1: CGPointMake(16.21, 59.99) controlPoint2: CGPointMake(22.35, 59.99)];
    [bezierPath addLineToPoint: CGPointMake(44.7, 37.58)];
    [bezierPath addLineToPoint: CGPointMake(50.43, 31.85)];
    [bezierPath addCurveToPoint: CGPointMake(50.42, 9.57) controlPoint1: CGPointMake(56.57, 25.69) controlPoint2: CGPointMake(56.57, 15.73)];
    [bezierPath addCurveToPoint: CGPointMake(28.16, 9.57) controlPoint1: CGPointMake(44.28, 3.42) controlPoint2: CGPointMake(34.3, 3.42)];
    [bezierPath addLineToPoint: CGPointMake(8.14, 29.63)];
    [bezierPath addCurveToPoint: CGPointMake(4.68, 29.63) controlPoint1: CGPointMake(7.18, 30.59) controlPoint2: CGPointMake(5.63, 30.59)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x643_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(48, 36)];
    [bezierPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(48, 27.16) controlPoint2: CGPointMake(40.84, 20)];
    [bezierPath addCurveToPoint: CGPointMake(16, 36) controlPoint1: CGPointMake(23.16, 20) controlPoint2: CGPointMake(16, 27.16)];
    [bezierPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(16, 44.84) controlPoint2: CGPointMake(23.16, 52)];
    [bezierPath addCurveToPoint: CGPointMake(48, 36) controlPoint1: CGPointMake(40.84, 52) controlPoint2: CGPointMake(48, 44.84)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(52, 36)];
    [bezierPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(52, 47.05) controlPoint2: CGPointMake(43.05, 56)];
    [bezierPath addCurveToPoint: CGPointMake(12, 36) controlPoint1: CGPointMake(20.95, 56) controlPoint2: CGPointMake(12, 47.05)];
    [bezierPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(12, 24.95) controlPoint2: CGPointMake(20.95, 16)];
    [bezierPath addCurveToPoint: CGPointMake(52, 36) controlPoint1: CGPointMake(43.05, 16) controlPoint2: CGPointMake(52, 24.95)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 28)];
    [bezierPath addCurveToPoint: CGPointMake(24, 36) controlPoint1: CGPointMake(27.58, 28) controlPoint2: CGPointMake(24, 31.58)];
    [bezierPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(24, 40.42) controlPoint2: CGPointMake(27.58, 44)];
    [bezierPath addCurveToPoint: CGPointMake(40, 36) controlPoint1: CGPointMake(36.42, 44) controlPoint2: CGPointMake(40, 40.42)];
    [bezierPath addCurveToPoint: CGPointMake(32, 28) controlPoint1: CGPointMake(40, 31.58) controlPoint2: CGPointMake(36.42, 28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 24)];
    [bezierPath addCurveToPoint: CGPointMake(44, 36) controlPoint1: CGPointMake(38.63, 24) controlPoint2: CGPointMake(44, 29.37)];
    [bezierPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(44, 42.63) controlPoint2: CGPointMake(38.63, 48)];
    [bezierPath addCurveToPoint: CGPointMake(20, 36) controlPoint1: CGPointMake(25.37, 48) controlPoint2: CGPointMake(20, 42.63)];
    [bezierPath addCurveToPoint: CGPointMake(32, 24) controlPoint1: CGPointMake(20, 29.37) controlPoint2: CGPointMake(25.37, 24)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(23.07, 4.78)];
    [bezierPath addLineToPoint: CGPointMake(21.52, 12)];
    [bezierPath addLineToPoint: CGPointMake(7.98, 12)];
    [bezierPath addCurveToPoint: CGPointMake(4, 16.02) controlPoint1: CGPointMake(5.79, 12) controlPoint2: CGPointMake(4, 13.8)];
    [bezierPath addLineToPoint: CGPointMake(4, 55.98)];
    [bezierPath addCurveToPoint: CGPointMake(7.98, 60) controlPoint1: CGPointMake(4, 58.21) controlPoint2: CGPointMake(5.78, 60)];
    [bezierPath addLineToPoint: CGPointMake(56.02, 60)];
    [bezierPath addCurveToPoint: CGPointMake(60, 55.98) controlPoint1: CGPointMake(58.21, 60) controlPoint2: CGPointMake(60, 58.2)];
    [bezierPath addLineToPoint: CGPointMake(60, 16.02)];
    [bezierPath addCurveToPoint: CGPointMake(56.02, 12) controlPoint1: CGPointMake(60, 13.79) controlPoint2: CGPointMake(58.22, 12)];
    [bezierPath addLineToPoint: CGPointMake(42.48, 12)];
    [bezierPath addLineToPoint: CGPointMake(40.93, 4.78)];
    [bezierPath addCurveToPoint: CGPointMake(40.04, 4) controlPoint1: CGPointMake(40.86, 4.42) controlPoint2: CGPointMake(40.34, 4)];
    [bezierPath addLineToPoint: CGPointMake(23.96, 4)];
    [bezierPath addCurveToPoint: CGPointMake(23.07, 4.78) controlPoint1: CGPointMake(23.69, 4) controlPoint2: CGPointMake(23.14, 4.45)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(19.16, 3.94)];
    [bezierPath addCurveToPoint: CGPointMake(23.96, 0) controlPoint1: CGPointMake(19.62, 1.76) controlPoint2: CGPointMake(21.8, 0)];
    [bezierPath addLineToPoint: CGPointMake(40.04, 0)];
    [bezierPath addCurveToPoint: CGPointMake(44.84, 3.94) controlPoint1: CGPointMake(42.23, 0) controlPoint2: CGPointMake(44.37, 1.74)];
    [bezierPath addLineToPoint: CGPointMake(45.71, 8)];
    [bezierPath addLineToPoint: CGPointMake(56.02, 8)];
    [bezierPath addCurveToPoint: CGPointMake(64, 16.02) controlPoint1: CGPointMake(60.43, 8) controlPoint2: CGPointMake(64, 11.59)];
    [bezierPath addLineToPoint: CGPointMake(64, 55.98)];
    [bezierPath addCurveToPoint: CGPointMake(56.02, 64) controlPoint1: CGPointMake(64, 60.41) controlPoint2: CGPointMake(60.42, 64)];
    [bezierPath addLineToPoint: CGPointMake(7.98, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 55.98) controlPoint1: CGPointMake(3.57, 64) controlPoint2: CGPointMake(0, 60.41)];
    [bezierPath addLineToPoint: CGPointMake(0, 16.02)];
    [bezierPath addCurveToPoint: CGPointMake(7.98, 8) controlPoint1: CGPointMake(0, 11.59) controlPoint2: CGPointMake(3.58, 8)];
    [bezierPath addLineToPoint: CGPointMake(18.29, 8)];
    [bezierPath addLineToPoint: CGPointMake(19.16, 3.94)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x645_32ptWithColor: (UIColor*)color
{

    //// Bezier 4 Drawing
    UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
    [bezier4Path moveToPoint: CGPointMake(42, 16)];
    [bezier4Path addCurveToPoint: CGPointMake(36, 22) controlPoint1: CGPointMake(38.69, 16) controlPoint2: CGPointMake(36, 18.69)];
    [bezier4Path addCurveToPoint: CGPointMake(42, 28) controlPoint1: CGPointMake(36, 25.31) controlPoint2: CGPointMake(38.69, 28)];
    [bezier4Path addCurveToPoint: CGPointMake(48, 22) controlPoint1: CGPointMake(45.31, 28) controlPoint2: CGPointMake(48, 25.31)];
    [bezier4Path addCurveToPoint: CGPointMake(42, 16) controlPoint1: CGPointMake(48, 18.69) controlPoint2: CGPointMake(45.31, 16)];
    [bezier4Path closePath];
    [bezier4Path moveToPoint: CGPointMake(52, 22)];
    [bezier4Path addCurveToPoint: CGPointMake(42, 32) controlPoint1: CGPointMake(52, 27.52) controlPoint2: CGPointMake(47.52, 32)];
    [bezier4Path addCurveToPoint: CGPointMake(32, 22) controlPoint1: CGPointMake(36.48, 32) controlPoint2: CGPointMake(32, 27.52)];
    [bezier4Path addCurveToPoint: CGPointMake(42, 12) controlPoint1: CGPointMake(32, 16.48) controlPoint2: CGPointMake(36.48, 12)];
    [bezier4Path addCurveToPoint: CGPointMake(52, 22) controlPoint1: CGPointMake(47.52, 12) controlPoint2: CGPointMake(52, 16.48)];
    [bezier4Path closePath];
    [bezier4Path moveToPoint: CGPointMake(4.16, 4)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 44.21) controlPoint1: CGPointMake(4, 4) controlPoint2: CGPointMake(4, 27.65)];
    [bezier4Path addCurveToPoint: CGPointMake(23.94, 36.04) controlPoint1: CGPointMake(8.67, 42.3) controlPoint2: CGPointMake(23.94, 36.04)];
    [bezier4Path addCurveToPoint: CGPointMake(60, 49.95) controlPoint1: CGPointMake(23.94, 36.04) controlPoint2: CGPointMake(52.02, 46.87)];
    [bezier4Path addCurveToPoint: CGPointMake(60, 4) controlPoint1: CGPointMake(60, 33.84) controlPoint2: CGPointMake(60, 4)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 4) controlPoint1: CGPointMake(60, 3.99) controlPoint2: CGPointMake(4, 4)];
    [bezier4Path addLineToPoint: CGPointMake(4.16, 4)];
    [bezier4Path closePath];
    [bezier4Path moveToPoint: CGPointMake(23.94, 40.45)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 48.55) controlPoint1: CGPointMake(23.94, 40.45) controlPoint2: CGPointMake(8.67, 46.66)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 57.45) controlPoint1: CGPointMake(4, 52.29) controlPoint2: CGPointMake(4, 55.42)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 60) controlPoint1: CGPointMake(4, 59.07) controlPoint2: CGPointMake(4, 60)];
    [bezier4Path addCurveToPoint: CGPointMake(60, 60) controlPoint1: CGPointMake(4, 60.01) controlPoint2: CGPointMake(60, 60)];
    [bezier4Path addCurveToPoint: CGPointMake(60, 54.18) controlPoint1: CGPointMake(60, 60) controlPoint2: CGPointMake(60, 57.76)];
    [bezier4Path addCurveToPoint: CGPointMake(23.94, 40.45) controlPoint1: CGPointMake(52.02, 51.14) controlPoint2: CGPointMake(23.94, 40.45)];
    [bezier4Path closePath];
    [bezier4Path moveToPoint: CGPointMake(64, 4)];
    [bezier4Path addLineToPoint: CGPointMake(64, 60)];
    [bezier4Path addCurveToPoint: CGPointMake(60, 64) controlPoint1: CGPointMake(64, 62.21) controlPoint2: CGPointMake(62.22, 64)];
    [bezier4Path addLineToPoint: CGPointMake(4, 64)];
    [bezier4Path addCurveToPoint: CGPointMake(0, 60) controlPoint1: CGPointMake(1.79, 64) controlPoint2: CGPointMake(0, 62.22)];
    [bezier4Path addLineToPoint: CGPointMake(0, 4)];
    [bezier4Path addCurveToPoint: CGPointMake(3.08, 0.11) controlPoint1: CGPointMake(0, 2.11) controlPoint2: CGPointMake(1.31, 0.52)];
    [bezier4Path addCurveToPoint: CGPointMake(4, 0) controlPoint1: CGPointMake(3.38, 0.04) controlPoint2: CGPointMake(3.69, 0)];
    [bezier4Path addLineToPoint: CGPointMake(60, 0)];
    [bezier4Path addCurveToPoint: CGPointMake(64, 4) controlPoint1: CGPointMake(62.21, 0) controlPoint2: CGPointMake(64, 1.78)];
    [bezier4Path closePath];
    [color setFill];
    [bezier4Path fill];
}

+ (void)drawIcon_0x644_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 60)];
    [bezierPath addCurveToPoint: CGPointMake(60, 32) controlPoint1: CGPointMake(47.46, 60) controlPoint2: CGPointMake(60, 47.46)];
    [bezierPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(60, 16.54) controlPoint2: CGPointMake(47.46, 4)];
    [bezierPath addCurveToPoint: CGPointMake(4, 32) controlPoint1: CGPointMake(16.54, 4) controlPoint2: CGPointMake(4, 16.54)];
    [bezierPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(4, 47.46) controlPoint2: CGPointMake(16.54, 60)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 52)];
    [bezierPath addCurveToPoint: CGPointMake(52, 32) controlPoint1: CGPointMake(43.05, 52) controlPoint2: CGPointMake(52, 43.05)];
    [bezierPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(52, 20.95) controlPoint2: CGPointMake(43.05, 12)];
    [bezierPath addCurveToPoint: CGPointMake(12, 32) controlPoint1: CGPointMake(20.95, 12) controlPoint2: CGPointMake(12, 20.95)];
    [bezierPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(12, 43.05) controlPoint2: CGPointMake(20.95, 52)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 56)];
    [bezierPath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 56) controlPoint2: CGPointMake(8, 45.25)];
    [bezierPath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(8, 18.75) controlPoint2: CGPointMake(18.75, 8)];
    [bezierPath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(45.25, 8) controlPoint2: CGPointMake(56, 18.75)];
    [bezierPath addCurveToPoint: CGPointMake(32, 56) controlPoint1: CGPointMake(56, 45.25) controlPoint2: CGPointMake(45.25, 56)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x719_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 8)];
    [bezierPath addLineToPoint: CGPointMake(36, 8)];
    [bezierPath addLineToPoint: CGPointMake(36, 56)];
    [bezierPath addLineToPoint: CGPointMake(32, 56)];
    [bezierPath addLineToPoint: CGPointMake(32, 8)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(48, 36)];
    [bezierPath addLineToPoint: CGPointMake(48, 56)];
    [bezierPath addLineToPoint: CGPointMake(44, 56)];
    [bezierPath addLineToPoint: CGPointMake(44, 8)];
    [bezierPath addLineToPoint: CGPointMake(46, 8)];
    [bezierPath addLineToPoint: CGPointMake(64, 8)];
    [bezierPath addLineToPoint: CGPointMake(64, 12)];
    [bezierPath addLineToPoint: CGPointMake(48, 12)];
    [bezierPath addLineToPoint: CGPointMake(48, 32)];
    [bezierPath addLineToPoint: CGPointMake(60, 32)];
    [bezierPath addLineToPoint: CGPointMake(60, 36)];
    [bezierPath addLineToPoint: CGPointMake(48, 36)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(24, 32)];
    [bezierPath addLineToPoint: CGPointMake(24, 44.79)];
    [bezierPath addCurveToPoint: CGPointMake(12, 56.8) controlPoint1: CGPointMake(24, 51.42) controlPoint2: CGPointMake(18.61, 56.8)];
    [bezierPath addCurveToPoint: CGPointMake(0, 44.79) controlPoint1: CGPointMake(5.37, 56.8) controlPoint2: CGPointMake(0, 51.4)];
    [bezierPath addLineToPoint: CGPointMake(0, 19.21)];
    [bezierPath addCurveToPoint: CGPointMake(12, 7.2) controlPoint1: CGPointMake(0, 12.58) controlPoint2: CGPointMake(5.39, 7.2)];
    [bezierPath addCurveToPoint: CGPointMake(24, 19.21) controlPoint1: CGPointMake(18.63, 7.2) controlPoint2: CGPointMake(24, 12.6)];
    [bezierPath addLineToPoint: CGPointMake(24, 20)];
    [bezierPath addLineToPoint: CGPointMake(20, 20)];
    [bezierPath addLineToPoint: CGPointMake(20, 19.21)];
    [bezierPath addCurveToPoint: CGPointMake(12, 11.2) controlPoint1: CGPointMake(20, 14.8) controlPoint2: CGPointMake(16.41, 11.2)];
    [bezierPath addCurveToPoint: CGPointMake(4, 19.21) controlPoint1: CGPointMake(7.59, 11.2) controlPoint2: CGPointMake(4, 14.79)];
    [bezierPath addLineToPoint: CGPointMake(4, 44.79)];
    [bezierPath addCurveToPoint: CGPointMake(12, 52.8) controlPoint1: CGPointMake(4, 49.2) controlPoint2: CGPointMake(7.59, 52.8)];
    [bezierPath addCurveToPoint: CGPointMake(20, 44.79) controlPoint1: CGPointMake(16.41, 52.8) controlPoint2: CGPointMake(20, 49.21)];
    [bezierPath addLineToPoint: CGPointMake(20, 36)];
    [bezierPath addLineToPoint: CGPointMake(12, 36)];
    [bezierPath addLineToPoint: CGPointMake(12, 32)];
    [bezierPath addLineToPoint: CGPointMake(24, 32)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x648_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 4)];
    [bezierPath addCurveToPoint: CGPointMake(12, 24) controlPoint1: CGPointMake(20.95, 4) controlPoint2: CGPointMake(12, 12.95)];
    [bezierPath addCurveToPoint: CGPointMake(23.04, 50.4) controlPoint1: CGPointMake(12, 33.41) controlPoint2: CGPointMake(16.11, 42.31)];
    [bezierPath addCurveToPoint: CGPointMake(30.81, 58.05) controlPoint1: CGPointMake(25.51, 53.28) controlPoint2: CGPointMake(28.16, 55.84)];
    [bezierPath addCurveToPoint: CGPointMake(34.22, 60.67) controlPoint1: CGPointMake(32.38, 59.36) controlPoint2: CGPointMake(33.58, 60.25)];
    [bezierPath addLineToPoint: CGPointMake(29.78, 60.67)];
    [bezierPath addCurveToPoint: CGPointMake(33.19, 58.05) controlPoint1: CGPointMake(30.42, 60.25) controlPoint2: CGPointMake(31.62, 59.36)];
    [bezierPath addCurveToPoint: CGPointMake(40.96, 50.4) controlPoint1: CGPointMake(35.84, 55.84) controlPoint2: CGPointMake(38.49, 53.28)];
    [bezierPath addCurveToPoint: CGPointMake(52, 24) controlPoint1: CGPointMake(47.89, 42.31) controlPoint2: CGPointMake(52, 33.41)];
    [bezierPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(52, 12.95) controlPoint2: CGPointMake(43.05, 4)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(8, 24) controlPoint1: CGPointMake(32, 64) controlPoint2: CGPointMake(8, 48)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(8, 10.75) controlPoint2: CGPointMake(18.75, 0)];
    [bezierPath addCurveToPoint: CGPointMake(56, 24) controlPoint1: CGPointMake(45.25, 0) controlPoint2: CGPointMake(56, 10.75)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(56, 48) controlPoint2: CGPointMake(32, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(40, 24)];
    [bezierPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(40, 19.58) controlPoint2: CGPointMake(36.42, 16)];
    [bezierPath addCurveToPoint: CGPointMake(24, 24) controlPoint1: CGPointMake(27.58, 16) controlPoint2: CGPointMake(24, 19.58)];
    [bezierPath addCurveToPoint: CGPointMake(32, 32) controlPoint1: CGPointMake(24, 28.42) controlPoint2: CGPointMake(27.58, 32)];
    [bezierPath addCurveToPoint: CGPointMake(40, 24) controlPoint1: CGPointMake(36.42, 32) controlPoint2: CGPointMake(40, 28.42)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(20, 24)];
    [bezierPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(20, 17.37) controlPoint2: CGPointMake(25.37, 12)];
    [bezierPath addCurveToPoint: CGPointMake(44, 24) controlPoint1: CGPointMake(38.63, 12) controlPoint2: CGPointMake(44, 17.37)];
    [bezierPath addCurveToPoint: CGPointMake(32, 36) controlPoint1: CGPointMake(44, 30.63) controlPoint2: CGPointMake(38.63, 36)];
    [bezierPath addCurveToPoint: CGPointMake(20, 24) controlPoint1: CGPointMake(25.37, 36) controlPoint2: CGPointMake(20, 30.63)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x637_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(51.55, 8.64)];
    [bezierPath addCurveToPoint: CGPointMake(55.36, 8.64) controlPoint1: CGPointMake(52.6, 7.59) controlPoint2: CGPointMake(54.31, 7.59)];
    [bezierPath addCurveToPoint: CGPointMake(55.36, 12.45) controlPoint1: CGPointMake(56.41, 9.69) controlPoint2: CGPointMake(56.41, 11.4)];
    [bezierPath addLineToPoint: CGPointMake(46.16, 21.64)];
    [bezierPath addCurveToPoint: CGPointMake(42.36, 21.64) controlPoint1: CGPointMake(45.11, 22.7) controlPoint2: CGPointMake(43.41, 22.7)];
    [bezierPath addCurveToPoint: CGPointMake(42.36, 17.84) controlPoint1: CGPointMake(41.31, 20.59) controlPoint2: CGPointMake(41.31, 18.89)];
    [bezierPath addLineToPoint: CGPointMake(51.55, 8.64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(12.45, 55.36)];
    [bezierPath addCurveToPoint: CGPointMake(8.64, 55.36) controlPoint1: CGPointMake(11.4, 56.41) controlPoint2: CGPointMake(9.69, 56.41)];
    [bezierPath addCurveToPoint: CGPointMake(8.64, 51.55) controlPoint1: CGPointMake(7.59, 54.31) controlPoint2: CGPointMake(7.59, 52.6)];
    [bezierPath addLineToPoint: CGPointMake(17.84, 42.36)];
    [bezierPath addCurveToPoint: CGPointMake(21.64, 42.36) controlPoint1: CGPointMake(18.89, 41.3) controlPoint2: CGPointMake(20.59, 41.3)];
    [bezierPath addCurveToPoint: CGPointMake(21.64, 46.16) controlPoint1: CGPointMake(22.69, 43.41) controlPoint2: CGPointMake(22.69, 45.11)];
    [bezierPath addLineToPoint: CGPointMake(12.45, 55.36)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(62, 37.25)];
    [bezierPath addCurveToPoint: CGPointMake(63.91, 40.55) controlPoint1: CGPointMake(63.44, 37.64) controlPoint2: CGPointMake(64.29, 39.11)];
    [bezierPath addCurveToPoint: CGPointMake(60.61, 42.45) controlPoint1: CGPointMake(63.52, 41.99) controlPoint2: CGPointMake(62.05, 42.84)];
    [bezierPath addLineToPoint: CGPointMake(48.05, 39.09)];
    [bezierPath addCurveToPoint: CGPointMake(46.15, 35.79) controlPoint1: CGPointMake(46.61, 38.7) controlPoint2: CGPointMake(45.76, 37.23)];
    [bezierPath addCurveToPoint: CGPointMake(49.44, 33.89) controlPoint1: CGPointMake(46.53, 34.35) controlPoint2: CGPointMake(48.01, 33.5)];
    [bezierPath addLineToPoint: CGPointMake(62, 37.25)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(2, 26.75)];
    [bezierPath addCurveToPoint: CGPointMake(0.09, 23.45) controlPoint1: CGPointMake(0.56, 26.36) controlPoint2: CGPointMake(-0.29, 24.89)];
    [bezierPath addCurveToPoint: CGPointMake(3.39, 21.55) controlPoint1: CGPointMake(0.48, 22.01) controlPoint2: CGPointMake(1.95, 21.16)];
    [bezierPath addLineToPoint: CGPointMake(15.95, 24.91)];
    [bezierPath addCurveToPoint: CGPointMake(17.85, 28.21) controlPoint1: CGPointMake(17.39, 25.3) controlPoint2: CGPointMake(18.24, 26.77)];
    [bezierPath addCurveToPoint: CGPointMake(14.56, 30.11) controlPoint1: CGPointMake(17.47, 29.65) controlPoint2: CGPointMake(15.99, 30.5)];
    [bezierPath addLineToPoint: CGPointMake(2, 26.75)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(42.45, 60.61)];
    [bezierPath addCurveToPoint: CGPointMake(40.55, 63.91) controlPoint1: CGPointMake(42.84, 62.05) controlPoint2: CGPointMake(41.99, 63.52)];
    [bezierPath addCurveToPoint: CGPointMake(37.25, 62) controlPoint1: CGPointMake(39.11, 64.29) controlPoint2: CGPointMake(37.64, 63.44)];
    [bezierPath addLineToPoint: CGPointMake(33.89, 49.44)];
    [bezierPath addCurveToPoint: CGPointMake(35.79, 46.15) controlPoint1: CGPointMake(33.5, 48.01) controlPoint2: CGPointMake(34.35, 46.53)];
    [bezierPath addCurveToPoint: CGPointMake(39.09, 48.05) controlPoint1: CGPointMake(37.23, 45.76) controlPoint2: CGPointMake(38.7, 46.61)];
    [bezierPath addLineToPoint: CGPointMake(42.45, 60.61)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(21.55, 3.39)];
    [bezierPath addCurveToPoint: CGPointMake(23.45, 0.09) controlPoint1: CGPointMake(21.16, 1.95) controlPoint2: CGPointMake(22.01, 0.48)];
    [bezierPath addCurveToPoint: CGPointMake(26.75, 2) controlPoint1: CGPointMake(24.89, -0.29) controlPoint2: CGPointMake(26.36, 0.56)];
    [bezierPath addLineToPoint: CGPointMake(30.11, 14.56)];
    [bezierPath addCurveToPoint: CGPointMake(28.21, 17.85) controlPoint1: CGPointMake(30.5, 15.99) controlPoint2: CGPointMake(29.65, 17.47)];
    [bezierPath addCurveToPoint: CGPointMake(24.91, 15.95) controlPoint1: CGPointMake(26.77, 18.24) controlPoint2: CGPointMake(25.3, 17.39)];
    [bezierPath addLineToPoint: CGPointMake(21.55, 3.39)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x735_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(12, 28)];
    [bezierPath addLineToPoint: CGPointMake(46, 28)];
    [bezierPath addCurveToPoint: CGPointMake(46.73, 35.93) controlPoint1: CGPointMake(50.87, 28) controlPoint2: CGPointMake(51.51, 35.05)];
    [bezierPath addLineToPoint: CGPointMake(12, 42.33)];
    [bezierPath addLineToPoint: CGPointMake(12, 54.06)];
    [bezierPath addCurveToPoint: CGPointMake(14.37, 55.52) controlPoint1: CGPointMake(12, 56.18) controlPoint2: CGPointMake(12.5, 56.48)];
    [bezierPath addLineToPoint: CGPointMake(58.79, 32.66)];
    [bezierPath addCurveToPoint: CGPointMake(58.79, 31.33) controlPoint1: CGPointMake(60.41, 31.82) controlPoint2: CGPointMake(60.4, 32.16)];
    [bezierPath addLineToPoint: CGPointMake(14.37, 8.47)];
    [bezierPath addCurveToPoint: CGPointMake(12, 9.93) controlPoint1: CGPointMake(12.53, 7.52) controlPoint2: CGPointMake(12, 7.84)];
    [bezierPath addLineToPoint: CGPointMake(12, 28)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(46, 32)];
    [bezierPath addLineToPoint: CGPointMake(8, 32)];
    [bezierPath addLineToPoint: CGPointMake(8, 9.93)];
    [bezierPath addCurveToPoint: CGPointMake(16.2, 4.91) controlPoint1: CGPointMake(8, 4.83) controlPoint2: CGPointMake(11.71, 2.6)];
    [bezierPath addLineToPoint: CGPointMake(60.62, 27.77)];
    [bezierPath addCurveToPoint: CGPointMake(60.62, 36.21) controlPoint1: CGPointMake(65.15, 30.11) controlPoint2: CGPointMake(65.11, 33.9)];
    [bezierPath addLineToPoint: CGPointMake(16.2, 59.08)];
    [bezierPath addCurveToPoint: CGPointMake(8, 54.06) controlPoint1: CGPointMake(11.67, 61.4) controlPoint2: CGPointMake(8, 59.19)];
    [bezierPath addLineToPoint: CGPointMake(8, 39)];
    [bezierPath addLineToPoint: CGPointMake(24.29, 36)];
    [bezierPath addLineToPoint: CGPointMake(46, 32)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x659_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(51.26, 52.18)];
    [bezierPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(46.16, 57.14) controlPoint2: CGPointMake(39.32, 60)];
    [bezierPath addCurveToPoint: CGPointMake(12.74, 52.18) controlPoint1: CGPointMake(24.68, 60) controlPoint2: CGPointMake(17.84, 57.14)];
    [bezierPath addLineToPoint: CGPointMake(15.18, 49.7)];
    [bezierPath addCurveToPoint: CGPointMake(32, 56.5) controlPoint1: CGPointMake(19.63, 54.01) controlPoint2: CGPointMake(25.62, 56.5)];
    [bezierPath addCurveToPoint: CGPointMake(48.82, 49.7) controlPoint1: CGPointMake(38.38, 56.5) controlPoint2: CGPointMake(44.37, 54.01)];
    [bezierPath addLineToPoint: CGPointMake(51.26, 52.18)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(50.19, 45.43)];
    [bezierPath addCurveToPoint: CGPointMake(47.32, 45.52) controlPoint1: CGPointMake(49.38, 44.62) controlPoint2: CGPointMake(48.07, 44.66)];
    [bezierPath addCurveToPoint: CGPointMake(32, 52.5) controlPoint1: CGPointMake(43.5, 49.92) controlPoint2: CGPointMake(37.96, 52.5)];
    [bezierPath addCurveToPoint: CGPointMake(16.68, 45.52) controlPoint1: CGPointMake(26.04, 52.5) controlPoint2: CGPointMake(20.5, 49.92)];
    [bezierPath addCurveToPoint: CGPointMake(13.81, 45.43) controlPoint1: CGPointMake(15.93, 44.66) controlPoint2: CGPointMake(14.62, 44.62)];
    [bezierPath addLineToPoint: CGPointMake(8.58, 50.74)];
    [bezierPath addCurveToPoint: CGPointMake(8.51, 53.5) controlPoint1: CGPointMake(7.83, 51.5) controlPoint2: CGPointMake(7.8, 52.71)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(14.46, 60.14) controlPoint2: CGPointMake(22.92, 64)];
    [bezierPath addCurveToPoint: CGPointMake(55.49, 53.5) controlPoint1: CGPointMake(41.08, 64) controlPoint2: CGPointMake(49.54, 60.14)];
    [bezierPath addCurveToPoint: CGPointMake(55.42, 50.74) controlPoint1: CGPointMake(56.2, 52.71) controlPoint2: CGPointMake(56.17, 51.5)];
    [bezierPath addLineToPoint: CGPointMake(50.19, 45.43)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 49)];
    [bezierPath addCurveToPoint: CGPointMake(48.75, 32.25) controlPoint1: CGPointMake(41.24, 49) controlPoint2: CGPointMake(48.75, 41.49)];
    [bezierPath addLineToPoint: CGPointMake(48.75, 16.75)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(48.75, 7.51) controlPoint2: CGPointMake(41.24, 0)];
    [bezierPath addCurveToPoint: CGPointMake(15.25, 16.75) controlPoint1: CGPointMake(22.76, 0) controlPoint2: CGPointMake(15.25, 7.51)];
    [bezierPath addLineToPoint: CGPointMake(15.25, 32.25)];
    [bezierPath addCurveToPoint: CGPointMake(32, 49) controlPoint1: CGPointMake(15.25, 41.49) controlPoint2: CGPointMake(22.76, 49)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 45)];
    [bezierPath addCurveToPoint: CGPointMake(19.19, 32.25) controlPoint1: CGPointMake(24.92, 45) controlPoint2: CGPointMake(19.19, 39.27)];
    [bezierPath addLineToPoint: CGPointMake(19.19, 16.75)];
    [bezierPath addCurveToPoint: CGPointMake(32, 4) controlPoint1: CGPointMake(19.19, 9.73) controlPoint2: CGPointMake(24.92, 4)];
    [bezierPath addCurveToPoint: CGPointMake(44.81, 16.75) controlPoint1: CGPointMake(39.08, 4) controlPoint2: CGPointMake(44.81, 9.73)];
    [bezierPath addLineToPoint: CGPointMake(44.81, 32.25)];
    [bezierPath addCurveToPoint: CGPointMake(32, 45) controlPoint1: CGPointMake(44.81, 39.27) controlPoint2: CGPointMake(39.08, 45)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x679_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(29.59, 63.97)];
    [bezierPath addCurveToPoint: CGPointMake(26.49, 61.73) controlPoint1: CGPointMake(28.1, 64.19) controlPoint2: CGPointMake(26.72, 63.19)];
    [bezierPath addCurveToPoint: CGPointMake(28.76, 58.68) controlPoint1: CGPointMake(26.27, 60.27) controlPoint2: CGPointMake(27.28, 58.91)];
    [bezierPath addCurveToPoint: CGPointMake(52.56, 50.43) controlPoint1: CGPointMake(35.21, 57.7) controlPoint2: CGPointMake(45.62, 54.09)];
    [bezierPath addCurveToPoint: CGPointMake(57.8, 47.54) controlPoint1: CGPointMake(52.71, 50.36) controlPoint2: CGPointMake(57.49, 47.88)];
    [bezierPath addCurveToPoint: CGPointMake(47.12, 48.14) controlPoint1: CGPointMake(57.9, 45.34) controlPoint2: CGPointMake(53.98, 46.58)];
    [bezierPath addCurveToPoint: CGPointMake(34.93, 51.12) controlPoint1: CGPointMake(43.1, 49.06) controlPoint2: CGPointMake(38.95, 50.04)];
    [bezierPath addCurveToPoint: CGPointMake(32.53, 51.75) controlPoint1: CGPointMake(33.97, 51.37) controlPoint2: CGPointMake(33.23, 51.57)];
    [bezierPath addCurveToPoint: CGPointMake(11.38, 55.58) controlPoint1: CGPointMake(21.83, 54.57) controlPoint2: CGPointMake(16.17, 55.61)];
    [bezierPath addCurveToPoint: CGPointMake(0.62, 45.26) controlPoint1: CGPointMake(3.63, 55.52) controlPoint2: CGPointMake(-0.29, 51.88)];
    [bezierPath addCurveToPoint: CGPointMake(30.2, 33.76) controlPoint1: CGPointMake(1.4, 39.52) controlPoint2: CGPointMake(5.7, 37.83)];
    [bezierPath addCurveToPoint: CGPointMake(31.68, 33.52) controlPoint1: CGPointMake(30.66, 33.69) controlPoint2: CGPointMake(31.22, 33.59)];
    [bezierPath addCurveToPoint: CGPointMake(51.48, 29.47) controlPoint1: CGPointMake(42.6, 31.7) controlPoint2: CGPointMake(47.24, 30.76)];
    [bezierPath addCurveToPoint: CGPointMake(53.98, 28.62) controlPoint1: CGPointMake(52.35, 29.2) controlPoint2: CGPointMake(53.18, 28.92)];
    [bezierPath addCurveToPoint: CGPointMake(53.45, 25.57) controlPoint1: CGPointMake(55.61, 28.02) controlPoint2: CGPointMake(55.19, 25.6)];
    [bezierPath addCurveToPoint: CGPointMake(51.69, 25.58) controlPoint1: CGPointMake(52.9, 25.57) controlPoint2: CGPointMake(52.31, 25.57)];
    [bezierPath addCurveToPoint: CGPointMake(32.17, 27.37) controlPoint1: CGPointMake(47.37, 25.67) controlPoint2: CGPointMake(42.4, 26.14)];
    [bezierPath addCurveToPoint: CGPointMake(30.87, 27.53) controlPoint1: CGPointMake(31.77, 27.42) controlPoint2: CGPointMake(31.28, 27.48)];
    [bezierPath addCurveToPoint: CGPointMake(11.45, 29.48) controlPoint1: CGPointMake(19.3, 28.94) controlPoint2: CGPointMake(15.68, 29.31)];
    [bezierPath addCurveToPoint: CGPointMake(0, 24.89) controlPoint1: CGPointMake(2.48, 29.85) controlPoint2: CGPointMake(0, 28.86)];
    [bezierPath addCurveToPoint: CGPointMake(29.76, 11.86) controlPoint1: CGPointMake(-0, 18.94) controlPoint2: CGPointMake(5.17, 16.66)];
    [bezierPath addCurveToPoint: CGPointMake(55.12, 6.62) controlPoint1: CGPointMake(30.76, 11.67) controlPoint2: CGPointMake(53.62, 8.21)];
    [bezierPath addCurveToPoint: CGPointMake(35.97, 5.5) controlPoint1: CGPointMake(56.63, 5.03) controlPoint2: CGPointMake(36.95, 5.46)];
    [bezierPath addCurveToPoint: CGPointMake(5.35, 10.74) controlPoint1: CGPointMake(23.3, 6) controlPoint2: CGPointMake(11.22, 8.03)];
    [bezierPath addCurveToPoint: CGPointMake(1.73, 9.44) controlPoint1: CGPointMake(3.99, 11.37) controlPoint2: CGPointMake(2.37, 10.79)];
    [bezierPath addCurveToPoint: CGPointMake(3.05, 5.9) controlPoint1: CGPointMake(1.11, 8.11) controlPoint2: CGPointMake(1.69, 6.52)];
    [bezierPath addCurveToPoint: CGPointMake(35.75, 0.15) controlPoint1: CGPointMake(9.61, 2.87) controlPoint2: CGPointMake(22.16, 0.69)];
    [bezierPath addCurveToPoint: CGPointMake(60.52, 5.28) controlPoint1: CGPointMake(52.53, -0.52) controlPoint2: CGPointMake(59.78, 1.01)];
    [bezierPath addCurveToPoint: CGPointMake(39.96, 15.33) controlPoint1: CGPointMake(61.37, 10.17) controlPoint2: CGPointMake(58.52, 11.61)];
    [bezierPath addCurveToPoint: CGPointMake(30.82, 17.11) controlPoint1: CGPointMake(38.7, 15.58) controlPoint2: CGPointMake(31.81, 16.91)];
    [bezierPath addCurveToPoint: CGPointMake(7.86, 21.81) controlPoint1: CGPointMake(22.81, 18.67) controlPoint2: CGPointMake(11.62, 20.7)];
    [bezierPath addCurveToPoint: CGPointMake(8.43, 24.89) controlPoint1: CGPointMake(6.05, 22.34) controlPoint2: CGPointMake(6.55, 25.04)];
    [bezierPath addCurveToPoint: CGPointMake(30.21, 22.22) controlPoint1: CGPointMake(11.54, 24.64) controlPoint2: CGPointMake(21.81, 23.24)];
    [bezierPath addCurveToPoint: CGPointMake(31.51, 22.07) controlPoint1: CGPointMake(30.61, 22.18) controlPoint2: CGPointMake(31.1, 22.12)];
    [bezierPath addCurveToPoint: CGPointMake(51.57, 20.24) controlPoint1: CGPointMake(42, 20.8) controlPoint2: CGPointMake(47.03, 20.33)];
    [bezierPath addCurveToPoint: CGPointMake(63.66, 25.12) controlPoint1: CGPointMake(60.25, 20.05) controlPoint2: CGPointMake(63.27, 21.27)];
    [bezierPath addCurveToPoint: CGPointMake(53.09, 34.57) controlPoint1: CGPointMake(64.1, 29.38) controlPoint2: CGPointMake(60.95, 32.17)];
    [bezierPath addCurveToPoint: CGPointMake(32.58, 38.79) controlPoint1: CGPointMake(48.56, 35.96) controlPoint2: CGPointMake(43.87, 36.92)];
    [bezierPath addCurveToPoint: CGPointMake(31.1, 39.04) controlPoint1: CGPointMake(32.12, 38.87) controlPoint2: CGPointMake(31.57, 38.96)];
    [bezierPath addCurveToPoint: CGPointMake(12.89, 42.66) controlPoint1: CGPointMake(21.04, 40.71) controlPoint2: CGPointMake(16.85, 41.53)];
    [bezierPath addCurveToPoint: CGPointMake(6.36, 45.95) controlPoint1: CGPointMake(10.45, 43.35) controlPoint2: CGPointMake(6.64, 43.87)];
    [bezierPath addCurveToPoint: CGPointMake(11.41, 50.23) controlPoint1: CGPointMake(5.91, 49.23) controlPoint2: CGPointMake(6.99, 50.2)];
    [bezierPath addCurveToPoint: CGPointMake(31.13, 46.58) controlPoint1: CGPointMake(15.62, 50.26) controlPoint2: CGPointMake(21.13, 49.22)];
    [bezierPath addCurveToPoint: CGPointMake(33.51, 45.95) controlPoint1: CGPointMake(31.82, 46.4) controlPoint2: CGPointMake(32.55, 46.21)];
    [bezierPath addCurveToPoint: CGPointMake(57.38, 41.62) controlPoint1: CGPointMake(49.42, 41.71) controlPoint2: CGPointMake(53.11, 41.03)];
    [bezierPath addCurveToPoint: CGPointMake(63.29, 48.78) controlPoint1: CGPointMake(62.98, 42.4) controlPoint2: CGPointMake(65.29, 45.13)];
    [bezierPath addCurveToPoint: CGPointMake(55.12, 55.15) controlPoint1: CGPointMake(62.21, 50.77) controlPoint2: CGPointMake(59.63, 52.78)];
    [bezierPath addCurveToPoint: CGPointMake(29.59, 63.97) controlPoint1: CGPointMake(47.62, 59.1) controlPoint2: CGPointMake(36.64, 62.89)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x167_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(20, 13)];
    [bezierPath addCurveToPoint: CGPointMake(40.85, 0) controlPoint1: CGPointMake(23.74, 5.31) controlPoint2: CGPointMake(31.67, 0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 23) controlPoint1: CGPointMake(53.64, 0) controlPoint2: CGPointMake(64, 10.3)];
    [bezierPath addCurveToPoint: CGPointMake(40.85, 46) controlPoint1: CGPointMake(64, 35.7) controlPoint2: CGPointMake(53.64, 46)];
    [bezierPath addCurveToPoint: CGPointMake(20, 33) controlPoint1: CGPointMake(31.67, 46) controlPoint2: CGPointMake(23.74, 40.69)];
    [bezierPath addLineToPoint: CGPointMake(29.6, 33)];
    [bezierPath addCurveToPoint: CGPointMake(40.85, 38) controlPoint1: CGPointMake(32.36, 36.07) controlPoint2: CGPointMake(36.38, 38)];
    [bezierPath addCurveToPoint: CGPointMake(55.95, 23) controlPoint1: CGPointMake(49.19, 38) controlPoint2: CGPointMake(55.95, 31.28)];
    [bezierPath addCurveToPoint: CGPointMake(40.85, 8) controlPoint1: CGPointMake(55.95, 14.72) controlPoint2: CGPointMake(49.19, 8)];
    [bezierPath addCurveToPoint: CGPointMake(29.6, 13) controlPoint1: CGPointMake(36.38, 8) controlPoint2: CGPointMake(32.36, 9.93)];
    [bezierPath addLineToPoint: CGPointMake(20, 13)];
    [bezierPath addLineToPoint: CGPointMake(20, 13)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(44, 31)];
    [bezierPath addCurveToPoint: CGPointMake(23.15, 18) controlPoint1: CGPointMake(40.26, 23.31) controlPoint2: CGPointMake(32.33, 18)];
    [bezierPath addCurveToPoint: CGPointMake(0, 41) controlPoint1: CGPointMake(10.36, 18) controlPoint2: CGPointMake(0, 28.3)];
    [bezierPath addCurveToPoint: CGPointMake(23.15, 64) controlPoint1: CGPointMake(0, 53.7) controlPoint2: CGPointMake(10.36, 64)];
    [bezierPath addCurveToPoint: CGPointMake(44, 51) controlPoint1: CGPointMake(32.33, 64) controlPoint2: CGPointMake(40.26, 58.69)];
    [bezierPath addLineToPoint: CGPointMake(34.4, 51)];
    [bezierPath addCurveToPoint: CGPointMake(23.15, 56) controlPoint1: CGPointMake(31.64, 54.07) controlPoint2: CGPointMake(27.62, 56)];
    [bezierPath addCurveToPoint: CGPointMake(8.05, 41) controlPoint1: CGPointMake(14.81, 56) controlPoint2: CGPointMake(8.05, 49.28)];
    [bezierPath addCurveToPoint: CGPointMake(23.15, 26) controlPoint1: CGPointMake(8.05, 32.72) controlPoint2: CGPointMake(14.81, 26)];
    [bezierPath addCurveToPoint: CGPointMake(34.4, 31) controlPoint1: CGPointMake(27.62, 26) controlPoint2: CGPointMake(31.64, 27.93)];
    [bezierPath addLineToPoint: CGPointMake(44, 31)];
    [bezierPath addLineToPoint: CGPointMake(44, 31)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x736_32ptWithColor: (UIColor*)color
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 12)];
    [bezierPath addLineToPoint: CGPointMake(48, 12)];
    [bezierPath addLineToPoint: CGPointMake(48, 8)];
    [bezierPath addLineToPoint: CGPointMake(12, 8)];
    [bezierPath addLineToPoint: CGPointMake(12, 12)];
    [bezierPath addLineToPoint: CGPointMake(28, 12)];
    [bezierPath addLineToPoint: CGPointMake(28, 56)];
    [bezierPath addLineToPoint: CGPointMake(32, 56)];
    [bezierPath addLineToPoint: CGPointMake(32, 12)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(60, 0)];
    [bezierPath addLineToPoint: CGPointMake(64, 0)];
    [bezierPath addLineToPoint: CGPointMake(64, 64)];
    [bezierPath addLineToPoint: CGPointMake(60, 64)];
    [bezierPath addLineToPoint: CGPointMake(60, 0)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x260_32ptWithColor: (UIColor*)color
{

    //// Collection Drawing
    UIBezierPath* collectionPath = [UIBezierPath bezierPath];
    [collectionPath moveToPoint: CGPointMake(0.02, 27.98)];
    [collectionPath addCurveToPoint: CGPointMake(3.67, 24) controlPoint1: CGPointMake(-0.2, 25.78) controlPoint2: CGPointMake(1.42, 24)];
    [collectionPath addLineToPoint: CGPointMake(60.33, 24)];
    [collectionPath addCurveToPoint: CGPointMake(63.98, 27.98) controlPoint1: CGPointMake(62.57, 24) controlPoint2: CGPointMake(64.2, 25.77)];
    [collectionPath addLineToPoint: CGPointMake(60.33, 64)];
    [collectionPath addLineToPoint: CGPointMake(3.67, 64)];
    [collectionPath addLineToPoint: CGPointMake(0.02, 27.98)];
    [collectionPath closePath];
    [collectionPath moveToPoint: CGPointMake(3.67, 15)];
    [collectionPath addCurveToPoint: CGPointMake(6.71, 12) controlPoint1: CGPointMake(3.67, 13.34) controlPoint2: CGPointMake(5.01, 12)];
    [collectionPath addLineToPoint: CGPointMake(57.29, 12)];
    [collectionPath addCurveToPoint: CGPointMake(60.33, 15) controlPoint1: CGPointMake(58.97, 12) controlPoint2: CGPointMake(60.33, 13.33)];
    [collectionPath addLineToPoint: CGPointMake(60.33, 18)];
    [collectionPath addLineToPoint: CGPointMake(3.67, 18)];
    [collectionPath addLineToPoint: CGPointMake(3.67, 15)];
    [collectionPath closePath];
    [collectionPath moveToPoint: CGPointMake(7.71, 3)];
    [collectionPath addCurveToPoint: CGPointMake(10.75, 0) controlPoint1: CGPointMake(7.71, 1.34) controlPoint2: CGPointMake(9.06, 0)];
    [collectionPath addLineToPoint: CGPointMake(53.25, 0)];
    [collectionPath addCurveToPoint: CGPointMake(56.29, 3) controlPoint1: CGPointMake(54.93, 0) controlPoint2: CGPointMake(56.29, 1.33)];
    [collectionPath addLineToPoint: CGPointMake(56.29, 6)];
    [collectionPath addLineToPoint: CGPointMake(7.71, 6)];
    [collectionPath addLineToPoint: CGPointMake(7.71, 3)];
    [collectionPath closePath];
    collectionPath.usesEvenOddFillRule = YES;
    [color setFill];
    [collectionPath fill];
}

+ (void)drawIcon_0x234_32ptWithColor: (UIColor*)color
{

    //// Copy Drawing
    UIBezierPath* copyPath = [UIBezierPath bezierPath];
    [copyPath moveToPoint: CGPointMake(24, 40)];
    [copyPath addLineToPoint: CGPointMake(56, 40)];
    [copyPath addLineToPoint: CGPointMake(56, 8)];
    [copyPath addLineToPoint: CGPointMake(24, 8)];
    [copyPath addLineToPoint: CGPointMake(24, 40)];
    [copyPath closePath];
    [copyPath moveToPoint: CGPointMake(19.98, 0)];
    [copyPath addCurveToPoint: CGPointMake(16, 4.01) controlPoint1: CGPointMake(17.82, 0) controlPoint2: CGPointMake(16, 1.8)];
    [copyPath addLineToPoint: CGPointMake(16, 43.99)];
    [copyPath addCurveToPoint: CGPointMake(19.98, 48) controlPoint1: CGPointMake(16, 46.18) controlPoint2: CGPointMake(17.78, 48)];
    [copyPath addLineToPoint: CGPointMake(60.02, 48)];
    [copyPath addCurveToPoint: CGPointMake(64, 43.99) controlPoint1: CGPointMake(62.18, 48) controlPoint2: CGPointMake(64, 46.21)];
    [copyPath addLineToPoint: CGPointMake(64, 4.01)];
    [copyPath addCurveToPoint: CGPointMake(60.02, 0) controlPoint1: CGPointMake(64, 1.82) controlPoint2: CGPointMake(62.22, 0)];
    [copyPath addLineToPoint: CGPointMake(19.98, 0)];
    [copyPath closePath];
    [copyPath moveToPoint: CGPointMake(8, 16)];
    [copyPath addLineToPoint: CGPointMake(3.98, 16)];
    [copyPath addCurveToPoint: CGPointMake(0, 20.01) controlPoint1: CGPointMake(1.82, 16) controlPoint2: CGPointMake(0, 17.79)];
    [copyPath addLineToPoint: CGPointMake(0, 59.99)];
    [copyPath addCurveToPoint: CGPointMake(3.98, 64) controlPoint1: CGPointMake(0, 62.18) controlPoint2: CGPointMake(1.78, 64)];
    [copyPath addLineToPoint: CGPointMake(44.02, 64)];
    [copyPath addCurveToPoint: CGPointMake(48, 59.99) controlPoint1: CGPointMake(46.18, 64) controlPoint2: CGPointMake(48, 62.21)];
    [copyPath addLineToPoint: CGPointMake(48, 56)];
    [copyPath addLineToPoint: CGPointMake(8, 56)];
    [copyPath addLineToPoint: CGPointMake(8, 16)];
    [copyPath closePath];
    copyPath.usesEvenOddFillRule = YES;
    [color setFill];
    [copyPath fill];
}

+ (void)drawIcon_0x261_32ptWithColor: (UIColor*)color
{

    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(55.9, 27.97)];
    [bezier3Path addCurveToPoint: CGPointMake(50.33, 44.73) controlPoint1: CGPointMake(55.9, 34.26) controlPoint2: CGPointMake(53.83, 40.06)];
    [bezier3Path addLineToPoint: CGPointMake(64, 58.35)];
    [bezier3Path addLineToPoint: CGPointMake(58.35, 64)];
    [bezier3Path addLineToPoint: CGPointMake(44.69, 50.38)];
    [bezier3Path addCurveToPoint: CGPointMake(27.95, 55.95) controlPoint1: CGPointMake(40.02, 53.87) controlPoint2: CGPointMake(34.23, 55.95)];
    [bezier3Path addCurveToPoint: CGPointMake(0, 27.97) controlPoint1: CGPointMake(12.51, 55.95) controlPoint2: CGPointMake(0, 43.42)];
    [bezier3Path addCurveToPoint: CGPointMake(27.95, 0) controlPoint1: CGPointMake(0, 12.52) controlPoint2: CGPointMake(12.51, 0)];
    [bezier3Path addCurveToPoint: CGPointMake(55.9, 27.97) controlPoint1: CGPointMake(43.38, 0) controlPoint2: CGPointMake(55.9, 12.52)];
    [bezier3Path closePath];
    [bezier3Path moveToPoint: CGPointMake(28, 48)];
    [bezier3Path addCurveToPoint: CGPointMake(48, 28) controlPoint1: CGPointMake(39.05, 48) controlPoint2: CGPointMake(48, 39.05)];
    [bezier3Path addCurveToPoint: CGPointMake(28, 8) controlPoint1: CGPointMake(48, 16.95) controlPoint2: CGPointMake(39.05, 8)];
    [bezier3Path addCurveToPoint: CGPointMake(8, 28) controlPoint1: CGPointMake(16.95, 8) controlPoint2: CGPointMake(8, 16.95)];
    [bezier3Path addCurveToPoint: CGPointMake(28, 48) controlPoint1: CGPointMake(8, 39.05) controlPoint2: CGPointMake(16.95, 48)];
    [bezier3Path closePath];
    [bezier3Path moveToPoint: CGPointMake(28, 36)];
    [bezier3Path addCurveToPoint: CGPointMake(36, 28) controlPoint1: CGPointMake(32.42, 36) controlPoint2: CGPointMake(36, 32.42)];
    [bezier3Path addCurveToPoint: CGPointMake(28, 20) controlPoint1: CGPointMake(36, 23.58) controlPoint2: CGPointMake(32.42, 20)];
    [bezier3Path addCurveToPoint: CGPointMake(20, 28) controlPoint1: CGPointMake(23.58, 20) controlPoint2: CGPointMake(20, 23.58)];
    [bezier3Path addCurveToPoint: CGPointMake(28, 36) controlPoint1: CGPointMake(20, 32.42) controlPoint2: CGPointMake(23.58, 36)];
    [bezier3Path closePath];
    [color setFill];
    [bezier3Path fill];
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
    shadowPath.usesEvenOddFillRule = YES;
    [black24 setFill];
    [shadowPath fill];
}

+ (void)drawShieldnotverified
{
    //// Color Declarations
    UIColor* e2EE = [UIColor colorWithRed: 0 green: 0.588 blue: 0.941 alpha: 1];

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(15, 1.87)];
    [bezierPath addLineToPoint: CGPointMake(15, 8)];
    [bezierPath addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(15, 12) controlPoint2: CGPointMake(12.03, 15.1)];
    [bezierPath addCurveToPoint: CGPointMake(1, 8) controlPoint1: CGPointMake(4, 15.1) controlPoint2: CGPointMake(1, 12)];
    [bezierPath addLineToPoint: CGPointMake(1, 2)];
    [bezierPath addLineToPoint: CGPointMake(8, 0)];
    [bezierPath addLineToPoint: CGPointMake(15, 1.87)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(8, 1.56)];
    [bezierPath addLineToPoint: CGPointMake(7.98, 1.56)];
    [bezierPath addLineToPoint: CGPointMake(2.5, 3.02)];
    [bezierPath addLineToPoint: CGPointMake(2.5, 8)];
    [bezierPath addCurveToPoint: CGPointMake(8, 14.46) controlPoint1: CGPointMake(2.5, 11.06) controlPoint2: CGPointMake(4.68, 13.59)];
    [bezierPath addLineToPoint: CGPointMake(8, 14.46)];
    [bezierPath addLineToPoint: CGPointMake(8, 1.56)];
    [bezierPath addLineToPoint: CGPointMake(8, 1.56)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [e2EE setFill];
    [bezierPath fill];
}

+ (void)drawShieldWithColor: (UIColor*)color
{

    //// Bezier 56 Drawing
    UIBezierPath* bezier56Path = [UIBezierPath bezierPath];
    [bezier56Path moveToPoint: CGPointMake(148.01, 70.64)];
    [bezier56Path addLineToPoint: CGPointMake(145.37, 69.69)];
    [bezier56Path addCurveToPoint: CGPointMake(144.19, 70.25) controlPoint1: CGPointMake(144.89, 69.52) controlPoint2: CGPointMake(144.37, 69.77)];
    [bezier56Path addCurveToPoint: CGPointMake(144.75, 71.43) controlPoint1: CGPointMake(144.02, 70.73) controlPoint2: CGPointMake(144.27, 71.26)];
    [bezier56Path addLineToPoint: CGPointMake(147.39, 72.38)];
    [bezier56Path addCurveToPoint: CGPointMake(148.57, 71.82) controlPoint1: CGPointMake(147.87, 72.55) controlPoint2: CGPointMake(148.4, 72.3)];
    [bezier56Path addCurveToPoint: CGPointMake(148.01, 70.64) controlPoint1: CGPointMake(148.74, 71.34) controlPoint2: CGPointMake(148.49, 70.81)];
    [bezier56Path addLineToPoint: CGPointMake(148.01, 70.64)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(153.88, 73.73)];
    [bezier56Path addCurveToPoint: CGPointMake(154.44, 74.91) controlPoint1: CGPointMake(153.71, 74.21) controlPoint2: CGPointMake(153.96, 74.74)];
    [bezier56Path addLineToPoint: CGPointMake(157.08, 75.86)];
    [bezier56Path addCurveToPoint: CGPointMake(158.26, 75.3) controlPoint1: CGPointMake(157.56, 76.03) controlPoint2: CGPointMake(158.09, 75.78)];
    [bezier56Path addCurveToPoint: CGPointMake(157.7, 74.12) controlPoint1: CGPointMake(158.43, 74.82) controlPoint2: CGPointMake(158.18, 74.29)];
    [bezier56Path addLineToPoint: CGPointMake(155.06, 73.17)];
    [bezier56Path addCurveToPoint: CGPointMake(153.88, 73.73) controlPoint1: CGPointMake(154.58, 73) controlPoint2: CGPointMake(154.05, 73.25)];
    [bezier56Path addLineToPoint: CGPointMake(153.88, 73.73)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(151.73, 75.56)];
    [bezier56Path addCurveToPoint: CGPointMake(150.99, 76.64) controlPoint1: CGPointMake(151.23, 75.65) controlPoint2: CGPointMake(150.9, 76.13)];
    [bezier56Path addLineToPoint: CGPointMake(151.49, 79.41)];
    [bezier56Path addCurveToPoint: CGPointMake(152.56, 80.15) controlPoint1: CGPointMake(151.58, 79.91) controlPoint2: CGPointMake(152.06, 80.24)];
    [bezier56Path addCurveToPoint: CGPointMake(153.3, 79.08) controlPoint1: CGPointMake(153.06, 80.06) controlPoint2: CGPointMake(153.4, 79.58)];
    [bezier56Path addLineToPoint: CGPointMake(152.8, 76.31)];
    [bezier56Path addCurveToPoint: CGPointMake(151.73, 75.56) controlPoint1: CGPointMake(152.71, 75.8) controlPoint2: CGPointMake(152.23, 75.47)];
    [bezier56Path addLineToPoint: CGPointMake(151.73, 75.56)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(155.63, 67.82)];
    [bezier56Path addLineToPoint: CGPointMake(153.49, 69.64)];
    [bezier56Path addCurveToPoint: CGPointMake(153.38, 70.95) controlPoint1: CGPointMake(153.1, 69.97) controlPoint2: CGPointMake(153.05, 70.56)];
    [bezier56Path addCurveToPoint: CGPointMake(154.68, 71.05) controlPoint1: CGPointMake(153.71, 71.34) controlPoint2: CGPointMake(154.29, 71.38)];
    [bezier56Path addLineToPoint: CGPointMake(156.82, 69.23)];
    [bezier56Path addCurveToPoint: CGPointMake(156.92, 67.93) controlPoint1: CGPointMake(157.2, 68.9) controlPoint2: CGPointMake(157.25, 68.32)];
    [bezier56Path addCurveToPoint: CGPointMake(155.63, 67.82) controlPoint1: CGPointMake(156.6, 67.54) controlPoint2: CGPointMake(156.01, 67.49)];
    [bezier56Path addLineToPoint: CGPointMake(155.63, 67.82)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(150.96, 66.15)];
    [bezier56Path addCurveToPoint: CGPointMake(149.89, 65.4) controlPoint1: CGPointMake(150.87, 65.64) controlPoint2: CGPointMake(150.39, 65.31)];
    [bezier56Path addCurveToPoint: CGPointMake(149.15, 66.48) controlPoint1: CGPointMake(149.39, 65.49) controlPoint2: CGPointMake(149.06, 65.98)];
    [bezier56Path addLineToPoint: CGPointMake(149.65, 69.25)];
    [bezier56Path addCurveToPoint: CGPointMake(150.72, 69.99) controlPoint1: CGPointMake(149.74, 69.75) controlPoint2: CGPointMake(150.22, 70.08)];
    [bezier56Path addCurveToPoint: CGPointMake(151.46, 68.92) controlPoint1: CGPointMake(151.22, 69.9) controlPoint2: CGPointMake(151.55, 69.42)];
    [bezier56Path addLineToPoint: CGPointMake(150.96, 66.15)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(147.78, 74.5)];
    [bezier56Path addLineToPoint: CGPointMake(145.64, 76.32)];
    [bezier56Path addCurveToPoint: CGPointMake(145.53, 77.63) controlPoint1: CGPointMake(145.25, 76.65) controlPoint2: CGPointMake(145.2, 77.24)];
    [bezier56Path addCurveToPoint: CGPointMake(146.83, 77.73) controlPoint1: CGPointMake(145.86, 78.01) controlPoint2: CGPointMake(146.44, 78.06)];
    [bezier56Path addLineToPoint: CGPointMake(148.97, 75.91)];
    [bezier56Path addCurveToPoint: CGPointMake(149.08, 74.61) controlPoint1: CGPointMake(149.36, 75.58) controlPoint2: CGPointMake(149.4, 75)];
    [bezier56Path addCurveToPoint: CGPointMake(147.78, 74.5) controlPoint1: CGPointMake(148.75, 74.22) controlPoint2: CGPointMake(148.17, 74.17)];
    [bezier56Path addLineToPoint: CGPointMake(147.78, 74.5)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(126.65, 15.18)];
    [bezier56Path addCurveToPoint: CGPointMake(126.99, 15.92) controlPoint1: CGPointMake(126.55, 15.48) controlPoint2: CGPointMake(126.7, 15.81)];
    [bezier56Path addLineToPoint: CGPointMake(128.6, 16.51)];
    [bezier56Path addCurveToPoint: CGPointMake(129.32, 16.16) controlPoint1: CGPointMake(128.89, 16.62) controlPoint2: CGPointMake(129.21, 16.46)];
    [bezier56Path addCurveToPoint: CGPointMake(128.98, 15.43) controlPoint1: CGPointMake(129.42, 15.86) controlPoint2: CGPointMake(129.27, 15.53)];
    [bezier56Path addLineToPoint: CGPointMake(127.37, 14.83)];
    [bezier56Path addCurveToPoint: CGPointMake(126.65, 15.18) controlPoint1: CGPointMake(127.08, 14.72) controlPoint2: CGPointMake(126.76, 14.88)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(121.09, 13.74)];
    [bezier56Path addLineToPoint: CGPointMake(122.7, 14.34)];
    [bezier56Path addCurveToPoint: CGPointMake(123.42, 13.99) controlPoint1: CGPointMake(122.99, 14.44) controlPoint2: CGPointMake(123.32, 14.29)];
    [bezier56Path addCurveToPoint: CGPointMake(123.08, 13.25) controlPoint1: CGPointMake(123.52, 13.69) controlPoint2: CGPointMake(123.37, 13.36)];
    [bezier56Path addLineToPoint: CGPointMake(121.47, 12.66)];
    [bezier56Path addCurveToPoint: CGPointMake(120.76, 13.01) controlPoint1: CGPointMake(121.18, 12.55) controlPoint2: CGPointMake(120.86, 12.71)];
    [bezier56Path addCurveToPoint: CGPointMake(121.09, 13.74) controlPoint1: CGPointMake(120.65, 13.31) controlPoint2: CGPointMake(120.8, 13.64)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(127.14, 13.51)];
    [bezier56Path addLineToPoint: CGPointMake(128.44, 12.37)];
    [bezier56Path addCurveToPoint: CGPointMake(128.5, 11.55) controlPoint1: CGPointMake(128.68, 12.16) controlPoint2: CGPointMake(128.7, 11.8)];
    [bezier56Path addCurveToPoint: CGPointMake(127.71, 11.49) controlPoint1: CGPointMake(128.3, 11.31) controlPoint2: CGPointMake(127.95, 11.28)];
    [bezier56Path addLineToPoint: CGPointMake(126.41, 12.63)];
    [bezier56Path addCurveToPoint: CGPointMake(126.35, 13.44) controlPoint1: CGPointMake(126.18, 12.83) controlPoint2: CGPointMake(126.15, 13.2)];
    [bezier56Path addCurveToPoint: CGPointMake(127.14, 13.51) controlPoint1: CGPointMake(126.55, 13.68) controlPoint2: CGPointMake(126.9, 13.71)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(122.94, 15.66)];
    [bezier56Path addLineToPoint: CGPointMake(121.63, 16.8)];
    [bezier56Path addCurveToPoint: CGPointMake(121.57, 17.61) controlPoint1: CGPointMake(121.4, 17.01) controlPoint2: CGPointMake(121.37, 17.37)];
    [bezier56Path addCurveToPoint: CGPointMake(122.36, 17.68) controlPoint1: CGPointMake(121.77, 17.86) controlPoint2: CGPointMake(122.12, 17.89)];
    [bezier56Path addLineToPoint: CGPointMake(123.66, 16.54)];
    [bezier56Path addCurveToPoint: CGPointMake(123.73, 15.73) controlPoint1: CGPointMake(123.9, 16.34) controlPoint2: CGPointMake(123.93, 15.97)];
    [bezier56Path addCurveToPoint: CGPointMake(122.94, 15.66) controlPoint1: CGPointMake(123.53, 15.49) controlPoint2: CGPointMake(123.17, 15.46)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(124.73, 12.84)];
    [bezier56Path addCurveToPoint: CGPointMake(125.18, 12.17) controlPoint1: CGPointMake(125.03, 12.79) controlPoint2: CGPointMake(125.24, 12.49)];
    [bezier56Path addLineToPoint: CGPointMake(124.88, 10.44)];
    [bezier56Path addCurveToPoint: CGPointMake(124.22, 9.98) controlPoint1: CGPointMake(124.82, 10.13) controlPoint2: CGPointMake(124.53, 9.92)];
    [bezier56Path addCurveToPoint: CGPointMake(123.77, 10.65) controlPoint1: CGPointMake(123.92, 10.03) controlPoint2: CGPointMake(123.72, 10.33)];
    [bezier56Path addLineToPoint: CGPointMake(124.08, 12.38)];
    [bezier56Path addCurveToPoint: CGPointMake(124.73, 12.84) controlPoint1: CGPointMake(124.13, 12.69) controlPoint2: CGPointMake(124.42, 12.9)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(124.89, 17)];
    [bezier56Path addLineToPoint: CGPointMake(125.2, 18.73)];
    [bezier56Path addCurveToPoint: CGPointMake(125.85, 19.19) controlPoint1: CGPointMake(125.25, 19.04) controlPoint2: CGPointMake(125.55, 19.25)];
    [bezier56Path addCurveToPoint: CGPointMake(126.3, 18.52) controlPoint1: CGPointMake(126.15, 19.14) controlPoint2: CGPointMake(126.36, 18.84)];
    [bezier56Path addLineToPoint: CGPointMake(126, 16.79)];
    [bezier56Path addCurveToPoint: CGPointMake(125.34, 16.33) controlPoint1: CGPointMake(125.94, 16.48) controlPoint2: CGPointMake(125.65, 16.27)];
    [bezier56Path addCurveToPoint: CGPointMake(124.89, 17) controlPoint1: CGPointMake(125.04, 16.38) controlPoint2: CGPointMake(124.84, 16.68)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(209.86, 30.29)];
    [bezier56Path addCurveToPoint: CGPointMake(210.97, 32.64) controlPoint1: CGPointMake(209.52, 31.25) controlPoint2: CGPointMake(210.02, 32.3)];
    [bezier56Path addCurveToPoint: CGPointMake(213.32, 31.52) controlPoint1: CGPointMake(211.93, 32.98) controlPoint2: CGPointMake(212.98, 32.48)];
    [bezier56Path addCurveToPoint: CGPointMake(212.2, 29.16) controlPoint1: CGPointMake(213.65, 30.56) controlPoint2: CGPointMake(213.15, 29.5)];
    [bezier56Path addLineToPoint: CGPointMake(206.31, 27.07)];
    [bezier56Path addLineToPoint: CGPointMake(208.27, 21.5)];
    [bezier56Path addLineToPoint: CGPointMake(212.77, 23.1)];
    [bezier56Path addCurveToPoint: CGPointMake(212.06, 24.02) controlPoint1: CGPointMake(212.45, 23.31) controlPoint2: CGPointMake(212.2, 23.63)];
    [bezier56Path addCurveToPoint: CGPointMake(213.18, 26.38) controlPoint1: CGPointMake(211.72, 24.98) controlPoint2: CGPointMake(212.22, 26.04)];
    [bezier56Path addCurveToPoint: CGPointMake(215.52, 25.25) controlPoint1: CGPointMake(214.13, 26.72) controlPoint2: CGPointMake(215.18, 26.21)];
    [bezier56Path addCurveToPoint: CGPointMake(214.4, 22.9) controlPoint1: CGPointMake(215.86, 24.29) controlPoint2: CGPointMake(215.36, 23.24)];
    [bezier56Path addLineToPoint: CGPointMake(207.13, 20.31)];
    [bezier56Path addLineToPoint: CGPointMake(205.75, 19.82)];
    [bezier56Path addLineToPoint: CGPointMake(203.42, 26.43)];
    [bezier56Path addLineToPoint: CGPointMake(203.3, 26.78)];
    [bezier56Path addLineToPoint: CGPointMake(210.57, 29.37)];
    [bezier56Path addCurveToPoint: CGPointMake(209.86, 30.29) controlPoint1: CGPointMake(210.25, 29.58) controlPoint2: CGPointMake(209.99, 29.9)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(263.26, 194.7)];
    [bezier56Path addLineToPoint: CGPointMake(258.27, 222.76)];
    [bezier56Path addCurveToPoint: CGPointMake(254.46, 220.72) controlPoint1: CGPointMake(257.29, 221.72) controlPoint2: CGPointMake(255.98, 220.98)];
    [bezier56Path addCurveToPoint: CGPointMake(246.54, 226.22) controlPoint1: CGPointMake(250.75, 220.06) controlPoint2: CGPointMake(247.2, 222.53)];
    [bezier56Path addCurveToPoint: CGPointMake(252.09, 234.07) controlPoint1: CGPointMake(245.89, 229.9) controlPoint2: CGPointMake(248.37, 233.42)];
    [bezier56Path addCurveToPoint: CGPointMake(260.01, 228.57) controlPoint1: CGPointMake(255.81, 234.73) controlPoint2: CGPointMake(259.35, 232.26)];
    [bezier56Path addLineToPoint: CGPointMake(264.05, 205.86)];
    [bezier56Path addLineToPoint: CGPointMake(285.6, 209.64)];
    [bezier56Path addLineToPoint: CGPointMake(282.51, 227)];
    [bezier56Path addCurveToPoint: CGPointMake(278.7, 224.96) controlPoint1: CGPointMake(281.53, 225.97) controlPoint2: CGPointMake(280.22, 225.23)];
    [bezier56Path addCurveToPoint: CGPointMake(270.78, 230.46) controlPoint1: CGPointMake(274.98, 224.31) controlPoint2: CGPointMake(271.44, 226.77)];
    [bezier56Path addCurveToPoint: CGPointMake(276.33, 238.32) controlPoint1: CGPointMake(270.12, 234.15) controlPoint2: CGPointMake(272.61, 237.67)];
    [bezier56Path addCurveToPoint: CGPointMake(284.25, 232.82) controlPoint1: CGPointMake(280.04, 238.97) controlPoint2: CGPointMake(283.59, 236.51)];
    [bezier56Path addLineToPoint: CGPointMake(289.24, 204.77)];
    [bezier56Path addLineToPoint: CGPointMake(290.19, 199.42)];
    [bezier56Path addLineToPoint: CGPointMake(264.61, 194.94)];
    [bezier56Path addLineToPoint: CGPointMake(263.26, 194.7)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(258.13, 151.03)];
    [bezier56Path addCurveToPoint: CGPointMake(254.45, 149.72) controlPoint1: CGPointMake(257.48, 149.66) controlPoint2: CGPointMake(255.83, 149.07)];
    [bezier56Path addCurveToPoint: CGPointMake(253.13, 153.38) controlPoint1: CGPointMake(253.07, 150.37) controlPoint2: CGPointMake(252.48, 152.01)];
    [bezier56Path addCurveToPoint: CGPointMake(256.82, 154.69) controlPoint1: CGPointMake(253.79, 154.75) controlPoint2: CGPointMake(255.44, 155.34)];
    [bezier56Path addCurveToPoint: CGPointMake(258.13, 151.03) controlPoint1: CGPointMake(258.2, 154.04) controlPoint2: CGPointMake(258.79, 152.4)];
    [bezier56Path addLineToPoint: CGPointMake(258.13, 151.03)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(248.65, 131.16)];
    [bezier56Path addCurveToPoint: CGPointMake(244.97, 129.85) controlPoint1: CGPointMake(248, 129.79) controlPoint2: CGPointMake(246.35, 129.2)];
    [bezier56Path addCurveToPoint: CGPointMake(243.65, 133.51) controlPoint1: CGPointMake(243.58, 130.5) controlPoint2: CGPointMake(243, 132.14)];
    [bezier56Path addCurveToPoint: CGPointMake(247.34, 134.82) controlPoint1: CGPointMake(244.31, 134.88) controlPoint2: CGPointMake(245.96, 135.47)];
    [bezier56Path addCurveToPoint: CGPointMake(248.65, 131.16) controlPoint1: CGPointMake(248.72, 134.17) controlPoint2: CGPointMake(249.31, 132.53)];
    [bezier56Path addLineToPoint: CGPointMake(248.65, 131.16)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(248.13, 155.74)];
    [bezier56Path addCurveToPoint: CGPointMake(244.45, 154.43) controlPoint1: CGPointMake(247.48, 154.37) controlPoint2: CGPointMake(245.83, 153.78)];
    [bezier56Path addCurveToPoint: CGPointMake(243.13, 158.09) controlPoint1: CGPointMake(243.07, 155.08) controlPoint2: CGPointMake(242.48, 156.72)];
    [bezier56Path addCurveToPoint: CGPointMake(246.82, 159.4) controlPoint1: CGPointMake(243.79, 159.47) controlPoint2: CGPointMake(245.44, 160.05)];
    [bezier56Path addCurveToPoint: CGPointMake(248.13, 155.74) controlPoint1: CGPointMake(248.2, 158.75) controlPoint2: CGPointMake(248.79, 157.11)];
    [bezier56Path addLineToPoint: CGPointMake(248.13, 155.74)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(238.65, 135.87)];
    [bezier56Path addCurveToPoint: CGPointMake(234.96, 134.56) controlPoint1: CGPointMake(238, 134.5) controlPoint2: CGPointMake(236.35, 133.91)];
    [bezier56Path addCurveToPoint: CGPointMake(233.65, 138.22) controlPoint1: CGPointMake(233.58, 135.21) controlPoint2: CGPointMake(232.99, 136.85)];
    [bezier56Path addCurveToPoint: CGPointMake(237.34, 139.53) controlPoint1: CGPointMake(234.3, 139.59) controlPoint2: CGPointMake(235.95, 140.18)];
    [bezier56Path addCurveToPoint: CGPointMake(238.65, 135.87) controlPoint1: CGPointMake(238.72, 138.88) controlPoint2: CGPointMake(239.3, 137.24)];
    [bezier56Path addLineToPoint: CGPointMake(238.65, 135.87)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(238.13, 160.45)];
    [bezier56Path addCurveToPoint: CGPointMake(234.45, 159.14) controlPoint1: CGPointMake(237.48, 159.08) controlPoint2: CGPointMake(235.83, 158.49)];
    [bezier56Path addCurveToPoint: CGPointMake(233.13, 162.8) controlPoint1: CGPointMake(233.07, 159.79) controlPoint2: CGPointMake(232.48, 161.43)];
    [bezier56Path addCurveToPoint: CGPointMake(236.82, 164.11) controlPoint1: CGPointMake(233.79, 164.18) controlPoint2: CGPointMake(235.44, 164.76)];
    [bezier56Path addCurveToPoint: CGPointMake(238.13, 160.45) controlPoint1: CGPointMake(238.2, 163.46) controlPoint2: CGPointMake(238.79, 161.82)];
    [bezier56Path addLineToPoint: CGPointMake(238.13, 160.45)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(228.65, 140.58)];
    [bezier56Path addCurveToPoint: CGPointMake(224.96, 139.27) controlPoint1: CGPointMake(227.99, 139.21) controlPoint2: CGPointMake(226.34, 138.62)];
    [bezier56Path addCurveToPoint: CGPointMake(223.65, 142.93) controlPoint1: CGPointMake(223.58, 139.92) controlPoint2: CGPointMake(222.99, 141.56)];
    [bezier56Path addCurveToPoint: CGPointMake(227.33, 144.24) controlPoint1: CGPointMake(224.3, 144.3) controlPoint2: CGPointMake(225.95, 144.89)];
    [bezier56Path addCurveToPoint: CGPointMake(228.65, 140.58) controlPoint1: CGPointMake(228.71, 143.59) controlPoint2: CGPointMake(229.3, 141.95)];
    [bezier56Path addLineToPoint: CGPointMake(228.65, 140.58)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(268.01, 152.46)];
    [bezier56Path addLineToPoint: CGPointMake(228, 171.3)];
    [bezier56Path addLineToPoint: CGPointMake(226.82, 168.82)];
    [bezier56Path addCurveToPoint: CGPointMake(228.13, 165.16) controlPoint1: CGPointMake(228.2, 168.17) controlPoint2: CGPointMake(228.78, 166.53)];
    [bezier56Path addCurveToPoint: CGPointMake(224.44, 163.85) controlPoint1: CGPointMake(227.48, 163.79) controlPoint2: CGPointMake(225.83, 163.2)];
    [bezier56Path addLineToPoint: CGPointMake(217.33, 148.95)];
    [bezier56Path addCurveToPoint: CGPointMake(218.65, 145.29) controlPoint1: CGPointMake(218.71, 148.3) controlPoint2: CGPointMake(219.3, 146.66)];
    [bezier56Path addCurveToPoint: CGPointMake(214.96, 143.98) controlPoint1: CGPointMake(217.99, 143.92) controlPoint2: CGPointMake(216.34, 143.33)];
    [bezier56Path addLineToPoint: CGPointMake(213.78, 141.5)];
    [bezier56Path addLineToPoint: CGPointMake(253.78, 122.66)];
    [bezier56Path addLineToPoint: CGPointMake(254.97, 125.14)];
    [bezier56Path addCurveToPoint: CGPointMake(253.65, 128.8) controlPoint1: CGPointMake(253.59, 125.79) controlPoint2: CGPointMake(253, 127.43)];
    [bezier56Path addCurveToPoint: CGPointMake(257.34, 130.11) controlPoint1: CGPointMake(254.31, 130.17) controlPoint2: CGPointMake(255.96, 130.76)];
    [bezier56Path addLineToPoint: CGPointMake(264.45, 145.01)];
    [bezier56Path addCurveToPoint: CGPointMake(263.13, 148.67) controlPoint1: CGPointMake(263.07, 145.66) controlPoint2: CGPointMake(262.48, 147.3)];
    [bezier56Path addCurveToPoint: CGPointMake(266.82, 149.98) controlPoint1: CGPointMake(263.79, 150.04) controlPoint2: CGPointMake(265.44, 150.63)];
    [bezier56Path addLineToPoint: CGPointMake(268.01, 152.46)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(167.79, 80.14)];
    [bezier56Path addLineToPoint: CGPointMake(169.12, 80.36)];
    [bezier56Path addLineToPoint: CGPointMake(169.2, 79.87)];
    [bezier56Path addCurveToPoint: CGPointMake(169.17, 78.8) controlPoint1: CGPointMake(169.26, 79.48) controlPoint2: CGPointMake(169.25, 79.13)];
    [bezier56Path addCurveToPoint: CGPointMake(168.77, 77.97) controlPoint1: CGPointMake(169.09, 78.48) controlPoint2: CGPointMake(168.95, 78.2)];
    [bezier56Path addCurveToPoint: CGPointMake(168.12, 77.41) controlPoint1: CGPointMake(168.58, 77.74) controlPoint2: CGPointMake(168.37, 77.55)];
    [bezier56Path addCurveToPoint: CGPointMake(167.33, 77.12) controlPoint1: CGPointMake(167.86, 77.26) controlPoint2: CGPointMake(167.6, 77.17)];
    [bezier56Path addCurveToPoint: CGPointMake(166.5, 77.13) controlPoint1: CGPointMake(167.06, 77.07) controlPoint2: CGPointMake(166.78, 77.08)];
    [bezier56Path addCurveToPoint: CGPointMake(165.71, 77.45) controlPoint1: CGPointMake(166.22, 77.19) controlPoint2: CGPointMake(165.95, 77.29)];
    [bezier56Path addCurveToPoint: CGPointMake(165.07, 78.11) controlPoint1: CGPointMake(165.46, 77.61) controlPoint2: CGPointMake(165.25, 77.83)];
    [bezier56Path addCurveToPoint: CGPointMake(164.71, 79.11) controlPoint1: CGPointMake(164.89, 78.38) controlPoint2: CGPointMake(164.77, 78.72)];
    [bezier56Path addLineToPoint: CGPointMake(163.9, 84.23)];
    [bezier56Path addCurveToPoint: CGPointMake(163.93, 85.31) controlPoint1: CGPointMake(163.84, 84.63) controlPoint2: CGPointMake(163.85, 84.99)];
    [bezier56Path addCurveToPoint: CGPointMake(164.34, 86.13) controlPoint1: CGPointMake(164.02, 85.63) controlPoint2: CGPointMake(164.15, 85.9)];
    [bezier56Path addCurveToPoint: CGPointMake(164.99, 86.7) controlPoint1: CGPointMake(164.52, 86.37) controlPoint2: CGPointMake(164.74, 86.55)];
    [bezier56Path addCurveToPoint: CGPointMake(165.77, 86.99) controlPoint1: CGPointMake(165.24, 86.84) controlPoint2: CGPointMake(165.5, 86.94)];
    [bezier56Path addCurveToPoint: CGPointMake(166.6, 86.97) controlPoint1: CGPointMake(166.04, 87.03) controlPoint2: CGPointMake(166.32, 87.03)];
    [bezier56Path addCurveToPoint: CGPointMake(167.4, 86.65) controlPoint1: CGPointMake(166.89, 86.92) controlPoint2: CGPointMake(167.15, 86.81)];
    [bezier56Path addCurveToPoint: CGPointMake(168.03, 86.01) controlPoint1: CGPointMake(167.64, 86.49) controlPoint2: CGPointMake(167.85, 86.28)];
    [bezier56Path addCurveToPoint: CGPointMake(168.39, 85) controlPoint1: CGPointMake(168.21, 85.73) controlPoint2: CGPointMake(168.33, 85.4)];
    [bezier56Path addLineToPoint: CGPointMake(168.87, 81.94)];
    [bezier56Path addLineToPoint: CGPointMake(166.47, 81.54)];
    [bezier56Path addLineToPoint: CGPointMake(166.28, 82.76)];
    [bezier56Path addLineToPoint: CGPointMake(167.34, 82.94)];
    [bezier56Path addLineToPoint: CGPointMake(167.05, 84.77)];
    [bezier56Path addCurveToPoint: CGPointMake(166.67, 85.47) controlPoint1: CGPointMake(167, 85.11) controlPoint2: CGPointMake(166.87, 85.34)];
    [bezier56Path addCurveToPoint: CGPointMake(165.99, 85.6) controlPoint1: CGPointMake(166.46, 85.59) controlPoint2: CGPointMake(166.24, 85.64)];
    [bezier56Path addCurveToPoint: CGPointMake(165.39, 85.25) controlPoint1: CGPointMake(165.75, 85.55) controlPoint2: CGPointMake(165.55, 85.44)];
    [bezier56Path addCurveToPoint: CGPointMake(165.24, 84.46) controlPoint1: CGPointMake(165.24, 85.06) controlPoint2: CGPointMake(165.19, 84.8)];
    [bezier56Path addLineToPoint: CGPointMake(166.05, 79.34)];
    [bezier56Path addCurveToPoint: CGPointMake(166.44, 78.64) controlPoint1: CGPointMake(166.1, 79) controlPoint2: CGPointMake(166.23, 78.77)];
    [bezier56Path addCurveToPoint: CGPointMake(167.11, 78.51) controlPoint1: CGPointMake(166.64, 78.51) controlPoint2: CGPointMake(166.87, 78.47)];
    [bezier56Path addCurveToPoint: CGPointMake(167.71, 78.86) controlPoint1: CGPointMake(167.36, 78.55) controlPoint2: CGPointMake(167.56, 78.67)];
    [bezier56Path addCurveToPoint: CGPointMake(167.86, 79.65) controlPoint1: CGPointMake(167.87, 79.05) controlPoint2: CGPointMake(167.92, 79.31)];
    [bezier56Path addLineToPoint: CGPointMake(167.79, 80.14)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(171.89, 87.94)];
    [bezier56Path addLineToPoint: CGPointMake(173.23, 88.17)];
    [bezier56Path addLineToPoint: CGPointMake(173.89, 84.03)];
    [bezier56Path addLineToPoint: CGPointMake(176.2, 84.42)];
    [bezier56Path addLineToPoint: CGPointMake(176.4, 83.11)];
    [bezier56Path addLineToPoint: CGPointMake(174.09, 82.72)];
    [bezier56Path addLineToPoint: CGPointMake(174.56, 79.78)];
    [bezier56Path addLineToPoint: CGPointMake(177.21, 80.23)];
    [bezier56Path addLineToPoint: CGPointMake(177.42, 78.92)];
    [bezier56Path addLineToPoint: CGPointMake(173.43, 78.24)];
    [bezier56Path addLineToPoint: CGPointMake(171.89, 87.94)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(169.25, 87.49)];
    [bezier56Path addLineToPoint: CGPointMake(170.59, 87.72)];
    [bezier56Path addLineToPoint: CGPointMake(172.13, 78.02)];
    [bezier56Path addLineToPoint: CGPointMake(170.79, 77.79)];
    [bezier56Path addLineToPoint: CGPointMake(169.25, 87.49)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(136.48, 293.04)];
    [bezier56Path addCurveToPoint: CGPointMake(134.42, 285.22) controlPoint1: CGPointMake(138.09, 290.32) controlPoint2: CGPointMake(137.17, 286.82)];
    [bezier56Path addCurveToPoint: CGPointMake(126.53, 287.26) controlPoint1: CGPointMake(131.68, 283.63) controlPoint2: CGPointMake(128.14, 284.54)];
    [bezier56Path addCurveToPoint: CGPointMake(128.59, 295.08) controlPoint1: CGPointMake(124.92, 289.99) controlPoint2: CGPointMake(125.84, 293.48)];
    [bezier56Path addCurveToPoint: CGPointMake(136.48, 293.04) controlPoint1: CGPointMake(131.34, 296.67) controlPoint2: CGPointMake(134.87, 295.76)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(131.81, 300.92)];
    [bezier56Path addLineToPoint: CGPointMake(121.87, 295.15)];
    [bezier56Path addCurveToPoint: CGPointMake(121.04, 292.03) controlPoint1: CGPointMake(120.77, 294.51) controlPoint2: CGPointMake(120.4, 293.11)];
    [bezier56Path addLineToPoint: CGPointMake(128.04, 280.19)];
    [bezier56Path addCurveToPoint: CGPointMake(131.2, 279.38) controlPoint1: CGPointMake(128.69, 279.11) controlPoint2: CGPointMake(130.1, 278.74)];
    [bezier56Path addLineToPoint: CGPointMake(141.14, 285.15)];
    [bezier56Path addCurveToPoint: CGPointMake(141.98, 288.28) controlPoint1: CGPointMake(142.25, 285.79) controlPoint2: CGPointMake(142.62, 287.19)];
    [bezier56Path addLineToPoint: CGPointMake(140.47, 290.82)];
    [bezier56Path addLineToPoint: CGPointMake(141.36, 291.62)];
    [bezier56Path addCurveToPoint: CGPointMake(141.64, 293.37) controlPoint1: CGPointMake(141.83, 292.05) controlPoint2: CGPointMake(141.95, 292.84)];
    [bezier56Path addLineToPoint: CGPointMake(139.29, 297.33)];
    [bezier56Path addCurveToPoint: CGPointMake(137.61, 297.95) controlPoint1: CGPointMake(138.97, 297.87) controlPoint2: CGPointMake(138.23, 298.15)];
    [bezier56Path addLineToPoint: CGPointMake(136.47, 297.57)];
    [bezier56Path addLineToPoint: CGPointMake(134.97, 300.11)];
    [bezier56Path addCurveToPoint: CGPointMake(131.81, 300.92) controlPoint1: CGPointMake(134.33, 301.2) controlPoint2: CGPointMake(132.92, 301.56)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(133.26, 287.2)];
    [bezier56Path addCurveToPoint: CGPointMake(128.52, 288.42) controlPoint1: CGPointMake(131.61, 286.24) controlPoint2: CGPointMake(129.49, 286.79)];
    [bezier56Path addCurveToPoint: CGPointMake(129.76, 293.11) controlPoint1: CGPointMake(127.56, 290.05) controlPoint2: CGPointMake(128.11, 292.15)];
    [bezier56Path addCurveToPoint: CGPointMake(134.49, 291.88) controlPoint1: CGPointMake(131.41, 294.07) controlPoint2: CGPointMake(133.53, 293.52)];
    [bezier56Path addCurveToPoint: CGPointMake(133.26, 287.2) controlPoint1: CGPointMake(135.46, 290.25) controlPoint2: CGPointMake(134.91, 288.15)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(19.81, 221.29)];
    [bezier56Path addCurveToPoint: CGPointMake(17.66, 218.42) controlPoint1: CGPointMake(18.83, 220.63) controlPoint2: CGPointMake(18.05, 219.65)];
    [bezier56Path addCurveToPoint: CGPointMake(17.76, 214.82) controlPoint1: CGPointMake(17.28, 217.2) controlPoint2: CGPointMake(17.34, 215.94)];
    [bezier56Path addLineToPoint: CGPointMake(17.66, 214.51)];
    [bezier56Path addCurveToPoint: CGPointMake(14.2, 212.7) controlPoint1: CGPointMake(17.2, 213.03) controlPoint2: CGPointMake(15.65, 212.22)];
    [bezier56Path addLineToPoint: CGPointMake(13.09, 213.06)];
    [bezier56Path addCurveToPoint: CGPointMake(13.54, 219.77) controlPoint1: CGPointMake(12.71, 215.23) controlPoint2: CGPointMake(12.83, 217.53)];
    [bezier56Path addCurveToPoint: CGPointMake(17.02, 225.49) controlPoint1: CGPointMake(14.25, 222.02) controlPoint2: CGPointMake(15.47, 223.95)];
    [bezier56Path addLineToPoint: CGPointMake(18.13, 225.13)];
    [bezier56Path addCurveToPoint: CGPointMake(19.91, 221.61) controlPoint1: CGPointMake(19.57, 224.66) controlPoint2: CGPointMake(20.37, 223.08)];
    [bezier56Path addLineToPoint: CGPointMake(19.81, 221.29)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(23.89, 220.31)];
    [bezier56Path addCurveToPoint: CGPointMake(26.26, 215.61) controlPoint1: CGPointMake(25.82, 219.68) controlPoint2: CGPointMake(26.88, 217.58)];
    [bezier56Path addCurveToPoint: CGPointMake(21.64, 213.2) controlPoint1: CGPointMake(25.64, 213.65) controlPoint2: CGPointMake(23.57, 212.57)];
    [bezier56Path addCurveToPoint: CGPointMake(19.27, 217.9) controlPoint1: CGPointMake(19.71, 213.83) controlPoint2: CGPointMake(18.65, 215.94)];
    [bezier56Path addCurveToPoint: CGPointMake(23.89, 220.31) controlPoint1: CGPointMake(19.89, 219.86) controlPoint2: CGPointMake(21.96, 220.94)];
    [bezier56Path addLineToPoint: CGPointMake(23.89, 220.31)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(185.84, 101.81)];
    [bezier56Path addLineToPoint: CGPointMake(186.89, 104.92)];
    [bezier56Path addCurveToPoint: CGPointMake(205.46, 103.37) controlPoint1: CGPointMake(192.92, 105.89) controlPoint2: CGPointMake(199.27, 105.46)];
    [bezier56Path addCurveToPoint: CGPointMake(221.17, 93.36) controlPoint1: CGPointMake(211.65, 101.28) controlPoint2: CGPointMake(216.97, 97.79)];
    [bezier56Path addLineToPoint: CGPointMake(220.12, 90.26)];
    [bezier56Path addCurveToPoint: CGPointMake(210.29, 85.41) controlPoint1: CGPointMake(218.75, 86.22) controlPoint2: CGPointMake(214.35, 84.04)];
    [bezier56Path addLineToPoint: CGPointMake(209.42, 85.7)];
    [bezier56Path addCurveToPoint: CGPointMake(201.56, 91.84) controlPoint1: CGPointMake(207.63, 88.48) controlPoint2: CGPointMake(204.93, 90.7)];
    [bezier56Path addCurveToPoint: CGPointMake(191.58, 91.71) controlPoint1: CGPointMake(198.19, 92.98) controlPoint2: CGPointMake(194.69, 92.84)];
    [bezier56Path addLineToPoint: CGPointMake(190.71, 92)];
    [bezier56Path addCurveToPoint: CGPointMake(185.84, 101.81) controlPoint1: CGPointMake(186.65, 93.37) controlPoint2: CGPointMake(184.47, 97.76)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(200.04, 87.33)];
    [bezier56Path addCurveToPoint: CGPointMake(206.52, 74.26) controlPoint1: CGPointMake(205.45, 85.51) controlPoint2: CGPointMake(208.35, 79.66)];
    [bezier56Path addCurveToPoint: CGPointMake(193.42, 67.78) controlPoint1: CGPointMake(204.7, 68.86) controlPoint2: CGPointMake(198.83, 65.96)];
    [bezier56Path addCurveToPoint: CGPointMake(186.93, 80.86) controlPoint1: CGPointMake(188.01, 69.6) controlPoint2: CGPointMake(185.11, 75.46)];
    [bezier56Path addCurveToPoint: CGPointMake(200.04, 87.33) controlPoint1: CGPointMake(188.76, 86.26) controlPoint2: CGPointMake(194.63, 89.16)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(223.56, 122.5)];
    [bezier56Path addCurveToPoint: CGPointMake(222.94, 121.99) controlPoint1: CGPointMake(223.24, 122.53) controlPoint2: CGPointMake(222.97, 122.3)];
    [bezier56Path addLineToPoint: CGPointMake(222.13, 114.02)];
    [bezier56Path addCurveToPoint: CGPointMake(220.88, 112.99) controlPoint1: CGPointMake(222.07, 113.4) controlPoint2: CGPointMake(221.5, 112.94)];
    [bezier56Path addCurveToPoint: CGPointMake(219.85, 114.23) controlPoint1: CGPointMake(220.25, 113.05) controlPoint2: CGPointMake(219.79, 113.61)];
    [bezier56Path addLineToPoint: CGPointMake(220.66, 122.2)];
    [bezier56Path addCurveToPoint: CGPointMake(223.79, 124.77) controlPoint1: CGPointMake(220.82, 123.77) controlPoint2: CGPointMake(222.22, 124.91)];
    [bezier56Path addCurveToPoint: CGPointMake(226.35, 121.68) controlPoint1: CGPointMake(225.37, 124.62) controlPoint2: CGPointMake(226.51, 123.24)];
    [bezier56Path addLineToPoint: CGPointMake(225.6, 114.29)];
    [bezier56Path addLineToPoint: CGPointMake(225.37, 112.02)];
    [bezier56Path addCurveToPoint: CGPointMake(220.36, 107.9) controlPoint1: CGPointMake(225.12, 109.51) controlPoint2: CGPointMake(222.87, 107.67)];
    [bezier56Path addCurveToPoint: CGPointMake(216.26, 112.85) controlPoint1: CGPointMake(217.85, 108.13) controlPoint2: CGPointMake(216.01, 110.35)];
    [bezier56Path addLineToPoint: CGPointMake(217.01, 120.23)];
    [bezier56Path addLineToPoint: CGPointMake(217.24, 122.5)];
    [bezier56Path addCurveToPoint: CGPointMake(224.14, 128.17) controlPoint1: CGPointMake(217.59, 125.95) controlPoint2: CGPointMake(220.68, 128.49)];
    [bezier56Path addCurveToPoint: CGPointMake(229.77, 121.36) controlPoint1: CGPointMake(227.59, 127.86) controlPoint2: CGPointMake(230.12, 124.8)];
    [bezier56Path addLineToPoint: CGPointMake(228.96, 113.41)];
    [bezier56Path addCurveToPoint: CGPointMake(227.71, 112.38) controlPoint1: CGPointMake(228.9, 112.78) controlPoint2: CGPointMake(228.34, 112.32)];
    [bezier56Path addCurveToPoint: CGPointMake(226.68, 113.62) controlPoint1: CGPointMake(227.08, 112.44) controlPoint2: CGPointMake(226.62, 112.99)];
    [bezier56Path addLineToPoint: CGPointMake(227.49, 121.57)];
    [bezier56Path addCurveToPoint: CGPointMake(223.91, 125.9) controlPoint1: CGPointMake(227.71, 123.76) controlPoint2: CGPointMake(226.1, 125.7)];
    [bezier56Path addCurveToPoint: CGPointMake(219.52, 122.29) controlPoint1: CGPointMake(221.7, 126.1) controlPoint2: CGPointMake(219.74, 124.49)];
    [bezier56Path addLineToPoint: CGPointMake(219.29, 120.02)];
    [bezier56Path addLineToPoint: CGPointMake(218.54, 112.64)];
    [bezier56Path addCurveToPoint: CGPointMake(220.59, 110.17) controlPoint1: CGPointMake(218.42, 111.39) controlPoint2: CGPointMake(219.33, 110.28)];
    [bezier56Path addCurveToPoint: CGPointMake(223.1, 112.23) controlPoint1: CGPointMake(221.85, 110.05) controlPoint2: CGPointMake(222.97, 110.97)];
    [bezier56Path addLineToPoint: CGPointMake(223.33, 114.5)];
    [bezier56Path addLineToPoint: CGPointMake(224.07, 121.89)];
    [bezier56Path addCurveToPoint: CGPointMake(223.56, 122.5) controlPoint1: CGPointMake(224.11, 122.2) controlPoint2: CGPointMake(223.88, 122.47)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(262.63, 244.93)];
    [bezier56Path addLineToPoint: CGPointMake(260.69, 243.51)];
    [bezier56Path addCurveToPoint: CGPointMake(243.79, 243.22) controlPoint1: CGPointMake(255.55, 239.77) controlPoint2: CGPointMake(248.77, 239.84)];
    [bezier56Path addLineToPoint: CGPointMake(237.22, 238.43)];
    [bezier56Path addLineToPoint: CGPointMake(237.72, 250.07)];
    [bezier56Path addLineToPoint: CGPointMake(234.48, 254.47)];
    [bezier56Path addCurveToPoint: CGPointMake(237.64, 274.83) controlPoint1: CGPointMake(229.69, 260.98) controlPoint2: CGPointMake(231.12, 270.07)];
    [bezier56Path addLineToPoint: CGPointMake(239.59, 276.25)];
    [bezier56Path addCurveToPoint: CGPointMake(260.04, 273.11) controlPoint1: CGPointMake(246.09, 281) controlPoint2: CGPointMake(255.26, 279.6)];
    [bezier56Path addLineToPoint: CGPointMake(265.79, 265.3)];
    [bezier56Path addCurveToPoint: CGPointMake(262.63, 244.93) controlPoint1: CGPointMake(270.58, 258.79) controlPoint2: CGPointMake(269.15, 249.69)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(256.44, 75)];
    [bezier56Path addCurveToPoint: CGPointMake(263.97, 71.52) controlPoint1: CGPointMake(259.48, 76.11) controlPoint2: CGPointMake(262.85, 74.56)];
    [bezier56Path addLineToPoint: CGPointMake(270.84, 52.82)];
    [bezier56Path addLineToPoint: CGPointMake(288.45, 59.29)];
    [bezier56Path addLineToPoint: CGPointMake(283.2, 73.58)];
    [bezier56Path addCurveToPoint: CGPointMake(280.3, 71.27) controlPoint1: CGPointMake(282.53, 72.56) controlPoint2: CGPointMake(281.54, 71.73)];
    [bezier56Path addCurveToPoint: CGPointMake(272.77, 74.75) controlPoint1: CGPointMake(277.26, 70.16) controlPoint2: CGPointMake(273.89, 71.71)];
    [bezier56Path addCurveToPoint: CGPointMake(276.26, 82.27) controlPoint1: CGPointMake(271.66, 77.79) controlPoint2: CGPointMake(273.22, 81.15)];
    [bezier56Path addCurveToPoint: CGPointMake(283.78, 78.79) controlPoint1: CGPointMake(279.29, 83.38) controlPoint2: CGPointMake(282.66, 81.83)];
    [bezier56Path addLineToPoint: CGPointMake(292.27, 55.7)];
    [bezier56Path addLineToPoint: CGPointMake(293.89, 51.3)];
    [bezier56Path addLineToPoint: CGPointMake(272.98, 43.62)];
    [bezier56Path addLineToPoint: CGPointMake(271.87, 43.22)];
    [bezier56Path addLineToPoint: CGPointMake(263.38, 66.31)];
    [bezier56Path addCurveToPoint: CGPointMake(260.49, 64) controlPoint1: CGPointMake(262.72, 65.28) controlPoint2: CGPointMake(261.73, 64.46)];
    [bezier56Path addCurveToPoint: CGPointMake(252.96, 67.48) controlPoint1: CGPointMake(257.45, 62.89) controlPoint2: CGPointMake(254.08, 64.44)];
    [bezier56Path addCurveToPoint: CGPointMake(256.44, 75) controlPoint1: CGPointMake(251.84, 70.52) controlPoint2: CGPointMake(253.4, 73.88)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(98.94, 209.79)];
    [bezier56Path addCurveToPoint: CGPointMake(94.13, 209.66) controlPoint1: CGPointMake(97.65, 208.42) controlPoint2: CGPointMake(95.49, 208.36)];
    [bezier56Path addCurveToPoint: CGPointMake(93.99, 214.48) controlPoint1: CGPointMake(92.76, 210.95) controlPoint2: CGPointMake(92.7, 213.11)];
    [bezier56Path addCurveToPoint: CGPointMake(98.81, 214.61) controlPoint1: CGPointMake(95.29, 215.85) controlPoint2: CGPointMake(97.44, 215.91)];
    [bezier56Path addCurveToPoint: CGPointMake(98.94, 209.79) controlPoint1: CGPointMake(100.18, 213.32) controlPoint2: CGPointMake(100.24, 211.16)];
    [bezier56Path addLineToPoint: CGPointMake(98.94, 209.79)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(95.05, 175.92)];
    [bezier56Path addCurveToPoint: CGPointMake(99.87, 176.05) controlPoint1: CGPointMake(96.35, 177.29) controlPoint2: CGPointMake(98.5, 177.35)];
    [bezier56Path addCurveToPoint: CGPointMake(100, 171.24) controlPoint1: CGPointMake(101.24, 174.76) controlPoint2: CGPointMake(101.29, 172.6)];
    [bezier56Path addCurveToPoint: CGPointMake(95.18, 171.1) controlPoint1: CGPointMake(98.71, 169.87) controlPoint2: CGPointMake(96.55, 169.81)];
    [bezier56Path addCurveToPoint: CGPointMake(95.05, 175.92) controlPoint1: CGPointMake(93.82, 172.4) controlPoint2: CGPointMake(93.76, 174.55)];
    [bezier56Path addLineToPoint: CGPointMake(95.05, 175.92)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(89.57, 199.89)];
    [bezier56Path addCurveToPoint: CGPointMake(84.76, 199.76) controlPoint1: CGPointMake(88.28, 198.52) controlPoint2: CGPointMake(86.12, 198.46)];
    [bezier56Path addCurveToPoint: CGPointMake(84.63, 204.58) controlPoint1: CGPointMake(83.39, 201.05) controlPoint2: CGPointMake(83.33, 203.21)];
    [bezier56Path addCurveToPoint: CGPointMake(89.44, 204.71) controlPoint1: CGPointMake(85.92, 205.94) controlPoint2: CGPointMake(88.08, 206)];
    [bezier56Path addCurveToPoint: CGPointMake(89.57, 199.89) controlPoint1: CGPointMake(90.81, 203.41) controlPoint2: CGPointMake(90.87, 201.26)];
    [bezier56Path addLineToPoint: CGPointMake(89.57, 199.89)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(80.2, 189.98)];
    [bezier56Path addCurveToPoint: CGPointMake(75.39, 189.85) controlPoint1: CGPointMake(78.91, 188.62) controlPoint2: CGPointMake(76.75, 188.56)];
    [bezier56Path addCurveToPoint: CGPointMake(75.26, 194.67) controlPoint1: CGPointMake(74.02, 191.15) controlPoint2: CGPointMake(73.96, 193.3)];
    [bezier56Path addCurveToPoint: CGPointMake(80.07, 194.8) controlPoint1: CGPointMake(76.55, 196.04) controlPoint2: CGPointMake(78.71, 196.1)];
    [bezier56Path addCurveToPoint: CGPointMake(80.2, 189.98) controlPoint1: CGPointMake(81.44, 193.51) controlPoint2: CGPointMake(81.5, 191.35)];
    [bezier56Path addLineToPoint: CGPointMake(80.2, 189.98)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(104.42, 185.83)];
    [bezier56Path addCurveToPoint: CGPointMake(109.24, 185.96) controlPoint1: CGPointMake(105.71, 187.19) controlPoint2: CGPointMake(107.87, 187.25)];
    [bezier56Path addCurveToPoint: CGPointMake(109.37, 181.14) controlPoint1: CGPointMake(110.6, 184.66) controlPoint2: CGPointMake(110.66, 182.51)];
    [bezier56Path addCurveToPoint: CGPointMake(104.55, 181.01) controlPoint1: CGPointMake(108.08, 179.77) controlPoint2: CGPointMake(105.92, 179.71)];
    [bezier56Path addCurveToPoint: CGPointMake(104.42, 185.83) controlPoint1: CGPointMake(103.19, 182.3) controlPoint2: CGPointMake(103.13, 184.46)];
    [bezier56Path addLineToPoint: CGPointMake(104.42, 185.83)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(113.79, 195.73)];
    [bezier56Path addCurveToPoint: CGPointMake(118.61, 195.86) controlPoint1: CGPointMake(115.08, 197.1) controlPoint2: CGPointMake(117.24, 197.16)];
    [bezier56Path addCurveToPoint: CGPointMake(118.74, 191.04) controlPoint1: CGPointMake(119.97, 194.57) controlPoint2: CGPointMake(120.03, 192.41)];
    [bezier56Path addCurveToPoint: CGPointMake(113.92, 190.91) controlPoint1: CGPointMake(117.45, 189.67) controlPoint2: CGPointMake(115.29, 189.62)];
    [bezier56Path addCurveToPoint: CGPointMake(113.79, 195.73) controlPoint1: CGPointMake(112.56, 192.2) controlPoint2: CGPointMake(112.5, 194.36)];
    [bezier56Path addLineToPoint: CGPointMake(113.79, 195.73)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(100.89, 226.73)];
    [bezier56Path addLineToPoint: CGPointMake(63.41, 187.11)];
    [bezier56Path addLineToPoint: CGPointMake(65.89, 184.77)];
    [bezier56Path addCurveToPoint: CGPointMake(70.7, 184.9) controlPoint1: CGPointMake(67.18, 186.14) controlPoint2: CGPointMake(69.34, 186.19)];
    [bezier56Path addCurveToPoint: CGPointMake(70.84, 180.08) controlPoint1: CGPointMake(72.07, 183.61) controlPoint2: CGPointMake(72.13, 181.45)];
    [bezier56Path addLineToPoint: CGPointMake(85.68, 166.02)];
    [bezier56Path addCurveToPoint: CGPointMake(90.5, 166.15) controlPoint1: CGPointMake(86.98, 167.39) controlPoint2: CGPointMake(89.13, 167.45)];
    [bezier56Path addCurveToPoint: CGPointMake(90.63, 161.33) controlPoint1: CGPointMake(91.87, 164.86) controlPoint2: CGPointMake(91.93, 162.7)];
    [bezier56Path addLineToPoint: CGPointMake(93.11, 158.99)];
    [bezier56Path addLineToPoint: CGPointMake(130.58, 198.6)];
    [bezier56Path addLineToPoint: CGPointMake(128.11, 200.95)];
    [bezier56Path addCurveToPoint: CGPointMake(123.29, 200.81) controlPoint1: CGPointMake(126.81, 199.58) controlPoint2: CGPointMake(124.66, 199.52)];
    [bezier56Path addCurveToPoint: CGPointMake(123.16, 205.63) controlPoint1: CGPointMake(121.92, 202.11) controlPoint2: CGPointMake(121.87, 204.27)];
    [bezier56Path addLineToPoint: CGPointMake(108.31, 219.69)];
    [bezier56Path addCurveToPoint: CGPointMake(103.5, 219.56) controlPoint1: CGPointMake(107.02, 218.33) controlPoint2: CGPointMake(104.86, 218.27)];
    [bezier56Path addCurveToPoint: CGPointMake(103.36, 224.38) controlPoint1: CGPointMake(102.13, 220.86) controlPoint2: CGPointMake(102.07, 223.01)];
    [bezier56Path addLineToPoint: CGPointMake(100.89, 226.73)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(165.38, 166.97)];
    [bezier56Path addCurveToPoint: CGPointMake(164.16, 169.16) controlPoint1: CGPointMake(164.43, 167.24) controlPoint2: CGPointMake(163.88, 168.22)];
    [bezier56Path addLineToPoint: CGPointMake(165.68, 174.34)];
    [bezier56Path addCurveToPoint: CGPointMake(167.9, 175.54) controlPoint1: CGPointMake(165.95, 175.27) controlPoint2: CGPointMake(166.94, 175.82)];
    [bezier56Path addCurveToPoint: CGPointMake(169.12, 173.35) controlPoint1: CGPointMake(168.85, 175.27) controlPoint2: CGPointMake(169.4, 174.29)];
    [bezier56Path addLineToPoint: CGPointMake(167.6, 168.17)];
    [bezier56Path addCurveToPoint: CGPointMake(165.38, 166.97) controlPoint1: CGPointMake(167.33, 167.24) controlPoint2: CGPointMake(166.34, 166.7)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(157.52, 165.71)];
    [bezier56Path addLineToPoint: CGPointMake(153.73, 169.6)];
    [bezier56Path addCurveToPoint: CGPointMake(153.78, 172.1) controlPoint1: CGPointMake(153.04, 170.3) controlPoint2: CGPointMake(153.06, 171.42)];
    [bezier56Path addCurveToPoint: CGPointMake(156.31, 172.05) controlPoint1: CGPointMake(154.49, 172.78) controlPoint2: CGPointMake(155.62, 172.76)];
    [bezier56Path addLineToPoint: CGPointMake(160.1, 168.17)];
    [bezier56Path addCurveToPoint: CGPointMake(160.05, 165.66) controlPoint1: CGPointMake(160.79, 167.46) controlPoint2: CGPointMake(160.76, 166.34)];
    [bezier56Path addCurveToPoint: CGPointMake(157.52, 165.71) controlPoint1: CGPointMake(159.34, 164.99) controlPoint2: CGPointMake(158.2, 165.01)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(169.19, 163.06)];
    [bezier56Path addCurveToPoint: CGPointMake(170.5, 165.2) controlPoint1: CGPointMake(168.96, 164.01) controlPoint2: CGPointMake(169.54, 164.97)];
    [bezier56Path addLineToPoint: CGPointMake(175.81, 166.5)];
    [bezier56Path addCurveToPoint: CGPointMake(177.98, 165.2) controlPoint1: CGPointMake(176.77, 166.73) controlPoint2: CGPointMake(177.74, 166.15)];
    [bezier56Path addCurveToPoint: CGPointMake(176.67, 163.06) controlPoint1: CGPointMake(178.22, 164.26) controlPoint2: CGPointMake(177.63, 163.3)];
    [bezier56Path addLineToPoint: CGPointMake(171.37, 161.77)];
    [bezier56Path addCurveToPoint: CGPointMake(169.19, 163.06) controlPoint1: CGPointMake(170.4, 161.53) controlPoint2: CGPointMake(169.43, 162.11)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(162.34, 156.55)];
    [bezier56Path addCurveToPoint: CGPointMake(163.56, 154.36) controlPoint1: CGPointMake(163.29, 156.28) controlPoint2: CGPointMake(163.84, 155.3)];
    [bezier56Path addLineToPoint: CGPointMake(162.04, 149.18)];
    [bezier56Path addCurveToPoint: CGPointMake(159.82, 147.97) controlPoint1: CGPointMake(161.77, 148.24) controlPoint2: CGPointMake(160.78, 147.7)];
    [bezier56Path addCurveToPoint: CGPointMake(158.6, 150.16) controlPoint1: CGPointMake(158.87, 148.25) controlPoint2: CGPointMake(158.33, 149.23)];
    [bezier56Path addLineToPoint: CGPointMake(160.12, 155.34)];
    [bezier56Path addCurveToPoint: CGPointMake(162.34, 156.55) controlPoint1: CGPointMake(160.39, 156.28) controlPoint2: CGPointMake(161.38, 156.82)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(157.22, 158.32)];
    [bezier56Path addLineToPoint: CGPointMake(151.91, 157.02)];
    [bezier56Path addCurveToPoint: CGPointMake(149.74, 158.31) controlPoint1: CGPointMake(150.95, 156.79) controlPoint2: CGPointMake(149.98, 157.37)];
    [bezier56Path addCurveToPoint: CGPointMake(151.05, 160.46) controlPoint1: CGPointMake(149.5, 159.26) controlPoint2: CGPointMake(150.09, 160.22)];
    [bezier56Path addLineToPoint: CGPointMake(156.36, 161.75)];
    [bezier56Path addCurveToPoint: CGPointMake(158.53, 160.46) controlPoint1: CGPointMake(157.32, 161.98) controlPoint2: CGPointMake(158.29, 161.41)];
    [bezier56Path addCurveToPoint: CGPointMake(157.22, 158.32) controlPoint1: CGPointMake(158.76, 159.51) controlPoint2: CGPointMake(158.18, 158.55)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(171.41, 151.47)];
    [bezier56Path addLineToPoint: CGPointMake(167.62, 155.35)];
    [bezier56Path addCurveToPoint: CGPointMake(167.67, 157.85) controlPoint1: CGPointMake(166.93, 156.06) controlPoint2: CGPointMake(166.96, 157.18)];
    [bezier56Path addCurveToPoint: CGPointMake(170.21, 157.81) controlPoint1: CGPointMake(168.38, 158.53) controlPoint2: CGPointMake(169.52, 158.51)];
    [bezier56Path addLineToPoint: CGPointMake(173.99, 153.92)];
    [bezier56Path addCurveToPoint: CGPointMake(173.95, 151.42) controlPoint1: CGPointMake(174.68, 153.22) controlPoint2: CGPointMake(174.66, 152.1)];
    [bezier56Path addCurveToPoint: CGPointMake(171.41, 151.47) controlPoint1: CGPointMake(173.23, 150.74) controlPoint2: CGPointMake(172.1, 150.76)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(14.73, 72.4)];
    [bezier56Path addCurveToPoint: CGPointMake(10.75, 71.15) controlPoint1: CGPointMake(13.97, 70.95) controlPoint2: CGPointMake(12.19, 70.39)];
    [bezier56Path addCurveToPoint: CGPointMake(9.52, 75.14) controlPoint1: CGPointMake(9.32, 71.91) controlPoint2: CGPointMake(8.76, 73.69)];
    [bezier56Path addCurveToPoint: CGPointMake(21.23, 90.07) controlPoint1: CGPointMake(11.88, 79.63) controlPoint2: CGPointMake(16.91, 86.02)];
    [bezier56Path addCurveToPoint: CGPointMake(27.79, 94.24) controlPoint1: CGPointMake(23.78, 92.47) controlPoint2: CGPointMake(25.89, 93.92)];
    [bezier56Path addCurveToPoint: CGPointMake(32.4, 87.49) controlPoint1: CGPointMake(31.78, 94.91) controlPoint2: CGPointMake(33.21, 91.62)];
    [bezier56Path addCurveToPoint: CGPointMake(24.06, 72.52) controlPoint1: CGPointMake(31.77, 84.25) controlPoint2: CGPointMake(30.19, 81.62)];
    [bezier56Path addCurveToPoint: CGPointMake(23.12, 71.12) controlPoint1: CGPointMake(23.69, 71.97) controlPoint2: CGPointMake(23.4, 71.54)];
    [bezier56Path addCurveToPoint: CGPointMake(16.44, 59.35) controlPoint1: CGPointMake(19.35, 65.48) controlPoint2: CGPointMake(17.35, 62.06)];
    [bezier56Path addCurveToPoint: CGPointMake(17.19, 56.28) controlPoint1: CGPointMake(15.64, 56.96) controlPoint2: CGPointMake(15.78, 56.56)];
    [bezier56Path addCurveToPoint: CGPointMake(17.35, 56.65) controlPoint1: CGPointMake(16.93, 56.33) controlPoint2: CGPointMake(16.99, 56.35)];
    [bezier56Path addCurveToPoint: CGPointMake(19.8, 59.57) controlPoint1: CGPointMake(18.02, 57.22) controlPoint2: CGPointMake(18.84, 58.2)];
    [bezier56Path addCurveToPoint: CGPointMake(26.19, 70.52) controlPoint1: CGPointMake(21.46, 61.95) controlPoint2: CGPointMake(23, 64.64)];
    [bezier56Path addCurveToPoint: CGPointMake(26.68, 71.43) controlPoint1: CGPointMake(26.43, 70.98) controlPoint2: CGPointMake(26.43, 70.98)];
    [bezier56Path addCurveToPoint: CGPointMake(34.11, 83.97) controlPoint1: CGPointMake(30.27, 78.06) controlPoint2: CGPointMake(32.06, 81.15)];
    [bezier56Path addCurveToPoint: CGPointMake(44, 89.07) controlPoint1: CGPointMake(37.43, 88.53) controlPoint2: CGPointMake(40.48, 90.7)];
    [bezier56Path addCurveToPoint: CGPointMake(45.06, 78.73) controlPoint1: CGPointMake(47.4, 87.5) controlPoint2: CGPointMake(47.08, 84.23)];
    [bezier56Path addCurveToPoint: CGPointMake(39.32, 65.97) controlPoint1: CGPointMake(43.91, 75.62) controlPoint2: CGPointMake(42.37, 72.24)];
    [bezier56Path addCurveToPoint: CGPointMake(38.93, 65.16) controlPoint1: CGPointMake(39.12, 65.57) controlPoint2: CGPointMake(39.12, 65.57)];
    [bezier56Path addCurveToPoint: CGPointMake(34.38, 55.54) controlPoint1: CGPointMake(36.55, 60.27) controlPoint2: CGPointMake(35.29, 57.63)];
    [bezier56Path addCurveToPoint: CGPointMake(40.49, 65.42) controlPoint1: CGPointMake(36, 57.83) controlPoint2: CGPointMake(37.82, 60.81)];
    [bezier56Path addCurveToPoint: CGPointMake(42.11, 68.23) controlPoint1: CGPointMake(40.88, 66.09) controlPoint2: CGPointMake(41.3, 66.83)];
    [bezier56Path addCurveToPoint: CGPointMake(43.71, 70.98) controlPoint1: CGPointMake(42.76, 69.37) controlPoint2: CGPointMake(43.24, 70.19)];
    [bezier56Path addCurveToPoint: CGPointMake(56.35, 82.52) controlPoint1: CGPointMake(50.15, 82) controlPoint2: CGPointMake(52.28, 84.76)];
    [bezier56Path addCurveToPoint: CGPointMake(54.65, 63.88) controlPoint1: CGPointMake(60.01, 80.51) controlPoint2: CGPointMake(58.65, 74.15)];
    [bezier56Path addCurveToPoint: CGPointMake(43.34, 43.51) controlPoint1: CGPointMake(51.32, 55.32) controlPoint2: CGPointMake(47.02, 47.34)];
    [bezier56Path addCurveToPoint: CGPointMake(39.18, 43.43) controlPoint1: CGPointMake(42.21, 42.33) controlPoint2: CGPointMake(40.35, 42.3)];
    [bezier56Path addCurveToPoint: CGPointMake(39.11, 47.61) controlPoint1: CGPointMake(38.01, 44.56) controlPoint2: CGPointMake(37.98, 46.43)];
    [bezier56Path addCurveToPoint: CGPointMake(49.17, 66.02) controlPoint1: CGPointMake(42.12, 50.74) controlPoint2: CGPointMake(46.1, 58.12)];
    [bezier56Path addCurveToPoint: CGPointMake(51.33, 72.23) controlPoint1: CGPointMake(50.03, 68.23) controlPoint2: CGPointMake(50.76, 70.35)];
    [bezier56Path addCurveToPoint: CGPointMake(48.78, 68) controlPoint1: CGPointMake(50.59, 71.05) controlPoint2: CGPointMake(49.75, 69.67)];
    [bezier56Path addCurveToPoint: CGPointMake(47.2, 65.28) controlPoint1: CGPointMake(48.32, 67.22) controlPoint2: CGPointMake(47.85, 66.41)];
    [bezier56Path addCurveToPoint: CGPointMake(45.57, 62.47) controlPoint1: CGPointMake(46.39, 63.88) controlPoint2: CGPointMake(45.96, 63.14)];
    [bezier56Path addCurveToPoint: CGPointMake(29.09, 45.53) controlPoint1: CGPointMake(37.22, 48.04) controlPoint2: CGPointMake(34.05, 43.82)];
    [bezier56Path addCurveToPoint: CGPointMake(27.98, 55.44) controlPoint1: CGPointMake(25.37, 46.81) controlPoint2: CGPointMake(25.78, 49.82)];
    [bezier56Path addCurveToPoint: CGPointMake(33.64, 67.74) controlPoint1: CGPointMake(29.1, 58.31) controlPoint2: CGPointMake(30.28, 60.82)];
    [bezier56Path addCurveToPoint: CGPointMake(34.04, 68.55) controlPoint1: CGPointMake(33.84, 68.15) controlPoint2: CGPointMake(33.84, 68.15)];
    [bezier56Path addCurveToPoint: CGPointMake(39.54, 80.76) controlPoint1: CGPointMake(36.99, 74.63) controlPoint2: CGPointMake(38.49, 77.9)];
    [bezier56Path addCurveToPoint: CGPointMake(39.92, 81.85) controlPoint1: CGPointMake(39.68, 81.15) controlPoint2: CGPointMake(39.8, 81.51)];
    [bezier56Path addCurveToPoint: CGPointMake(38.85, 80.49) controlPoint1: CGPointMake(39.58, 81.46) controlPoint2: CGPointMake(39.23, 81)];
    [bezier56Path addCurveToPoint: CGPointMake(31.84, 68.62) controlPoint1: CGPointMake(37.02, 77.97) controlPoint2: CGPointMake(35.3, 75)];
    [bezier56Path addCurveToPoint: CGPointMake(31.35, 67.71) controlPoint1: CGPointMake(31.6, 68.17) controlPoint2: CGPointMake(31.6, 68.17)];
    [bezier56Path addCurveToPoint: CGPointMake(16.04, 50.48) controlPoint1: CGPointMake(23.42, 53.06) controlPoint2: CGPointMake(20.94, 49.51)];
    [bezier56Path addCurveToPoint: CGPointMake(10.87, 61.22) controlPoint1: CGPointMake(10.59, 51.56) controlPoint2: CGPointMake(9.06, 55.83)];
    [bezier56Path addCurveToPoint: CGPointMake(18.24, 74.4) controlPoint1: CGPointMake(12.01, 64.62) controlPoint2: CGPointMake(14.16, 68.32)];
    [bezier56Path addCurveToPoint: CGPointMake(19.19, 75.82) controlPoint1: CGPointMake(18.52, 74.83) controlPoint2: CGPointMake(18.82, 75.27)];
    [bezier56Path addCurveToPoint: CGPointMake(25.75, 86.23) controlPoint1: CGPointMake(22.83, 81.22) controlPoint2: CGPointMake(24.76, 84.22)];
    [bezier56Path addCurveToPoint: CGPointMake(25.24, 85.76) controlPoint1: CGPointMake(25.58, 86.08) controlPoint2: CGPointMake(25.41, 85.93)];
    [bezier56Path addCurveToPoint: CGPointMake(14.73, 72.4) controlPoint1: CGPointMake(21.38, 82.14) controlPoint2: CGPointMake(16.75, 76.27)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(195.23, 178.98)];
    [bezier56Path addCurveToPoint: CGPointMake(195.48, 180.56) controlPoint1: CGPointMake(194.86, 179.48) controlPoint2: CGPointMake(194.96, 180.18)];
    [bezier56Path addCurveToPoint: CGPointMake(197.06, 180.35) controlPoint1: CGPointMake(195.99, 180.95) controlPoint2: CGPointMake(196.69, 180.85)];
    [bezier56Path addLineToPoint: CGPointMake(205.93, 168.4)];
    [bezier56Path addLineToPoint: CGPointMake(208.66, 164.73)];
    [bezier56Path addCurveToPoint: CGPointMake(207.71, 158.32) controlPoint1: CGPointMake(210.16, 162.7) controlPoint2: CGPointMake(209.73, 159.83)];
    [bezier56Path addCurveToPoint: CGPointMake(201.31, 159.25) controlPoint1: CGPointMake(205.68, 156.81) controlPoint2: CGPointMake(202.81, 157.23)];
    [bezier56Path addLineToPoint: CGPointMake(192.46, 171.18)];
    [bezier56Path addLineToPoint: CGPointMake(189.73, 174.85)];
    [bezier56Path addCurveToPoint: CGPointMake(191.39, 186.07) controlPoint1: CGPointMake(187.09, 178.41) controlPoint2: CGPointMake(187.84, 183.42)];
    [bezier56Path addCurveToPoint: CGPointMake(202.58, 184.44) controlPoint1: CGPointMake(194.93, 188.71) controlPoint2: CGPointMake(199.95, 187.99)];
    [bezier56Path addLineToPoint: CGPointMake(212.12, 171.59)];
    [bezier56Path addCurveToPoint: CGPointMake(215.32, 171.12) controlPoint1: CGPointMake(212.87, 170.58) controlPoint2: CGPointMake(214.3, 170.37)];
    [bezier56Path addCurveToPoint: CGPointMake(215.79, 174.33) controlPoint1: CGPointMake(216.33, 171.88) controlPoint2: CGPointMake(216.54, 173.32)];
    [bezier56Path addLineToPoint: CGPointMake(206.25, 187.18)];
    [bezier56Path addCurveToPoint: CGPointMake(188.67, 189.74) controlPoint1: CGPointMake(202.12, 192.75) controlPoint2: CGPointMake(194.24, 193.9)];
    [bezier56Path addCurveToPoint: CGPointMake(186.06, 172.12) controlPoint1: CGPointMake(183.09, 185.58) controlPoint2: CGPointMake(181.92, 177.7)];
    [bezier56Path addLineToPoint: CGPointMake(188.78, 168.44)];
    [bezier56Path addLineToPoint: CGPointMake(197.64, 156.51)];
    [bezier56Path addCurveToPoint: CGPointMake(210.43, 154.65) controlPoint1: CGPointMake(200.65, 152.46) controlPoint2: CGPointMake(206.38, 151.63)];
    [bezier56Path addCurveToPoint: CGPointMake(212.33, 167.47) controlPoint1: CGPointMake(214.49, 157.67) controlPoint2: CGPointMake(215.34, 163.41)];
    [bezier56Path addLineToPoint: CGPointMake(209.6, 171.14)];
    [bezier56Path addLineToPoint: CGPointMake(200.74, 183.09)];
    [bezier56Path addCurveToPoint: CGPointMake(192.75, 184.24) controlPoint1: CGPointMake(198.86, 185.62) controlPoint2: CGPointMake(195.29, 186.13)];
    [bezier56Path addCurveToPoint: CGPointMake(191.56, 176.24) controlPoint1: CGPointMake(190.22, 182.35) controlPoint2: CGPointMake(189.67, 178.77)];
    [bezier56Path addLineToPoint: CGPointMake(201.12, 163.36)];
    [bezier56Path addCurveToPoint: CGPointMake(204.31, 162.89) controlPoint1: CGPointMake(201.87, 162.34) controlPoint2: CGPointMake(203.3, 162.13)];
    [bezier56Path addCurveToPoint: CGPointMake(204.79, 166.09) controlPoint1: CGPointMake(205.33, 163.65) controlPoint2: CGPointMake(205.54, 165.08)];
    [bezier56Path addLineToPoint: CGPointMake(195.23, 178.98)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(143.2, 312.25)];
    [bezier56Path addLineToPoint: CGPointMake(136.73, 308.49)];
    [bezier56Path addCurveToPoint: CGPointMake(133.38, 309.39) controlPoint1: CGPointMake(135.56, 307.81) controlPoint2: CGPointMake(134.06, 308.21)];
    [bezier56Path addCurveToPoint: CGPointMake(134.28, 312.76) controlPoint1: CGPointMake(132.7, 310.57) controlPoint2: CGPointMake(133.1, 312.08)];
    [bezier56Path addLineToPoint: CGPointMake(140.75, 316.52)];
    [bezier56Path addCurveToPoint: CGPointMake(144.1, 315.62) controlPoint1: CGPointMake(141.92, 317.2) controlPoint2: CGPointMake(143.42, 316.8)];
    [bezier56Path addCurveToPoint: CGPointMake(143.2, 312.25) controlPoint1: CGPointMake(144.78, 314.44) controlPoint2: CGPointMake(144.38, 312.93)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(164.5, 308.5)];
    [bezier56Path addLineToPoint: CGPointMake(158.02, 312.25)];
    [bezier56Path addCurveToPoint: CGPointMake(157.12, 315.62) controlPoint1: CGPointMake(156.85, 312.94) controlPoint2: CGPointMake(156.44, 314.44)];
    [bezier56Path addCurveToPoint: CGPointMake(160.47, 316.53) controlPoint1: CGPointMake(157.8, 316.8) controlPoint2: CGPointMake(159.3, 317.21)];
    [bezier56Path addLineToPoint: CGPointMake(166.95, 312.77)];
    [bezier56Path addCurveToPoint: CGPointMake(167.85, 309.4) controlPoint1: CGPointMake(168.12, 312.09) controlPoint2: CGPointMake(168.52, 310.58)];
    [bezier56Path addCurveToPoint: CGPointMake(164.5, 308.5) controlPoint1: CGPointMake(167.17, 308.22) controlPoint2: CGPointMake(165.67, 307.81)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(150.61, 326.96)];
    [bezier56Path addCurveToPoint: CGPointMake(148.16, 329.43) controlPoint1: CGPointMake(149.25, 326.96) controlPoint2: CGPointMake(148.16, 328.07)];
    [bezier56Path addLineToPoint: CGPointMake(148.15, 336.95)];
    [bezier56Path addCurveToPoint: CGPointMake(150.61, 339.42) controlPoint1: CGPointMake(148.15, 338.31) controlPoint2: CGPointMake(149.25, 339.42)];
    [bezier56Path addCurveToPoint: CGPointMake(153.06, 336.95) controlPoint1: CGPointMake(151.96, 339.42) controlPoint2: CGPointMake(153.06, 338.31)];
    [bezier56Path addLineToPoint: CGPointMake(153.06, 329.43)];
    [bezier56Path addCurveToPoint: CGPointMake(150.61, 326.96) controlPoint1: CGPointMake(153.06, 328.07) controlPoint2: CGPointMake(151.96, 326.96)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(166.94, 326.04)];
    [bezier56Path addLineToPoint: CGPointMake(160.47, 322.28)];
    [bezier56Path addCurveToPoint: CGPointMake(157.12, 323.18) controlPoint1: CGPointMake(159.3, 321.6) controlPoint2: CGPointMake(157.8, 322)];
    [bezier56Path addCurveToPoint: CGPointMake(158.02, 326.55) controlPoint1: CGPointMake(156.44, 324.36) controlPoint2: CGPointMake(156.84, 325.87)];
    [bezier56Path addLineToPoint: CGPointMake(164.49, 330.31)];
    [bezier56Path addCurveToPoint: CGPointMake(167.84, 329.41) controlPoint1: CGPointMake(165.66, 331) controlPoint2: CGPointMake(167.16, 330.59)];
    [bezier56Path addCurveToPoint: CGPointMake(166.94, 326.04) controlPoint1: CGPointMake(168.52, 328.23) controlPoint2: CGPointMake(168.12, 326.72)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(150.61, 299.39)];
    [bezier56Path addCurveToPoint: CGPointMake(148.16, 301.86) controlPoint1: CGPointMake(149.26, 299.39) controlPoint2: CGPointMake(148.16, 300.49)];
    [bezier56Path addLineToPoint: CGPointMake(148.16, 309.37)];
    [bezier56Path addCurveToPoint: CGPointMake(150.61, 311.84) controlPoint1: CGPointMake(148.16, 310.74) controlPoint2: CGPointMake(149.26, 311.84)];
    [bezier56Path addCurveToPoint: CGPointMake(153.07, 309.38) controlPoint1: CGPointMake(151.97, 311.84) controlPoint2: CGPointMake(153.07, 310.74)];
    [bezier56Path addLineToPoint: CGPointMake(153.07, 301.86)];
    [bezier56Path addCurveToPoint: CGPointMake(150.61, 299.39) controlPoint1: CGPointMake(153.07, 300.49) controlPoint2: CGPointMake(151.97, 299.39)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(140.75, 322.28)];
    [bezier56Path addLineToPoint: CGPointMake(134.28, 326.04)];
    [bezier56Path addCurveToPoint: CGPointMake(133.38, 329.41) controlPoint1: CGPointMake(133.1, 326.72) controlPoint2: CGPointMake(132.7, 328.23)];
    [bezier56Path addCurveToPoint: CGPointMake(136.73, 330.31) controlPoint1: CGPointMake(134.05, 330.59) controlPoint2: CGPointMake(135.55, 330.99)];
    [bezier56Path addLineToPoint: CGPointMake(143.2, 326.55)];
    [bezier56Path addCurveToPoint: CGPointMake(144.1, 323.18) controlPoint1: CGPointMake(144.38, 325.87) controlPoint2: CGPointMake(144.78, 324.36)];
    [bezier56Path addCurveToPoint: CGPointMake(140.75, 322.28) controlPoint1: CGPointMake(143.42, 322) controlPoint2: CGPointMake(141.92, 321.6)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(123.08, 264.96)];
    [bezier56Path addCurveToPoint: CGPointMake(129.28, 262.99) controlPoint1: CGPointMake(125.21, 263.98) controlPoint2: CGPointMake(127.35, 263.34)];
    [bezier56Path addLineToPoint: CGPointMake(131.07, 262.66)];
    [bezier56Path addLineToPoint: CGPointMake(131.83, 264.32)];
    [bezier56Path addLineToPoint: CGPointMake(132.96, 266.78)];
    [bezier56Path addCurveToPoint: CGPointMake(134.11, 267.4) controlPoint1: CGPointMake(133.26, 267.45) controlPoint2: CGPointMake(133.25, 267.45)];
    [bezier56Path addCurveToPoint: CGPointMake(137.29, 267.17) controlPoint1: CGPointMake(134.83, 267.35) controlPoint2: CGPointMake(135.82, 267.28)];
    [bezier56Path addCurveToPoint: CGPointMake(142.6, 266.79) controlPoint1: CGPointMake(139.83, 266.98) controlPoint2: CGPointMake(141.29, 266.87)];
    [bezier56Path addCurveToPoint: CGPointMake(143.38, 266.59) controlPoint1: CGPointMake(143.25, 266.76) controlPoint2: CGPointMake(143.33, 266.73)];
    [bezier56Path addCurveToPoint: CGPointMake(143.49, 265.85) controlPoint1: CGPointMake(143.42, 266.49) controlPoint2: CGPointMake(143.45, 266.27)];
    [bezier56Path addCurveToPoint: CGPointMake(139.7, 256.95) controlPoint1: CGPointMake(143.79, 261.69) controlPoint2: CGPointMake(142.23, 257.87)];
    [bezier56Path addCurveToPoint: CGPointMake(120.67, 259.66) controlPoint1: CGPointMake(135.77, 255.51) controlPoint2: CGPointMake(127.73, 256.4)];
    [bezier56Path addCurveToPoint: CGPointMake(106.2, 272.38) controlPoint1: CGPointMake(113.62, 262.9) controlPoint2: CGPointMake(107.69, 268.44)];
    [bezier56Path addLineToPoint: CGPointMake(106.17, 272.44)];
    [bezier56Path addCurveToPoint: CGPointMake(110.37, 281.11) controlPoint1: CGPointMake(105.24, 274.95) controlPoint2: CGPointMake(107.08, 278.63)];
    [bezier56Path addCurveToPoint: CGPointMake(111.69, 281.02) controlPoint1: CGPointMake(111.14, 281.68) controlPoint2: CGPointMake(111.05, 281.69)];
    [bezier56Path addCurveToPoint: CGPointMake(115.4, 277.28) controlPoint1: CGPointMake(112.58, 280.11) controlPoint2: CGPointMake(113.62, 279.06)];
    [bezier56Path addCurveToPoint: CGPointMake(117.65, 274.98) controlPoint1: CGPointMake(116.22, 276.43) controlPoint2: CGPointMake(117.05, 275.58)];
    [bezier56Path addCurveToPoint: CGPointMake(118.16, 274.36) controlPoint1: CGPointMake(118.01, 274.6) controlPoint2: CGPointMake(118.12, 274.46)];
    [bezier56Path addCurveToPoint: CGPointMake(118.12, 274.04) controlPoint1: CGPointMake(118.18, 274.31) controlPoint2: CGPointMake(118.17, 274.21)];
    [bezier56Path addCurveToPoint: CGPointMake(117.97, 273.66) controlPoint1: CGPointMake(118.09, 273.94) controlPoint2: CGPointMake(118.05, 273.85)];
    [bezier56Path addLineToPoint: CGPointMake(116.87, 271.24)];
    [bezier56Path addLineToPoint: CGPointMake(116.11, 269.56)];
    [bezier56Path addLineToPoint: CGPointMake(117.54, 268.41)];
    [bezier56Path addCurveToPoint: CGPointMake(123.08, 264.96) controlPoint1: CGPointMake(119.1, 267.14) controlPoint2: CGPointMake(120.96, 265.93)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(290, 159.99)];
    [bezier56Path addCurveToPoint: CGPointMake(268.5, 160.3) controlPoint1: CGPointMake(285.83, 157.85) controlPoint2: CGPointMake(276.79, 157.71)];
    [bezier56Path addCurveToPoint: CGPointMake(250.68, 172.25) controlPoint1: CGPointMake(260.23, 162.88) controlPoint2: CGPointMake(252.88, 168.13)];
    [bezier56Path addLineToPoint: CGPointMake(250.64, 172.32)];
    [bezier56Path addCurveToPoint: CGPointMake(254.1, 182.44) controlPoint1: CGPointMake(249.26, 174.95) controlPoint2: CGPointMake(250.79, 179.26)];
    [bezier56Path addCurveToPoint: CGPointMake(255.57, 182.53) controlPoint1: CGPointMake(254.87, 183.18) controlPoint2: CGPointMake(254.77, 183.17)];
    [bezier56Path addCurveToPoint: CGPointMake(260.21, 178.93) controlPoint1: CGPointMake(256.68, 181.65) controlPoint2: CGPointMake(257.98, 180.64)];
    [bezier56Path addCurveToPoint: CGPointMake(263.03, 176.72) controlPoint1: CGPointMake(261.24, 178.12) controlPoint2: CGPointMake(262.28, 177.3)];
    [bezier56Path addCurveToPoint: CGPointMake(263.68, 176.11) controlPoint1: CGPointMake(263.48, 176.36) controlPoint2: CGPointMake(263.62, 176.22)];
    [bezier56Path addCurveToPoint: CGPointMake(263.68, 175.76) controlPoint1: CGPointMake(263.71, 176.05) controlPoint2: CGPointMake(263.72, 175.95)];
    [bezier56Path addCurveToPoint: CGPointMake(263.56, 175.32) controlPoint1: CGPointMake(263.66, 175.64) controlPoint2: CGPointMake(263.63, 175.54)];
    [bezier56Path addLineToPoint: CGPointMake(262.68, 172.5)];
    [bezier56Path addLineToPoint: CGPointMake(262.07, 170.55)];
    [bezier56Path addLineToPoint: CGPointMake(263.81, 169.48)];
    [bezier56Path addCurveToPoint: CGPointMake(270.45, 166.46) controlPoint1: CGPointMake(265.73, 168.31) controlPoint2: CGPointMake(267.96, 167.24)];
    [bezier56Path addCurveToPoint: CGPointMake(277.6, 165.17) controlPoint1: CGPointMake(272.94, 165.69) controlPoint2: CGPointMake(275.4, 165.29)];
    [bezier56Path addLineToPoint: CGPointMake(279.63, 165.06)];
    [bezier56Path addLineToPoint: CGPointMake(280.24, 166.99)];
    [bezier56Path addLineToPoint: CGPointMake(281.16, 169.85)];
    [bezier56Path addCurveToPoint: CGPointMake(282.35, 170.69) controlPoint1: CGPointMake(281.39, 170.63) controlPoint2: CGPointMake(281.38, 170.63)];
    [bezier56Path addCurveToPoint: CGPointMake(285.91, 170.88) controlPoint1: CGPointMake(283.15, 170.74) controlPoint2: CGPointMake(284.26, 170.8)];
    [bezier56Path addCurveToPoint: CGPointMake(291.85, 171.21) controlPoint1: CGPointMake(288.75, 171.03) controlPoint2: CGPointMake(290.39, 171.12)];
    [bezier56Path addCurveToPoint: CGPointMake(292.75, 171.1) controlPoint1: CGPointMake(292.58, 171.27) controlPoint2: CGPointMake(292.67, 171.25)];
    [bezier56Path addCurveToPoint: CGPointMake(292.97, 170.3) controlPoint1: CGPointMake(292.8, 171) controlPoint2: CGPointMake(292.87, 170.76)];
    [bezier56Path addCurveToPoint: CGPointMake(290, 159.99) controlPoint1: CGPointMake(293.89, 165.78) controlPoint2: CGPointMake(292.68, 161.36)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(204.91, 230.22)];
    [bezier56Path addLineToPoint: CGPointMake(203.75, 232.16)];
    [bezier56Path addLineToPoint: CGPointMake(209.94, 235.82)];
    [bezier56Path addLineToPoint: CGPointMake(218.56, 221.4)];
    [bezier56Path addLineToPoint: CGPointMake(216.48, 220.18)];
    [bezier56Path addLineToPoint: CGPointMake(212.8, 226.33)];
    [bezier56Path addLineToPoint: CGPointMake(209.22, 224.21)];
    [bezier56Path addLineToPoint: CGPointMake(208.06, 226.16)];
    [bezier56Path addLineToPoint: CGPointMake(211.64, 228.28)];
    [bezier56Path addLineToPoint: CGPointMake(209.02, 232.65)];
    [bezier56Path addLineToPoint: CGPointMake(204.91, 230.22)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(223.7, 241.44)];
    [bezier56Path addCurveToPoint: CGPointMake(224.92, 240.08) controlPoint1: CGPointMake(224.17, 241.11) controlPoint2: CGPointMake(224.57, 240.66)];
    [bezier56Path addLineToPoint: CGPointMake(229.47, 232.46)];
    [bezier56Path addCurveToPoint: CGPointMake(230.09, 230.73) controlPoint1: CGPointMake(229.83, 231.87) controlPoint2: CGPointMake(230.04, 231.29)];
    [bezier56Path addCurveToPoint: CGPointMake(229.94, 229.17) controlPoint1: CGPointMake(230.15, 230.18) controlPoint2: CGPointMake(230.1, 229.65)];
    [bezier56Path addCurveToPoint: CGPointMake(229.22, 227.85) controlPoint1: CGPointMake(229.79, 228.68) controlPoint2: CGPointMake(229.54, 228.24)];
    [bezier56Path addCurveToPoint: CGPointMake(228.1, 226.88) controlPoint1: CGPointMake(228.89, 227.45) controlPoint2: CGPointMake(228.52, 227.13)];
    [bezier56Path addCurveToPoint: CGPointMake(226.71, 226.36) controlPoint1: CGPointMake(227.68, 226.63) controlPoint2: CGPointMake(227.22, 226.46)];
    [bezier56Path addCurveToPoint: CGPointMake(225.2, 226.36) controlPoint1: CGPointMake(226.21, 226.27) controlPoint2: CGPointMake(225.71, 226.27)];
    [bezier56Path addCurveToPoint: CGPointMake(223.74, 226.98) controlPoint1: CGPointMake(224.69, 226.45) controlPoint2: CGPointMake(224.21, 226.66)];
    [bezier56Path addCurveToPoint: CGPointMake(222.51, 228.35) controlPoint1: CGPointMake(223.28, 227.3) controlPoint2: CGPointMake(222.87, 227.75)];
    [bezier56Path addLineToPoint: CGPointMake(219.8, 232.88)];
    [bezier56Path addLineToPoint: CGPointMake(223.52, 235.09)];
    [bezier56Path addLineToPoint: CGPointMake(224.61, 233.26)];
    [bezier56Path addLineToPoint: CGPointMake(222.96, 232.29)];
    [bezier56Path addLineToPoint: CGPointMake(224.59, 229.57)];
    [bezier56Path addCurveToPoint: CGPointMake(225.66, 228.72) controlPoint1: CGPointMake(224.89, 229.08) controlPoint2: CGPointMake(225.25, 228.79)];
    [bezier56Path addCurveToPoint: CGPointMake(226.86, 228.95) controlPoint1: CGPointMake(226.08, 228.65) controlPoint2: CGPointMake(226.48, 228.72)];
    [bezier56Path addCurveToPoint: CGPointMake(227.64, 229.89) controlPoint1: CGPointMake(227.24, 229.17) controlPoint2: CGPointMake(227.5, 229.49)];
    [bezier56Path addCurveToPoint: CGPointMake(227.4, 231.24) controlPoint1: CGPointMake(227.78, 230.29) controlPoint2: CGPointMake(227.7, 230.74)];
    [bezier56Path addLineToPoint: CGPointMake(222.85, 238.85)];
    [bezier56Path addCurveToPoint: CGPointMake(221.77, 239.71) controlPoint1: CGPointMake(222.55, 239.35) controlPoint2: CGPointMake(222.19, 239.64)];
    [bezier56Path addCurveToPoint: CGPointMake(220.57, 239.48) controlPoint1: CGPointMake(221.35, 239.78) controlPoint2: CGPointMake(220.95, 239.7)];
    [bezier56Path addCurveToPoint: CGPointMake(219.79, 238.54) controlPoint1: CGPointMake(220.19, 239.25) controlPoint2: CGPointMake(219.93, 238.94)];
    [bezier56Path addCurveToPoint: CGPointMake(220.04, 237.19) controlPoint1: CGPointMake(219.66, 238.14) controlPoint2: CGPointMake(219.74, 237.69)];
    [bezier56Path addLineToPoint: CGPointMake(220.47, 236.46)];
    [bezier56Path addLineToPoint: CGPointMake(218.39, 235.23)];
    [bezier56Path addLineToPoint: CGPointMake(217.96, 235.96)];
    [bezier56Path addCurveToPoint: CGPointMake(217.34, 237.68) controlPoint1: CGPointMake(217.61, 236.54) controlPoint2: CGPointMake(217.41, 237.11)];
    [bezier56Path addCurveToPoint: CGPointMake(217.49, 239.26) controlPoint1: CGPointMake(217.28, 238.25) controlPoint2: CGPointMake(217.33, 238.77)];
    [bezier56Path addCurveToPoint: CGPointMake(218.21, 240.58) controlPoint1: CGPointMake(217.65, 239.75) controlPoint2: CGPointMake(217.89, 240.19)];
    [bezier56Path addCurveToPoint: CGPointMake(219.33, 241.54) controlPoint1: CGPointMake(218.54, 240.97) controlPoint2: CGPointMake(218.91, 241.29)];
    [bezier56Path addCurveToPoint: CGPointMake(220.72, 242.06) controlPoint1: CGPointMake(219.75, 241.79) controlPoint2: CGPointMake(220.22, 241.96)];
    [bezier56Path addCurveToPoint: CGPointMake(222.23, 242.06) controlPoint1: CGPointMake(221.22, 242.16) controlPoint2: CGPointMake(221.73, 242.16)];
    [bezier56Path addCurveToPoint: CGPointMake(223.7, 241.44) controlPoint1: CGPointMake(222.74, 241.97) controlPoint2: CGPointMake(223.23, 241.76)];
    [bezier56Path addLineToPoint: CGPointMake(223.7, 241.44)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(222.65, 223.82)];
    [bezier56Path addLineToPoint: CGPointMake(220.57, 222.6)];
    [bezier56Path addLineToPoint: CGPointMake(211.96, 237.01)];
    [bezier56Path addLineToPoint: CGPointMake(214.03, 238.24)];
    [bezier56Path addLineToPoint: CGPointMake(222.65, 223.82)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(45.33, 165.61)];
    [bezier56Path addLineToPoint: CGPointMake(43.7, 174.11)];
    [bezier56Path addCurveToPoint: CGPointMake(44.54, 174.8) controlPoint1: CGPointMake(43.61, 174.6) controlPoint2: CGPointMake(44.09, 174.99)];
    [bezier56Path addLineToPoint: CGPointMake(48.89, 172.93)];
    [bezier56Path addLineToPoint: CGPointMake(48.33, 175.86)];
    [bezier56Path addCurveToPoint: CGPointMake(50.1, 178.53) controlPoint1: CGPointMake(48.09, 177.1) controlPoint2: CGPointMake(48.88, 178.29)];
    [bezier56Path addLineToPoint: CGPointMake(60.04, 180.5)];
    [bezier56Path addCurveToPoint: CGPointMake(62.67, 178.7) controlPoint1: CGPointMake(61.25, 180.74) controlPoint2: CGPointMake(62.43, 179.93)];
    [bezier56Path addLineToPoint: CGPointMake(64.6, 168.59)];
    [bezier56Path addCurveToPoint: CGPointMake(62.83, 165.92) controlPoint1: CGPointMake(64.84, 167.36) controlPoint2: CGPointMake(64.05, 166.17)];
    [bezier56Path addLineToPoint: CGPointMake(52.89, 163.96)];
    [bezier56Path addCurveToPoint: CGPointMake(50.26, 165.76) controlPoint1: CGPointMake(51.68, 163.72) controlPoint2: CGPointMake(50.5, 164.52)];
    [bezier56Path addLineToPoint: CGPointMake(49.7, 168.69)];
    [bezier56Path addLineToPoint: CGPointMake(46.36, 165.29)];
    [bezier56Path addCurveToPoint: CGPointMake(45.33, 165.61) controlPoint1: CGPointMake(46.01, 164.94) controlPoint2: CGPointMake(45.42, 165.13)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(20.67, 125.27)];
    [bezier56Path addLineToPoint: CGPointMake(20.67, 125.27)];
    [bezier56Path addCurveToPoint: CGPointMake(32.34, 113.61) controlPoint1: CGPointMake(27.12, 125.27) controlPoint2: CGPointMake(32.34, 120.05)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 101.95) controlPoint1: CGPointMake(32.34, 107.17) controlPoint2: CGPointMake(27.12, 101.95)];
    [bezier56Path addCurveToPoint: CGPointMake(9, 113.61) controlPoint1: CGPointMake(14.23, 101.95) controlPoint2: CGPointMake(9, 107.17)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 125.27) controlPoint1: CGPointMake(9, 120.05) controlPoint2: CGPointMake(14.23, 125.27)];
    [bezier56Path addLineToPoint: CGPointMake(20.67, 125.27)];
    [bezier56Path addLineToPoint: CGPointMake(20.67, 125.27)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(20.67, 126.94)];
    [bezier56Path addCurveToPoint: CGPointMake(7.33, 113.61) controlPoint1: CGPointMake(13.3, 126.94) controlPoint2: CGPointMake(7.33, 120.97)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 100.28) controlPoint1: CGPointMake(7.33, 106.25) controlPoint2: CGPointMake(13.3, 100.28)];
    [bezier56Path addCurveToPoint: CGPointMake(34.01, 113.61) controlPoint1: CGPointMake(28.04, 100.28) controlPoint2: CGPointMake(34.01, 106.25)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 126.94) controlPoint1: CGPointMake(34.01, 120.97) controlPoint2: CGPointMake(28.04, 126.94)];
    [bezier56Path addLineToPoint: CGPointMake(20.67, 126.94)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(20.67, 123.6)];
    [bezier56Path addCurveToPoint: CGPointMake(30.68, 113.61) controlPoint1: CGPointMake(26.2, 123.6) controlPoint2: CGPointMake(30.68, 119.13)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 103.61) controlPoint1: CGPointMake(30.68, 108.09) controlPoint2: CGPointMake(26.2, 103.61)];
    [bezier56Path addCurveToPoint: CGPointMake(10.67, 113.61) controlPoint1: CGPointMake(15.15, 103.61) controlPoint2: CGPointMake(10.67, 108.09)];
    [bezier56Path addCurveToPoint: CGPointMake(20.67, 123.6) controlPoint1: CGPointMake(10.67, 119.13) controlPoint2: CGPointMake(15.15, 123.6)];
    [bezier56Path addLineToPoint: CGPointMake(20.67, 123.6)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(287.78, 179.35)];
    [bezier56Path addLineToPoint: CGPointMake(279.57, 178.09)];
    [bezier56Path addCurveToPoint: CGPointMake(278.2, 179.08) controlPoint1: CGPointMake(278.92, 177.99) controlPoint2: CGPointMake(278.31, 178.43)];
    [bezier56Path addCurveToPoint: CGPointMake(279.18, 180.42) controlPoint1: CGPointMake(278.09, 179.72) controlPoint2: CGPointMake(278.53, 180.32)];
    [bezier56Path addLineToPoint: CGPointMake(287.4, 181.68)];
    [bezier56Path addCurveToPoint: CGPointMake(290.84, 186.39) controlPoint1: CGPointMake(289.67, 182.03) controlPoint2: CGPointMake(291.21, 184.14)];
    [bezier56Path addCurveToPoint: CGPointMake(286.06, 189.83) controlPoint1: CGPointMake(290.47, 188.64) controlPoint2: CGPointMake(288.33, 190.18)];
    [bezier56Path addLineToPoint: CGPointMake(283.71, 189.47)];
    [bezier56Path addLineToPoint: CGPointMake(276.08, 188.31)];
    [bezier56Path addCurveToPoint: CGPointMake(274.11, 185.62) controlPoint1: CGPointMake(274.78, 188.11) controlPoint2: CGPointMake(273.9, 186.9)];
    [bezier56Path addCurveToPoint: CGPointMake(276.84, 183.65) controlPoint1: CGPointMake(274.33, 184.33) controlPoint2: CGPointMake(275.55, 183.45)];
    [bezier56Path addLineToPoint: CGPointMake(279.2, 184.01)];
    [bezier56Path addLineToPoint: CGPointMake(286.84, 185.18)];
    [bezier56Path addCurveToPoint: CGPointMake(287.32, 185.85) controlPoint1: CGPointMake(287.16, 185.22) controlPoint2: CGPointMake(287.37, 185.52)];
    [bezier56Path addCurveToPoint: CGPointMake(286.64, 186.34) controlPoint1: CGPointMake(287.26, 186.17) controlPoint2: CGPointMake(286.96, 186.39)];
    [bezier56Path addLineToPoint: CGPointMake(278.4, 185.08)];
    [bezier56Path addCurveToPoint: CGPointMake(277.04, 186.06) controlPoint1: CGPointMake(277.76, 184.98) controlPoint2: CGPointMake(277.14, 185.42)];
    [bezier56Path addCurveToPoint: CGPointMake(278.02, 187.41) controlPoint1: CGPointMake(276.93, 186.71) controlPoint2: CGPointMake(277.37, 187.31)];
    [bezier56Path addLineToPoint: CGPointMake(286.26, 188.67)];
    [bezier56Path addCurveToPoint: CGPointMake(289.66, 186.21) controlPoint1: CGPointMake(287.88, 188.92) controlPoint2: CGPointMake(289.4, 187.81)];
    [bezier56Path addCurveToPoint: CGPointMake(287.22, 182.85) controlPoint1: CGPointMake(289.93, 184.59) controlPoint2: CGPointMake(288.84, 183.09)];
    [bezier56Path addLineToPoint: CGPointMake(279.58, 181.68)];
    [bezier56Path addLineToPoint: CGPointMake(277.23, 181.32)];
    [bezier56Path addCurveToPoint: CGPointMake(271.77, 185.26) controlPoint1: CGPointMake(274.64, 180.92) controlPoint2: CGPointMake(272.19, 182.68)];
    [bezier56Path addCurveToPoint: CGPointMake(275.69, 190.64) controlPoint1: CGPointMake(271.34, 187.83) controlPoint2: CGPointMake(273.1, 190.24)];
    [bezier56Path addLineToPoint: CGPointMake(283.33, 191.8)];
    [bezier56Path addLineToPoint: CGPointMake(285.68, 192.16)];
    [bezier56Path addCurveToPoint: CGPointMake(293.19, 186.75) controlPoint1: CGPointMake(289.24, 192.71) controlPoint2: CGPointMake(292.6, 190.29)];
    [bezier56Path addCurveToPoint: CGPointMake(287.78, 179.35) controlPoint1: CGPointMake(293.77, 183.21) controlPoint2: CGPointMake(291.35, 179.9)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(31.34, 238.09)];
    [bezier56Path addLineToPoint: CGPointMake(35.19, 236.15)];
    [bezier56Path addLineToPoint: CGPointMake(27.26, 233.5)];
    [bezier56Path addLineToPoint: CGPointMake(29.24, 237.47)];
    [bezier56Path addCurveToPoint: CGPointMake(31.34, 238.09) controlPoint1: CGPointMake(29.7, 238.18) controlPoint2: CGPointMake(30.6, 238.46)];
    [bezier56Path addLineToPoint: CGPointMake(31.34, 238.09)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(35.72, 237.21)];
    [bezier56Path addLineToPoint: CGPointMake(31.52, 239.33)];
    [bezier56Path addCurveToPoint: CGPointMake(28.32, 238.28) controlPoint1: CGPointMake(30.34, 239.92) controlPoint2: CGPointMake(28.91, 239.47)];
    [bezier56Path addLineToPoint: CGPointMake(26.2, 234.03)];
    [bezier56Path addLineToPoint: CGPointMake(20.92, 236.7)];
    [bezier56Path addCurveToPoint: CGPointMake(20.4, 238.29) controlPoint1: CGPointMake(20.34, 236.99) controlPoint2: CGPointMake(20.11, 237.7)];
    [bezier56Path addLineToPoint: CGPointMake(27.82, 253.17)];
    [bezier56Path addCurveToPoint: CGPointMake(29.41, 253.69) controlPoint1: CGPointMake(28.11, 253.75) controlPoint2: CGPointMake(28.83, 253.99)];
    [bezier56Path addLineToPoint: CGPointMake(39.96, 248.37)];
    [bezier56Path addCurveToPoint: CGPointMake(40.49, 246.78) controlPoint1: CGPointMake(40.54, 248.07) controlPoint2: CGPointMake(40.77, 247.35)];
    [bezier56Path addLineToPoint: CGPointMake(35.72, 237.21)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(172.05, 129.62)];
    [bezier56Path addLineToPoint: CGPointMake(172.42, 131.95)];
    [bezier56Path addCurveToPoint: CGPointMake(183.92, 143.74) controlPoint1: CGPointMake(173.4, 138.08) controlPoint2: CGPointMake(178.15, 142.68)];
    [bezier56Path addLineToPoint: CGPointMake(185.17, 151.6)];
    [bezier56Path addLineToPoint: CGPointMake(192.83, 143.14)];
    [bezier56Path addLineToPoint: CGPointMake(198.09, 142.29)];
    [bezier56Path addCurveToPoint: CGPointMake(209.9, 125.93) controlPoint1: CGPointMake(205.88, 141.04) controlPoint2: CGPointMake(211.14, 133.72)];
    [bezier56Path addLineToPoint: CGPointMake(209.53, 123.6)];
    [bezier56Path addCurveToPoint: CGPointMake(193.22, 111.75) controlPoint1: CGPointMake(208.28, 115.82) controlPoint2: CGPointMake(200.98, 110.51)];
    [bezier56Path addLineToPoint: CGPointMake(183.86, 113.26)];
    [bezier56Path addCurveToPoint: CGPointMake(172.05, 129.62) controlPoint1: CGPointMake(176.07, 114.51) controlPoint2: CGPointMake(170.81, 121.83)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(24.21, 203.93)];
    [bezier56Path addCurveToPoint: CGPointMake(25.91, 201.85) controlPoint1: CGPointMake(25.25, 203.83) controlPoint2: CGPointMake(26.01, 202.9)];
    [bezier56Path addLineToPoint: CGPointMake(25.36, 196.07)];
    [bezier56Path addCurveToPoint: CGPointMake(23.29, 194.36) controlPoint1: CGPointMake(25.26, 195.03) controlPoint2: CGPointMake(24.34, 194.26)];
    [bezier56Path addCurveToPoint: CGPointMake(21.59, 196.44) controlPoint1: CGPointMake(22.25, 194.46) controlPoint2: CGPointMake(21.49, 195.39)];
    [bezier56Path addLineToPoint: CGPointMake(22.14, 202.22)];
    [bezier56Path addCurveToPoint: CGPointMake(24.21, 203.93) controlPoint1: CGPointMake(22.24, 203.26) controlPoint2: CGPointMake(23.16, 204.03)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(23.89, 180.66)];
    [bezier56Path addLineToPoint: CGPointMake(23.34, 174.88)];
    [bezier56Path addCurveToPoint: CGPointMake(21.27, 173.16) controlPoint1: CGPointMake(23.24, 173.83) controlPoint2: CGPointMake(22.32, 173.06)];
    [bezier56Path addCurveToPoint: CGPointMake(19.56, 175.24) controlPoint1: CGPointMake(20.23, 173.26) controlPoint2: CGPointMake(19.46, 174.19)];
    [bezier56Path addLineToPoint: CGPointMake(20.12, 181.02)];
    [bezier56Path addCurveToPoint: CGPointMake(22.19, 182.73) controlPoint1: CGPointMake(20.22, 182.07) controlPoint2: CGPointMake(21.14, 182.83)];
    [bezier56Path addCurveToPoint: CGPointMake(23.89, 180.66) controlPoint1: CGPointMake(23.23, 182.63) controlPoint2: CGPointMake(23.99, 181.7)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(32.63, 179.13)];
    [bezier56Path addLineToPoint: CGPointMake(27.92, 182.5)];
    [bezier56Path addCurveToPoint: CGPointMake(27.47, 185.16) controlPoint1: CGPointMake(27.07, 183.11) controlPoint2: CGPointMake(26.87, 184.3)];
    [bezier56Path addCurveToPoint: CGPointMake(30.12, 185.6) controlPoint1: CGPointMake(28.08, 186.02) controlPoint2: CGPointMake(29.27, 186.22)];
    [bezier56Path addLineToPoint: CGPointMake(34.83, 182.23)];
    [bezier56Path addCurveToPoint: CGPointMake(35.27, 179.58) controlPoint1: CGPointMake(35.68, 181.62) controlPoint2: CGPointMake(35.88, 180.43)];
    [bezier56Path addCurveToPoint: CGPointMake(32.63, 179.13) controlPoint1: CGPointMake(34.67, 178.72) controlPoint2: CGPointMake(33.48, 178.52)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(28.03, 190.97)];
    [bezier56Path addCurveToPoint: CGPointMake(28.97, 193.49) controlPoint1: CGPointMake(27.59, 191.93) controlPoint2: CGPointMake(28.01, 193.06)];
    [bezier56Path addLineToPoint: CGPointMake(34.23, 195.91)];
    [bezier56Path addCurveToPoint: CGPointMake(36.74, 194.96) controlPoint1: CGPointMake(35.18, 196.34) controlPoint2: CGPointMake(36.31, 195.92)];
    [bezier56Path addCurveToPoint: CGPointMake(35.8, 192.44) controlPoint1: CGPointMake(37.18, 194.01) controlPoint2: CGPointMake(36.76, 192.88)];
    [bezier56Path addLineToPoint: CGPointMake(30.54, 190.03)];
    [bezier56Path addCurveToPoint: CGPointMake(28.03, 190.97) controlPoint1: CGPointMake(29.59, 189.59) controlPoint2: CGPointMake(28.46, 190.01)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(18.01, 191.93)];
    [bezier56Path addCurveToPoint: CGPointMake(15.36, 191.49) controlPoint1: CGPointMake(17.4, 191.08) controlPoint2: CGPointMake(16.21, 190.88)];
    [bezier56Path addLineToPoint: CGPointMake(10.65, 194.86)];
    [bezier56Path addCurveToPoint: CGPointMake(10.2, 197.52) controlPoint1: CGPointMake(9.8, 195.47) controlPoint2: CGPointMake(9.6, 196.66)];
    [bezier56Path addCurveToPoint: CGPointMake(12.85, 197.96) controlPoint1: CGPointMake(10.81, 198.37) controlPoint2: CGPointMake(12, 198.57)];
    [bezier56Path addLineToPoint: CGPointMake(17.56, 194.59)];
    [bezier56Path addCurveToPoint: CGPointMake(18.01, 191.93) controlPoint1: CGPointMake(18.41, 193.98) controlPoint2: CGPointMake(18.61, 192.79)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(17.45, 186.12)];
    [bezier56Path addCurveToPoint: CGPointMake(16.51, 183.6) controlPoint1: CGPointMake(17.89, 185.17) controlPoint2: CGPointMake(17.47, 184.04)];
    [bezier56Path addLineToPoint: CGPointMake(11.25, 181.19)];
    [bezier56Path addCurveToPoint: CGPointMake(8.74, 182.13) controlPoint1: CGPointMake(10.3, 180.75) controlPoint2: CGPointMake(9.17, 181.17)];
    [bezier56Path addCurveToPoint: CGPointMake(9.68, 184.65) controlPoint1: CGPointMake(8.3, 183.09) controlPoint2: CGPointMake(8.72, 184.22)];
    [bezier56Path addLineToPoint: CGPointMake(14.94, 187.06)];
    [bezier56Path addCurveToPoint: CGPointMake(17.45, 186.12) controlPoint1: CGPointMake(15.89, 187.5) controlPoint2: CGPointMake(17.02, 187.08)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(117.94, 314.36)];
    [bezier56Path addLineToPoint: CGPointMake(111.99, 327.02)];
    [bezier56Path addLineToPoint: CGPointMake(113.79, 327.88)];
    [bezier56Path addLineToPoint: CGPointMake(119.75, 315.22)];
    [bezier56Path addLineToPoint: CGPointMake(117.94, 314.36)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(115.55, 328.71)];
    [bezier56Path addLineToPoint: CGPointMake(117.35, 329.56)];
    [bezier56Path addLineToPoint: CGPointMake(119.9, 324.16)];
    [bezier56Path addLineToPoint: CGPointMake(123.01, 325.64)];
    [bezier56Path addLineToPoint: CGPointMake(123.82, 323.93)];
    [bezier56Path addLineToPoint: CGPointMake(120.7, 322.45)];
    [bezier56Path addLineToPoint: CGPointMake(122.51, 318.61)];
    [bezier56Path addLineToPoint: CGPointMake(126.08, 320.31)];
    [bezier56Path addLineToPoint: CGPointMake(126.89, 318.6)];
    [bezier56Path addLineToPoint: CGPointMake(121.5, 316.05)];
    [bezier56Path addLineToPoint: CGPointMake(115.55, 328.71)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(110.38, 317.73)];
    [bezier56Path addLineToPoint: CGPointMake(109.63, 319.33)];
    [bezier56Path addLineToPoint: CGPointMake(111.06, 320.01)];
    [bezier56Path addLineToPoint: CGPointMake(109.94, 322.4)];
    [bezier56Path addCurveToPoint: CGPointMake(109.12, 323.19) controlPoint1: CGPointMake(109.73, 322.83) controlPoint2: CGPointMake(109.46, 323.1)];
    [bezier56Path addCurveToPoint: CGPointMake(108.12, 323.1) controlPoint1: CGPointMake(108.78, 323.29) controlPoint2: CGPointMake(108.45, 323.25)];
    [bezier56Path addCurveToPoint: CGPointMake(107.4, 322.38) controlPoint1: CGPointMake(107.79, 322.94) controlPoint2: CGPointMake(107.55, 322.7)];
    [bezier56Path addCurveToPoint: CGPointMake(107.5, 321.24) controlPoint1: CGPointMake(107.26, 322.06) controlPoint2: CGPointMake(107.29, 321.68)];
    [bezier56Path addLineToPoint: CGPointMake(110.64, 314.55)];
    [bezier56Path addCurveToPoint: CGPointMake(111.46, 313.76) controlPoint1: CGPointMake(110.85, 314.12) controlPoint2: CGPointMake(111.12, 313.85)];
    [bezier56Path addCurveToPoint: CGPointMake(112.47, 313.85) controlPoint1: CGPointMake(111.8, 313.67) controlPoint2: CGPointMake(112.14, 313.7)];
    [bezier56Path addCurveToPoint: CGPointMake(113.18, 314.57) controlPoint1: CGPointMake(112.8, 314.01) controlPoint2: CGPointMake(113.03, 314.25)];
    [bezier56Path addCurveToPoint: CGPointMake(113.09, 315.71) controlPoint1: CGPointMake(113.32, 314.89) controlPoint2: CGPointMake(113.29, 315.27)];
    [bezier56Path addLineToPoint: CGPointMake(112.78, 316.35)];
    [bezier56Path addLineToPoint: CGPointMake(114.59, 317.21)];
    [bezier56Path addLineToPoint: CGPointMake(114.89, 316.57)];
    [bezier56Path addCurveToPoint: CGPointMake(115.26, 315.09) controlPoint1: CGPointMake(115.13, 316.06) controlPoint2: CGPointMake(115.25, 315.57)];
    [bezier56Path addCurveToPoint: CGPointMake(115.02, 313.79) controlPoint1: CGPointMake(115.27, 314.62) controlPoint2: CGPointMake(115.19, 314.18)];
    [bezier56Path addCurveToPoint: CGPointMake(114.32, 312.75) controlPoint1: CGPointMake(114.85, 313.4) controlPoint2: CGPointMake(114.61, 313.05)];
    [bezier56Path addCurveToPoint: CGPointMake(113.32, 312.04) controlPoint1: CGPointMake(114.02, 312.45) controlPoint2: CGPointMake(113.68, 312.21)];
    [bezier56Path addCurveToPoint: CGPointMake(112.14, 311.72) controlPoint1: CGPointMake(112.95, 311.87) controlPoint2: CGPointMake(112.56, 311.76)];
    [bezier56Path addCurveToPoint: CGPointMake(110.89, 311.84) controlPoint1: CGPointMake(111.72, 311.68) controlPoint2: CGPointMake(111.3, 311.72)];
    [bezier56Path addCurveToPoint: CGPointMake(109.74, 312.47) controlPoint1: CGPointMake(110.48, 311.95) controlPoint2: CGPointMake(110.1, 312.17)];
    [bezier56Path addCurveToPoint: CGPointMake(108.84, 313.7) controlPoint1: CGPointMake(109.38, 312.78) controlPoint2: CGPointMake(109.08, 313.19)];
    [bezier56Path addLineToPoint: CGPointMake(105.69, 320.38)];
    [bezier56Path addCurveToPoint: CGPointMake(105.32, 321.87) controlPoint1: CGPointMake(105.45, 320.9) controlPoint2: CGPointMake(105.32, 321.4)];
    [bezier56Path addCurveToPoint: CGPointMake(105.56, 323.16) controlPoint1: CGPointMake(105.31, 322.34) controlPoint2: CGPointMake(105.4, 322.77)];
    [bezier56Path addCurveToPoint: CGPointMake(106.27, 324.2) controlPoint1: CGPointMake(105.73, 323.55) controlPoint2: CGPointMake(105.97, 323.9)];
    [bezier56Path addCurveToPoint: CGPointMake(107.26, 324.91) controlPoint1: CGPointMake(106.57, 324.5) controlPoint2: CGPointMake(106.9, 324.74)];
    [bezier56Path addCurveToPoint: CGPointMake(108.44, 325.23) controlPoint1: CGPointMake(107.63, 325.08) controlPoint2: CGPointMake(108.02, 325.19)];
    [bezier56Path addCurveToPoint: CGPointMake(109.69, 325.11) controlPoint1: CGPointMake(108.87, 325.27) controlPoint2: CGPointMake(109.28, 325.23)];
    [bezier56Path addCurveToPoint: CGPointMake(110.84, 324.49) controlPoint1: CGPointMake(110.1, 325) controlPoint2: CGPointMake(110.48, 324.79)];
    [bezier56Path addCurveToPoint: CGPointMake(111.75, 323.25) controlPoint1: CGPointMake(111.2, 324.18) controlPoint2: CGPointMake(111.5, 323.77)];
    [bezier56Path addLineToPoint: CGPointMake(113.62, 319.27)];
    [bezier56Path addLineToPoint: CGPointMake(110.38, 317.73)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(262.4, 43.53)];
    [bezier56Path addCurveToPoint: CGPointMake(255.56, 36.7) controlPoint1: CGPointMake(262.4, 39.76) controlPoint2: CGPointMake(259.34, 36.7)];
    [bezier56Path addCurveToPoint: CGPointMake(248.73, 43.53) controlPoint1: CGPointMake(251.79, 36.7) controlPoint2: CGPointMake(248.73, 39.76)];
    [bezier56Path addCurveToPoint: CGPointMake(255.56, 54.91) controlPoint1: CGPointMake(248.73, 50.36) controlPoint2: CGPointMake(255.56, 54.91)];
    [bezier56Path addCurveToPoint: CGPointMake(262.4, 43.53) controlPoint1: CGPointMake(255.56, 54.91) controlPoint2: CGPointMake(262.4, 50.36)];
    [bezier56Path addLineToPoint: CGPointMake(262.4, 43.53)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(255.56, 46.95)];
    [bezier56Path addCurveToPoint: CGPointMake(258.98, 43.53) controlPoint1: CGPointMake(257.45, 46.95) controlPoint2: CGPointMake(258.98, 45.42)];
    [bezier56Path addCurveToPoint: CGPointMake(255.56, 40.12) controlPoint1: CGPointMake(258.98, 41.65) controlPoint2: CGPointMake(257.45, 40.12)];
    [bezier56Path addCurveToPoint: CGPointMake(252.15, 43.53) controlPoint1: CGPointMake(253.68, 40.12) controlPoint2: CGPointMake(252.15, 41.65)];
    [bezier56Path addCurveToPoint: CGPointMake(255.56, 46.95) controlPoint1: CGPointMake(252.15, 45.42) controlPoint2: CGPointMake(253.68, 46.95)];
    [bezier56Path addLineToPoint: CGPointMake(255.56, 46.95)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(125.39, 80.34)];
    [bezier56Path addLineToPoint: CGPointMake(125.39, 85.23)];
    [bezier56Path addCurveToPoint: CGPointMake(110.56, 79.47) controlPoint1: CGPointMake(120.09, 85.48) controlPoint2: CGPointMake(114.66, 83.56)];
    [bezier56Path addCurveToPoint: CGPointMake(104.8, 64.65) controlPoint1: CGPointMake(106.47, 75.37) controlPoint2: CGPointMake(104.55, 69.95)];
    [bezier56Path addLineToPoint: CGPointMake(104.8, 64.65)];
    [bezier56Path addLineToPoint: CGPointMake(109.69, 64.65)];
    [bezier56Path addCurveToPoint: CGPointMake(114.02, 76.02) controlPoint1: CGPointMake(109.44, 68.7) controlPoint2: CGPointMake(110.88, 72.88)];
    [bezier56Path addCurveToPoint: CGPointMake(125.39, 80.34) controlPoint1: CGPointMake(117.16, 79.15) controlPoint2: CGPointMake(121.34, 80.59)];
    [bezier56Path addLineToPoint: CGPointMake(125.39, 80.34)];
    [bezier56Path addLineToPoint: CGPointMake(125.39, 80.34)];
    [bezier56Path addLineToPoint: CGPointMake(125.39, 80.34)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(117.47, 72.56)];
    [bezier56Path addCurveToPoint: CGPointMake(131.17, 72.68) controlPoint1: CGPointMake(121.29, 76.38) controlPoint2: CGPointMake(127.44, 76.41)];
    [bezier56Path addLineToPoint: CGPointMake(138.31, 65.55)];
    [bezier56Path addCurveToPoint: CGPointMake(138.2, 51.85) controlPoint1: CGPointMake(142.05, 61.81) controlPoint2: CGPointMake(142.02, 55.67)];
    [bezier56Path addCurveToPoint: CGPointMake(124.49, 51.74) controlPoint1: CGPointMake(134.38, 48.03) controlPoint2: CGPointMake(128.23, 48)];
    [bezier56Path addLineToPoint: CGPointMake(117.36, 58.87)];
    [bezier56Path addCurveToPoint: CGPointMake(117.47, 72.56) controlPoint1: CGPointMake(113.62, 62.6) controlPoint2: CGPointMake(113.65, 68.74)];
    [bezier56Path addLineToPoint: CGPointMake(117.47, 72.56)];
    [bezier56Path addLineToPoint: CGPointMake(117.47, 72.56)];
    [bezier56Path addLineToPoint: CGPointMake(117.47, 72.56)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(103.35, 37.66)];
    [bezier56Path addLineToPoint: CGPointMake(104.35, 40.67)];
    [bezier56Path addCurveToPoint: CGPointMake(115.37, 46.26) controlPoint1: CGPointMake(105.87, 45.24) controlPoint2: CGPointMake(110.8, 47.74)];
    [bezier56Path addCurveToPoint: CGPointMake(120.89, 35.3) controlPoint1: CGPointMake(119.93, 44.78) controlPoint2: CGPointMake(122.41, 39.87)];
    [bezier56Path addLineToPoint: CGPointMake(117.39, 24.77)];
    [bezier56Path addCurveToPoint: CGPointMake(115.39, 23.75) controlPoint1: CGPointMake(117.12, 23.94) controlPoint2: CGPointMake(116.22, 23.48)];
    [bezier56Path addCurveToPoint: CGPointMake(114.38, 25.74) controlPoint1: CGPointMake(114.56, 24.02) controlPoint2: CGPointMake(114.11, 24.91)];
    [bezier56Path addLineToPoint: CGPointMake(117.88, 36.28)];
    [bezier56Path addCurveToPoint: CGPointMake(114.37, 43.25) controlPoint1: CGPointMake(118.85, 39.18) controlPoint2: CGPointMake(117.27, 42.31)];
    [bezier56Path addCurveToPoint: CGPointMake(107.35, 39.69) controlPoint1: CGPointMake(111.46, 44.2) controlPoint2: CGPointMake(108.32, 42.61)];
    [bezier56Path addLineToPoint: CGPointMake(106.35, 36.68)];
    [bezier56Path addLineToPoint: CGPointMake(103.1, 26.9)];
    [bezier56Path addCurveToPoint: CGPointMake(105.11, 22.91) controlPoint1: CGPointMake(102.55, 25.24) controlPoint2: CGPointMake(103.45, 23.45)];
    [bezier56Path addCurveToPoint: CGPointMake(109.12, 24.95) controlPoint1: CGPointMake(106.77, 22.38) controlPoint2: CGPointMake(108.57, 23.29)];
    [bezier56Path addLineToPoint: CGPointMake(110.12, 27.96)];
    [bezier56Path addLineToPoint: CGPointMake(113.38, 37.75)];
    [bezier56Path addCurveToPoint: CGPointMake(112.87, 38.74) controlPoint1: CGPointMake(113.51, 38.16) controlPoint2: CGPointMake(113.29, 38.6)];
    [bezier56Path addCurveToPoint: CGPointMake(111.87, 38.24) controlPoint1: CGPointMake(112.45, 38.87) controlPoint2: CGPointMake(112.01, 38.65)];
    [bezier56Path addLineToPoint: CGPointMake(108.36, 27.68)];
    [bezier56Path addCurveToPoint: CGPointMake(106.36, 26.66) controlPoint1: CGPointMake(108.09, 26.85) controlPoint2: CGPointMake(107.19, 26.39)];
    [bezier56Path addCurveToPoint: CGPointMake(105.35, 28.65) controlPoint1: CGPointMake(105.53, 26.93) controlPoint2: CGPointMake(105.08, 27.82)];
    [bezier56Path addLineToPoint: CGPointMake(108.86, 39.22)];
    [bezier56Path addCurveToPoint: CGPointMake(113.87, 41.75) controlPoint1: CGPointMake(109.55, 41.3) controlPoint2: CGPointMake(111.79, 42.42)];
    [bezier56Path addCurveToPoint: CGPointMake(116.38, 36.78) controlPoint1: CGPointMake(115.95, 41.07) controlPoint2: CGPointMake(117.07, 38.85)];
    [bezier56Path addLineToPoint: CGPointMake(113.13, 26.98)];
    [bezier56Path addLineToPoint: CGPointMake(112.13, 23.97)];
    [bezier56Path addCurveToPoint: CGPointMake(104.11, 19.9) controlPoint1: CGPointMake(111.02, 20.65) controlPoint2: CGPointMake(107.44, 18.83)];
    [bezier56Path addCurveToPoint: CGPointMake(100.1, 27.87) controlPoint1: CGPointMake(100.79, 20.98) controlPoint2: CGPointMake(98.99, 24.55)];
    [bezier56Path addLineToPoint: CGPointMake(103.35, 37.66)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(140.62, 165.25)];
    [bezier56Path addCurveToPoint: CGPointMake(140.95, 162.83) controlPoint1: CGPointMake(141.61, 164.29) controlPoint2: CGPointMake(141.61, 164.31)];
    [bezier56Path addCurveToPoint: CGPointMake(138.44, 157.39) controlPoint1: CGPointMake(140.4, 161.6) controlPoint2: CGPointMake(139.61, 159.9)];
    [bezier56Path addCurveToPoint: CGPointMake(134.26, 148.31) controlPoint1: CGPointMake(136.42, 153.06) controlPoint2: CGPointMake(135.27, 150.55)];
    [bezier56Path addCurveToPoint: CGPointMake(133.39, 147.06) controlPoint1: CGPointMake(133.78, 147.19) controlPoint2: CGPointMake(133.66, 147.06)];
    [bezier56Path addCurveToPoint: CGPointMake(132.01, 147.36) controlPoint1: CGPointMake(133.18, 147.06) controlPoint2: CGPointMake(132.77, 147.15)];
    [bezier56Path addCurveToPoint: CGPointMake(118.87, 159.78) controlPoint1: CGPointMake(124.5, 149.52) controlPoint2: CGPointMake(118.83, 154.75)];
    [bezier56Path addCurveToPoint: CGPointMake(136.25, 191.47) controlPoint1: CGPointMake(118.95, 167.64) controlPoint2: CGPointMake(125.85, 181.17)];
    [bezier56Path addCurveToPoint: CGPointMake(168.21, 208.64) controlPoint1: CGPointMake(146.63, 201.75) controlPoint2: CGPointMake(160.29, 208.57)];
    [bezier56Path addLineToPoint: CGPointMake(168.33, 208.64)];
    [bezier56Path addCurveToPoint: CGPointMake(180.8, 195.64) controlPoint1: CGPointMake(173.37, 208.64) controlPoint2: CGPointMake(178.62, 203.03)];
    [bezier56Path addCurveToPoint: CGPointMake(179.77, 193.38) controlPoint1: CGPointMake(181.3, 193.92) controlPoint2: CGPointMake(181.37, 194.07)];
    [bezier56Path addCurveToPoint: CGPointMake(170.73, 189.29) controlPoint1: CGPointMake(177.58, 192.41) controlPoint2: CGPointMake(175.05, 191.26)];
    [bezier56Path addCurveToPoint: CGPointMake(165.19, 186.83) controlPoint1: CGPointMake(168.7, 188.4) controlPoint2: CGPointMake(166.64, 187.48)];
    [bezier56Path addCurveToPoint: CGPointMake(163.77, 186.34) controlPoint1: CGPointMake(164.29, 186.43) controlPoint2: CGPointMake(163.97, 186.34)];
    [bezier56Path addCurveToPoint: CGPointMake(163.24, 186.61) controlPoint1: CGPointMake(163.66, 186.34) controlPoint2: CGPointMake(163.5, 186.4)];
    [bezier56Path addCurveToPoint: CGPointMake(162.67, 187.13) controlPoint1: CGPointMake(163.08, 186.73) controlPoint2: CGPointMake(162.94, 186.85)];
    [bezier56Path addLineToPoint: CGPointMake(159.14, 190.62)];
    [bezier56Path addLineToPoint: CGPointMake(156.69, 193.05)];
    [bezier56Path addLineToPoint: CGPointMake(153.72, 191.29)];
    [bezier56Path addCurveToPoint: CGPointMake(143.97, 183.79) controlPoint1: CGPointMake(150.45, 189.36) controlPoint2: CGPointMake(147.09, 186.88)];
    [bezier56Path addCurveToPoint: CGPointMake(136.4, 174.18) controlPoint1: CGPointMake(140.84, 180.69) controlPoint2: CGPointMake(138.3, 177.35)];
    [bezier56Path addLineToPoint: CGPointMake(134.64, 171.25)];
    [bezier56Path addLineToPoint: CGPointMake(137.05, 168.83)];
    [bezier56Path addLineToPoint: CGPointMake(140.62, 165.25)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(95.62, 76.26)];
    [bezier56Path addCurveToPoint: CGPointMake(94.97, 76.57) controlPoint1: CGPointMake(95.51, 76.28) controlPoint2: CGPointMake(95.32, 76.37)];
    [bezier56Path addCurveToPoint: CGPointMake(90.02, 84.3) controlPoint1: CGPointMake(91.53, 78.55) controlPoint2: CGPointMake(89.38, 81.82)];
    [bezier56Path addCurveToPoint: CGPointMake(102.52, 97.87) controlPoint1: CGPointMake(91.03, 88.18) controlPoint2: CGPointMake(96.11, 94.03)];
    [bezier56Path addCurveToPoint: CGPointMake(120.41, 102.48) controlPoint1: CGPointMake(108.91, 101.69) controlPoint2: CGPointMake(116.5, 103.4)];
    [bezier56Path addLineToPoint: CGPointMake(120.47, 102.47)];
    [bezier56Path addCurveToPoint: CGPointMake(125.02, 94.53) controlPoint1: CGPointMake(122.96, 101.86) controlPoint2: CGPointMake(124.86, 98.44)];
    [bezier56Path addCurveToPoint: CGPointMake(124.23, 93.53) controlPoint1: CGPointMake(125.06, 93.61) controlPoint2: CGPointMake(125.11, 93.68)];
    [bezier56Path addCurveToPoint: CGPointMake(119.27, 92.61) controlPoint1: CGPointMake(123.03, 93.32) controlPoint2: CGPointMake(121.64, 93.06)];
    [bezier56Path addCurveToPoint: CGPointMake(116.23, 92.06) controlPoint1: CGPointMake(118.15, 92.41) controlPoint2: CGPointMake(117.03, 92.21)];
    [bezier56Path addCurveToPoint: CGPointMake(115.47, 91.99) controlPoint1: CGPointMake(115.73, 91.98) controlPoint2: CGPointMake(115.56, 91.97)];
    [bezier56Path addCurveToPoint: CGPointMake(115.24, 92.19) controlPoint1: CGPointMake(115.41, 92) controlPoint2: CGPointMake(115.34, 92.06)];
    [bezier56Path addCurveToPoint: CGPointMake(115.02, 92.52) controlPoint1: CGPointMake(115.17, 92.27) controlPoint2: CGPointMake(115.12, 92.35)];
    [bezier56Path addLineToPoint: CGPointMake(113.71, 94.67)];
    [bezier56Path addLineToPoint: CGPointMake(112.8, 96.17)];
    [bezier56Path addLineToPoint: CGPointMake(111.12, 95.66)];
    [bezier56Path addCurveToPoint: CGPointMake(105.38, 93.13) controlPoint1: CGPointMake(109.27, 95.1) controlPoint2: CGPointMake(107.3, 94.28)];
    [bezier56Path addCurveToPoint: CGPointMake(100.45, 89.3) controlPoint1: CGPointMake(103.45, 91.98) controlPoint2: CGPointMake(101.79, 90.63)];
    [bezier56Path addLineToPoint: CGPointMake(99.22, 88.06)];
    [bezier56Path addLineToPoint: CGPointMake(100.12, 86.57)];
    [bezier56Path addLineToPoint: CGPointMake(101.44, 84.37)];
    [bezier56Path addCurveToPoint: CGPointMake(101.3, 83.13) controlPoint1: CGPointMake(101.81, 83.77) controlPoint2: CGPointMake(101.81, 83.79)];
    [bezier56Path addCurveToPoint: CGPointMake(99.38, 80.75) controlPoint1: CGPointMake(100.87, 82.59) controlPoint2: CGPointMake(100.28, 81.85)];
    [bezier56Path addCurveToPoint: CGPointMake(96.2, 76.77) controlPoint1: CGPointMake(97.86, 78.85) controlPoint2: CGPointMake(96.97, 77.75)];
    [bezier56Path addCurveToPoint: CGPointMake(95.62, 76.26) controlPoint1: CGPointMake(95.82, 76.27) controlPoint2: CGPointMake(95.75, 76.22)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(127.59, 107.96)];
    [bezier56Path addLineToPoint: CGPointMake(126.89, 109.21)];
    [bezier56Path addLineToPoint: CGPointMake(152.92, 124.08)];
    [bezier56Path addCurveToPoint: CGPointMake(149.57, 127.11) controlPoint1: CGPointMake(151.56, 124.67) controlPoint2: CGPointMake(150.37, 125.71)];
    [bezier56Path addCurveToPoint: CGPointMake(152.25, 136.89) controlPoint1: CGPointMake(147.63, 130.56) controlPoint2: CGPointMake(148.83, 134.94)];
    [bezier56Path addCurveToPoint: CGPointMake(161.97, 134.19) controlPoint1: CGPointMake(155.68, 138.85) controlPoint2: CGPointMake(160.03, 137.64)];
    [bezier56Path addCurveToPoint: CGPointMake(159.29, 124.41) controlPoint1: CGPointMake(163.92, 130.75) controlPoint2: CGPointMake(162.72, 126.37)];
    [bezier56Path addLineToPoint: CGPointMake(138.21, 112.38)];
    [bezier56Path addLineToPoint: CGPointMake(149.47, 92.41)];
    [bezier56Path addLineToPoint: CGPointMake(165.59, 101.62)];
    [bezier56Path addCurveToPoint: CGPointMake(162.24, 104.65) controlPoint1: CGPointMake(164.22, 102.22) controlPoint2: CGPointMake(163.03, 103.25)];
    [bezier56Path addCurveToPoint: CGPointMake(164.92, 114.43) controlPoint1: CGPointMake(160.3, 108.1) controlPoint2: CGPointMake(161.5, 112.48)];
    [bezier56Path addCurveToPoint: CGPointMake(174.64, 111.73) controlPoint1: CGPointMake(168.35, 116.39) controlPoint2: CGPointMake(172.7, 115.18)];
    [bezier56Path addCurveToPoint: CGPointMake(171.96, 101.95) controlPoint1: CGPointMake(176.58, 108.29) controlPoint2: CGPointMake(175.38, 103.91)];
    [bezier56Path addLineToPoint: CGPointMake(145.92, 87.08)];
    [bezier56Path addLineToPoint: CGPointMake(140.96, 84.25)];
    [bezier56Path addLineToPoint: CGPointMake(127.59, 107.96)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(102.87, 249.41)];
    [bezier56Path addCurveToPoint: CGPointMake(104.24, 250.75) controlPoint1: CGPointMake(103.19, 249.91) controlPoint2: CGPointMake(103.65, 250.36)];
    [bezier56Path addLineToPoint: CGPointMake(112.06, 255.89)];
    [bezier56Path addCurveToPoint: CGPointMake(113.85, 256.62) controlPoint1: CGPointMake(112.67, 256.29) controlPoint2: CGPointMake(113.27, 256.54)];
    [bezier56Path addCurveToPoint: CGPointMake(115.52, 256.54) controlPoint1: CGPointMake(114.44, 256.71) controlPoint2: CGPointMake(115, 256.68)];
    [bezier56Path addCurveToPoint: CGPointMake(116.95, 255.84) controlPoint1: CGPointMake(116.04, 256.4) controlPoint2: CGPointMake(116.52, 256.17)];
    [bezier56Path addCurveToPoint: CGPointMake(118.02, 254.72) controlPoint1: CGPointMake(117.38, 255.52) controlPoint2: CGPointMake(117.73, 255.15)];
    [bezier56Path addCurveToPoint: CGPointMake(118.63, 253.29) controlPoint1: CGPointMake(118.3, 254.29) controlPoint2: CGPointMake(118.5, 253.82)];
    [bezier56Path addCurveToPoint: CGPointMake(118.71, 251.71) controlPoint1: CGPointMake(118.76, 252.77) controlPoint2: CGPointMake(118.78, 252.24)];
    [bezier56Path addCurveToPoint: CGPointMake(118.13, 250.15) controlPoint1: CGPointMake(118.63, 251.18) controlPoint2: CGPointMake(118.44, 250.66)];
    [bezier56Path addCurveToPoint: CGPointMake(116.74, 248.8) controlPoint1: CGPointMake(117.81, 249.65) controlPoint2: CGPointMake(117.35, 249.2)];
    [bezier56Path addLineToPoint: CGPointMake(112.08, 245.74)];
    [bezier56Path addLineToPoint: CGPointMake(109.58, 249.53)];
    [bezier56Path addLineToPoint: CGPointMake(111.45, 250.76)];
    [bezier56Path addLineToPoint: CGPointMake(112.56, 249.08)];
    [bezier56Path addLineToPoint: CGPointMake(115.34, 250.91)];
    [bezier56Path addCurveToPoint: CGPointMake(116.2, 252.08) controlPoint1: CGPointMake(115.86, 251.25) controlPoint2: CGPointMake(116.14, 251.64)];
    [bezier56Path addCurveToPoint: CGPointMake(115.9, 253.33) controlPoint1: CGPointMake(116.25, 252.52) controlPoint2: CGPointMake(116.15, 252.94)];
    [bezier56Path addCurveToPoint: CGPointMake(114.87, 254.09) controlPoint1: CGPointMake(115.64, 253.71) controlPoint2: CGPointMake(115.3, 253.97)];
    [bezier56Path addCurveToPoint: CGPointMake(113.46, 253.77) controlPoint1: CGPointMake(114.44, 254.22) controlPoint2: CGPointMake(113.97, 254.11)];
    [bezier56Path addLineToPoint: CGPointMake(105.64, 248.64)];
    [bezier56Path addCurveToPoint: CGPointMake(104.79, 247.47) controlPoint1: CGPointMake(105.13, 248.3) controlPoint2: CGPointMake(104.84, 247.91)];
    [bezier56Path addCurveToPoint: CGPointMake(105.09, 246.22) controlPoint1: CGPointMake(104.73, 247.03) controlPoint2: CGPointMake(104.83, 246.61)];
    [bezier56Path addCurveToPoint: CGPointMake(106.11, 245.46) controlPoint1: CGPointMake(105.34, 245.84) controlPoint2: CGPointMake(105.69, 245.58)];
    [bezier56Path addCurveToPoint: CGPointMake(107.53, 245.78) controlPoint1: CGPointMake(106.54, 245.33) controlPoint2: CGPointMake(107.02, 245.44)];
    [bezier56Path addLineToPoint: CGPointMake(108.28, 246.27)];
    [bezier56Path addLineToPoint: CGPointMake(109.67, 244.15)];
    [bezier56Path addLineToPoint: CGPointMake(108.92, 243.66)];
    [bezier56Path addCurveToPoint: CGPointMake(107.14, 242.93) controlPoint1: CGPointMake(108.33, 243.27) controlPoint2: CGPointMake(107.73, 243.03)];
    [bezier56Path addCurveToPoint: CGPointMake(105.47, 243.01) controlPoint1: CGPointMake(106.55, 242.84) controlPoint2: CGPointMake(105.99, 242.87)];
    [bezier56Path addCurveToPoint: CGPointMake(104.04, 243.71) controlPoint1: CGPointMake(104.94, 243.15) controlPoint2: CGPointMake(104.47, 243.38)];
    [bezier56Path addCurveToPoint: CGPointMake(102.97, 244.83) controlPoint1: CGPointMake(103.61, 244.03) controlPoint2: CGPointMake(103.25, 244.4)];
    [bezier56Path addCurveToPoint: CGPointMake(102.35, 246.26) controlPoint1: CGPointMake(102.68, 245.26) controlPoint2: CGPointMake(102.48, 245.74)];
    [bezier56Path addCurveToPoint: CGPointMake(102.28, 247.84) controlPoint1: CGPointMake(102.23, 246.78) controlPoint2: CGPointMake(102.2, 247.31)];
    [bezier56Path addCurveToPoint: CGPointMake(102.87, 249.41) controlPoint1: CGPointMake(102.35, 248.38) controlPoint2: CGPointMake(102.55, 248.9)];
    [bezier56Path addLineToPoint: CGPointMake(102.87, 249.41)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(106.71, 239.44)];
    [bezier56Path addLineToPoint: CGPointMake(121.51, 249.16)];
    [bezier56Path addLineToPoint: CGPointMake(122.9, 247.05)];
    [bezier56Path addLineToPoint: CGPointMake(108.1, 237.32)];
    [bezier56Path addLineToPoint: CGPointMake(106.71, 239.44)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(125.65, 242.88)];
    [bezier56Path addLineToPoint: CGPointMake(119.33, 238.73)];
    [bezier56Path addLineToPoint: CGPointMake(121.74, 235.08)];
    [bezier56Path addLineToPoint: CGPointMake(119.75, 233.76)];
    [bezier56Path addLineToPoint: CGPointMake(117.34, 237.41)];
    [bezier56Path addLineToPoint: CGPointMake(112.85, 234.46)];
    [bezier56Path addLineToPoint: CGPointMake(115.61, 230.27)];
    [bezier56Path addLineToPoint: CGPointMake(113.62, 228.96)];
    [bezier56Path addLineToPoint: CGPointMake(109.46, 235.27)];
    [bezier56Path addLineToPoint: CGPointMake(124.26, 244.99)];
    [bezier56Path addLineToPoint: CGPointMake(125.65, 242.88)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(54.47, 146.11)];
    [bezier56Path addCurveToPoint: CGPointMake(62, 137.72) controlPoint1: CGPointMake(56.35, 145.02) controlPoint2: CGPointMake(57.65, 143.48)];
    [bezier56Path addCurveToPoint: CGPointMake(62.67, 136.83) controlPoint1: CGPointMake(62.26, 137.38) controlPoint2: CGPointMake(62.47, 137.1)];
    [bezier56Path addCurveToPoint: CGPointMake(68.57, 130.17) controlPoint1: CGPointMake(65.38, 133.29) controlPoint2: CGPointMake(67.08, 131.32)];
    [bezier56Path addCurveToPoint: CGPointMake(70.64, 129.99) controlPoint1: CGPointMake(69.89, 129.16) controlPoint2: CGPointMake(70.17, 129.17)];
    [bezier56Path addCurveToPoint: CGPointMake(70.44, 130.16) controlPoint1: CGPointMake(70.56, 129.84) controlPoint2: CGPointMake(70.55, 129.88)];
    [bezier56Path addCurveToPoint: CGPointMake(69.15, 132.31) controlPoint1: CGPointMake(70.23, 130.7) controlPoint2: CGPointMake(69.8, 131.42)];
    [bezier56Path addCurveToPoint: CGPointMake(63.7, 138.62) controlPoint1: CGPointMake(68.02, 133.85) controlPoint2: CGPointMake(66.68, 135.38)];
    [bezier56Path addCurveToPoint: CGPointMake(63.24, 139.12) controlPoint1: CGPointMake(63.47, 138.87) controlPoint2: CGPointMake(63.47, 138.87)];
    [bezier56Path addCurveToPoint: CGPointMake(57.02, 146.41) controlPoint1: CGPointMake(59.88, 142.77) controlPoint2: CGPointMake(58.34, 144.54)];
    [bezier56Path addCurveToPoint: CGPointMake(55.96, 153.66) controlPoint1: CGPointMake(54.89, 149.46) controlPoint2: CGPointMake(54.19, 151.82)];
    [bezier56Path addCurveToPoint: CGPointMake(62.61, 152.12) controlPoint1: CGPointMake(57.66, 155.44) controlPoint2: CGPointMake(59.62, 154.55)];
    [bezier56Path addCurveToPoint: CGPointMake(69.32, 145.83) controlPoint1: CGPointMake(64.3, 150.74) controlPoint2: CGPointMake(66.07, 149.06)];
    [bezier56Path addCurveToPoint: CGPointMake(69.74, 145.41) controlPoint1: CGPointMake(69.53, 145.62) controlPoint2: CGPointMake(69.53, 145.62)];
    [bezier56Path addCurveToPoint: CGPointMake(74.76, 140.54) controlPoint1: CGPointMake(72.28, 142.89) controlPoint2: CGPointMake(73.65, 141.55)];
    [bezier56Path addCurveToPoint: CGPointMake(69.91, 146.44) controlPoint1: CGPointMake(73.68, 142.03) controlPoint2: CGPointMake(72.21, 143.8)];
    [bezier56Path addCurveToPoint: CGPointMake(68.51, 148.05) controlPoint1: CGPointMake(69.58, 146.82) controlPoint2: CGPointMake(69.21, 147.25)];
    [bezier56Path addCurveToPoint: CGPointMake(67.14, 149.63) controlPoint1: CGPointMake(67.94, 148.7) controlPoint2: CGPointMake(67.53, 149.17)];
    [bezier56Path addCurveToPoint: CGPointMake(62.66, 159.96) controlPoint1: CGPointMake(61.66, 155.99) controlPoint2: CGPointMake(60.4, 157.9)];
    [bezier56Path addCurveToPoint: CGPointMake(73.89, 154.93) controlPoint1: CGPointMake(64.69, 161.81) controlPoint2: CGPointMake(68.35, 159.61)];
    [bezier56Path addCurveToPoint: CGPointMake(84.15, 143.55) controlPoint1: CGPointMake(78.5, 151.03) controlPoint2: CGPointMake(82.55, 146.66)];
    [bezier56Path addCurveToPoint: CGPointMake(83.31, 140.94) controlPoint1: CGPointMake(84.64, 142.6) controlPoint2: CGPointMake(84.27, 141.43)];
    [bezier56Path addCurveToPoint: CGPointMake(80.7, 141.79) controlPoint1: CGPointMake(82.36, 140.45) controlPoint2: CGPointMake(81.19, 140.83)];
    [bezier56Path addCurveToPoint: CGPointMake(71.39, 151.97) controlPoint1: CGPointMake(79.39, 144.33) controlPoint2: CGPointMake(75.65, 148.38)];
    [bezier56Path addCurveToPoint: CGPointMake(67.99, 154.64) controlPoint1: CGPointMake(70.2, 152.98) controlPoint2: CGPointMake(69.04, 153.89)];
    [bezier56Path addCurveToPoint: CGPointMake(70.07, 152.15) controlPoint1: CGPointMake(68.56, 153.93) controlPoint2: CGPointMake(69.25, 153.11)];
    [bezier56Path addCurveToPoint: CGPointMake(71.43, 150.59) controlPoint1: CGPointMake(70.46, 151.7) controlPoint2: CGPointMake(70.87, 151.23)];
    [bezier56Path addCurveToPoint: CGPointMake(72.83, 148.98) controlPoint1: CGPointMake(72.13, 149.79) controlPoint2: CGPointMake(72.5, 149.36)];
    [bezier56Path addCurveToPoint: CGPointMake(79.86, 135.11) controlPoint1: CGPointMake(80.03, 140.7) controlPoint2: CGPointMake(81.98, 137.83)];
    [bezier56Path addCurveToPoint: CGPointMake(73.46, 136.53) controlPoint1: CGPointMake(78.27, 133.06) controlPoint2: CGPointMake(76.49, 133.96)];
    [bezier56Path addCurveToPoint: CGPointMake(67.02, 142.67) controlPoint1: CGPointMake(71.91, 137.84) controlPoint2: CGPointMake(70.6, 139.1)];
    [bezier56Path addCurveToPoint: CGPointMake(66.59, 143.09) controlPoint1: CGPointMake(66.81, 142.88) controlPoint2: CGPointMake(66.81, 142.88)];
    [bezier56Path addCurveToPoint: CGPointMake(60.17, 149.11) controlPoint1: CGPointMake(63.44, 146.22) controlPoint2: CGPointMake(61.73, 147.85)];
    [bezier56Path addCurveToPoint: CGPointMake(59.59, 149.57) controlPoint1: CGPointMake(59.96, 149.28) controlPoint2: CGPointMake(59.77, 149.43)];
    [bezier56Path addCurveToPoint: CGPointMake(60.2, 148.63) controlPoint1: CGPointMake(59.76, 149.28) controlPoint2: CGPointMake(59.96, 148.97)];
    [bezier56Path addCurveToPoint: CGPointMake(66.09, 141.74) controlPoint1: CGPointMake(61.37, 146.95) controlPoint2: CGPointMake(62.85, 145.25)];
    [bezier56Path addCurveToPoint: CGPointMake(66.55, 141.24) controlPoint1: CGPointMake(66.31, 141.49) controlPoint2: CGPointMake(66.31, 141.49)];
    [bezier56Path addCurveToPoint: CGPointMake(74, 128.03) controlPoint1: CGPointMake(73.97, 133.18) controlPoint2: CGPointMake(75.65, 130.88)];
    [bezier56Path addCurveToPoint: CGPointMake(66.22, 127.1) controlPoint1: CGPointMake(72.17, 124.87) controlPoint2: CGPointMake(69.19, 124.82)];
    [bezier56Path addCurveToPoint: CGPointMake(59.59, 134.5) controlPoint1: CGPointMake(64.35, 128.53) controlPoint2: CGPointMake(62.51, 130.66)];
    [bezier56Path addCurveToPoint: CGPointMake(58.91, 135.39) controlPoint1: CGPointMake(59.39, 134.76) controlPoint2: CGPointMake(59.18, 135.04)];
    [bezier56Path addCurveToPoint: CGPointMake(53.83, 141.69) controlPoint1: CGPointMake(56.33, 138.81) controlPoint2: CGPointMake(54.87, 140.65)];
    [bezier56Path addCurveToPoint: CGPointMake(54.02, 141.27) controlPoint1: CGPointMake(53.89, 141.56) controlPoint2: CGPointMake(53.95, 141.42)];
    [bezier56Path addCurveToPoint: CGPointMake(60.09, 131.88) controlPoint1: CGPointMake(55.45, 138.1) controlPoint2: CGPointMake(58.12, 133.97)];
    [bezier56Path addCurveToPoint: CGPointMake(60.02, 129.14) controlPoint1: CGPointMake(60.83, 131.1) controlPoint2: CGPointMake(60.8, 129.88)];
    [bezier56Path addCurveToPoint: CGPointMake(57.28, 129.23) controlPoint1: CGPointMake(59.24, 128.41) controlPoint2: CGPointMake(58.02, 128.45)];
    [bezier56Path addCurveToPoint: CGPointMake(50.48, 139.69) controlPoint1: CGPointMake(54.99, 131.65) controlPoint2: CGPointMake(52.08, 136.14)];
    [bezier56Path addCurveToPoint: CGPointMake(49.29, 144.67) controlPoint1: CGPointMake(49.54, 141.8) controlPoint2: CGPointMake(49.08, 143.42)];
    [bezier56Path addCurveToPoint: CGPointMake(54.47, 146.11) controlPoint1: CGPointMake(49.72, 147.3) controlPoint2: CGPointMake(52.07, 147.49)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(179.9, 268.98)];
    [bezier56Path addLineToPoint: CGPointMake(200.2, 284.46)];
    [bezier56Path addCurveToPoint: CGPointMake(208.13, 283.42) controlPoint1: CGPointMake(202.68, 286.34) controlPoint2: CGPointMake(206.23, 285.88)];
    [bezier56Path addLineToPoint: CGPointMake(223.7, 263.25)];
    [bezier56Path addCurveToPoint: CGPointMake(222.65, 255.37) controlPoint1: CGPointMake(225.6, 260.78) controlPoint2: CGPointMake(225.13, 257.27)];
    [bezier56Path addLineToPoint: CGPointMake(202.36, 239.9)];
    [bezier56Path addCurveToPoint: CGPointMake(194.43, 240.94) controlPoint1: CGPointMake(199.88, 238.01) controlPoint2: CGPointMake(196.33, 238.48)];
    [bezier56Path addLineToPoint: CGPointMake(189.91, 246.78)];
    [bezier56Path addLineToPoint: CGPointMake(186.12, 235.55)];
    [bezier56Path addCurveToPoint: CGPointMake(183.44, 235.11) controlPoint1: CGPointMake(185.72, 234.39) controlPoint2: CGPointMake(184.19, 234.13)];
    [bezier56Path addLineToPoint: CGPointMake(170.34, 252.06)];
    [bezier56Path addCurveToPoint: CGPointMake(171.47, 254.53) controlPoint1: CGPointMake(169.59, 253.03) controlPoint2: CGPointMake(170.24, 254.44)];
    [bezier56Path addLineToPoint: CGPointMake(183.37, 255.26)];
    [bezier56Path addLineToPoint: CGPointMake(178.86, 261.1)];
    [bezier56Path addCurveToPoint: CGPointMake(179.9, 268.98) controlPoint1: CGPointMake(176.95, 263.57) controlPoint2: CGPointMake(177.42, 267.09)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(221.65, 292.32)];
    [bezier56Path addCurveToPoint: CGPointMake(220.78, 298.38) controlPoint1: CGPointMake(219.73, 293.75) controlPoint2: CGPointMake(219.34, 296.47)];
    [bezier56Path addCurveToPoint: CGPointMake(226.86, 299.24) controlPoint1: CGPointMake(222.22, 300.29) controlPoint2: CGPointMake(224.94, 300.67)];
    [bezier56Path addCurveToPoint: CGPointMake(227.72, 293.18) controlPoint1: CGPointMake(228.77, 297.8) controlPoint2: CGPointMake(229.16, 295.09)];
    [bezier56Path addCurveToPoint: CGPointMake(221.65, 292.32) controlPoint1: CGPointMake(226.28, 291.27) controlPoint2: CGPointMake(223.56, 290.88)];
    [bezier56Path addLineToPoint: CGPointMake(221.65, 292.32)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(230.03, 291.44)];
    [bezier56Path addCurveToPoint: CGPointMake(219.91, 290.01) controlPoint1: CGPointMake(227.63, 288.26) controlPoint2: CGPointMake(223.1, 287.62)];
    [bezier56Path addCurveToPoint: CGPointMake(218.47, 300.11) controlPoint1: CGPointMake(216.72, 292.4) controlPoint2: CGPointMake(216.07, 296.93)];
    [bezier56Path addCurveToPoint: CGPointMake(228.6, 301.55) controlPoint1: CGPointMake(220.87, 303.3) controlPoint2: CGPointMake(225.4, 303.94)];
    [bezier56Path addCurveToPoint: CGPointMake(230.03, 291.44) controlPoint1: CGPointMake(231.79, 299.15) controlPoint2: CGPointMake(232.43, 294.63)];
    [bezier56Path addLineToPoint: CGPointMake(230.03, 291.44)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(237.84, 294.6)];
    [bezier56Path addCurveToPoint: CGPointMake(237.28, 298.65) controlPoint1: CGPointMake(238.8, 295.88) controlPoint2: CGPointMake(238.55, 297.69)];
    [bezier56Path addLineToPoint: CGPointMake(223.39, 309.06)];
    [bezier56Path addCurveToPoint: CGPointMake(219.34, 308.47) controlPoint1: CGPointMake(222.12, 310.01) controlPoint2: CGPointMake(220.3, 309.75)];
    [bezier56Path addLineToPoint: CGPointMake(210.66, 296.95)];
    [bezier56Path addCurveToPoint: CGPointMake(211.23, 292.91) controlPoint1: CGPointMake(209.7, 295.67) controlPoint2: CGPointMake(209.95, 293.86)];
    [bezier56Path addLineToPoint: CGPointMake(214.21, 290.67)];
    [bezier56Path addLineToPoint: CGPointMake(213.58, 289.31)];
    [bezier56Path addCurveToPoint: CGPointMake(214.11, 287.14) controlPoint1: CGPointMake(213.24, 288.59) controlPoint2: CGPointMake(213.49, 287.6)];
    [bezier56Path addLineToPoint: CGPointMake(218.76, 283.65)];
    [bezier56Path addCurveToPoint: CGPointMake(221, 283.75) controlPoint1: CGPointMake(219.39, 283.18) controlPoint2: CGPointMake(220.39, 283.22)];
    [bezier56Path addLineToPoint: CGPointMake(222.14, 284.73)];
    [bezier56Path addLineToPoint: CGPointMake(225.12, 282.5)];
    [bezier56Path addCurveToPoint: CGPointMake(229.16, 283.08) controlPoint1: CGPointMake(226.39, 281.54) controlPoint2: CGPointMake(228.2, 281.8)];
    [bezier56Path addLineToPoint: CGPointMake(237.84, 294.6)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(285.77, 94.76)];
    [bezier56Path addCurveToPoint: CGPointMake(278.54, 97.3) controlPoint1: CGPointMake(283.08, 93.44) controlPoint2: CGPointMake(279.84, 94.58)];
    [bezier56Path addCurveToPoint: CGPointMake(281.06, 104.6) controlPoint1: CGPointMake(277.24, 100.02) controlPoint2: CGPointMake(278.37, 103.28)];
    [bezier56Path addCurveToPoint: CGPointMake(288.28, 102.05) controlPoint1: CGPointMake(283.75, 105.91) controlPoint2: CGPointMake(286.98, 104.77)];
    [bezier56Path addCurveToPoint: CGPointMake(285.77, 94.76) controlPoint1: CGPointMake(289.58, 99.34) controlPoint2: CGPointMake(288.46, 96.07)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(293.06, 97.1)];
    [bezier56Path addLineToPoint: CGPointMake(291.85, 99.63)];
    [bezier56Path addLineToPoint: CGPointMake(292.73, 100.33)];
    [bezier56Path addCurveToPoint: CGPointMake(293.12, 101.98) controlPoint1: CGPointMake(293.21, 100.7) controlPoint2: CGPointMake(293.38, 101.45)];
    [bezier56Path addLineToPoint: CGPointMake(291.23, 105.93)];
    [bezier56Path addCurveToPoint: CGPointMake(289.71, 106.65) controlPoint1: CGPointMake(290.98, 106.47) controlPoint2: CGPointMake(290.3, 106.8)];
    [bezier56Path addLineToPoint: CGPointMake(288.62, 106.38)];
    [bezier56Path addLineToPoint: CGPointMake(287.4, 108.92)];
    [bezier56Path addCurveToPoint: CGPointMake(284.51, 109.92) controlPoint1: CGPointMake(286.88, 110) controlPoint2: CGPointMake(285.59, 110.45)];
    [bezier56Path addLineToPoint: CGPointMake(274.78, 105.17)];
    [bezier56Path addCurveToPoint: CGPointMake(273.77, 102.26) controlPoint1: CGPointMake(273.7, 104.65) controlPoint2: CGPointMake(273.25, 103.34)];
    [bezier56Path addLineToPoint: CGPointMake(279.42, 90.44)];
    [bezier56Path addCurveToPoint: CGPointMake(282.31, 89.43) controlPoint1: CGPointMake(279.94, 89.35) controlPoint2: CGPointMake(281.23, 88.9)];
    [bezier56Path addLineToPoint: CGPointMake(292.04, 94.18)];
    [bezier56Path addCurveToPoint: CGPointMake(293.06, 97.1) controlPoint1: CGPointMake(293.12, 94.71) controlPoint2: CGPointMake(293.58, 96.01)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(284.82, 96.72)];
    [bezier56Path addCurveToPoint: CGPointMake(280.49, 98.25) controlPoint1: CGPointMake(283.21, 95.94) controlPoint2: CGPointMake(281.27, 96.62)];
    [bezier56Path addCurveToPoint: CGPointMake(282, 102.63) controlPoint1: CGPointMake(279.71, 99.88) controlPoint2: CGPointMake(280.39, 101.84)];
    [bezier56Path addCurveToPoint: CGPointMake(286.33, 101.1) controlPoint1: CGPointMake(283.61, 103.42) controlPoint2: CGPointMake(285.55, 102.73)];
    [bezier56Path addCurveToPoint: CGPointMake(284.82, 96.72) controlPoint1: CGPointMake(287.11, 99.47) controlPoint2: CGPointMake(286.44, 97.51)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(92.23, 263.1)];
    [bezier56Path addCurveToPoint: CGPointMake(92.74, 258.08) controlPoint1: CGPointMake(93.75, 261.85) controlPoint2: CGPointMake(93.98, 259.6)];
    [bezier56Path addCurveToPoint: CGPointMake(87.76, 257.58) controlPoint1: CGPointMake(91.5, 256.55) controlPoint2: CGPointMake(89.27, 256.33)];
    [bezier56Path addLineToPoint: CGPointMake(68.55, 273.42)];
    [bezier56Path addCurveToPoint: CGPointMake(51.11, 271.67) controlPoint1: CGPointMake(63.25, 277.78) controlPoint2: CGPointMake(55.43, 277)];
    [bezier56Path addCurveToPoint: CGPointMake(52.87, 254.09) controlPoint1: CGPointMake(46.77, 266.33) controlPoint2: CGPointMake(47.56, 258.47)];
    [bezier56Path addLineToPoint: CGPointMake(58.36, 249.56)];
    [bezier56Path addLineToPoint: CGPointMake(76.2, 234.86)];
    [bezier56Path addCurveToPoint: CGPointMake(86.16, 235.86) controlPoint1: CGPointMake(79.22, 232.37) controlPoint2: CGPointMake(83.69, 232.82)];
    [bezier56Path addCurveToPoint: CGPointMake(85.15, 245.9) controlPoint1: CGPointMake(88.63, 238.91) controlPoint2: CGPointMake(88.18, 243.41)];
    [bezier56Path addLineToPoint: CGPointMake(79.66, 250.43)];
    [bezier56Path addLineToPoint: CGPointMake(61.81, 265.15)];
    [bezier56Path addCurveToPoint: CGPointMake(59.34, 264.88) controlPoint1: CGPointMake(61.06, 265.77) controlPoint2: CGPointMake(59.97, 265.66)];
    [bezier56Path addCurveToPoint: CGPointMake(59.57, 262.39) controlPoint1: CGPointMake(58.71, 264.11) controlPoint2: CGPointMake(58.82, 263.01)];
    [bezier56Path addLineToPoint: CGPointMake(78.82, 246.52)];
    [bezier56Path addCurveToPoint: CGPointMake(79.33, 241.49) controlPoint1: CGPointMake(80.34, 245.27) controlPoint2: CGPointMake(80.56, 243.02)];
    [bezier56Path addCurveToPoint: CGPointMake(74.35, 240.99) controlPoint1: CGPointMake(78.09, 239.97) controlPoint2: CGPointMake(75.86, 239.74)];
    [bezier56Path addLineToPoint: CGPointMake(55.09, 256.87)];
    [bezier56Path addCurveToPoint: CGPointMake(53.85, 269.41) controlPoint1: CGPointMake(51.3, 259.99) controlPoint2: CGPointMake(50.76, 265.6)];
    [bezier56Path addCurveToPoint: CGPointMake(66.29, 270.67) controlPoint1: CGPointMake(56.95, 273.23) controlPoint2: CGPointMake(62.5, 273.79)];
    [bezier56Path addLineToPoint: CGPointMake(84.14, 255.95)];
    [bezier56Path addLineToPoint: CGPointMake(89.63, 251.42)];
    [bezier56Path addCurveToPoint: CGPointMake(91.65, 231.34) controlPoint1: CGPointMake(95.69, 246.43) controlPoint2: CGPointMake(96.59, 237.44)];
    [bezier56Path addCurveToPoint: CGPointMake(71.72, 229.34) controlPoint1: CGPointMake(86.71, 225.24) controlPoint2: CGPointMake(77.78, 224.35)];
    [bezier56Path addLineToPoint: CGPointMake(53.88, 244.04)];
    [bezier56Path addLineToPoint: CGPointMake(48.39, 248.57)];
    [bezier56Path addCurveToPoint: CGPointMake(45.62, 276.19) controlPoint1: CGPointMake(40.05, 255.45) controlPoint2: CGPointMake(38.81, 267.8)];
    [bezier56Path addCurveToPoint: CGPointMake(73.03, 278.94) controlPoint1: CGPointMake(52.41, 284.57) controlPoint2: CGPointMake(64.7, 285.8)];
    [bezier56Path addLineToPoint: CGPointMake(92.23, 263.1)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(47.91, 122.16)];
    [bezier56Path addCurveToPoint: CGPointMake(47.21, 121.58) controlPoint1: CGPointMake(47.55, 122.19) controlPoint2: CGPointMake(47.24, 121.93)];
    [bezier56Path addLineToPoint: CGPointMake(46.31, 112.58)];
    [bezier56Path addCurveToPoint: CGPointMake(44.91, 111.41) controlPoint1: CGPointMake(46.24, 111.87) controlPoint2: CGPointMake(45.61, 111.34)];
    [bezier56Path addCurveToPoint: CGPointMake(43.77, 112.81) controlPoint1: CGPointMake(44.21, 111.47) controlPoint2: CGPointMake(43.7, 112.1)];
    [bezier56Path addLineToPoint: CGPointMake(44.67, 121.82)];
    [bezier56Path addCurveToPoint: CGPointMake(48.16, 124.72) controlPoint1: CGPointMake(44.85, 123.59) controlPoint2: CGPointMake(46.41, 124.89)];
    [bezier56Path addCurveToPoint: CGPointMake(51.02, 121.23) controlPoint1: CGPointMake(49.92, 124.56) controlPoint2: CGPointMake(51.19, 123)];
    [bezier56Path addLineToPoint: CGPointMake(50.18, 112.88)];
    [bezier56Path addLineToPoint: CGPointMake(49.92, 110.31)];
    [bezier56Path addCurveToPoint: CGPointMake(44.34, 105.65) controlPoint1: CGPointMake(49.64, 107.47) controlPoint2: CGPointMake(47.14, 105.39)];
    [bezier56Path addCurveToPoint: CGPointMake(39.77, 111.25) controlPoint1: CGPointMake(41.54, 105.91) controlPoint2: CGPointMake(39.49, 108.42)];
    [bezier56Path addLineToPoint: CGPointMake(40.6, 119.59)];
    [bezier56Path addLineToPoint: CGPointMake(40.86, 122.16)];
    [bezier56Path addCurveToPoint: CGPointMake(48.55, 128.57) controlPoint1: CGPointMake(41.25, 126.07) controlPoint2: CGPointMake(44.69, 128.93)];
    [bezier56Path addCurveToPoint: CGPointMake(54.82, 120.87) controlPoint1: CGPointMake(52.4, 128.22) controlPoint2: CGPointMake(55.21, 124.76)];
    [bezier56Path addLineToPoint: CGPointMake(53.92, 111.88)];
    [bezier56Path addCurveToPoint: CGPointMake(52.53, 110.71) controlPoint1: CGPointMake(53.85, 111.17) controlPoint2: CGPointMake(53.23, 110.65)];
    [bezier56Path addCurveToPoint: CGPointMake(51.39, 112.12) controlPoint1: CGPointMake(51.83, 110.78) controlPoint2: CGPointMake(51.32, 111.41)];
    [bezier56Path addLineToPoint: CGPointMake(52.28, 121.1)];
    [bezier56Path addCurveToPoint: CGPointMake(48.29, 126.01) controlPoint1: CGPointMake(52.53, 123.58) controlPoint2: CGPointMake(50.74, 125.78)];
    [bezier56Path addCurveToPoint: CGPointMake(43.4, 121.93) controlPoint1: CGPointMake(45.83, 126.24) controlPoint2: CGPointMake(43.65, 124.41)];
    [bezier56Path addLineToPoint: CGPointMake(43.14, 119.36)];
    [bezier56Path addLineToPoint: CGPointMake(42.31, 111.01)];
    [bezier56Path addCurveToPoint: CGPointMake(44.59, 108.21) controlPoint1: CGPointMake(42.17, 109.6) controlPoint2: CGPointMake(43.19, 108.34)];
    [bezier56Path addCurveToPoint: CGPointMake(47.39, 110.54) controlPoint1: CGPointMake(45.99, 108.08) controlPoint2: CGPointMake(47.24, 109.13)];
    [bezier56Path addLineToPoint: CGPointMake(47.64, 113.11)];
    [bezier56Path addLineToPoint: CGPointMake(48.48, 121.47)];
    [bezier56Path addCurveToPoint: CGPointMake(47.91, 122.16) controlPoint1: CGPointMake(48.51, 121.82) controlPoint2: CGPointMake(48.26, 122.12)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(110.46, 111.13)];
    [bezier56Path addLineToPoint: CGPointMake(100.95, 112.6)];
    [bezier56Path addCurveToPoint: CGPointMake(88.85, 129.17) controlPoint1: CGPointMake(93.02, 113.82) controlPoint2: CGPointMake(87.63, 121.24)];
    [bezier56Path addLineToPoint: CGPointMake(89.21, 131.54)];
    [bezier56Path addCurveToPoint: CGPointMake(100.82, 143.6) controlPoint1: CGPointMake(90.17, 137.78) controlPoint2: CGPointMake(94.97, 142.49)];
    [bezier56Path addLineToPoint: CGPointMake(102.05, 151.6)];
    [bezier56Path addLineToPoint: CGPointMake(109.88, 143.04)];
    [bezier56Path addLineToPoint: CGPointMake(115.23, 142.21)];
    [bezier56Path addCurveToPoint: CGPointMake(127.33, 125.64) controlPoint1: CGPointMake(123.15, 140.99) controlPoint2: CGPointMake(128.55, 133.57)];
    [bezier56Path addLineToPoint: CGPointMake(126.97, 123.28)];
    [bezier56Path addCurveToPoint: CGPointMake(110.46, 111.13) controlPoint1: CGPointMake(125.75, 115.36) controlPoint2: CGPointMake(118.36, 109.91)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(165.57, 299.39)];
    [bezier56Path addLineToPoint: CGPointMake(180.34, 285.24)];
    [bezier56Path addLineToPoint: CGPointMake(181.12, 284.49)];
    [bezier56Path addLineToPoint: CGPointMake(165.42, 268.22)];
    [bezier56Path addCurveToPoint: CGPointMake(168.5, 266.76) controlPoint1: CGPointMake(166.54, 268.09) controlPoint2: CGPointMake(167.62, 267.6)];
    [bezier56Path addCurveToPoint: CGPointMake(168.65, 259.16) controlPoint1: CGPointMake(170.64, 264.71) controlPoint2: CGPointMake(170.71, 261.3)];
    [bezier56Path addCurveToPoint: CGPointMake(161.02, 259.01) controlPoint1: CGPointMake(166.58, 257.03) controlPoint2: CGPointMake(163.17, 256.96)];
    [bezier56Path addCurveToPoint: CGPointMake(160.87, 266.61) controlPoint1: CGPointMake(158.88, 261.07) controlPoint2: CGPointMake(158.81, 264.47)];
    [bezier56Path addLineToPoint: CGPointMake(173.58, 279.78)];
    [bezier56Path addLineToPoint: CGPointMake(161.14, 291.7)];
    [bezier56Path addLineToPoint: CGPointMake(151.42, 281.63)];
    [bezier56Path addCurveToPoint: CGPointMake(154.5, 280.17) controlPoint1: CGPointMake(152.54, 281.49) controlPoint2: CGPointMake(153.63, 281.01)];
    [bezier56Path addCurveToPoint: CGPointMake(154.65, 272.57) controlPoint1: CGPointMake(156.65, 278.11) controlPoint2: CGPointMake(156.72, 274.71)];
    [bezier56Path addCurveToPoint: CGPointMake(147.03, 272.42) controlPoint1: CGPointMake(152.59, 270.43) controlPoint2: CGPointMake(149.17, 270.37)];
    [bezier56Path addCurveToPoint: CGPointMake(146.88, 280.02) controlPoint1: CGPointMake(144.88, 274.48) controlPoint2: CGPointMake(144.81, 277.88)];
    [bezier56Path addLineToPoint: CGPointMake(162.58, 296.29)];
    [bezier56Path addLineToPoint: CGPointMake(165.57, 299.39)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(293.55, 147.9)];
    [bezier56Path addLineToPoint: CGPointMake(293.61, 138.18)];
    [bezier56Path addLineToPoint: CGPointMake(271.19, 138.04)];
    [bezier56Path addLineToPoint: CGPointMake(271.17, 141.3)];
    [bezier56Path addLineToPoint: CGPointMake(280.74, 141.36)];
    [bezier56Path addLineToPoint: CGPointMake(280.71, 146.99)];
    [bezier56Path addLineToPoint: CGPointMake(283.73, 147.01)];
    [bezier56Path addLineToPoint: CGPointMake(283.77, 141.38)];
    [bezier56Path addLineToPoint: CGPointMake(290.57, 141.42)];
    [bezier56Path addLineToPoint: CGPointMake(290.53, 147.89)];
    [bezier56Path addLineToPoint: CGPointMake(293.55, 147.9)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(288.4, 125.48)];
    [bezier56Path addLineToPoint: CGPointMake(287.26, 125.47)];
    [bezier56Path addLineToPoint: CGPointMake(287.24, 128.74)];
    [bezier56Path addLineToPoint: CGPointMake(288.38, 128.74)];
    [bezier56Path addCurveToPoint: CGPointMake(290.77, 128.28) controlPoint1: CGPointMake(289.28, 128.75) controlPoint2: CGPointMake(290.08, 128.59)];
    [bezier56Path addCurveToPoint: CGPointMake(292.5, 127.02) controlPoint1: CGPointMake(291.47, 127.96) controlPoint2: CGPointMake(292.04, 127.54)];
    [bezier56Path addCurveToPoint: CGPointMake(293.53, 125.27) controlPoint1: CGPointMake(292.95, 126.51) controlPoint2: CGPointMake(293.3, 125.92)];
    [bezier56Path addCurveToPoint: CGPointMake(293.89, 123.31) controlPoint1: CGPointMake(293.77, 124.62) controlPoint2: CGPointMake(293.88, 123.97)];
    [bezier56Path addCurveToPoint: CGPointMake(293.55, 121.34) controlPoint1: CGPointMake(293.89, 122.65) controlPoint2: CGPointMake(293.78, 121.99)];
    [bezier56Path addCurveToPoint: CGPointMake(292.54, 119.57) controlPoint1: CGPointMake(293.33, 120.69) controlPoint2: CGPointMake(292.99, 120.1)];
    [bezier56Path addCurveToPoint: CGPointMake(290.83, 118.3) controlPoint1: CGPointMake(292.09, 119.05) controlPoint2: CGPointMake(291.52, 118.62)];
    [bezier56Path addCurveToPoint: CGPointMake(288.44, 117.8) controlPoint1: CGPointMake(290.14, 117.97) controlPoint2: CGPointMake(289.34, 117.81)];
    [bezier56Path addLineToPoint: CGPointMake(276.6, 117.73)];
    [bezier56Path addCurveToPoint: CGPointMake(274.19, 118.19) controlPoint1: CGPointMake(275.68, 117.72) controlPoint2: CGPointMake(274.87, 117.88)];
    [bezier56Path addCurveToPoint: CGPointMake(272.48, 119.45) controlPoint1: CGPointMake(273.5, 118.51) controlPoint2: CGPointMake(272.93, 118.93)];
    [bezier56Path addCurveToPoint: CGPointMake(271.45, 121.2) controlPoint1: CGPointMake(272.03, 119.97) controlPoint2: CGPointMake(271.68, 120.55)];
    [bezier56Path addCurveToPoint: CGPointMake(271.09, 123.17) controlPoint1: CGPointMake(271.21, 121.85) controlPoint2: CGPointMake(271.09, 122.5)];
    [bezier56Path addCurveToPoint: CGPointMake(271.42, 125.14) controlPoint1: CGPointMake(271.08, 123.83) controlPoint2: CGPointMake(271.2, 124.48)];
    [bezier56Path addCurveToPoint: CGPointMake(272.44, 126.9) controlPoint1: CGPointMake(271.65, 125.79) controlPoint2: CGPointMake(271.99, 126.38)];
    [bezier56Path addCurveToPoint: CGPointMake(274.13, 128.18) controlPoint1: CGPointMake(272.88, 127.43) controlPoint2: CGPointMake(273.45, 127.85)];
    [bezier56Path addCurveToPoint: CGPointMake(276.53, 128.67) controlPoint1: CGPointMake(274.81, 128.5) controlPoint2: CGPointMake(275.61, 128.66)];
    [bezier56Path addLineToPoint: CGPointMake(283.59, 128.71)];
    [bezier56Path addLineToPoint: CGPointMake(283.62, 122.86)];
    [bezier56Path addLineToPoint: CGPointMake(280.79, 122.84)];
    [bezier56Path addLineToPoint: CGPointMake(280.77, 125.43)];
    [bezier56Path addLineToPoint: CGPointMake(276.55, 125.41)];
    [bezier56Path addCurveToPoint: CGPointMake(274.84, 124.74) controlPoint1: CGPointMake(275.78, 125.4) controlPoint2: CGPointMake(275.21, 125.18)];
    [bezier56Path addCurveToPoint: CGPointMake(274.3, 123.19) controlPoint1: CGPointMake(274.48, 124.3) controlPoint2: CGPointMake(274.3, 123.78)];
    [bezier56Path addCurveToPoint: CGPointMake(274.86, 121.64) controlPoint1: CGPointMake(274.3, 122.59) controlPoint2: CGPointMake(274.49, 122.07)];
    [bezier56Path addCurveToPoint: CGPointMake(276.58, 120.99) controlPoint1: CGPointMake(275.23, 121.2) controlPoint2: CGPointMake(275.8, 120.99)];
    [bezier56Path addLineToPoint: CGPointMake(288.42, 121.07)];
    [bezier56Path addCurveToPoint: CGPointMake(290.13, 121.73) controlPoint1: CGPointMake(289.2, 121.07) controlPoint2: CGPointMake(289.77, 121.29)];
    [bezier56Path addCurveToPoint: CGPointMake(290.68, 123.29) controlPoint1: CGPointMake(290.5, 122.17) controlPoint2: CGPointMake(290.68, 122.69)];
    [bezier56Path addCurveToPoint: CGPointMake(290.12, 124.83) controlPoint1: CGPointMake(290.67, 123.88) controlPoint2: CGPointMake(290.49, 124.4)];
    [bezier56Path addCurveToPoint: CGPointMake(288.4, 125.48) controlPoint1: CGPointMake(289.75, 125.27) controlPoint2: CGPointMake(289.17, 125.48)];
    [bezier56Path addLineToPoint: CGPointMake(288.4, 125.48)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(271.21, 134.87)];
    [bezier56Path addLineToPoint: CGPointMake(293.63, 135.01)];
    [bezier56Path addLineToPoint: CGPointMake(293.65, 131.75)];
    [bezier56Path addLineToPoint: CGPointMake(271.23, 131.61)];
    [bezier56Path addLineToPoint: CGPointMake(271.21, 134.87)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(239.95, 105.01)];
    [bezier56Path addLineToPoint: CGPointMake(235.33, 109.76)];
    [bezier56Path addCurveToPoint: CGPointMake(235.39, 112.82) controlPoint1: CGPointMake(234.5, 110.62) controlPoint2: CGPointMake(234.52, 111.99)];
    [bezier56Path addCurveToPoint: CGPointMake(238.48, 112.76) controlPoint1: CGPointMake(236.26, 113.65) controlPoint2: CGPointMake(237.64, 113.62)];
    [bezier56Path addLineToPoint: CGPointMake(243.09, 108.01)];
    [bezier56Path addCurveToPoint: CGPointMake(243.03, 104.95) controlPoint1: CGPointMake(243.93, 107.15) controlPoint2: CGPointMake(243.9, 105.78)];
    [bezier56Path addCurveToPoint: CGPointMake(239.95, 105.01) controlPoint1: CGPointMake(242.16, 104.13) controlPoint2: CGPointMake(240.78, 104.15)];
    [bezier56Path addLineToPoint: CGPointMake(239.95, 105.01)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(239.58, 95.97)];
    [bezier56Path addLineToPoint: CGPointMake(233.12, 94.39)];
    [bezier56Path addCurveToPoint: CGPointMake(230.48, 95.97) controlPoint1: CGPointMake(231.95, 94.1) controlPoint2: CGPointMake(230.77, 94.81)];
    [bezier56Path addCurveToPoint: CGPointMake(232.07, 98.59) controlPoint1: CGPointMake(230.19, 97.13) controlPoint2: CGPointMake(230.9, 98.3)];
    [bezier56Path addLineToPoint: CGPointMake(238.53, 100.17)];
    [bezier56Path addCurveToPoint: CGPointMake(241.18, 98.59) controlPoint1: CGPointMake(239.7, 100.46) controlPoint2: CGPointMake(240.89, 99.75)];
    [bezier56Path addCurveToPoint: CGPointMake(239.58, 95.97) controlPoint1: CGPointMake(241.47, 97.43) controlPoint2: CGPointMake(240.75, 96.26)];
    [bezier56Path addLineToPoint: CGPointMake(239.58, 95.97)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(245.81, 93.82)];
    [bezier56Path addCurveToPoint: CGPointMake(247.31, 91.14) controlPoint1: CGPointMake(246.97, 93.48) controlPoint2: CGPointMake(247.64, 92.29)];
    [bezier56Path addLineToPoint: CGPointMake(245.46, 84.81)];
    [bezier56Path addCurveToPoint: CGPointMake(242.76, 83.33) controlPoint1: CGPointMake(245.13, 83.66) controlPoint2: CGPointMake(243.92, 83)];
    [bezier56Path addCurveToPoint: CGPointMake(241.27, 86.01) controlPoint1: CGPointMake(241.6, 83.66) controlPoint2: CGPointMake(240.93, 84.86)];
    [bezier56Path addLineToPoint: CGPointMake(243.11, 92.34)];
    [bezier56Path addCurveToPoint: CGPointMake(245.81, 93.82) controlPoint1: CGPointMake(243.45, 93.49) controlPoint2: CGPointMake(244.66, 94.15)];
    [bezier56Path addLineToPoint: CGPointMake(245.81, 93.82)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(249.53, 106.54)];
    [bezier56Path addCurveToPoint: CGPointMake(248.03, 109.22) controlPoint1: CGPointMake(248.37, 106.88) controlPoint2: CGPointMake(247.7, 108.07)];
    [bezier56Path addLineToPoint: CGPointMake(249.88, 115.55)];
    [bezier56Path addCurveToPoint: CGPointMake(252.58, 117.03) controlPoint1: CGPointMake(250.21, 116.7) controlPoint2: CGPointMake(251.42, 117.36)];
    [bezier56Path addCurveToPoint: CGPointMake(254.07, 114.35) controlPoint1: CGPointMake(253.74, 116.7) controlPoint2: CGPointMake(254.41, 115.5)];
    [bezier56Path addLineToPoint: CGPointMake(252.23, 108.02)];
    [bezier56Path addCurveToPoint: CGPointMake(249.53, 106.54) controlPoint1: CGPointMake(251.89, 106.87) controlPoint2: CGPointMake(250.68, 106.21)];
    [bezier56Path addLineToPoint: CGPointMake(249.53, 106.54)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(262.22, 105.97)];
    [bezier56Path addCurveToPoint: CGPointMake(264.86, 104.39) controlPoint1: CGPointMake(263.39, 106.26) controlPoint2: CGPointMake(264.57, 105.55)];
    [bezier56Path addCurveToPoint: CGPointMake(263.27, 101.77) controlPoint1: CGPointMake(265.15, 103.23) controlPoint2: CGPointMake(264.44, 102.06)];
    [bezier56Path addLineToPoint: CGPointMake(256.81, 100.19)];
    [bezier56Path addCurveToPoint: CGPointMake(254.16, 101.77) controlPoint1: CGPointMake(255.64, 99.9) controlPoint2: CGPointMake(254.45, 100.61)];
    [bezier56Path addCurveToPoint: CGPointMake(255.76, 104.39) controlPoint1: CGPointMake(253.87, 102.93) controlPoint2: CGPointMake(254.59, 104.1)];
    [bezier56Path addLineToPoint: CGPointMake(262.22, 105.97)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(255.39, 95.35)];
    [bezier56Path addLineToPoint: CGPointMake(260.01, 90.6)];
    [bezier56Path addCurveToPoint: CGPointMake(259.95, 87.54) controlPoint1: CGPointMake(260.84, 89.74) controlPoint2: CGPointMake(260.82, 88.37)];
    [bezier56Path addCurveToPoint: CGPointMake(256.86, 87.6) controlPoint1: CGPointMake(259.08, 86.71) controlPoint2: CGPointMake(257.7, 86.74)];
    [bezier56Path addLineToPoint: CGPointMake(252.25, 92.35)];
    [bezier56Path addCurveToPoint: CGPointMake(252.31, 95.41) controlPoint1: CGPointMake(251.41, 93.21) controlPoint2: CGPointMake(251.44, 94.58)];
    [bezier56Path addCurveToPoint: CGPointMake(255.39, 95.35) controlPoint1: CGPointMake(253.18, 96.23) controlPoint2: CGPointMake(254.56, 96.21)];
    [bezier56Path addLineToPoint: CGPointMake(255.39, 95.35)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(247.14, 209.14)];
    [bezier56Path addCurveToPoint: CGPointMake(249.93, 207.34) controlPoint1: CGPointMake(248.4, 209.42) controlPoint2: CGPointMake(249.65, 208.61)];
    [bezier56Path addCurveToPoint: CGPointMake(250.44, 192.2) controlPoint1: CGPointMake(250.79, 203.39) controlPoint2: CGPointMake(251, 196.89)];
    [bezier56Path addCurveToPoint: CGPointMake(248.58, 186.27) controlPoint1: CGPointMake(250.12, 189.42) controlPoint2: CGPointMake(249.58, 187.45)];
    [bezier56Path addCurveToPoint: CGPointMake(242.33, 188.03) controlPoint1: CGPointMake(246.5, 183.81) controlPoint2: CGPointMake(243.95, 185.09)];
    [bezier56Path addCurveToPoint: CGPointMake(239.75, 201.46) controlPoint1: CGPointMake(241.05, 190.34) controlPoint2: CGPointMake(240.67, 192.75)];
    [bezier56Path addCurveToPoint: CGPointMake(239.6, 202.81) controlPoint1: CGPointMake(239.69, 201.99) controlPoint2: CGPointMake(239.65, 202.4)];
    [bezier56Path addCurveToPoint: CGPointMake(237.65, 213.42) controlPoint1: CGPointMake(239.02, 208.19) controlPoint2: CGPointMake(238.48, 211.3)];
    [bezier56Path addCurveToPoint: CGPointMake(235.62, 214.92) controlPoint1: CGPointMake(236.91, 215.3) controlPoint2: CGPointMake(236.62, 215.47)];
    [bezier56Path addCurveToPoint: CGPointMake(235.72, 214.61) controlPoint1: CGPointMake(235.8, 215.02) controlPoint2: CGPointMake(235.78, 214.97)];
    [bezier56Path addCurveToPoint: CGPointMake(235.72, 211.56) controlPoint1: CGPointMake(235.6, 213.92) controlPoint2: CGPointMake(235.6, 212.89)];
    [bezier56Path addCurveToPoint: CGPointMake(237.43, 201.59) controlPoint1: CGPointMake(235.93, 209.26) controlPoint2: CGPointMake(236.36, 206.82)];
    [bezier56Path addCurveToPoint: CGPointMake(237.6, 200.78) controlPoint1: CGPointMake(237.52, 201.19) controlPoint2: CGPointMake(237.52, 201.19)];
    [bezier56Path addCurveToPoint: CGPointMake(239.49, 189.31) controlPoint1: CGPointMake(238.8, 194.89) controlPoint2: CGPointMake(239.3, 192.08)];
    [bezier56Path addCurveToPoint: CGPointMake(236.08, 181.1) controlPoint1: CGPointMake(239.8, 184.81) controlPoint2: CGPointMake(239.05, 181.92)];
    [bezier56Path addCurveToPoint: CGPointMake(230.15, 186.87) controlPoint1: CGPointMake(233.21, 180.32) controlPoint2: CGPointMake(231.74, 182.48)];
    [bezier56Path addCurveToPoint: CGPointMake(227.12, 197.61) controlPoint1: CGPointMake(229.26, 189.36) controlPoint2: CGPointMake(228.47, 192.22)];
    [bezier56Path addCurveToPoint: CGPointMake(226.94, 198.32) controlPoint1: CGPointMake(227.03, 197.97) controlPoint2: CGPointMake(227.03, 197.97)];
    [bezier56Path addCurveToPoint: CGPointMake(224.79, 206.53) controlPoint1: CGPointMake(225.89, 202.53) controlPoint2: CGPointMake(225.31, 204.78)];
    [bezier56Path addCurveToPoint: CGPointMake(226.13, 197.35) controlPoint1: CGPointMake(224.98, 204.3) controlPoint2: CGPointMake(225.39, 201.54)];
    [bezier56Path addCurveToPoint: CGPointMake(226.58, 194.8) controlPoint1: CGPointMake(226.24, 196.74) controlPoint2: CGPointMake(226.35, 196.07)];
    [bezier56Path addCurveToPoint: CGPointMake(227.02, 192.3) controlPoint1: CGPointMake(226.76, 193.77) controlPoint2: CGPointMake(226.89, 193.02)];
    [bezier56Path addCurveToPoint: CGPointMake(225.22, 178.75) controlPoint1: CGPointMake(228.73, 182.26) controlPoint2: CGPointMake(228.84, 179.48)];
    [bezier56Path addCurveToPoint: CGPointMake(216.73, 191.02) controlPoint1: CGPointMake(221.97, 178.1) controlPoint2: CGPointMake(219.55, 182.69)];
    [bezier56Path addCurveToPoint: CGPointMake(213.19, 209.27) controlPoint1: CGPointMake(214.38, 197.96) controlPoint2: CGPointMake(212.92, 205.04)];
    [bezier56Path addCurveToPoint: CGPointMake(215.68, 211.46) controlPoint1: CGPointMake(213.28, 210.57) controlPoint2: CGPointMake(214.39, 211.55)];
    [bezier56Path addCurveToPoint: CGPointMake(217.86, 208.95) controlPoint1: CGPointMake(216.97, 211.37) controlPoint2: CGPointMake(217.95, 210.25)];
    [bezier56Path addCurveToPoint: CGPointMake(221.15, 192.53) controlPoint1: CGPointMake(217.63, 205.48) controlPoint2: CGPointMake(218.98, 198.93)];
    [bezier56Path addCurveToPoint: CGPointMake(223.02, 187.62) controlPoint1: CGPointMake(221.76, 190.73) controlPoint2: CGPointMake(222.4, 189.06)];
    [bezier56Path addCurveToPoint: CGPointMake(222.41, 191.52) controlPoint1: CGPointMake(222.87, 188.72) controlPoint2: CGPointMake(222.67, 190)];
    [bezier56Path addCurveToPoint: CGPointMake(221.98, 193.99) controlPoint1: CGPointMake(222.29, 192.23) controlPoint2: CGPointMake(222.16, 192.97)];
    [bezier56Path addCurveToPoint: CGPointMake(221.52, 196.54) controlPoint1: CGPointMake(221.75, 195.26) controlPoint2: CGPointMake(221.63, 195.93)];
    [bezier56Path addCurveToPoint: CGPointMake(222.89, 215.37) controlPoint1: CGPointMake(219.23, 209.65) controlPoint2: CGPointMake(219, 213.86)];
    [bezier56Path addCurveToPoint: CGPointMake(228.63, 209.88) controlPoint1: CGPointMake(225.81, 216.5) controlPoint2: CGPointMake(227.1, 214.44)];
    [bezier56Path addCurveToPoint: CGPointMake(231.48, 199.46) controlPoint1: CGPointMake(229.42, 207.55) controlPoint2: CGPointMake(229.98, 205.42)];
    [bezier56Path addCurveToPoint: CGPointMake(231.65, 198.76) controlPoint1: CGPointMake(231.56, 199.11) controlPoint2: CGPointMake(231.56, 199.11)];
    [bezier56Path addCurveToPoint: CGPointMake(234.55, 188.47) controlPoint1: CGPointMake(232.96, 193.53) controlPoint2: CGPointMake(233.73, 190.76)];
    [bezier56Path addCurveToPoint: CGPointMake(234.87, 187.61) controlPoint1: CGPointMake(234.66, 188.16) controlPoint2: CGPointMake(234.77, 187.88)];
    [bezier56Path addCurveToPoint: CGPointMake(234.82, 188.99) controlPoint1: CGPointMake(234.88, 188.02) controlPoint2: CGPointMake(234.86, 188.48)];
    [bezier56Path addCurveToPoint: CGPointMake(233.02, 199.84) controlPoint1: CGPointMake(234.65, 191.47) controlPoint2: CGPointMake(234.18, 194.17)];
    [bezier56Path addCurveToPoint: CGPointMake(232.85, 200.65) controlPoint1: CGPointMake(232.94, 200.25) controlPoint2: CGPointMake(232.94, 200.25)];
    [bezier56Path addCurveToPoint: CGPointMake(233.36, 219.05) controlPoint1: CGPointMake(230.19, 213.68) controlPoint2: CGPointMake(229.88, 217.12)];
    [bezier56Path addCurveToPoint: CGPointMake(242, 215.14) controlPoint1: CGPointMake(237.22, 221.19) controlPoint2: CGPointMake(240.34, 219.37)];
    [bezier56Path addCurveToPoint: CGPointMake(244.25, 203.31) controlPoint1: CGPointMake(243.04, 212.49) controlPoint2: CGPointMake(243.62, 209.12)];
    [bezier56Path addCurveToPoint: CGPointMake(244.4, 201.95) controlPoint1: CGPointMake(244.3, 202.9) controlPoint2: CGPointMake(244.34, 202.48)];
    [bezier56Path addCurveToPoint: CGPointMake(245.73, 192.22) controlPoint1: CGPointMake(244.94, 196.78) controlPoint2: CGPointMake(245.31, 193.96)];
    [bezier56Path addCurveToPoint: CGPointMake(245.8, 192.77) controlPoint1: CGPointMake(245.75, 192.39) controlPoint2: CGPointMake(245.78, 192.58)];
    [bezier56Path addCurveToPoint: CGPointMake(245.36, 206.34) controlPoint1: CGPointMake(246.3, 196.97) controlPoint2: CGPointMake(246.1, 202.93)];
    [bezier56Path addCurveToPoint: CGPointMake(247.14, 209.14) controlPoint1: CGPointMake(245.08, 207.61) controlPoint2: CGPointMake(245.88, 208.86)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(99.8, 304.29)];
    [bezier56Path addCurveToPoint: CGPointMake(91.79, 298.89) controlPoint1: CGPointMake(98.06, 302.96) controlPoint2: CGPointMake(96.41, 301.86)];
    [bezier56Path addCurveToPoint: CGPointMake(91.25, 298.54) controlPoint1: CGPointMake(91.52, 298.71) controlPoint2: CGPointMake(91.52, 298.71)];
    [bezier56Path addCurveToPoint: CGPointMake(83.37, 293.12) controlPoint1: CGPointMake(87.2, 295.92) controlPoint2: CGPointMake(85.07, 294.48)];
    [bezier56Path addCurveToPoint: CGPointMake(82.75, 292.61) controlPoint1: CGPointMake(83.15, 292.94) controlPoint2: CGPointMake(82.94, 292.77)];
    [bezier56Path addCurveToPoint: CGPointMake(83.89, 293.04) controlPoint1: CGPointMake(83.1, 292.73) controlPoint2: CGPointMake(83.47, 292.86)];
    [bezier56Path addCurveToPoint: CGPointMake(92.57, 297.69) controlPoint1: CGPointMake(85.95, 293.9) controlPoint2: CGPointMake(88.1, 295.08)];
    [bezier56Path addCurveToPoint: CGPointMake(93.21, 298.06) controlPoint1: CGPointMake(92.89, 297.88) controlPoint2: CGPointMake(92.89, 297.88)];
    [bezier56Path addCurveToPoint: CGPointMake(108.96, 302.94) controlPoint1: CGPointMake(103.48, 304.07) controlPoint2: CGPointMake(106.31, 305.33)];
    [bezier56Path addCurveToPoint: CGPointMake(108.17, 294.51) controlPoint1: CGPointMake(111.9, 300.29) controlPoint2: CGPointMake(111.27, 297.13)];
    [bezier56Path addCurveToPoint: CGPointMake(98.79, 289.19) controlPoint1: CGPointMake(106.22, 292.86) controlPoint2: CGPointMake(103.53, 291.4)];
    [bezier56Path addCurveToPoint: CGPointMake(97.68, 288.68) controlPoint1: CGPointMake(98.45, 289.04) controlPoint2: CGPointMake(98.11, 288.88)];
    [bezier56Path addCurveToPoint: CGPointMake(89.81, 284.75) controlPoint1: CGPointMake(93.45, 286.73) controlPoint2: CGPointMake(91.16, 285.61)];
    [bezier56Path addCurveToPoint: CGPointMake(90.3, 284.85) controlPoint1: CGPointMake(89.97, 284.78) controlPoint2: CGPointMake(90.13, 284.81)];
    [bezier56Path addCurveToPoint: CGPointMake(101.68, 289.13) controlPoint1: CGPointMake(94, 285.64) controlPoint2: CGPointMake(99.01, 287.52)];
    [bezier56Path addCurveToPoint: CGPointMake(104.58, 288.43) controlPoint1: CGPointMake(102.68, 289.73) controlPoint2: CGPointMake(103.97, 289.42)];
    [bezier56Path addCurveToPoint: CGPointMake(103.86, 285.55) controlPoint1: CGPointMake(105.18, 287.44) controlPoint2: CGPointMake(104.86, 286.16)];
    [bezier56Path addCurveToPoint: CGPointMake(91.17, 280.76) controlPoint1: CGPointMake(100.76, 283.69) controlPoint2: CGPointMake(95.32, 281.64)];
    [bezier56Path addCurveToPoint: CGPointMake(85.61, 280.62) controlPoint1: CGPointMake(88.72, 280.23) controlPoint2: CGPointMake(86.89, 280.12)];
    [bezier56Path addCurveToPoint: CGPointMake(85.26, 286.42) controlPoint1: CGPointMake(82.91, 281.68) controlPoint2: CGPointMake(83.25, 284.2)];
    [bezier56Path addCurveToPoint: CGPointMake(95.91, 292.47) controlPoint1: CGPointMake(86.85, 288.16) controlPoint2: CGPointMake(88.79, 289.18)];
    [bezier56Path addCurveToPoint: CGPointMake(97, 292.98) controlPoint1: CGPointMake(96.33, 292.67) controlPoint2: CGPointMake(96.68, 292.83)];
    [bezier56Path addCurveToPoint: CGPointMake(105.44, 297.69) controlPoint1: CGPointMake(101.4, 295.02) controlPoint2: CGPointMake(103.88, 296.37)];
    [bezier56Path addCurveToPoint: CGPointMake(106.11, 299.84) controlPoint1: CGPointMake(106.81, 298.85) controlPoint2: CGPointMake(106.87, 299.15)];
    [bezier56Path addCurveToPoint: CGPointMake(105.88, 299.66) controlPoint1: CGPointMake(106.25, 299.71) controlPoint2: CGPointMake(106.21, 299.72)];
    [bezier56Path addCurveToPoint: CGPointMake(103.3, 298.79) controlPoint1: CGPointMake(105.26, 299.56) controlPoint2: CGPointMake(104.39, 299.27)];
    [bezier56Path addCurveToPoint: CGPointMake(95.34, 294.46) controlPoint1: CGPointMake(101.41, 297.95) controlPoint2: CGPointMake(99.47, 296.88)];
    [bezier56Path addCurveToPoint: CGPointMake(94.7, 294.09) controlPoint1: CGPointMake(95.02, 294.28) controlPoint2: CGPointMake(95.02, 294.28)];
    [bezier56Path addCurveToPoint: CGPointMake(85.52, 289.19) controlPoint1: CGPointMake(90.05, 291.37) controlPoint2: CGPointMake(87.82, 290.15)];
    [bezier56Path addCurveToPoint: CGPointMake(77.57, 289.71) controlPoint1: CGPointMake(81.8, 287.63) controlPoint2: CGPointMake(79.13, 287.43)];
    [bezier56Path addCurveToPoint: CGPointMake(80.73, 296.38) controlPoint1: CGPointMake(76.06, 291.9) controlPoint2: CGPointMake(77.47, 293.77)];
    [bezier56Path addCurveToPoint: CGPointMake(88.96, 302.04) controlPoint1: CGPointMake(82.58, 297.85) controlPoint2: CGPointMake(84.78, 299.34)];
    [bezier56Path addCurveToPoint: CGPointMake(89.5, 302.39) controlPoint1: CGPointMake(89.23, 302.22) controlPoint2: CGPointMake(89.23, 302.22)];
    [bezier56Path addCurveToPoint: CGPointMake(95.84, 306.58) controlPoint1: CGPointMake(92.77, 304.5) controlPoint2: CGPointMake(94.51, 305.64)];
    [bezier56Path addCurveToPoint: CGPointMake(88.44, 302.8) controlPoint1: CGPointMake(94, 305.78) controlPoint2: CGPointMake(91.78, 304.63)];
    [bezier56Path addCurveToPoint: CGPointMake(86.42, 301.69) controlPoint1: CGPointMake(87.96, 302.54) controlPoint2: CGPointMake(87.43, 302.24)];
    [bezier56Path addCurveToPoint: CGPointMake(84.42, 300.6) controlPoint1: CGPointMake(85.59, 301.24) controlPoint2: CGPointMake(85, 300.91)];
    [bezier56Path addCurveToPoint: CGPointMake(72.41, 298.21) controlPoint1: CGPointMake(76.4, 296.26) controlPoint2: CGPointMake(74.08, 295.36)];
    [bezier56Path addCurveToPoint: CGPointMake(80.33, 308.93) controlPoint1: CGPointMake(70.91, 300.77) controlPoint2: CGPointMake(74.09, 304.14)];
    [bezier56Path addCurveToPoint: CGPointMake(94.78, 317.17) controlPoint1: CGPointMake(85.53, 312.91) controlPoint2: CGPointMake(91.11, 316.19)];
    [bezier56Path addCurveToPoint: CGPointMake(97.36, 315.7) controlPoint1: CGPointMake(95.91, 317.48) controlPoint2: CGPointMake(97.06, 316.82)];
    [bezier56Path addCurveToPoint: CGPointMake(95.87, 313.13) controlPoint1: CGPointMake(97.66, 314.59) controlPoint2: CGPointMake(96.99, 313.44)];
    [bezier56Path addCurveToPoint: CGPointMake(82.9, 305.62) controlPoint1: CGPointMake(92.86, 312.33) controlPoint2: CGPointMake(87.7, 309.3)];
    [bezier56Path addCurveToPoint: CGPointMake(79.28, 302.63) controlPoint1: CGPointMake(81.56, 304.59) controlPoint2: CGPointMake(80.32, 303.57)];
    [bezier56Path addCurveToPoint: CGPointMake(82.41, 304.27) controlPoint1: CGPointMake(80.17, 303.07) controlPoint2: CGPointMake(81.2, 303.61)];
    [bezier56Path addCurveToPoint: CGPointMake(84.38, 305.34) controlPoint1: CGPointMake(82.98, 304.58) controlPoint2: CGPointMake(83.57, 304.9)];
    [bezier56Path addCurveToPoint: CGPointMake(86.42, 306.46) controlPoint1: CGPointMake(85.39, 305.9) controlPoint2: CGPointMake(85.93, 306.2)];
    [bezier56Path addCurveToPoint: CGPointMake(102.78, 310.73) controlPoint1: CGPointMake(96.86, 312.18) controlPoint2: CGPointMake(100.37, 313.58)];
    [bezier56Path addCurveToPoint: CGPointMake(99.8, 304.29) controlPoint1: CGPointMake(104.59, 308.59) controlPoint2: CGPointMake(103.22, 306.91)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(131.19, 26.16)];
    [bezier56Path addLineToPoint: CGPointMake(147.2, 28.1)];
    [bezier56Path addLineToPoint: CGPointMake(140.65, 35.68)];
    [bezier56Path addCurveToPoint: CGPointMake(141.43, 46.47) controlPoint1: CGPointMake(137.88, 38.88) controlPoint2: CGPointMake(138.23, 43.7)];
    [bezier56Path addLineToPoint: CGPointMake(167.6, 69.09)];
    [bezier56Path addCurveToPoint: CGPointMake(178.38, 68.31) controlPoint1: CGPointMake(170.79, 71.86) controlPoint2: CGPointMake(175.62, 71.51)];
    [bezier56Path addLineToPoint: CGPointMake(201, 42.15)];
    [bezier56Path addCurveToPoint: CGPointMake(200.22, 31.36) controlPoint1: CGPointMake(203.77, 38.94) controlPoint2: CGPointMake(203.42, 34.12)];
    [bezier56Path addLineToPoint: CGPointMake(174.05, 8.73)];
    [bezier56Path addCurveToPoint: CGPointMake(163.27, 9.51) controlPoint1: CGPointMake(170.86, 5.97) controlPoint2: CGPointMake(166.03, 6.32)];
    [bezier56Path addLineToPoint: CGPointMake(156.71, 17.1)];
    [bezier56Path addLineToPoint: CGPointMake(152.49, 1.53)];
    [bezier56Path addCurveToPoint: CGPointMake(148.9, 0.72) controlPoint1: CGPointMake(152.04, -0.07) controlPoint2: CGPointMake(149.99, -0.54)];
    [bezier56Path addLineToPoint: CGPointMake(129.87, 22.72)];
    [bezier56Path addCurveToPoint: CGPointMake(131.19, 26.16) controlPoint1: CGPointMake(128.78, 23.99) controlPoint2: CGPointMake(129.54, 25.95)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(145.33, 237.86)];
    [bezier56Path addCurveToPoint: CGPointMake(159.33, 231.49) controlPoint1: CGPointMake(150.96, 239.96) controlPoint2: CGPointMake(157.23, 237.1)];
    [bezier56Path addCurveToPoint: CGPointMake(152.93, 217.54) controlPoint1: CGPointMake(161.43, 225.87) controlPoint2: CGPointMake(158.56, 219.63)];
    [bezier56Path addCurveToPoint: CGPointMake(138.93, 223.91) controlPoint1: CGPointMake(147.3, 215.44) controlPoint2: CGPointMake(141.03, 218.3)];
    [bezier56Path addCurveToPoint: CGPointMake(145.33, 237.86) controlPoint1: CGPointMake(136.83, 229.53) controlPoint2: CGPointMake(139.69, 235.77)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(146.39, 247.52)];
    [bezier56Path addLineToPoint: CGPointMake(138.19, 244.47)];
    [bezier56Path addCurveToPoint: CGPointMake(136.49, 241.56) controlPoint1: CGPointMake(137.07, 244.06) controlPoint2: CGPointMake(136.31, 242.77)];
    [bezier56Path addLineToPoint: CGPointMake(136.81, 239.33)];
    [bezier56Path addLineToPoint: CGPointMake(131.56, 237.38)];
    [bezier56Path addCurveToPoint: CGPointMake(129.01, 231.79) controlPoint1: CGPointMake(129.31, 236.55) controlPoint2: CGPointMake(128.17, 234.05)];
    [bezier56Path addLineToPoint: CGPointMake(136.61, 211.49)];
    [bezier56Path addCurveToPoint: CGPointMake(142.2, 208.92) controlPoint1: CGPointMake(137.45, 209.24) controlPoint2: CGPointMake(139.95, 208.09)];
    [bezier56Path addLineToPoint: CGPointMake(166.7, 218.02)];
    [bezier56Path addCurveToPoint: CGPointMake(169.25, 223.61) controlPoint1: CGPointMake(168.95, 218.85) controlPoint2: CGPointMake(170.09, 221.35)];
    [bezier56Path addLineToPoint: CGPointMake(161.65, 243.91)];
    [bezier56Path addCurveToPoint: CGPointMake(156.06, 246.48) controlPoint1: CGPointMake(160.81, 246.16) controlPoint2: CGPointMake(158.3, 247.31)];
    [bezier56Path addLineToPoint: CGPointMake(150.8, 244.53)];
    [bezier56Path addLineToPoint: CGPointMake(149.59, 246.43)];
    [bezier56Path addCurveToPoint: CGPointMake(146.39, 247.52) controlPoint1: CGPointMake(148.94, 247.44) controlPoint2: CGPointMake(147.49, 247.93)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(155.25, 229.97)];
    [bezier56Path addCurveToPoint: CGPointMake(151.41, 221.6) controlPoint1: CGPointMake(156.51, 226.6) controlPoint2: CGPointMake(154.79, 222.86)];
    [bezier56Path addCurveToPoint: CGPointMake(143.01, 225.43) controlPoint1: CGPointMake(148.03, 220.35) controlPoint2: CGPointMake(144.27, 222.06)];
    [bezier56Path addCurveToPoint: CGPointMake(146.85, 233.8) controlPoint1: CGPointMake(141.75, 228.8) controlPoint2: CGPointMake(143.47, 232.54)];
    [bezier56Path addCurveToPoint: CGPointMake(155.25, 229.97) controlPoint1: CGPointMake(150.23, 235.05) controlPoint2: CGPointMake(153.99, 233.34)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(81.78, 45.75)];
    [bezier56Path addCurveToPoint: CGPointMake(84.81, 40.38) controlPoint1: CGPointMake(84.1, 45.1) controlPoint2: CGPointMake(85.45, 42.7)];
    [bezier56Path addCurveToPoint: CGPointMake(79.44, 37.36) controlPoint1: CGPointMake(84.16, 38.07) controlPoint2: CGPointMake(81.76, 36.72)];
    [bezier56Path addCurveToPoint: CGPointMake(76.42, 42.72) controlPoint1: CGPointMake(77.13, 38.01) controlPoint2: CGPointMake(75.77, 40.41)];
    [bezier56Path addCurveToPoint: CGPointMake(81.78, 45.75) controlPoint1: CGPointMake(77.06, 45.04) controlPoint2: CGPointMake(79.46, 46.39)];
    [bezier56Path addLineToPoint: CGPointMake(81.78, 45.75)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(61.49, 37.84)];
    [bezier56Path addLineToPoint: CGPointMake(66.77, 56.75)];
    [bezier56Path addLineToPoint: CGPointMake(73.98, 50.18)];
    [bezier56Path addLineToPoint: CGPointMake(92.79, 52.81)];
    [bezier56Path addLineToPoint: CGPointMake(86.66, 30.83)];
    [bezier56Path addLineToPoint: CGPointMake(61.49, 37.84)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(56.71, 36.92)];
    [bezier56Path addCurveToPoint: CGPointMake(58.23, 34.24) controlPoint1: CGPointMake(56.39, 35.76) controlPoint2: CGPointMake(57.06, 34.56)];
    [bezier56Path addLineToPoint: CGPointMake(87.59, 26.06)];
    [bezier56Path addCurveToPoint: CGPointMake(90.27, 27.57) controlPoint1: CGPointMake(88.75, 25.73) controlPoint2: CGPointMake(89.95, 26.4)];
    [bezier56Path addLineToPoint: CGPointMake(98.46, 56.91)];
    [bezier56Path addCurveToPoint: CGPointMake(96.94, 59.59) controlPoint1: CGPointMake(98.78, 58.07) controlPoint2: CGPointMake(98.11, 59.27)];
    [bezier56Path addLineToPoint: CGPointMake(67.58, 67.77)];
    [bezier56Path addCurveToPoint: CGPointMake(64.9, 66.26) controlPoint1: CGPointMake(66.42, 68.09) controlPoint2: CGPointMake(65.22, 67.42)];
    [bezier56Path addLineToPoint: CGPointMake(56.71, 36.92)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(215.23, 53.81)];
    [bezier56Path addCurveToPoint: CGPointMake(228.48, 60.44) controlPoint1: CGPointMake(217.04, 59.27) controlPoint2: CGPointMake(222.97, 62.24)];
    [bezier56Path addCurveToPoint: CGPointMake(235.17, 47.31) controlPoint1: CGPointMake(233.98, 58.65) controlPoint2: CGPointMake(236.98, 52.77)];
    [bezier56Path addCurveToPoint: CGPointMake(221.92, 40.68) controlPoint1: CGPointMake(233.36, 41.85) controlPoint2: CGPointMake(227.43, 38.88)];
    [bezier56Path addCurveToPoint: CGPointMake(215.23, 53.81) controlPoint1: CGPointMake(216.42, 42.47) controlPoint2: CGPointMake(213.42, 48.35)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(208.64, 40.63)];
    [bezier56Path addLineToPoint: CGPointMake(232.58, 32.82)];
    [bezier56Path addCurveToPoint: CGPointMake(237.87, 35.49) controlPoint1: CGPointMake(234.78, 32.11) controlPoint2: CGPointMake(237.15, 33.3)];
    [bezier56Path addLineToPoint: CGPointMake(244.42, 55.23)];
    [bezier56Path addCurveToPoint: CGPointMake(241.76, 60.49) controlPoint1: CGPointMake(245.14, 57.42) controlPoint2: CGPointMake(243.95, 59.78)];
    [bezier56Path addLineToPoint: CGPointMake(236.62, 62.17)];
    [bezier56Path addLineToPoint: CGPointMake(236.85, 64.31)];
    [bezier56Path addCurveToPoint: CGPointMake(235.1, 67.04) controlPoint1: CGPointMake(236.98, 65.46) controlPoint2: CGPointMake(236.18, 66.69)];
    [bezier56Path addLineToPoint: CGPointMake(227.09, 69.65)];
    [bezier56Path addCurveToPoint: CGPointMake(224.05, 68.49) controlPoint1: CGPointMake(226, 70.01) controlPoint2: CGPointMake(224.65, 69.5)];
    [bezier56Path addLineToPoint: CGPointMake(222.95, 66.62)];
    [bezier56Path addLineToPoint: CGPointMake(217.81, 68.3)];
    [bezier56Path addCurveToPoint: CGPointMake(212.52, 65.63) controlPoint1: CGPointMake(215.62, 69.01) controlPoint2: CGPointMake(213.25, 67.82)];
    [bezier56Path addLineToPoint: CGPointMake(205.98, 45.89)];
    [bezier56Path addCurveToPoint: CGPointMake(208.64, 40.63) controlPoint1: CGPointMake(205.25, 43.7) controlPoint2: CGPointMake(206.45, 41.34)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(227.16, 56.49)];
    [bezier56Path addCurveToPoint: CGPointMake(231.18, 48.61) controlPoint1: CGPointMake(230.47, 55.41) controlPoint2: CGPointMake(232.26, 51.89)];
    [bezier56Path addCurveToPoint: CGPointMake(223.23, 44.63) controlPoint1: CGPointMake(230.09, 45.34) controlPoint2: CGPointMake(226.53, 43.55)];
    [bezier56Path addCurveToPoint: CGPointMake(219.22, 52.51) controlPoint1: CGPointMake(219.93, 45.71) controlPoint2: CGPointMake(218.13, 49.23)];
    [bezier56Path addCurveToPoint: CGPointMake(227.16, 56.49) controlPoint1: CGPointMake(220.3, 55.78) controlPoint2: CGPointMake(223.86, 57.57)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(199.25, 307.79)];
    [bezier56Path addLineToPoint: CGPointMake(198.56, 308.15)];
    [bezier56Path addCurveToPoint: CGPointMake(192.82, 314.29) controlPoint1: CGPointMake(197.45, 310.69) controlPoint2: CGPointMake(195.49, 312.89)];
    [bezier56Path addCurveToPoint: CGPointMake(184.44, 315.53) controlPoint1: CGPointMake(190.15, 315.69) controlPoint2: CGPointMake(187.2, 316.05)];
    [bezier56Path addLineToPoint: CGPointMake(183.75, 315.89)];
    [bezier56Path addCurveToPoint: CGPointMake(181.01, 324.67) controlPoint1: CGPointMake(180.53, 317.58) controlPoint2: CGPointMake(179.31, 321.5)];
    [bezier56Path addLineToPoint: CGPointMake(182.32, 327.1)];
    [bezier56Path addCurveToPoint: CGPointMake(197.67, 323.31) controlPoint1: CGPointMake(187.51, 327.09) controlPoint2: CGPointMake(192.77, 325.87)];
    [bezier56Path addCurveToPoint: CGPointMake(209.46, 312.91) controlPoint1: CGPointMake(202.57, 320.75) controlPoint2: CGPointMake(206.55, 317.14)];
    [bezier56Path addLineToPoint: CGPointMake(208.16, 310.48)];
    [bezier56Path addCurveToPoint: CGPointMake(199.25, 307.79) controlPoint1: CGPointMake(206.46, 307.32) controlPoint2: CGPointMake(202.47, 306.11)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(190.93, 310.77)];
    [bezier56Path addCurveToPoint: CGPointMake(194.57, 299.07) controlPoint1: CGPointMake(195.21, 308.53) controlPoint2: CGPointMake(196.84, 303.29)];
    [bezier56Path addCurveToPoint: CGPointMake(182.7, 295.47) controlPoint1: CGPointMake(192.3, 294.84) controlPoint2: CGPointMake(186.98, 293.23)];
    [bezier56Path addCurveToPoint: CGPointMake(179.06, 307.18) controlPoint1: CGPointMake(178.42, 297.71) controlPoint2: CGPointMake(176.79, 302.95)];
    [bezier56Path addCurveToPoint: CGPointMake(190.93, 310.77) controlPoint1: CGPointMake(181.33, 311.4) controlPoint2: CGPointMake(186.64, 313.01)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(71.08, 94.75)];
    [bezier56Path addCurveToPoint: CGPointMake(70.57, 103.26) controlPoint1: CGPointMake(68.57, 96.96) controlPoint2: CGPointMake(68.34, 100.77)];
    [bezier56Path addCurveToPoint: CGPointMake(79.16, 103.76) controlPoint1: CGPointMake(72.81, 105.75) controlPoint2: CGPointMake(76.65, 105.97)];
    [bezier56Path addCurveToPoint: CGPointMake(79.67, 95.25) controlPoint1: CGPointMake(81.67, 101.55) controlPoint2: CGPointMake(81.9, 97.74)];
    [bezier56Path addCurveToPoint: CGPointMake(71.08, 94.75) controlPoint1: CGPointMake(77.44, 92.76) controlPoint2: CGPointMake(73.59, 92.54)];
    [bezier56Path addLineToPoint: CGPointMake(71.08, 94.75)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(82.7, 92.58)];
    [bezier56Path addCurveToPoint: CGPointMake(68.38, 91.75) controlPoint1: CGPointMake(78.98, 88.43) controlPoint2: CGPointMake(72.57, 88.06)];
    [bezier56Path addCurveToPoint: CGPointMake(67.54, 105.93) controlPoint1: CGPointMake(64.2, 95.43) controlPoint2: CGPointMake(63.82, 101.78)];
    [bezier56Path addCurveToPoint: CGPointMake(81.86, 106.77) controlPoint1: CGPointMake(71.26, 110.08) controlPoint2: CGPointMake(77.67, 110.45)];
    [bezier56Path addCurveToPoint: CGPointMake(82.7, 92.58) controlPoint1: CGPointMake(86.04, 103.08) controlPoint2: CGPointMake(86.42, 96.73)];
    [bezier56Path addLineToPoint: CGPointMake(82.7, 92.58)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(93.82, 98.93)];
    [bezier56Path addCurveToPoint: CGPointMake(93.47, 104.6) controlPoint1: CGPointMake(95.31, 100.59) controlPoint2: CGPointMake(95.15, 103.12)];
    [bezier56Path addLineToPoint: CGPointMake(78.33, 117.94)];
    [bezier56Path addCurveToPoint: CGPointMake(72.6, 117.62) controlPoint1: CGPointMake(76.65, 119.42) controlPoint2: CGPointMake(74.08, 119.27)];
    [bezier56Path addLineToPoint: CGPointMake(69.13, 113.75)];
    [bezier56Path addLineToPoint: CGPointMake(67.3, 114.78)];
    [bezier56Path addCurveToPoint: CGPointMake(64.19, 114.29) controlPoint1: CGPointMake(66.32, 115.33) controlPoint2: CGPointMake(64.91, 115.1)];
    [bezier56Path addLineToPoint: CGPointMake(58.77, 108.25)];
    [bezier56Path addCurveToPoint: CGPointMake(58.64, 105.13) controlPoint1: CGPointMake(58.03, 107.43) controlPoint2: CGPointMake(57.97, 106.05)];
    [bezier56Path addLineToPoint: CGPointMake(59.89, 103.45)];
    [bezier56Path addLineToPoint: CGPointMake(56.42, 99.58)];
    [bezier56Path addCurveToPoint: CGPointMake(56.77, 93.91) controlPoint1: CGPointMake(54.93, 97.93) controlPoint2: CGPointMake(55.09, 95.39)];
    [bezier56Path addLineToPoint: CGPointMake(71.91, 80.57)];
    [bezier56Path addCurveToPoint: CGPointMake(77.64, 80.89) controlPoint1: CGPointMake(73.59, 79.09) controlPoint2: CGPointMake(76.16, 79.24)];
    [bezier56Path addLineToPoint: CGPointMake(93.82, 98.93)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(200.9, 200.77)];
    [bezier56Path addCurveToPoint: CGPointMake(203.17, 210.98) controlPoint1: CGPointMake(204.36, 203.02) controlPoint2: CGPointMake(205.36, 207.6)];
    [bezier56Path addLineToPoint: CGPointMake(198.97, 217.44)];
    [bezier56Path addCurveToPoint: CGPointMake(190.19, 220.27) controlPoint1: CGPointMake(197.07, 220.36) controlPoint2: CGPointMake(193.39, 221.47)];
    [bezier56Path addCurveToPoint: CGPointMake(188.72, 219.53) controlPoint1: CGPointMake(189.69, 220.08) controlPoint2: CGPointMake(189.19, 219.84)];
    [bezier56Path addCurveToPoint: CGPointMake(185.4, 214.54) controlPoint1: CGPointMake(186.89, 218.34) controlPoint2: CGPointMake(185.75, 216.5)];
    [bezier56Path addCurveToPoint: CGPointMake(186.45, 209.31) controlPoint1: CGPointMake(185.09, 212.78) controlPoint2: CGPointMake(185.42, 210.91)];
    [bezier56Path addLineToPoint: CGPointMake(190.65, 202.85)];
    [bezier56Path addCurveToPoint: CGPointMake(200.9, 200.77) controlPoint1: CGPointMake(192.85, 199.47) controlPoint2: CGPointMake(197.44, 198.52)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(186.69, 222.66)];
    [bezier56Path addCurveToPoint: CGPointMake(193.69, 224.46) controlPoint1: CGPointMake(188.86, 224.06) controlPoint2: CGPointMake(191.32, 224.64)];
    [bezier56Path addCurveToPoint: CGPointMake(195.87, 224.08) controlPoint1: CGPointMake(194.43, 224.41) controlPoint2: CGPointMake(195.16, 224.28)];
    [bezier56Path addLineToPoint: CGPointMake(196.65, 227.74)];
    [bezier56Path addCurveToPoint: CGPointMake(184.66, 225.78) controlPoint1: CGPointMake(192.73, 228.76) controlPoint2: CGPointMake(188.37, 228.19)];
    [bezier56Path addCurveToPoint: CGPointMake(177.99, 215.62) controlPoint1: CGPointMake(180.95, 223.37) controlPoint2: CGPointMake(178.65, 219.62)];
    [bezier56Path addLineToPoint: CGPointMake(181.65, 214.85)];
    [bezier56Path addCurveToPoint: CGPointMake(186.69, 222.66) controlPoint1: CGPointMake(182.1, 217.92) controlPoint2: CGPointMake(183.84, 220.81)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(44.43, 206.92)];
    [bezier56Path addCurveToPoint: CGPointMake(49.51, 217.35) controlPoint1: CGPointMake(42.95, 211.21) controlPoint2: CGPointMake(45.23, 215.87)];
    [bezier56Path addCurveToPoint: CGPointMake(59.94, 212.27) controlPoint1: CGPointMake(53.8, 218.82) controlPoint2: CGPointMake(58.47, 216.55)];
    [bezier56Path addCurveToPoint: CGPointMake(54.85, 201.84) controlPoint1: CGPointMake(61.42, 207.99) controlPoint2: CGPointMake(59.14, 203.32)];
    [bezier56Path addCurveToPoint: CGPointMake(44.43, 206.92) controlPoint1: CGPointMake(50.57, 200.37) controlPoint2: CGPointMake(45.9, 202.64)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(57.52, 194.09)];
    [bezier56Path addCurveToPoint: CGPointMake(62.81, 197.1) controlPoint1: CGPointMake(59.52, 194.78) controlPoint2: CGPointMake(61.29, 195.81)];
    [bezier56Path addCurveToPoint: CGPointMake(67.7, 214.94) controlPoint1: CGPointMake(67.81, 201.34) controlPoint2: CGPointMake(69.96, 208.37)];
    [bezier56Path addCurveToPoint: CGPointMake(43.29, 235.44) controlPoint1: CGPointMake(62.36, 230.44) controlPoint2: CGPointMake(43.29, 235.44)];
    [bezier56Path addCurveToPoint: CGPointMake(36.67, 204.25) controlPoint1: CGPointMake(43.29, 235.44) controlPoint2: CGPointMake(31.33, 219.76)];
    [bezier56Path addCurveToPoint: CGPointMake(57.52, 194.09) controlPoint1: CGPointMake(39.62, 195.69) controlPoint2: CGPointMake(48.95, 191.14)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(30.1, 135.51)];
    [bezier56Path addCurveToPoint: CGPointMake(25.35, 141.86) controlPoint1: CGPointMake(30.1, 135.51) controlPoint2: CGPointMake(25.35, 141.86)];
    [bezier56Path addCurveToPoint: CGPointMake(21.39, 142.58) controlPoint1: CGPointMake(24.44, 143.09) controlPoint2: CGPointMake(22.73, 143.36)];
    [bezier56Path addLineToPoint: CGPointMake(14.88, 137.71)];
    [bezier56Path addCurveToPoint: CGPointMake(21, 136.83) controlPoint1: CGPointMake(14.88, 137.71) controlPoint2: CGPointMake(17.75, 137.3)];
    [bezier56Path addCurveToPoint: CGPointMake(30.1, 135.51) controlPoint1: CGPointMake(25.23, 136.22) controlPoint2: CGPointMake(30.1, 135.51)];
    [bezier56Path addLineToPoint: CGPointMake(30.1, 135.51)];
    [bezier56Path closePath];
    [bezier56Path moveToPoint: CGPointMake(31.84, 136.82)];
    [bezier56Path addCurveToPoint: CGPointMake(47.53, 148.54) controlPoint1: CGPointMake(31.84, 136.81) controlPoint2: CGPointMake(47.53, 148.54)];
    [bezier56Path addCurveToPoint: CGPointMake(47.96, 151.59) controlPoint1: CGPointMake(48.47, 149.25) controlPoint2: CGPointMake(48.68, 150.62)];
    [bezier56Path addLineToPoint: CGPointMake(34.94, 169.01)];
    [bezier56Path addCurveToPoint: CGPointMake(31.89, 169.45) controlPoint1: CGPointMake(34.23, 169.96) controlPoint2: CGPointMake(32.86, 170.17)];
    [bezier56Path addLineToPoint: CGPointMake(7.51, 151.21)];
    [bezier56Path addCurveToPoint: CGPointMake(7.05, 148.18) controlPoint1: CGPointMake(6.54, 150.49) controlPoint2: CGPointMake(6.34, 149.14)];
    [bezier56Path addLineToPoint: CGPointMake(13.57, 139.46)];
    [bezier56Path addLineToPoint: CGPointMake(20.53, 144.66)];
    [bezier56Path addCurveToPoint: CGPointMake(26.67, 143.74) controlPoint1: CGPointMake(22.48, 146.12) controlPoint2: CGPointMake(25.21, 145.69)];
    [bezier56Path addLineToPoint: CGPointMake(31.84, 136.81)];
    [bezier56Path addLineToPoint: CGPointMake(31.84, 136.82)];
    [bezier56Path closePath];
    [color setFill];
    [bezier56Path fill];
}

+ (void)drawMentionsWithFrame: (CGRect)frame backgroundColor: (UIColor*)backgroundColor
{
    //// Color Declarations
    UIColor* black40 = [backgroundColor colorWithAlphaComponent: 0.4];


    //// Subframes
    CGRect frame2 = CGRectMake(CGRectGetMinX(frame) + floor((frame.size.width - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((frame.size.height - 12) * 1.00000 + 0.5), 16, 12);


    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMinY(frame) + 1)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 25, CGRectGetMinY(frame) + 1)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 32) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 11.7, CGRectGetMinY(frame) + 1) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 45.3)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 25, CGRectGetMaxY(frame) - 8) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 1, CGRectGetMaxY(frame) - 18.7) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 11.7, CGRectGetMaxY(frame) - 8)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 1, CGRectGetMinY(frame2) + 0.33333 * frame2.size.height)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 8, CGRectGetMinY(frame2) + 0.91667 * frame2.size.height)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 15, CGRectGetMinY(frame2) + 0.33333 * frame2.size.height)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMaxY(frame) - 8)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 32) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 11.7, CGRectGetMaxY(frame) - 8) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 18.7)];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 25, CGRectGetMinY(frame) + 1) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMaxY(frame) - 45.3) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 11.7, CGRectGetMinY(frame) + 1)];
    [bezierPath closePath];
    [black40 setFill];
    [bezierPath fill];


    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMinY(frame))];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 24.28, CGRectGetMinY(frame))];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 32.13) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 10.82, CGRectGetMinY(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 45.91)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 24.28, CGRectGetMaxY(frame) - 7.25) controlPoint1: CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - 18.34) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 10.82, CGRectGetMaxY(frame) - 7.25)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 0.92, CGRectGetMinY(frame2) + 0.39545 * frame2.size.height)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 8, CGRectGetMinY(frame2) + 1.00000 * frame2.size.height)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame2) + 15.08, CGRectGetMinY(frame2) + 0.39545 * frame2.size.height)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMaxY(frame) - 7.25)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 32.13) controlPoint1: CGPointMake(CGRectGetMaxX(frame) - 10.82, CGRectGetMaxY(frame) - 7.25) controlPoint2: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 18.34)];
    [bezier2Path addCurveToPoint: CGPointMake(CGRectGetMaxX(frame) - 24.28, CGRectGetMinY(frame)) controlPoint1: CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - 45.91) controlPoint2: CGPointMake(CGRectGetMaxX(frame) - 10.82, CGRectGetMinY(frame))];
    [bezier2Path closePath];
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
    [color setStroke];
    bezierPath.lineWidth = 1;
    bezierPath.lineJoinStyle = kCGLineJoinRound;
    [bezierPath stroke];
}

#pragma mark Generated Images

+ (UIImage*)imageOfIcon_0x100_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x100_32ptWithColor: color];

    UIImage* imageOfIcon_0x100_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x100_32pt;
}

+ (UIImage*)imageOfIcon_0x102_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x102_32ptWithColor: color];

    UIImage* imageOfIcon_0x102_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x102_32pt;
}

+ (UIImage*)imageOfIcon_0x104_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x104_32ptWithColor: color];

    UIImage* imageOfIcon_0x104_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x104_32pt;
}

+ (UIImage*)imageOfIcon_0x120_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x120_32ptWithColor: color];

    UIImage* imageOfIcon_0x120_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x120_32pt;
}

+ (UIImage*)imageOfIcon_0x125_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x125_32ptWithColor: color];

    UIImage* imageOfIcon_0x125_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x125_32pt;
}

+ (UIImage*)imageOfIcon_0x137_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x137_32ptWithColor: color];

    UIImage* imageOfIcon_0x137_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x137_32pt;
}

+ (UIImage*)imageOfIcon_0x143_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x143_32ptWithColor: color];

    UIImage* imageOfIcon_0x143_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x143_32pt;
}

+ (UIImage*)imageOfIcon_0x144_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x144_32ptWithColor: color];

    UIImage* imageOfIcon_0x144_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x144_32pt;
}

+ (UIImage*)imageOfIcon_0x145_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x145_32ptWithColor: color];

    UIImage* imageOfIcon_0x145_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x145_32pt;
}

+ (UIImage*)imageOfIcon_0x150_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x150_32ptWithColor: color];

    UIImage* imageOfIcon_0x150_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x150_32pt;
}

+ (UIImage*)imageOfIcon_0x158_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x158_32ptWithColor: color];

    UIImage* imageOfIcon_0x158_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x158_32pt;
}

+ (UIImage*)imageOfIcon_0x162_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x162_32ptWithColor: color];

    UIImage* imageOfIcon_0x162_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x162_32pt;
}

+ (UIImage*)imageOfIcon_0x177_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x177_32ptWithColor: color];

    UIImage* imageOfIcon_0x177_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x177_32pt;
}

+ (UIImage*)imageOfIcon_0x193_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x193_32ptWithColor: color];

    UIImage* imageOfIcon_0x193_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x193_32pt;
}

+ (UIImage*)imageOfIcon_0x194_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x194_32ptWithColor: color];

    UIImage* imageOfIcon_0x194_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x194_32pt;
}

+ (UIImage*)imageOfIcon_0x195_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x195_32ptWithColor: color];

    UIImage* imageOfIcon_0x195_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x195_32pt;
}

+ (UIImage*)imageOfIcon_0x197_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x197_32ptWithColor: color];

    UIImage* imageOfIcon_0x197_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x197_32pt;
}

+ (UIImage*)imageOfIcon_0x205_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x205_32ptWithColor: color];

    UIImage* imageOfIcon_0x205_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x205_32pt;
}

+ (UIImage*)imageOfIcon_0x212_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x212_32ptWithColor: color];

    UIImage* imageOfIcon_0x212_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x212_32pt;
}

+ (UIImage*)imageOfIcon_0x198_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x198_32ptWithColor: color];

    UIImage* imageOfIcon_0x198_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x198_32pt;
}

+ (UIImage*)imageOfIcon_0x217_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x217_32ptWithColor: color];

    UIImage* imageOfIcon_0x217_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x217_32pt;
}

+ (UIImage*)imageOfIcon_0x117_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x117_32ptWithColor: color];

    UIImage* imageOfIcon_0x117_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x117_32pt;
}

+ (UIImage*)imageOfIcon_0x126_24ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(48, 48), NO, 0);
    [WireStyleKit drawIcon_0x126_24ptWithColor: color];

    UIImage* imageOfIcon_0x126_24pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x126_24pt;
}

+ (UIImage*)imageOfIcon_0x128_8ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    [WireStyleKit drawIcon_0x128_8ptWithColor: color];

    UIImage* imageOfIcon_0x128_8pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x128_8pt;
}

+ (UIImage*)imageOfIcon_0x163_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x163_32ptWithColor: color];

    UIImage* imageOfIcon_0x163_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x163_32pt;
}

+ (UIImage*)imageOfIcon_0x221_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x221_32ptWithColor: color];

    UIImage* imageOfIcon_0x221_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x221_32pt;
}

+ (UIImage*)imageOfInviteWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    [WireStyleKit drawInviteWithColor: color];

    UIImage* imageOfInvite = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfInvite;
}

+ (UIImage*)imageOfIcon_0x123_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x123_32ptWithColor: color];

    UIImage* imageOfIcon_0x123_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x123_32pt;
}

+ (UIImage*)imageOfIcon_0x128_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x128_32ptWithColor: color];

    UIImage* imageOfIcon_0x128_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x128_32pt;
}

+ (UIImage*)imageOfIcon_0x113_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x113_32ptWithColor: color];

    UIImage* imageOfIcon_0x113_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x113_32pt;
}

+ (UIImage*)imageOfIcon_0x121_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x121_32ptWithColor: color];

    UIImage* imageOfIcon_0x121_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x121_32pt;
}

+ (UIImage*)imageOfIcon_0x111_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x111_32ptWithColor: color];

    UIImage* imageOfIcon_0x111_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x111_32pt;
}

+ (UIImage*)imageOfIcon_0x226_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x226_32ptWithColor: color];

    UIImage* imageOfIcon_0x226_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x226_32pt;
}

+ (UIImage*)imageOfIcon_0x164_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x164_32ptWithColor: color];

    UIImage* imageOfIcon_0x164_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x164_32pt;
}

+ (UIImage*)imageOfIcon_0x1420_28ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(56, 56), NO, 0);
    [WireStyleKit drawIcon_0x1420_28ptWithColor: color];

    UIImage* imageOfIcon_0x1420_28pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x1420_28pt;
}

+ (UIImage*)imageOfIcon_0x110_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x110_32ptWithColor: color];

    UIImage* imageOfIcon_0x110_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x110_32pt;
}

+ (UIImage*)imageOfIcon_0x103_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x103_32ptWithColor: color];

    UIImage* imageOfIcon_0x103_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x103_32pt;
}

+ (UIImage*)imageOfIcon_0x211_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x211_32ptWithColor: color];

    UIImage* imageOfIcon_0x211_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x211_32pt;
}

+ (UIImage*)imageOfIcon_0x142_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x142_32ptWithColor: color];

    UIImage* imageOfIcon_0x142_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x142_32pt;
}

+ (UIImage*)imageOfIcon_0x152_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x152_32ptWithColor: color];

    UIImage* imageOfIcon_0x152_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x152_32pt;
}

+ (UIImage*)imageOfIcon_0x146_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x146_32ptWithColor: color];

    UIImage* imageOfIcon_0x146_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x146_32pt;
}

+ (UIImage*)imageOfIcon_0x227_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x227_32ptWithColor: color];

    UIImage* imageOfIcon_0x227_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x227_32pt;
}

+ (UIImage*)imageOfIcon_0x159_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x159_32ptWithColor: color];

    UIImage* imageOfIcon_0x159_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x159_32pt;
}

+ (UIImage*)imageOfIcon_0x228_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x228_32ptWithColor: color];

    UIImage* imageOfIcon_0x228_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x228_32pt;
}

+ (UIImage*)imageOfIcon_0x154_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x154_32ptWithColor: color];

    UIImage* imageOfIcon_0x154_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x154_32pt;
}

+ (UIImage*)imageOfIcon_0x148_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x148_32ptWithColor: color];

    UIImage* imageOfIcon_0x148_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x148_32pt;
}

+ (UIImage*)imageOfIcon_0x229_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x229_32ptWithColor: color];

    UIImage* imageOfIcon_0x229_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x229_32pt;
}

+ (UIImage*)imageOfIcon_0x230_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x230_32ptWithColor: color];

    UIImage* imageOfIcon_0x230_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x230_32pt;
}

+ (UIImage*)imageOfIcon_0x149_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x149_32ptWithColor: color];

    UIImage* imageOfIcon_0x149_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x149_32pt;
}

+ (UIImage*)imageOfIcon_0x240_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x240_32ptWithColor: color];

    UIImage* imageOfIcon_0x240_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x240_32pt;
}

+ (UIImage*)imageOfIcon_0x244_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x244_32ptWithColor: color];

    UIImage* imageOfIcon_0x244_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x244_32pt;
}

+ (UIImage*)imageOfIcon_0x246_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x246_32ptWithColor: color];

    UIImage* imageOfIcon_0x246_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x246_32pt;
}

+ (UIImage*)imageOfIcon_0x245_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x245_32ptWithColor: color];

    UIImage* imageOfIcon_0x245_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x245_32pt;
}

+ (UIImage*)imageOfIcon_0x242_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x242_32ptWithColor: color];

    UIImage* imageOfIcon_0x242_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x242_32pt;
}

+ (UIImage*)imageOfIcon_0x247_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x247_32ptWithColor: color];

    UIImage* imageOfIcon_0x247_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x247_32pt;
}

+ (UIImage*)imageOfIcon_0x243_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x243_32ptWithColor: color];

    UIImage* imageOfIcon_0x243_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x243_32pt;
}

+ (UIImage*)imageOfIcon_0x139_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x139_32ptWithColor: color];

    UIImage* imageOfIcon_0x139_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x139_32pt;
}

+ (UIImage*)imageOfIcon_0x183_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x183_32ptWithColor: color];

    UIImage* imageOfIcon_0x183_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x183_32pt;
}

+ (UIImage*)imageOfIcon_0x184_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x184_32ptWithColor: color];

    UIImage* imageOfIcon_0x184_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x184_32pt;
}

+ (UIImage*)imageOfIcon_0x202_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x202_32ptWithColor: color];

    UIImage* imageOfIcon_0x202_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x202_32pt;
}

+ (UIImage*)imageOfIcon_0x235_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x235_32ptWithColor: color];

    UIImage* imageOfIcon_0x235_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x235_32pt;
}

+ (UIImage*)imageOfIcon_0x237_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x237_32ptWithColor: color];

    UIImage* imageOfIcon_0x237_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x237_32pt;
}

+ (UIImage*)imageOfIcon_0x236_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x236_32ptWithColor: color];

    UIImage* imageOfIcon_0x236_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x236_32pt;
}

+ (UIImage*)imageOfIcon_0x238_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x238_32ptWithColor: color];

    UIImage* imageOfIcon_0x238_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x238_32pt;
}

+ (UIImage*)imageOfIcon_0x250_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x250_32ptWithColor: color];

    UIImage* imageOfIcon_0x250_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x250_32pt;
}

+ (UIImage*)imageOfIcon_0x251_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x251_32ptWithColor: color];

    UIImage* imageOfIcon_0x251_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x251_32pt;
}

+ (UIImage*)imageOfIcon_0x252_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x252_32ptWithColor: color];

    UIImage* imageOfIcon_0x252_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x252_32pt;
}

+ (UIImage*)imageOfIcon_0x253_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x253_32ptWithColor: color];

    UIImage* imageOfIcon_0x253_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x253_32pt;
}

+ (UIImage*)imageOfIcon_0x254_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x254_32ptWithColor: color];

    UIImage* imageOfIcon_0x254_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x254_32pt;
}

+ (UIImage*)imageOfIcon_0x255_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x255_32ptWithColor: color];

    UIImage* imageOfIcon_0x255_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x255_32pt;
}

+ (UIImage*)imageOfIcon_0x256_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x256_32ptWithColor: color];

    UIImage* imageOfIcon_0x256_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x256_32pt;
}

+ (UIImage*)imageOfIcon_0x124_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x124_32ptWithColor: color];

    UIImage* imageOfIcon_0x124_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x124_32pt;
}

+ (UIImage*)imageOfIcon_0x239_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x239_32ptWithColor: color];

    UIImage* imageOfIcon_0x239_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x239_32pt;
}

+ (UIImage*)imageOfSecondWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawSecondWithColor: color];

    UIImage* imageOfSecond = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfSecond;
}

+ (UIImage*)imageOfMinuteWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawMinuteWithColor: color];

    UIImage* imageOfMinute = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfMinute;
}

+ (UIImage*)imageOfHourWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawHourWithColor: color];

    UIImage* imageOfHour = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfHour;
}

+ (UIImage*)imageOfDayWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawDayWithColor: color];

    UIImage* imageOfDay = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfDay;
}

+ (UIImage*)imageOfIcon_0x737_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x737_32ptWithColor: color];

    UIImage* imageOfIcon_0x737_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x737_32pt;
}

+ (UIImage*)imageOfIcon_0x654_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x654_32ptWithColor: color];

    UIImage* imageOfIcon_0x654_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x654_32pt;
}

+ (UIImage*)imageOfIcon_0x643_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x643_32ptWithColor: color];

    UIImage* imageOfIcon_0x643_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x643_32pt;
}

+ (UIImage*)imageOfIcon_0x645_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x645_32ptWithColor: color];

    UIImage* imageOfIcon_0x645_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x645_32pt;
}

+ (UIImage*)imageOfIcon_0x644_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x644_32ptWithColor: color];

    UIImage* imageOfIcon_0x644_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x644_32pt;
}

+ (UIImage*)imageOfIcon_0x648_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x648_32ptWithColor: color];

    UIImage* imageOfIcon_0x648_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x648_32pt;
}

+ (UIImage*)imageOfIcon_0x637_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x637_32ptWithColor: color];

    UIImage* imageOfIcon_0x637_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x637_32pt;
}

+ (UIImage*)imageOfIcon_0x735_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x735_32ptWithColor: color];

    UIImage* imageOfIcon_0x735_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x735_32pt;
}

+ (UIImage*)imageOfIcon_0x659_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x659_32ptWithColor: color];

    UIImage* imageOfIcon_0x659_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x659_32pt;
}

+ (UIImage*)imageOfIcon_0x736_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x736_32ptWithColor: color];

    UIImage* imageOfIcon_0x736_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x736_32pt;
}

+ (UIImage*)imageOfIcon_0x260_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x260_32ptWithColor: color];

    UIImage* imageOfIcon_0x260_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x260_32pt;
}

+ (UIImage*)imageOfIcon_0x234_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x234_32ptWithColor: color];

    UIImage* imageOfIcon_0x234_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x234_32pt;
}

+ (UIImage*)imageOfIcon_0x261_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x261_32ptWithColor: color];

    UIImage* imageOfIcon_0x261_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x261_32pt;
}

+ (UIImage*)imageOfMissedcallWithAccent: (UIColor*)accent
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    [WireStyleKit drawMissedcallWithAccent: accent];

    UIImage* imageOfMissedcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfMissedcall;
}

+ (UIImage*)imageOfYoutubeWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 26), NO, 0);
    [WireStyleKit drawYoutubeWithColor: color];

    UIImage* imageOfYoutube = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfYoutube;
}

+ (UIImage*)imageOfMissedcalllastWithAccent: (UIColor*)accent
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 40), NO, 0);
    [WireStyleKit drawMissedcalllastWithAccent: accent];

    UIImage* imageOfMissedcalllast = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfMissedcalllast;
}

+ (UIImage*)imageOfVimeoWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(84, 24), NO, 0);
    [WireStyleKit drawVimeoWithColor: color];

    UIImage* imageOfVimeo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfVimeo;
}

+ (UIImage*)imageOfOngoingcall
{
    if (_imageOfOngoingcall)
        return _imageOfOngoingcall;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    [WireStyleKit drawOngoingcall];

    _imageOfOngoingcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfOngoingcall;
}

+ (UIImage*)imageOfJoinongoingcallWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    [WireStyleKit drawJoinongoingcallWithColor: color];

    UIImage* imageOfJoinongoingcall = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfJoinongoingcall;
}

+ (UIImage*)imageOfLogoWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(272, 224), NO, 0);
    [WireStyleKit drawLogoWithColor: color];

    UIImage* imageOfLogo = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfLogo;
}

+ (UIImage*)imageOfWireWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(174, 50), NO, 0);
    [WireStyleKit drawWireWithColor: color];

    UIImage* imageOfWire = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfWire;
}

+ (UIImage*)imageOfShieldverified
{
    if (_imageOfShieldverified)
        return _imageOfShieldverified;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    [WireStyleKit drawShieldverified];

    _imageOfShieldverified = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfShieldverified;
}

+ (UIImage*)imageOfShieldnotverified
{
    if (_imageOfShieldnotverified)
        return _imageOfShieldnotverified;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), NO, 0);
    [WireStyleKit drawShieldnotverified];

    _imageOfShieldnotverified = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _imageOfShieldnotverified;
}

+ (UIImage*)imageOfTabWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 9), NO, 0);
    [WireStyleKit drawTabWithColor: color];

    UIImage* imageOfTab = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfTab;
}

#pragma mark Customization Infrastructure

- (void)setOngoingcallTargets: (NSArray*)ongoingcallTargets
{
    _ongoingcallTargets = ongoingcallTargets;

    for (id target in ongoingcallTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfOngoingcall];
}

- (void)setShieldverifiedTargets: (NSArray*)shieldverifiedTargets
{
    _shieldverifiedTargets = shieldverifiedTargets;

    for (id target in shieldverifiedTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfShieldverified];
}

- (void)setShieldnotverifiedTargets: (NSArray*)shieldnotverifiedTargets
{
    _shieldnotverifiedTargets = shieldnotverifiedTargets;

    for (id target in shieldnotverifiedTargets)
        [target performSelector: @selector(setImage:) withObject: WireStyleKit.imageOfShieldnotverified];
}


@end
