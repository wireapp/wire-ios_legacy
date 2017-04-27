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


#import "ImageCache.h"
#import "weakify.h"

@import CocoaLumberjack;


static const int ddLogLevel = LOG_LEVEL_CONFIG;

@interface ImageCache ()

@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) NSOperationQueue *imageProcessingQueue;

@end



@implementation ImageCache

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
        self.cache.name = name;
        
        self.imageProcessingQueue = [[NSOperationQueue alloc] init];
        self.imageProcessingQueue.maxConcurrentOperationCount = 1;
        self.imageProcessingQueue.qualityOfService = NSQualityOfServiceUtility;
        
        _processingGroup = dispatch_group_create();
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (NSUInteger)countLimit
{
    return self.cache.countLimit;
}

- (void)setCountLimit:(NSUInteger)countLimit
{
    self.cache.countLimit = countLimit;
}

- (NSUInteger)totalCostLimit
{
    return self.cache.totalCostLimit;
}

- (void)setTotalCostLimit:(NSUInteger)totalCostLimit
{
    self.cache.totalCostLimit = totalCostLimit;
}

- (NSInteger)maxConcurrentOperationCount
{
    return self.imageProcessingQueue.maxConcurrentOperationCount;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    self.imageProcessingQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (NSQualityOfService)qualityOfService
{
    return self.imageProcessingQueue.qualityOfService;
}

- (void)setQualityOfService:(NSQualityOfService)qualityOfService
{
    self.imageProcessingQueue.qualityOfService = qualityOfService;
}

- (UIImage *)imageForCacheKey:(NSString *)cacheKey
{
    return [self.cache objectForKey:cacheKey];
}

- (void)removeImageForCacheKey:(NSString *)cacheKey
{
    [self.cache removeObjectForKey:cacheKey];
}

- (void)setImage:(UIImage *)image forCacheKey:(NSString *)cacheKey
{
    if (! image) {
        return;
    }
    [self.cache setObject:image forKey:cacheKey cost:[self costForImage:image]];
}

- (NSUInteger)costForImage:(UIImage *)image
{
    return CGImageGetHeight(image.CGImage) * CGImageGetBytesPerRow(image.CGImage);
}

- (void)imageForData:(NSData *)imageData cacheKey:(NSString *)cacheKey withCompletion:(void (^)(UIImage *image, NSString *cacheKey))completion
{
    return [self imageForData:imageData cacheKey:cacheKey creationBlock:^id(NSData *data) {
        return [UIImage imageWithData:data];
    } completion:completion];
}

- (void)imageForData:(NSData *)imageData cacheKey:(NSString *)cacheKey
       creationBlock:(id (^)(NSData *data)) creation
          completion:(void (^)(id image, NSString *cacheKey)) completion
{
    if (nil == cacheKey) {
        return;
    }
    
    __block UIImage *image = [self.cache objectForKey:cacheKey];
    if (image != nil) {
        if (nil != completion) {
            completion(image, cacheKey);
        }
        return;
    }
    
    @weakify(self);
    
    dispatch_group_enter(self.processingGroup);
    
    NSOperation *pendingOperation = [self pendingOperationForCacheKey:cacheKey];
    
    if (pendingOperation != nil) {

        NSOperation *callbackOperation = [NSBlockOperation blockOperationWithBlock:^{
            @strongify(self);
            __block UIImage *image = [self.cache objectForKey:cacheKey];
            if (image != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (nil != completion) {
                        completion(image, cacheKey);
                    }
                    dispatch_group_leave(self.processingGroup);
                });
            }
            else {
                dispatch_group_leave(self.processingGroup);
            }
        }];
        [callbackOperation addDependency:pendingOperation];
        [self.imageProcessingQueue addOperation:callbackOperation];
    }
    else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            
            @strongify(self);
            
            NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
            
            image = creation(imageData);
            
            if (image != nil) {
                [self.cache setObject:image forKey:cacheKey];
            }
            else {
                DDLogError(@"Error creating image from data");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
                NSTimeInterval duration = endTime - startTime;
                
                if (duration > 10) {
                    DDLogVerbose(@"Image took a really long time to create! (time: %.2f bytes: %ld)", duration, (unsigned long)imageData.length);
                }
                if (nil != completion) {
                    completion(image, cacheKey);
                }
                dispatch_group_leave(self.processingGroup);
            });
        }];
        
        operation.name = cacheKey;
        [self.imageProcessingQueue addOperation:operation];
    }
}

// Return a running operation for a cachekey
- (NSOperation *)pendingOperationForCacheKey:(NSString *)cacheKey
{
    for (NSOperation *operation in self.imageProcessingQueue.operations) {
        if ([operation.name isEqualToString:cacheKey]) {
            return operation;
        }
    }
    return nil;
}

- (void)cancelAllOperations
{
    [self.imageProcessingQueue cancelAllOperations];
}

#pragma mark - Memory warnings

- (void)didReceiveMemoryWarning
{
    [self.cache removeAllObjects];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self.cache removeAllObjects];
}

@end
