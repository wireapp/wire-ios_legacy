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

#import <WireImages/ZMImageOwner.h>
#import <WireImages/ZMIImageProperties.h>

@class ZMImageLoadOperation;


typedef NS_ENUM (int16_t, ZMImageDownsampleType) {
    ZMImageDownsampleTypeInvalid,
    ZMImageDownsampleTypePreview,
    ZMImageDownsampleTypeMedium,
    ZMImageDownsampleTypeSmallProfile,
};

@protocol ZMImageDownsampleOperationProtocol <NSObject>

@property (nonatomic, readonly, copy) NSData *downsampleImageData;
@property (nonatomic, readonly) ZMImageFormat format;
@property (nonatomic, readonly) ZMIImageProperties *properties;

@end


@interface ZMImageDownsampleOperation : NSOperation <ZMImageDownsampleOperationProtocol>

- (instancetype)initWithLoadOperation:(ZMImageLoadOperation *)loadOperation downsampleType:(ZMImageDownsampleType)downsampleType;
- (instancetype)initWithLoadOperation:(ZMImageLoadOperation *)loadOperation format:(ZMImageFormat)format;

+ (ZMImageDownsampleType)downsampleTypeForImageFormat:(ZMImageFormat)format;

@property (nonatomic, readonly, copy) NSData *downsampleImageData;
@property (nonatomic, readonly) ZMImageFormat format;
@property (nonatomic, readonly) ZMIImageProperties *properties;

@end
