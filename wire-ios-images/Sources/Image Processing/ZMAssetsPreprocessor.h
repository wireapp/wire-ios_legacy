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
#import <WireImages/ZMImageDownsampleOperation.h>

@protocol ZMAssetsPreprocessorDelegate;


@protocol ZMAssetsPreprocessor <NSObject>

@property (nonatomic, weak, nullable) id<ZMAssetsPreprocessorDelegate> delegate;

- (NSArray<NSOperation *> * __nullable)operationsForPreprocessingImageOwner:(id<ZMImageOwner> __nonnull)imageOwner;

@end



@protocol ZMAssetsPreprocessorDelegate <NSObject>

- (void)completedDownsampleOperation:(id<ZMImageDownsampleOperationProtocol> __nonnull)operation
                          imageOwner:(id<ZMImageOwner> __nonnull)imageOwner;

- (void)failedPreprocessingImageOwner:(id<ZMImageOwner> __nonnull)imageOwner;
- (void)didCompleteProcessingImageOwner:(id<ZMImageOwner> __nonnull)imageOwner;

- (NSOperation * __nullable)preprocessingCompleteOperationForImageOwner:(id<ZMImageOwner> __nonnull)imageOwner;

@end



@interface ZMAssetsPreprocessor : NSObject <ZMAssetsPreprocessor>

- (nonnull instancetype)initWithDelegate:(id<ZMAssetsPreprocessorDelegate> __nullable)delegate;

@property (nonatomic, weak, nullable) id<ZMAssetsPreprocessorDelegate> delegate;

@end
