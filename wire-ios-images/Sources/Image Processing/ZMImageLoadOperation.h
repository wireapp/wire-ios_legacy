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

#import <WireImages/ZMIImageProperties.h>

@interface ZMImageLoadOperation : NSOperation

- (instancetype)initWithImageData:(NSData *)imageData;
- (instancetype)initWithImageFileURL:(NSURL *)fileURL;

@property (nonatomic, readonly) CGImageRef CGImage;
@property (nonatomic, readonly, copy) NSDictionary *sourceImageProperties;

@property (nonatomic, readonly) int tiffOrientation;
@property (nonatomic, readonly) ZMIImageProperties *computedImageProperties;
@property (nonatomic, readonly, copy) NSData *originalImageData;

@property (nonatomic, readonly, copy) NSString *inputDescription;

@end
