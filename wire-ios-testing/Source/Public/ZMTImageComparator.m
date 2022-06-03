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


#import "ZMTImageComparator.h"

@import CoreGraphics;
@import ImageIO;



struct pixel_s {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} __attribute__((packed));

struct RGB_s {
    double r;
    double g;
    double b;
};

struct XYZ_s {
    double x;
    double y;
    double z;
};

struct Lab_s {
    double L;
    double a;
    double b;
};

static double calculateDifference(struct pixel_s const * const pixelA,
                                  struct pixel_s const * const pixelB);
static struct XYZ_s xyzFromRGB(struct RGB_s const rgb);
static struct Lab_s labFromRGB(struct RGB_s const rgb);



@interface ZMTImageComparator ()
{
    CGImageSourceRef _sourceA;
    CGImageSourceRef _sourceB;
}

@property (nonatomic) double maxPixelDifference;

@property (nonatomic) BOOL propertiesDiffer;
@property (nonatomic) NSString *propertiesDiffDescription;

@end



@implementation ZMTImageComparator

- (instancetype)initWithImageDataA:(NSData *)imageDataA imageDataB:(NSData *)imageDataB;
{
    CGImageSourceRef sourceA = CGImageSourceCreateWithData((__bridge CFDataRef) imageDataA, NULL);
    CGImageSourceRef sourceB = CGImageSourceCreateWithData((__bridge CFDataRef) imageDataB, NULL);
    self = [self initWithImageSourceA:sourceA imageSourceB:sourceB];
    CFBridgingRelease(sourceA);
    CFBridgingRelease(sourceB);
    return self;
}

- (instancetype)initWithImageSourceA:(CGImageSourceRef)sourceA imageSourceB:(CGImageSourceRef)sourceB;
{
    self = [super init];
    if (self != nil) {
        _sourceA = (CGImageSourceRef) CFRetain(sourceA);
        _sourceB = (CGImageSourceRef) CFRetain(sourceB);
    }
    return self;
}

- (void)dealloc
{
    CFBridgingRelease(_sourceA);
    CFBridgingRelease(_sourceB);
}

- (void)calculateDifference;
{
    self.maxPixelDifference = 0;
    
    CGImageRef imageA = CGImageSourceCreateImageAtIndex(_sourceA, 0, NULL);
    CGImageRef imageB = CGImageSourceCreateImageAtIndex(_sourceB, 0, NULL);
    
    NSDictionary *propertiesA = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_sourceA, 0, NULL));
    NSDictionary *propertiesB = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_sourceB, 0, NULL));
    
    CGContextRef ctxA = [self createBitmapContextFromImage:imageA];
    CGContextRef ctxB = [self createBitmapContextFromImage:imageB];
    NSAssert(ctxA != NULL, @"");
    NSAssert(ctxB != NULL, @"");
    
    [self calculateMaximumDifferenceBetweenContextA:ctxA contextB:ctxB];

    [self comparePropertiesForA:propertiesA b:propertiesB];
    
    CFRelease(imageA);
    CFRelease(imageB);
    
    CFRelease(ctxA);
    CFRelease(ctxB);
}

- (void)calculateMaximumDifferenceBetweenContextA:(CGContextRef)ctxA contextB:(CGContextRef)ctxB;
{
    size_t const width = MIN(CGBitmapContextGetWidth(ctxA), CGBitmapContextGetWidth(ctxB));
    size_t const height = MIN(CGBitmapContextGetHeight(ctxA), CGBitmapContextGetHeight(ctxB));
    
    char const * const dataA = CGBitmapContextGetData(ctxA);
    char const * const dataB = CGBitmapContextGetData(ctxB);
    
    double max = self.maxPixelDifference;
    
    for (size_t y = 0; y < height; ++y) {
        uint8_t const * const rowDataA = (uint8_t const *) (dataA + y * CGBitmapContextGetBytesPerRow(ctxA));
        uint8_t const * const rowDataB = (uint8_t const *) (dataB + y * CGBitmapContextGetBytesPerRow(ctxB));
        for (size_t x = 0; x < width; ++x) {
            struct pixel_s const * const pixelA = (struct pixel_s const *) (rowDataA + 4 * x);
            struct pixel_s const * const pixelB = (struct pixel_s const *) (rowDataB + 4 * x);
            
            double diff = calculateDifference(pixelA, pixelB);
            max = fmax(max, diff);
        }
    }
    self.maxPixelDifference = max;
}

- (NSDictionary *)removeKeysThatChangeFromProperties:(NSDictionary *)properties;
{
    // On iOS 8 and OS X 10.10 ImageIO has better fidelity than previously. We'll ignore the difference
    // by removing those keys that changed.
    NSMutableDictionary *result = [properties mutableCopy];
    if (result[@"{Exif}"] != nil) {
        NSMutableDictionary *exif = [result[@"{Exif}"] mutableCopy];
        result[@"{Exif}"] = exif;
        [exif removeObjectForKey:@"ColorSpace"];
    }
    if (result[@"{JFIF}"] != nil) {
        NSMutableDictionary *jfif = [result[@"{JFIF}"] mutableCopy];
        result[@"{JFIF}"] = jfif;
        [jfif removeObjectForKey:@"DensityUnit"];
        [jfif removeObjectForKey:@"XDensity"];
        [jfif removeObjectForKey:@"YDensity"];
    }
    if (result[@"{TIFF}"] != nil) {
        NSMutableDictionary *tiff = [result[@"{TIFF}"] mutableCopy];
        result[@"{TIFF}"] = tiff;
        [tiff removeObjectForKey:@"ResolutionUnit"];
    }
    [result removeObjectForKey:@"DPIWidth"];
    [result removeObjectForKey:@"DPIHeight"];
    return result;
}

- (void)comparePropertiesForA:(NSDictionary *)propertiesAIn b:(NSDictionary *)propertiesBIn;
{
    NSDictionary *propertiesA = [self removeKeysThatChangeFromProperties:propertiesAIn];
    NSDictionary *propertiesB = [self removeKeysThatChangeFromProperties:propertiesBIn];
    
    NSMutableArray *diffDescriptions = [NSMutableArray array];
    
    NSSet *keysA = [NSSet setWithArray:propertiesA.allKeys];
    NSSet *keysB = [NSSet setWithArray:propertiesB.allKeys];
    
    if (! [keysA isEqualToSet:keysB]) {
        NSMutableSet *missingKeys = [keysB mutableCopy];
        [missingKeys minusSet:keysA];
        for (NSString *key in missingKeys) {
            [diffDescriptions addObject:[NSString stringWithFormat:@"Key \"%@\" is missing.", key]];
        }
        NSMutableSet *additionalKeys = [keysA mutableCopy];
        [additionalKeys minusSet:keysB];
        for (NSString *key in additionalKeys) {
            [diffDescriptions addObject:[NSString stringWithFormat:@"Key \"%@\" is extraneous.", key]];
        }
    }
    {
        NSMutableSet *commonKeys = [keysA mutableCopy];
        [commonKeys intersectSet:keysB];
        for (NSString *key in commonKeys) {
            id objA = propertiesA[key];
            id objB = propertiesB[key];
            if (! [objA isEqual:objB]) {
                [diffDescriptions addObject:[NSString stringWithFormat:@"Value for \"%@\" doesn't match (%@ != %@).",
                                             key, objA, objB]];
            }
        }
    }
    
    self.propertiesDiffer = (0 < diffDescriptions.count);
    self.propertiesDiffDescription = [diffDescriptions componentsJoinedByString:@" "];
}

- (CGContextRef)createBitmapContextFromImage:(CGImageRef)image CF_RETURNS_RETAINED;
{
    size_t const width = CGImageGetWidth(image);
    size_t const height = CGImageGetHeight(image);
    size_t const bitsPerComponent = 8;
    size_t const bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, space, bitmapInfo);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
    CFRelease(space);
    return ctx;
}

@end



static double calculateDifference(struct pixel_s const * const pixelA,
                                  struct pixel_s const * const pixelB)
{
    struct RGB_s const a = {
        pixelA->red / (double) UINT16_MAX,
        pixelA->green / (double) UINT16_MAX,
        pixelA->blue / (double) UINT16_MAX,
    };
    struct RGB_s const b = {
        pixelB->red / (double) UINT16_MAX,
        pixelB->green / (double) UINT16_MAX,
        pixelB->blue / (double) UINT16_MAX,
    };
    struct Lab_s LabA = labFromRGB(a);
    struct Lab_s LabB = labFromRGB(b);
    
    LabA.L *= 0.01;
    LabA.a *= 0.01;
    LabA.b *= 0.01;
    
    LabB.L *= 0.01;
    LabB.a *= 0.01;
    LabB.b *= 0.01;
    
    return fmax(fabs(LabA.L - LabB.L),
                fmax(fabs(LabA.a - LabB.a),
                     fmax(fabs(LabA.b - LabB.b),
                          abs(pixelA->alpha - pixelB->alpha))));
}

//
// C.f. <http://www.easyrgb.com/index.php?X=MATH&H=07#text7>
//

static struct XYZ_s xyzFromRGB(struct RGB_s const rgb)
{
    struct RGB_s temp;
    
    if ( rgb.r > 0.04045 ) {
        temp.r = pow(( rgb.r + 0.055 ) / 1.055, 2.4);
    } else {
        temp.r = rgb.r / 12.92;
    }
    if ( rgb.g > 0.04045 ) {
        temp.g = pow(( rgb.g + 0.055 ) / 1.055, 2.4);
    } else {
        temp.g = rgb.g / 12.92;
    }
    if ( rgb.b > 0.04045 ) {
        temp.b = pow(( rgb.b + 0.055 ) / 1.055, 2.4);
    } else {
        temp.b = rgb.b / 12.92;
    }
    
    temp.r *= 100.0;
    temp.g *= 100.0;
    temp.b *= 100.0;
    
    
    // Observer. = 2°, Illuminant = D65
    struct XYZ_s const result = {
        temp.r * 0.4124 + temp.g * 0.3576 + temp.b * 0.1805,
        temp.r * 0.2126 + temp.g * 0.7152 + temp.b * 0.0722,
        temp.r * 0.0193 + temp.g * 0.1192 + temp.b * 0.9505,
    };
    return result;
}

static struct Lab_s labFromRGB(struct RGB_s const rgb)
{
    struct XYZ_s const xyz = xyzFromRGB(rgb);
    
    // Observer= 2°, Illuminant= D65
    double const ref_X =  95.047;
    double const ref_Y = 100.000;
    double const ref_Z = 108.883;
    
    double X = xyz.x / ref_X;
    double Y = xyz.y / ref_Y;
    double Z = xyz.z / ref_Z;
    
    if ( X > 0.008856 ) {
        X =  pow(X, 1./3.);
    } else {
        X = ( 7.787 * X ) + ( 16 / 116 );
    }
    if ( Y > 0.008856 ) {
        Y =  pow(Y, 1./3.);
    } else {
        Y = ( 7.787 * Y ) + ( 16 / 116 );
    }
    if ( Z > 0.008856 ) {
        Z =  pow(Z, 1./3.);
    } else {
        Z = ( 7.787 * Z ) + ( 16 / 116 );
    }
    
    struct Lab_s const result = {
        ( 116. * Y ) - 16.,
        500. * ( X - Y ),
        200. * ( Y - Z ),
    };
    return result;
}
