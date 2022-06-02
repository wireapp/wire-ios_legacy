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


@import WireImages;
@import WireDataModel;

#import "ZMImagePreprocessingTracker+Testing.h"

@interface ZMImagePreprocessingTracker ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) id<ZMAssetsPreprocessor> preprocessor;
@property (nonatomic) NSOperationQueue *imagePreprocessingQueue;
@property (nonatomic) NSPredicate *needsPreprocessingPredicate;
@property (nonatomic) NSPredicate *fetchPredicate;
@property (nonatomic) Class entityClass;

@end



@implementation ZMImagePreprocessingTracker

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                        imageProcessingQueue:(NSOperationQueue *)imageProcessingQueue
                              fetchPredicate:(NSPredicate *)fetchPredicate
                    needsProcessingPredicate:(NSPredicate *)needsProcessingPredicate
                                 entityClass:(Class)entityClass;
{
    return [self initWithManagedObjectContext:moc
                         imageProcessingQueue:imageProcessingQueue
                               fetchPredicate:fetchPredicate
                     needsProcessingPredicate:needsProcessingPredicate
                                  entityClass:entityClass
                                 preprocessor:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                        imageProcessingQueue:(NSOperationQueue *)imageProcessingQueue
                              fetchPredicate:(NSPredicate *)fetchPredicate
                    needsProcessingPredicate:(NSPredicate *)needsProcessingPredicate
                                 entityClass:(Class)entityClass
                                preprocessor:(ZMAssetsPreprocessor *)preprocessor;
{
    RequireString(imageProcessingQueue != nil, "ImageProcessingQueue can't be nil");
    self = [super init];
    if (self) {
        self.needsPreprocessingPredicate = needsProcessingPredicate;
        self.fetchPredicate = fetchPredicate;
        
        self.managedObjectContext = moc;
        self.preprocessor = preprocessor ?: [[ZMAssetsPreprocessor alloc] init];
        self.preprocessor.delegate = self;
        
        _imageOwnersBeingPreprocessed = [NSMutableSet set];
        _imageOwnersThatNeedPreprocessing = [NSMutableOrderedSet orderedSet];
        self.imagePreprocessingQueue = imageProcessingQueue;
        self.entityClass = entityClass;
    }
    return self;
}

- (void)tearDown;
{
    self.preprocessor = nil;
    [self.imagePreprocessingQueue cancelAllOperations];
}

- (BOOL)hasOutstandingItems;
{
    return ((self.imageOwnersThatNeedPreprocessing.count != 0) ||
            (self.imageOwnersBeingPreprocessed.count != 0));
}

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    return [self.entityClass sortedFetchRequestWithPredicate:self.fetchPredicate];
}

- (void)addTrackedObjects:(NSSet *)objects;
{
    NSMutableArray *filteredObjects = [objects.allObjects mutableCopy];
    [filteredObjects filterUsingPredicate:self.needsPreprocessingPredicate];
    NSArray *sortDescriptors = [self.entityClass defaultSortDescriptors];
    NSArray *sortedObjects = [filteredObjects sortedArrayUsingDescriptors:sortDescriptors];
    [self.imageOwnersThatNeedPreprocessing addObjectsFromArray:sortedObjects];
    [self enqueueAll];
}

- (void)objectsDidChange:(NSSet *)objects
{
    [self addImageOwners:objects];
    [self enqueueAll];
}

- (void)addImageOwners:(NSSet *)imageOwners
{
    for (id<ZMImageOwner> imageOwner in imageOwners) {
        if([imageOwner isKindOfClass:self.entityClass])
        {
            if (
                [self.needsPreprocessingPredicate evaluateWithObject:imageOwner] &&
                ![self.imageOwnersBeingPreprocessed containsObject:imageOwner] &&
                ![self.imageOwnersThatNeedPreprocessing containsObject:imageOwner])
            {
                [self.imageOwnersThatNeedPreprocessing addObject:imageOwner];
            }
        }
    }
}

- (void)enqueueAll;
{
    while ([self enqueueNext]) {
        ; // nothing to do here
    }
}

- (BOOL)enqueueNext;
{
    id<ZMImageOwner> owner = [self.imageOwnersThatNeedPreprocessing firstObject];
    if (owner == nil) {
        return NO;
    }
    [self.imageOwnersThatNeedPreprocessing removeObjectAtIndex:0];
    
    id<ZMAssetsPreprocessor> const preprocessor = self.preprocessor;
    
    NSArray *operations = [preprocessor operationsForPreprocessingImageOwner:owner];
    if (operations == nil) {
        [self failedPreprocessingImageOwner:owner];
        return YES;
    }
    
    [self.imageOwnersBeingPreprocessed addObject:owner];
    
    // Add the context group to all operations:
    ZMSDispatchGroup *group = self.managedObjectContext.dispatchGroup;
    ZMSDispatchGroup *completionGroup = [ZMSDispatchGroup groupWithLabel:@"ZMAssetPreProcessingTracker"];
    for (NSOperation *op in operations) {
        [group enter];
        [completionGroup enter];
        dispatch_block_t original = op.completionBlock;
        if (original == nil) {
            op.completionBlock = ^{
                [group leave];
                [completionGroup leave];
            };
        } else {
            op.completionBlock = ^{
                original();
                [group leave];
                [completionGroup leave];
            };
        }
    }
    
    [group enter];
    [completionGroup notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self.managedObjectContext performGroupedBlock:^{
            [self didCompleteProcessingImageOwner:owner];
            [self.imageOwnersBeingPreprocessed removeObject:owner];
            [group leave];
        }];
    }];
    
    [self.imagePreprocessingQueue addOperations:operations waitUntilFinished:NO];
    return YES;
}


#pragma mark - ZMAssetsPreprocessorDelegate

- (NSOperation * __nullable)preprocessingCompleteOperationForImageOwner:(id<ZMImageOwner> __nonnull)imageOwner
{
    // TODO: should this use the imageOwner's dispatchGroup? Currently this only works because both the image owner and this object coincidentally use the same dispatchGroup
    ZMSDispatchGroup *group = self.managedObjectContext.dispatchGroup;
    [group enter];
    
    NSBlockOperation *done = [NSBlockOperation blockOperationWithBlock:^{
        [group enter];
        [self.managedObjectContext performGroupedBlockAndWait:^{
            [group leave];
            if ([imageOwner respondsToSelector:@selector(processingDidFinish)])  {
                [(id)imageOwner processingDidFinish];
            }
        }];
    }];
    done.completionBlock = ^{
        [group leave];
    };
    return done;
}

- (void)completedDownsampleOperation:(ZMImageDownsampleOperation * __nonnull)operation imageOwner:(id<ZMImageOwner> __nonnull)imageOwner
{    
    [self.managedObjectContext performGroupedBlock:^{
        if ([imageOwner respondsToSelector:@selector(setImageData:for:properties:)])  {
            [(id)imageOwner setImageData:operation.downsampleImageData for:operation.format properties:operation.properties];
        }
    }];
}

- (void)failedPreprocessingImageOwner:(id<ZMImageOwner>)imageOwner;
{
    if ([imageOwner respondsToSelector:@selector(processingDidFinish)])  {
        [(id)imageOwner processingDidFinish];
    }
}


- (void)didCompleteProcessingImageOwner:(__unused id<ZMImageOwner>)imageOwner;
{
}


@end
