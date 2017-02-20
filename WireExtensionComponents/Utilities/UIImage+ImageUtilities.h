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


#import <UIKit/UIKit.h>

@interface UIImage (ImageUtilities)

- (UIImage *)imageScaledWithFactor:(CGFloat)scaleFactor;

+ (UIImage *)desaturatedImageFromData:(NSData *)data
                          withContext:(CIContext *)context
                           saturation:(NSNumber *)saturation;
- (UIImage *)desaturatedImageWithContext:(CIContext *)context saturation:(NSNumber *)saturation;

- (UIImage *)blurredAutoEnhancedImageWithContext:(CIContext *)context
                                      blurRadius:(CGFloat)radius;

- (UIImage *)blurredImageWithContext:(CIContext *)context
                          blurRadius:(CGFloat)radius;

- (UIImage *)blurredImageWithContext:(CIContext *)context
                          blurRadius:(CGFloat)radius
                          saturation:(CGFloat)saturation
                          brightness:(CGFloat)brightness
                            contrast:(CGFloat)contrast;

- (instancetype)imageWithColor:(UIColor *)color;

- (UIImage *)imageWithInsets:(UIEdgeInsets)insets backgroundColor:(UIColor *)backgroundColor;

+ (UIImage *)singlePixelImageWithColor:(UIColor *)color;
+ (UIImage *)shadowImageWithInset:(CGFloat)inset color:(UIColor *)color;
+ (UIImage *)deviceOptimizedImageFromData:(NSData *)imageData;
+ (UIImage *)imageFromData:(NSData *)imageData withMaxSize:(CGFloat)maxSize;

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;

/// Draw a vignette. Use different gradient settings depending on if a photo is being shown underneath the vignette or not
+ (UIImage *)imageVignetteForRect:(CGRect)rect ontoImage:(UIImage *)image showingImageUnderneath:(BOOL)showingImageUnderneath startColor:(UIColor *)vignetteStartColor endColor:(UIColor *)vignetteEndColor colorLocation:(CGFloat)middleColorLocation radiusMultiplier:(CGFloat)vignetteRadiusMultiplier;

@end

