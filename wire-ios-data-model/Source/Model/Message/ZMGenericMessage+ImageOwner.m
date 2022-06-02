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


@import WireTransport;
#import "ZMGenericMessage+ImageOwner.h"
#import <WireDataModel/WireDataModel-Swift.h>


@implementation ZMGenericMessage (ImageOwner)

- (void)setImageData:(NSData *)imageData forFormat:(ZMImageFormat)format properties:(ZMIImageProperties *)properties
{
    NOT_USED(imageData);
    NOT_USED(format);
    NOT_USED(properties);
}

- (BOOL)encrypted
{
    return self.hasImage && self.image.otrKey.length > 0;
}

- (NSUUID *)nonce
{
    if(self.hasImage) {
        return [NSUUID uuidWithTransportString:self.messageId];
    }
    return nil;
}

- (AssetDirectory *)directory {
    return [[AssetDirectory alloc] init];
}

- (NSData *)originalImageData
{
    if(self.hasImage) {
        return [self.directory assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
    }
    return nil;
}

- (BOOL)isPublicForFormat:(ZMImageFormat)format
{
    NOT_USED(format);
    return NO;
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format
{
    if(self.hasImage && format == self.image.imageFormat) {
        return [self.directory assetData:self.nonce format:format encrypted:[self encrypted]];
    }
    return nil;
}

- (CGSize)originalImageSize
{
    if(self.hasImage) {
        return CGSizeMake(self.image.originalWidth, self.image.originalHeight);
    }
    return CGSizeMake(0,0);
}

- (NSOrderedSet *)requiredImageFormats
{
    return [NSOrderedSet orderedSet];
}

- (BOOL)isInlineForFormat:(ZMImageFormat)format
{
    switch(format) {
        case ZMImageFormatPreview:
            return YES;
        case ZMImageFormatInvalid:
        case ZMImageFormatMedium:
        case ZMImageFormatOriginal:
        case ZMImageFormatProfile:
            return NO;
    }
}

- (BOOL)isUsingNativePushForFormat:(ZMImageFormat)format
{
    switch(format) {
        case ZMImageFormatMedium:
            return YES;
        case ZMImageFormatInvalid:
        case ZMImageFormatPreview:
        case ZMImageFormatOriginal:
        case ZMImageFormatProfile:
            return NO;
    }
}

- (void)processingDidFinish
{
}

- (ZMImageFormat)imageFormat
{
    if (self.hasImage) {
        return self.image.imageFormat;
    }
    return ZMImageFormatInvalid;
}


@end
