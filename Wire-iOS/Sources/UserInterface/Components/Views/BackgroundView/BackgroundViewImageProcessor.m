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


#import "BackgroundViewImageProcessor.h"
#import "ImageCache.h"
#import "zmessaging+iOS.h"
#import "UIImage+ImageUtilities.h"

@import WireExtensionComponents;

static ImageCache *originalImageCache(void);
static ImageCache *blurredImageCache(void);



@interface BackgroundViewImageProcessor ()

@property (nonatomic, strong) NSOperationQueue *imageProcessingQueue;
@property (nonatomic, strong) CIContext *ciContext;

@end



@implementation BackgroundViewImageProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imageProcessingQueue = [[NSOperationQueue alloc] init];
        self.imageProcessingQueue.maxConcurrentOperationCount = 2;
        self.imageProcessingQueue.qualityOfService = NSQualityOfServiceUtility;
        
        self.ciContext = [CIContext contextWithOptions:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)processImageForData:(NSData *)imageData withCacheKey:(NSString *)imageCacheKey
         originalCompletion:(void (^)(UIImage *image, NSString *imageCacheKey))originalImageCompletion
             blurCompletion:(void (^)(UIImage *image, NSString *imageCacheKey))blurredImageCompletion;
{
    // Check for generated images in the cache
    UIImage *originalImage = [originalImageCache() imageForCacheKey:imageCacheKey];
    if (originalImage != nil) {
        originalImageCompletion(originalImage, imageCacheKey);
    }
    
    UIImage *blurredImage = [blurredImageCache() imageForCacheKey:imageCacheKey];
    if (blurredImage != nil) {
        blurredImageCompletion(blurredImage, imageCacheKey);
    }
    
    if (blurredImage != nil && originalImage != nil) {
        return;
    }
    
    // If one of the images is not in the cache, generate the appropriate images
    
    @weakify(self);
    
    ImageCache *cache = originalImageCache();
    [cache imageForData:imageData cacheKey:imageCacheKey withCompletion:^(UIImage *image, NSString *cacheKey) {
        
        @strongify(self);
        
        if (! image) {
            return;
        }
        
        if (originalImage == nil) {
            @weakify(self);
            [self.imageProcessingQueue addOperationWithBlock:^{
                @strongify(self);

                UIImage *originalImage = [image blurredAutoEnhancedImageWithContext:self.ciContext blurRadius:0.0];
                [originalImageCache() setImage:originalImage forCacheKey:cacheKey];
                dispatch_async(dispatch_get_main_queue(), ^{
                    originalImageCompletion(originalImage, cacheKey);
                });
            }];
        }
        
        if (blurredImage == nil) {
            @weakify(self);
            [self.imageProcessingQueue addOperationWithBlock:^{
                @strongify(self);
                
                UIImage *blurredImage = [image blurredAutoEnhancedImageWithContext:self.ciContext blurRadius:40.0];
                [blurredImageCache() setImage:blurredImage forCacheKey:cacheKey];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    blurredImageCompletion(blurredImage, cacheKey);
                });
            }];
        }
    }];
}

- (void)wipeImageForCacheKey:(NSString *)key
{
    [originalImageCache() removeImageForCacheKey:key];
    [blurredImageCache() removeImageForCacheKey:key];
}

#pragma mark - Application Background State

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    DDLogDebug(@"Suspending Background  Image Processor");
    self.imageProcessingQueue.suspended = YES;
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    DDLogDebug(@"Un-Suspending Background  Image Processor");
    self.imageProcessingQueue.suspended = NO;
}

@end



static ImageCache *originalImageCache(void)
{
    static ImageCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ImageCache alloc] initWithName:@"BackgroundViewController.originalImageCache"];
        // Only keep the last requested one around..
        cache.countLimit = 1;
        cache.totalCostLimit = 1024 * 1024 * 20; // 20 MB
        cache.maxConcurrentOperationCount = 1;
        cache.qualityOfService = NSQualityOfServiceUtility;
    });
    return cache;
}

static ImageCache *blurredImageCache(void)
{
    static ImageCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ImageCache alloc] initWithName:@"BackgroundViewController.blurredImageCache"];
        cache.countLimit = 10;
        cache.totalCostLimit = 1024 * 1024 * 20; // 20 MB
        cache.maxConcurrentOperationCount = 1;
        cache.qualityOfService = NSQualityOfServiceUtility;
    });
    return cache;
}
