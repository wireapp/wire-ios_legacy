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


@import WireSystem;

#import "ZMAssetsPreprocessor.h"
#import "ZMImageLoadOperation.h"
#import "ZMImageOwner.h"
#import "ZMImageDownsampleOperation.h"


@implementation ZMAssetsPreprocessor


- (nonnull instancetype)initWithDelegate:(id<ZMAssetsPreprocessorDelegate> __nullable)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (NSArray * __nullable)operationsForPreprocessingImageOwner:(id<ZMImageOwner> __nonnull)imageOwner
{
    Require(imageOwner != nil);
    NSMutableArray *allOperations = [NSMutableArray array];
    
    ZMImageLoadOperation *load = [[ZMImageLoadOperation alloc] initWithImageData:imageOwner.originalImageData];
    if (load == nil) {
        return nil;
    }
    [allOperations addObject:load];
    
    NSArray *downsampleOPs = [self downsampleOperationsForImageOwner:imageOwner loadOperation:load];
    [allOperations addObjectsFromArray:downsampleOPs];
    
    NSOperation *done = [self.delegate preprocessingCompleteOperationForImageOwner:imageOwner];
    if (done != nil) {
        for (NSOperation *op in downsampleOPs) {
            [done addDependency:op];
        }
        [allOperations addObject:done];
    }

    return allOperations;
}

- (NSArray *)downsampleOperationsForImageOwner:(id<ZMImageOwner>)imageOwner loadOperation:(ZMImageLoadOperation *)load
{
    NSMutableArray *operations = [NSMutableArray array];

    for (NSNumber *boxedImageFormat in imageOwner.requiredImageFormats) {
        ZMImageFormat format = (ZMImageFormat) boxedImageFormat.integerValue;
        NSOperation *op = [self imageOperationForFormat:format imageOwner:imageOwner loadOperation:load];
        [operations addObject:op];
    }

    return operations;
}

- (NSOperation *)imageOperationForFormat:(ZMImageFormat)format
                              imageOwner:(id<ZMImageOwner>)imageOwner
                           loadOperation:(ZMImageLoadOperation *)loadOperation
{
    ZMImageDownsampleOperation *generateImageData = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation
                                                                                                       format:format];
    ZM_WEAK(generateImageData);
    ZM_WEAK(self);
    generateImageData.completionBlock = ^(){
        ZM_STRONG(generateImageData);
        ZM_STRONG(self);
        [self.delegate completedDownsampleOperation:generateImageData imageOwner:imageOwner];
    };
    return generateImageData;
}


- (ZMImageDownsampleType)downsampleTypeForImageFormat:(ZMImageFormat)format
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
        default:
            RequireString(NO, "Unknown image format for downsampling: %ld", (long)format);
            break;
    }
    
    return ZMImageDownsampleTypeInvalid;
}

@end
