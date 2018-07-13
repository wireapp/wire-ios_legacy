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
    
    CFDictionaryRef options = [self thumbnailOptionsWithMaxSize:maxSize];
    
    CGImageRef scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options);
    if (scaledImage == NULL) {
        CFRelease(source);
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:scaledImage scale:2.0 orientation:UIImageOrientationUp];
    
    CFRelease(source);
    CFRelease(scaledImage);
    
    return image;
}

+ (CFDictionaryRef)thumbnailOptionsWithMaxSize:(CGFloat)maxSize
{
    return (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                      (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                      (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
                                      (id)[NSNumber numberWithFloat:maxSize], (id)kCGImageSourceThumbnailMaxPixelSize,
                                      nil];
}

+ (UIImage *)imageFromData:(NSData *)imageData withShorterSideLength:(CGFloat)shorterSideLength
{
    if (! imageData) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    if (source == NULL) {
        return nil;
    }
    
    const CGSize size = [self sizeForImageSource:source];
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }

    CGFloat longSideLength = shorterSideLength;

    if (size.width > size.height) {
        longSideLength = shorterSideLength * (size.width / size.height);
    } else if (size.height > size.width) {
        longSideLength = shorterSideLength * (size.height / size.width);
    }
    
    CFDictionaryRef options = [self thumbnailOptionsWithMaxSize:longSideLength];
    
    CGImageRef scaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options);
    if (scaledImage == NULL) {
        CFRelease(source);
        return nil;
    }
    
    UIImage *image = [UIImage imageWithCGImage:scaledImage scale:2.0 orientation:UIImageOrientationUp];
    CFRelease(source);
    CFRelease(scaledImage);
    
    return image;
}

+ (CGSize)sizeForImageSource:(CGImageSourceRef)source
{
    CGSize size = CGSizeZero;
    
    if (!source) {
        return size;
    }
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)@{ (id)kCGImageSourceShouldCache: (id)kCFBooleanTrue };
    NSDictionary *properties = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, options);
    
    if (!properties) {
        return size;
    }

    NSNumber *width = [properties objectForKey:(NSString *)kCGImagePropertyPixelWidth];
    NSNumber *height = [properties objectForKey:(NSString *)kCGImagePropertyPixelHeight];
    
    if (nil != height && nil != width) {
        size = CGSizeMake(width.floatValue, height.floatValue);
    }

    return size;
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
