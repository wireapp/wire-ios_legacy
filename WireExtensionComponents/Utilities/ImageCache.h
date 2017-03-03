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
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ImageCache : NSObject

@property (nonatomic) NSUInteger countLimit;
@property (nonatomic) NSUInteger totalCostLimit;
@property (nonatomic) NSInteger maxConcurrentOperationCount;
@property (nonatomic) NSQualityOfService qualityOfService;
@property (nonatomic, readonly) dispatch_group_t processingGroup;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

/// Either creates the image in the background and caches it with the supplied cache key,
/// or retrieves it from the cache.
- (void)imageForData:(NSData *)imageData
            cacheKey:(NSString *)cacheKey
      withCompletion:(nullable void (^)(UIImage *image, NSString *cacheKey))completion;

/// Either creates the image in the background and caches it with the supplied cache key,
/// or retrieves it from the cache.  Takes a block that actually creates the image from the
/// passed in data.
- (void)imageForData:(NSData *)imageData cacheKey:(NSString *)cacheKey
       creationBlock:(id (^)(NSData *data)) creation
          completion:(nullable void (^)(id image, NSString *cacheKey)) completion;

- (nullable UIImage *)imageForCacheKey:(NSString *)cacheKey;

- (void)setImage:(UIImage *)image forCacheKey:(NSString *)cacheKey;
- (void)removeImageForCacheKey:(NSString *)cacheKey;
- (void)cancelAllOperations;


@end

NS_ASSUME_NONNULL_END
