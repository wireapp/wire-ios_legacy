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


#import "UIImage+ImageUtilities.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>


@implementation UIImage (ImageUtilities)

- (UIImage *)imageScaledWithFactor:(CGFloat)scaleFactor
{
    CGSize size = CGSizeApplyAffineTransform(self.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    CGFloat scale = 0; // Automatically use scale factor of main screens
    BOOL hasAlpha = NO;
    
    UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

+ (UIImage *)desaturatedImageFromData:(NSData *)data
                          withContext:(CIContext *)context
                           saturation:(NSNumber *)saturation
{
    CIImage *i = [CIImage imageWithData:data];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:i forKey:kCIInputImageKey];
    [filter setValue:saturation forKey:@"InputSaturation"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *processed = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    
    return processed;
}

- (UIImage *)desaturatedImageWithContext:(CIContext *)context saturation:(NSNumber *)saturation
{
    CIImage *i = [CIImage imageWithCGImage:[self CGImage]];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:i forKey:kCIInputImageKey];
    [filter setValue:saturation forKey:@"InputSaturation"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *processed = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(cgImage);
    
    return processed;
}

- (UIImage *)blurredAutoEnhancedImageWithContext:(CIContext *)context
                                      blurRadius:(CGFloat)radius
{
    CIImage *outputImage = [CIImage imageWithCGImage:[self CGImage]];
    
    NSArray *adjustments = [outputImage autoAdjustmentFiltersWithOptions:@{kCIImageAutoAdjustRedEye : @(NO)}];
    for (CIFilter *filter in adjustments) {
        [filter setValue:outputImage forKey:kCIInputImageKey];
        outputImage = filter.outputImage;
    }
    
    CGRect extent = outputImage.extent;
    // Clamp
    CIFilter * clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setDefaults];
    [clampFilter setValue:[NSValue valueWithBytes:&CGAffineTransformIdentity
                                         objCType:@encode(CGAffineTransform)]
                   forKey:kCIInputTransformKey];
    
    [clampFilter setValue:outputImage forKey:kCIInputImageKey];
    outputImage = [clampFilter outputImage];
    
    // Blur
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@(radius) forKey:kCIInputRadiusKey];
    [blurFilter setValue:outputImage forKey:kCIInputImageKey];
    outputImage = blurFilter.outputImage;
    
    CIImage *result = [outputImage imageByCroppingToRect:extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *processed = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(cgImage);
    
    return processed;
}

- (UIImage *)blurredImageWithContext:(CIContext *)context
                          blurRadius:(CGFloat)radius
{
    CIImage *outputImage = [CIImage imageWithCGImage:[self CGImage]];
    
    CGRect extent = outputImage.extent;
    
    // Blur
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@(radius) forKey:kCIInputRadiusKey];
    [blurFilter setValue:outputImage forKey:kCIInputImageKey];
    outputImage = blurFilter.outputImage;
    
    CIImage *result = [outputImage imageByCroppingToRect:extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *processed = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(cgImage);
    
    return processed;
}

- (UIImage *)blurredImageWithContext:(CIContext *)context
                          blurRadius:(CGFloat)radius
                          saturation:(CGFloat)saturation
                          brightness:(CGFloat)brightness
                            contrast:(CGFloat)contrast
{
    CIImage *i = [CIImage imageWithCGImage:[self CGImage]];
    
    CGRect extent = i.extent;
    
    // Clamp
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setDefaults];
    [clampFilter setValue:[NSValue valueWithBytes:&CGAffineTransformIdentity
                                         objCType:@encode(CGAffineTransform)]
                   forKey:kCIInputTransformKey];
    [clampFilter setValue:i forKey:kCIInputImageKey];

    // Saturate
    CIFilter *saturationFilter = [CIFilter filterWithName:@"CIColorControls"];
    [saturationFilter setValue:[clampFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [saturationFilter setValue:@(saturation) forKey:kCIInputSaturationKey];
    [saturationFilter setValue:@(brightness) forKey:kCIInputBrightnessKey];
    [saturationFilter setValue:@(contrast) forKey:kCIInputContrastKey];

    // Blur
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@(radius) forKey:kCIInputRadiusKey];
    [blurFilter setValue:[saturationFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    
    CIImage *result = [[blurFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:extent];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *processed = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(cgImage);
    
    return processed;
}

- (instancetype)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, 0.0f, 0.0f);
    
    [self drawInRect:rect];
    [color setFill];
    UIRectFillUsingBlendMode(rect, kCGBlendModeSourceAtop);
    
    UIImage * colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return colorImage;
}

- (UIImage *)imageWithInsets:(UIEdgeInsets)insets backgroundColor:(UIColor *)backgroundColor
{
    CGSize newSize = CGSizeMake(self.size.width + insets.left + insets.right, self.size.height + insets.top + insets.bottom);
    
    UIGraphicsBeginImageContextWithOptions(newSize, 0.0f, 0.0f);
    
    [backgroundColor setFill];
    UIRectFill(CGRectMake(0, 0, newSize.width, newSize.height));
    [self drawInRect:CGRectMake(insets.left, insets.top, self.size.width, self.size.height)];
    
    UIImage * colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return colorImage;
}

+ (UIImage *)singlePixelImageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)shadowImageWithInset:(CGFloat)inset color:(UIColor *)color
{
    const CGFloat middleSize = 10.0f;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, ceilf(inset * 2.0f + middleSize), 1.0f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, CGRectMake(inset, 0, middleSize, 1.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)deviceOptimizedImageFromData:(NSData *)imageData
{
    return [self imageFromData:imageData withMaxSize:[UIScreen mainScreen].nativeBounds.size.height];
}

+ (UIImage *)imageFromData:(NSData *)imageData withMaxSize:(CGFloat)maxSize
{
    if (! imageData) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    if (source == NULL) {
        return nil;
    }
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                         (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                                         (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                         (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                                                         (id)[NSNumber numberWithFloat:maxSize], (id)kCGImageSourceThumbnailMaxPixelSize,
                                                         nil];
    
    
    CGImageRef scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (CFDictionaryRef)options);
    if (scaledImage == NULL) {
        CFRelease(source);
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:scaledImage scale:2.0 orientation:UIImageOrientationUp];
    
    CFRelease(source);
    CFRelease(scaledImage);
    
    return image;
}

+ (UIImage *)imageVignetteForRect:(CGRect)rect ontoImage:(UIImage *)image showingImageUnderneath:(BOOL)showingImageUnderneath startColor:(UIColor *)vignetteStartColor endColor:(UIColor *)vignetteEndColor colorLocation:(CGFloat)middleColorLocation radiusMultiplier:(CGFloat)vignetteRadiusMultiplier
{    
    // begin
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(image.size.width, image.size.height), NO, image.scale);
    
    // draw image
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    
    // flip the drawing context
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, image.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, - 1.0);
    
    // darken mode for the overlays
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDarken);
    
    // draw the flat overlay
    
    // radial gradient
    CGFloat colorLocations[3];
    colorLocations[0] = 0.0;
    colorLocations[1] = middleColorLocation;
    colorLocations[2] = 1.0;
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef gradient = CGGradientCreateWithColors(rgb,
                                                        (__bridge CFArrayRef) @[
                                                                                (id) vignetteStartColor.CGColor,
                                                                                (id) vignetteStartColor.CGColor,
                                                                                (id) vignetteEndColor.CGColor
                                                                                ], // colors
                                                        colorLocations); // color locations array
    
    CGPoint faceCenter = CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
    
    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), // context
                                gradient, // gradient spec
                                faceCenter, // start center point
                                0.0f, // start radius
                                faceCenter, // end center
                                vignetteRadiusMultiplier * sqrt((pow(rect.size.width / 2, 2)) * 2), // end radius
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgb);
    
    // wrap up
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;
}

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
