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

#import "ZMImageLoadOperation.h"


@interface ZMImageLoadOperation ()
{
    CGImageSourceRef _source;
}

@property (nonatomic, copy) NSString *inputDescription;
@property (nonatomic, copy) NSDictionary *sourceImageProperties;
@property (nonatomic, copy) NSData *originalImageData;
@property (nonatomic) ZMIImageProperties *computedImageProperties;

@end



@implementation ZMImageLoadOperation

- (instancetype)initWithImageData:(NSData *)imageData;
{
    VerifyReturnNil(imageData != nil);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    NSString *description = [NSString stringWithFormat:@"data with %llu bytes", (unsigned long long) imageData.length];
    self = [self initWithImageSource:source inputDescription:description];
    if (source) {
        CFRelease(source);
    }
    if (self != nil) {
        self.originalImageData = imageData;
    }
    return self;
}

- (instancetype)initWithImageFileURL:(NSURL *)fileURL;
{
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef) fileURL, NULL);
    self = [self initWithImageSource:source inputDescription:fileURL.path];
    if (source) {
        CFRelease(source);
    }
    if (self != nil) {
        self.originalImageData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:NULL];
        if (self.originalImageData == nil) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithImageSource:(CGImageSourceRef)source inputDescription:(NSString *)description;
{
    self = [super init];
    if (self) {
        if (source == NULL) {
            return nil;
        }
        _source = (CGImageSourceRef) CFRetain(source);
        self.inputDescription = description;
    }
    return self;
}

- (void)dealloc
{
    CGImageRelease(_CGImage);
    if (_source != NULL) {
        CFRelease(_source);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.inputDescription];
}

- (void)main;
{
    NSDictionary *imageOptions = nil;
    size_t const imageIndex = 0;
    
    _CGImage = CGImageSourceCreateImageAtIndex(_source, imageIndex, (__bridge CFDictionaryRef) imageOptions);
    
    self.sourceImageProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(_source, imageIndex, (__bridge CFDictionaryRef) imageOptions));
    
    CGSize size = [self imageSizeFromSourceImage];
    NSUInteger length = (NSUInteger) [(NSNumber *)self.sourceImageProperties[(__bridge id) kCGImagePropertyFileSize] intValue];
    NSString *mimeType = (__bridge id) CGImageSourceGetType(_source);
    self.computedImageProperties = [ZMIImageProperties
                                    imagePropertiesWithSize:size
                                    length:length
                                    mimeType:mimeType
                                    ];
}

- (int)tiffOrientation;
{
    NSNumber *o = self.sourceImageProperties[(__bridge id) kCGImagePropertyOrientation];
    return o.intValue;
}

- (CGSize)imageSizeFromSourceImage;
{
    NSNumber *w = self.sourceImageProperties[(__bridge id) kCGImagePropertyPixelWidth];
    NSNumber *h = self.sourceImageProperties[(__bridge id) kCGImagePropertyPixelHeight];
    return CGSizeMake((CGFloat) w.doubleValue, (CGFloat) h.doubleValue);
}

@end
