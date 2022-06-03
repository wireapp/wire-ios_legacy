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


@import Foundation;
@import CoreGraphics;
#import "ZMIImageProperties.h"

typedef NS_ENUM(NSUInteger, ZMImageFormat) {
    ZMImageFormatInvalid = 0,
    ZMImageFormatPreview,
    ZMImageFormatMedium,
    ZMImageFormatOriginal,
    ZMImageFormatProfile
};

extern ZMImageFormat ImageFormatFromString(NSString * _Nonnull string);
extern NSString * _Nonnull StringFromImageFormat(ZMImageFormat format);


@protocol ZMImageOwner <NSObject>

/// The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
- (nonnull NSOrderedSet *)requiredImageFormats;

- (nullable NSData *)originalImageData;

@end

