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


@import CoreGraphics;
@import ImageIO;
@import WireSystem;

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif

#import "ZMImageDownsampleOperation.h"
#import "ZMImageLoadOperation.h"
#import <WireImages/WireImages-Swift.h>

static const NSUInteger MaximumGIFImageByteCount = 5 * 1024 * 1024;
static const double DownsampleResizeThreshold = 1.2;
static const int TiffOrientationCorrect = 1;
static const int TiffOrientationNotSet = 0;
static const double ScaleFudgeFactor = 1.3; ///< We will not require scaling if the image is within 30% of the target size

static BOOL isFormatKindOfFormat(NSString *format1, CFStringRef format2) {
    return (BOOL) UTTypeConformsTo((__bridge CFStringRef) format1, format2);
}
static CGContextRef createBitmapContext(size_t width, size_t height);
static void bitmapContextReleaseData(void *releaseInfo, void *data);




@interface ZMImageDownsampleOperation ()

@property (nonatomic) ZMImageLoadOperation *loadOperation;
@property (nonatomic, copy) NSData *downsampleImageData;
@property (nonatomic) ZMImageDownsampleType downsampleType;
@property (nonatomic) NSString *imageFormat;
@property (nonatomic) ZMImageFormat format;
@property (nonatomic) ZMIImageProperties *properties;

@end



@implementation ZMImageDownsampleOperation

+ (ZMImageDownsampleType)downsampleTypeForImageFormat:(ZMImageFormat)format
{
    switch (format) {
        case ZMImageFormatPreview:
            return ZMImageDownsampleTypePreview;
            break;
            
        case ZMImageFormatMedium:
            return ZMImageDownsampleTypeMedium;
            break;
            
        case ZMImageFormatProfile:
            return ZMImageDownsampleTypeSmallProfile;
            break;
            
        case ZMImageFormatInvalid:
        case ZMImageFormatOriginal:
        default:
            RequireString(NO, "Unknown image format for downsampling: %ld", (long)format);
            break;
    }
    
    return ZMImageDownsampleTypeInvalid;
}

+ (ZMImageFormat)imageFormatForDownsampleType:(ZMImageDownsampleType)format
{
    switch (format) {
        case ZMImageDownsampleTypePreview:
            return ZMImageFormatPreview;
            break;
            
        case ZMImageDownsampleTypeMedium:
            return ZMImageFormatMedium;
            break;
            
        case ZMImageDownsampleTypeSmallProfile:
            return ZMImageFormatProfile;
            break;
            
        case ZMImageDownsampleTypeInvalid:
        default:
            RequireString(NO, "Unknown image format for downsampling: %ld", (long)format);
            break;
    }
    
    return ZMImageFormatInvalid;
}

- (instancetype)initWithLoadOperation:(ZMImageLoadOperation *)loadOperation downsampleType:(ZMImageDownsampleType)downsampleType;
{
    self = [super init];
    if (self) {
        self.loadOperation = loadOperation;
        if (self.loadOperation == nil) {
            return nil;
        }
        [self addDependency:self.loadOperation];
        self.downsampleType = downsampleType;
        self.format = [ZMImageDownsampleOperation imageFormatForDownsampleType:downsampleType];
    }
    return self;
}

- (instancetype)initWithLoadOperation:(ZMImageLoadOperation *)loadOperation format:(ZMImageFormat)format;
{
    self = [self initWithLoadOperation:loadOperation downsampleType:[ZMImageDownsampleOperation downsampleTypeForImageFormat:format]];
    if (self) {
        self.format = format;
    }
    return self;
}

- (NSString *)description
{
    NSString *typeName = @"Invalid";
    switch (self.downsampleType) {
        case ZMImageDownsampleTypePreview:
            typeName = @"Preview";
            break;
        case ZMImageDownsampleTypeMedium:
            typeName = @"Medium";
            break;
        case ZMImageDownsampleTypeSmallProfile:
            typeName = @"SmallProfile";
            break;
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    return [NSString stringWithFormat:@"<%@: %p> \"%@\" input: %@",
            self.class, self,
            typeName,
            self.loadOperation.inputDescription];
}

- (void)main
{
    self.imageFormat = self.loadOperation.computedImageProperties.mimeType;
    
    if (self.isCancelled || (self.loadOperation.CGImage == NULL)) {
        return;
    }

    const CGImageRef image = self.forceSquare ? [self squareImage] : [self rotatedImage];
    CGSize imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));

    NSString *mimeType = self.loadOperation.computedImageProperties.mimeType;
    if ([self shouldScale:image]) {
        imageSize = [self scaleImage:image];
    }
    else if([self originalImageByteSizeTooBig])
    {
        mimeType = [self recompressImage:image];
    }
    if (self.downsampleImageData == nil) {
        if(image == self.loadOperation.CGImage) {
            self.downsampleImageData = self.loadOperation.originalImageData;
        }
        else {
            self.downsampleImageData = [self createCompressImageDataFromImage:image format:self.loadOperation.computedImageProperties.mimeType];
        }
    }
    
    self.properties = [self createImagePropertiesWithUti:mimeType imageSize:imageSize];

    CGImageRelease(image);
}

- (CGSize)scaleImage:(CGImageRef)image
{
    const CGSize originalSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    const CGSize finalSize = [self finalSizeForOriginalSize:originalSize];
    CGImageRef scaledImage = [self scaleImage:image toSize:finalSize];
    
    NSString *format = self.forceLossy ? (id)kUTTypeJPEG : self.formatForScaling;
    
    self.downsampleImageData = [self createCompressImageDataFromImage:scaledImage format:format];
    self.imageFormat = format;
    CGImageRelease(scaledImage);
    return finalSize;
}

- (BOOL)originalImageByteSizeTooBig
{
    const BOOL isGif = isFormatKindOfFormat(self.imageFormat, kUTTypeGIF);
    if (isGif) {
        return (self.loadOperation.originalImageData.length > MaximumGIFImageByteCount);
    } else {
        return (self.loadOperation.originalImageData.length > self.targetByteCount);
    }
}

/// Recompress image and returns new kUTType
- (NSString*)recompressImage:(CGImageRef)image
{
    // Try to recompress it to see if that helps:
    NSString *format = self.forceLossy ? (id)kUTTypeJPEG : self.loadOperation.computedImageProperties.mimeType;
    NSData *compressedData = [self createCompressImageDataFromImage:image format:format];
    
    NSString *finalFormat = format;
    // too big? if not JPEG...
    if(! isFormatKindOfFormat(format, kUTTypeJPEG) && compressedData.length > self.targetByteCount)
    {
        // Force JPEG:
        compressedData = [self createCompressImageDataFromImage:image format:(__bridge id)kUTTypeJPEG];
        finalFormat = (__bridge NSString *)kUTTypeJPEG;
    }
    
    // did I not achieve any sensible compression?
    if (compressedData.length * DownsampleResizeThreshold < self.loadOperation.originalImageData.length)
    {
        // not worth compressing, use original
        self.downsampleImageData = compressedData;
        finalFormat = format;
    }
    return finalFormat;
}

- (BOOL)shouldScale:(CGImageRef)image
{
    const CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    BOOL const oneSideIsToLong = ((size.width > ScaleFudgeFactor * self.targetDimension) || (size.height > ScaleFudgeFactor * self.targetDimension));
    double const MaxPixelCount = ScaleFudgeFactor * self.targetDimension * self.targetDimension;
    BOOL const pixelCountIsTooBig = (size.width * size.height > MaxPixelCount);
    return (oneSideIsToLong && pixelCountIsTooBig);
}

- (NSUInteger)targetByteCount
{
    switch (self.downsampleType) {
        case ZMImageDownsampleTypeMedium:
            return 310 * 1024;
        case ZMImageDownsampleTypePreview:
            return 1024;
        case ZMImageDownsampleTypeSmallProfile:
            return 1024 * 1024; // Don't care about this
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    VerifyActionString(NO, return 0, "Invalid downsample type");
}


- (NSUInteger)targetDimension
{
    switch (self.downsampleType) {
        case ZMImageDownsampleTypeMedium:
            return 1448;
        case ZMImageDownsampleTypePreview:
            return 30;
        case ZMImageDownsampleTypeSmallProfile:
            return 280;
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    VerifyActionString(NO, return 0, "Invalid downsample type");
}

- (double)compressionQuality;
{
    switch (self.downsampleType) {
        case ZMImageDownsampleTypeMedium:
            return 0.45;
        case ZMImageDownsampleTypePreview:
            return 0;
        case ZMImageDownsampleTypeSmallProfile:
            return 0.7;
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    VerifyActionString(NO, return 0, "Invalid downsample type");
}


- (NSDictionary *)outputProperties
{
    NSMutableDictionary *properties = nil;
    if (self.downsampleType == ZMImageDownsampleTypeMedium) {
        properties = [NSMutableDictionary dictionaryWithDictionary:self.loadOperation.sourceImageProperties];
    }
    else if (self.downsampleType == ZMImageDownsampleTypePreview) {
        properties = [self justOrientationExifProperties];
    }
    

    if ((self.loadOperation.tiffOrientation != TiffOrientationCorrect) &&
        (self.loadOperation.tiffOrientation != TiffOrientationNotSet))
    {
        properties[(__bridge id) kCGImagePropertyOrientation] = @(TiffOrientationCorrect);
        if (properties[(__bridge id) kCGImagePropertyTIFFDictionary]) {
            NSMutableDictionary *tiffDictionary = [NSMutableDictionary dictionaryWithDictionary:properties[(__bridge id) kCGImagePropertyTIFFDictionary]];
            tiffDictionary[(__bridge id) kCGImagePropertyTIFFOrientation] = @(TiffOrientationCorrect);
            properties[(__bridge id) kCGImagePropertyTIFFDictionary] = tiffDictionary;
        }
    }
    properties[(__bridge id) kCGImageDestinationLossyCompressionQuality] = @(self.compressionQuality);
    return properties;
}


- (NSMutableDictionary *)justOrientationExifProperties
{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    NSNumber *orientation = self.loadOperation.sourceImageProperties[(__bridge id) kCGImagePropertyTIFFDictionary][(__bridge id) kCGImagePropertyTIFFOrientation];
    if (orientation != nil) {
        NSMutableDictionary *tiffDict = [NSMutableDictionary dictionary];
        tiffDict[(__bridge id) kCGImagePropertyTIFFOrientation] = orientation;
        properties[(__bridge id) kCGImagePropertyTIFFDictionary] = tiffDict;
    }
    return properties;
}

- (NSData *)createCompressImageDataFromImage:(CGImageRef)image format:(NSString *)format
{
    NSData *result = nil;
    NSMutableData *data = [NSMutableData dataWithCapacity:(NSUInteger) llround(self.targetByteCount * 1.5)];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) data, (__bridge CFStringRef) format, 1, NULL);
    if (dest != NULL) {
        CGImageDestinationAddImage(dest, image, (__bridge CFDictionaryRef) self.outputProperties);
        if (CGImageDestinationFinalize(dest)) {
            result = data;
        }
        CFRelease(dest);
    }
    return result;
}

- (NSString *)formatForScaling
{
    return (__bridge id)kUTTypeJPEG;
}

- (BOOL)forceLossy
{
    switch (self.downsampleType) {
        case ZMImageDownsampleTypeMedium:
            return NO;
        case ZMImageDownsampleTypeSmallProfile:
        case ZMImageDownsampleTypePreview:
            return YES;
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    VerifyActionString(NO, return NO, "Invalid downsample type");
}

- (BOOL)forceSquare
{
    switch (self.downsampleType) {
        case ZMImageDownsampleTypeSmallProfile:
            return YES;
        case ZMImageDownsampleTypeMedium:
        case ZMImageDownsampleTypePreview:
            return NO;
        case ZMImageDownsampleTypeInvalid:
            break;
    }
    VerifyActionString(NO, return NO, "Invalid downsample type");
}

- (CGImageRef)squareImage CF_RETURNS_RETAINED
{
    CGImageRef const image = [self rotatedImage];
    
    CGSize const imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    CGFloat const shortestSide = (CGFloat) fmin(imageSize.width,
                                      imageSize.height);
    CGFloat const width = (CGFloat) floor(fmin(self.targetDimension, shortestSide));
    
    CGContextRef context = createBitmapContext((size_t) width, (size_t) width);
    
    CGFloat const scale = ((CGFloat) width) / ((CGFloat) shortestSide);
    
    CGRect r = CGRectMake(0,
                          0,
                          scale * imageSize.width,
                          scale * imageSize.height);
    if (imageSize.width < imageSize.height) {
        r.origin.y = (CGFloat) (- (imageSize.height - imageSize.width) * scale * 0.5);
    } else {
        r.origin.x = (CGFloat) (- (imageSize.width - imageSize.height) * scale * 0.5);
    }
    
    CGContextDrawImage(context, r, image);
    CGContextFlush(context);
    CGImageRef result = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CFRelease(image);
    
    return result;
}

- (CGImageRef)rotatedImage CF_RETURNS_RETAINED
{
    CGImageRef image = [self.loadOperation CGImage];
    int orientation = [self.loadOperation tiffOrientation];
    
    if ((orientation == TiffOrientationCorrect) ||
        (orientation == TiffOrientationNotSet))
    {
        return CGImageRetain(image);
    }

    CGImageRef i = [self rotateImageWithEXIF:image orientation:orientation];
    return i;
}

- (CGSize)finalSizeForOriginalSize:(CGSize)originalSize
{
    VerifyReturnValue(originalSize.width > 0 && originalSize.height > 0, CGSizeMake(1, 1));
    
    double const scale1 = fmax(self.targetDimension / (double) originalSize.width,
                                   self.targetDimension / (double) originalSize.height);
    double const scale2 = self.targetDimension / sqrt(originalSize.width * originalSize.height);
    double const scale =  (isfinite(scale2) && (scale2 < scale1)) ? 0.5 * (scale2 + scale1) : scale1;
    CGSize result = CGSizeZero;
    result.width = (CGFloat) ceil(scale * originalSize.width);
    result.height = (CGFloat) round(result.width / originalSize.width * originalSize.height);
    return result;
}


- (CGImageRef)scaleImage:(CGImageRef)image toSize:(CGSize)finalSize CF_RETURNS_RETAINED
{
	CGContextRef ctx = createBitmapContext((size_t) finalSize.width, (size_t) finalSize.height);
	CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
	if (image != NULL) {
		CGContextDrawImage(ctx, CGRectMake(0, 0, finalSize.width, finalSize.height), image);
	}
	CGImageRef result = CGBitmapContextCreateImage(ctx);
	CFRelease(ctx);
    return result;
}

- (CGImageRef)rotateImageWithEXIF:(CGImageRef)source orientation:(int) orientation CF_RETURNS_RETAINED
{
    switch (orientation)
    {
        case 2:
            return [self rotateImageWithFlip:source angle:0 flipX:YES flipY:NO];
            break;
        case 3:
            return [self rotateImageWithFlip:source angle:0 flipX:YES flipY:YES];
            break;
        case 4:
            return [self rotateImageWithFlip:source angle:0 flipX:NO flipY:YES];
            break;
            
        case 5:
            return [self rotateImageWithFlip:source angle:90 flipX:NO flipY:YES];
            break;
        case 6:
            return [self rotateImageWithFlip:source angle:-90 flipX:NO flipY:NO];
            break;
            
        case 7:
            return [self rotateImageWithFlip:source angle:90 flipX:YES flipY:NO];
            break;
        case 8:
            return [self rotateImageWithFlip:source angle:-90 flipX:YES flipY:YES];
            break;
            
        default:
            break;
    }
    
    return NULL;
}

static inline double radians (double degrees) { return degrees * M_PI/180; }

- (CGImageRef)rotateImageWithFlip:(CGImageRef)source angle:(float)angle flipX:(BOOL)flipX flipY:(BOOL)flipY CF_RETURNS_RETAINED
{
    double fX    =  fabs ( cos ( radians ( angle ) ) );
    double fY    =  fabs ( sin ( radians ( angle ) ) );
    
    double dW    =  CGImageGetWidth(source) * fX + CGImageGetHeight(source) * fY;
    double dH    =  CGImageGetWidth(source) * fY + CGImageGetHeight(source) * fX;
    
    CGContextRef context = createBitmapContext((size_t)dW, (size_t)dH);
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(flipX?(CGFloat)dW:0.0f,flipY?(CGFloat)dH:0.0f);
    transform = CGAffineTransformScale(transform, flipX?-1.0:1.0f,flipY?-1.0: 1.0f);
    
    if (angle != 0) {
        CGAffineTransform rot = CGAffineTransformMakeTranslation ((CGFloat)dW*0.5f,(CGFloat)dH*0.5f);
        rot                   = CGAffineTransformRotate(rot, (CGFloat) radians ( angle ));
        rot                   = CGAffineTransformTranslate (rot,-(CGFloat)dH*0.5f,-(CGFloat)dW*0.5f);
        transform             = CGAffineTransformConcat(rot, transform);
    }
    
    CGContextConcatCTM(context, transform);
    CGRect r = CGRectMake(0, 0,
                          CGImageGetWidth(source), CGImageGetHeight(source));
    CGContextDrawImage(context, r, source);
    CGContextFlush(context);
    CGImageRef rotated = CGBitmapContextCreateImage(context);
    
    CFRelease(context);
    
    return rotated;
}

@end


static CGContextRef createBitmapContext(size_t width, size_t height)
{
	size_t const bytesPerRow = width * 4;
    size_t const bitsPerComponent = 8;
	size_t const length = height * bytesPerRow;
	NSMutableData *data = [NSMutableData dataWithLength:length];
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSCAssert(space != NULL, @"");
	CGContextRef ctx = CGBitmapContextCreateWithData([data mutableBytes], width, height, bitsPerComponent, bytesPerRow, space, (CGBitmapInfo) kCGImageAlphaPremultipliedLast, bitmapContextReleaseData, (void *) CFBridgingRetain(data));
	NSCAssert(ctx != NULL, @"");
	CFRelease(space);
    
    CGContextSetAllowsAntialiasing(ctx, NO);
    CGContextSetShouldAntialias(ctx, NO);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    
	return ctx;
}

static void bitmapContextReleaseData(void *releaseInfo, void * __unused data)
{
	CFTypeRef o = (CFTypeRef) releaseInfo;
	if (o != NULL) {
		CFRelease(o);
	}
}
