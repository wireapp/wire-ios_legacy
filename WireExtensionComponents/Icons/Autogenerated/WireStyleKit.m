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
    [chatPath moveToPoint: CGPointMake(12, 0)];
    [chatPath addLineToPoint: CGPointMake(52, 0)];
    [chatPath addCurveToPoint: CGPointMake(64, 11.98) controlPoint1: CGPointMake(58.63, 0) controlPoint2: CGPointMake(64, 5.36)];
    [chatPath addLineToPoint: CGPointMake(64, 39.93)];
    [chatPath addCurveToPoint: CGPointMake(52, 51.91) controlPoint1: CGPointMake(64, 46.55) controlPoint2: CGPointMake(58.63, 51.91)];
    [chatPath addLineToPoint: CGPointMake(32, 51.91)];
    [chatPath addLineToPoint: CGPointMake(24.34, 51.91)];
    [chatPath addCurveToPoint: CGPointMake(16.66, 54.68) controlPoint1: CGPointMake(21.53, 51.91) controlPoint2: CGPointMake(18.82, 52.89)];
    [chatPath addLineToPoint: CGPointMake(6.56, 63.08)];
    [chatPath addCurveToPoint: CGPointMake(0.92, 62.56) controlPoint1: CGPointMake(4.86, 64.49) controlPoint2: CGPointMake(2.34, 64.26)];
    [chatPath addCurveToPoint: CGPointMake(0, 60.01) controlPoint1: CGPointMake(0.33, 61.84) controlPoint2: CGPointMake(0, 60.94)];
    [chatPath addLineToPoint: CGPointMake(0, 11.98)];
    [chatPath addCurveToPoint: CGPointMake(12, 0) controlPoint1: CGPointMake(0, 5.36) controlPoint2: CGPointMake(5.37, 0)];
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
    
    //// Hangup Drawing
    UIBezierPath* hangupPath = [UIBezierPath bezierPath];
    [hangupPath moveToPoint: CGPointMake(61.8, 27.81)];
    [hangupPath addCurveToPoint: CGPointMake(61.45, 43.25) controlPoint1: CGPointMake(64.9, 30.84) controlPoint2: CGPointMake(64.67, 37.43)];
    [hangupPath addCurveToPoint: CGPointMake(60.8, 44.27) controlPoint1: CGPointMake(61.12, 43.84) controlPoint2: CGPointMake(60.93, 44.14)];
    [hangupPath addCurveToPoint: CGPointMake(59.51, 44.03) controlPoint1: CGPointMake(60.63, 44.43) controlPoint2: CGPointMake(60.49, 44.42)];
    [hangupPath addCurveToPoint: CGPointMake(51.46, 41.03) controlPoint1: CGPointMake(57.54, 43.27) controlPoint2: CGPointMake(55.31, 42.45)];
    [hangupPath addCurveToPoint: CGPointMake(46.62, 39.23) controlPoint1: CGPointMake(49.21, 40.2) controlPoint2: CGPointMake(47.7, 39.65)];
    [hangupPath addCurveToPoint: CGPointMake(45.33, 37.56) controlPoint1: CGPointMake(45.31, 38.73) controlPoint2: CGPointMake(45.33, 38.74)];
    [hangupPath addLineToPoint: CGPointMake(45.31, 33.24)];
    [hangupPath addLineToPoint: CGPointMake(45.29, 30.32)];
    [hangupPath addLineToPoint: CGPointMake(42.44, 29.6)];
    [hangupPath addCurveToPoint: CGPointMake(32.01, 28.31) controlPoint1: CGPointMake(39.36, 28.82) controlPoint2: CGPointMake(35.78, 28.31)];
    [hangupPath addCurveToPoint: CGPointMake(21.54, 29.61) controlPoint1: CGPointMake(28.24, 28.31) controlPoint2: CGPointMake(24.7, 28.82)];
    [hangupPath addLineToPoint: CGPointMake(18.68, 30.33)];
    [hangupPath addLineToPoint: CGPointMake(18.69, 37.52)];
    [hangupPath addCurveToPoint: CGPointMake(18.66, 38.18) controlPoint1: CGPointMake(18.69, 37.85) controlPoint2: CGPointMake(18.68, 38.01)];
    [hangupPath addCurveToPoint: CGPointMake(18.5, 38.66) controlPoint1: CGPointMake(18.63, 38.46) controlPoint2: CGPointMake(18.57, 38.6)];
    [hangupPath addCurveToPoint: CGPointMake(17.34, 39.22) controlPoint1: CGPointMake(18.38, 38.79) controlPoint2: CGPointMake(18.13, 38.92)];
    [hangupPath addCurveToPoint: CGPointMake(12.5, 41.05) controlPoint1: CGPointMake(16.07, 39.69) controlPoint2: CGPointMake(14.27, 40.37)];
    [hangupPath addCurveToPoint: CGPointMake(4.55, 44) controlPoint1: CGPointMake(8.69, 42.45) controlPoint2: CGPointMake(6.46, 43.28)];
    [hangupPath addCurveToPoint: CGPointMake(2.55, 43.25) controlPoint1: CGPointMake(3.16, 44.55) controlPoint2: CGPointMake(3.3, 44.6)];
    [hangupPath addCurveToPoint: CGPointMake(0.93, 39.54) controlPoint1: CGPointMake(1.88, 42.03) controlPoint2: CGPointMake(1.34, 40.78)];
    [hangupPath addCurveToPoint: CGPointMake(2.14, 27.85) controlPoint1: CGPointMake(-0.61, 34.85) controlPoint2: CGPointMake(-0.26, 30.25)];
    [hangupPath addCurveToPoint: CGPointMake(31.98, 19) controlPoint1: CGPointMake(7.04, 23.07) controlPoint2: CGPointMake(19.45, 18.99)];
    [hangupPath addCurveToPoint: CGPointMake(61.8, 27.81) controlPoint1: CGPointMake(44.54, 19.01) controlPoint2: CGPointMake(56.96, 23.08)];
    [hangupPath closePath];
    [color setFill];
    [hangupPath fill];
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
    [videoPath moveToPoint: CGPointMake(10.26, 8)];
    [videoPath addLineToPoint: CGPointMake(29.74, 8)];
    [videoPath addCurveToPoint: CGPointMake(35.91, 9.07) controlPoint1: CGPointMake(33.31, 8) controlPoint2: CGPointMake(34.6, 8.37)];
    [videoPath addCurveToPoint: CGPointMake(38.93, 12.09) controlPoint1: CGPointMake(37.21, 9.77) controlPoint2: CGPointMake(38.23, 10.79)];
    [videoPath addCurveToPoint: CGPointMake(40, 18.26) controlPoint1: CGPointMake(39.63, 13.4) controlPoint2: CGPointMake(40, 14.69)];
    [videoPath addLineToPoint: CGPointMake(40, 45.74)];
    [videoPath addCurveToPoint: CGPointMake(38.93, 51.91) controlPoint1: CGPointMake(40, 49.31) controlPoint2: CGPointMake(39.63, 50.6)];
    [videoPath addCurveToPoint: CGPointMake(35.91, 54.93) controlPoint1: CGPointMake(38.23, 53.21) controlPoint2: CGPointMake(37.21, 54.23)];
    [videoPath addCurveToPoint: CGPointMake(29.74, 56) controlPoint1: CGPointMake(34.6, 55.63) controlPoint2: CGPointMake(33.31, 56)];
    [videoPath addLineToPoint: CGPointMake(10.26, 56)];
    [videoPath addCurveToPoint: CGPointMake(4.09, 54.93) controlPoint1: CGPointMake(6.69, 56) controlPoint2: CGPointMake(5.4, 55.63)];
    [videoPath addCurveToPoint: CGPointMake(1.07, 51.91) controlPoint1: CGPointMake(2.79, 54.23) controlPoint2: CGPointMake(1.77, 53.21)];
    [videoPath addCurveToPoint: CGPointMake(0, 45.74) controlPoint1: CGPointMake(0.37, 50.6) controlPoint2: CGPointMake(0, 49.31)];
    [videoPath addLineToPoint: CGPointMake(0, 18.26)];
    [videoPath addCurveToPoint: CGPointMake(1.07, 12.09) controlPoint1: CGPointMake(0, 14.69) controlPoint2: CGPointMake(0.37, 13.4)];
    [videoPath addCurveToPoint: CGPointMake(4.09, 9.07) controlPoint1: CGPointMake(1.77, 10.79) controlPoint2: CGPointMake(2.79, 9.77)];
    [videoPath addCurveToPoint: CGPointMake(10.26, 8) controlPoint1: CGPointMake(5.4, 8.37) controlPoint2: CGPointMake(6.69, 8)];
    [videoPath closePath];
    [videoPath moveToPoint: CGPointMake(45.17, 29.18)];
    [videoPath addLineToPoint: CGPointMake(57.18, 17.22)];
    [videoPath addCurveToPoint: CGPointMake(62.83, 17.23) controlPoint1: CGPointMake(58.74, 15.66) controlPoint2: CGPointMake(61.27, 15.66)];
    [videoPath addCurveToPoint: CGPointMake(64, 20.05) controlPoint1: CGPointMake(63.58, 17.98) controlPoint2: CGPointMake(64, 18.99)];
    [videoPath addLineToPoint: CGPointMake(64, 43.98)];
    [videoPath addCurveToPoint: CGPointMake(60, 47.98) controlPoint1: CGPointMake(64, 46.19) controlPoint2: CGPointMake(62.21, 47.98)];
    [videoPath addCurveToPoint: CGPointMake(57.18, 46.82) controlPoint1: CGPointMake(58.94, 47.98) controlPoint2: CGPointMake(57.93, 47.57)];
    [videoPath addLineToPoint: CGPointMake(45.17, 34.85)];
    [videoPath addCurveToPoint: CGPointMake(45.16, 29.19) controlPoint1: CGPointMake(43.61, 33.29) controlPoint2: CGPointMake(43.6, 30.76)];
    [videoPath addLineToPoint: CGPointMake(45.17, 29.18)];
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
    [likePath moveToPoint: CGPointMake(32.84, 50.34)];
    [likePath addCurveToPoint: CGPointMake(42.91, 43.23) controlPoint1: CGPointMake(36.29, 48.25) controlPoint2: CGPointMake(39.73, 45.85)];
    [likePath addCurveToPoint: CGPointMake(56, 23.16) controlPoint1: CGPointMake(51.25, 36.35) controlPoint2: CGPointMake(56, 29.34)];
    [likePath addCurveToPoint: CGPointMake(53.3, 14.71) controlPoint1: CGPointMake(56.02, 18.95) controlPoint2: CGPointMake(55.14, 16.54)];
    [likePath addCurveToPoint: CGPointMake(40.09, 14.7) controlPoint1: CGPointMake(49.66, 11.1) controlPoint2: CGPointMake(43.72, 11.1)];
    [likePath addLineToPoint: CGPointMake(32, 22.72)];
    [likePath addLineToPoint: CGPointMake(23.91, 14.7)];
    [likePath addCurveToPoint: CGPointMake(10.7, 14.71) controlPoint1: CGPointMake(20.28, 11.1) controlPoint2: CGPointMake(14.34, 11.1)];
    [likePath addCurveToPoint: CGPointMake(8.01, 23.21) controlPoint1: CGPointMake(8.79, 16.6) controlPoint2: CGPointMake(7.89, 19.13)];
    [likePath addCurveToPoint: CGPointMake(21.1, 43.23) controlPoint1: CGPointMake(8.01, 29.34) controlPoint2: CGPointMake(12.76, 36.36)];
    [likePath addCurveToPoint: CGPointMake(31.16, 50.34) controlPoint1: CGPointMake(24.28, 45.86) controlPoint2: CGPointMake(27.72, 48.25)];
    [likePath addCurveToPoint: CGPointMake(32, 50.85) controlPoint1: CGPointMake(31.44, 50.52) controlPoint2: CGPointMake(31.73, 50.68)];
    [likePath addCurveToPoint: CGPointMake(32.84, 50.34) controlPoint1: CGPointMake(32.27, 50.68) controlPoint2: CGPointMake(32.56, 50.51)];
    [likePath closePath];
    [likePath moveToPoint: CGPointMake(32, 11.45)];
    [likePath addLineToPoint: CGPointMake(34.46, 9.02)];
    [likePath addCurveToPoint: CGPointMake(58.93, 9.03) controlPoint1: CGPointMake(41.21, 2.32) controlPoint2: CGPointMake(52.18, 2.34)];
    [likePath addCurveToPoint: CGPointMake(64, 23.2) controlPoint1: CGPointMake(62.34, 12.41) controlPoint2: CGPointMake(64.03, 16.85)];
    [likePath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(64, 44) controlPoint2: CGPointMake(32, 60)];
    [likePath addCurveToPoint: CGPointMake(0.01, 23.2) controlPoint1: CGPointMake(32, 60) controlPoint2: CGPointMake(0, 44)];
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
    [likedPath moveToPoint: CGPointMake(29.54, 9.02)];
    [likedPath addCurveToPoint: CGPointMake(5.07, 9.03) controlPoint1: CGPointMake(22.8, 2.33) controlPoint2: CGPointMake(11.83, 2.32)];
    [likedPath addCurveToPoint: CGPointMake(0.01, 23.2) controlPoint1: CGPointMake(1.51, 12.55) controlPoint2: CGPointMake(-0.18, 17.24)];
    [likedPath addCurveToPoint: CGPointMake(32, 60) controlPoint1: CGPointMake(-0, 44) controlPoint2: CGPointMake(32, 60)];
    [likedPath addCurveToPoint: CGPointMake(64, 23.2) controlPoint1: CGPointMake(32, 60) controlPoint2: CGPointMake(64, 44)];
    [likedPath addCurveToPoint: CGPointMake(58.93, 9.03) controlPoint1: CGPointMake(64.03, 16.85) controlPoint2: CGPointMake(62.34, 12.41)];
    [likedPath addCurveToPoint: CGPointMake(34.46, 9.02) controlPoint1: CGPointMake(52.18, 2.34) controlPoint2: CGPointMake(41.21, 2.32)];
    [likedPath addLineToPoint: CGPointMake(32, 11.45)];
    [likedPath addLineToPoint: CGPointMake(29.54, 9.02)];
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
    
    //// Timed message Drawing
    UIBezierPath* timedMessagePath = [UIBezierPath bezierPath];
    [timedMessagePath moveToPoint: CGPointMake(35.51, 8)];
    [timedMessagePath addLineToPoint: CGPointMake(35.51, 12.31)];
    [timedMessagePath addCurveToPoint: CGPointMake(57.51, 38) controlPoint1: CGPointMake(47.97, 14.23) controlPoint2: CGPointMake(57.51, 25)];
    [timedMessagePath addCurveToPoint: CGPointMake(31.51, 64) controlPoint1: CGPointMake(57.51, 52.36) controlPoint2: CGPointMake(45.87, 64)];
    [timedMessagePath addCurveToPoint: CGPointMake(5.5, 38) controlPoint1: CGPointMake(17.14, 64) controlPoint2: CGPointMake(5.5, 52.36)];
    [timedMessagePath addCurveToPoint: CGPointMake(27.51, 12.31) controlPoint1: CGPointMake(5.5, 25) controlPoint2: CGPointMake(15.04, 14.23)];
    [timedMessagePath addLineToPoint: CGPointMake(27.51, 8)];
    [timedMessagePath addLineToPoint: CGPointMake(25.51, 8)];
    [timedMessagePath addCurveToPoint: CGPointMake(21.5, 4) controlPoint1: CGPointMake(23.3, 8) controlPoint2: CGPointMake(21.5, 6.21)];
    [timedMessagePath addCurveToPoint: CGPointMake(25.51, 0) controlPoint1: CGPointMake(21.5, 1.79) controlPoint2: CGPointMake(23.3, 0)];
    [timedMessagePath addLineToPoint: CGPointMake(37.51, 0)];
    [timedMessagePath addCurveToPoint: CGPointMake(41.51, 4) controlPoint1: CGPointMake(39.72, 0) controlPoint2: CGPointMake(41.51, 1.79)];
    [timedMessagePath addCurveToPoint: CGPointMake(37.51, 8) controlPoint1: CGPointMake(41.51, 6.21) controlPoint2: CGPointMake(39.72, 8)];
    [timedMessagePath addLineToPoint: CGPointMake(35.51, 8)];
    [timedMessagePath closePath];
    [timedMessagePath moveToPoint: CGPointMake(31.51, 56)];
    [timedMessagePath addCurveToPoint: CGPointMake(49.51, 38) controlPoint1: CGPointMake(41.45, 56) controlPoint2: CGPointMake(49.51, 47.94)];
    [timedMessagePath addCurveToPoint: CGPointMake(31.51, 20) controlPoint1: CGPointMake(49.51, 28.06) controlPoint2: CGPointMake(41.45, 20)];
    [timedMessagePath addCurveToPoint: CGPointMake(13.5, 38) controlPoint1: CGPointMake(21.56, 20) controlPoint2: CGPointMake(13.5, 28.06)];
    [timedMessagePath addCurveToPoint: CGPointMake(31.51, 56) controlPoint1: CGPointMake(13.5, 47.94) controlPoint2: CGPointMake(21.56, 56)];
    [timedMessagePath closePath];
    [timedMessagePath moveToPoint: CGPointMake(31.51, 52)];
    [timedMessagePath addCurveToPoint: CGPointMake(17.5, 38) controlPoint1: CGPointMake(23.77, 52) controlPoint2: CGPointMake(17.5, 45.73)];
    [timedMessagePath addCurveToPoint: CGPointMake(31.51, 24) controlPoint1: CGPointMake(17.5, 30.27) controlPoint2: CGPointMake(23.77, 24)];
    [timedMessagePath addLineToPoint: CGPointMake(31.51, 38)];
    [timedMessagePath addLineToPoint: CGPointMake(41.44, 47.87)];
    [timedMessagePath addCurveToPoint: CGPointMake(31.51, 52) controlPoint1: CGPointMake(38.91, 50.42) controlPoint2: CGPointMake(35.39, 52)];
    [timedMessagePath closePath];
    [timedMessagePath moveToPoint: CGPointMake(58, 10.83)];
    [timedMessagePath addLineToPoint: CGPointMake(60.83, 13.66)];
    [timedMessagePath addCurveToPoint: CGPointMake(60.83, 19.31) controlPoint1: CGPointMake(62.39, 15.22) controlPoint2: CGPointMake(62.39, 17.75)];
    [timedMessagePath addCurveToPoint: CGPointMake(55.17, 19.31) controlPoint1: CGPointMake(59.27, 20.88) controlPoint2: CGPointMake(56.73, 20.88)];
    [timedMessagePath addLineToPoint: CGPointMake(52.34, 16.49)];
    [timedMessagePath addCurveToPoint: CGPointMake(52.34, 10.83) controlPoint1: CGPointMake(50.78, 14.92) controlPoint2: CGPointMake(50.78, 12.39)];
    [timedMessagePath addCurveToPoint: CGPointMake(58, 10.83) controlPoint1: CGPointMake(53.9, 9.27) controlPoint2: CGPointMake(56.44, 9.27)];
    [timedMessagePath closePath];
    [color setFill];
    [timedMessagePath fill];
}

+ (void)drawSecondWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(40.3, 16.02)];
    [bezierPath addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(37.82, 14.73) controlPoint2: CGPointMake(34.99, 14)];
    [bezierPath addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezierPath addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezierPath addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezierPath addLineToPoint: CGPointMake(54, 32)];
    [bezierPath addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezierPath addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezierPath addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezierPath addCurveToPoint: CGPointMake(42.04, 12.42) controlPoint1: CGPointMake(35.62, 10) controlPoint2: CGPointMake(39.03, 10.87)];
    [bezierPath addCurveToPoint: CGPointMake(40.3, 16.01) controlPoint1: CGPointMake(41.46, 13.63) controlPoint2: CGPointMake(40.88, 14.83)];
    [bezierPath addLineToPoint: CGPointMake(40.3, 16.02)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(43.82, 19.27)];
    [bezier2Path addCurveToPoint: CGPointMake(48.28, 16) controlPoint1: CGPointMake(43.82, 17.34) controlPoint2: CGPointMake(45.65, 16)];
    [bezier2Path addCurveToPoint: CGPointMake(52.77, 19.07) controlPoint1: CGPointMake(50.92, 16) controlPoint2: CGPointMake(52.58, 17.12)];
    [bezier2Path addLineToPoint: CGPointMake(50.39, 19.07)];
    [bezier2Path addCurveToPoint: CGPointMake(48.29, 17.84) controlPoint1: CGPointMake(50.21, 18.32) controlPoint2: CGPointMake(49.47, 17.84)];
    [bezier2Path addCurveToPoint: CGPointMake(46.27, 19.14) controlPoint1: CGPointMake(47.14, 17.84) controlPoint2: CGPointMake(46.27, 18.36)];
    [bezier2Path addCurveToPoint: CGPointMake(47.92, 20.36) controlPoint1: CGPointMake(46.27, 19.74) controlPoint2: CGPointMake(46.8, 20.11)];
    [bezier2Path addLineToPoint: CGPointMake(49.88, 20.79)];
    [bezier2Path addCurveToPoint: CGPointMake(53, 23.7) controlPoint1: CGPointMake(52.01, 21.25) controlPoint2: CGPointMake(53, 22.13)];
    [bezier2Path addCurveToPoint: CGPointMake(48.26, 27.12) controlPoint1: CGPointMake(53, 25.75) controlPoint2: CGPointMake(51.04, 27.12)];
    [bezier2Path addCurveToPoint: CGPointMake(43.53, 24.02) controlPoint1: CGPointMake(45.48, 27.12) controlPoint2: CGPointMake(43.73, 25.97)];
    [bezier2Path addLineToPoint: CGPointMake(46.03, 24.02)];
    [bezier2Path addCurveToPoint: CGPointMake(48.32, 25.28) controlPoint1: CGPointMake(46.27, 24.81) controlPoint2: CGPointMake(47.05, 25.28)];
    [bezier2Path addCurveToPoint: CGPointMake(50.48, 23.95) controlPoint1: CGPointMake(49.59, 25.28) controlPoint2: CGPointMake(50.48, 24.74)];
    [bezier2Path addCurveToPoint: CGPointMake(48.94, 22.74) controlPoint1: CGPointMake(50.48, 23.35) controlPoint2: CGPointMake(50, 22.97)];
    [bezier2Path addLineToPoint: CGPointMake(46.96, 22.3)];
    [bezier2Path addCurveToPoint: CGPointMake(43.82, 19.27) controlPoint1: CGPointMake(44.82, 21.83) controlPoint2: CGPointMake(43.82, 20.88)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawMinuteWithColor: (UIColor*)color
{
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(42.89, 27)];
    [bezier2Path addLineToPoint: CGPointMake(42.89, 16.22)];
    [bezier2Path addLineToPoint: CGPointMake(45.36, 16.22)];
    [bezier2Path addLineToPoint: CGPointMake(45.36, 17.96)];
    [bezier2Path addLineToPoint: CGPointMake(45.53, 17.96)];
    [bezier2Path addCurveToPoint: CGPointMake(48.67, 16) controlPoint1: CGPointMake(46.02, 16.73) controlPoint2: CGPointMake(47.17, 16)];
    [bezier2Path addCurveToPoint: CGPointMake(51.78, 17.96) controlPoint1: CGPointMake(50.22, 16) controlPoint2: CGPointMake(51.31, 16.75)];
    [bezier2Path addLineToPoint: CGPointMake(51.96, 17.96)];
    [bezier2Path addCurveToPoint: CGPointMake(55.38, 16) controlPoint1: CGPointMake(52.51, 16.78) controlPoint2: CGPointMake(53.81, 16)];
    [bezier2Path addCurveToPoint: CGPointMake(59, 19.59) controlPoint1: CGPointMake(57.64, 16) controlPoint2: CGPointMake(59, 17.35)];
    [bezier2Path addLineToPoint: CGPointMake(59, 27)];
    [bezier2Path addLineToPoint: CGPointMake(56.45, 27)];
    [bezier2Path addLineToPoint: CGPointMake(56.45, 20.21)];
    [bezier2Path addCurveToPoint: CGPointMake(54.39, 18.13) controlPoint1: CGPointMake(56.45, 18.82) controlPoint2: CGPointMake(55.76, 18.13)];
    [bezier2Path addCurveToPoint: CGPointMake(52.18, 20.29) controlPoint1: CGPointMake(53.06, 18.13) controlPoint2: CGPointMake(52.18, 19.06)];
    [bezier2Path addLineToPoint: CGPointMake(52.18, 27)];
    [bezier2Path addLineToPoint: CGPointMake(49.7, 27)];
    [bezier2Path addLineToPoint: CGPointMake(49.7, 20.03)];
    [bezier2Path addCurveToPoint: CGPointMake(47.66, 18.13) controlPoint1: CGPointMake(49.7, 18.85) controlPoint2: CGPointMake(48.91, 18.13)];
    [bezier2Path addCurveToPoint: CGPointMake(45.45, 20.45) controlPoint1: CGPointMake(46.39, 18.13) controlPoint2: CGPointMake(45.45, 19.12)];
    [bezier2Path addLineToPoint: CGPointMake(45.45, 27)];
    [bezier2Path addLineToPoint: CGPointMake(42.89, 27)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
    
    
    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(40.3, 16.02)];
    [bezier3Path addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(37.82, 14.73) controlPoint2: CGPointMake(34.99, 14)];
    [bezier3Path addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezier3Path addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezier3Path addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezier3Path addLineToPoint: CGPointMake(54, 32)];
    [bezier3Path addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezier3Path addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezier3Path addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezier3Path addCurveToPoint: CGPointMake(42.04, 12.42) controlPoint1: CGPointMake(35.62, 10) controlPoint2: CGPointMake(39.03, 10.87)];
    [bezier3Path addCurveToPoint: CGPointMake(40.3, 16.01) controlPoint1: CGPointMake(41.46, 13.63) controlPoint2: CGPointMake(40.88, 14.83)];
    [bezier3Path addLineToPoint: CGPointMake(40.3, 16.02)];
    [bezier3Path closePath];
    bezier3Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier3Path fill];
}

+ (void)drawHourWithColor: (UIColor*)color
{
    
    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(42, 27)];
    [bezier3Path addLineToPoint: CGPointMake(42, 11)];
    [bezier3Path addLineToPoint: CGPointMake(44.52, 11)];
    [bezier3Path addLineToPoint: CGPointMake(44.52, 17.33)];
    [bezier3Path addLineToPoint: CGPointMake(44.7, 17.33)];
    [bezier3Path addCurveToPoint: CGPointMake(48.12, 15.25) controlPoint1: CGPointMake(45.24, 16.03) controlPoint2: CGPointMake(46.44, 15.25)];
    [bezier3Path addCurveToPoint: CGPointMake(52, 19.55) controlPoint1: CGPointMake(50.54, 15.25) controlPoint2: CGPointMake(52, 16.81)];
    [bezier3Path addLineToPoint: CGPointMake(52, 27)];
    [bezier3Path addLineToPoint: CGPointMake(49.44, 27)];
    [bezier3Path addLineToPoint: CGPointMake(49.44, 20.18)];
    [bezier3Path addCurveToPoint: CGPointMake(47.18, 17.53) controlPoint1: CGPointMake(49.44, 18.43) controlPoint2: CGPointMake(48.66, 17.53)];
    [bezier3Path addCurveToPoint: CGPointMake(44.56, 20.3) controlPoint1: CGPointMake(45.49, 17.53) controlPoint2: CGPointMake(44.56, 18.65)];
    [bezier3Path addLineToPoint: CGPointMake(44.56, 27)];
    [bezier3Path addLineToPoint: CGPointMake(42, 27)];
    [bezier3Path closePath];
    bezier3Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier3Path fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 14)];
    [bezierPath addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezierPath addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezierPath addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezierPath addLineToPoint: CGPointMake(54, 32)];
    [bezierPath addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezierPath addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezierPath addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezierPath addCurveToPoint: CGPointMake(35.89, 10.34) controlPoint1: CGPointMake(33.33, 10) controlPoint2: CGPointMake(34.63, 10.12)];
    [bezierPath addCurveToPoint: CGPointMake(35.19, 14.28) controlPoint1: CGPointMake(35.66, 11.65) controlPoint2: CGPointMake(35.43, 12.97)];
    [bezierPath addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(34.16, 14.1) controlPoint2: CGPointMake(33.09, 14)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawDayWithColor: (UIColor*)color
{
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(49.03, 27.1)];
    [bezier2Path addCurveToPoint: CGPointMake(44.53, 21.16) controlPoint1: CGPointMake(46.26, 27.1) controlPoint2: CGPointMake(44.53, 24.81)];
    [bezier2Path addCurveToPoint: CGPointMake(49.03, 15.25) controlPoint1: CGPointMake(44.53, 17.53) controlPoint2: CGPointMake(46.27, 15.25)];
    [bezier2Path addCurveToPoint: CGPointMake(52.35, 17.26) controlPoint1: CGPointMake(50.53, 15.25) controlPoint2: CGPointMake(51.77, 16)];
    [bezier2Path addLineToPoint: CGPointMake(52.52, 17.26)];
    [bezier2Path addLineToPoint: CGPointMake(52.52, 11)];
    [bezier2Path addLineToPoint: CGPointMake(55, 11)];
    [bezier2Path addLineToPoint: CGPointMake(55, 26.91)];
    [bezier2Path addLineToPoint: CGPointMake(52.6, 26.91)];
    [bezier2Path addLineToPoint: CGPointMake(52.6, 25.09)];
    [bezier2Path addLineToPoint: CGPointMake(52.43, 25.09)];
    [bezier2Path addCurveToPoint: CGPointMake(49.03, 27.1) controlPoint1: CGPointMake(51.81, 26.35) controlPoint2: CGPointMake(50.55, 27.1)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(49.8, 17.46)];
    [bezier2Path addCurveToPoint: CGPointMake(47.07, 21.17) controlPoint1: CGPointMake(48.11, 17.46) controlPoint2: CGPointMake(47.07, 18.86)];
    [bezier2Path addCurveToPoint: CGPointMake(49.8, 24.88) controlPoint1: CGPointMake(47.07, 23.49) controlPoint2: CGPointMake(48.1, 24.88)];
    [bezier2Path addCurveToPoint: CGPointMake(52.55, 21.17) controlPoint1: CGPointMake(51.51, 24.88) controlPoint2: CGPointMake(52.55, 23.48)];
    [bezier2Path addCurveToPoint: CGPointMake(49.8, 17.46) controlPoint1: CGPointMake(52.55, 18.89) controlPoint2: CGPointMake(51.5, 17.46)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(40.3, 16.02)];
    [bezierPath addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(37.82, 14.73) controlPoint2: CGPointMake(34.99, 14)];
    [bezierPath addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezierPath addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezierPath addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezierPath addLineToPoint: CGPointMake(54, 32)];
    [bezierPath addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezierPath addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezierPath addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezierPath addCurveToPoint: CGPointMake(42.04, 12.42) controlPoint1: CGPointMake(35.62, 10) controlPoint2: CGPointMake(39.03, 10.87)];
    [bezierPath addCurveToPoint: CGPointMake(40.3, 16.01) controlPoint1: CGPointMake(41.46, 13.63) controlPoint2: CGPointMake(40.88, 14.83)];
    [bezierPath addLineToPoint: CGPointMake(40.3, 16.02)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
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
    
    //// Return-search Drawing
    UIBezierPath* returnsearchPath = [UIBezierPath bezierPath];
    [returnsearchPath moveToPoint: CGPointMake(55.9, 27.97)];
    [returnsearchPath addCurveToPoint: CGPointMake(50.33, 44.73) controlPoint1: CGPointMake(55.9, 34.26) controlPoint2: CGPointMake(53.83, 40.06)];
    [returnsearchPath addLineToPoint: CGPointMake(64, 58.35)];
    [returnsearchPath addLineToPoint: CGPointMake(58.35, 64)];
    [returnsearchPath addLineToPoint: CGPointMake(44.69, 50.38)];
    [returnsearchPath addCurveToPoint: CGPointMake(27.95, 55.95) controlPoint1: CGPointMake(40.02, 53.87) controlPoint2: CGPointMake(34.23, 55.95)];
    [returnsearchPath addCurveToPoint: CGPointMake(0, 27.97) controlPoint1: CGPointMake(12.51, 55.95) controlPoint2: CGPointMake(0, 43.42)];
    [returnsearchPath addCurveToPoint: CGPointMake(27.95, 0) controlPoint1: CGPointMake(0, 12.52) controlPoint2: CGPointMake(12.51, 0)];
    [returnsearchPath addCurveToPoint: CGPointMake(55.9, 27.97) controlPoint1: CGPointMake(43.38, 0) controlPoint2: CGPointMake(55.9, 12.52)];
    [returnsearchPath closePath];
    [returnsearchPath moveToPoint: CGPointMake(28, 48)];
    [returnsearchPath addCurveToPoint: CGPointMake(48, 28) controlPoint1: CGPointMake(39.05, 48) controlPoint2: CGPointMake(48, 39.05)];
    [returnsearchPath addCurveToPoint: CGPointMake(28, 8) controlPoint1: CGPointMake(48, 16.95) controlPoint2: CGPointMake(39.05, 8)];
    [returnsearchPath addCurveToPoint: CGPointMake(8, 28) controlPoint1: CGPointMake(16.95, 8) controlPoint2: CGPointMake(8, 16.95)];
    [returnsearchPath addCurveToPoint: CGPointMake(28, 48) controlPoint1: CGPointMake(8, 39.05) controlPoint2: CGPointMake(16.95, 48)];
    [returnsearchPath closePath];
    [returnsearchPath moveToPoint: CGPointMake(36, 28)];
    [returnsearchPath addCurveToPoint: CGPointMake(28, 36) controlPoint1: CGPointMake(36, 32.42) controlPoint2: CGPointMake(32.42, 36)];
    [returnsearchPath addCurveToPoint: CGPointMake(20, 28) controlPoint1: CGPointMake(23.58, 36) controlPoint2: CGPointMake(20, 32.42)];
    [returnsearchPath addCurveToPoint: CGPointMake(28, 20) controlPoint1: CGPointMake(20, 23.58) controlPoint2: CGPointMake(23.58, 20)];
    [returnsearchPath addCurveToPoint: CGPointMake(36, 28) controlPoint1: CGPointMake(32.42, 20) controlPoint2: CGPointMake(36, 23.58)];
    [returnsearchPath closePath];
    [color setFill];
    [returnsearchPath fill];
}

+ (void)drawIcon_0x262_32ptWithColor: (UIColor*)color
{
    
    //// Dismiss Drawing
    UIBezierPath* dismissPath = [UIBezierPath bezierPath];
    [dismissPath moveToPoint: CGPointMake(44.97, 13.37)];
    [dismissPath addLineToPoint: CGPointMake(32, 26.34)];
    [dismissPath addLineToPoint: CGPointMake(19.03, 13.37)];
    [dismissPath addCurveToPoint: CGPointMake(15.24, 17.16) controlPoint1: CGPointMake(19.03, 13.37) controlPoint2: CGPointMake(16.89, 15.51)];
    [dismissPath addCurveToPoint: CGPointMake(13.37, 19.03) controlPoint1: CGPointMake(14.21, 18.19) controlPoint2: CGPointMake(13.37, 19.03)];
    [dismissPath addLineToPoint: CGPointMake(26.34, 32)];
    [dismissPath addLineToPoint: CGPointMake(13.37, 44.97)];
    [dismissPath addLineToPoint: CGPointMake(19.03, 50.63)];
    [dismissPath addLineToPoint: CGPointMake(32, 37.66)];
    [dismissPath addLineToPoint: CGPointMake(44.97, 50.63)];
    [dismissPath addLineToPoint: CGPointMake(50.63, 44.97)];
    [dismissPath addLineToPoint: CGPointMake(37.66, 32)];
    [dismissPath addLineToPoint: CGPointMake(50.63, 19.03)];
    [dismissPath addLineToPoint: CGPointMake(44.97, 13.37)];
    [dismissPath closePath];
    [dismissPath moveToPoint: CGPointMake(64, 32)];
    [dismissPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [dismissPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [dismissPath addCurveToPoint: CGPointMake(6.5, 12.67) controlPoint1: CGPointMake(0, 24.74) controlPoint2: CGPointMake(2.42, 18.04)];
    [dismissPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(12.34, 4.97) controlPoint2: CGPointMake(21.59, 0)];
    [dismissPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [dismissPath closePath];
    [color setFill];
    [dismissPath fill];
}

+ (void)drawIcon_0x263_32ptWithColor: (UIColor*)color
{
    
    //// Unread Drawing
    UIBezierPath* unreadPath = [UIBezierPath bezierPath];
    [unreadPath moveToPoint: CGPointMake(16, 8)];
    [unreadPath addCurveToPoint: CGPointMake(8, 16) controlPoint1: CGPointMake(16, 12.42) controlPoint2: CGPointMake(12.42, 16)];
    [unreadPath addCurveToPoint: CGPointMake(0, 8) controlPoint1: CGPointMake(3.58, 16) controlPoint2: CGPointMake(0, 12.42)];
    [unreadPath addCurveToPoint: CGPointMake(8, 0) controlPoint1: CGPointMake(0, 3.58) controlPoint2: CGPointMake(3.58, 0)];
    [unreadPath addCurveToPoint: CGPointMake(16, 8) controlPoint1: CGPointMake(12.42, 0) controlPoint2: CGPointMake(16, 3.58)];
    [unreadPath closePath];
    [unreadPath moveToPoint: CGPointMake(19.78, 36.27)];
    [unreadPath addLineToPoint: CGPointMake(39.99, 56.22)];
    [unreadPath addLineToPoint: CGPointMake(34.53, 61.6)];
    [unreadPath addLineToPoint: CGPointMake(5, 32.45)];
    [unreadPath addLineToPoint: CGPointMake(34.53, 3.29)];
    [unreadPath addLineToPoint: CGPointMake(39.99, 8.68)];
    [unreadPath addLineToPoint: CGPointMake(19.75, 28.65)];
    [unreadPath addLineToPoint: CGPointMake(59, 28.65)];
    [unreadPath addLineToPoint: CGPointMake(59, 36.27)];
    [unreadPath addLineToPoint: CGPointMake(19.78, 36.27)];
    [unreadPath addLineToPoint: CGPointMake(19.78, 36.27)];
    [unreadPath closePath];
    [color setFill];
    [unreadPath fill];
}

+ (void)drawIcon_0x264_32ptWithColor: (UIColor*)color
{
    
    //// Spaces Drawing
    UIBezierPath* spacesPath = [UIBezierPath bezierPath];
    [spacesPath moveToPoint: CGPointMake(11.63, 20.01)];
    [spacesPath addLineToPoint: CGPointMake(11.63, 43.99)];
    [spacesPath addLineToPoint: CGPointMake(32, 56.05)];
    [spacesPath addLineToPoint: CGPointMake(52.37, 43.99)];
    [spacesPath addLineToPoint: CGPointMake(52.37, 20.01)];
    [spacesPath addLineToPoint: CGPointMake(32, 7.95)];
    [spacesPath addLineToPoint: CGPointMake(11.63, 20.01)];
    [spacesPath closePath];
    [spacesPath moveToPoint: CGPointMake(28.68, 0.81)];
    [spacesPath addCurveToPoint: CGPointMake(35.32, 0.81) controlPoint1: CGPointMake(30.51, -0.28) controlPoint2: CGPointMake(33.51, -0.26)];
    [spacesPath addLineToPoint: CGPointMake(56.68, 13.46)];
    [spacesPath addCurveToPoint: CGPointMake(60, 19.36) controlPoint1: CGPointMake(58.51, 14.54) controlPoint2: CGPointMake(60, 17.2)];
    [spacesPath addLineToPoint: CGPointMake(60, 44.64)];
    [spacesPath addCurveToPoint: CGPointMake(56.68, 50.54) controlPoint1: CGPointMake(60, 46.82) controlPoint2: CGPointMake(58.49, 49.47)];
    [spacesPath addLineToPoint: CGPointMake(35.32, 63.19)];
    [spacesPath addCurveToPoint: CGPointMake(28.68, 63.19) controlPoint1: CGPointMake(33.49, 64.28) controlPoint2: CGPointMake(30.49, 64.26)];
    [spacesPath addLineToPoint: CGPointMake(7.32, 50.54)];
    [spacesPath addCurveToPoint: CGPointMake(4, 44.64) controlPoint1: CGPointMake(5.49, 49.46) controlPoint2: CGPointMake(4, 46.8)];
    [spacesPath addLineToPoint: CGPointMake(4, 19.36)];
    [spacesPath addCurveToPoint: CGPointMake(7.32, 13.46) controlPoint1: CGPointMake(4, 17.18) controlPoint2: CGPointMake(5.51, 14.53)];
    [spacesPath addLineToPoint: CGPointMake(28.68, 0.81)];
    [spacesPath closePath];
    [color setFill];
    [spacesPath fill];
}

+ (void)drawIcon_0x265_32ptWithColor: (UIColor*)color
{
    
    //// Profile Drawing
    UIBezierPath* profilePath = [UIBezierPath bezierPath];
    [profilePath moveToPoint: CGPointMake(32, 64)];
    [profilePath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [profilePath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [profilePath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [profilePath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [profilePath closePath];
    [profilePath moveToPoint: CGPointMake(8, 32)];
    [profilePath addCurveToPoint: CGPointMake(13.89, 47.75) controlPoint1: CGPointMake(8, 38.03) controlPoint2: CGPointMake(10.22, 43.54)];
    [profilePath addLineToPoint: CGPointMake(14.21, 45.93)];
    [profilePath addCurveToPoint: CGPointMake(21.24, 40) controlPoint1: CGPointMake(14.78, 42.66) controlPoint2: CGPointMake(17.93, 40)];
    [profilePath addLineToPoint: CGPointMake(42.76, 40)];
    [profilePath addCurveToPoint: CGPointMake(49.79, 45.93) controlPoint1: CGPointMake(46.07, 40) controlPoint2: CGPointMake(49.22, 42.66)];
    [profilePath addLineToPoint: CGPointMake(50.11, 47.75)];
    [profilePath addCurveToPoint: CGPointMake(56, 32) controlPoint1: CGPointMake(53.78, 43.54) controlPoint2: CGPointMake(56, 38.03)];
    [profilePath addCurveToPoint: CGPointMake(32, 8) controlPoint1: CGPointMake(56, 18.75) controlPoint2: CGPointMake(45.25, 8)];
    [profilePath addCurveToPoint: CGPointMake(8, 32) controlPoint1: CGPointMake(18.75, 8) controlPoint2: CGPointMake(8, 18.75)];
    [profilePath closePath];
    [profilePath moveToPoint: CGPointMake(32, 36)];
    [profilePath addCurveToPoint: CGPointMake(22, 26) controlPoint1: CGPointMake(26.48, 36) controlPoint2: CGPointMake(22, 31.52)];
    [profilePath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(22, 20.48) controlPoint2: CGPointMake(26.48, 16)];
    [profilePath addCurveToPoint: CGPointMake(42, 26) controlPoint1: CGPointMake(37.52, 16) controlPoint2: CGPointMake(42, 20.48)];
    [profilePath addCurveToPoint: CGPointMake(32, 36) controlPoint1: CGPointMake(42, 31.52) controlPoint2: CGPointMake(37.52, 36)];
    [profilePath closePath];
    profilePath.usesEvenOddFillRule = YES;
    [color setFill];
    [profilePath fill];
}

+ (void)drawIcon_0x266_32ptWithColor: (UIColor*)color
{
    
    //// Compose Drawing
    UIBezierPath* composePath = [UIBezierPath bezierPath];
    [composePath moveToPoint: CGPointMake(44, 56)];
    [composePath addLineToPoint: CGPointMake(44, 44)];
    [composePath addLineToPoint: CGPointMake(52, 36)];
    [composePath addLineToPoint: CGPointMake(52, 64)];
    [composePath addLineToPoint: CGPointMake(0, 64)];
    [composePath addLineToPoint: CGPointMake(0, 0)];
    [composePath addLineToPoint: CGPointMake(48, 0)];
    [composePath addLineToPoint: CGPointMake(40, 8)];
    [composePath addLineToPoint: CGPointMake(8, 8)];
    [composePath addLineToPoint: CGPointMake(8, 56)];
    [composePath addLineToPoint: CGPointMake(44, 56)];
    [composePath closePath];
    [composePath moveToPoint: CGPointMake(61.11, 13.69)];
    [composePath addLineToPoint: CGPointMake(54.31, 6.89)];
    [composePath addLineToPoint: CGPointMake(55.81, 5.4)];
    [composePath addCurveToPoint: CGPointMake(62.59, 5.42) controlPoint1: CGPointMake(57.68, 3.53) controlPoint2: CGPointMake(60.7, 3.53)];
    [composePath addCurveToPoint: CGPointMake(62.6, 12.2) controlPoint1: CGPointMake(64.47, 7.29) controlPoint2: CGPointMake(64.47, 10.33)];
    [composePath addLineToPoint: CGPointMake(61.11, 13.69)];
    [composePath closePath];
    [composePath moveToPoint: CGPointMake(32.5, 42.3)];
    [composePath addLineToPoint: CGPointMake(24, 44)];
    [composePath addLineToPoint: CGPointMake(25.7, 35.5)];
    [composePath addLineToPoint: CGPointMake(52.9, 8.31)];
    [composePath addLineToPoint: CGPointMake(59.7, 15.11)];
    [composePath addLineToPoint: CGPointMake(32.5, 42.3)];
    [composePath closePath];
    composePath.usesEvenOddFillRule = YES;
    [color setFill];
    [composePath fill];
}

+ (void)drawIcon_0x267_32ptWithColor: (UIColor*)color
{
    
    //// Megaphone Drawing
    UIBezierPath* megaphonePath = [UIBezierPath bezierPath];
    [megaphonePath moveToPoint: CGPointMake(47.81, 53.75)];
    [megaphonePath addCurveToPoint: CGPointMake(39.98, 60) controlPoint1: CGPointMake(47.01, 57.33) controlPoint2: CGPointMake(43.84, 60)];
    [megaphonePath addLineToPoint: CGPointMake(28.02, 60)];
    [megaphonePath addCurveToPoint: CGPointMake(20, 51.98) controlPoint1: CGPointMake(23.59, 60) controlPoint2: CGPointMake(20, 56.44)];
    [megaphonePath addLineToPoint: CGPointMake(20, 43.02)];
    [megaphonePath addLineToPoint: CGPointMake(12, 39.93)];
    [megaphonePath addLineToPoint: CGPointMake(3.8, 42.68)];
    [megaphonePath addCurveToPoint: CGPointMake(0, 39.97) controlPoint1: CGPointMake(1.7, 43.38) controlPoint2: CGPointMake(0, 42.14)];
    [megaphonePath addLineToPoint: CGPointMake(0, 23.84)];
    [megaphonePath addCurveToPoint: CGPointMake(3.8, 21.13) controlPoint1: CGPointMake(0, 21.64) controlPoint2: CGPointMake(1.67, 20.42)];
    [megaphonePath addLineToPoint: CGPointMake(12, 23.88)];
    [megaphonePath addLineToPoint: CGPointMake(60.26, 5.25)];
    [megaphonePath addCurveToPoint: CGPointMake(64, 7.85) controlPoint1: CGPointMake(62.33, 4.45) controlPoint2: CGPointMake(64, 5.61)];
    [megaphonePath addLineToPoint: CGPointMake(64, 55.96)];
    [megaphonePath addCurveToPoint: CGPointMake(60.26, 58.56) controlPoint1: CGPointMake(64, 58.19) controlPoint2: CGPointMake(62.33, 59.36)];
    [megaphonePath addLineToPoint: CGPointMake(47.81, 53.75)];
    [megaphonePath closePath];
    [megaphonePath moveToPoint: CGPointMake(24, 44.56)];
    [megaphonePath addLineToPoint: CGPointMake(24, 51.98)];
    [megaphonePath addCurveToPoint: CGPointMake(28.02, 55.99) controlPoint1: CGPointMake(24, 54.21) controlPoint2: CGPointMake(25.78, 55.99)];
    [megaphonePath addLineToPoint: CGPointMake(39.98, 55.99)];
    [megaphonePath addCurveToPoint: CGPointMake(43.99, 52.28) controlPoint1: CGPointMake(42.13, 55.99) controlPoint2: CGPointMake(43.84, 54.36)];
    [megaphonePath addLineToPoint: CGPointMake(24, 44.56)];
    [megaphonePath closePath];
    megaphonePath.usesEvenOddFillRule = YES;
    [color setFill];
    [megaphonePath fill];
}

+ (void)drawIcon_0x268_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(16, 64)];
    [bezierPath addCurveToPoint: CGPointMake(8, 56) controlPoint1: CGPointMake(11.58, 64) controlPoint2: CGPointMake(8, 60.42)];
    [bezierPath addCurveToPoint: CGPointMake(16, 48) controlPoint1: CGPointMake(8, 51.58) controlPoint2: CGPointMake(11.58, 48)];
    [bezierPath addCurveToPoint: CGPointMake(24, 56) controlPoint1: CGPointMake(20.42, 48) controlPoint2: CGPointMake(24, 51.58)];
    [bezierPath addCurveToPoint: CGPointMake(16, 64) controlPoint1: CGPointMake(24, 60.42) controlPoint2: CGPointMake(20.42, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(0, 22)];
    [bezierPath addCurveToPoint: CGPointMake(22.03, 0) controlPoint1: CGPointMake(0, 9.85) controlPoint2: CGPointMake(9.86, 0)];
    [bezierPath addLineToPoint: CGPointMake(41.97, 0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 22) controlPoint1: CGPointMake(54.14, 0) controlPoint2: CGPointMake(64, 9.87)];
    [bezierPath addCurveToPoint: CGPointMake(41.97, 44) controlPoint1: CGPointMake(64, 34.15) controlPoint2: CGPointMake(54.14, 44)];
    [bezierPath addLineToPoint: CGPointMake(22.03, 44)];
    [bezierPath addCurveToPoint: CGPointMake(0, 22) controlPoint1: CGPointMake(9.86, 44) controlPoint2: CGPointMake(0, 34.13)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x738_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(17.42, 18.27)];
    [bezierPath addLineToPoint: CGPointMake(17.25, 18.27)];
    [bezierPath addLineToPoint: CGPointMake(12.94, 41.27)];
    [bezierPath addLineToPoint: CGPointMake(21.74, 41.27)];
    [bezierPath addLineToPoint: CGPointMake(17.42, 18.27)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(13.71, 0)];
    [bezierPath addLineToPoint: CGPointMake(21.05, 0)];
    [bezierPath addLineToPoint: CGPointMake(34.76, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(25.96, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(23.37, 49.83)];
    [bezierPath addLineToPoint: CGPointMake(11.39, 49.83)];
    [bezierPath addLineToPoint: CGPointMake(8.8, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(0, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(13.71, 0)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(55.2, 58.83)];
    [bezierPath addLineToPoint: CGPointMake(55.03, 58.83)];
    [bezierPath addCurveToPoint: CGPointMake(51.54, 62.66) controlPoint1: CGPointMake(53.88, 60.49) controlPoint2: CGPointMake(52.72, 61.77)];
    [bezierPath addCurveToPoint: CGPointMake(46.58, 64) controlPoint1: CGPointMake(50.36, 63.55) controlPoint2: CGPointMake(48.7, 64)];
    [bezierPath addCurveToPoint: CGPointMake(43.39, 63.51) controlPoint1: CGPointMake(45.54, 64) controlPoint2: CGPointMake(44.48, 63.84)];
    [bezierPath addCurveToPoint: CGPointMake(40.32, 61.73) controlPoint1: CGPointMake(42.29, 63.18) controlPoint2: CGPointMake(41.27, 62.59)];
    [bezierPath addCurveToPoint: CGPointMake(37.99, 58.07) controlPoint1: CGPointMake(39.37, 60.87) controlPoint2: CGPointMake(38.6, 59.65)];
    [bezierPath addCurveToPoint: CGPointMake(37.09, 51.97) controlPoint1: CGPointMake(37.39, 56.5) controlPoint2: CGPointMake(37.09, 54.46)];
    [bezierPath addCurveToPoint: CGPointMake(37.69, 45.24) controlPoint1: CGPointMake(37.09, 49.41) controlPoint2: CGPointMake(37.29, 47.17)];
    [bezierPath addCurveToPoint: CGPointMake(39.89, 40.42) controlPoint1: CGPointMake(38.1, 43.31) controlPoint2: CGPointMake(38.83, 41.7)];
    [bezierPath addCurveToPoint: CGPointMake(44.16, 37.57) controlPoint1: CGPointMake(40.96, 39.15) controlPoint2: CGPointMake(42.38, 38.19)];
    [bezierPath addCurveToPoint: CGPointMake(50.98, 36.64) controlPoint1: CGPointMake(45.94, 36.95) controlPoint2: CGPointMake(48.22, 36.64)];
    [bezierPath addCurveToPoint: CGPointMake(52.87, 36.72) controlPoint1: CGPointMake(51.61, 36.64) controlPoint2: CGPointMake(52.24, 36.66)];
    [bezierPath addCurveToPoint: CGPointMake(55.2, 36.9) controlPoint1: CGPointMake(53.51, 36.78) controlPoint2: CGPointMake(54.28, 36.84)];
    [bezierPath addLineToPoint: CGPointMake(55.2, 32.18)];
    [bezierPath addCurveToPoint: CGPointMake(54.25, 28.35) controlPoint1: CGPointMake(55.2, 30.63) controlPoint2: CGPointMake(54.89, 29.36)];
    [bezierPath addCurveToPoint: CGPointMake(50.8, 26.83) controlPoint1: CGPointMake(53.62, 27.34) controlPoint2: CGPointMake(52.47, 26.83)];
    [bezierPath addCurveToPoint: CGPointMake(47.65, 27.99) controlPoint1: CGPointMake(49.65, 26.83) controlPoint2: CGPointMake(48.6, 27.22)];
    [bezierPath addCurveToPoint: CGPointMake(45.8, 31.38) controlPoint1: CGPointMake(46.71, 28.76) controlPoint2: CGPointMake(46.09, 29.89)];
    [bezierPath addLineToPoint: CGPointMake(37.26, 31.38)];
    [bezierPath addCurveToPoint: CGPointMake(41.23, 21.57) controlPoint1: CGPointMake(37.55, 27.28) controlPoint2: CGPointMake(38.87, 24.01)];
    [bezierPath addCurveToPoint: CGPointMake(45.37, 18.76) controlPoint1: CGPointMake(42.38, 20.38) controlPoint2: CGPointMake(43.76, 19.45)];
    [bezierPath addCurveToPoint: CGPointMake(50.8, 17.74) controlPoint1: CGPointMake(46.98, 18.08) controlPoint2: CGPointMake(48.79, 17.74)];
    [bezierPath addCurveToPoint: CGPointMake(55.98, 18.63) controlPoint1: CGPointMake(52.64, 17.74) controlPoint2: CGPointMake(54.37, 18.04)];
    [bezierPath addCurveToPoint: CGPointMake(60.16, 21.3) controlPoint1: CGPointMake(57.59, 19.22) controlPoint2: CGPointMake(58.98, 20.12)];
    [bezierPath addCurveToPoint: CGPointMake(62.96, 25.76) controlPoint1: CGPointMake(61.34, 22.49) controlPoint2: CGPointMake(62.27, 23.98)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(63.65, 27.54) controlPoint2: CGPointMake(64, 29.62)];
    [bezierPath addLineToPoint: CGPointMake(64, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(55.2, 63.47)];
    [bezierPath addLineToPoint: CGPointMake(55.2, 58.83)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(55.2, 44.03)];
    [bezierPath addCurveToPoint: CGPointMake(52.79, 43.77) controlPoint1: CGPointMake(54.22, 43.86) controlPoint2: CGPointMake(53.42, 43.77)];
    [bezierPath addCurveToPoint: CGPointMake(47.91, 45.15) controlPoint1: CGPointMake(50.89, 43.77) controlPoint2: CGPointMake(49.27, 44.23)];
    [bezierPath addCurveToPoint: CGPointMake(45.89, 50.18) controlPoint1: CGPointMake(46.56, 46.07) controlPoint2: CGPointMake(45.89, 47.75)];
    [bezierPath addCurveToPoint: CGPointMake(47.09, 54.37) controlPoint1: CGPointMake(45.89, 51.91) controlPoint2: CGPointMake(46.29, 53.3)];
    [bezierPath addCurveToPoint: CGPointMake(50.46, 55.98) controlPoint1: CGPointMake(47.9, 55.44) controlPoint2: CGPointMake(49.02, 55.98)];
    [bezierPath addCurveToPoint: CGPointMake(53.95, 54.46) controlPoint1: CGPointMake(51.95, 55.98) controlPoint2: CGPointMake(53.12, 55.47)];
    [bezierPath addCurveToPoint: CGPointMake(55.2, 50.18) controlPoint1: CGPointMake(54.79, 53.45) controlPoint2: CGPointMake(55.2, 52.03)];
    [bezierPath addLineToPoint: CGPointMake(55.2, 44.03)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x739_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(4, 0)];
    [bezierPath addLineToPoint: CGPointMake(12.76, 0)];
    [bezierPath addLineToPoint: CGPointMake(12.76, 27.42)];
    [bezierPath addLineToPoint: CGPointMake(23.58, 27.42)];
    [bezierPath addLineToPoint: CGPointMake(23.58, 0)];
    [bezierPath addLineToPoint: CGPointMake(32.35, 0)];
    [bezierPath addLineToPoint: CGPointMake(32.35, 64)];
    [bezierPath addLineToPoint: CGPointMake(23.58, 64)];
    [bezierPath addLineToPoint: CGPointMake(23.58, 35.51)];
    [bezierPath addLineToPoint: CGPointMake(12.76, 35.51)];
    [bezierPath addLineToPoint: CGPointMake(12.76, 64)];
    [bezierPath addLineToPoint: CGPointMake(4, 64)];
    [bezierPath addLineToPoint: CGPointMake(4, 0)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(45.24, 9.71)];
    [bezierPath addLineToPoint: CGPointMake(36.48, 16.45)];
    [bezierPath addLineToPoint: CGPointMake(36.48, 6.74)];
    [bezierPath addLineToPoint: CGPointMake(45.24, 0)];
    [bezierPath addLineToPoint: CGPointMake(54, 0)];
    [bezierPath addLineToPoint: CGPointMake(54, 64)];
    [bezierPath addLineToPoint: CGPointMake(45.24, 64)];
    [bezierPath addLineToPoint: CGPointMake(45.24, 9.71)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x740_32ptWithColor: (UIColor*)color
{
    
    //// Group 2
    {
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(35.79, 55.44)];
        [bezier2Path addLineToPoint: CGPointMake(52.08, 24.51)];
        [bezier2Path addCurveToPoint: CGPointMake(53.5, 20.46) controlPoint1: CGPointMake(52.91, 22.97) controlPoint2: CGPointMake(53.38, 21.62)];
        [bezier2Path addCurveToPoint: CGPointMake(53.68, 16.13) controlPoint1: CGPointMake(53.62, 19.3) controlPoint2: CGPointMake(53.68, 17.86)];
        [bezier2Path addCurveToPoint: CGPointMake(53.59, 13.68) controlPoint1: CGPointMake(53.68, 15.36) controlPoint2: CGPointMake(53.65, 14.54)];
        [bezier2Path addCurveToPoint: CGPointMake(53.1, 11.41) controlPoint1: CGPointMake(53.53, 12.82) controlPoint2: CGPointMake(53.37, 12.06)];
        [bezier2Path addCurveToPoint: CGPointMake(51.82, 9.76) controlPoint1: CGPointMake(52.84, 10.76) controlPoint2: CGPointMake(52.41, 10.21)];
        [bezier2Path addCurveToPoint: CGPointMake(49.25, 9.09) controlPoint1: CGPointMake(51.23, 9.31) controlPoint2: CGPointMake(50.37, 9.09)];
        [bezier2Path addCurveToPoint: CGPointMake(46.02, 10.25) controlPoint1: CGPointMake(47.89, 9.09) controlPoint2: CGPointMake(46.82, 9.48)];
        [bezier2Path addCurveToPoint: CGPointMake(44.82, 13.64) controlPoint1: CGPointMake(45.22, 11.02) controlPoint2: CGPointMake(44.82, 12.15)];
        [bezier2Path addLineToPoint: CGPointMake(44.82, 18.81)];
        [bezier2Path addLineToPoint: CGPointMake(35.79, 18.81)];
        [bezier2Path addLineToPoint: CGPointMake(35.79, 13.82)];
        [bezier2Path addCurveToPoint: CGPointMake(36.85, 8.47) controlPoint1: CGPointMake(35.79, 11.91) controlPoint2: CGPointMake(36.14, 10.13)];
        [bezier2Path addCurveToPoint: CGPointMake(39.73, 4.1) controlPoint1: CGPointMake(37.56, 6.8) controlPoint2: CGPointMake(38.52, 5.35)];
        [bezier2Path addCurveToPoint: CGPointMake(44.03, 1.11) controlPoint1: CGPointMake(40.94, 2.85) controlPoint2: CGPointMake(42.37, 1.86)];
        [bezier2Path addCurveToPoint: CGPointMake(49.34, 0) controlPoint1: CGPointMake(45.68, 0.37) controlPoint2: CGPointMake(47.45, 0)];
        [bezier2Path addCurveToPoint: CGPointMake(55.4, 1.29) controlPoint1: CGPointMake(51.7, 0) controlPoint2: CGPointMake(53.72, 0.43)];
        [bezier2Path addCurveToPoint: CGPointMake(59.57, 4.81) controlPoint1: CGPointMake(57.09, 2.15) controlPoint2: CGPointMake(58.47, 3.33)];
        [bezier2Path addCurveToPoint: CGPointMake(61.96, 9.89) controlPoint1: CGPointMake(60.66, 6.3) controlPoint2: CGPointMake(61.46, 7.99)];
        [bezier2Path addCurveToPoint: CGPointMake(62.71, 15.96) controlPoint1: CGPointMake(62.46, 11.8) controlPoint2: CGPointMake(62.71, 13.82)];
        [bezier2Path addCurveToPoint: CGPointMake(62.62, 19.83) controlPoint1: CGPointMake(62.71, 17.5) controlPoint2: CGPointMake(62.68, 18.79)];
        [bezier2Path addCurveToPoint: CGPointMake(62.27, 22.82) controlPoint1: CGPointMake(62.56, 20.87) controlPoint2: CGPointMake(62.44, 21.87)];
        [bezier2Path addCurveToPoint: CGPointMake(61.38, 25.67) controlPoint1: CGPointMake(62.09, 23.77) controlPoint2: CGPointMake(61.8, 24.72)];
        [bezier2Path addCurveToPoint: CGPointMake(59.7, 29.15) controlPoint1: CGPointMake(60.97, 26.62) controlPoint2: CGPointMake(60.41, 27.78)];
        [bezier2Path addLineToPoint: CGPointMake(46.42, 54.91)];
        [bezier2Path addLineToPoint: CGPointMake(62.71, 54.91)];
        [bezier2Path addLineToPoint: CGPointMake(62.71, 64)];
        [bezier2Path addLineToPoint: CGPointMake(35.79, 64)];
        [bezier2Path addLineToPoint: CGPointMake(35.79, 55.44)];
        [bezier2Path closePath];
        bezier2Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier2Path fill];
        
        
        //// Bezier 3 Drawing
        UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
        [bezier3Path moveToPoint: CGPointMake(4, 0)];
        [bezier3Path addLineToPoint: CGPointMake(12.75, 0)];
        [bezier3Path addLineToPoint: CGPointMake(12.75, 27.42)];
        [bezier3Path addLineToPoint: CGPointMake(23.57, 27.42)];
        [bezier3Path addLineToPoint: CGPointMake(23.57, 0)];
        [bezier3Path addLineToPoint: CGPointMake(32.32, 0)];
        [bezier3Path addLineToPoint: CGPointMake(32.32, 64)];
        [bezier3Path addLineToPoint: CGPointMake(23.57, 64)];
        [bezier3Path addLineToPoint: CGPointMake(23.57, 35.51)];
        [bezier3Path addLineToPoint: CGPointMake(12.75, 35.51)];
        [bezier3Path addLineToPoint: CGPointMake(12.75, 64)];
        [bezier3Path addLineToPoint: CGPointMake(4, 64)];
        [bezier3Path addLineToPoint: CGPointMake(4, 0)];
        [bezier3Path closePath];
        bezier3Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier3Path fill];
    }
}

+ (void)drawIcon_0x741_32ptWithColor: (UIColor*)color
{
    
    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(4, 0)];
        [bezierPath addLineToPoint: CGPointMake(12.76, 0)];
        [bezierPath addLineToPoint: CGPointMake(12.76, 27.42)];
        [bezierPath addLineToPoint: CGPointMake(23.58, 27.42)];
        [bezierPath addLineToPoint: CGPointMake(23.58, 0)];
        [bezierPath addLineToPoint: CGPointMake(32.33, 0)];
        [bezierPath addLineToPoint: CGPointMake(32.33, 64)];
        [bezierPath addLineToPoint: CGPointMake(23.58, 64)];
        [bezierPath addLineToPoint: CGPointMake(23.58, 35.51)];
        [bezierPath addLineToPoint: CGPointMake(12.76, 35.51)];
        [bezierPath addLineToPoint: CGPointMake(12.76, 64)];
        [bezierPath addLineToPoint: CGPointMake(4, 64)];
        [bezierPath addLineToPoint: CGPointMake(4, 0)];
        [bezierPath closePath];
        bezierPath.usesEvenOddFillRule = YES;
        [color setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(46.44, 27.05)];
        [bezier2Path addCurveToPoint: CGPointMake(52.01, 26.08) controlPoint1: CGPointMake(49.13, 27.05) controlPoint2: CGPointMake(50.99, 26.73)];
        [bezier2Path addCurveToPoint: CGPointMake(53.55, 21.57) controlPoint1: CGPointMake(53.04, 25.43) controlPoint2: CGPointMake(53.55, 23.93)];
        [bezier2Path addLineToPoint: CGPointMake(53.55, 13.44)];
        [bezier2Path addCurveToPoint: CGPointMake(52.37, 10.25) controlPoint1: CGPointMake(53.55, 12.14) controlPoint2: CGPointMake(53.16, 11.08)];
        [bezier2Path addCurveToPoint: CGPointMake(49.16, 9.02) controlPoint1: CGPointMake(51.58, 9.43) controlPoint2: CGPointMake(50.51, 9.02)];
        [bezier2Path addCurveToPoint: CGPointMake(45.78, 10.52) controlPoint1: CGPointMake(47.58, 9.02) controlPoint2: CGPointMake(46.45, 9.52)];
        [bezier2Path addCurveToPoint: CGPointMake(44.77, 13.44) controlPoint1: CGPointMake(45.1, 11.52) controlPoint2: CGPointMake(44.77, 12.49)];
        [bezier2Path addLineToPoint: CGPointMake(44.77, 18.56)];
        [bezier2Path addLineToPoint: CGPointMake(35.8, 18.56)];
        [bezier2Path addLineToPoint: CGPointMake(35.8, 13.35)];
        [bezier2Path addCurveToPoint: CGPointMake(36.86, 8.13) controlPoint1: CGPointMake(35.8, 11.52) controlPoint2: CGPointMake(36.16, 9.78)];
        [bezier2Path addCurveToPoint: CGPointMake(39.76, 3.89) controlPoint1: CGPointMake(37.56, 6.48) controlPoint2: CGPointMake(38.53, 5.07)];
        [bezier2Path addCurveToPoint: CGPointMake(44.06, 1.06) controlPoint1: CGPointMake(40.99, 2.71) controlPoint2: CGPointMake(42.42, 1.77)];
        [bezier2Path addCurveToPoint: CGPointMake(49.34, 0) controlPoint1: CGPointMake(45.7, 0.35) controlPoint2: CGPointMake(47.46, 0)];
        [bezier2Path addCurveToPoint: CGPointMake(55.44, 1.46) controlPoint1: CGPointMake(51.8, 0) controlPoint2: CGPointMake(53.83, 0.49)];
        [bezier2Path addCurveToPoint: CGPointMake(59.09, 4.42) controlPoint1: CGPointMake(57.05, 2.43) controlPoint2: CGPointMake(58.27, 3.42)];
        [bezier2Path addCurveToPoint: CGPointMake(60.62, 6.59) controlPoint1: CGPointMake(59.67, 5.13) controlPoint2: CGPointMake(60.19, 5.85)];
        [bezier2Path addCurveToPoint: CGPointMake(61.68, 9.15) controlPoint1: CGPointMake(61.06, 7.32) controlPoint2: CGPointMake(61.42, 8.18)];
        [bezier2Path addCurveToPoint: CGPointMake(62.29, 12.69) controlPoint1: CGPointMake(61.94, 10.12) controlPoint2: CGPointMake(62.15, 11.3)];
        [bezier2Path addCurveToPoint: CGPointMake(62.51, 17.77) controlPoint1: CGPointMake(62.44, 14.07) controlPoint2: CGPointMake(62.51, 15.76)];
        [bezier2Path addCurveToPoint: CGPointMake(62.38, 23.07) controlPoint1: CGPointMake(62.51, 19.95) controlPoint2: CGPointMake(62.47, 21.72)];
        [bezier2Path addCurveToPoint: CGPointMake(61.68, 26.48) controlPoint1: CGPointMake(62.29, 24.43) controlPoint2: CGPointMake(62.06, 25.56)];
        [bezier2Path addCurveToPoint: CGPointMake(60.01, 28.82) controlPoint1: CGPointMake(61.3, 27.39) controlPoint2: CGPointMake(60.74, 28.17)];
        [bezier2Path addCurveToPoint: CGPointMake(56.98, 30.94) controlPoint1: CGPointMake(59.28, 29.47) controlPoint2: CGPointMake(58.27, 30.17)];
        [bezier2Path addCurveToPoint: CGPointMake(60.19, 33.41) controlPoint1: CGPointMake(58.38, 31.82) controlPoint2: CGPointMake(59.45, 32.65)];
        [bezier2Path addCurveToPoint: CGPointMake(61.81, 36.11) controlPoint1: CGPointMake(60.92, 34.18) controlPoint2: CGPointMake(61.46, 35.08)];
        [bezier2Path addCurveToPoint: CGPointMake(62.43, 39.82) controlPoint1: CGPointMake(62.16, 37.14) controlPoint2: CGPointMake(62.37, 38.38)];
        [bezier2Path addCurveToPoint: CGPointMake(62.51, 45.35) controlPoint1: CGPointMake(62.48, 41.27) controlPoint2: CGPointMake(62.51, 43.11)];
        [bezier2Path addCurveToPoint: CGPointMake(62.38, 50.48) controlPoint1: CGPointMake(62.51, 47.41) controlPoint2: CGPointMake(62.47, 49.12)];
        [bezier2Path addCurveToPoint: CGPointMake(61.99, 53.88) controlPoint1: CGPointMake(62.29, 51.83) controlPoint2: CGPointMake(62.16, 52.97)];
        [bezier2Path addCurveToPoint: CGPointMake(61.28, 56.22) controlPoint1: CGPointMake(61.81, 54.79) controlPoint2: CGPointMake(61.58, 55.57)];
        [bezier2Path addCurveToPoint: CGPointMake(60.14, 58.25) controlPoint1: CGPointMake(60.99, 56.87) controlPoint2: CGPointMake(60.61, 57.55)];
        [bezier2Path addCurveToPoint: CGPointMake(55.84, 62.36) controlPoint1: CGPointMake(59.03, 59.9) controlPoint2: CGPointMake(57.59, 61.27)];
        [bezier2Path addCurveToPoint: CGPointMake(49.07, 64) controlPoint1: CGPointMake(54.08, 63.45) controlPoint2: CGPointMake(51.82, 64)];
        [bezier2Path addCurveToPoint: CGPointMake(44.59, 63.29) controlPoint1: CGPointMake(47.67, 64) controlPoint2: CGPointMake(46.17, 63.76)];
        [bezier2Path addCurveToPoint: CGPointMake(40.29, 60.99) controlPoint1: CGPointMake(43.01, 62.82) controlPoint2: CGPointMake(41.57, 62.06)];
        [bezier2Path addCurveToPoint: CGPointMake(37.08, 56.84) controlPoint1: CGPointMake(39, 59.93) controlPoint2: CGPointMake(37.93, 58.55)];
        [bezier2Path addCurveToPoint: CGPointMake(35.8, 50.56) controlPoint1: CGPointMake(36.23, 55.13) controlPoint2: CGPointMake(35.8, 53.04)];
        [bezier2Path addLineToPoint: CGPointMake(35.8, 45.44)];
        [bezier2Path addLineToPoint: CGPointMake(44.77, 45.44)];
        [bezier2Path addLineToPoint: CGPointMake(44.77, 50.12)];
        [bezier2Path addCurveToPoint: CGPointMake(45.95, 53.61) controlPoint1: CGPointMake(44.77, 51.54) controlPoint2: CGPointMake(45.16, 52.7)];
        [bezier2Path addCurveToPoint: CGPointMake(49.16, 54.98) controlPoint1: CGPointMake(46.74, 54.53) controlPoint2: CGPointMake(47.81, 54.98)];
        [bezier2Path addCurveToPoint: CGPointMake(52.37, 53.61) controlPoint1: CGPointMake(50.51, 54.98) controlPoint2: CGPointMake(51.58, 54.53)];
        [bezier2Path addCurveToPoint: CGPointMake(53.55, 49.94) controlPoint1: CGPointMake(53.16, 52.7) controlPoint2: CGPointMake(53.55, 51.48)];
        [bezier2Path addLineToPoint: CGPointMake(53.55, 40.93)];
        [bezier2Path addCurveToPoint: CGPointMake(53.24, 37.92) controlPoint1: CGPointMake(53.55, 39.69) controlPoint2: CGPointMake(53.45, 38.69)];
        [bezier2Path addCurveToPoint: CGPointMake(52.15, 36.11) controlPoint1: CGPointMake(53.04, 37.16) controlPoint2: CGPointMake(52.67, 36.55)];
        [bezier2Path addCurveToPoint: CGPointMake(49.99, 35.23) controlPoint1: CGPointMake(51.62, 35.67) controlPoint2: CGPointMake(50.9, 35.37)];
        [bezier2Path addCurveToPoint: CGPointMake(46.44, 35.01) controlPoint1: CGPointMake(49.09, 35.08) controlPoint2: CGPointMake(47.9, 35.01)];
        [bezier2Path addLineToPoint: CGPointMake(46.44, 27.05)];
        [bezier2Path closePath];
        bezier2Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier2Path fill];
    }
}

+ (void)drawIcon_0x742_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(11, 64)];
    [bezierPath addLineToPoint: CGPointMake(11, 0)];
    [bezierPath addLineToPoint: CGPointMake(35.4, 0)];
    [bezierPath addCurveToPoint: CGPointMake(49.34, 4.74) controlPoint1: CGPointMake(41.59, 0.06) controlPoint2: CGPointMake(46.23, 1.64)];
    [bezierPath addCurveToPoint: CGPointMake(54.05, 17.16) controlPoint1: CGPointMake(52.48, 7.87) controlPoint2: CGPointMake(54.05, 12.01)];
    [bezierPath addCurveToPoint: CGPointMake(52.19, 24.71) controlPoint1: CGPointMake(54.11, 19.8) controlPoint2: CGPointMake(53.49, 22.31)];
    [bezierPath addCurveToPoint: CGPointMake(49.34, 27.96) controlPoint1: CGPointMake(51.53, 25.85) controlPoint2: CGPointMake(50.58, 26.94)];
    [bezierPath addCurveToPoint: CGPointMake(44.77, 30.9) controlPoint1: CGPointMake(48.11, 29.04) controlPoint2: CGPointMake(46.58, 30.02)];
    [bezierPath addLineToPoint: CGPointMake(44.77, 31.08)];
    [bezierPath addCurveToPoint: CGPointMake(52.54, 36.57) controlPoint1: CGPointMake(48.19, 31.99) controlPoint2: CGPointMake(50.78, 33.81)];
    [bezierPath addCurveToPoint: CGPointMake(55, 45.83) controlPoint1: CGPointMake(54.18, 39.4) controlPoint2: CGPointMake(55, 42.49)];
    [bezierPath addCurveToPoint: CGPointMake(49.9, 58.95) controlPoint1: CGPointMake(54.94, 51.36) controlPoint2: CGPointMake(53.24, 55.73)];
    [bezierPath addCurveToPoint: CGPointMake(37.51, 64) controlPoint1: CGPointMake(46.59, 62.32) controlPoint2: CGPointMake(42.46, 64)];
    [bezierPath addLineToPoint: CGPointMake(11, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(35.22, 35.26)];
    [bezierPath addLineToPoint: CGPointMake(20.54, 35.26)];
    [bezierPath addLineToPoint: CGPointMake(20.54, 54.31)];
    [bezierPath addLineToPoint: CGPointMake(35.22, 54.31)];
    [bezierPath addCurveToPoint: CGPointMake(43, 51.4) controlPoint1: CGPointMake(38.76, 54.25) controlPoint2: CGPointMake(41.36, 53.28)];
    [bezierPath addCurveToPoint: CGPointMake(45.46, 44.79) controlPoint1: CGPointMake(44.64, 49.54) controlPoint2: CGPointMake(45.46, 47.34)];
    [bezierPath addCurveToPoint: CGPointMake(43, 38.09) controlPoint1: CGPointMake(45.46, 42.18) controlPoint2: CGPointMake(44.64, 39.95)];
    [bezierPath addCurveToPoint: CGPointMake(35.22, 35.26) controlPoint1: CGPointMake(41.36, 36.26) controlPoint2: CGPointMake(38.76, 35.32)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(34.32, 8.57)];
    [bezierPath addLineToPoint: CGPointMake(20.54, 8.57)];
    [bezierPath addLineToPoint: CGPointMake(20.54, 26.7)];
    [bezierPath addLineToPoint: CGPointMake(34.32, 26.7)];
    [bezierPath addCurveToPoint: CGPointMake(42, 23.96) controlPoint1: CGPointMake(37.8, 26.7) controlPoint2: CGPointMake(40.36, 25.78)];
    [bezierPath addCurveToPoint: CGPointMake(44.51, 17.61) controlPoint1: CGPointMake(43.67, 22.28) controlPoint2: CGPointMake(44.51, 20.16)];
    [bezierPath addCurveToPoint: CGPointMake(42, 11.13) controlPoint1: CGPointMake(44.51, 15.06) controlPoint2: CGPointMake(43.67, 12.9)];
    [bezierPath addCurveToPoint: CGPointMake(34.32, 8.57) controlPoint1: CGPointMake(40.36, 9.48) controlPoint2: CGPointMake(37.8, 8.62)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x743_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32.98, 54.15)];
    [bezierPath addLineToPoint: CGPointMake(39.68, 9.85)];
    [bezierPath addLineToPoint: CGPointMake(44.51, 9.85)];
    [bezierPath addLineToPoint: CGPointMake(46, -0)];
    [bezierPath addLineToPoint: CGPointMake(26.65, -0)];
    [bezierPath addLineToPoint: CGPointMake(25.17, 9.85)];
    [bezierPath addLineToPoint: CGPointMake(30, 9.85)];
    [bezierPath addLineToPoint: CGPointMake(23.31, 54.15)];
    [bezierPath addLineToPoint: CGPointMake(18.47, 54.15)];
    [bezierPath addLineToPoint: CGPointMake(16.98, 64)];
    [bezierPath addLineToPoint: CGPointMake(36.33, 64)];
    [bezierPath addLineToPoint: CGPointMake(37.81, 54.15)];
    [bezierPath addLineToPoint: CGPointMake(32.98, 54.15)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x744_32ptWithColor: (UIColor*)color
{
    
    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(12, 30.49)];
        [bezierPath addCurveToPoint: CGPointMake(17.13, 42.21) controlPoint1: CGPointMake(12.06, 35.66) controlPoint2: CGPointMake(13.77, 39.57)];
        [bezierPath addCurveToPoint: CGPointMake(27.51, 46.36) controlPoint1: CGPointMake(20.22, 44.92) controlPoint2: CGPointMake(23.68, 46.3)];
        [bezierPath addCurveToPoint: CGPointMake(39.5, 40.94) controlPoint1: CGPointMake(32.45, 46.36) controlPoint2: CGPointMake(36.44, 44.55)];
        [bezierPath addLineToPoint: CGPointMake(39.68, 40.94)];
        [bezierPath addLineToPoint: CGPointMake(39.68, 45.83)];
        [bezierPath addLineToPoint: CGPointMake(49, 45.83)];
        [bezierPath addLineToPoint: CGPointMake(49, 0.08)];
        [bezierPath addLineToPoint: CGPointMake(39.68, 0.08)];
        [bezierPath addLineToPoint: CGPointMake(39.68, 27.32)];
        [bezierPath addCurveToPoint: CGPointMake(37.1, 34.55) controlPoint1: CGPointMake(39.68, 30.4) controlPoint2: CGPointMake(38.82, 32.81)];
        [bezierPath addCurveToPoint: CGPointMake(30.54, 37.15) controlPoint1: CGPointMake(35.4, 36.28) controlPoint2: CGPointMake(33.22, 37.15)];
        [bezierPath addCurveToPoint: CGPointMake(23.95, 34.55) controlPoint1: CGPointMake(27.87, 37.15) controlPoint2: CGPointMake(25.67, 36.28)];
        [bezierPath addCurveToPoint: CGPointMake(21.32, 27.32) controlPoint1: CGPointMake(22.19, 32.81) controlPoint2: CGPointMake(21.32, 30.4)];
        [bezierPath addLineToPoint: CGPointMake(21.32, 0.08)];
        [bezierPath addLineToPoint: CGPointMake(12, 0.08)];
        [bezierPath addLineToPoint: CGPointMake(12, 30.49)];
        [bezierPath closePath];
        bezierPath.usesEvenOddFillRule = YES;
        [color setFill];
        [bezierPath fill];
        
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(12, 55, 37, 9)];
        [color setFill];
        [rectanglePath fill];
    }
}

+ (void)drawIcon_0x745_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(20, 28.18)];
    [bezierPath addLineToPoint: CGPointMake(60, 28.18)];
    [bezierPath addLineToPoint: CGPointMake(60, 36.23)];
    [bezierPath addLineToPoint: CGPointMake(20, 36.23)];
    [bezierPath addLineToPoint: CGPointMake(20, 28.18)];
    [bezierPath addLineToPoint: CGPointMake(20, 28.18)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(20, 4.03)];
    [bezierPath addLineToPoint: CGPointMake(60, 4.03)];
    [bezierPath addLineToPoint: CGPointMake(60, 12.08)];
    [bezierPath addLineToPoint: CGPointMake(20, 12.08)];
    [bezierPath addLineToPoint: CGPointMake(20, 4.03)];
    [bezierPath addLineToPoint: CGPointMake(20, 4.03)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(20, 52.33)];
    [bezierPath addLineToPoint: CGPointMake(60, 52.33)];
    [bezierPath addLineToPoint: CGPointMake(60, 60.38)];
    [bezierPath addLineToPoint: CGPointMake(20, 60.38)];
    [bezierPath addLineToPoint: CGPointMake(20, 52.33)];
    [bezierPath addLineToPoint: CGPointMake(20, 52.33)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(5, 28.18)];
    [bezier2Path addLineToPoint: CGPointMake(13, 28.18)];
    [bezier2Path addLineToPoint: CGPointMake(13, 36.23)];
    [bezier2Path addLineToPoint: CGPointMake(5, 36.23)];
    [bezier2Path addLineToPoint: CGPointMake(5, 28.18)];
    [bezier2Path addLineToPoint: CGPointMake(5, 28.18)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(5, 4.03)];
    [bezier2Path addLineToPoint: CGPointMake(13, 4.03)];
    [bezier2Path addLineToPoint: CGPointMake(13, 12.08)];
    [bezier2Path addLineToPoint: CGPointMake(5, 12.08)];
    [bezier2Path addLineToPoint: CGPointMake(5, 4.03)];
    [bezier2Path addLineToPoint: CGPointMake(5, 4.03)];
    [bezier2Path closePath];
    [bezier2Path moveToPoint: CGPointMake(5, 52.33)];
    [bezier2Path addLineToPoint: CGPointMake(13, 52.33)];
    [bezier2Path addLineToPoint: CGPointMake(13, 60.38)];
    [bezier2Path addLineToPoint: CGPointMake(5, 60.38)];
    [bezier2Path addLineToPoint: CGPointMake(5, 52.33)];
    [bezier2Path addLineToPoint: CGPointMake(5, 52.33)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawIcon_0x746_32ptWithColor: (UIColor*)color
{
    
    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(20, 28.18)];
        [bezierPath addLineToPoint: CGPointMake(60, 28.18)];
        [bezierPath addLineToPoint: CGPointMake(60, 36.23)];
        [bezierPath addLineToPoint: CGPointMake(20, 36.23)];
        [bezierPath addLineToPoint: CGPointMake(20, 28.18)];
        [bezierPath addLineToPoint: CGPointMake(20, 28.18)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(20, 4.03)];
        [bezierPath addLineToPoint: CGPointMake(60, 4.03)];
        [bezierPath addLineToPoint: CGPointMake(60, 12.08)];
        [bezierPath addLineToPoint: CGPointMake(20, 12.08)];
        [bezierPath addLineToPoint: CGPointMake(20, 4.03)];
        [bezierPath addLineToPoint: CGPointMake(20, 4.03)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(20, 52.33)];
        [bezierPath addLineToPoint: CGPointMake(60, 52.33)];
        [bezierPath addLineToPoint: CGPointMake(60, 60.38)];
        [bezierPath addLineToPoint: CGPointMake(20, 60.38)];
        [bezierPath addLineToPoint: CGPointMake(20, 52.33)];
        [bezierPath addLineToPoint: CGPointMake(20, 52.33)];
        [bezierPath closePath];
        bezierPath.usesEvenOddFillRule = YES;
        [color setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(0, 29.42)];
        [bezier2Path addLineToPoint: CGPointMake(0, 29.48)];
        [bezier2Path addLineToPoint: CGPointMake(3.61, 29.48)];
        [bezier2Path addLineToPoint: CGPointMake(3.61, 29.4)];
        [bezier2Path addCurveToPoint: CGPointMake(5.86, 27.18) controlPoint1: CGPointMake(3.61, 28.1) controlPoint2: CGPointMake(4.53, 27.18)];
        [bezier2Path addCurveToPoint: CGPointMake(7.97, 29.12) controlPoint1: CGPointMake(7.13, 27.18) controlPoint2: CGPointMake(7.97, 27.96)];
        [bezier2Path addCurveToPoint: CGPointMake(5.12, 32.99) controlPoint1: CGPointMake(7.97, 30.07) controlPoint2: CGPointMake(7.36, 30.89)];
        [bezier2Path addLineToPoint: CGPointMake(0.23, 37.58)];
        [bezier2Path addLineToPoint: CGPointMake(0.23, 40.26)];
        [bezier2Path addLineToPoint: CGPointMake(12, 40.26)];
        [bezier2Path addLineToPoint: CGPointMake(12, 37.13)];
        [bezier2Path addLineToPoint: CGPointMake(5.47, 37.13)];
        [bezier2Path addLineToPoint: CGPointMake(5.47, 36.92)];
        [bezier2Path addLineToPoint: CGPointMake(8.03, 34.63)];
        [bezier2Path addCurveToPoint: CGPointMake(11.79, 28.84) controlPoint1: CGPointMake(10.75, 32.19) controlPoint2: CGPointMake(11.79, 30.61)];
        [bezier2Path addCurveToPoint: CGPointMake(6, 24.15) controlPoint1: CGPointMake(11.79, 26.03) controlPoint2: CGPointMake(9.46, 24.15)];
        [bezier2Path addCurveToPoint: CGPointMake(0, 29.42) controlPoint1: CGPointMake(2.42, 24.15) controlPoint2: CGPointMake(0, 26.26)];
        [bezier2Path closePath];
        bezier2Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier2Path fill];
        
        
        //// Bezier 3 Drawing
        UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
        [bezier3Path moveToPoint: CGPointMake(4.11, 57.22)];
        [bezier3Path addLineToPoint: CGPointMake(5.91, 57.22)];
        [bezier3Path addCurveToPoint: CGPointMake(8.2, 59.07) controlPoint1: CGPointMake(7.34, 57.22) controlPoint2: CGPointMake(8.2, 57.92)];
        [bezier3Path addCurveToPoint: CGPointMake(5.95, 60.91) controlPoint1: CGPointMake(8.2, 60.16) controlPoint2: CGPointMake(7.29, 60.91)];
        [bezier3Path addCurveToPoint: CGPointMake(3.57, 59.09) controlPoint1: CGPointMake(4.52, 60.91) controlPoint2: CGPointMake(3.63, 60.2)];
        [bezier3Path addLineToPoint: CGPointMake(0, 59.09)];
        [bezier3Path addCurveToPoint: CGPointMake(5.89, 63.86) controlPoint1: CGPointMake(0.14, 61.98) controlPoint2: CGPointMake(2.43, 63.86)];
        [bezier3Path addCurveToPoint: CGPointMake(12, 59.39) controlPoint1: CGPointMake(9.55, 63.86) controlPoint2: CGPointMake(12, 62.11)];
        [bezier3Path addCurveToPoint: CGPointMake(8.4, 55.83) controlPoint1: CGPointMake(12, 57.35) controlPoint2: CGPointMake(10.58, 56.04)];
        [bezier3Path addLineToPoint: CGPointMake(8.4, 55.75)];
        [bezier3Path addCurveToPoint: CGPointMake(11.46, 52.33) controlPoint1: CGPointMake(10.19, 55.43) controlPoint2: CGPointMake(11.46, 54.13)];
        [bezier3Path addCurveToPoint: CGPointMake(6.03, 48.31) controlPoint1: CGPointMake(11.46, 49.89) controlPoint2: CGPointMake(9.31, 48.31)];
        [bezier3Path addCurveToPoint: CGPointMake(0.29, 53.04) controlPoint1: CGPointMake(2.61, 48.31) controlPoint2: CGPointMake(0.34, 50.19)];
        [bezier3Path addLineToPoint: CGPointMake(3.67, 53.04)];
        [bezier3Path addCurveToPoint: CGPointMake(5.87, 51.11) controlPoint1: CGPointMake(3.71, 51.89) controlPoint2: CGPointMake(4.58, 51.11)];
        [bezier3Path addCurveToPoint: CGPointMake(7.99, 52.85) controlPoint1: CGPointMake(7.21, 51.11) controlPoint2: CGPointMake(7.99, 51.78)];
        [bezier3Path addCurveToPoint: CGPointMake(5.9, 54.62) controlPoint1: CGPointMake(7.99, 53.91) controlPoint2: CGPointMake(7.16, 54.62)];
        [bezier3Path addLineToPoint: CGPointMake(4.11, 54.62)];
        [bezier3Path addLineToPoint: CGPointMake(4.11, 57.22)];
        [bezier3Path closePath];
        bezier3Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier3Path fill];
        
        
        //// Bezier 4 Drawing
        UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
        [bezier4Path moveToPoint: CGPointMake(4.08, 16.1)];
        [bezier4Path addLineToPoint: CGPointMake(8, 16.1)];
        [bezier4Path addLineToPoint: CGPointMake(8, 0)];
        [bezier4Path addLineToPoint: CGPointMake(4.07, 0)];
        [bezier4Path addLineToPoint: CGPointMake(0, 2.79)];
        [bezier4Path addLineToPoint: CGPointMake(0, 6.32)];
        [bezier4Path addLineToPoint: CGPointMake(4, 3.59)];
        [bezier4Path addLineToPoint: CGPointMake(4.08, 3.59)];
        [bezier4Path addLineToPoint: CGPointMake(4.08, 16.1)];
        [bezier4Path closePath];
        bezier4Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier4Path fill];
    }
}

+ (void)drawIcon_0x747_32ptWithColor: (UIColor*)color
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(54.33, 32)];
        [bezierPath addLineToPoint: CGPointMake(45.08, 17.16)];
        [bezierPath addLineToPoint: CGPointMake(52.31, 12.62)];
        [bezierPath addLineToPoint: CGPointMake(64.39, 32)];
        [bezierPath addLineToPoint: CGPointMake(52.31, 51.38)];
        [bezierPath addLineToPoint: CGPointMake(45.08, 46.84)];
        [bezierPath addLineToPoint: CGPointMake(54.33, 32)];
        [bezierPath closePath];
        [color setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(19.6, 17.16)];
        [bezier2Path addLineToPoint: CGPointMake(12.36, 12.62)];
        [bezier2Path addLineToPoint: CGPointMake(0.28, 32)];
        [bezier2Path addLineToPoint: CGPointMake(12.36, 51.38)];
        [bezier2Path addLineToPoint: CGPointMake(19.6, 46.84)];
        [bezier2Path addLineToPoint: CGPointMake(10.34, 32)];
        [bezier2Path addLineToPoint: CGPointMake(19.6, 17.16)];
        [bezier2Path closePath];
        [color setFill];
        [bezier2Path fill];
        
        
        //// Rectangle Drawing
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 33.04, 32);
        CGContextRotateCTM(context, 12.1 * M_PI/180);
        
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(-4.25, -30.61, 8.5, 61.21)];
        [color setFill];
        [rectanglePath fill];
        
        CGContextRestoreGState(context);
    }
}

+ (void)drawIcon_0x269_32ptWithColor: (UIColor*)color
{
    
    //// Group 2
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(11.63, 20.01)];
        [bezierPath addLineToPoint: CGPointMake(11.63, 43.99)];
        [bezierPath addLineToPoint: CGPointMake(32, 56.05)];
        [bezierPath addLineToPoint: CGPointMake(52.37, 43.99)];
        [bezierPath addLineToPoint: CGPointMake(52.37, 20.01)];
        [bezierPath addLineToPoint: CGPointMake(32, 7.95)];
        [bezierPath addLineToPoint: CGPointMake(11.63, 20.01)];
        [bezierPath closePath];
        [bezierPath moveToPoint: CGPointMake(28.68, 0.81)];
        [bezierPath addCurveToPoint: CGPointMake(35.32, 0.81) controlPoint1: CGPointMake(30.51, -0.28) controlPoint2: CGPointMake(33.51, -0.26)];
        [bezierPath addLineToPoint: CGPointMake(56.68, 13.46)];
        [bezierPath addCurveToPoint: CGPointMake(60, 19.36) controlPoint1: CGPointMake(58.51, 14.54) controlPoint2: CGPointMake(60, 17.2)];
        [bezierPath addLineToPoint: CGPointMake(60, 44.64)];
        [bezierPath addCurveToPoint: CGPointMake(56.68, 50.54) controlPoint1: CGPointMake(60, 46.82) controlPoint2: CGPointMake(58.49, 49.47)];
        [bezierPath addLineToPoint: CGPointMake(35.32, 63.19)];
        [bezierPath addCurveToPoint: CGPointMake(28.68, 63.19) controlPoint1: CGPointMake(33.49, 64.28) controlPoint2: CGPointMake(30.49, 64.26)];
        [bezierPath addLineToPoint: CGPointMake(7.32, 50.54)];
        [bezierPath addCurveToPoint: CGPointMake(4, 44.64) controlPoint1: CGPointMake(5.49, 49.46) controlPoint2: CGPointMake(4, 46.8)];
        [bezierPath addLineToPoint: CGPointMake(4, 19.36)];
        [bezierPath addCurveToPoint: CGPointMake(7.32, 13.46) controlPoint1: CGPointMake(4, 17.18) controlPoint2: CGPointMake(5.51, 14.53)];
        [bezierPath addLineToPoint: CGPointMake(28.68, 0.81)];
        [bezierPath closePath];
        [color setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(36, 28)];
        [bezier2Path addLineToPoint: CGPointMake(36, 20)];
        [bezier2Path addLineToPoint: CGPointMake(28, 20)];
        [bezier2Path addLineToPoint: CGPointMake(28, 28)];
        [bezier2Path addLineToPoint: CGPointMake(20, 28)];
        [bezier2Path addLineToPoint: CGPointMake(20, 36)];
        [bezier2Path addLineToPoint: CGPointMake(28, 36)];
        [bezier2Path addLineToPoint: CGPointMake(28, 44)];
        [bezier2Path addLineToPoint: CGPointMake(36, 44)];
        [bezier2Path addLineToPoint: CGPointMake(36, 36)];
        [bezier2Path addLineToPoint: CGPointMake(44, 36)];
        [bezier2Path addLineToPoint: CGPointMake(44, 28)];
        [bezier2Path addLineToPoint: CGPointMake(36, 28)];
        [bezier2Path closePath];
        bezier2Path.usesEvenOddFillRule = YES;
        [color setFill];
        [bezier2Path fill];
    }
}

+ (void)drawIcon_0x748_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(19.2, 25.6)];
    [bezierPath addCurveToPoint: CGPointMake(12.8, 32) controlPoint1: CGPointMake(15.67, 25.6) controlPoint2: CGPointMake(12.8, 28.47)];
    [bezierPath addCurveToPoint: CGPointMake(19.2, 38.4) controlPoint1: CGPointMake(12.8, 35.53) controlPoint2: CGPointMake(15.67, 38.4)];
    [bezierPath addLineToPoint: CGPointMake(44.8, 38.4)];
    [bezierPath addCurveToPoint: CGPointMake(51.2, 32) controlPoint1: CGPointMake(48.33, 38.4) controlPoint2: CGPointMake(51.2, 35.53)];
    [bezierPath addCurveToPoint: CGPointMake(44.8, 25.6) controlPoint1: CGPointMake(51.2, 28.47) controlPoint2: CGPointMake(48.33, 25.6)];
    [bezierPath addLineToPoint: CGPointMake(19.2, 25.6)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x749_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(32, 51.2)];
    [bezierPath addCurveToPoint: CGPointMake(51.2, 32) controlPoint1: CGPointMake(42.6, 51.2) controlPoint2: CGPointMake(51.2, 42.6)];
    [bezierPath addCurveToPoint: CGPointMake(32, 12.8) controlPoint1: CGPointMake(51.2, 21.4) controlPoint2: CGPointMake(42.6, 12.8)];
    [bezierPath addCurveToPoint: CGPointMake(12.8, 32) controlPoint1: CGPointMake(21.4, 12.8) controlPoint2: CGPointMake(12.8, 21.4)];
    [bezierPath addCurveToPoint: CGPointMake(32, 51.2) controlPoint1: CGPointMake(12.8, 42.6) controlPoint2: CGPointMake(21.4, 51.2)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x750_32ptWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 64)];
    [bezierPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 64) controlPoint2: CGPointMake(64, 49.67)];
    [bezierPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(64, 14.33) controlPoint2: CGPointMake(49.67, 0)];
    [bezierPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 0) controlPoint2: CGPointMake(0, 14.33)];
    [bezierPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(0, 49.67) controlPoint2: CGPointMake(14.33, 64)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x751_32ptWithColor: (UIColor*)color
{
    
    //// Alert Drawing
    UIBezierPath* alertPath = [UIBezierPath bezierPath];
    [alertPath moveToPoint: CGPointMake(32, 64)];
    [alertPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.33, 64) controlPoint2: CGPointMake(0, 49.67)];
    [alertPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.33) controlPoint2: CGPointMake(14.33, 0)];
    [alertPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.67, 0) controlPoint2: CGPointMake(64, 14.33)];
    [alertPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.67) controlPoint2: CGPointMake(49.67, 64)];
    [alertPath closePath];
    [alertPath moveToPoint: CGPointMake(32, 12)];
    [alertPath addCurveToPoint: CGPointMake(28, 16) controlPoint1: CGPointMake(29.79, 12) controlPoint2: CGPointMake(28, 13.79)];
    [alertPath addLineToPoint: CGPointMake(28, 36)];
    [alertPath addCurveToPoint: CGPointMake(32, 40) controlPoint1: CGPointMake(28, 38.21) controlPoint2: CGPointMake(29.79, 40)];
    [alertPath addCurveToPoint: CGPointMake(36, 36) controlPoint1: CGPointMake(34.21, 40) controlPoint2: CGPointMake(36, 38.21)];
    [alertPath addLineToPoint: CGPointMake(36, 16)];
    [alertPath addCurveToPoint: CGPointMake(32, 12) controlPoint1: CGPointMake(36, 13.79) controlPoint2: CGPointMake(34.21, 12)];
    [alertPath closePath];
    [alertPath moveToPoint: CGPointMake(32, 52)];
    [alertPath addCurveToPoint: CGPointMake(36, 48) controlPoint1: CGPointMake(34.21, 52) controlPoint2: CGPointMake(36, 50.21)];
    [alertPath addCurveToPoint: CGPointMake(32, 44) controlPoint1: CGPointMake(36, 45.79) controlPoint2: CGPointMake(34.21, 44)];
    [alertPath addCurveToPoint: CGPointMake(28, 48) controlPoint1: CGPointMake(29.79, 44) controlPoint2: CGPointMake(28, 45.79)];
    [alertPath addCurveToPoint: CGPointMake(32, 52) controlPoint1: CGPointMake(28, 50.21) controlPoint2: CGPointMake(29.79, 52)];
    [alertPath closePath];
    alertPath.usesEvenOddFillRule = YES;
    [color setFill];
    [alertPath fill];
}

+ (void)drawIcon_0x752_32ptWithColor: (UIColor*)color
{
    
    //// Service Drawing
    UIBezierPath* servicePath = [UIBezierPath bezierPath];
    [servicePath moveToPoint: CGPointMake(20.44, 23.59)];
    [servicePath addCurveToPoint: CGPointMake(7.11, 36.78) controlPoint1: CGPointMake(13.08, 23.59) controlPoint2: CGPointMake(7.11, 29.49)];
    [servicePath addLineToPoint: CGPointMake(7.11, 48.21)];
    [servicePath addCurveToPoint: CGPointMake(8.89, 49.97) controlPoint1: CGPointMake(7.11, 49.18) controlPoint2: CGPointMake(7.91, 49.97)];
    [servicePath addLineToPoint: CGPointMake(55.11, 49.97)];
    [servicePath addCurveToPoint: CGPointMake(56.89, 48.21) controlPoint1: CGPointMake(56.09, 49.97) controlPoint2: CGPointMake(56.89, 49.18)];
    [servicePath addLineToPoint: CGPointMake(56.89, 36.78)];
    [servicePath addCurveToPoint: CGPointMake(43.55, 23.59) controlPoint1: CGPointMake(56.89, 29.49) controlPoint2: CGPointMake(50.92, 23.59)];
    [servicePath addLineToPoint: CGPointMake(20.44, 23.59)];
    [servicePath closePath];
    [servicePath moveToPoint: CGPointMake(57.67, 22.14)];
    [servicePath addCurveToPoint: CGPointMake(64, 36.78) controlPoint1: CGPointMake(61.57, 25.83) controlPoint2: CGPointMake(64, 31.02)];
    [servicePath addLineToPoint: CGPointMake(64, 48.21)];
    [servicePath addCurveToPoint: CGPointMake(55.11, 57) controlPoint1: CGPointMake(64, 53.06) controlPoint2: CGPointMake(60.02, 57)];
    [servicePath addLineToPoint: CGPointMake(8.89, 57)];
    [servicePath addCurveToPoint: CGPointMake(0, 48.21) controlPoint1: CGPointMake(3.98, 57) controlPoint2: CGPointMake(0, 53.06)];
    [servicePath addLineToPoint: CGPointMake(0, 36.78)];
    [servicePath addCurveToPoint: CGPointMake(6.33, 22.14) controlPoint1: CGPointMake(0, 31.02) controlPoint2: CGPointMake(2.43, 25.83)];
    [servicePath addLineToPoint: CGPointMake(0.42, 11.17)];
    [servicePath addCurveToPoint: CGPointMake(1.88, 6.41) controlPoint1: CGPointMake(-0.51, 9.46) controlPoint2: CGPointMake(0.15, 7.33)];
    [servicePath addCurveToPoint: CGPointMake(6.69, 7.86) controlPoint1: CGPointMake(3.62, 5.5) controlPoint2: CGPointMake(5.77, 6.15)];
    [servicePath addLineToPoint: CGPointMake(12.28, 18.23)];
    [servicePath addCurveToPoint: CGPointMake(20.44, 16.55) controlPoint1: CGPointMake(14.78, 17.15) controlPoint2: CGPointMake(17.54, 16.55)];
    [servicePath addLineToPoint: CGPointMake(43.55, 16.55)];
    [servicePath addCurveToPoint: CGPointMake(51.72, 18.23) controlPoint1: CGPointMake(46.46, 16.55) controlPoint2: CGPointMake(49.22, 17.15)];
    [servicePath addLineToPoint: CGPointMake(57.31, 7.86)];
    [servicePath addCurveToPoint: CGPointMake(62.12, 6.41) controlPoint1: CGPointMake(58.23, 6.15) controlPoint2: CGPointMake(60.38, 5.5)];
    [servicePath addCurveToPoint: CGPointMake(63.58, 11.17) controlPoint1: CGPointMake(63.85, 7.33) controlPoint2: CGPointMake(64.51, 9.46)];
    [servicePath addLineToPoint: CGPointMake(57.67, 22.14)];
    [servicePath closePath];
    [servicePath moveToPoint: CGPointMake(21.33, 37.66)];
    [servicePath addCurveToPoint: CGPointMake(17.78, 41.17) controlPoint1: CGPointMake(21.33, 39.6) controlPoint2: CGPointMake(19.74, 41.17)];
    [servicePath addCurveToPoint: CGPointMake(14.22, 37.66) controlPoint1: CGPointMake(15.81, 41.17) controlPoint2: CGPointMake(14.22, 39.6)];
    [servicePath addCurveToPoint: CGPointMake(17.78, 34.14) controlPoint1: CGPointMake(14.22, 35.71) controlPoint2: CGPointMake(15.81, 34.14)];
    [servicePath addCurveToPoint: CGPointMake(21.33, 37.66) controlPoint1: CGPointMake(19.74, 34.14) controlPoint2: CGPointMake(21.33, 35.71)];
    [servicePath closePath];
    [servicePath moveToPoint: CGPointMake(35.55, 37.66)];
    [servicePath addCurveToPoint: CGPointMake(32, 41.17) controlPoint1: CGPointMake(35.55, 39.6) controlPoint2: CGPointMake(33.96, 41.17)];
    [servicePath addCurveToPoint: CGPointMake(28.44, 37.66) controlPoint1: CGPointMake(30.04, 41.17) controlPoint2: CGPointMake(28.44, 39.6)];
    [servicePath addCurveToPoint: CGPointMake(32, 34.14) controlPoint1: CGPointMake(28.44, 35.71) controlPoint2: CGPointMake(30.04, 34.14)];
    [servicePath addCurveToPoint: CGPointMake(35.55, 37.66) controlPoint1: CGPointMake(33.96, 34.14) controlPoint2: CGPointMake(35.55, 35.71)];
    [servicePath closePath];
    [servicePath moveToPoint: CGPointMake(46.22, 41.17)];
    [servicePath addCurveToPoint: CGPointMake(42.67, 37.66) controlPoint1: CGPointMake(44.26, 41.17) controlPoint2: CGPointMake(42.67, 39.6)];
    [servicePath addCurveToPoint: CGPointMake(46.22, 34.14) controlPoint1: CGPointMake(42.67, 35.71) controlPoint2: CGPointMake(44.26, 34.14)];
    [servicePath addCurveToPoint: CGPointMake(49.78, 37.66) controlPoint1: CGPointMake(48.18, 34.14) controlPoint2: CGPointMake(49.78, 35.71)];
    [servicePath addCurveToPoint: CGPointMake(46.22, 41.17) controlPoint1: CGPointMake(49.78, 39.6) controlPoint2: CGPointMake(48.18, 41.17)];
    [servicePath closePath];
    [color setFill];
    [servicePath fill];
}

+ (void)drawIcon_0x753_32ptWithColor: (UIColor*)color
{
    
    //// DownArrow Drawing
    UIBezierPath* downArrowPath = [UIBezierPath bezierPath];
    [downArrowPath moveToPoint: CGPointMake(40.25, 52.03)];
    [downArrowPath addLineToPoint: CGPointMake(42, 53.74)];
    [downArrowPath addLineToPoint: CGPointMake(32.5, 63)];
    [downArrowPath addLineToPoint: CGPointMake(23, 53.74)];
    [downArrowPath addLineToPoint: CGPointMake(24.75, 52.03)];
    [downArrowPath addLineToPoint: CGPointMake(31.26, 58.36)];
    [downArrowPath addLineToPoint: CGPointMake(31.26, 0)];
    [downArrowPath addLineToPoint: CGPointMake(33.74, 0)];
    [downArrowPath addLineToPoint: CGPointMake(33.74, 58.37)];
    [downArrowPath addLineToPoint: CGPointMake(40.25, 52.03)];
    [downArrowPath closePath];
    downArrowPath.usesEvenOddFillRule = YES;
    [color setFill];
    [downArrowPath fill];
}

+ (void)drawIcon_0x754_32ptWithColor: (UIColor*)color
{
    
    //// Group Drawing
    UIBezierPath* groupPath = [UIBezierPath bezierPath];
    [groupPath moveToPoint: CGPointMake(40, 8)];
    [groupPath addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(40, 12.42) controlPoint2: CGPointMake(36.42, 16)];
    [groupPath addCurveToPoint: CGPointMake(24, 8) controlPoint1: CGPointMake(27.58, 16) controlPoint2: CGPointMake(24, 12.42)];
    [groupPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(24, 3.58) controlPoint2: CGPointMake(27.58, 0)];
    [groupPath addCurveToPoint: CGPointMake(40, 8) controlPoint1: CGPointMake(36.42, 0) controlPoint2: CGPointMake(40, 3.58)];
    [groupPath closePath];
    [groupPath moveToPoint: CGPointMake(64, 20)];
    [groupPath addCurveToPoint: CGPointMake(56, 28) controlPoint1: CGPointMake(64, 24.42) controlPoint2: CGPointMake(60.42, 28)];
    [groupPath addCurveToPoint: CGPointMake(48, 20) controlPoint1: CGPointMake(51.58, 28) controlPoint2: CGPointMake(48, 24.42)];
    [groupPath addCurveToPoint: CGPointMake(56, 12) controlPoint1: CGPointMake(48, 15.58) controlPoint2: CGPointMake(51.58, 12)];
    [groupPath addCurveToPoint: CGPointMake(64, 20) controlPoint1: CGPointMake(60.42, 12) controlPoint2: CGPointMake(64, 15.58)];
    [groupPath closePath];
    [groupPath moveToPoint: CGPointMake(64, 44)];
    [groupPath addCurveToPoint: CGPointMake(56, 52) controlPoint1: CGPointMake(64, 48.42) controlPoint2: CGPointMake(60.42, 52)];
    [groupPath addCurveToPoint: CGPointMake(48, 44) controlPoint1: CGPointMake(51.58, 52) controlPoint2: CGPointMake(48, 48.42)];
    [groupPath addCurveToPoint: CGPointMake(56, 36) controlPoint1: CGPointMake(48, 39.58) controlPoint2: CGPointMake(51.58, 36)];
    [groupPath addCurveToPoint: CGPointMake(64, 44) controlPoint1: CGPointMake(60.42, 36) controlPoint2: CGPointMake(64, 39.58)];
    [groupPath closePath];
    [groupPath moveToPoint: CGPointMake(40, 56)];
    [groupPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(40, 60.42) controlPoint2: CGPointMake(36.42, 64)];
    [groupPath addCurveToPoint: CGPointMake(24, 56) controlPoint1: CGPointMake(27.58, 64) controlPoint2: CGPointMake(24, 60.42)];
    [groupPath addCurveToPoint: CGPointMake(32, 48) controlPoint1: CGPointMake(24, 51.58) controlPoint2: CGPointMake(27.58, 48)];
    [groupPath addCurveToPoint: CGPointMake(40, 56) controlPoint1: CGPointMake(36.42, 48) controlPoint2: CGPointMake(40, 51.58)];
    [groupPath closePath];
    [groupPath moveToPoint: CGPointMake(16, 44)];
    [groupPath addCurveToPoint: CGPointMake(8, 52) controlPoint1: CGPointMake(16, 48.42) controlPoint2: CGPointMake(12.42, 52)];
    [groupPath addCurveToPoint: CGPointMake(0, 44) controlPoint1: CGPointMake(3.58, 52) controlPoint2: CGPointMake(0, 48.42)];
    [groupPath addCurveToPoint: CGPointMake(8, 36) controlPoint1: CGPointMake(0, 39.58) controlPoint2: CGPointMake(3.58, 36)];
    [groupPath addCurveToPoint: CGPointMake(16, 44) controlPoint1: CGPointMake(12.42, 36) controlPoint2: CGPointMake(16, 39.58)];
    [groupPath closePath];
    [groupPath moveToPoint: CGPointMake(16, 20)];
    [groupPath addCurveToPoint: CGPointMake(8, 28) controlPoint1: CGPointMake(16, 24.42) controlPoint2: CGPointMake(12.42, 28)];
    [groupPath addCurveToPoint: CGPointMake(0, 20) controlPoint1: CGPointMake(3.58, 28) controlPoint2: CGPointMake(0, 24.42)];
    [groupPath addCurveToPoint: CGPointMake(8, 12) controlPoint1: CGPointMake(0, 15.58) controlPoint2: CGPointMake(3.58, 12)];
    [groupPath addCurveToPoint: CGPointMake(16, 20) controlPoint1: CGPointMake(12.42, 12) controlPoint2: CGPointMake(16, 15.58)];
    [groupPath closePath];
    [color setFill];
    [groupPath fill];
}

+ (void)drawIcon_0x755_32ptWithColor: (UIColor*)color
{
    
    //// Arrow Drawing
    UIBezierPath* arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint: CGPointMake(13, 8.15)];
    [arrowPath addLineToPoint: CGPointMake(20.12, 1)];
    [arrowPath addLineToPoint: CGPointMake(51, 32)];
    [arrowPath addLineToPoint: CGPointMake(20.12, 63)];
    [arrowPath addLineToPoint: CGPointMake(13, 55.85)];
    [arrowPath addLineToPoint: CGPointMake(36.75, 32)];
    [arrowPath addLineToPoint: CGPointMake(13, 8.15)];
    [arrowPath closePath];
    arrowPath.usesEvenOddFillRule = YES;
    [color setFill];
    [arrowPath fill];
}

+ (void)drawIcon_0x756_32ptWithColor: (UIColor*)color
{
    
    //// Guest Drawing
    UIBezierPath* guestPath = [UIBezierPath bezierPath];
    [guestPath moveToPoint: CGPointMake(24, 4)];
    [guestPath addCurveToPoint: CGPointMake(28, 0) controlPoint1: CGPointMake(24, 1.79) controlPoint2: CGPointMake(25.79, 0)];
    [guestPath addLineToPoint: CGPointMake(36, 0)];
    [guestPath addCurveToPoint: CGPointMake(40, 4) controlPoint1: CGPointMake(38.21, 0) controlPoint2: CGPointMake(40, 1.79)];
    [guestPath addLineToPoint: CGPointMake(52, 4)];
    [guestPath addCurveToPoint: CGPointMake(60, 12) controlPoint1: CGPointMake(56.42, 4) controlPoint2: CGPointMake(60, 7.58)];
    [guestPath addLineToPoint: CGPointMake(60, 56)];
    [guestPath addCurveToPoint: CGPointMake(52, 64) controlPoint1: CGPointMake(60, 60.42) controlPoint2: CGPointMake(56.42, 64)];
    [guestPath addLineToPoint: CGPointMake(12, 64)];
    [guestPath addCurveToPoint: CGPointMake(4, 56) controlPoint1: CGPointMake(7.58, 64) controlPoint2: CGPointMake(4, 60.42)];
    [guestPath addLineToPoint: CGPointMake(4, 12)];
    [guestPath addCurveToPoint: CGPointMake(12, 4) controlPoint1: CGPointMake(4, 7.58) controlPoint2: CGPointMake(7.58, 4)];
    [guestPath addLineToPoint: CGPointMake(24, 4)];
    [guestPath closePath];
    [guestPath moveToPoint: CGPointMake(26, 8)];
    [guestPath addCurveToPoint: CGPointMake(24, 10) controlPoint1: CGPointMake(24.9, 8) controlPoint2: CGPointMake(24, 8.9)];
    [guestPath addCurveToPoint: CGPointMake(26, 12) controlPoint1: CGPointMake(24, 11.1) controlPoint2: CGPointMake(24.9, 12)];
    [guestPath addLineToPoint: CGPointMake(38, 12)];
    [guestPath addCurveToPoint: CGPointMake(40, 10) controlPoint1: CGPointMake(39.1, 12) controlPoint2: CGPointMake(40, 11.1)];
    [guestPath addCurveToPoint: CGPointMake(38, 8) controlPoint1: CGPointMake(40, 8.9) controlPoint2: CGPointMake(39.1, 8)];
    [guestPath addLineToPoint: CGPointMake(26, 8)];
    [guestPath closePath];
    [guestPath moveToPoint: CGPointMake(32, 36)];
    [guestPath addCurveToPoint: CGPointMake(40, 28) controlPoint1: CGPointMake(36.42, 36) controlPoint2: CGPointMake(40, 32.42)];
    [guestPath addCurveToPoint: CGPointMake(32, 20) controlPoint1: CGPointMake(40, 23.58) controlPoint2: CGPointMake(36.42, 20)];
    [guestPath addCurveToPoint: CGPointMake(24, 28) controlPoint1: CGPointMake(27.58, 20) controlPoint2: CGPointMake(24, 23.58)];
    [guestPath addCurveToPoint: CGPointMake(32, 36) controlPoint1: CGPointMake(24, 32.42) controlPoint2: CGPointMake(27.58, 36)];
    [guestPath closePath];
    [guestPath moveToPoint: CGPointMake(24, 40)];
    [guestPath addCurveToPoint: CGPointMake(16, 48) controlPoint1: CGPointMake(19.58, 40) controlPoint2: CGPointMake(16, 43.58)];
    [guestPath addLineToPoint: CGPointMake(16, 52)];
    [guestPath addLineToPoint: CGPointMake(48, 52)];
    [guestPath addLineToPoint: CGPointMake(48, 48)];
    [guestPath addCurveToPoint: CGPointMake(40, 40) controlPoint1: CGPointMake(48, 43.58) controlPoint2: CGPointMake(44.42, 40)];
    [guestPath addLineToPoint: CGPointMake(24, 40)];
    [guestPath closePath];
    [color setFill];
    [guestPath fill];
}

+ (void)drawIcon_0x757_32ptWithColor: (UIColor*)color
{
    
    //// MissedCall Drawing
    UIBezierPath* missedCallPath = [UIBezierPath bezierPath];
    [missedCallPath moveToPoint: CGPointMake(0, 50.85)];
    [missedCallPath addLineToPoint: CGPointMake(0, 50.73)];
    [missedCallPath addCurveToPoint: CGPointMake(17.84, 17.87) controlPoint1: CGPointMake(0.08, 42.59) controlPoint2: CGPointMake(7.16, 28.54)];
    [missedCallPath addCurveToPoint: CGPointMake(50.78, 0) controlPoint1: CGPointMake(28.55, 7.17) controlPoint2: CGPointMake(42.62, 0.08)];
    [missedCallPath addCurveToPoint: CGPointMake(63.69, 13.51) controlPoint1: CGPointMake(56.01, -0.05) controlPoint2: CGPointMake(61.45, 5.78)];
    [missedCallPath addCurveToPoint: CGPointMake(64, 14.93) controlPoint1: CGPointMake(63.91, 14.29) controlPoint2: CGPointMake(64, 14.71)];
    [missedCallPath addCurveToPoint: CGPointMake(62.7, 15.82) controlPoint1: CGPointMake(64, 15.21) controlPoint2: CGPointMake(63.87, 15.32)];
    [missedCallPath addCurveToPoint: CGPointMake(53.27, 20.12) controlPoint1: CGPointMake(60.38, 16.86) controlPoint2: CGPointMake(57.77, 18.05)];
    [missedCallPath addCurveToPoint: CGPointMake(47.61, 22.7) controlPoint1: CGPointMake(50.66, 21.33) controlPoint2: CGPointMake(48.89, 22.13)];
    [missedCallPath addCurveToPoint: CGPointMake(45.09, 22.36) controlPoint1: CGPointMake(46.07, 23.38) controlPoint2: CGPointMake(46.1, 23.38)];
    [missedCallPath addLineToPoint: CGPointMake(41.38, 18.69)];
    [missedCallPath addLineToPoint: CGPointMake(38.86, 16.21)];
    [missedCallPath addLineToPoint: CGPointMake(35.82, 18.02)];
    [missedCallPath addCurveToPoint: CGPointMake(25.83, 25.81) controlPoint1: CGPointMake(32.53, 19.98) controlPoint2: CGPointMake(29.05, 22.59)];
    [missedCallPath addCurveToPoint: CGPointMake(18.03, 35.83) controlPoint1: CGPointMake(22.62, 29.01) controlPoint2: CGPointMake(20.04, 32.47)];
    [missedCallPath addLineToPoint: CGPointMake(16.21, 38.89)];
    [missedCallPath addLineToPoint: CGPointMake(22.36, 45.03)];
    [missedCallPath addCurveToPoint: CGPointMake(22.9, 45.61) controlPoint1: CGPointMake(22.64, 45.31) controlPoint2: CGPointMake(22.77, 45.45)];
    [missedCallPath addCurveToPoint: CGPointMake(23.18, 46.16) controlPoint1: CGPointMake(23.11, 45.89) controlPoint2: CGPointMake(23.18, 46.05)];
    [missedCallPath addCurveToPoint: CGPointMake(22.67, 47.63) controlPoint1: CGPointMake(23.18, 46.37) controlPoint2: CGPointMake(23.08, 46.7)];
    [missedCallPath addCurveToPoint: CGPointMake(20.11, 53.32) controlPoint1: CGPointMake(21.99, 49.12) controlPoint2: CGPointMake(21.04, 51.23)];
    [missedCallPath addCurveToPoint: CGPointMake(15.87, 62.61) controlPoint1: CGPointMake(18.06, 57.76) controlPoint2: CGPointMake(16.87, 60.36)];
    [missedCallPath addCurveToPoint: CGPointMake(13.51, 63.67) controlPoint1: CGPointMake(15.15, 64.26) controlPoint2: CGPointMake(15.3, 64.19)];
    [missedCallPath addCurveToPoint: CGPointMake(0, 50.85) controlPoint1: CGPointMake(5.84, 61.44) controlPoint2: CGPointMake(0, 56.04)];
    [missedCallPath closePath];
    [color setFill];
    [missedCallPath fill];
}

+ (void)drawWeekWithColor: (UIColor*)color
{
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(56, 16)];
    [bezier2Path addLineToPoint: CGPointMake(53.02, 27)];
    [bezier2Path addLineToPoint: CGPointMake(50.4, 27)];
    [bezier2Path addLineToPoint: CGPointMake(48.25, 19.08)];
    [bezier2Path addLineToPoint: CGPointMake(48.08, 19.08)];
    [bezier2Path addLineToPoint: CGPointMake(45.95, 27)];
    [bezier2Path addLineToPoint: CGPointMake(43.35, 27)];
    [bezier2Path addLineToPoint: CGPointMake(40.38, 16)];
    [bezier2Path addLineToPoint: CGPointMake(42.89, 16)];
    [bezier2Path addLineToPoint: CGPointMake(44.72, 24.21)];
    [bezier2Path addLineToPoint: CGPointMake(44.89, 24.21)];
    [bezier2Path addLineToPoint: CGPointMake(47.01, 16)];
    [bezier2Path addLineToPoint: CGPointMake(49.39, 16)];
    [bezier2Path addLineToPoint: CGPointMake(51.52, 24.21)];
    [bezier2Path addLineToPoint: CGPointMake(51.69, 24.21)];
    [bezier2Path addLineToPoint: CGPointMake(53.51, 16)];
    [bezier2Path addLineToPoint: CGPointMake(56, 16)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(32, 14)];
    [bezierPath addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezierPath addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezierPath addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezierPath addLineToPoint: CGPointMake(54, 32)];
    [bezierPath addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezierPath addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezierPath addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezierPath addCurveToPoint: CGPointMake(35.89, 10.34) controlPoint1: CGPointMake(33.33, 10) controlPoint2: CGPointMake(34.63, 10.12)];
    [bezierPath addCurveToPoint: CGPointMake(35.19, 14.28) controlPoint1: CGPointMake(35.66, 11.65) controlPoint2: CGPointMake(35.43, 12.97)];
    [bezierPath addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(34.16, 14.1) controlPoint2: CGPointMake(33.09, 14)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawMonthWithColor: (UIColor*)color
{
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(55, 27)];
    [bezierPath addLineToPoint: CGPointMake(52.59, 27)];
    [bezierPath addLineToPoint: CGPointMake(52.59, 16.45)];
    [bezierPath addLineToPoint: CGPointMake(52.45, 16.45)];
    [bezierPath addLineToPoint: CGPointMake(48.45, 26.42)];
    [bezierPath addLineToPoint: CGPointMake(46.6, 26.42)];
    [bezierPath addLineToPoint: CGPointMake(42.59, 16.45)];
    [bezierPath addLineToPoint: CGPointMake(42.45, 16.45)];
    [bezierPath addLineToPoint: CGPointMake(42.45, 27)];
    [bezierPath addLineToPoint: CGPointMake(40.04, 27)];
    [bezierPath addLineToPoint: CGPointMake(40.04, 12)];
    [bezierPath addLineToPoint: CGPointMake(43.07, 12)];
    [bezierPath addLineToPoint: CGPointMake(47.43, 22.93)];
    [bezierPath addLineToPoint: CGPointMake(47.61, 22.93)];
    [bezierPath addLineToPoint: CGPointMake(51.97, 12)];
    [bezierPath addLineToPoint: CGPointMake(55, 12)];
    [bezierPath addLineToPoint: CGPointMake(55, 27)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(32, 14)];
    [bezier2Path addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezier2Path addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezier2Path addLineToPoint: CGPointMake(54, 32)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezier2Path addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezier2Path addCurveToPoint: CGPointMake(35.89, 10.34) controlPoint1: CGPointMake(33.33, 10) controlPoint2: CGPointMake(34.63, 10.12)];
    [bezier2Path addCurveToPoint: CGPointMake(35.19, 14.28) controlPoint1: CGPointMake(35.66, 11.65) controlPoint2: CGPointMake(35.43, 12.97)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(34.16, 14.1) controlPoint2: CGPointMake(33.09, 14)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
}

+ (void)drawYearWithColor: (UIColor*)color
{
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(32, 14)];
    [bezier2Path addCurveToPoint: CGPointMake(14, 32) controlPoint1: CGPointMake(22.06, 14) controlPoint2: CGPointMake(14, 22.06)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 50) controlPoint1: CGPointMake(14, 41.94) controlPoint2: CGPointMake(22.06, 50)];
    [bezier2Path addCurveToPoint: CGPointMake(50, 32) controlPoint1: CGPointMake(41.94, 50) controlPoint2: CGPointMake(50, 41.94)];
    [bezier2Path addLineToPoint: CGPointMake(54, 32)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 54) controlPoint1: CGPointMake(54, 44.15) controlPoint2: CGPointMake(44.15, 54)];
    [bezier2Path addCurveToPoint: CGPointMake(10, 32) controlPoint1: CGPointMake(19.85, 54) controlPoint2: CGPointMake(10, 44.15)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 10) controlPoint1: CGPointMake(10, 19.85) controlPoint2: CGPointMake(19.85, 10)];
    [bezier2Path addCurveToPoint: CGPointMake(35.89, 10.34) controlPoint1: CGPointMake(33.33, 10) controlPoint2: CGPointMake(34.63, 10.12)];
    [bezier2Path addCurveToPoint: CGPointMake(35.19, 14.28) controlPoint1: CGPointMake(35.66, 11.65) controlPoint2: CGPointMake(35.43, 12.97)];
    [bezier2Path addCurveToPoint: CGPointMake(32, 14) controlPoint1: CGPointMake(34.16, 14.1) controlPoint2: CGPointMake(33.09, 14)];
    [bezier2Path closePath];
    bezier2Path.usesEvenOddFillRule = YES;
    [color setFill];
    [bezier2Path fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(42.88, 30.33)];
    [bezierPath addCurveToPoint: CGPointMake(41.71, 30.28) controlPoint1: CGPointMake(42.7, 30.33) controlPoint2: CGPointMake(41.9, 30.32)];
    [bezierPath addLineToPoint: CGPointMake(41.71, 28.06)];
    [bezierPath addCurveToPoint: CGPointMake(42.52, 28.1) controlPoint1: CGPointMake(41.88, 28.09) controlPoint2: CGPointMake(42.32, 28.1)];
    [bezierPath addCurveToPoint: CGPointMake(44.85, 26.56) controlPoint1: CGPointMake(43.77, 28.1) controlPoint2: CGPointMake(44.47, 27.67)];
    [bezierPath addLineToPoint: CGPointMake(45.01, 26.03)];
    [bezierPath addLineToPoint: CGPointMake(40.35, 14)];
    [bezierPath addLineToPoint: CGPointMake(43.59, 14)];
    [bezierPath addLineToPoint: CGPointMake(46.64, 23.35)];
    [bezierPath addLineToPoint: CGPointMake(46.84, 23.35)];
    [bezierPath addLineToPoint: CGPointMake(49.88, 14)];
    [bezierPath addLineToPoint: CGPointMake(53, 14)];
    [bezierPath addLineToPoint: CGPointMake(48.3, 26.36)];
    [bezierPath addCurveToPoint: CGPointMake(42.88, 30.33) controlPoint1: CGPointMake(47.19, 29.34) controlPoint2: CGPointMake(45.79, 30.33)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
}

+ (void)drawIcon_0x758_32ptWithColor: (UIColor*)color
{

    //// Browser Drawing
    UIBezierPath* browserPath = [UIBezierPath bezierPath];
    [browserPath moveToPoint: CGPointMake(32, 0)];
    [browserPath addCurveToPoint: CGPointMake(64, 32) controlPoint1: CGPointMake(49.65, 0) controlPoint2: CGPointMake(64, 14.35)];
    [browserPath addCurveToPoint: CGPointMake(32, 64) controlPoint1: CGPointMake(64, 49.64) controlPoint2: CGPointMake(49.65, 64)];
    [browserPath addCurveToPoint: CGPointMake(0, 32) controlPoint1: CGPointMake(14.36, 64) controlPoint2: CGPointMake(0, 49.64)];
    [browserPath addCurveToPoint: CGPointMake(32, 0) controlPoint1: CGPointMake(0, 14.35) controlPoint2: CGPointMake(14.36, 0)];
    [browserPath closePath];
    [browserPath moveToPoint: CGPointMake(46.97, 14.28)];
    [browserPath addLineToPoint: CGPointMake(26.96, 26.27)];
    [browserPath addCurveToPoint: CGPointMake(26.27, 26.96) controlPoint1: CGPointMake(26.67, 26.44) controlPoint2: CGPointMake(26.44, 26.67)];
    [browserPath addLineToPoint: CGPointMake(14.28, 46.97)];
    [browserPath addCurveToPoint: CGPointMake(14.59, 49.41) controlPoint1: CGPointMake(13.81, 47.76) controlPoint2: CGPointMake(13.94, 48.77)];
    [browserPath addCurveToPoint: CGPointMake(16, 50) controlPoint1: CGPointMake(14.97, 49.8) controlPoint2: CGPointMake(15.48, 50)];
    [browserPath addCurveToPoint: CGPointMake(17.03, 49.72) controlPoint1: CGPointMake(16.35, 50) controlPoint2: CGPointMake(16.71, 49.91)];
    [browserPath addLineToPoint: CGPointMake(37.04, 37.73)];
    [browserPath addCurveToPoint: CGPointMake(37.73, 37.04) controlPoint1: CGPointMake(37.33, 37.56) controlPoint2: CGPointMake(37.56, 37.33)];
    [browserPath addLineToPoint: CGPointMake(49.72, 17.03)];
    [browserPath addCurveToPoint: CGPointMake(49.41, 14.59) controlPoint1: CGPointMake(50.19, 16.24) controlPoint2: CGPointMake(50.06, 15.23)];
    [browserPath addCurveToPoint: CGPointMake(46.97, 14.28) controlPoint1: CGPointMake(48.77, 13.94) controlPoint2: CGPointMake(47.76, 13.81)];
    [browserPath closePath];
    browserPath.usesEvenOddFillRule = YES;
    [color setFill];
    [browserPath fill];
}

+ (void)drawIcon_0x759_32ptWithColor: (UIColor*)color
{

    //// Group 2
    {
    }


    //// Network Drawing
    UIBezierPath* networkPath = [UIBezierPath bezierPath];
    [networkPath moveToPoint: CGPointMake(10.24, 8.55)];
    [networkPath addCurveToPoint: CGPointMake(15.9, 8.77) controlPoint1: CGPointMake(11.86, 7.04) controlPoint2: CGPointMake(14.4, 7.14)];
    [networkPath addCurveToPoint: CGPointMake(15.68, 14.47) controlPoint1: CGPointMake(17.4, 10.4) controlPoint2: CGPointMake(17.3, 12.95)];
    [networkPath addCurveToPoint: CGPointMake(8, 32.21) controlPoint1: CGPointMake(10.81, 19.02) controlPoint2: CGPointMake(8, 25.38)];
    [networkPath addCurveToPoint: CGPointMake(16.1, 50.33) controlPoint1: CGPointMake(8, 39.23) controlPoint2: CGPointMake(10.98, 45.77)];
    [networkPath addCurveToPoint: CGPointMake(16.45, 56.02) controlPoint1: CGPointMake(17.76, 51.81) controlPoint2: CGPointMake(17.91, 54.36)];
    [networkPath addCurveToPoint: CGPointMake(10.8, 56.37) controlPoint1: CGPointMake(14.99, 57.69) controlPoint2: CGPointMake(12.46, 57.85)];
    [networkPath addCurveToPoint: CGPointMake(0, 32.21) controlPoint1: CGPointMake(3.98, 50.29) controlPoint2: CGPointMake(0, 41.57)];
    [networkPath addCurveToPoint: CGPointMake(10.24, 8.55) controlPoint1: CGPointMake(0, 23.11) controlPoint2: CGPointMake(3.76, 14.62)];
    [networkPath closePath];
    [networkPath moveToPoint: CGPointMake(53, 56.54)];
    [networkPath addCurveToPoint: CGPointMake(47.36, 56.15) controlPoint1: CGPointMake(51.34, 58) controlPoint2: CGPointMake(48.81, 57.83)];
    [networkPath addCurveToPoint: CGPointMake(47.75, 50.46) controlPoint1: CGPointMake(45.91, 54.47) controlPoint2: CGPointMake(46.08, 51.92)];
    [networkPath addCurveToPoint: CGPointMake(56, 32.21) controlPoint1: CGPointMake(52.96, 45.89) controlPoint2: CGPointMake(56, 39.3)];
    [networkPath addCurveToPoint: CGPointMake(47.87, 14.06) controlPoint1: CGPointMake(56, 25.17) controlPoint2: CGPointMake(53, 18.62)];
    [networkPath addCurveToPoint: CGPointMake(47.51, 8.37) controlPoint1: CGPointMake(46.21, 12.58) controlPoint2: CGPointMake(46.05, 10.04)];
    [networkPath addCurveToPoint: CGPointMake(53.16, 8.01) controlPoint1: CGPointMake(48.97, 6.7) controlPoint2: CGPointMake(51.5, 6.54)];
    [networkPath addCurveToPoint: CGPointMake(64, 32.21) controlPoint1: CGPointMake(60, 14.09) controlPoint2: CGPointMake(64, 22.83)];
    [networkPath addCurveToPoint: CGPointMake(53, 56.54) controlPoint1: CGPointMake(64, 41.66) controlPoint2: CGPointMake(59.94, 50.46)];
    [networkPath closePath];
    [networkPath moveToPoint: CGPointMake(21.36, 20.16)];
    [networkPath addCurveToPoint: CGPointMake(27.01, 20.49) controlPoint1: CGPointMake(23.01, 18.68) controlPoint2: CGPointMake(25.54, 18.83)];
    [networkPath addCurveToPoint: CGPointMake(26.68, 26.18) controlPoint1: CGPointMake(28.48, 22.15) controlPoint2: CGPointMake(28.33, 24.7)];
    [networkPath addCurveToPoint: CGPointMake(24, 32.21) controlPoint1: CGPointMake(24.99, 27.71) controlPoint2: CGPointMake(24, 29.87)];
    [networkPath addCurveToPoint: CGPointMake(26.68, 38.23) controlPoint1: CGPointMake(24, 34.54) controlPoint2: CGPointMake(24.99, 36.71)];
    [networkPath addCurveToPoint: CGPointMake(27.01, 43.93) controlPoint1: CGPointMake(28.33, 39.71) controlPoint2: CGPointMake(28.48, 42.26)];
    [networkPath addCurveToPoint: CGPointMake(21.37, 44.26) controlPoint1: CGPointMake(25.54, 45.59) controlPoint2: CGPointMake(23.02, 45.74)];
    [networkPath addCurveToPoint: CGPointMake(16, 32.21) controlPoint1: CGPointMake(17.98, 41.22) controlPoint2: CGPointMake(16, 36.87)];
    [networkPath addCurveToPoint: CGPointMake(21.36, 20.16) controlPoint1: CGPointMake(16, 27.55) controlPoint2: CGPointMake(17.98, 23.2)];
    [networkPath closePath];
    [networkPath moveToPoint: CGPointMake(42.7, 44.2)];
    [networkPath addCurveToPoint: CGPointMake(37.05, 43.9) controlPoint1: CGPointMake(41.06, 45.69) controlPoint2: CGPointMake(38.53, 45.55)];
    [networkPath addCurveToPoint: CGPointMake(37.35, 38.2) controlPoint1: CGPointMake(35.57, 42.24) controlPoint2: CGPointMake(35.71, 39.69)];
    [networkPath addCurveToPoint: CGPointMake(40, 32.21) controlPoint1: CGPointMake(39.03, 36.68) controlPoint2: CGPointMake(40, 34.53)];
    [networkPath addCurveToPoint: CGPointMake(37.32, 26.19) controlPoint1: CGPointMake(40, 29.87) controlPoint2: CGPointMake(39.02, 27.71)];
    [networkPath addCurveToPoint: CGPointMake(37, 20.49) controlPoint1: CGPointMake(35.67, 24.7) controlPoint2: CGPointMake(35.53, 22.16)];
    [networkPath addCurveToPoint: CGPointMake(42.64, 20.17) controlPoint1: CGPointMake(38.47, 18.83) controlPoint2: CGPointMake(40.99, 18.68)];
    [networkPath addCurveToPoint: CGPointMake(48, 32.21) controlPoint1: CGPointMake(46.03, 23.2) controlPoint2: CGPointMake(48, 27.55)];
    [networkPath addCurveToPoint: CGPointMake(42.7, 44.2) controlPoint1: CGPointMake(48, 36.84) controlPoint2: CGPointMake(46.05, 41.16)];
    [networkPath closePath];
    [color setFill];
    [networkPath fill];
}

+ (void)drawIcon_0x760_32ptWithColor: (UIColor*)color
{

    //// Group 2
    {
    }


    //// Mention Drawing
    UIBezierPath* mentionPath = [UIBezierPath bezierPath];
    [mentionPath moveToPoint: CGPointMake(32.19, 24.81)];
    [mentionPath addCurveToPoint: CGPointMake(26.52, 32.95) controlPoint1: CGPointMake(28.63, 24.81) controlPoint2: CGPointMake(26.52, 27.86)];
    [mentionPath addCurveToPoint: CGPointMake(32.19, 41.09) controlPoint1: CGPointMake(26.52, 38.04) controlPoint2: CGPointMake(28.63, 41.09)];
    [mentionPath addCurveToPoint: CGPointMake(37.97, 32.95) controlPoint1: CGPointMake(35.78, 41.09) controlPoint2: CGPointMake(37.97, 38)];
    [mentionPath addCurveToPoint: CGPointMake(32.19, 24.81) controlPoint1: CGPointMake(37.97, 27.9) controlPoint2: CGPointMake(35.74, 24.81)];
    [mentionPath closePath];
    [mentionPath moveToPoint: CGPointMake(33.44, 0)];
    [mentionPath addCurveToPoint: CGPointMake(64, 29.2) controlPoint1: CGPointMake(52.27, 0) controlPoint2: CGPointMake(64, 11.83)];
    [mentionPath addCurveToPoint: CGPointMake(49.34, 49.15) controlPoint1: CGPointMake(64, 41.53) controlPoint2: CGPointMake(59.06, 49.15)];
    [mentionPath addCurveToPoint: CGPointMake(39.65, 43.24) controlPoint1: CGPointMake(44.3, 49.15) controlPoint2: CGPointMake(40.7, 46.96)];
    [mentionPath addLineToPoint: CGPointMake(38.91, 43.24)];
    [mentionPath addCurveToPoint: CGPointMake(29.77, 49.19) controlPoint1: CGPointMake(37.3, 47.19) controlPoint2: CGPointMake(34.26, 49.19)];
    [mentionPath addCurveToPoint: CGPointMake(16.25, 32.68) controlPoint1: CGPointMake(21.64, 49.19) controlPoint2: CGPointMake(16.25, 42.61)];
    [mentionPath addCurveToPoint: CGPointMake(29.18, 16.75) controlPoint1: CGPointMake(16.25, 23.17) controlPoint2: CGPointMake(21.45, 16.75)];
    [mentionPath addCurveToPoint: CGPointMake(37.35, 20.65) controlPoint1: CGPointMake(32.69, 16.75) controlPoint2: CGPointMake(35.57, 18.16)];
    [mentionPath addCurveToPoint: CGPointMake(38.11, 21.98) controlPoint1: CGPointMake(37.55, 20.94) controlPoint2: CGPointMake(37.81, 21.38)];
    [mentionPath addLineToPoint: CGPointMake(38.11, 21.98)];
    [mentionPath addCurveToPoint: CGPointMake(38.65, 22.31) controlPoint1: CGPointMake(38.22, 22.18) controlPoint2: CGPointMake(38.43, 22.31)];
    [mentionPath addLineToPoint: CGPointMake(38.65, 22.31)];
    [mentionPath addCurveToPoint: CGPointMake(39.02, 21.93) controlPoint1: CGPointMake(38.86, 22.31) controlPoint2: CGPointMake(39.02, 22.14)];
    [mentionPath addLineToPoint: CGPointMake(39.02, 21.85)];
    [mentionPath addLineToPoint: CGPointMake(39.02, 21.69)];
    [mentionPath addCurveToPoint: CGPointMake(43.02, 17.69) controlPoint1: CGPointMake(39.02, 19.48) controlPoint2: CGPointMake(40.81, 17.69)];
    [mentionPath addLineToPoint: CGPointMake(44.01, 17.69)];
    [mentionPath addCurveToPoint: CGPointMake(48.01, 21.69) controlPoint1: CGPointMake(46.22, 17.69) controlPoint2: CGPointMake(48.01, 19.48)];
    [mentionPath addLineToPoint: CGPointMake(48.01, 37.57)];
    [mentionPath addCurveToPoint: CGPointMake(51.37, 41.99) controlPoint1: CGPointMake(48.01, 40.35) controlPoint2: CGPointMake(49.26, 41.99)];
    [mentionPath addCurveToPoint: CGPointMake(56.41, 30.08) controlPoint1: CGPointMake(54.8, 41.99) controlPoint2: CGPointMake(56.41, 37.36)];
    [mentionPath addCurveToPoint: CGPointMake(33.32, 6.89) controlPoint1: CGPointMake(56.41, 15.92) controlPoint2: CGPointMake(47.73, 6.89)];
    [mentionPath addCurveToPoint: CGPointMake(8.05, 32.83) controlPoint1: CGPointMake(18.28, 6.89) controlPoint2: CGPointMake(8.05, 17.45)];
    [mentionPath addCurveToPoint: CGPointMake(35.1, 56.96) controlPoint1: CGPointMake(8.05, 48.41) controlPoint2: CGPointMake(18.54, 56.96)];
    [mentionPath addCurveToPoint: CGPointMake(39.96, 56.69) controlPoint1: CGPointMake(36.76, 56.96) controlPoint2: CGPointMake(38.44, 56.86)];
    [mentionPath addCurveToPoint: CGPointMake(41.02, 56.5) controlPoint1: CGPointMake(39.99, 56.69) controlPoint2: CGPointMake(40.34, 56.62)];
    [mentionPath addLineToPoint: CGPointMake(41.02, 56.5)];
    [mentionPath addCurveToPoint: CGPointMake(44.39, 58.82) controlPoint1: CGPointMake(42.59, 56.21) controlPoint2: CGPointMake(44.1, 57.25)];
    [mentionPath addCurveToPoint: CGPointMake(44.44, 59.34) controlPoint1: CGPointMake(44.42, 58.99) controlPoint2: CGPointMake(44.44, 59.17)];
    [mentionPath addLineToPoint: CGPointMake(44.44, 59.34)];
    [mentionPath addCurveToPoint: CGPointMake(40.87, 63.53) controlPoint1: CGPointMake(44.44, 61.43) controlPoint2: CGPointMake(42.93, 63.2)];
    [mentionPath addCurveToPoint: CGPointMake(39.99, 63.65) controlPoint1: CGPointMake(40.55, 63.58) controlPoint2: CGPointMake(40.26, 63.62)];
    [mentionPath addCurveToPoint: CGPointMake(34.24, 64) controlPoint1: CGPointMake(39.79, 63.68) controlPoint2: CGPointMake(35.99, 64)];
    [mentionPath addCurveToPoint: CGPointMake(0, 32.64) controlPoint1: CGPointMake(13.81, 64) controlPoint2: CGPointMake(0, 52.16)];
    [mentionPath addCurveToPoint: CGPointMake(33.44, 0) controlPoint1: CGPointMake(0, 13.34) controlPoint2: CGPointMake(13.67, 0)];
    [mentionPath closePath];
    mentionPath.usesEvenOddFillRule = YES;
    [color setFill];
    [mentionPath fill];
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

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(35.71, 12.99)];
    [bezierPath addCurveToPoint: CGPointMake(35.9, 11.38) controlPoint1: CGPointMake(35.84, 12.66) controlPoint2: CGPointMake(35.9, 12.13)];
    [bezierPath addLineToPoint: CGPointMake(35.9, 8.26)];
    [bezierPath addCurveToPoint: CGPointMake(35.71, 6.69) controlPoint1: CGPointMake(35.9, 7.54) controlPoint2: CGPointMake(35.84, 7.02)];
    [bezierPath addCurveToPoint: CGPointMake(35.05, 6.19) controlPoint1: CGPointMake(35.59, 6.35) controlPoint2: CGPointMake(35.36, 6.19)];
    [bezierPath addCurveToPoint: CGPointMake(34.4, 6.69) controlPoint1: CGPointMake(34.74, 6.19) controlPoint2: CGPointMake(34.53, 6.35)];
    [bezierPath addCurveToPoint: CGPointMake(34.22, 8.26) controlPoint1: CGPointMake(34.28, 7.02) controlPoint2: CGPointMake(34.22, 7.54)];
    [bezierPath addLineToPoint: CGPointMake(34.22, 11.38)];
    [bezierPath addCurveToPoint: CGPointMake(34.4, 12.99) controlPoint1: CGPointMake(34.22, 12.13) controlPoint2: CGPointMake(34.28, 12.66)];
    [bezierPath addCurveToPoint: CGPointMake(35.05, 13.48) controlPoint1: CGPointMake(34.51, 13.31) controlPoint2: CGPointMake(34.73, 13.48)];
    [bezierPath addCurveToPoint: CGPointMake(35.71, 12.99) controlPoint1: CGPointMake(35.36, 13.48) controlPoint2: CGPointMake(35.59, 13.31)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(33.18, 14.56)];
    [bezierPath addCurveToPoint: CGPointMake(32.21, 13.13) controlPoint1: CGPointMake(32.72, 14.25) controlPoint2: CGPointMake(32.4, 13.78)];
    [bezierPath addCurveToPoint: CGPointMake(31.93, 10.57) controlPoint1: CGPointMake(32.02, 12.49) controlPoint2: CGPointMake(31.93, 11.64)];
    [bezierPath addLineToPoint: CGPointMake(31.93, 9.11)];
    [bezierPath addCurveToPoint: CGPointMake(32.25, 6.51) controlPoint1: CGPointMake(31.93, 8.03) controlPoint2: CGPointMake(32.04, 7.17)];
    [bezierPath addCurveToPoint: CGPointMake(33.28, 5.08) controlPoint1: CGPointMake(32.47, 5.86) controlPoint2: CGPointMake(32.81, 5.38)];
    [bezierPath addCurveToPoint: CGPointMake(35.1, 4.63) controlPoint1: CGPointMake(33.74, 4.78) controlPoint2: CGPointMake(34.35, 4.63)];
    [bezierPath addCurveToPoint: CGPointMake(36.88, 5.09) controlPoint1: CGPointMake(35.84, 4.63) controlPoint2: CGPointMake(36.43, 4.79)];
    [bezierPath addCurveToPoint: CGPointMake(37.86, 6.52) controlPoint1: CGPointMake(37.33, 5.4) controlPoint2: CGPointMake(37.65, 5.87)];
    [bezierPath addCurveToPoint: CGPointMake(38.17, 9.11) controlPoint1: CGPointMake(38.07, 7.17) controlPoint2: CGPointMake(38.17, 8.03)];
    [bezierPath addLineToPoint: CGPointMake(38.17, 10.57)];
    [bezierPath addCurveToPoint: CGPointMake(37.87, 13.14) controlPoint1: CGPointMake(38.17, 11.64) controlPoint2: CGPointMake(38.07, 12.49)];
    [bezierPath addCurveToPoint: CGPointMake(36.89, 14.56) controlPoint1: CGPointMake(37.67, 13.79) controlPoint2: CGPointMake(37.34, 14.26)];
    [bezierPath addCurveToPoint: CGPointMake(35.05, 15.01) controlPoint1: CGPointMake(36.44, 14.86) controlPoint2: CGPointMake(35.82, 15.01)];
    [bezierPath addCurveToPoint: CGPointMake(33.18, 14.56) controlPoint1: CGPointMake(34.25, 15.01) controlPoint2: CGPointMake(33.63, 14.86)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(67.89, 10.59)];
    [bezierPath addLineToPoint: CGPointMake(67.89, 11.1)];
    [bezierPath addCurveToPoint: CGPointMake(67.95, 12.54) controlPoint1: CGPointMake(67.89, 11.74) controlPoint2: CGPointMake(67.91, 12.22)];
    [bezierPath addCurveToPoint: CGPointMake(68.19, 13.25) controlPoint1: CGPointMake(67.99, 12.87) controlPoint2: CGPointMake(68.07, 13.1)];
    [bezierPath addCurveToPoint: CGPointMake(68.74, 13.47) controlPoint1: CGPointMake(68.31, 13.39) controlPoint2: CGPointMake(68.49, 13.47)];
    [bezierPath addCurveToPoint: CGPointMake(69.44, 13.08) controlPoint1: CGPointMake(69.08, 13.47) controlPoint2: CGPointMake(69.31, 13.34)];
    [bezierPath addCurveToPoint: CGPointMake(69.64, 11.77) controlPoint1: CGPointMake(69.56, 12.81) controlPoint2: CGPointMake(69.63, 12.38)];
    [bezierPath addLineToPoint: CGPointMake(71.59, 11.88)];
    [bezierPath addCurveToPoint: CGPointMake(71.61, 12.24) controlPoint1: CGPointMake(71.6, 11.97) controlPoint2: CGPointMake(71.61, 12.09)];
    [bezierPath addCurveToPoint: CGPointMake(70.85, 14.32) controlPoint1: CGPointMake(71.61, 13.17) controlPoint2: CGPointMake(71.35, 13.86)];
    [bezierPath addCurveToPoint: CGPointMake(68.7, 15) controlPoint1: CGPointMake(70.34, 14.78) controlPoint2: CGPointMake(69.62, 15)];
    [bezierPath addCurveToPoint: CGPointMake(66.36, 13.96) controlPoint1: CGPointMake(67.58, 15) controlPoint2: CGPointMake(66.8, 14.66)];
    [bezierPath addCurveToPoint: CGPointMake(65.69, 10.72) controlPoint1: CGPointMake(65.91, 13.26) controlPoint2: CGPointMake(65.69, 12.18)];
    [bezierPath addLineToPoint: CGPointMake(65.69, 8.97)];
    [bezierPath addCurveToPoint: CGPointMake(66.38, 5.68) controlPoint1: CGPointMake(65.69, 7.47) controlPoint2: CGPointMake(65.92, 6.37)];
    [bezierPath addCurveToPoint: CGPointMake(68.76, 4.64) controlPoint1: CGPointMake(66.85, 4.99) controlPoint2: CGPointMake(67.64, 4.64)];
    [bezierPath addCurveToPoint: CGPointMake(70.54, 5.07) controlPoint1: CGPointMake(69.53, 4.64) controlPoint2: CGPointMake(70.13, 4.78)];
    [bezierPath addCurveToPoint: CGPointMake(71.42, 6.39) controlPoint1: CGPointMake(70.96, 5.35) controlPoint2: CGPointMake(71.25, 5.79)];
    [bezierPath addCurveToPoint: CGPointMake(71.67, 8.87) controlPoint1: CGPointMake(71.59, 6.99) controlPoint2: CGPointMake(71.67, 7.82)];
    [bezierPath addLineToPoint: CGPointMake(71.67, 10.59)];
    [bezierPath addLineToPoint: CGPointMake(67.89, 10.59)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(27.68, 10.4)];
    [bezierPath addLineToPoint: CGPointMake(25.12, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(27.36, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(28.26, 5.34)];
    [bezierPath addCurveToPoint: CGPointMake(28.76, 7.98) controlPoint1: CGPointMake(28.49, 6.37) controlPoint2: CGPointMake(28.65, 7.25)];
    [bezierPath addLineToPoint: CGPointMake(28.83, 7.98)];
    [bezierPath addCurveToPoint: CGPointMake(29.34, 5.35) controlPoint1: CGPointMake(28.9, 7.46) controlPoint2: CGPointMake(29.07, 6.58)];
    [bezierPath addLineToPoint: CGPointMake(30.27, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(32.51, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(29.91, 10.4)];
    [bezierPath addLineToPoint: CGPointMake(29.91, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(27.68, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(27.68, 10.4)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(45.45, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(45.45, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(43.69, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(43.49, 13.62)];
    [bezierPath addLineToPoint: CGPointMake(43.44, 13.62)];
    [bezierPath addCurveToPoint: CGPointMake(41.29, 15.01) controlPoint1: CGPointMake(42.96, 14.55) controlPoint2: CGPointMake(42.24, 15.01)];
    [bezierPath addCurveToPoint: CGPointMake(39.81, 14.36) controlPoint1: CGPointMake(40.62, 15.01) controlPoint2: CGPointMake(40.13, 14.8)];
    [bezierPath addCurveToPoint: CGPointMake(39.34, 12.32) controlPoint1: CGPointMake(39.5, 13.92) controlPoint2: CGPointMake(39.34, 13.24)];
    [bezierPath addLineToPoint: CGPointMake(39.34, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(41.6, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(41.6, 12.19)];
    [bezierPath addCurveToPoint: CGPointMake(41.74, 13.14) controlPoint1: CGPointMake(41.6, 12.63) controlPoint2: CGPointMake(41.65, 12.95)];
    [bezierPath addCurveToPoint: CGPointMake(42.23, 13.43) controlPoint1: CGPointMake(41.84, 13.33) controlPoint2: CGPointMake(42.01, 13.43)];
    [bezierPath addCurveToPoint: CGPointMake(42.8, 13.25) controlPoint1: CGPointMake(42.43, 13.43) controlPoint2: CGPointMake(42.62, 13.37)];
    [bezierPath addCurveToPoint: CGPointMake(43.2, 12.79) controlPoint1: CGPointMake(42.98, 13.13) controlPoint2: CGPointMake(43.11, 12.98)];
    [bezierPath addLineToPoint: CGPointMake(43.2, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(45.45, 4.83)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(57.02, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(57.02, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(55.26, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(55.06, 13.62)];
    [bezierPath addLineToPoint: CGPointMake(55.01, 13.62)];
    [bezierPath addCurveToPoint: CGPointMake(52.86, 15.01) controlPoint1: CGPointMake(54.53, 14.55) controlPoint2: CGPointMake(53.82, 15.01)];
    [bezierPath addCurveToPoint: CGPointMake(51.39, 14.36) controlPoint1: CGPointMake(52.19, 15.01) controlPoint2: CGPointMake(51.7, 14.8)];
    [bezierPath addCurveToPoint: CGPointMake(50.91, 12.32) controlPoint1: CGPointMake(51.07, 13.92) controlPoint2: CGPointMake(50.91, 13.24)];
    [bezierPath addLineToPoint: CGPointMake(50.91, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(53.17, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(53.17, 12.19)];
    [bezierPath addCurveToPoint: CGPointMake(53.31, 13.14) controlPoint1: CGPointMake(53.17, 12.63) controlPoint2: CGPointMake(53.22, 12.95)];
    [bezierPath addCurveToPoint: CGPointMake(53.8, 13.43) controlPoint1: CGPointMake(53.41, 13.33) controlPoint2: CGPointMake(53.58, 13.43)];
    [bezierPath addCurveToPoint: CGPointMake(54.37, 13.25) controlPoint1: CGPointMake(54, 13.43) controlPoint2: CGPointMake(54.19, 13.37)];
    [bezierPath addCurveToPoint: CGPointMake(54.77, 12.79) controlPoint1: CGPointMake(54.55, 13.13) controlPoint2: CGPointMake(54.68, 12.98)];
    [bezierPath addLineToPoint: CGPointMake(54.77, 4.83)];
    [bezierPath addLineToPoint: CGPointMake(57.02, 4.83)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(51.58, 2.95)];
    [bezierPath addLineToPoint: CGPointMake(49.34, 2.95)];
    [bezierPath addLineToPoint: CGPointMake(49.34, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(47.14, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(47.14, 2.95)];
    [bezierPath addLineToPoint: CGPointMake(44.9, 2.95)];
    [bezierPath addLineToPoint: CGPointMake(44.9, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(51.58, 1.14)];
    [bezierPath addLineToPoint: CGPointMake(51.58, 2.95)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(64.49, 6.43)];
    [bezierPath addCurveToPoint: CGPointMake(64.69, 9.06) controlPoint1: CGPointMake(64.63, 7.06) controlPoint2: CGPointMake(64.69, 7.94)];
    [bezierPath addLineToPoint: CGPointMake(64.69, 10.65)];
    [bezierPath addCurveToPoint: CGPointMake(64.16, 13.94) controlPoint1: CGPointMake(64.69, 12.14) controlPoint2: CGPointMake(64.51, 13.24)];
    [bezierPath addCurveToPoint: CGPointMake(62.47, 15) controlPoint1: CGPointMake(63.8, 14.65) controlPoint2: CGPointMake(63.23, 15)];
    [bezierPath addCurveToPoint: CGPointMake(61.31, 14.7) controlPoint1: CGPointMake(62.05, 15) controlPoint2: CGPointMake(61.66, 14.9)];
    [bezierPath addCurveToPoint: CGPointMake(60.53, 13.9) controlPoint1: CGPointMake(60.96, 14.51) controlPoint2: CGPointMake(60.7, 14.24)];
    [bezierPath addLineToPoint: CGPointMake(60.48, 13.9)];
    [bezierPath addLineToPoint: CGPointMake(60.25, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(58.39, 14.85)];
    [bezierPath addLineToPoint: CGPointMake(58.39, 0.63)];
    [bezierPath addLineToPoint: CGPointMake(60.56, 0.63)];
    [bezierPath addLineToPoint: CGPointMake(60.56, 5.91)];
    [bezierPath addLineToPoint: CGPointMake(60.58, 5.91)];
    [bezierPath addCurveToPoint: CGPointMake(61.41, 4.99) controlPoint1: CGPointMake(60.77, 5.53) controlPoint2: CGPointMake(61.05, 5.22)];
    [bezierPath addCurveToPoint: CGPointMake(62.57, 4.63) controlPoint1: CGPointMake(61.77, 4.75) controlPoint2: CGPointMake(62.16, 4.63)];
    [bezierPath addCurveToPoint: CGPointMake(63.83, 5.06) controlPoint1: CGPointMake(63.1, 4.63) controlPoint2: CGPointMake(63.52, 4.78)];
    [bezierPath addCurveToPoint: CGPointMake(64.49, 6.43) controlPoint1: CGPointMake(64.13, 5.34) controlPoint2: CGPointMake(64.35, 5.8)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(22.38, 2.5)];
    [bezierPath addCurveToPoint: CGPointMake(22.86, 8) controlPoint1: CGPointMake(22.86, 4.28) controlPoint2: CGPointMake(22.86, 8)];
    [bezierPath addCurveToPoint: CGPointMake(22.38, 13.5) controlPoint1: CGPointMake(22.86, 8) controlPoint2: CGPointMake(22.86, 11.72)];
    [bezierPath addCurveToPoint: CGPointMake(20.36, 15.52) controlPoint1: CGPointMake(22.12, 14.48) controlPoint2: CGPointMake(21.34, 15.26)];
    [bezierPath addCurveToPoint: CGPointMake(11.43, 16) controlPoint1: CGPointMake(18.58, 16) controlPoint2: CGPointMake(11.43, 16)];
    [bezierPath addCurveToPoint: CGPointMake(2.5, 15.52) controlPoint1: CGPointMake(11.43, 16) controlPoint2: CGPointMake(4.28, 16)];
    [bezierPath addCurveToPoint: CGPointMake(0.48, 13.5) controlPoint1: CGPointMake(1.51, 15.26) controlPoint2: CGPointMake(0.74, 14.48)];
    [bezierPath addCurveToPoint: CGPointMake(0, 8) controlPoint1: CGPointMake(0, 11.72) controlPoint2: CGPointMake(0, 8)];
    [bezierPath addCurveToPoint: CGPointMake(0.48, 2.5) controlPoint1: CGPointMake(0, 8) controlPoint2: CGPointMake(0, 4.28)];
    [bezierPath addCurveToPoint: CGPointMake(2.5, 0.48) controlPoint1: CGPointMake(0.74, 1.51) controlPoint2: CGPointMake(1.51, 0.74)];
    [bezierPath addCurveToPoint: CGPointMake(11.43, 0) controlPoint1: CGPointMake(4.28, 0) controlPoint2: CGPointMake(11.43, 0)];
    [bezierPath addCurveToPoint: CGPointMake(20.36, 0.48) controlPoint1: CGPointMake(11.43, 0) controlPoint2: CGPointMake(18.58, 0)];
    [bezierPath addCurveToPoint: CGPointMake(22.38, 2.5) controlPoint1: CGPointMake(21.34, 0.74) controlPoint2: CGPointMake(22.12, 1.51)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(9.14, 11.43)];
    [bezierPath addLineToPoint: CGPointMake(15.08, 8)];
    [bezierPath addLineToPoint: CGPointMake(9.14, 4.57)];
    [bezierPath addLineToPoint: CGPointMake(9.14, 11.43)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(68.18, 6.37)];
    [bezierPath addCurveToPoint: CGPointMake(67.95, 7.07) controlPoint1: CGPointMake(68.07, 6.52) controlPoint2: CGPointMake(67.99, 6.75)];
    [bezierPath addCurveToPoint: CGPointMake(67.89, 8.53) controlPoint1: CGPointMake(67.91, 7.39) controlPoint2: CGPointMake(67.89, 7.88)];
    [bezierPath addLineToPoint: CGPointMake(67.89, 9.25)];
    [bezierPath addLineToPoint: CGPointMake(69.55, 9.25)];
    [bezierPath addLineToPoint: CGPointMake(69.55, 8.53)];
    [bezierPath addCurveToPoint: CGPointMake(69.48, 7.07) controlPoint1: CGPointMake(69.55, 7.89) controlPoint2: CGPointMake(69.52, 7.4)];
    [bezierPath addCurveToPoint: CGPointMake(69.24, 6.37) controlPoint1: CGPointMake(69.44, 6.74) controlPoint2: CGPointMake(69.36, 6.5)];
    [bezierPath addCurveToPoint: CGPointMake(68.71, 6.16) controlPoint1: CGPointMake(69.13, 6.23) controlPoint2: CGPointMake(68.95, 6.16)];
    [bezierPath addCurveToPoint: CGPointMake(68.18, 6.37) controlPoint1: CGPointMake(68.47, 6.16) controlPoint2: CGPointMake(68.3, 6.23)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(62.42, 10.52)];
    [bezierPath addLineToPoint: CGPointMake(62.42, 9.23)];
    [bezierPath addCurveToPoint: CGPointMake(62.35, 7.41) controlPoint1: CGPointMake(62.42, 8.44) controlPoint2: CGPointMake(62.4, 7.84)];
    [bezierPath addCurveToPoint: CGPointMake(62.09, 6.51) controlPoint1: CGPointMake(62.3, 6.99) controlPoint2: CGPointMake(62.21, 6.69)];
    [bezierPath addCurveToPoint: CGPointMake(61.56, 6.24) controlPoint1: CGPointMake(61.96, 6.33) controlPoint2: CGPointMake(61.78, 6.24)];
    [bezierPath addCurveToPoint: CGPointMake(60.95, 6.5) controlPoint1: CGPointMake(61.34, 6.24) controlPoint2: CGPointMake(61.14, 6.32)];
    [bezierPath addCurveToPoint: CGPointMake(60.56, 7.17) controlPoint1: CGPointMake(60.77, 6.67) controlPoint2: CGPointMake(60.64, 6.9)];
    [bezierPath addLineToPoint: CGPointMake(60.56, 12.86)];
    [bezierPath addCurveToPoint: CGPointMake(60.94, 13.25) controlPoint1: CGPointMake(60.66, 13.03) controlPoint2: CGPointMake(60.78, 13.16)];
    [bezierPath addCurveToPoint: CGPointMake(61.46, 13.38) controlPoint1: CGPointMake(61.1, 13.34) controlPoint2: CGPointMake(61.27, 13.38)];
    [bezierPath addCurveToPoint: CGPointMake(62.03, 13.12) controlPoint1: CGPointMake(61.7, 13.38) controlPoint2: CGPointMake(61.89, 13.29)];
    [bezierPath addCurveToPoint: CGPointMake(62.33, 12.24) controlPoint1: CGPointMake(62.17, 12.94) controlPoint2: CGPointMake(62.27, 12.65)];
    [bezierPath addCurveToPoint: CGPointMake(62.42, 10.52) controlPoint1: CGPointMake(62.39, 11.82) controlPoint2: CGPointMake(62.42, 11.25)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
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
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Fill-1 Drawing
    UIBezierPath* fill1Path = [UIBezierPath bezierPath];
    [fill1Path moveToPoint: CGPointMake(5.88, 145.5)];
    [fill1Path addCurveToPoint: CGPointMake(2.94, 148.44) controlPoint1: CGPointMake(5.88, 147.12) controlPoint2: CGPointMake(4.57, 148.44)];
    [fill1Path addCurveToPoint: CGPointMake(-0, 145.5) controlPoint1: CGPointMake(1.32, 148.44) controlPoint2: CGPointMake(-0, 147.12)];
    [fill1Path addLineToPoint: CGPointMake(-0, 49.96)];
    [fill1Path addCurveToPoint: CGPointMake(2.94, 47.02) controlPoint1: CGPointMake(-0, 48.34) controlPoint2: CGPointMake(1.32, 47.02)];
    [fill1Path addCurveToPoint: CGPointMake(32.2, 44.35) controlPoint1: CGPointMake(12.13, 47.02) controlPoint2: CGPointMake(21.91, 46.11)];
    [fill1Path addCurveToPoint: CGPointMake(100.35, 23.73) controlPoint1: CGPointMake(53.75, 40.67) controlPoint2: CGPointMake(76.83, 33.45)];
    [fill1Path addCurveToPoint: CGPointMake(135.05, 7.66) controlPoint1: CGPointMake(112.71, 18.61) controlPoint2: CGPointMake(124.4, 13.14)];
    [fill1Path addCurveToPoint: CGPointMake(144.99, 2.37) controlPoint1: CGPointMake(138.78, 5.74) controlPoint2: CGPointMake(142.11, 3.97)];
    [fill1Path addCurveToPoint: CGPointMake(147.63, 0.9) controlPoint1: CGPointMake(146, 1.82) controlPoint2: CGPointMake(146.88, 1.32)];
    [fill1Path addCurveToPoint: CGPointMake(148.3, 0.51) controlPoint1: CGPointMake(147.88, 0.75) controlPoint2: CGPointMake(148.11, 0.62)];
    [fill1Path addCurveToPoint: CGPointMake(151.49, 0.39) controlPoint1: CGPointMake(149.43, -0.15) controlPoint2: CGPointMake(150.57, -0.15)];
    [fill1Path addCurveToPoint: CGPointMake(152.37, 0.9) controlPoint1: CGPointMake(151.89, 0.62) controlPoint2: CGPointMake(152.12, 0.75)];
    [fill1Path addCurveToPoint: CGPointMake(155.01, 2.37) controlPoint1: CGPointMake(153.12, 1.32) controlPoint2: CGPointMake(154, 1.82)];
    [fill1Path addCurveToPoint: CGPointMake(164.95, 7.66) controlPoint1: CGPointMake(157.89, 3.97) controlPoint2: CGPointMake(161.22, 5.74)];
    [fill1Path addCurveToPoint: CGPointMake(199.65, 23.73) controlPoint1: CGPointMake(175.6, 13.14) controlPoint2: CGPointMake(187.29, 18.61)];
    [fill1Path addCurveToPoint: CGPointMake(267.8, 44.35) controlPoint1: CGPointMake(223.17, 33.45) controlPoint2: CGPointMake(246.25, 40.67)];
    [fill1Path addCurveToPoint: CGPointMake(297.06, 47.02) controlPoint1: CGPointMake(278.09, 46.11) controlPoint2: CGPointMake(287.87, 47.02)];
    [fill1Path addCurveToPoint: CGPointMake(300, 49.96) controlPoint1: CGPointMake(298.68, 47.02) controlPoint2: CGPointMake(300, 48.34)];
    [fill1Path addLineToPoint: CGPointMake(300, 88.18)];
    [fill1Path addCurveToPoint: CGPointMake(297.06, 91.12) controlPoint1: CGPointMake(300, 89.8) controlPoint2: CGPointMake(298.68, 91.12)];
    [fill1Path addCurveToPoint: CGPointMake(294.12, 88.18) controlPoint1: CGPointMake(295.43, 91.12) controlPoint2: CGPointMake(294.12, 89.8)];
    [fill1Path addLineToPoint: CGPointMake(294.12, 52.87)];
    [fill1Path addCurveToPoint: CGPointMake(266.81, 50.15) controlPoint1: CGPointMake(285.45, 52.7) controlPoint2: CGPointMake(276.33, 51.77)];
    [fill1Path addCurveToPoint: CGPointMake(197.41, 29.16) controlPoint1: CGPointMake(244.77, 46.39) controlPoint2: CGPointMake(221.3, 39.04)];
    [fill1Path addCurveToPoint: CGPointMake(162.26, 12.89) controlPoint1: CGPointMake(184.89, 23.98) controlPoint2: CGPointMake(173.05, 18.44)];
    [fill1Path addCurveToPoint: CGPointMake(152.16, 7.52) controlPoint1: CGPointMake(158.48, 10.95) controlPoint2: CGPointMake(155.1, 9.14)];
    [fill1Path addCurveToPoint: CGPointMake(150, 6.31) controlPoint1: CGPointMake(151.36, 7.08) controlPoint2: CGPointMake(150.64, 6.67)];
    [fill1Path addCurveToPoint: CGPointMake(147.84, 7.52) controlPoint1: CGPointMake(149.36, 6.67) controlPoint2: CGPointMake(148.64, 7.08)];
    [fill1Path addCurveToPoint: CGPointMake(137.74, 12.89) controlPoint1: CGPointMake(144.9, 9.14) controlPoint2: CGPointMake(141.52, 10.95)];
    [fill1Path addCurveToPoint: CGPointMake(102.59, 29.16) controlPoint1: CGPointMake(126.95, 18.44) controlPoint2: CGPointMake(115.11, 23.98)];
    [fill1Path addCurveToPoint: CGPointMake(33.19, 50.15) controlPoint1: CGPointMake(78.7, 39.04) controlPoint2: CGPointMake(55.23, 46.39)];
    [fill1Path addCurveToPoint: CGPointMake(5.88, 52.87) controlPoint1: CGPointMake(23.67, 51.77) controlPoint2: CGPointMake(14.55, 52.7)];
    [fill1Path addLineToPoint: CGPointMake(5.88, 145.5)];
    [fill1Path closePath];
    fill1Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill1Path fill];
    
    
    //// Fill-4 Drawing
    UIBezierPath* fill4Path = [UIBezierPath bezierPath];
    [fill4Path moveToPoint: CGPointMake(255.88, 276.29)];
    [fill4Path addCurveToPoint: CGPointMake(236.76, 257.18) controlPoint1: CGPointMake(245.32, 276.29) controlPoint2: CGPointMake(236.76, 267.73)];
    [fill4Path addCurveToPoint: CGPointMake(255.88, 238.08) controlPoint1: CGPointMake(236.76, 246.63) controlPoint2: CGPointMake(245.32, 238.08)];
    [fill4Path addCurveToPoint: CGPointMake(275, 257.18) controlPoint1: CGPointMake(266.44, 238.08) controlPoint2: CGPointMake(275, 246.63)];
    [fill4Path addCurveToPoint: CGPointMake(255.88, 276.29) controlPoint1: CGPointMake(275, 267.73) controlPoint2: CGPointMake(266.44, 276.29)];
    [fill4Path closePath];
    [fill4Path moveToPoint: CGPointMake(255.88, 232.2)];
    [fill4Path addCurveToPoint: CGPointMake(230.88, 257.18) controlPoint1: CGPointMake(242.08, 232.2) controlPoint2: CGPointMake(230.88, 243.38)];
    [fill4Path addCurveToPoint: CGPointMake(255.88, 282.17) controlPoint1: CGPointMake(230.88, 270.98) controlPoint2: CGPointMake(242.08, 282.17)];
    [fill4Path addCurveToPoint: CGPointMake(280.88, 257.18) controlPoint1: CGPointMake(269.69, 282.17) controlPoint2: CGPointMake(280.88, 270.98)];
    [fill4Path addCurveToPoint: CGPointMake(255.88, 232.2) controlPoint1: CGPointMake(280.88, 243.38) controlPoint2: CGPointMake(269.69, 232.2)];
    [fill4Path closePath];
    fill4Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill4Path fill];
    
    
    //// Fill-6 Drawing
    UIBezierPath* fill6Path = [UIBezierPath bezierPath];
    [fill6Path moveToPoint: CGPointMake(269.16, 260.2)];
    [fill6Path addCurveToPoint: CGPointMake(265.11, 261.14) controlPoint1: CGPointMake(267.78, 259.34) controlPoint2: CGPointMake(265.97, 259.76)];
    [fill6Path addCurveToPoint: CGPointMake(256.57, 265.27) controlPoint1: CGPointMake(263.37, 263.91) controlPoint2: CGPointMake(260.66, 265.27)];
    [fill6Path addCurveToPoint: CGPointMake(247.21, 260.93) controlPoint1: CGPointMake(252.42, 265.27) controlPoint2: CGPointMake(249.39, 263.84)];
    [fill6Path addCurveToPoint: CGPointMake(243.09, 260.34) controlPoint1: CGPointMake(246.23, 259.63) controlPoint2: CGPointMake(244.39, 259.37)];
    [fill6Path addCurveToPoint: CGPointMake(242.5, 264.46) controlPoint1: CGPointMake(241.79, 261.32) controlPoint2: CGPointMake(241.53, 263.16)];
    [fill6Path addCurveToPoint: CGPointMake(256.57, 271.14) controlPoint1: CGPointMake(245.83, 268.89) controlPoint2: CGPointMake(250.62, 271.14)];
    [fill6Path addCurveToPoint: CGPointMake(270.09, 264.25) controlPoint1: CGPointMake(262.6, 271.14) controlPoint2: CGPointMake(267.23, 268.83)];
    [fill6Path addCurveToPoint: CGPointMake(269.16, 260.2) controlPoint1: CGPointMake(270.96, 262.88) controlPoint2: CGPointMake(270.54, 261.06)];
    [fill6Path closePath];
    fill6Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill6Path fill];
    
    
    //// Fill-8 Drawing
    UIBezierPath* fill8Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(259.6, 247.82, 7.4, 7.4)];
    [color setFill];
    [fill8Path fill];
    
    
    //// Fill-10 Drawing
    UIBezierPath* fill10Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(245.85, 247.82, 7.4, 7.4)];
    [color setFill];
    [fill10Path fill];
    
    
    //// Fill-12 Drawing
    UIBezierPath* fill12Path = [UIBezierPath bezierPath];
    [fill12Path moveToPoint: CGPointMake(291.17, 97)];
    [fill12Path addLineToPoint: CGPointMake(238.22, 97)];
    [fill12Path addCurveToPoint: CGPointMake(235.28, 94.06) controlPoint1: CGPointMake(236.59, 97) controlPoint2: CGPointMake(235.28, 95.68)];
    [fill12Path addCurveToPoint: CGPointMake(238.22, 91.12) controlPoint1: CGPointMake(235.28, 92.44) controlPoint2: CGPointMake(236.59, 91.12)];
    [fill12Path addCurveToPoint: CGPointMake(238.74, 91.17) controlPoint1: CGPointMake(238.38, 91.12) controlPoint2: CGPointMake(238.55, 91.14)];
    [fill12Path addCurveToPoint: CGPointMake(242.03, 87.28) controlPoint1: CGPointMake(240.97, 91.57) controlPoint2: CGPointMake(242.8, 89.41)];
    [fill12Path addCurveToPoint: CGPointMake(241.16, 82.3) controlPoint1: CGPointMake(241.46, 85.7) controlPoint2: CGPointMake(241.16, 84.02)];
    [fill12Path addCurveToPoint: CGPointMake(255.87, 67.61) controlPoint1: CGPointMake(241.16, 74.19) controlPoint2: CGPointMake(247.75, 67.61)];
    [fill12Path addCurveToPoint: CGPointMake(269.75, 77.45) controlPoint1: CGPointMake(262.17, 67.61) controlPoint2: CGPointMake(267.71, 71.6)];
    [fill12Path addCurveToPoint: CGPointMake(272.77, 79.4) controlPoint1: CGPointMake(270.2, 78.71) controlPoint2: CGPointMake(271.44, 79.51)];
    [fill12Path addCurveToPoint: CGPointMake(273.52, 79.36) controlPoint1: CGPointMake(273.11, 79.38) controlPoint2: CGPointMake(273.33, 79.36)];
    [fill12Path addCurveToPoint: CGPointMake(282.35, 88.18) controlPoint1: CGPointMake(278.4, 79.36) controlPoint2: CGPointMake(282.35, 83.31)];
    [fill12Path addCurveToPoint: CGPointMake(285.29, 91.12) controlPoint1: CGPointMake(282.35, 89.8) controlPoint2: CGPointMake(283.67, 91.12)];
    [fill12Path addCurveToPoint: CGPointMake(288.23, 88.18) controlPoint1: CGPointMake(286.91, 91.12) controlPoint2: CGPointMake(288.23, 89.8)];
    [fill12Path addCurveToPoint: CGPointMake(274.49, 73.52) controlPoint1: CGPointMake(288.23, 80.39) controlPoint2: CGPointMake(282.16, 74.02)];
    [fill12Path addCurveToPoint: CGPointMake(255.87, 61.73) controlPoint1: CGPointMake(271.14, 66.43) controlPoint2: CGPointMake(263.96, 61.73)];
    [fill12Path addCurveToPoint: CGPointMake(235.28, 82.3) controlPoint1: CGPointMake(244.5, 61.73) controlPoint2: CGPointMake(235.28, 70.94)];
    [fill12Path addCurveToPoint: CGPointMake(235.55, 85.65) controlPoint1: CGPointMake(235.28, 83.43) controlPoint2: CGPointMake(235.37, 84.55)];
    [fill12Path addCurveToPoint: CGPointMake(229.39, 94.06) controlPoint1: CGPointMake(231.98, 86.78) controlPoint2: CGPointMake(229.39, 90.12)];
    [fill12Path addCurveToPoint: CGPointMake(238.22, 102.88) controlPoint1: CGPointMake(229.39, 98.93) controlPoint2: CGPointMake(233.34, 102.88)];
    [fill12Path addLineToPoint: CGPointMake(291.17, 102.88)];
    [fill12Path addCurveToPoint: CGPointMake(294.12, 105.82) controlPoint1: CGPointMake(293.47, 102.88) controlPoint2: CGPointMake(294.12, 103.52)];
    [fill12Path addLineToPoint: CGPointMake(294.12, 238.09)];
    [fill12Path addCurveToPoint: CGPointMake(239.33, 346.02) controlPoint1: CGPointMake(294.12, 281.78) controlPoint2: CGPointMake(273.8, 318.68)];
    [fill12Path addCurveToPoint: CGPointMake(149.96, 382.12) controlPoint1: CGPointMake(211.17, 368.35) controlPoint2: CGPointMake(175.19, 382.12)];
    [fill12Path addCurveToPoint: CGPointMake(102, 370.63) controlPoint1: CGPointMake(136.66, 382.12) controlPoint2: CGPointMake(119.43, 378.08)];
    [fill12Path addCurveToPoint: CGPointMake(49.09, 336.02) controlPoint1: CGPointMake(82.73, 362.4) controlPoint2: CGPointMake(64.34, 350.56)];
    [fill12Path addCurveToPoint: CGPointMake(44.93, 336.12) controlPoint1: CGPointMake(47.91, 334.9) controlPoint2: CGPointMake(46.05, 334.95)];
    [fill12Path addCurveToPoint: CGPointMake(45.03, 340.28) controlPoint1: CGPointMake(43.81, 337.3) controlPoint2: CGPointMake(43.85, 339.16)];
    [fill12Path addCurveToPoint: CGPointMake(149.96, 388) controlPoint1: CGPointMake(75.57, 369.39) controlPoint2: CGPointMake(119.14, 388)];
    [fill12Path addCurveToPoint: CGPointMake(242.99, 350.62) controlPoint1: CGPointMake(176.58, 388) controlPoint2: CGPointMake(213.83, 373.74)];
    [fill12Path addCurveToPoint: CGPointMake(300, 238.09) controlPoint1: CGPointMake(278.79, 322.24) controlPoint2: CGPointMake(300, 283.7)];
    [fill12Path addLineToPoint: CGPointMake(300, 105.82)];
    [fill12Path addCurveToPoint: CGPointMake(291.17, 97) controlPoint1: CGPointMake(300, 100.28) controlPoint2: CGPointMake(296.72, 97)];
    [fill12Path closePath];
    fill12Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill12Path fill];
    
    
    //// Fill-14 Drawing
    UIBezierPath* fill14Path = [UIBezierPath bezierPath];
    [fill14Path moveToPoint: CGPointMake(55.88, 114.62)];
    [fill14Path addLineToPoint: CGPointMake(20.59, 114.62)];
    [fill14Path addCurveToPoint: CGPointMake(17.65, 111.68) controlPoint1: CGPointMake(18.96, 114.62) controlPoint2: CGPointMake(17.65, 113.31)];
    [fill14Path addLineToPoint: CGPointMake(17.65, 64.65)];
    [fill14Path addCurveToPoint: CGPointMake(20.59, 61.71) controlPoint1: CGPointMake(17.65, 63.03) controlPoint2: CGPointMake(18.96, 61.71)];
    [fill14Path addLineToPoint: CGPointMake(44.12, 61.71)];
    [fill14Path addCurveToPoint: CGPointMake(46.2, 62.57) controlPoint1: CGPointMake(44.9, 61.71) controlPoint2: CGPointMake(45.65, 62.02)];
    [fill14Path addLineToPoint: CGPointMake(57.96, 74.33)];
    [fill14Path addCurveToPoint: CGPointMake(58.82, 76.41) controlPoint1: CGPointMake(58.51, 74.88) controlPoint2: CGPointMake(58.82, 75.63)];
    [fill14Path addLineToPoint: CGPointMake(58.82, 111.68)];
    [fill14Path addCurveToPoint: CGPointMake(55.88, 114.62) controlPoint1: CGPointMake(58.82, 113.31) controlPoint2: CGPointMake(57.51, 114.62)];
    [fill14Path closePath];
    [fill14Path moveToPoint: CGPointMake(52.94, 108.74)];
    [fill14Path addLineToPoint: CGPointMake(52.94, 77.63)];
    [fill14Path addLineToPoint: CGPointMake(42.9, 67.59)];
    [fill14Path addLineToPoint: CGPointMake(23.53, 67.59)];
    [fill14Path addLineToPoint: CGPointMake(23.53, 108.74)];
    [fill14Path addLineToPoint: CGPointMake(52.94, 108.74)];
    [fill14Path closePath];
    fill14Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill14Path fill];
    
    
    //// Fill-16 Drawing
    UIBezierPath* fill16Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(29, 81, 18, 6) cornerRadius: 3];
    [color setFill];
    [fill16Path fill];
    
    
    //// Fill-18 Drawing
    UIBezierPath* fill18Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(29, 91, 18, 6) cornerRadius: 3];
    [color setFill];
    [fill18Path fill];
    
    
    //// Fill-20 Drawing
    UIBezierPath* fill20Path = [UIBezierPath bezierPath];
    [fill20Path moveToPoint: CGPointMake(162.98, 364.55)];
    [fill20Path addLineToPoint: CGPointMake(152.07, 375.37)];
    [fill20Path addCurveToPoint: CGPointMake(147.06, 373.29) controlPoint1: CGPointMake(150.22, 377.22) controlPoint2: CGPointMake(147.06, 375.9)];
    [fill20Path addLineToPoint: CGPointMake(147.06, 338.02)];
    [fill20Path addCurveToPoint: CGPointMake(155.88, 329.2) controlPoint1: CGPointMake(147.06, 333.15) controlPoint2: CGPointMake(151.01, 329.2)];
    [fill20Path addLineToPoint: CGPointMake(191.1, 329.2)];
    [fill20Path addCurveToPoint: CGPointMake(200, 338.1) controlPoint1: CGPointMake(196.01, 329.2) controlPoint2: CGPointMake(200, 333.18)];
    [fill20Path addLineToPoint: CGPointMake(200, 355.73)];
    [fill20Path addCurveToPoint: CGPointMake(191.18, 364.55) controlPoint1: CGPointMake(200, 360.6) controlPoint2: CGPointMake(196.05, 364.55)];
    [fill20Path addLineToPoint: CGPointMake(162.98, 364.55)];
    [fill20Path closePath];
    [fill20Path moveToPoint: CGPointMake(152.94, 366.23)];
    [fill20Path addLineToPoint: CGPointMake(159.69, 359.53)];
    [fill20Path addCurveToPoint: CGPointMake(161.76, 358.67) controlPoint1: CGPointMake(160.24, 358.98) controlPoint2: CGPointMake(160.99, 358.67)];
    [fill20Path addLineToPoint: CGPointMake(191.18, 358.67)];
    [fill20Path addCurveToPoint: CGPointMake(194.12, 355.73) controlPoint1: CGPointMake(192.8, 358.67) controlPoint2: CGPointMake(194.12, 357.36)];
    [fill20Path addLineToPoint: CGPointMake(194.12, 338.1)];
    [fill20Path addCurveToPoint: CGPointMake(191.1, 335.08) controlPoint1: CGPointMake(194.12, 336.43) controlPoint2: CGPointMake(192.76, 335.08)];
    [fill20Path addLineToPoint: CGPointMake(155.88, 335.08)];
    [fill20Path addCurveToPoint: CGPointMake(152.94, 338.02) controlPoint1: CGPointMake(154.26, 335.08) controlPoint2: CGPointMake(152.94, 336.39)];
    [fill20Path addLineToPoint: CGPointMake(152.94, 366.23)];
    [fill20Path closePath];
    fill20Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill20Path fill];
    
    
    //// Fill-22 Drawing
    UIBezierPath* fill22Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(159, 344.1, 6, 6)];
    [color setFill];
    [fill22Path fill];
    
    
    //// Fill-24 Drawing
    UIBezierPath* fill24Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(171, 344.1, 6, 6)];
    [color setFill];
    [fill24Path fill];
    
    
    //// Fill-26 Drawing
    UIBezierPath* fill26Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(182, 344.1, 6, 6)];
    [color setFill];
    [fill26Path fill];
    
    
    //// Fill-28 Drawing
    UIBezierPath* fill28Path = [UIBezierPath bezierPath];
    [fill28Path moveToPoint: CGPointMake(150, 193.99)];
    [fill28Path addCurveToPoint: CGPointMake(158.82, 202.8) controlPoint1: CGPointMake(154.87, 193.99) controlPoint2: CGPointMake(158.82, 197.93)];
    [fill28Path addCurveToPoint: CGPointMake(150, 211.62) controlPoint1: CGPointMake(158.82, 207.67) controlPoint2: CGPointMake(154.87, 211.62)];
    [fill28Path addCurveToPoint: CGPointMake(141.18, 202.8) controlPoint1: CGPointMake(145.13, 211.62) controlPoint2: CGPointMake(141.18, 207.67)];
    [fill28Path addCurveToPoint: CGPointMake(150, 193.99) controlPoint1: CGPointMake(141.18, 197.93) controlPoint2: CGPointMake(145.13, 193.99)];
    [fill28Path closePath];
    [fill28Path moveToPoint: CGPointMake(150, 217.5)];
    [fill28Path addCurveToPoint: CGPointMake(164.71, 202.8) controlPoint1: CGPointMake(158.12, 217.5) controlPoint2: CGPointMake(164.71, 210.92)];
    [fill28Path addCurveToPoint: CGPointMake(150, 188.11) controlPoint1: CGPointMake(164.71, 194.69) controlPoint2: CGPointMake(158.12, 188.11)];
    [fill28Path addCurveToPoint: CGPointMake(135.29, 202.8) controlPoint1: CGPointMake(141.88, 188.11) controlPoint2: CGPointMake(135.29, 194.69)];
    [fill28Path addCurveToPoint: CGPointMake(150, 217.5) controlPoint1: CGPointMake(135.29, 210.92) controlPoint2: CGPointMake(141.88, 217.5)];
    [fill28Path closePath];
    fill28Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill28Path fill];
    
    
    //// Fill-30 Drawing
    UIBezierPath* fill30Path = [UIBezierPath bezierPath];
    [fill30Path moveToPoint: CGPointMake(164.71, 235.14)];
    [fill30Path addLineToPoint: CGPointMake(135.29, 235.14)];
    [fill30Path addLineToPoint: CGPointMake(135.29, 226.32)];
    [fill30Path addCurveToPoint: CGPointMake(136.61, 223.8) controlPoint1: CGPointMake(135.29, 224.9) controlPoint2: CGPointMake(135.73, 224.24)];
    [fill30Path addCurveToPoint: CGPointMake(137.69, 223.45) controlPoint1: CGPointMake(136.93, 223.64) controlPoint2: CGPointMake(137.31, 223.52)];
    [fill30Path addLineToPoint: CGPointMake(148.68, 228.95)];
    [fill30Path addCurveToPoint: CGPointMake(151.32, 228.95) controlPoint1: CGPointMake(149.51, 229.36) controlPoint2: CGPointMake(150.49, 229.36)];
    [fill30Path addLineToPoint: CGPointMake(162.39, 223.41)];
    [fill30Path addCurveToPoint: CGPointMake(164.28, 224.69) controlPoint1: CGPointMake(163.39, 223.53) controlPoint2: CGPointMake(163.91, 223.96)];
    [fill30Path addCurveToPoint: CGPointMake(164.65, 225.88) controlPoint1: CGPointMake(164.46, 225.05) controlPoint2: CGPointMake(164.58, 225.47)];
    [fill30Path addCurveToPoint: CGPointMake(164.71, 226.32) controlPoint1: CGPointMake(164.69, 226.12) controlPoint2: CGPointMake(164.71, 226.29)];
    [fill30Path addLineToPoint: CGPointMake(164.71, 235.14)];
    [fill30Path closePath];
    [fill30Path moveToPoint: CGPointMake(170.46, 224.92)];
    [fill30Path addCurveToPoint: CGPointMake(169.54, 222.06) controlPoint1: CGPointMake(170.3, 223.96) controlPoint2: CGPointMake(170.01, 222.99)];
    [fill30Path addCurveToPoint: CGPointMake(161.76, 217.5) controlPoint1: CGPointMake(168.14, 219.26) controlPoint2: CGPointMake(165.49, 217.5)];
    [fill30Path addCurveToPoint: CGPointMake(160.45, 217.81) controlPoint1: CGPointMake(161.31, 217.5) controlPoint2: CGPointMake(160.86, 217.61)];
    [fill30Path addLineToPoint: CGPointMake(150, 223.03)];
    [fill30Path addLineToPoint: CGPointMake(139.55, 217.81)];
    [fill30Path addCurveToPoint: CGPointMake(138.24, 217.5) controlPoint1: CGPointMake(139.14, 217.61) controlPoint2: CGPointMake(138.69, 217.5)];
    [fill30Path addCurveToPoint: CGPointMake(136.83, 217.63) controlPoint1: CGPointMake(137.9, 217.5) controlPoint2: CGPointMake(137.42, 217.53)];
    [fill30Path addCurveToPoint: CGPointMake(133.98, 218.55) controlPoint1: CGPointMake(135.87, 217.79) controlPoint2: CGPointMake(134.91, 218.08)];
    [fill30Path addCurveToPoint: CGPointMake(129.41, 226.32) controlPoint1: CGPointMake(131.18, 219.95) controlPoint2: CGPointMake(129.41, 222.59)];
    [fill30Path addLineToPoint: CGPointMake(129.41, 238.08)];
    [fill30Path addCurveToPoint: CGPointMake(132.35, 241.02) controlPoint1: CGPointMake(129.41, 239.7) controlPoint2: CGPointMake(130.73, 241.02)];
    [fill30Path addLineToPoint: CGPointMake(167.65, 241.02)];
    [fill30Path addCurveToPoint: CGPointMake(170.59, 238.08) controlPoint1: CGPointMake(169.27, 241.02) controlPoint2: CGPointMake(170.59, 239.7)];
    [fill30Path addLineToPoint: CGPointMake(170.59, 226.32)];
    [fill30Path addCurveToPoint: CGPointMake(170.46, 224.92) controlPoint1: CGPointMake(170.59, 225.98) controlPoint2: CGPointMake(170.55, 225.5)];
    [fill30Path closePath];
    fill30Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill30Path fill];
    
    
    //// Fill-32 Drawing
    UIBezierPath* fill32Path = [UIBezierPath bezierPath];
    [fill32Path moveToPoint: CGPointMake(150, 135.93)];
    [fill32Path addCurveToPoint: CGPointMake(158.82, 144.75) controlPoint1: CGPointMake(154.87, 135.93) controlPoint2: CGPointMake(158.82, 139.88)];
    [fill32Path addCurveToPoint: CGPointMake(150, 153.57) controlPoint1: CGPointMake(158.82, 149.62) controlPoint2: CGPointMake(154.87, 153.57)];
    [fill32Path addCurveToPoint: CGPointMake(141.18, 144.75) controlPoint1: CGPointMake(145.13, 153.57) controlPoint2: CGPointMake(141.18, 149.62)];
    [fill32Path addCurveToPoint: CGPointMake(150, 135.93) controlPoint1: CGPointMake(141.18, 139.88) controlPoint2: CGPointMake(145.13, 135.93)];
    [fill32Path closePath];
    [fill32Path moveToPoint: CGPointMake(150, 159.45)];
    [fill32Path addCurveToPoint: CGPointMake(164.71, 144.75) controlPoint1: CGPointMake(158.12, 159.45) controlPoint2: CGPointMake(164.71, 152.87)];
    [fill32Path addCurveToPoint: CGPointMake(150, 130.05) controlPoint1: CGPointMake(164.71, 136.63) controlPoint2: CGPointMake(158.12, 130.05)];
    [fill32Path addCurveToPoint: CGPointMake(135.29, 144.75) controlPoint1: CGPointMake(141.88, 130.05) controlPoint2: CGPointMake(135.29, 136.63)];
    [fill32Path addCurveToPoint: CGPointMake(150, 159.45) controlPoint1: CGPointMake(135.29, 152.87) controlPoint2: CGPointMake(141.88, 159.45)];
    [fill32Path closePath];
    fill32Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill32Path fill];
    
    
    //// Fill-34 Drawing
    UIBezierPath* fill34Path = [UIBezierPath bezierPath];
    [fill34Path moveToPoint: CGPointMake(164.71, 177.08)];
    [fill34Path addLineToPoint: CGPointMake(135.29, 177.08)];
    [fill34Path addLineToPoint: CGPointMake(135.29, 168.27)];
    [fill34Path addCurveToPoint: CGPointMake(136.61, 165.75) controlPoint1: CGPointMake(135.29, 166.85) controlPoint2: CGPointMake(135.73, 166.19)];
    [fill34Path addCurveToPoint: CGPointMake(137.69, 165.4) controlPoint1: CGPointMake(136.93, 165.59) controlPoint2: CGPointMake(137.31, 165.47)];
    [fill34Path addLineToPoint: CGPointMake(148.68, 170.89)];
    [fill34Path addCurveToPoint: CGPointMake(151.32, 170.89) controlPoint1: CGPointMake(149.51, 171.31) controlPoint2: CGPointMake(150.49, 171.31)];
    [fill34Path addLineToPoint: CGPointMake(162.39, 165.36)];
    [fill34Path addCurveToPoint: CGPointMake(164.28, 166.64) controlPoint1: CGPointMake(163.39, 165.48) controlPoint2: CGPointMake(163.91, 165.91)];
    [fill34Path addCurveToPoint: CGPointMake(164.65, 167.83) controlPoint1: CGPointMake(164.46, 167) controlPoint2: CGPointMake(164.58, 167.41)];
    [fill34Path addCurveToPoint: CGPointMake(164.71, 168.27) controlPoint1: CGPointMake(164.69, 168.07) controlPoint2: CGPointMake(164.71, 168.23)];
    [fill34Path addLineToPoint: CGPointMake(164.71, 177.08)];
    [fill34Path closePath];
    [fill34Path moveToPoint: CGPointMake(170.46, 166.86)];
    [fill34Path addCurveToPoint: CGPointMake(169.54, 164.01) controlPoint1: CGPointMake(170.3, 165.9) controlPoint2: CGPointMake(170.01, 164.94)];
    [fill34Path addCurveToPoint: CGPointMake(161.76, 159.45) controlPoint1: CGPointMake(168.14, 161.21) controlPoint2: CGPointMake(165.49, 159.45)];
    [fill34Path addCurveToPoint: CGPointMake(160.45, 159.76) controlPoint1: CGPointMake(161.31, 159.45) controlPoint2: CGPointMake(160.86, 159.55)];
    [fill34Path addLineToPoint: CGPointMake(150, 164.98)];
    [fill34Path addLineToPoint: CGPointMake(139.55, 159.76)];
    [fill34Path addCurveToPoint: CGPointMake(138.24, 159.45) controlPoint1: CGPointMake(139.14, 159.55) controlPoint2: CGPointMake(138.69, 159.45)];
    [fill34Path addCurveToPoint: CGPointMake(136.83, 159.58) controlPoint1: CGPointMake(137.9, 159.45) controlPoint2: CGPointMake(137.42, 159.48)];
    [fill34Path addCurveToPoint: CGPointMake(133.98, 160.49) controlPoint1: CGPointMake(135.87, 159.74) controlPoint2: CGPointMake(134.91, 160.03)];
    [fill34Path addCurveToPoint: CGPointMake(129.41, 168.27) controlPoint1: CGPointMake(131.18, 161.89) controlPoint2: CGPointMake(129.41, 164.54)];
    [fill34Path addLineToPoint: CGPointMake(129.41, 180.02)];
    [fill34Path addCurveToPoint: CGPointMake(132.35, 182.96) controlPoint1: CGPointMake(129.41, 181.65) controlPoint2: CGPointMake(130.73, 182.96)];
    [fill34Path addLineToPoint: CGPointMake(167.65, 182.96)];
    [fill34Path addCurveToPoint: CGPointMake(170.59, 180.02) controlPoint1: CGPointMake(169.27, 182.96) controlPoint2: CGPointMake(170.59, 181.65)];
    [fill34Path addLineToPoint: CGPointMake(170.59, 168.27)];
    [fill34Path addCurveToPoint: CGPointMake(170.46, 166.86) controlPoint1: CGPointMake(170.59, 167.93) controlPoint2: CGPointMake(170.55, 167.45)];
    [fill34Path closePath];
    fill34Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill34Path fill];
    
    
    //// Fill-36 Drawing
    UIBezierPath* fill36Path = [UIBezierPath bezierPath];
    [fill36Path moveToPoint: CGPointMake(200, 176.35)];
    [fill36Path addCurveToPoint: CGPointMake(208.82, 185.17) controlPoint1: CGPointMake(204.87, 176.35) controlPoint2: CGPointMake(208.82, 180.3)];
    [fill36Path addCurveToPoint: CGPointMake(200, 193.99) controlPoint1: CGPointMake(208.82, 190.04) controlPoint2: CGPointMake(204.87, 193.99)];
    [fill36Path addCurveToPoint: CGPointMake(191.18, 185.17) controlPoint1: CGPointMake(195.13, 193.99) controlPoint2: CGPointMake(191.18, 190.04)];
    [fill36Path addCurveToPoint: CGPointMake(200, 176.35) controlPoint1: CGPointMake(191.18, 180.3) controlPoint2: CGPointMake(195.13, 176.35)];
    [fill36Path closePath];
    [fill36Path moveToPoint: CGPointMake(200, 199.86)];
    [fill36Path addCurveToPoint: CGPointMake(214.71, 185.17) controlPoint1: CGPointMake(208.12, 199.86) controlPoint2: CGPointMake(214.71, 193.28)];
    [fill36Path addCurveToPoint: CGPointMake(200, 170.47) controlPoint1: CGPointMake(214.71, 177.05) controlPoint2: CGPointMake(208.12, 170.47)];
    [fill36Path addCurveToPoint: CGPointMake(185.29, 185.17) controlPoint1: CGPointMake(191.88, 170.47) controlPoint2: CGPointMake(185.29, 177.05)];
    [fill36Path addCurveToPoint: CGPointMake(200, 199.86) controlPoint1: CGPointMake(185.29, 193.28) controlPoint2: CGPointMake(191.88, 199.86)];
    [fill36Path closePath];
    fill36Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill36Path fill];
    
    
    //// Fill-38 Drawing
    UIBezierPath* fill38Path = [UIBezierPath bezierPath];
    [fill38Path moveToPoint: CGPointMake(214.71, 217.5)];
    [fill38Path addLineToPoint: CGPointMake(185.29, 217.5)];
    [fill38Path addLineToPoint: CGPointMake(185.29, 208.68)];
    [fill38Path addCurveToPoint: CGPointMake(186.61, 206.17) controlPoint1: CGPointMake(185.29, 207.26) controlPoint2: CGPointMake(185.74, 206.6)];
    [fill38Path addCurveToPoint: CGPointMake(187.69, 205.82) controlPoint1: CGPointMake(186.93, 206) controlPoint2: CGPointMake(187.31, 205.89)];
    [fill38Path addLineToPoint: CGPointMake(198.68, 211.31)];
    [fill38Path addCurveToPoint: CGPointMake(201.32, 211.31) controlPoint1: CGPointMake(199.51, 211.73) controlPoint2: CGPointMake(200.49, 211.73)];
    [fill38Path addLineToPoint: CGPointMake(212.39, 205.78)];
    [fill38Path addCurveToPoint: CGPointMake(214.28, 207.06) controlPoint1: CGPointMake(213.39, 205.9) controlPoint2: CGPointMake(213.91, 206.32)];
    [fill38Path addCurveToPoint: CGPointMake(214.65, 208.25) controlPoint1: CGPointMake(214.46, 207.42) controlPoint2: CGPointMake(214.58, 207.83)];
    [fill38Path addCurveToPoint: CGPointMake(214.71, 208.68) controlPoint1: CGPointMake(214.69, 208.49) controlPoint2: CGPointMake(214.71, 208.65)];
    [fill38Path addLineToPoint: CGPointMake(214.71, 217.5)];
    [fill38Path closePath];
    [fill38Path moveToPoint: CGPointMake(220.46, 207.28)];
    [fill38Path addCurveToPoint: CGPointMake(219.54, 204.43) controlPoint1: CGPointMake(220.3, 206.32) controlPoint2: CGPointMake(220.01, 205.36)];
    [fill38Path addCurveToPoint: CGPointMake(211.76, 199.86) controlPoint1: CGPointMake(218.14, 201.63) controlPoint2: CGPointMake(215.49, 199.86)];
    [fill38Path addCurveToPoint: CGPointMake(210.45, 200.17) controlPoint1: CGPointMake(211.31, 199.86) controlPoint2: CGPointMake(210.86, 199.97)];
    [fill38Path addLineToPoint: CGPointMake(200, 205.4)];
    [fill38Path addLineToPoint: CGPointMake(189.55, 200.17)];
    [fill38Path addCurveToPoint: CGPointMake(188.24, 199.86) controlPoint1: CGPointMake(189.14, 199.97) controlPoint2: CGPointMake(188.69, 199.86)];
    [fill38Path addCurveToPoint: CGPointMake(186.83, 200) controlPoint1: CGPointMake(187.9, 199.86) controlPoint2: CGPointMake(187.42, 199.9)];
    [fill38Path addCurveToPoint: CGPointMake(183.98, 200.91) controlPoint1: CGPointMake(185.87, 200.16) controlPoint2: CGPointMake(184.91, 200.45)];
    [fill38Path addCurveToPoint: CGPointMake(179.41, 208.68) controlPoint1: CGPointMake(181.18, 202.31) controlPoint2: CGPointMake(179.41, 204.96)];
    [fill38Path addLineToPoint: CGPointMake(179.41, 220.44)];
    [fill38Path addCurveToPoint: CGPointMake(182.35, 223.38) controlPoint1: CGPointMake(179.41, 222.06) controlPoint2: CGPointMake(180.73, 223.38)];
    [fill38Path addLineToPoint: CGPointMake(217.65, 223.38)];
    [fill38Path addCurveToPoint: CGPointMake(220.59, 220.44) controlPoint1: CGPointMake(219.27, 223.38) controlPoint2: CGPointMake(220.59, 222.06)];
    [fill38Path addLineToPoint: CGPointMake(220.59, 208.68)];
    [fill38Path addCurveToPoint: CGPointMake(220.46, 207.28) controlPoint1: CGPointMake(220.59, 208.35) controlPoint2: CGPointMake(220.55, 207.87)];
    [fill38Path closePath];
    fill38Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill38Path fill];
    
    
    //// Fill-40 Drawing
    UIBezierPath* fill40Path = [UIBezierPath bezierPath];
    [fill40Path moveToPoint: CGPointMake(100, 177.08)];
    [fill40Path addCurveToPoint: CGPointMake(108.82, 185.9) controlPoint1: CGPointMake(104.87, 177.08) controlPoint2: CGPointMake(108.82, 181.03)];
    [fill40Path addCurveToPoint: CGPointMake(100, 194.72) controlPoint1: CGPointMake(108.82, 190.77) controlPoint2: CGPointMake(104.87, 194.72)];
    [fill40Path addCurveToPoint: CGPointMake(91.18, 185.9) controlPoint1: CGPointMake(95.13, 194.72) controlPoint2: CGPointMake(91.18, 190.77)];
    [fill40Path addCurveToPoint: CGPointMake(100, 177.08) controlPoint1: CGPointMake(91.18, 181.03) controlPoint2: CGPointMake(95.13, 177.08)];
    [fill40Path closePath];
    [fill40Path moveToPoint: CGPointMake(100, 200.6)];
    [fill40Path addCurveToPoint: CGPointMake(114.71, 185.9) controlPoint1: CGPointMake(108.12, 200.6) controlPoint2: CGPointMake(114.71, 194.02)];
    [fill40Path addCurveToPoint: CGPointMake(100, 171.2) controlPoint1: CGPointMake(114.71, 177.79) controlPoint2: CGPointMake(108.12, 171.2)];
    [fill40Path addCurveToPoint: CGPointMake(85.29, 185.9) controlPoint1: CGPointMake(91.88, 171.2) controlPoint2: CGPointMake(85.29, 177.79)];
    [fill40Path addCurveToPoint: CGPointMake(100, 200.6) controlPoint1: CGPointMake(85.29, 194.02) controlPoint2: CGPointMake(91.88, 200.6)];
    [fill40Path closePath];
    fill40Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill40Path fill];
    
    
    //// Fill-42 Drawing
    UIBezierPath* fill42Path = [UIBezierPath bezierPath];
    [fill42Path moveToPoint: CGPointMake(114.71, 218.24)];
    [fill42Path addLineToPoint: CGPointMake(85.29, 218.24)];
    [fill42Path addLineToPoint: CGPointMake(85.29, 209.42)];
    [fill42Path addCurveToPoint: CGPointMake(86.61, 206.9) controlPoint1: CGPointMake(85.29, 208) controlPoint2: CGPointMake(85.73, 207.34)];
    [fill42Path addCurveToPoint: CGPointMake(87.69, 206.55) controlPoint1: CGPointMake(86.93, 206.74) controlPoint2: CGPointMake(87.31, 206.62)];
    [fill42Path addLineToPoint: CGPointMake(98.68, 212.05)];
    [fill42Path addCurveToPoint: CGPointMake(101.32, 212.05) controlPoint1: CGPointMake(99.51, 212.46) controlPoint2: CGPointMake(100.49, 212.46)];
    [fill42Path addLineToPoint: CGPointMake(112.39, 206.51)];
    [fill42Path addCurveToPoint: CGPointMake(114.28, 207.79) controlPoint1: CGPointMake(113.39, 206.63) controlPoint2: CGPointMake(113.91, 207.06)];
    [fill42Path addCurveToPoint: CGPointMake(114.65, 208.98) controlPoint1: CGPointMake(114.46, 208.15) controlPoint2: CGPointMake(114.58, 208.56)];
    [fill42Path addCurveToPoint: CGPointMake(114.71, 209.42) controlPoint1: CGPointMake(114.69, 209.22) controlPoint2: CGPointMake(114.71, 209.39)];
    [fill42Path addLineToPoint: CGPointMake(114.71, 218.24)];
    [fill42Path closePath];
    [fill42Path moveToPoint: CGPointMake(120.46, 208.02)];
    [fill42Path addCurveToPoint: CGPointMake(119.54, 205.16) controlPoint1: CGPointMake(120.3, 207.06) controlPoint2: CGPointMake(120.01, 206.09)];
    [fill42Path addCurveToPoint: CGPointMake(111.76, 200.6) controlPoint1: CGPointMake(118.14, 202.36) controlPoint2: CGPointMake(115.49, 200.6)];
    [fill42Path addCurveToPoint: CGPointMake(110.45, 200.91) controlPoint1: CGPointMake(111.31, 200.6) controlPoint2: CGPointMake(110.86, 200.71)];
    [fill42Path addLineToPoint: CGPointMake(100, 206.13)];
    [fill42Path addLineToPoint: CGPointMake(89.55, 200.91)];
    [fill42Path addCurveToPoint: CGPointMake(88.24, 200.6) controlPoint1: CGPointMake(89.14, 200.71) controlPoint2: CGPointMake(88.69, 200.6)];
    [fill42Path addCurveToPoint: CGPointMake(86.83, 200.73) controlPoint1: CGPointMake(87.9, 200.6) controlPoint2: CGPointMake(87.42, 200.63)];
    [fill42Path addCurveToPoint: CGPointMake(83.98, 201.64) controlPoint1: CGPointMake(85.87, 200.89) controlPoint2: CGPointMake(84.91, 201.18)];
    [fill42Path addCurveToPoint: CGPointMake(79.41, 209.42) controlPoint1: CGPointMake(81.18, 203.04) controlPoint2: CGPointMake(79.41, 205.69)];
    [fill42Path addLineToPoint: CGPointMake(79.41, 221.17)];
    [fill42Path addCurveToPoint: CGPointMake(82.35, 224.11) controlPoint1: CGPointMake(79.41, 222.8) controlPoint2: CGPointMake(80.73, 224.11)];
    [fill42Path addLineToPoint: CGPointMake(117.65, 224.11)];
    [fill42Path addCurveToPoint: CGPointMake(120.59, 221.17) controlPoint1: CGPointMake(119.27, 224.11) controlPoint2: CGPointMake(120.59, 222.8)];
    [fill42Path addLineToPoint: CGPointMake(120.59, 209.42)];
    [fill42Path addCurveToPoint: CGPointMake(120.46, 208.02) controlPoint1: CGPointMake(120.59, 209.08) controlPoint2: CGPointMake(120.55, 208.6)];
    [fill42Path closePath];
    fill42Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill42Path fill];
    
    
    //// Fill-44 Drawing
    UIBezierPath* fill44Path = [UIBezierPath bezierPath];
    [fill44Path moveToPoint: CGPointMake(70.59, 323.32)];
    [fill44Path addLineToPoint: CGPointMake(66.91, 323.32)];
    [fill44Path addCurveToPoint: CGPointMake(66.05, 322.71) controlPoint1: CGPointMake(66.67, 323.32) controlPoint2: CGPointMake(66.65, 323.31)];
    [fill44Path addCurveToPoint: CGPointMake(61.03, 320.38) controlPoint1: CGPointMake(64.45, 321.11) controlPoint2: CGPointMake(63.23, 320.38)];
    [fill44Path addCurveToPoint: CGPointMake(56.01, 322.71) controlPoint1: CGPointMake(58.82, 320.38) controlPoint2: CGPointMake(57.61, 321.11)];
    [fill44Path addCurveToPoint: CGPointMake(55.15, 323.32) controlPoint1: CGPointMake(55.41, 323.31) controlPoint2: CGPointMake(55.39, 323.32)];
    [fill44Path addCurveToPoint: CGPointMake(54.29, 322.71) controlPoint1: CGPointMake(54.9, 323.32) controlPoint2: CGPointMake(54.89, 323.31)];
    [fill44Path addCurveToPoint: CGPointMake(49.26, 320.38) controlPoint1: CGPointMake(52.68, 321.11) controlPoint2: CGPointMake(51.47, 320.38)];
    [fill44Path addCurveToPoint: CGPointMake(44.24, 322.71) controlPoint1: CGPointMake(47.06, 320.38) controlPoint2: CGPointMake(45.85, 321.11)];
    [fill44Path addCurveToPoint: CGPointMake(43.38, 323.32) controlPoint1: CGPointMake(43.64, 323.31) controlPoint2: CGPointMake(43.63, 323.32)];
    [fill44Path addCurveToPoint: CGPointMake(42.52, 322.71) controlPoint1: CGPointMake(43.14, 323.32) controlPoint2: CGPointMake(43.12, 323.31)];
    [fill44Path addCurveToPoint: CGPointMake(37.5, 320.38) controlPoint1: CGPointMake(40.92, 321.11) controlPoint2: CGPointMake(39.7, 320.38)];
    [fill44Path addCurveToPoint: CGPointMake(34.26, 318.41) controlPoint1: CGPointMake(37.02, 320.38) controlPoint2: CGPointMake(35.78, 319.71)];
    [fill44Path addCurveToPoint: CGPointMake(29.57, 313.48) controlPoint1: CGPointMake(32.74, 317.13) controlPoint2: CGPointMake(31.08, 315.36)];
    [fill44Path addCurveToPoint: CGPointMake(5.88, 238.08) controlPoint1: CGPointMake(14.35, 291.5) controlPoint2: CGPointMake(5.88, 265.77)];
    [fill44Path addLineToPoint: CGPointMake(5.88, 169.11)];
    [fill44Path addCurveToPoint: CGPointMake(5.88, 169.06) controlPoint1: CGPointMake(5.88, 169.09) controlPoint2: CGPointMake(5.88, 169.07)];
    [fill44Path addCurveToPoint: CGPointMake(5.88, 169) controlPoint1: CGPointMake(5.88, 169.04) controlPoint2: CGPointMake(5.88, 169.02)];
    [fill44Path addCurveToPoint: CGPointMake(20.61, 155.77) controlPoint1: CGPointMake(5.88, 160) controlPoint2: CGPointMake(10.4, 155.86)];
    [fill44Path addLineToPoint: CGPointMake(44.85, 155.77)];
    [fill44Path addCurveToPoint: CGPointMake(46.93, 154.91) controlPoint1: CGPointMake(45.63, 155.77) controlPoint2: CGPointMake(46.38, 155.46)];
    [fill44Path addLineToPoint: CGPointMake(53.68, 148.17)];
    [fill44Path addLineToPoint: CGPointMake(53.68, 151.36)];
    [fill44Path addCurveToPoint: CGPointMake(56.62, 154.3) controlPoint1: CGPointMake(53.68, 152.99) controlPoint2: CGPointMake(54.99, 154.3)];
    [fill44Path addCurveToPoint: CGPointMake(59.56, 151.36) controlPoint1: CGPointMake(58.24, 154.3) controlPoint2: CGPointMake(59.56, 152.99)];
    [fill44Path addLineToPoint: CGPointMake(59.56, 141.08)];
    [fill44Path addCurveToPoint: CGPointMake(59.5, 140.51) controlPoint1: CGPointMake(59.56, 140.88) controlPoint2: CGPointMake(59.54, 140.69)];
    [fill44Path addCurveToPoint: CGPointMake(59.48, 140.43) controlPoint1: CGPointMake(59.5, 140.49) controlPoint2: CGPointMake(59.49, 140.46)];
    [fill44Path addCurveToPoint: CGPointMake(59.33, 139.94) controlPoint1: CGPointMake(59.45, 140.26) controlPoint2: CGPointMake(59.39, 140.1)];
    [fill44Path addCurveToPoint: CGPointMake(59.32, 139.93) controlPoint1: CGPointMake(59.33, 139.94) controlPoint2: CGPointMake(59.33, 139.93)];
    [fill44Path addCurveToPoint: CGPointMake(58.31, 138.68) controlPoint1: CGPointMake(59.11, 139.41) controlPoint2: CGPointMake(58.75, 138.98)];
    [fill44Path addCurveToPoint: CGPointMake(58.21, 138.61) controlPoint1: CGPointMake(58.28, 138.66) controlPoint2: CGPointMake(58.25, 138.63)];
    [fill44Path addCurveToPoint: CGPointMake(57.81, 138.4) controlPoint1: CGPointMake(58.09, 138.53) controlPoint2: CGPointMake(57.95, 138.46)];
    [fill44Path addCurveToPoint: CGPointMake(57.75, 138.36) controlPoint1: CGPointMake(57.79, 138.39) controlPoint2: CGPointMake(57.77, 138.37)];
    [fill44Path addCurveToPoint: CGPointMake(57.26, 138.21) controlPoint1: CGPointMake(57.59, 138.3) controlPoint2: CGPointMake(57.42, 138.25)];
    [fill44Path addCurveToPoint: CGPointMake(57.15, 138.19) controlPoint1: CGPointMake(57.22, 138.2) controlPoint2: CGPointMake(57.18, 138.2)];
    [fill44Path addCurveToPoint: CGPointMake(56.47, 138.14) controlPoint1: CGPointMake(56.93, 138.15) controlPoint2: CGPointMake(56.7, 138.13)];
    [fill44Path addLineToPoint: CGPointMake(46.32, 138.14)];
    [fill44Path addCurveToPoint: CGPointMake(43.38, 141.08) controlPoint1: CGPointMake(44.7, 138.14) controlPoint2: CGPointMake(43.38, 139.45)];
    [fill44Path addCurveToPoint: CGPointMake(46.32, 144.02) controlPoint1: CGPointMake(43.38, 142.7) controlPoint2: CGPointMake(44.7, 144.02)];
    [fill44Path addLineToPoint: CGPointMake(49.52, 144.02)];
    [fill44Path addLineToPoint: CGPointMake(43.63, 149.89)];
    [fill44Path addLineToPoint: CGPointMake(20.59, 149.89)];
    [fill44Path addCurveToPoint: CGPointMake(-0, 169) controlPoint1: CGPointMake(7.24, 150) controlPoint2: CGPointMake(-0, 156.64)];
    [fill44Path addCurveToPoint: CGPointMake(0.01, 169.06) controlPoint1: CGPointMake(-0, 169.02) controlPoint2: CGPointMake(0.01, 169.04)];
    [fill44Path addCurveToPoint: CGPointMake(-0, 169.11) controlPoint1: CGPointMake(0.01, 169.07) controlPoint2: CGPointMake(-0, 169.09)];
    [fill44Path addLineToPoint: CGPointMake(-0, 238.08)];
    [fill44Path addCurveToPoint: CGPointMake(24.79, 316.91) controlPoint1: CGPointMake(-0, 267.04) controlPoint2: CGPointMake(8.87, 293.95)];
    [fill44Path addCurveToPoint: CGPointMake(24.85, 316.99) controlPoint1: CGPointMake(24.81, 316.94) controlPoint2: CGPointMake(24.83, 316.96)];
    [fill44Path addCurveToPoint: CGPointMake(24.91, 317.07) controlPoint1: CGPointMake(24.87, 317.01) controlPoint2: CGPointMake(24.89, 317.04)];
    [fill44Path addCurveToPoint: CGPointMake(37.5, 326.26) controlPoint1: CGPointMake(29.27, 322.51) controlPoint2: CGPointMake(33.67, 326.26)];
    [fill44Path addCurveToPoint: CGPointMake(38.36, 326.87) controlPoint1: CGPointMake(37.75, 326.26) controlPoint2: CGPointMake(37.76, 326.27)];
    [fill44Path addCurveToPoint: CGPointMake(43.38, 329.2) controlPoint1: CGPointMake(39.97, 328.47) controlPoint2: CGPointMake(41.18, 329.2)];
    [fill44Path addCurveToPoint: CGPointMake(48.4, 326.87) controlPoint1: CGPointMake(45.59, 329.2) controlPoint2: CGPointMake(46.8, 328.47)];
    [fill44Path addCurveToPoint: CGPointMake(49.26, 326.26) controlPoint1: CGPointMake(49, 326.27) controlPoint2: CGPointMake(49.02, 326.26)];
    [fill44Path addCurveToPoint: CGPointMake(50.13, 326.87) controlPoint1: CGPointMake(49.51, 326.26) controlPoint2: CGPointMake(49.53, 326.27)];
    [fill44Path addCurveToPoint: CGPointMake(55.15, 329.2) controlPoint1: CGPointMake(51.73, 328.47) controlPoint2: CGPointMake(52.94, 329.2)];
    [fill44Path addCurveToPoint: CGPointMake(60.17, 326.87) controlPoint1: CGPointMake(57.35, 329.2) controlPoint2: CGPointMake(58.56, 328.47)];
    [fill44Path addCurveToPoint: CGPointMake(61.03, 326.26) controlPoint1: CGPointMake(60.77, 326.27) controlPoint2: CGPointMake(60.78, 326.26)];
    [fill44Path addCurveToPoint: CGPointMake(61.89, 326.87) controlPoint1: CGPointMake(61.28, 326.26) controlPoint2: CGPointMake(61.29, 326.27)];
    [fill44Path addCurveToPoint: CGPointMake(66.91, 329.2) controlPoint1: CGPointMake(63.5, 328.47) controlPoint2: CGPointMake(64.71, 329.2)];
    [fill44Path addLineToPoint: CGPointMake(70.59, 329.2)];
    [fill44Path addCurveToPoint: CGPointMake(73.53, 326.26) controlPoint1: CGPointMake(72.21, 329.2) controlPoint2: CGPointMake(73.53, 327.88)];
    [fill44Path addCurveToPoint: CGPointMake(70.59, 323.32) controlPoint1: CGPointMake(73.53, 324.63) controlPoint2: CGPointMake(72.21, 323.32)];
    [fill44Path closePath];
    fill44Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill44Path fill];
    
    
    //// Fill-47 Drawing
    UIBezierPath* fill47Path = [UIBezierPath bezierPath];
    [fill47Path moveToPoint: CGPointMake(102.94, 307.93)];
    [fill47Path addLineToPoint: CGPointMake(100.35, 302.74)];
    [fill47Path addLineToPoint: CGPointMake(105.54, 302.74)];
    [fill47Path addLineToPoint: CGPointMake(102.94, 307.93)];
    [fill47Path closePath];
    [fill47Path moveToPoint: CGPointMake(98.53, 259.39)];
    [fill47Path addLineToPoint: CGPointMake(107.35, 259.39)];
    [fill47Path addLineToPoint: CGPointMake(107.35, 255.71)];
    [fill47Path addLineToPoint: CGPointMake(98.53, 255.71)];
    [fill47Path addLineToPoint: CGPointMake(98.53, 259.39)];
    [fill47Path closePath];
    [fill47Path moveToPoint: CGPointMake(98.53, 296.86)];
    [fill47Path addLineToPoint: CGPointMake(107.35, 296.86)];
    [fill47Path addLineToPoint: CGPointMake(107.35, 265.27)];
    [fill47Path addLineToPoint: CGPointMake(98.53, 265.27)];
    [fill47Path addLineToPoint: CGPointMake(98.53, 296.86)];
    [fill47Path closePath];
    [fill47Path moveToPoint: CGPointMake(113.23, 299.83)];
    [fill47Path addCurveToPoint: CGPointMake(113.24, 299.8) controlPoint1: CGPointMake(113.23, 299.82) controlPoint2: CGPointMake(113.24, 299.81)];
    [fill47Path addLineToPoint: CGPointMake(113.24, 252.77)];
    [fill47Path addCurveToPoint: CGPointMake(110.29, 249.83) controlPoint1: CGPointMake(113.24, 251.15) controlPoint2: CGPointMake(111.92, 249.83)];
    [fill47Path addLineToPoint: CGPointMake(95.59, 249.83)];
    [fill47Path addCurveToPoint: CGPointMake(92.65, 252.77) controlPoint1: CGPointMake(93.96, 249.83) controlPoint2: CGPointMake(92.65, 251.15)];
    [fill47Path addLineToPoint: CGPointMake(92.65, 299.8)];
    [fill47Path addCurveToPoint: CGPointMake(92.65, 299.83) controlPoint1: CGPointMake(92.65, 299.81) controlPoint2: CGPointMake(92.65, 299.82)];
    [fill47Path addCurveToPoint: CGPointMake(92.86, 300.88) controlPoint1: CGPointMake(92.65, 300.17) controlPoint2: CGPointMake(92.72, 300.53)];
    [fill47Path addCurveToPoint: CGPointMake(92.91, 301.01) controlPoint1: CGPointMake(92.87, 300.92) controlPoint2: CGPointMake(92.89, 300.97)];
    [fill47Path addCurveToPoint: CGPointMake(92.96, 301.12) controlPoint1: CGPointMake(92.93, 301.05) controlPoint2: CGPointMake(92.94, 301.08)];
    [fill47Path addLineToPoint: CGPointMake(100.31, 315.81)];
    [fill47Path addCurveToPoint: CGPointMake(105.57, 315.81) controlPoint1: CGPointMake(101.39, 317.98) controlPoint2: CGPointMake(104.49, 317.98)];
    [fill47Path addLineToPoint: CGPointMake(112.92, 301.12)];
    [fill47Path addCurveToPoint: CGPointMake(112.97, 301.01) controlPoint1: CGPointMake(112.94, 301.08) controlPoint2: CGPointMake(112.95, 301.05)];
    [fill47Path addCurveToPoint: CGPointMake(113.03, 300.88) controlPoint1: CGPointMake(112.99, 300.97) controlPoint2: CGPointMake(113.01, 300.92)];
    [fill47Path addCurveToPoint: CGPointMake(113.23, 299.83) controlPoint1: CGPointMake(113.16, 300.53) controlPoint2: CGPointMake(113.23, 300.17)];
    [fill47Path closePath];
    fill47Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill47Path fill];
    
    
    //// Fill-49 Drawing
    UIBezierPath* fill49Path = [UIBezierPath bezierPath];
    [fill49Path moveToPoint: CGPointMake(114.71, 320.38)];
    [fill49Path addCurveToPoint: CGPointMake(111.76, 317.44) controlPoint1: CGPointMake(113.08, 320.38) controlPoint2: CGPointMake(111.76, 319.06)];
    [fill49Path addCurveToPoint: CGPointMake(114.71, 314.5) controlPoint1: CGPointMake(111.76, 315.82) controlPoint2: CGPointMake(113.08, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(118.51, 312.42) controlPoint1: CGPointMake(116.18, 314.5) controlPoint2: CGPointMake(116.81, 314.12)];
    [fill49Path addCurveToPoint: CGPointMake(126.47, 308.62) controlPoint1: CGPointMake(121.22, 309.72) controlPoint2: CGPointMake(123.04, 308.62)];
    [fill49Path addCurveToPoint: CGPointMake(134.43, 312.42) controlPoint1: CGPointMake(129.9, 308.62) controlPoint2: CGPointMake(131.72, 309.72)];
    [fill49Path addCurveToPoint: CGPointMake(138.24, 314.5) controlPoint1: CGPointMake(136.14, 314.12) controlPoint2: CGPointMake(136.76, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(142.04, 312.42) controlPoint1: CGPointMake(139.71, 314.5) controlPoint2: CGPointMake(140.33, 314.12)];
    [fill49Path addCurveToPoint: CGPointMake(150, 308.62) controlPoint1: CGPointMake(144.75, 309.72) controlPoint2: CGPointMake(146.57, 308.62)];
    [fill49Path addCurveToPoint: CGPointMake(157.96, 312.42) controlPoint1: CGPointMake(153.43, 308.62) controlPoint2: CGPointMake(155.25, 309.72)];
    [fill49Path addCurveToPoint: CGPointMake(161.76, 314.5) controlPoint1: CGPointMake(159.67, 314.12) controlPoint2: CGPointMake(160.29, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(165.57, 312.42) controlPoint1: CGPointMake(163.24, 314.5) controlPoint2: CGPointMake(163.86, 314.12)];
    [fill49Path addCurveToPoint: CGPointMake(173.53, 308.62) controlPoint1: CGPointMake(168.27, 309.72) controlPoint2: CGPointMake(170.1, 308.62)];
    [fill49Path addCurveToPoint: CGPointMake(181.49, 312.42) controlPoint1: CGPointMake(176.96, 308.62) controlPoint2: CGPointMake(178.78, 309.72)];
    [fill49Path addCurveToPoint: CGPointMake(185.29, 314.5) controlPoint1: CGPointMake(183.2, 314.12) controlPoint2: CGPointMake(183.82, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(188.24, 317.44) controlPoint1: CGPointMake(186.92, 314.5) controlPoint2: CGPointMake(188.24, 315.82)];
    [fill49Path addCurveToPoint: CGPointMake(185.29, 320.38) controlPoint1: CGPointMake(188.24, 319.06) controlPoint2: CGPointMake(186.92, 320.38)];
    [fill49Path addCurveToPoint: CGPointMake(177.33, 316.58) controlPoint1: CGPointMake(181.86, 320.38) controlPoint2: CGPointMake(180.04, 319.29)];
    [fill49Path addCurveToPoint: CGPointMake(173.53, 314.5) controlPoint1: CGPointMake(175.63, 314.88) controlPoint2: CGPointMake(175, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(169.73, 316.58) controlPoint1: CGPointMake(172.06, 314.5) controlPoint2: CGPointMake(171.43, 314.88)];
    [fill49Path addCurveToPoint: CGPointMake(161.76, 320.38) controlPoint1: CGPointMake(167.02, 319.29) controlPoint2: CGPointMake(165.19, 320.38)];
    [fill49Path addCurveToPoint: CGPointMake(153.8, 316.58) controlPoint1: CGPointMake(158.34, 320.38) controlPoint2: CGPointMake(156.51, 319.29)];
    [fill49Path addCurveToPoint: CGPointMake(150, 314.5) controlPoint1: CGPointMake(152.1, 314.88) controlPoint2: CGPointMake(151.47, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(146.2, 316.58) controlPoint1: CGPointMake(148.53, 314.5) controlPoint2: CGPointMake(147.9, 314.88)];
    [fill49Path addCurveToPoint: CGPointMake(138.24, 320.38) controlPoint1: CGPointMake(143.49, 319.29) controlPoint2: CGPointMake(141.67, 320.38)];
    [fill49Path addCurveToPoint: CGPointMake(130.27, 316.58) controlPoint1: CGPointMake(134.81, 320.38) controlPoint2: CGPointMake(132.98, 319.29)];
    [fill49Path addCurveToPoint: CGPointMake(126.47, 314.5) controlPoint1: CGPointMake(128.57, 314.88) controlPoint2: CGPointMake(127.94, 314.5)];
    [fill49Path addCurveToPoint: CGPointMake(122.67, 316.58) controlPoint1: CGPointMake(125, 314.5) controlPoint2: CGPointMake(124.37, 314.88)];
    [fill49Path addCurveToPoint: CGPointMake(114.71, 320.38) controlPoint1: CGPointMake(119.96, 319.29) controlPoint2: CGPointMake(118.14, 320.38)];
    [fill49Path closePath];
    fill49Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill49Path fill];
    
    
    //// Fill-51 Drawing
    UIBezierPath* fill51Path = [UIBezierPath bezierPath];
    [fill51Path moveToPoint: CGPointMake(144.12, 83.04)];
    [fill51Path addLineToPoint: CGPointMake(155.88, 83.04)];
    [fill51Path addLineToPoint: CGPointMake(155.88, 77.16)];
    [fill51Path addLineToPoint: CGPointMake(144.12, 77.16)];
    [fill51Path addLineToPoint: CGPointMake(144.12, 83.04)];
    [fill51Path closePath];
    [fill51Path moveToPoint: CGPointMake(135.29, 56.58)];
    [fill51Path addCurveToPoint: CGPointMake(150, 41.89) controlPoint1: CGPointMake(135.29, 48.47) controlPoint2: CGPointMake(141.88, 41.89)];
    [fill51Path addCurveToPoint: CGPointMake(164.71, 56.58) controlPoint1: CGPointMake(158.12, 41.89) controlPoint2: CGPointMake(164.71, 48.47)];
    [fill51Path addCurveToPoint: CGPointMake(152.94, 70.99) controlPoint1: CGPointMake(164.71, 63.69) controlPoint2: CGPointMake(159.65, 69.62)];
    [fill51Path addLineToPoint: CGPointMake(152.94, 62.46)];
    [fill51Path addCurveToPoint: CGPointMake(152.08, 60.38) controlPoint1: CGPointMake(152.94, 61.68) controlPoint2: CGPointMake(152.63, 60.93)];
    [fill51Path addLineToPoint: CGPointMake(151.22, 59.52)];
    [fill51Path addLineToPoint: CGPointMake(155.88, 59.52)];
    [fill51Path addCurveToPoint: CGPointMake(158.82, 56.58) controlPoint1: CGPointMake(157.51, 59.52) controlPoint2: CGPointMake(158.82, 58.21)];
    [fill51Path addCurveToPoint: CGPointMake(155.88, 53.64) controlPoint1: CGPointMake(158.82, 54.96) controlPoint2: CGPointMake(157.51, 53.64)];
    [fill51Path addLineToPoint: CGPointMake(144.12, 53.64)];
    [fill51Path addCurveToPoint: CGPointMake(142.04, 58.66) controlPoint1: CGPointMake(141.5, 53.64) controlPoint2: CGPointMake(140.19, 56.81)];
    [fill51Path addLineToPoint: CGPointMake(147.06, 63.68)];
    [fill51Path addLineToPoint: CGPointMake(147.06, 70.99)];
    [fill51Path addCurveToPoint: CGPointMake(135.29, 56.58) controlPoint1: CGPointMake(140.35, 69.62) controlPoint2: CGPointMake(135.29, 63.69)];
    [fill51Path closePath];
    [fill51Path moveToPoint: CGPointMake(170.59, 56.58)];
    [fill51Path addCurveToPoint: CGPointMake(150, 36.01) controlPoint1: CGPointMake(170.59, 45.22) controlPoint2: CGPointMake(161.37, 36.01)];
    [fill51Path addCurveToPoint: CGPointMake(129.41, 56.58) controlPoint1: CGPointMake(138.63, 36.01) controlPoint2: CGPointMake(129.41, 45.22)];
    [fill51Path addCurveToPoint: CGPointMake(138.24, 73.46) controlPoint1: CGPointMake(129.41, 63.57) controlPoint2: CGPointMake(132.9, 69.75)];
    [fill51Path addLineToPoint: CGPointMake(138.24, 85.98)];
    [fill51Path addCurveToPoint: CGPointMake(141.18, 88.92) controlPoint1: CGPointMake(138.24, 87.6) controlPoint2: CGPointMake(139.55, 88.92)];
    [fill51Path addLineToPoint: CGPointMake(158.82, 88.92)];
    [fill51Path addCurveToPoint: CGPointMake(161.76, 85.98) controlPoint1: CGPointMake(160.45, 88.92) controlPoint2: CGPointMake(161.76, 87.6)];
    [fill51Path addLineToPoint: CGPointMake(161.76, 73.46)];
    [fill51Path addCurveToPoint: CGPointMake(170.59, 56.58) controlPoint1: CGPointMake(167.1, 69.75) controlPoint2: CGPointMake(170.59, 63.57)];
    [fill51Path closePath];
    fill51Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill51Path fill];
    
    
    //// Fill-53 Drawing
    UIBezierPath* fill53Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(147, 21, 6, 12) cornerRadius: 3];
    [color setFill];
    [fill53Path fill];
    
    
    //// Fill-54 Drawing
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 171.32, 37.11);
    CGContextRotateCTM(context, 45 * M_PI/180);
    
    UIBezierPath* fill54Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(-2.94, -6.07, 5.88, 12.13) cornerRadius: 2.94];
    [color setFill];
    [fill54Path fill];
    
    CGContextRestoreGState(context);
    
    
    //// Fill-55 Drawing
    UIBezierPath* fill55Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(174, 54, 11, 6) cornerRadius: 3];
    [color setFill];
    [fill55Path fill];
    
    
    //// Fill-56 Drawing
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 128.68, 36.86);
    CGContextRotateCTM(context, 45 * M_PI/180);
    
    UIBezierPath* fill56Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(-6.07, -2.94, 12.13, 5.88) cornerRadius: 2.94];
    [color setFill];
    [fill56Path fill];
    
    CGContextRestoreGState(context);
    
    
    //// Fill-57 Drawing
    UIBezierPath* fill57Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(115, 54, 11, 6) cornerRadius: 3];
    [color setFill];
    [fill57Path fill];
    
    
    //// Fill-58 Drawing
    UIBezierPath* fill58Path = [UIBezierPath bezierPath];
    [fill58Path moveToPoint: CGPointMake(208.82, 76.42)];
    [fill58Path addLineToPoint: CGPointMake(220.29, 76.42)];
    [fill58Path addCurveToPoint: CGPointMake(208.82, 64.96) controlPoint1: CGPointMake(219.12, 70.67) controlPoint2: CGPointMake(214.59, 66.13)];
    [fill58Path addLineToPoint: CGPointMake(208.82, 76.42)];
    [fill58Path closePath];
    [fill58Path moveToPoint: CGPointMake(205.88, 82.3)];
    [fill58Path addCurveToPoint: CGPointMake(202.94, 79.36) controlPoint1: CGPointMake(204.26, 82.3) controlPoint2: CGPointMake(202.94, 80.99)];
    [fill58Path addLineToPoint: CGPointMake(202.94, 61.73)];
    [fill58Path addCurveToPoint: CGPointMake(205.88, 58.79) controlPoint1: CGPointMake(202.94, 60.1) controlPoint2: CGPointMake(204.26, 58.79)];
    [fill58Path addCurveToPoint: CGPointMake(226.47, 79.36) controlPoint1: CGPointMake(217.25, 58.79) controlPoint2: CGPointMake(226.47, 68)];
    [fill58Path addCurveToPoint: CGPointMake(223.53, 82.3) controlPoint1: CGPointMake(226.47, 80.99) controlPoint2: CGPointMake(225.15, 82.3)];
    [fill58Path addLineToPoint: CGPointMake(205.88, 82.3)];
    [fill58Path closePath];
    fill58Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill58Path fill];
    
    
    //// Fill-59 Drawing
    UIBezierPath* fill59Path = [UIBezierPath bezierPath];
    [fill59Path moveToPoint: CGPointMake(196.33, 91.86)];
    [fill59Path addCurveToPoint: CGPointMake(193.39, 88.92) controlPoint1: CGPointMake(194.7, 91.86) controlPoint2: CGPointMake(193.39, 90.54)];
    [fill59Path addLineToPoint: CGPointMake(193.39, 71.52)];
    [fill59Path addCurveToPoint: CGPointMake(178.68, 88.92) controlPoint1: CGPointMake(185.04, 72.92) controlPoint2: CGPointMake(178.68, 80.18)];
    [fill59Path addCurveToPoint: CGPointMake(196.33, 106.56) controlPoint1: CGPointMake(178.68, 98.66) controlPoint2: CGPointMake(186.58, 106.56)];
    [fill59Path addCurveToPoint: CGPointMake(213.69, 91.86) controlPoint1: CGPointMake(204.95, 106.56) controlPoint2: CGPointMake(212.2, 100.17)];
    [fill59Path addLineToPoint: CGPointMake(196.33, 91.86)];
    [fill59Path closePath];
    [fill59Path moveToPoint: CGPointMake(199.27, 85.98)];
    [fill59Path addLineToPoint: CGPointMake(216.91, 85.98)];
    [fill59Path addCurveToPoint: CGPointMake(219.85, 88.95) controlPoint1: CGPointMake(218.55, 85.98) controlPoint2: CGPointMake(219.87, 87.32)];
    [fill59Path addCurveToPoint: CGPointMake(196.33, 112.44) controlPoint1: CGPointMake(219.72, 101.87) controlPoint2: CGPointMake(209.19, 112.44)];
    [fill59Path addCurveToPoint: CGPointMake(172.79, 88.92) controlPoint1: CGPointMake(183.33, 112.44) controlPoint2: CGPointMake(172.79, 101.91)];
    [fill59Path addCurveToPoint: CGPointMake(196.33, 65.4) controlPoint1: CGPointMake(172.79, 75.93) controlPoint2: CGPointMake(183.33, 65.4)];
    [fill59Path addCurveToPoint: CGPointMake(199.27, 68.34) controlPoint1: CGPointMake(197.95, 65.4) controlPoint2: CGPointMake(199.27, 66.72)];
    [fill59Path addLineToPoint: CGPointMake(199.27, 85.98)];
    [fill59Path closePath];
    fill59Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill59Path fill];
    
    
    //// Fill-60 Drawing
    UIBezierPath* fill60Path = [UIBezierPath bezierPath];
    [fill60Path moveToPoint: CGPointMake(277.04, 142.3)];
    [fill60Path addCurveToPoint: CGPointMake(273.02, 143.34) controlPoint1: CGPointMake(275.64, 141.47) controlPoint2: CGPointMake(273.84, 141.94)];
    [fill60Path addCurveToPoint: CGPointMake(258.96, 151.36) controlPoint1: CGPointMake(270.13, 148.27) controlPoint2: CGPointMake(264.82, 151.36)];
    [fill60Path addCurveToPoint: CGPointMake(244, 141.58) controlPoint1: CGPointMake(252.24, 151.36) controlPoint2: CGPointMake(246.48, 147.32)];
    [fill60Path addCurveToPoint: CGPointMake(247.4, 140.45) controlPoint1: CGPointMake(245.23, 142) controlPoint2: CGPointMake(246.64, 141.58)];
    [fill60Path addCurveToPoint: CGPointMake(246.6, 136.37) controlPoint1: CGPointMake(248.3, 139.1) controlPoint2: CGPointMake(247.94, 137.27)];
    [fill60Path addLineToPoint: CGPointMake(241.71, 133.08)];
    [fill60Path addCurveToPoint: CGPointMake(240.79, 132.53) controlPoint1: CGPointMake(241.44, 132.85) controlPoint2: CGPointMake(241.14, 132.66)];
    [fill60Path addCurveToPoint: CGPointMake(237.06, 133.7) controlPoint1: CGPointMake(239.46, 131.92) controlPoint2: CGPointMake(237.84, 132.39)];
    [fill60Path addLineToPoint: CGPointMake(233.5, 139.68)];
    [fill60Path addCurveToPoint: CGPointMake(234.53, 143.7) controlPoint1: CGPointMake(232.67, 141.07) controlPoint2: CGPointMake(233.13, 142.88)];
    [fill60Path addCurveToPoint: CGPointMake(238.27, 143.07) controlPoint1: CGPointMake(235.78, 144.45) controlPoint2: CGPointMake(237.35, 144.15)];
    [fill60Path addCurveToPoint: CGPointMake(258.96, 157.24) controlPoint1: CGPointMake(241.44, 151.35) controlPoint2: CGPointMake(249.51, 157.24)];
    [fill60Path addCurveToPoint: CGPointMake(278.09, 146.32) controlPoint1: CGPointMake(266.92, 157.24) controlPoint2: CGPointMake(274.15, 153.03)];
    [fill60Path addCurveToPoint: CGPointMake(277.04, 142.3) controlPoint1: CGPointMake(278.91, 144.92) controlPoint2: CGPointMake(278.45, 143.12)];
    [fill60Path closePath];
    fill60Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill60Path fill];
    
    
    //// Fill-61 Drawing
    UIBezierPath* fill61Path = [UIBezierPath bezierPath];
    [fill61Path moveToPoint: CGPointMake(283.22, 126.79)];
    [fill61Path addCurveToPoint: CGPointMake(279.61, 127.28) controlPoint1: CGPointMake(282.03, 126.08) controlPoint2: CGPointMake(280.54, 126.32)];
    [fill61Path addCurveToPoint: CGPointMake(258.94, 113.16) controlPoint1: CGPointMake(276.43, 119.02) controlPoint2: CGPointMake(268.37, 113.16)];
    [fill61Path addCurveToPoint: CGPointMake(239.8, 124.08) controlPoint1: CGPointMake(250.97, 113.16) controlPoint2: CGPointMake(243.74, 117.37)];
    [fill61Path addCurveToPoint: CGPointMake(240.85, 128.1) controlPoint1: CGPointMake(238.98, 125.48) controlPoint2: CGPointMake(239.45, 127.28)];
    [fill61Path addCurveToPoint: CGPointMake(244.88, 127.05) controlPoint1: CGPointMake(242.25, 128.92) controlPoint2: CGPointMake(244.05, 128.45)];
    [fill61Path addCurveToPoint: CGPointMake(258.94, 119.04) controlPoint1: CGPointMake(247.77, 122.13) controlPoint2: CGPointMake(253.08, 119.04)];
    [fill61Path addCurveToPoint: CGPointMake(273.97, 129) controlPoint1: CGPointMake(265.73, 119.04) controlPoint2: CGPointMake(271.53, 123.15)];
    [fill61Path addCurveToPoint: CGPointMake(270.35, 130.05) controlPoint1: CGPointMake(272.69, 128.44) controlPoint2: CGPointMake(271.16, 128.85)];
    [fill61Path addCurveToPoint: CGPointMake(271.15, 134.13) controlPoint1: CGPointMake(269.45, 131.4) controlPoint2: CGPointMake(269.81, 133.22)];
    [fill61Path addLineToPoint: CGPointMake(276.52, 137.74)];
    [fill61Path addCurveToPoint: CGPointMake(280.69, 136.8) controlPoint1: CGPointMake(277.92, 138.68) controlPoint2: CGPointMake(279.83, 138.25)];
    [fill61Path addLineToPoint: CGPointMake(284.25, 130.82)];
    [fill61Path addCurveToPoint: CGPointMake(283.22, 126.79) controlPoint1: CGPointMake(285.08, 129.43) controlPoint2: CGPointMake(284.62, 127.62)];
    [fill61Path closePath];
    fill61Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill61Path fill];
    
    
    //// Fill-62 Drawing
    UIBezierPath* fill62Path = [UIBezierPath bezierPath];
    [fill62Path moveToPoint: CGPointMake(64.71, 229.99)];
    [fill62Path addLineToPoint: CGPointMake(46.65, 229.99)];
    [fill62Path addCurveToPoint: CGPointMake(44.12, 228.52) controlPoint1: CGPointMake(46.14, 229.12) controlPoint2: CGPointMake(45.2, 228.52)];
    [fill62Path addCurveToPoint: CGPointMake(41.58, 229.99) controlPoint1: CGPointMake(43.03, 228.52) controlPoint2: CGPointMake(42.09, 229.12)];
    [fill62Path addLineToPoint: CGPointMake(23.53, 229.99)];
    [fill62Path addLineToPoint: CGPointMake(23.53, 200.6)];
    [fill62Path addLineToPoint: CGPointMake(32.35, 200.6)];
    [fill62Path addCurveToPoint: CGPointMake(35.29, 197.66) controlPoint1: CGPointMake(33.98, 200.6) controlPoint2: CGPointMake(35.29, 199.28)];
    [fill62Path addCurveToPoint: CGPointMake(36.61, 195.14) controlPoint1: CGPointMake(35.29, 196.24) controlPoint2: CGPointMake(35.73, 195.58)];
    [fill62Path addCurveToPoint: CGPointMake(37.8, 194.77) controlPoint1: CGPointMake(36.97, 194.97) controlPoint2: CGPointMake(37.38, 194.84)];
    [fill62Path addCurveToPoint: CGPointMake(38.24, 194.72) controlPoint1: CGPointMake(38.04, 194.73) controlPoint2: CGPointMake(38.2, 194.72)];
    [fill62Path addLineToPoint: CGPointMake(50, 194.72)];
    [fill62Path addCurveToPoint: CGPointMake(52.52, 196.03) controlPoint1: CGPointMake(51.42, 194.72) controlPoint2: CGPointMake(52.08, 195.16)];
    [fill62Path addCurveToPoint: CGPointMake(52.89, 197.22) controlPoint1: CGPointMake(52.7, 196.39) controlPoint2: CGPointMake(52.82, 196.81)];
    [fill62Path addCurveToPoint: CGPointMake(52.94, 197.66) controlPoint1: CGPointMake(52.93, 197.47) controlPoint2: CGPointMake(52.94, 197.63)];
    [fill62Path addCurveToPoint: CGPointMake(55.88, 200.6) controlPoint1: CGPointMake(52.94, 199.28) controlPoint2: CGPointMake(54.26, 200.6)];
    [fill62Path addLineToPoint: CGPointMake(64.71, 200.6)];
    [fill62Path addLineToPoint: CGPointMake(64.71, 229.99)];
    [fill62Path closePath];
    [fill62Path moveToPoint: CGPointMake(67.65, 194.72)];
    [fill62Path addLineToPoint: CGPointMake(58.32, 194.72)];
    [fill62Path addCurveToPoint: CGPointMake(57.78, 193.41) controlPoint1: CGPointMake(58.17, 194.28) controlPoint2: CGPointMake(57.99, 193.84)];
    [fill62Path addCurveToPoint: CGPointMake(50, 188.84) controlPoint1: CGPointMake(56.38, 190.61) controlPoint2: CGPointMake(53.73, 188.84)];
    [fill62Path addLineToPoint: CGPointMake(38.24, 188.84)];
    [fill62Path addCurveToPoint: CGPointMake(36.83, 188.97) controlPoint1: CGPointMake(37.9, 188.84) controlPoint2: CGPointMake(37.42, 188.88)];
    [fill62Path addCurveToPoint: CGPointMake(33.98, 189.89) controlPoint1: CGPointMake(35.87, 189.13) controlPoint2: CGPointMake(34.91, 189.42)];
    [fill62Path addCurveToPoint: CGPointMake(29.83, 194.72) controlPoint1: CGPointMake(31.98, 190.88) controlPoint2: CGPointMake(30.51, 192.52)];
    [fill62Path addLineToPoint: CGPointMake(20.59, 194.72)];
    [fill62Path addCurveToPoint: CGPointMake(17.65, 197.66) controlPoint1: CGPointMake(18.96, 194.72) controlPoint2: CGPointMake(17.65, 196.04)];
    [fill62Path addLineToPoint: CGPointMake(17.65, 232.93)];
    [fill62Path addCurveToPoint: CGPointMake(20.59, 235.87) controlPoint1: CGPointMake(17.65, 234.56) controlPoint2: CGPointMake(18.96, 235.87)];
    [fill62Path addLineToPoint: CGPointMake(41.18, 235.87)];
    [fill62Path addLineToPoint: CGPointMake(41.18, 238.81)];
    [fill62Path addCurveToPoint: CGPointMake(44.12, 241.75) controlPoint1: CGPointMake(41.18, 240.43) controlPoint2: CGPointMake(42.49, 241.75)];
    [fill62Path addCurveToPoint: CGPointMake(47.06, 238.81) controlPoint1: CGPointMake(45.74, 241.75) controlPoint2: CGPointMake(47.06, 240.43)];
    [fill62Path addLineToPoint: CGPointMake(47.06, 235.87)];
    [fill62Path addLineToPoint: CGPointMake(67.65, 235.87)];
    [fill62Path addCurveToPoint: CGPointMake(70.59, 232.93) controlPoint1: CGPointMake(69.27, 235.87) controlPoint2: CGPointMake(70.59, 234.56)];
    [fill62Path addLineToPoint: CGPointMake(70.59, 197.66)];
    [fill62Path addCurveToPoint: CGPointMake(67.65, 194.72) controlPoint1: CGPointMake(70.59, 196.04) controlPoint2: CGPointMake(69.27, 194.72)];
    [fill62Path closePath];
    fill62Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill62Path fill];
    
    
    //// Fill-63 Drawing
    UIBezierPath* fill63Path = [UIBezierPath bezierPath];
    [fill63Path moveToPoint: CGPointMake(44.12, 221.17)];
    [fill63Path addCurveToPoint: CGPointMake(36.76, 213.83) controlPoint1: CGPointMake(40.06, 221.17) controlPoint2: CGPointMake(36.76, 217.88)];
    [fill63Path addCurveToPoint: CGPointMake(44.12, 206.48) controlPoint1: CGPointMake(36.76, 209.77) controlPoint2: CGPointMake(40.06, 206.48)];
    [fill63Path addCurveToPoint: CGPointMake(51.47, 213.83) controlPoint1: CGPointMake(48.18, 206.48) controlPoint2: CGPointMake(51.47, 209.77)];
    [fill63Path addCurveToPoint: CGPointMake(44.12, 221.17) controlPoint1: CGPointMake(51.47, 217.88) controlPoint2: CGPointMake(48.18, 221.17)];
    [fill63Path closePath];
    [fill63Path moveToPoint: CGPointMake(44.12, 200.6)];
    [fill63Path addCurveToPoint: CGPointMake(30.88, 213.83) controlPoint1: CGPointMake(36.81, 200.6) controlPoint2: CGPointMake(30.88, 206.52)];
    [fill63Path addCurveToPoint: CGPointMake(44.12, 227.05) controlPoint1: CGPointMake(30.88, 221.13) controlPoint2: CGPointMake(36.81, 227.05)];
    [fill63Path addCurveToPoint: CGPointMake(57.35, 213.83) controlPoint1: CGPointMake(51.43, 227.05) controlPoint2: CGPointMake(57.35, 221.13)];
    [fill63Path addCurveToPoint: CGPointMake(44.12, 200.6) controlPoint1: CGPointMake(57.35, 206.52) controlPoint2: CGPointMake(51.43, 200.6)];
    [fill63Path closePath];
    fill63Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill63Path fill];
    
    
    //// Fill-64 Drawing
    UIBezierPath* fill64Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(41, 264, 6, 13) cornerRadius: 3];
    [color setFill];
    [fill64Path fill];
    
    
    //// Fill-65 Drawing
    UIBezierPath* fill65Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(41, 246, 6, 13) cornerRadius: 3];
    [color setFill];
    [fill65Path fill];
    
    
    //// Fill-66 Drawing
    UIBezierPath* fill66Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(41, 281, 6, 14) cornerRadius: 3];
    [color setFill];
    [fill66Path fill];
    
    
    //// Fill-67 Drawing
    UIBezierPath* fill67Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(200, 289, 6, 6)];
    [color setFill];
    [fill67Path fill];
    
    
    //// Fill-68 Drawing
    UIBezierPath* fill68Path = [UIBezierPath bezierPath];
    [fill68Path moveToPoint: CGPointMake(214.71, 296.86)];
    [fill68Path addLineToPoint: CGPointMake(191.18, 296.86)];
    [fill68Path addLineToPoint: CGPointMake(191.18, 255.71)];
    [fill68Path addLineToPoint: CGPointMake(211.76, 255.72)];
    [fill68Path addLineToPoint: CGPointMake(214.71, 255.72)];
    [fill68Path addLineToPoint: CGPointMake(214.71, 296.86)];
    [fill68Path closePath];
    [fill68Path moveToPoint: CGPointMake(217.65, 249.84)];
    [fill68Path addLineToPoint: CGPointMake(211.76, 249.84)];
    [fill68Path addLineToPoint: CGPointMake(194.12, 249.83)];
    [fill68Path addLineToPoint: CGPointMake(188.24, 249.83)];
    [fill68Path addCurveToPoint: CGPointMake(185.29, 252.77) controlPoint1: CGPointMake(186.61, 249.83) controlPoint2: CGPointMake(185.29, 251.15)];
    [fill68Path addLineToPoint: CGPointMake(185.29, 299.8)];
    [fill68Path addCurveToPoint: CGPointMake(188.24, 302.74) controlPoint1: CGPointMake(185.29, 301.43) controlPoint2: CGPointMake(186.61, 302.74)];
    [fill68Path addLineToPoint: CGPointMake(217.65, 302.74)];
    [fill68Path addCurveToPoint: CGPointMake(220.59, 299.8) controlPoint1: CGPointMake(219.27, 302.74) controlPoint2: CGPointMake(220.59, 301.43)];
    [fill68Path addLineToPoint: CGPointMake(220.59, 252.78)];
    [fill68Path addCurveToPoint: CGPointMake(217.65, 249.84) controlPoint1: CGPointMake(220.59, 251.15) controlPoint2: CGPointMake(219.27, 249.84)];
    [fill68Path closePath];
    fill68Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill68Path fill];
    
    
    //// Fill-69 Drawing
    UIBezierPath* fill69Path = [UIBezierPath bezierPath];
    [fill69Path moveToPoint: CGPointMake(136.03, 347.95)];
    [fill69Path addCurveToPoint: CGPointMake(118.38, 365.22) controlPoint1: CGPointMake(136.03, 365.32) controlPoint2: CGPointMake(118.99, 365.22)];
    [fill69Path addLineToPoint: CGPointMake(103.68, 365.22)];
    [fill69Path addCurveToPoint: CGPointMake(100.74, 362.31) controlPoint1: CGPointMake(103.68, 365.22) controlPoint2: CGPointMake(100.74, 365.22)];
    [fill69Path addCurveToPoint: CGPointMake(103.68, 359.4) controlPoint1: CGPointMake(100.74, 359.4) controlPoint2: CGPointMake(103.68, 359.4)];
    [fill69Path addLineToPoint: CGPointMake(118.38, 359.34)];
    [fill69Path addCurveToPoint: CGPointMake(130.15, 347.95) controlPoint1: CGPointMake(118.43, 359.34) controlPoint2: CGPointMake(130.15, 359.77)];
    [fill69Path addCurveToPoint: CGPointMake(118.38, 336.48) controlPoint1: CGPointMake(130.15, 336.12) controlPoint2: CGPointMake(118.49, 336.49)];
    [fill69Path addLineToPoint: CGPointMake(94.85, 336.48)];
    [fill69Path addCurveToPoint: CGPointMake(88.24, 343.16) controlPoint1: CGPointMake(94.85, 336.48) controlPoint2: CGPointMake(88.24, 336.55)];
    [fill69Path addCurveToPoint: CGPointMake(94.85, 349.78) controlPoint1: CGPointMake(88.24, 347.57) controlPoint2: CGPointMake(90.44, 349.78)];
    [fill69Path addLineToPoint: CGPointMake(118.75, 349.78)];
    [fill69Path addCurveToPoint: CGPointMake(120.59, 347.95) controlPoint1: CGPointMake(118.75, 349.78) controlPoint2: CGPointMake(120.59, 349.8)];
    [fill69Path addCurveToPoint: CGPointMake(118.75, 346.05) controlPoint1: CGPointMake(120.59, 346.11) controlPoint2: CGPointMake(118.75, 346.05)];
    [fill69Path addLineToPoint: CGPointMake(94.85, 346.1)];
    [fill69Path addCurveToPoint: CGPointMake(91.91, 343.16) controlPoint1: CGPointMake(94.85, 346.1) controlPoint2: CGPointMake(91.91, 346.1)];
    [fill69Path addCurveToPoint: CGPointMake(94.85, 340.22) controlPoint1: CGPointMake(91.91, 340.22) controlPoint2: CGPointMake(94.85, 340.22)];
    [fill69Path addLineToPoint: CGPointMake(118.38, 340.22)];
    [fill69Path addCurveToPoint: CGPointMake(126.47, 347.95) controlPoint1: CGPointMake(118.38, 340.22) controlPoint2: CGPointMake(126.47, 339.86)];
    [fill69Path addCurveToPoint: CGPointMake(118.38, 355.66) controlPoint1: CGPointMake(126.47, 356.04) controlPoint2: CGPointMake(118.38, 355.66)];
    [fill69Path addLineToPoint: CGPointMake(95.06, 355.66)];
    [fill69Path addCurveToPoint: CGPointMake(82.35, 343.16) controlPoint1: CGPointMake(95.06, 355.66) controlPoint2: CGPointMake(82.35, 355.64)];
    [fill69Path addCurveToPoint: CGPointMake(94.85, 330.68) controlPoint1: CGPointMake(82.35, 330.68) controlPoint2: CGPointMake(94.85, 330.68)];
    [fill69Path addLineToPoint: CGPointMake(118.38, 330.68)];
    [fill69Path addCurveToPoint: CGPointMake(136.03, 347.95) controlPoint1: CGPointMake(118.38, 330.68) controlPoint2: CGPointMake(136.03, 330.58)];
    [fill69Path closePath];
    fill69Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill69Path fill];
    
    
    //// Fill-70 Drawing
    UIBezierPath* fill70Path = [UIBezierPath bezierPath];
    [fill70Path moveToPoint: CGPointMake(89.71, 91.11)];
    [fill70Path addCurveToPoint: CGPointMake(75, 76.41) controlPoint1: CGPointMake(81.58, 91.11) controlPoint2: CGPointMake(75, 84.53)];
    [fill70Path addCurveToPoint: CGPointMake(89.71, 61.71) controlPoint1: CGPointMake(75, 68.29) controlPoint2: CGPointMake(81.58, 61.71)];
    [fill70Path addCurveToPoint: CGPointMake(104.41, 76.41) controlPoint1: CGPointMake(97.83, 61.71) controlPoint2: CGPointMake(104.41, 68.29)];
    [fill70Path addCurveToPoint: CGPointMake(89.71, 91.11) controlPoint1: CGPointMake(104.41, 84.53) controlPoint2: CGPointMake(97.83, 91.11)];
    [fill70Path closePath];
    [fill70Path moveToPoint: CGPointMake(92.65, 56.05)];
    [fill70Path addLineToPoint: CGPointMake(92.65, 52.89)];
    [fill70Path addLineToPoint: CGPointMake(95.59, 52.89)];
    [fill70Path addCurveToPoint: CGPointMake(98.53, 49.95) controlPoint1: CGPointMake(97.21, 52.89) controlPoint2: CGPointMake(98.53, 51.58)];
    [fill70Path addCurveToPoint: CGPointMake(95.59, 47.02) controlPoint1: CGPointMake(98.53, 48.33) controlPoint2: CGPointMake(97.21, 47.02)];
    [fill70Path addLineToPoint: CGPointMake(83.82, 47.02)];
    [fill70Path addCurveToPoint: CGPointMake(80.88, 49.95) controlPoint1: CGPointMake(82.2, 47.02) controlPoint2: CGPointMake(80.88, 48.33)];
    [fill70Path addCurveToPoint: CGPointMake(83.82, 52.89) controlPoint1: CGPointMake(80.88, 51.58) controlPoint2: CGPointMake(82.2, 52.89)];
    [fill70Path addLineToPoint: CGPointMake(86.76, 52.89)];
    [fill70Path addLineToPoint: CGPointMake(86.76, 56.05)];
    [fill70Path addCurveToPoint: CGPointMake(69.12, 76.41) controlPoint1: CGPointMake(76.79, 57.47) controlPoint2: CGPointMake(69.12, 66.04)];
    [fill70Path addCurveToPoint: CGPointMake(89.71, 96.99) controlPoint1: CGPointMake(69.12, 87.77) controlPoint2: CGPointMake(78.34, 96.99)];
    [fill70Path addCurveToPoint: CGPointMake(110.29, 76.41) controlPoint1: CGPointMake(101.08, 96.99) controlPoint2: CGPointMake(110.29, 87.77)];
    [fill70Path addCurveToPoint: CGPointMake(92.65, 56.05) controlPoint1: CGPointMake(110.29, 66.04) controlPoint2: CGPointMake(102.62, 57.47)];
    [fill70Path closePath];
    fill70Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill70Path fill];
    
    
    //// Fill-71 Drawing
    UIBezierPath* fill71Path = [UIBezierPath bezierPath];
    [fill71Path moveToPoint: CGPointMake(92.65, 75.19)];
    [fill71Path addLineToPoint: CGPointMake(97.67, 80.21)];
    [fill71Path addCurveToPoint: CGPointMake(97.67, 84.37) controlPoint1: CGPointMake(98.82, 81.36) controlPoint2: CGPointMake(98.82, 83.22)];
    [fill71Path addCurveToPoint: CGPointMake(93.51, 84.37) controlPoint1: CGPointMake(96.52, 85.51) controlPoint2: CGPointMake(94.66, 85.51)];
    [fill71Path addLineToPoint: CGPointMake(87.63, 78.49)];
    [fill71Path addCurveToPoint: CGPointMake(86.76, 76.41) controlPoint1: CGPointMake(87.07, 77.94) controlPoint2: CGPointMake(86.76, 77.19)];
    [fill71Path addLineToPoint: CGPointMake(86.76, 68.33)];
    [fill71Path addCurveToPoint: CGPointMake(89.71, 65.39) controlPoint1: CGPointMake(86.76, 66.7) controlPoint2: CGPointMake(88.08, 65.39)];
    [fill71Path addCurveToPoint: CGPointMake(92.65, 68.33) controlPoint1: CGPointMake(91.33, 65.39) controlPoint2: CGPointMake(92.65, 66.7)];
    [fill71Path addLineToPoint: CGPointMake(92.65, 75.19)];
    [fill71Path closePath];
    fill71Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill71Path fill];
    
    
    //// Fill-72 Drawing
    UIBezierPath* fill72Path = [UIBezierPath bezierPath];
    [fill72Path moveToPoint: CGPointMake(154.54, 109.12)];
    [fill72Path addLineToPoint: CGPointMake(157.99, 105.68)];
    [fill72Path addCurveToPoint: CGPointMake(157.99, 101.52) controlPoint1: CGPointMake(159.14, 104.53) controlPoint2: CGPointMake(159.14, 102.67)];
    [fill72Path addCurveToPoint: CGPointMake(153.83, 101.52) controlPoint1: CGPointMake(156.84, 100.37) controlPoint2: CGPointMake(154.98, 100.37)];
    [fill72Path addLineToPoint: CGPointMake(150.38, 104.97)];
    [fill72Path addLineToPoint: CGPointMake(146.93, 101.52)];
    [fill72Path addCurveToPoint: CGPointMake(142.77, 101.52) controlPoint1: CGPointMake(145.78, 100.37) controlPoint2: CGPointMake(143.92, 100.37)];
    [fill72Path addCurveToPoint: CGPointMake(142.77, 105.68) controlPoint1: CGPointMake(141.62, 102.67) controlPoint2: CGPointMake(141.62, 104.53)];
    [fill72Path addLineToPoint: CGPointMake(146.22, 109.12)];
    [fill72Path addLineToPoint: CGPointMake(142.77, 112.57)];
    [fill72Path addCurveToPoint: CGPointMake(142.77, 116.72) controlPoint1: CGPointMake(141.62, 113.72) controlPoint2: CGPointMake(141.62, 115.58)];
    [fill72Path addCurveToPoint: CGPointMake(146.93, 116.72) controlPoint1: CGPointMake(143.92, 117.87) controlPoint2: CGPointMake(145.78, 117.87)];
    [fill72Path addLineToPoint: CGPointMake(150.38, 113.28)];
    [fill72Path addLineToPoint: CGPointMake(153.83, 116.72)];
    [fill72Path addCurveToPoint: CGPointMake(157.99, 116.72) controlPoint1: CGPointMake(154.98, 117.87) controlPoint2: CGPointMake(156.84, 117.87)];
    [fill72Path addCurveToPoint: CGPointMake(157.99, 112.57) controlPoint1: CGPointMake(159.14, 115.58) controlPoint2: CGPointMake(159.14, 113.72)];
    [fill72Path addLineToPoint: CGPointMake(154.54, 109.12)];
    [fill72Path closePath];
    fill72Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill72Path fill];
    
    
    //// Fill-73 Drawing
    UIBezierPath* fill73Path = [UIBezierPath bezierPath];
    [fill73Path moveToPoint: CGPointMake(85.29, 126.38)];
    [fill73Path addLineToPoint: CGPointMake(120.59, 126.38)];
    [fill73Path addLineToPoint: CGPointMake(120.59, 114.62)];
    [fill73Path addLineToPoint: CGPointMake(85.29, 114.62)];
    [fill73Path addLineToPoint: CGPointMake(85.29, 126.38)];
    [fill73Path closePath];
    [fill73Path moveToPoint: CGPointMake(82.35, 132.26)];
    [fill73Path addCurveToPoint: CGPointMake(79.41, 129.32) controlPoint1: CGPointMake(80.73, 132.26) controlPoint2: CGPointMake(79.41, 130.94)];
    [fill73Path addLineToPoint: CGPointMake(79.41, 111.68)];
    [fill73Path addCurveToPoint: CGPointMake(82.35, 108.74) controlPoint1: CGPointMake(79.41, 110.06) controlPoint2: CGPointMake(80.73, 108.74)];
    [fill73Path addLineToPoint: CGPointMake(123.53, 108.74)];
    [fill73Path addCurveToPoint: CGPointMake(126.47, 111.68) controlPoint1: CGPointMake(125.15, 108.74) controlPoint2: CGPointMake(126.47, 110.06)];
    [fill73Path addLineToPoint: CGPointMake(126.47, 129.32)];
    [fill73Path addCurveToPoint: CGPointMake(123.53, 132.26) controlPoint1: CGPointMake(126.47, 130.94) controlPoint2: CGPointMake(125.15, 132.26)];
    [fill73Path addLineToPoint: CGPointMake(82.35, 132.26)];
    [fill73Path closePath];
    fill73Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill73Path fill];
    
    
    //// Fill-74 Drawing
    UIBezierPath* fill74Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(110, 118, 6, 6)];
    [color setFill];
    [fill74Path fill];
    
    
    //// Fill-75 Drawing
    UIBezierPath* fill75Path = [UIBezierPath bezierPath];
    [fill75Path moveToPoint: CGPointMake(85.29, 152.83)];
    [fill75Path addLineToPoint: CGPointMake(120.59, 152.83)];
    [fill75Path addLineToPoint: CGPointMake(120.59, 141.08)];
    [fill75Path addLineToPoint: CGPointMake(85.29, 141.08)];
    [fill75Path addLineToPoint: CGPointMake(85.29, 152.83)];
    [fill75Path closePath];
    [fill75Path moveToPoint: CGPointMake(82.35, 158.71)];
    [fill75Path addCurveToPoint: CGPointMake(79.41, 155.77) controlPoint1: CGPointMake(80.73, 158.71) controlPoint2: CGPointMake(79.41, 157.4)];
    [fill75Path addLineToPoint: CGPointMake(79.41, 138.14)];
    [fill75Path addCurveToPoint: CGPointMake(82.35, 135.2) controlPoint1: CGPointMake(79.41, 136.51) controlPoint2: CGPointMake(80.73, 135.2)];
    [fill75Path addLineToPoint: CGPointMake(123.53, 135.2)];
    [fill75Path addCurveToPoint: CGPointMake(126.47, 138.14) controlPoint1: CGPointMake(125.15, 135.2) controlPoint2: CGPointMake(126.47, 136.51)];
    [fill75Path addLineToPoint: CGPointMake(126.47, 155.77)];
    [fill75Path addCurveToPoint: CGPointMake(123.53, 158.71) controlPoint1: CGPointMake(126.47, 157.4) controlPoint2: CGPointMake(125.15, 158.71)];
    [fill75Path addLineToPoint: CGPointMake(82.35, 158.71)];
    [fill75Path closePath];
    fill75Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill75Path fill];
    
    
    //// Fill-76 Drawing
    UIBezierPath* fill76Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(110, 144, 6, 6)];
    [color setFill];
    [fill76Path fill];
    
    
    //// Fill-77 Drawing
    UIBezierPath* fill77Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(187, 141, 6, 6)];
    [color setFill];
    [fill77Path fill];
    
    
    //// Fill-78 Drawing
    UIBezierPath* fill78Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(197, 141, 6, 6)];
    [color setFill];
    [fill78Path fill];
    
    
    //// Fill-79 Drawing
    UIBezierPath* fill79Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(208, 141, 6, 6)];
    [color setFill];
    [fill79Path fill];
    
    
    //// Fill-80 Drawing
    UIBezierPath* fill80Path = [UIBezierPath bezierPath];
    [fill80Path moveToPoint: CGPointMake(219.12, 152.83)];
    [fill80Path addCurveToPoint: CGPointMake(217.65, 154.3) controlPoint1: CGPointMake(219.12, 153.64) controlPoint2: CGPointMake(218.46, 154.3)];
    [fill80Path addLineToPoint: CGPointMake(182.35, 154.3)];
    [fill80Path addCurveToPoint: CGPointMake(180.88, 152.83) controlPoint1: CGPointMake(181.54, 154.3) controlPoint2: CGPointMake(180.88, 153.64)];
    [fill80Path addLineToPoint: CGPointMake(180.88, 143.28)];
    [fill80Path addCurveToPoint: CGPointMake(191.91, 132.26) controlPoint1: CGPointMake(180.88, 137.19) controlPoint2: CGPointMake(185.82, 132.26)];
    [fill80Path addLineToPoint: CGPointMake(208.09, 132.26)];
    [fill80Path addCurveToPoint: CGPointMake(219.12, 143.28) controlPoint1: CGPointMake(214.18, 132.26) controlPoint2: CGPointMake(219.12, 137.19)];
    [fill80Path addLineToPoint: CGPointMake(219.12, 152.83)];
    [fill80Path closePath];
    [fill80Path moveToPoint: CGPointMake(224.18, 118.64)];
    [fill80Path addCurveToPoint: CGPointMake(220.2, 119.85) controlPoint1: CGPointMake(222.75, 117.88) controlPoint2: CGPointMake(220.96, 118.42)];
    [fill80Path addLineToPoint: CGPointMake(215.74, 128.21)];
    [fill80Path addCurveToPoint: CGPointMake(208.09, 126.38) controlPoint1: CGPointMake(213.44, 127.04) controlPoint2: CGPointMake(210.84, 126.38)];
    [fill80Path addLineToPoint: CGPointMake(191.91, 126.38)];
    [fill80Path addCurveToPoint: CGPointMake(184.26, 128.21) controlPoint1: CGPointMake(189.16, 126.38) controlPoint2: CGPointMake(186.56, 127.04)];
    [fill80Path addLineToPoint: CGPointMake(179.8, 119.85)];
    [fill80Path addCurveToPoint: CGPointMake(175.82, 118.64) controlPoint1: CGPointMake(179.04, 118.42) controlPoint2: CGPointMake(177.26, 117.88)];
    [fill80Path addCurveToPoint: CGPointMake(174.61, 122.62) controlPoint1: CGPointMake(174.39, 119.41) controlPoint2: CGPointMake(173.85, 121.19)];
    [fill80Path addLineToPoint: CGPointMake(179.51, 131.8)];
    [fill80Path addCurveToPoint: CGPointMake(175, 143.28) controlPoint1: CGPointMake(176.71, 134.81) controlPoint2: CGPointMake(175, 138.85)];
    [fill80Path addLineToPoint: CGPointMake(175, 152.83)];
    [fill80Path addCurveToPoint: CGPointMake(182.35, 160.18) controlPoint1: CGPointMake(175, 156.89) controlPoint2: CGPointMake(178.29, 160.18)];
    [fill80Path addLineToPoint: CGPointMake(217.65, 160.18)];
    [fill80Path addCurveToPoint: CGPointMake(225, 152.83) controlPoint1: CGPointMake(221.71, 160.18) controlPoint2: CGPointMake(225, 156.89)];
    [fill80Path addLineToPoint: CGPointMake(225, 143.28)];
    [fill80Path addCurveToPoint: CGPointMake(220.49, 131.8) controlPoint1: CGPointMake(225, 138.85) controlPoint2: CGPointMake(223.29, 134.81)];
    [fill80Path addLineToPoint: CGPointMake(225.39, 122.62)];
    [fill80Path addCurveToPoint: CGPointMake(224.18, 118.64) controlPoint1: CGPointMake(226.15, 121.19) controlPoint2: CGPointMake(225.61, 119.41)];
    [fill80Path closePath];
    fill80Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill80Path fill];
    
    
    //// Fill-81 Drawing
    UIBezierPath* fill81Path = [UIBezierPath bezierPath];
    [fill81Path moveToPoint: CGPointMake(230.88, 304.21)];
    [fill81Path addCurveToPoint: CGPointMake(227.94, 301.27) controlPoint1: CGPointMake(230.88, 302.59) controlPoint2: CGPointMake(229.57, 301.27)];
    [fill81Path addCurveToPoint: CGPointMake(225, 304.21) controlPoint1: CGPointMake(226.32, 301.27) controlPoint2: CGPointMake(225, 302.59)];
    [fill81Path addCurveToPoint: CGPointMake(222.06, 307.15) controlPoint1: CGPointMake(225, 305.84) controlPoint2: CGPointMake(223.68, 307.15)];
    [fill81Path addCurveToPoint: CGPointMake(219.12, 310.09) controlPoint1: CGPointMake(220.43, 307.15) controlPoint2: CGPointMake(219.12, 308.47)];
    [fill81Path addCurveToPoint: CGPointMake(222.06, 313.03) controlPoint1: CGPointMake(219.12, 311.71) controlPoint2: CGPointMake(220.43, 313.03)];
    [fill81Path addCurveToPoint: CGPointMake(230.88, 304.21) controlPoint1: CGPointMake(226.93, 313.03) controlPoint2: CGPointMake(230.88, 309.08)];
    [fill81Path closePath];
    fill81Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill81Path fill];
    
    
    //// Fill-82 Drawing
    UIBezierPath* fill82Path = [UIBezierPath bezierPath];
    [fill82Path moveToPoint: CGPointMake(242.65, 304.21)];
    [fill82Path addCurveToPoint: CGPointMake(239.71, 301.27) controlPoint1: CGPointMake(242.65, 302.59) controlPoint2: CGPointMake(241.33, 301.27)];
    [fill82Path addCurveToPoint: CGPointMake(236.76, 304.21) controlPoint1: CGPointMake(238.08, 301.27) controlPoint2: CGPointMake(236.76, 302.59)];
    [fill82Path addCurveToPoint: CGPointMake(222.06, 318.91) controlPoint1: CGPointMake(236.76, 312.33) controlPoint2: CGPointMake(230.18, 318.91)];
    [fill82Path addCurveToPoint: CGPointMake(219.12, 321.85) controlPoint1: CGPointMake(220.43, 318.91) controlPoint2: CGPointMake(219.12, 320.23)];
    [fill82Path addCurveToPoint: CGPointMake(222.06, 324.79) controlPoint1: CGPointMake(219.12, 323.47) controlPoint2: CGPointMake(220.43, 324.79)];
    [fill82Path addCurveToPoint: CGPointMake(242.65, 304.21) controlPoint1: CGPointMake(233.43, 324.79) controlPoint2: CGPointMake(242.65, 315.58)];
    [fill82Path closePath];
    fill82Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill82Path fill];
    
    
    //// Fill-83 Drawing
    UIBezierPath* fill83Path = [UIBezierPath bezierPath];
    [fill83Path moveToPoint: CGPointMake(254.41, 304.21)];
    [fill83Path addCurveToPoint: CGPointMake(251.47, 301.27) controlPoint1: CGPointMake(254.41, 302.59) controlPoint2: CGPointMake(253.09, 301.27)];
    [fill83Path addCurveToPoint: CGPointMake(248.53, 304.21) controlPoint1: CGPointMake(249.85, 301.27) controlPoint2: CGPointMake(248.53, 302.59)];
    [fill83Path addCurveToPoint: CGPointMake(222.06, 330.67) controlPoint1: CGPointMake(248.53, 318.82) controlPoint2: CGPointMake(236.68, 330.67)];
    [fill83Path addCurveToPoint: CGPointMake(219.12, 333.61) controlPoint1: CGPointMake(220.43, 330.67) controlPoint2: CGPointMake(219.12, 331.98)];
    [fill83Path addCurveToPoint: CGPointMake(222.06, 336.55) controlPoint1: CGPointMake(219.12, 335.23) controlPoint2: CGPointMake(220.43, 336.55)];
    [fill83Path addCurveToPoint: CGPointMake(254.41, 304.21) controlPoint1: CGPointMake(239.93, 336.55) controlPoint2: CGPointMake(254.41, 322.07)];
    [fill83Path closePath];
    fill83Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill83Path fill];
    
    
    //// Fill-84 Drawing
    UIBezierPath* fill84Path = [UIBezierPath bezierPath];
    [fill84Path moveToPoint: CGPointMake(235.29, 205.74)];
    [fill84Path addLineToPoint: CGPointMake(239.71, 205.74)];
    [fill84Path addLineToPoint: CGPointMake(239.71, 193.99)];
    [fill84Path addLineToPoint: CGPointMake(235.29, 193.99)];
    [fill84Path addLineToPoint: CGPointMake(235.29, 205.74)];
    [fill84Path closePath];
    [fill84Path moveToPoint: CGPointMake(232.35, 211.62)];
    [fill84Path addLineToPoint: CGPointMake(242.65, 211.62)];
    [fill84Path addCurveToPoint: CGPointMake(245.59, 208.68) controlPoint1: CGPointMake(244.27, 211.62) controlPoint2: CGPointMake(245.59, 210.31)];
    [fill84Path addLineToPoint: CGPointMake(245.59, 191.05)];
    [fill84Path addCurveToPoint: CGPointMake(242.65, 188.11) controlPoint1: CGPointMake(245.59, 189.42) controlPoint2: CGPointMake(244.27, 188.11)];
    [fill84Path addLineToPoint: CGPointMake(232.35, 188.11)];
    [fill84Path addCurveToPoint: CGPointMake(229.41, 191.05) controlPoint1: CGPointMake(230.73, 188.11) controlPoint2: CGPointMake(229.41, 189.42)];
    [fill84Path addLineToPoint: CGPointMake(229.41, 208.68)];
    [fill84Path addCurveToPoint: CGPointMake(232.35, 211.62) controlPoint1: CGPointMake(229.41, 210.31) controlPoint2: CGPointMake(230.73, 211.62)];
    [fill84Path closePath];
    fill84Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill84Path fill];
    
    
    //// Fill-85 Drawing
    UIBezierPath* fill85Path = [UIBezierPath bezierPath];
    [fill85Path moveToPoint: CGPointMake(253.68, 205.74)];
    [fill85Path addLineToPoint: CGPointMake(258.09, 205.74)];
    [fill85Path addLineToPoint: CGPointMake(258.09, 176.35)];
    [fill85Path addLineToPoint: CGPointMake(253.68, 176.35)];
    [fill85Path addLineToPoint: CGPointMake(253.68, 205.74)];
    [fill85Path closePath];
    [fill85Path moveToPoint: CGPointMake(250.74, 211.62)];
    [fill85Path addLineToPoint: CGPointMake(261.03, 211.62)];
    [fill85Path addCurveToPoint: CGPointMake(263.97, 208.68) controlPoint1: CGPointMake(262.65, 211.62) controlPoint2: CGPointMake(263.97, 210.31)];
    [fill85Path addLineToPoint: CGPointMake(263.97, 173.41)];
    [fill85Path addCurveToPoint: CGPointMake(261.03, 170.47) controlPoint1: CGPointMake(263.97, 171.79) controlPoint2: CGPointMake(262.65, 170.47)];
    [fill85Path addLineToPoint: CGPointMake(250.74, 170.47)];
    [fill85Path addCurveToPoint: CGPointMake(247.79, 173.41) controlPoint1: CGPointMake(249.11, 170.47) controlPoint2: CGPointMake(247.79, 171.79)];
    [fill85Path addLineToPoint: CGPointMake(247.79, 208.68)];
    [fill85Path addCurveToPoint: CGPointMake(250.74, 211.62) controlPoint1: CGPointMake(247.79, 210.31) controlPoint2: CGPointMake(249.11, 211.62)];
    [fill85Path closePath];
    fill85Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill85Path fill];
    
    
    //// Fill-86 Drawing
    UIBezierPath* fill86Path = [UIBezierPath bezierPath];
    [fill86Path moveToPoint: CGPointMake(272.06, 205.74)];
    [fill86Path addLineToPoint: CGPointMake(276.47, 205.74)];
    [fill86Path addLineToPoint: CGPointMake(276.47, 181.49)];
    [fill86Path addLineToPoint: CGPointMake(272.06, 181.49)];
    [fill86Path addLineToPoint: CGPointMake(272.06, 205.74)];
    [fill86Path closePath];
    [fill86Path moveToPoint: CGPointMake(279.41, 175.61)];
    [fill86Path addLineToPoint: CGPointMake(269.12, 175.61)];
    [fill86Path addCurveToPoint: CGPointMake(266.18, 178.55) controlPoint1: CGPointMake(267.49, 175.61) controlPoint2: CGPointMake(266.18, 176.93)];
    [fill86Path addLineToPoint: CGPointMake(266.18, 208.68)];
    [fill86Path addCurveToPoint: CGPointMake(269.12, 211.62) controlPoint1: CGPointMake(266.18, 210.31) controlPoint2: CGPointMake(267.49, 211.62)];
    [fill86Path addLineToPoint: CGPointMake(279.41, 211.62)];
    [fill86Path addCurveToPoint: CGPointMake(282.35, 208.68) controlPoint1: CGPointMake(281.04, 211.62) controlPoint2: CGPointMake(282.35, 210.31)];
    [fill86Path addLineToPoint: CGPointMake(282.35, 178.55)];
    [fill86Path addCurveToPoint: CGPointMake(279.41, 175.61) controlPoint1: CGPointMake(282.35, 176.93) controlPoint2: CGPointMake(281.04, 175.61)];
    [fill86Path closePath];
    fill86Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill86Path fill];
    
    
    //// Fill-87 Drawing
    UIBezierPath* fill87Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(229, 218, 53, 5) cornerRadius: 2.5];
    [color setFill];
    [fill87Path fill];
    
    
    //// Fill-88 Drawing
    UIBezierPath* fill88Path = [UIBezierPath bezierPath];
    [fill88Path moveToPoint: CGPointMake(129.41, 285.11)];
    [fill88Path addLineToPoint: CGPointMake(170.59, 285.11)];
    [fill88Path addLineToPoint: CGPointMake(170.59, 255.71)];
    [fill88Path addLineToPoint: CGPointMake(129.41, 255.71)];
    [fill88Path addLineToPoint: CGPointMake(129.41, 285.11)];
    [fill88Path closePath];
    [fill88Path moveToPoint: CGPointMake(173.53, 249.83)];
    [fill88Path addLineToPoint: CGPointMake(126.47, 249.83)];
    [fill88Path addCurveToPoint: CGPointMake(123.53, 252.77) controlPoint1: CGPointMake(124.85, 249.83) controlPoint2: CGPointMake(123.53, 251.15)];
    [fill88Path addLineToPoint: CGPointMake(123.53, 288.05)];
    [fill88Path addCurveToPoint: CGPointMake(126.47, 290.99) controlPoint1: CGPointMake(123.53, 289.67) controlPoint2: CGPointMake(124.85, 290.99)];
    [fill88Path addLineToPoint: CGPointMake(173.53, 290.99)];
    [fill88Path addCurveToPoint: CGPointMake(176.47, 288.05) controlPoint1: CGPointMake(175.15, 290.99) controlPoint2: CGPointMake(176.47, 289.67)];
    [fill88Path addLineToPoint: CGPointMake(176.47, 252.77)];
    [fill88Path addCurveToPoint: CGPointMake(173.53, 249.83) controlPoint1: CGPointMake(176.47, 251.15) controlPoint2: CGPointMake(175.15, 249.83)];
    [fill88Path closePath];
    fill88Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill88Path fill];
    
    
    //// Fill-89 Drawing
    UIBezierPath* fill89Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(135, 294, 30, 6) cornerRadius: 3];
    [color setFill];
    [fill89Path fill];
    
    
    //// Fill-90 Drawing
    UIBezierPath* fill90Path = [UIBezierPath bezierPath];
    [fill90Path moveToPoint: CGPointMake(73.53, 310.96)];
    [fill90Path addLineToPoint: CGPointMake(67.65, 309.86)];
    [fill90Path addLineToPoint: CGPointMake(67.65, 305.68)];
    [fill90Path addLineToPoint: CGPointMake(73.53, 305.68)];
    [fill90Path addLineToPoint: CGPointMake(73.53, 310.96)];
    [fill90Path closePath];
    [fill90Path moveToPoint: CGPointMake(77.36, 255.71)];
    [fill90Path addLineToPoint: CGPointMake(79.25, 291.04)];
    [fill90Path addCurveToPoint: CGPointMake(78.68, 290.98) controlPoint1: CGPointMake(79.07, 291.01) controlPoint2: CGPointMake(78.87, 290.98)];
    [fill90Path addLineToPoint: CGPointMake(61.93, 290.98)];
    [fill90Path addLineToPoint: CGPointMake(63.82, 255.71)];
    [fill90Path addLineToPoint: CGPointMake(77.36, 255.71)];
    [fill90Path closePath];
    [fill90Path moveToPoint: CGPointMake(64.32, 296.86)];
    [fill90Path addLineToPoint: CGPointMake(76.86, 296.86)];
    [fill90Path addLineToPoint: CGPointMake(74.9, 299.8)];
    [fill90Path addLineToPoint: CGPointMake(66.28, 299.8)];
    [fill90Path addLineToPoint: CGPointMake(64.32, 296.86)];
    [fill90Path closePath];
    [fill90Path moveToPoint: CGPointMake(85.29, 293.77)];
    [fill90Path addLineToPoint: CGPointMake(83.08, 252.62)];
    [fill90Path addCurveToPoint: CGPointMake(80.15, 249.83) controlPoint1: CGPointMake(83, 251.06) controlPoint2: CGPointMake(81.71, 249.83)];
    [fill90Path addLineToPoint: CGPointMake(61.03, 249.83)];
    [fill90Path addCurveToPoint: CGPointMake(58.09, 252.62) controlPoint1: CGPointMake(59.47, 249.83) controlPoint2: CGPointMake(58.18, 251.06)];
    [fill90Path addLineToPoint: CGPointMake(55.89, 293.77)];
    [fill90Path addCurveToPoint: CGPointMake(56.38, 295.55) controlPoint1: CGPointMake(55.85, 294.4) controlPoint2: CGPointMake(56.02, 295.03)];
    [fill90Path addLineToPoint: CGPointMake(61.76, 303.63)];
    [fill90Path addLineToPoint: CGPointMake(61.76, 312.3)];
    [fill90Path addCurveToPoint: CGPointMake(64.16, 315.18) controlPoint1: CGPointMake(61.76, 313.71) controlPoint2: CGPointMake(62.77, 314.92)];
    [fill90Path addLineToPoint: CGPointMake(75.93, 317.39)];
    [fill90Path addCurveToPoint: CGPointMake(79.41, 314.5) controlPoint1: CGPointMake(77.74, 317.73) controlPoint2: CGPointMake(79.41, 316.34)];
    [fill90Path addLineToPoint: CGPointMake(79.41, 303.63)];
    [fill90Path addLineToPoint: CGPointMake(84.8, 295.55)];
    [fill90Path addCurveToPoint: CGPointMake(85.29, 293.77) controlPoint1: CGPointMake(85.15, 295.03) controlPoint2: CGPointMake(85.32, 294.4)];
    [fill90Path closePath];
    fill90Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill90Path fill];
    
    
    //// Fill-91 Drawing
    UIBezierPath* fill91Path = [UIBezierPath bezierPath];
    [fill91Path moveToPoint: CGPointMake(67.65, 126.38)];
    [fill91Path addLineToPoint: CGPointMake(20.59, 126.38)];
    [fill91Path addCurveToPoint: CGPointMake(17.65, 129.32) controlPoint1: CGPointMake(18.96, 126.38) controlPoint2: CGPointMake(17.65, 127.7)];
    [fill91Path addLineToPoint: CGPointMake(17.65, 141.08)];
    [fill91Path addCurveToPoint: CGPointMake(20.59, 144.02) controlPoint1: CGPointMake(17.65, 142.7) controlPoint2: CGPointMake(18.96, 144.02)];
    [fill91Path addCurveToPoint: CGPointMake(23.53, 141.08) controlPoint1: CGPointMake(22.21, 144.02) controlPoint2: CGPointMake(23.53, 142.7)];
    [fill91Path addLineToPoint: CGPointMake(23.53, 132.26)];
    [fill91Path addLineToPoint: CGPointMake(64.71, 132.26)];
    [fill91Path addLineToPoint: CGPointMake(64.71, 161.65)];
    [fill91Path addLineToPoint: CGPointMake(32.35, 161.65)];
    [fill91Path addLineToPoint: CGPointMake(20.59, 161.65)];
    [fill91Path addCurveToPoint: CGPointMake(17.65, 164.59) controlPoint1: CGPointMake(18.96, 161.65) controlPoint2: CGPointMake(17.65, 162.97)];
    [fill91Path addCurveToPoint: CGPointMake(20.59, 167.53) controlPoint1: CGPointMake(17.65, 166.21) controlPoint2: CGPointMake(18.96, 167.53)];
    [fill91Path addLineToPoint: CGPointMake(27.59, 167.53)];
    [fill91Path addLineToPoint: CGPointMake(23.84, 175.03)];
    [fill91Path addCurveToPoint: CGPointMake(25.16, 178.98) controlPoint1: CGPointMake(23.11, 176.49) controlPoint2: CGPointMake(23.7, 178.25)];
    [fill91Path addCurveToPoint: CGPointMake(29.1, 177.66) controlPoint1: CGPointMake(26.61, 179.7) controlPoint2: CGPointMake(28.37, 179.12)];
    [fill91Path addLineToPoint: CGPointMake(34.17, 167.53)];
    [fill91Path addLineToPoint: CGPointMake(54.8, 167.53)];
    [fill91Path addLineToPoint: CGPointMake(59.87, 177.66)];
    [fill91Path addCurveToPoint: CGPointMake(63.82, 178.98) controlPoint1: CGPointMake(60.6, 179.12) controlPoint2: CGPointMake(62.36, 179.7)];
    [fill91Path addCurveToPoint: CGPointMake(65.13, 175.03) controlPoint1: CGPointMake(65.27, 178.25) controlPoint2: CGPointMake(65.86, 176.49)];
    [fill91Path addLineToPoint: CGPointMake(61.38, 167.53)];
    [fill91Path addLineToPoint: CGPointMake(67.65, 167.53)];
    [fill91Path addCurveToPoint: CGPointMake(70.59, 164.59) controlPoint1: CGPointMake(69.27, 167.53) controlPoint2: CGPointMake(70.59, 166.21)];
    [fill91Path addLineToPoint: CGPointMake(70.59, 129.32)];
    [fill91Path addCurveToPoint: CGPointMake(67.65, 126.38) controlPoint1: CGPointMake(70.59, 127.7) controlPoint2: CGPointMake(69.27, 126.38)];
    [fill91Path closePath];
    fill91Path.usesEvenOddFillRule = YES;
    [color setFill];
    [fill91Path fill];
}

+ (void)drawDegradation
{
    [WireStyleKit drawDegradationWithFrame: CGRectMake(0, 0, 260, 260) resizing: WireStyleKitResizingBehaviorStretch];
}

+ (void)drawDegradationWithFrame: (CGRect)targetFrame resizing: (WireStyleKitResizingBehavior)resizing
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Resize to Target Frame
    CGContextSaveGState(context);
    CGRect resizedFrame = WireStyleKitResizingBehaviorApply(resizing, CGRectMake(0, 0, 260, 260), targetFrame);
    CGContextTranslateCTM(context, resizedFrame.origin.x, resizedFrame.origin.y);
    CGContextScaleCTM(context, resizedFrame.size.width / 260, resizedFrame.size.height / 260);
    
    
    //// Color Declarations
    UIColor* white80 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.8];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(130, 260)];
    [bezierPath addCurveToPoint: CGPointMake(0, 130) controlPoint1: CGPointMake(58.2, 260) controlPoint2: CGPointMake(0, 201.8)];
    [bezierPath addCurveToPoint: CGPointMake(130, 0) controlPoint1: CGPointMake(0, 58.2) controlPoint2: CGPointMake(58.2, 0)];
    [bezierPath addCurveToPoint: CGPointMake(260, 130) controlPoint1: CGPointMake(201.8, 0) controlPoint2: CGPointMake(260, 58.2)];
    [bezierPath addCurveToPoint: CGPointMake(130, 260) controlPoint1: CGPointMake(260, 201.8) controlPoint2: CGPointMake(201.8, 260)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(177.52, 87.96)];
    [bezierPath addLineToPoint: CGPointMake(129.5, 75.12)];
    [bezierPath addLineToPoint: CGPointMake(81.48, 88.84)];
    [bezierPath addLineToPoint: CGPointMake(81.48, 130)];
    [bezierPath addCurveToPoint: CGPointMake(129.5, 184.88) controlPoint1: CGPointMake(81.48, 157.44) controlPoint2: CGPointMake(102.11, 178.69)];
    [bezierPath addCurveToPoint: CGPointMake(177.52, 130) controlPoint1: CGPointMake(157.17, 178.69) controlPoint2: CGPointMake(177.52, 157.44)];
    [bezierPath addLineToPoint: CGPointMake(177.52, 87.96)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(91.77, 95.86)];
    [bezierPath addLineToPoint: CGPointMake(129.5, 85.82)];
    [bezierPath addLineToPoint: CGPointMake(129.49, 174.29)];
    [bezierPath addCurveToPoint: CGPointMake(91.77, 130) controlPoint1: CGPointMake(106.77, 168.34) controlPoint2: CGPointMake(91.77, 150.97)];
    [bezierPath addLineToPoint: CGPointMake(91.77, 95.86)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [white80 setFill];
    [bezierPath fill];
    
    CGContextRestoreGState(context);
    
}

+ (void)drawSpaceWithColor: (UIColor*)color
{
    [WireStyleKit drawSpaceWithFrame: CGRectMake(0, 0, 28, 28) resizing: WireStyleKitResizingBehaviorStretch color: color];
}

+ (void)drawSpaceWithFrame: (CGRect)targetFrame resizing: (WireStyleKitResizingBehavior)resizing color: (UIColor*)color
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Resize to Target Frame
    CGContextSaveGState(context);
    CGRect resizedFrame = WireStyleKitResizingBehaviorApply(resizing, CGRectMake(0, 0, 28, 28), targetFrame);
    CGContextTranslateCTM(context, resizedFrame.origin.x, resizedFrame.origin.y);
    CGContextScaleCTM(context, resizedFrame.size.width / 28, resizedFrame.size.height / 28);
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(16.03, 0.55)];
    [bezierPath addLineToPoint: CGPointMake(24.53, 5.53)];
    [bezierPath addLineToPoint: CGPointMake(24.53, 5.53)];
    [bezierPath addCurveToPoint: CGPointMake(26.5, 8.96) controlPoint1: CGPointMake(25.75, 6.24) controlPoint2: CGPointMake(26.5, 7.55)];
    [bezierPath addLineToPoint: CGPointMake(26.5, 19.04)];
    [bezierPath addLineToPoint: CGPointMake(26.5, 19.04)];
    [bezierPath addCurveToPoint: CGPointMake(24.53, 22.47) controlPoint1: CGPointMake(26.5, 20.45) controlPoint2: CGPointMake(25.75, 21.76)];
    [bezierPath addLineToPoint: CGPointMake(16.03, 27.45)];
    [bezierPath addLineToPoint: CGPointMake(16.03, 27.45)];
    [bezierPath addCurveToPoint: CGPointMake(11.97, 27.45) controlPoint1: CGPointMake(14.77, 28.18) controlPoint2: CGPointMake(13.23, 28.18)];
    [bezierPath addLineToPoint: CGPointMake(3.47, 22.47)];
    [bezierPath addLineToPoint: CGPointMake(3.47, 22.47)];
    [bezierPath addCurveToPoint: CGPointMake(1.5, 19.04) controlPoint1: CGPointMake(2.25, 21.76) controlPoint2: CGPointMake(1.5, 20.45)];
    [bezierPath addLineToPoint: CGPointMake(1.5, 8.96)];
    [bezierPath addLineToPoint: CGPointMake(1.5, 8.96)];
    [bezierPath addCurveToPoint: CGPointMake(3.47, 5.53) controlPoint1: CGPointMake(1.5, 7.55) controlPoint2: CGPointMake(2.25, 6.24)];
    [bezierPath addLineToPoint: CGPointMake(11.97, 0.55)];
    [bezierPath addLineToPoint: CGPointMake(11.97, 0.55)];
    [bezierPath addCurveToPoint: CGPointMake(16.03, 0.55) controlPoint1: CGPointMake(13.23, -0.18) controlPoint2: CGPointMake(14.77, -0.18)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    CGContextRestoreGState(context);
    
}

+ (void)drawSpaceFocusWithColor: (UIColor*)color
{
    [WireStyleKit drawSpaceFocusWithFrame: CGRectMake(0, 0, 36, 36) resizing: WireStyleKitResizingBehaviorStretch color: color];
}

+ (void)drawSpaceFocusWithFrame: (CGRect)targetFrame resizing: (WireStyleKitResizingBehavior)resizing color: (UIColor*)color
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Resize to Target Frame
    CGContextSaveGState(context);
    CGRect resizedFrame = WireStyleKitResizingBehaviorApply(resizing, CGRectMake(0, 0, 36, 36), targetFrame);
    CGContextTranslateCTM(context, resizedFrame.origin.x, resizedFrame.origin.y);
    CGContextScaleCTM(context, resizedFrame.size.width / 36, resizedFrame.size.height / 36);
    
    
    //// Bezier Drawing
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
    [bezierPath moveToPoint: CGPointMake(20.45, 2.65)];
    [bezierPath addCurveToPoint: CGPointMake(15.55, 2.65) controlPoint1: CGPointMake(18.93, 1.79) controlPoint2: CGPointMake(17.07, 1.79)];
    [bezierPath addLineToPoint: CGPointMake(6.05, 8)];
    [bezierPath addCurveToPoint: CGPointMake(3.5, 12.36) controlPoint1: CGPointMake(4.47, 8.88) controlPoint2: CGPointMake(3.5, 10.55)];
    [bezierPath addLineToPoint: CGPointMake(3.5, 23.64)];
    [bezierPath addCurveToPoint: CGPointMake(6.04, 28) controlPoint1: CGPointMake(3.5, 25.45) controlPoint2: CGPointMake(4.47, 27.11)];
    [bezierPath addLineToPoint: CGPointMake(15.54, 33.36)];
    [bezierPath addCurveToPoint: CGPointMake(20.46, 33.36) controlPoint1: CGPointMake(17.07, 34.22) controlPoint2: CGPointMake(18.93, 34.22)];
    [bezierPath addLineToPoint: CGPointMake(29.96, 28)];
    [bezierPath addCurveToPoint: CGPointMake(32.5, 23.64) controlPoint1: CGPointMake(31.53, 27.11) controlPoint2: CGPointMake(32.5, 25.45)];
    [bezierPath addLineToPoint: CGPointMake(32.5, 12.36)];
    [bezierPath addCurveToPoint: CGPointMake(29.95, 8) controlPoint1: CGPointMake(32.5, 10.55) controlPoint2: CGPointMake(31.53, 8.88)];
    [bezierPath addLineToPoint: CGPointMake(20.45, 2.65)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    CGContextRestoreGState(context);
    
}

+ (void)drawRestoreWithColor: (UIColor*)color
{
    [WireStyleKit drawRestoreWithFrame: CGRectMake(0, 0, 48, 48) resizing: WireStyleKitResizingBehaviorStretch color: color];
}

+ (void)drawRestoreWithFrame: (CGRect)targetFrame resizing: (WireStyleKitResizingBehavior)resizing color: (UIColor*)color
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Resize to Target Frame
    CGContextSaveGState(context);
    CGRect resizedFrame = WireStyleKitResizingBehaviorApply(resizing, CGRectMake(0, 0, 48, 48), targetFrame);
    CGContextTranslateCTM(context, resizedFrame.origin.x, resizedFrame.origin.y);
    CGContextScaleCTM(context, resizedFrame.size.width / 48, resizedFrame.size.height / 48);
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0.08, 26)];
    [bezierPath addLineToPoint: CGPointMake(4.1, 26)];
    [bezierPath addCurveToPoint: CGPointMake(24, 44) controlPoint1: CGPointMake(5.1, 36.11) controlPoint2: CGPointMake(13.63, 44)];
    [bezierPath addCurveToPoint: CGPointMake(44, 24) controlPoint1: CGPointMake(35.05, 44) controlPoint2: CGPointMake(44, 35.05)];
    [bezierPath addCurveToPoint: CGPointMake(24, 4) controlPoint1: CGPointMake(44, 12.95) controlPoint2: CGPointMake(35.05, 4)];
    [bezierPath addCurveToPoint: CGPointMake(7.18, 13.18) controlPoint1: CGPointMake(16.94, 4) controlPoint2: CGPointMake(10.74, 7.66)];
    [bezierPath addLineToPoint: CGPointMake(12, 18)];
    [bezierPath addLineToPoint: CGPointMake(0, 18)];
    [bezierPath addLineToPoint: CGPointMake(0, 6)];
    [bezierPath addLineToPoint: CGPointMake(4.3, 10.3)];
    [bezierPath addCurveToPoint: CGPointMake(24, 0) controlPoint1: CGPointMake(8.63, 4.07) controlPoint2: CGPointMake(15.84, 0)];
    [bezierPath addCurveToPoint: CGPointMake(48, 24) controlPoint1: CGPointMake(37.25, 0) controlPoint2: CGPointMake(48, 10.75)];
    [bezierPath addCurveToPoint: CGPointMake(24, 48) controlPoint1: CGPointMake(48, 37.25) controlPoint2: CGPointMake(37.25, 48)];
    [bezierPath addCurveToPoint: CGPointMake(0.08, 26) controlPoint1: CGPointMake(11.42, 48) controlPoint2: CGPointMake(1.1, 38.32)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(26, 23.69)];
    [bezierPath addLineToPoint: CGPointMake(34.39, 28.54)];
    [bezierPath addLineToPoint: CGPointMake(32.39, 32)];
    [bezierPath addLineToPoint: CGPointMake(22, 26)];
    [bezierPath addLineToPoint: CGPointMake(22, 10)];
    [bezierPath addLineToPoint: CGPointMake(26, 10)];
    [bezierPath addLineToPoint: CGPointMake(26, 23.69)];
    [bezierPath closePath];
    bezierPath.usesEvenOddFillRule = YES;
    [color setFill];
    [bezierPath fill];
    
    CGContextRestoreGState(context);
    
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

+ (UIImage*)imageOfIcon_0x222_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x222_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x222_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x222_32pt;
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

+ (UIImage*)imageOfIcon_0x262_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x262_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x262_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x262_32pt;
}

+ (UIImage*)imageOfIcon_0x263_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x263_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x263_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x263_32pt;
}

+ (UIImage*)imageOfIcon_0x264_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x264_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x264_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x264_32pt;
}

+ (UIImage*)imageOfIcon_0x265_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x265_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x265_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x265_32pt;
}

+ (UIImage*)imageOfIcon_0x266_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x266_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x266_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x266_32pt;
}

+ (UIImage*)imageOfIcon_0x267_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x267_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x267_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x267_32pt;
}

+ (UIImage*)imageOfIcon_0x268_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x268_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x268_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x268_32pt;
}

+ (UIImage*)imageOfIcon_0x738_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x738_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x738_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x738_32pt;
}

+ (UIImage*)imageOfIcon_0x739_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x739_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x739_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x739_32pt;
}

+ (UIImage*)imageOfIcon_0x740_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x740_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x740_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x740_32pt;
}

+ (UIImage*)imageOfIcon_0x741_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x741_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x741_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x741_32pt;
}

+ (UIImage*)imageOfIcon_0x742_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x742_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x742_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x742_32pt;
}

+ (UIImage*)imageOfIcon_0x743_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x743_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x743_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x743_32pt;
}

+ (UIImage*)imageOfIcon_0x744_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x744_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x744_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x744_32pt;
}

+ (UIImage*)imageOfIcon_0x745_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x745_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x745_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x745_32pt;
}

+ (UIImage*)imageOfIcon_0x746_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x746_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x746_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x746_32pt;
}

+ (UIImage*)imageOfIcon_0x747_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x747_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x747_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x747_32pt;
}

+ (UIImage*)imageOfIcon_0x269_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x269_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x269_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x269_32pt;
}

+ (UIImage*)imageOfIcon_0x748_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x748_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x748_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x748_32pt;
}

+ (UIImage*)imageOfIcon_0x749_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x749_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x749_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x749_32pt;
}

+ (UIImage*)imageOfIcon_0x750_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x750_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x750_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x750_32pt;
}

+ (UIImage*)imageOfIcon_0x751_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x751_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x751_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x751_32pt;
}

+ (UIImage*)imageOfIcon_0x752_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x752_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x752_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x752_32pt;
}

+ (UIImage*)imageOfIcon_0x753_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x753_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x753_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x753_32pt;
}

+ (UIImage*)imageOfIcon_0x754_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x754_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x754_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x754_32pt;
}

+ (UIImage*)imageOfIcon_0x755_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x755_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x755_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x755_32pt;
}

+ (UIImage*)imageOfIcon_0x756_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x756_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x756_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x756_32pt;
}

+ (UIImage*)imageOfIcon_0x757_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x757_32ptWithColor: color];
    
    UIImage* imageOfIcon_0x757_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfIcon_0x757_32pt;
}

+ (UIImage*)imageOfWeekWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawWeekWithColor: color];
    
    UIImage* imageOfWeek = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfWeek;
}

+ (UIImage*)imageOfMonthWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawMonthWithColor: color];
    
    UIImage* imageOfMonth = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfMonth;
}

+ (UIImage*)imageOfYearWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawYearWithColor: color];
    
    UIImage* imageOfYear = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfYear;
}

+ (UIImage*)imageOfIcon_0x758_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x758_32ptWithColor: color];

    UIImage* imageOfIcon_0x758_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x758_32pt;
}

+ (UIImage*)imageOfIcon_0x759_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x759_32ptWithColor: color];

    UIImage* imageOfIcon_0x759_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x759_32pt;
}

+ (UIImage*)imageOfIcon_0x760_32ptWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), NO, 0);
    [WireStyleKit drawIcon_0x760_32ptWithColor: color];

    UIImage* imageOfIcon_0x760_32pt = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfIcon_0x760_32pt;
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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(72, 16), NO, 0);
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

+ (UIImage*)imageOfShieldWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(300, 388), NO, 0);
    [WireStyleKit drawShieldWithColor: color];
    
    UIImage* imageOfShield = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfShield;
}

+ (UIImage*)imageOfSpaceFocusWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0);
    [WireStyleKit drawSpaceFocusWithColor: color];
    
    UIImage* imageOfSpaceFocus = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfSpaceFocus;
}

+ (UIImage*)imageOfRestoreWithColor: (UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(48, 48), NO, 0);
    [WireStyleKit drawRestoreWithColor: color];
    
    UIImage* imageOfRestore = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfRestore;
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



CGRect WireStyleKitResizingBehaviorApply(WireStyleKitResizingBehavior behavior, CGRect rect, CGRect target)
{
    if (CGRectEqualToRect(rect, target) || CGRectEqualToRect(target, CGRectZero))
        return rect;
    
    CGSize scales = CGSizeZero;
    scales.width = ABS(target.size.width / rect.size.width);
    scales.height = ABS(target.size.height / rect.size.height);
    
    switch (behavior)
    {
        case WireStyleKitResizingBehaviorAspectFit:
        {
            scales.width = MIN(scales.width, scales.height);
            scales.height = scales.width;
            break;
        }
        case WireStyleKitResizingBehaviorAspectFill:
        {
            scales.width = MAX(scales.width, scales.height);
            scales.height = scales.width;
            break;
        }
        case WireStyleKitResizingBehaviorStretch:
            break;
        case WireStyleKitResizingBehaviorCenter:
        {
            scales.width = 1;
            scales.height = 1;
            break;
        }
    }
    
    CGRect result = CGRectStandardize(rect);
    result.size.width *= scales.width;
    result.size.height *= scales.height;
    result.origin.x = target.origin.x + (target.size.width - result.size.width) / 2;
    result.origin.y = target.origin.y + (target.size.height - result.size.height) / 2;
    return result;
}
