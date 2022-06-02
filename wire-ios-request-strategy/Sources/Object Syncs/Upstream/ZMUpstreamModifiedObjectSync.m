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
@import WireDataModel;

#import "ZMUpstreamModifiedObjectSync+Testing.h"
#import "ZMSyncOperationSet.h"
#import <WireRequestStrategy/WireRequestStrategy-Swift.h>
#import "ZMLocallyModifiedObjectSyncStatus.h"
#import "ZMLocallyModifiedObjectSet.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMUpstreamRequest.h"


@interface ZMUpstreamModifiedObjectSync ()

@property (nonatomic, readonly) ZMLocallyModifiedObjectSet *updatedObjects;
@property (nonatomic) NSEntityDescription *trackedEntity;
@property (nonatomic, weak) id<ZMUpstreamTranscoder> transcoder;
@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSPredicate *updatePredicate;
@property (nonatomic) DependentObjectsObjc *updatedObjectsWithDependencies;
@property (nonatomic, readonly) BOOL transcodeSupportsExpiration;
@property (nonatomic) NSPredicate *filter;

@end



@implementation ZMUpstreamModifiedObjectSync

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
              managedObjectContext:(NSManagedObjectContext *)context;
{
        return [self initWithTranscoder:transcoder
                             entityName:entityName
                   managedObjectContext:context
                locallyModifiedObjectSet:nil];
}

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                        keysToSync:(NSArray<NSString *> *)keysToSync
              managedObjectContext:(NSManagedObjectContext *)context;
{
    return [self initWithTranscoder:transcoder entityName:entityName updatePredicate:nil  filter:nil keysToSync:keysToSync managedObjectContext:context locallyModifiedObjectSet:nil];
}

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                   updatePredicate:(NSPredicate *)updatePredicate
                            filter:(NSPredicate *)filter
                        keysToSync:(NSArray<NSString *> *)keysToSync
              managedObjectContext:(NSManagedObjectContext *)context
{
    return [self initWithTranscoder:transcoder entityName:entityName updatePredicate:updatePredicate  filter:filter keysToSync:keysToSync managedObjectContext:context locallyModifiedObjectSet:nil];
}

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
              managedObjectContext:(NSManagedObjectContext *)context
          locallyModifiedObjectSet:(ZMLocallyModifiedObjectSet *)objectSet
{
    return [self initWithTranscoder:transcoder entityName:entityName updatePredicate:nil filter:nil keysToSync:nil managedObjectContext:context locallyModifiedObjectSet:objectSet];
}

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                   updatePredicate:(NSPredicate *)updatePredicate
                            filter:(NSPredicate *)filter
                        keysToSync:(NSArray<NSString *> *)keysToSync
              managedObjectContext:(NSManagedObjectContext *)context
          locallyModifiedObjectSet:(ZMLocallyModifiedObjectSet *)objectSet
{
    RequireString(transcoder != nil, "Transcoder can't be nil");
    RequireString(entityName != nil, "Entity name can't be nil");
    RequireString(context != nil, "MOC can't be nil");
    self = [super init];
    if(self) {
        self.transcoder = transcoder;
        _transcodeSupportsExpiration = [transcoder respondsToSelector:@selector(requestExpiredForObject:forKeys:)];
        
        self.trackedEntity = [context.persistentStoreCoordinator.managedObjectModel entitiesByName][entityName];
        RequireString(self.trackedEntity != nil, "Unable to retrieve entity by name.");
        
        self.context = context;
        self.filter = filter;
        
        Class moClass = NSClassFromString(self.trackedEntity.managedObjectClassName);
        self.updatePredicate = updatePredicate ?: [moClass predicateForObjectsThatNeedToBeUpdatedUpstream];
        
        if (objectSet == nil) {
            if (keysToSync != nil) {
                _updatedObjects = [[ZMLocallyModifiedObjectSet alloc] initWithTrackedKeys:[NSSet setWithArray:keysToSync]];
            }
            else {
                _updatedObjects = [[ZMLocallyModifiedObjectSet alloc] init];
            }
        }
        else {
            _updatedObjects = objectSet;
        }
        
        
        if ([transcoder respondsToSelector:@selector(dependentObjectNeedingUpdateBeforeProcessingObject:)]) {
            self.updatedObjectsWithDependencies = [[DependentObjectsObjc alloc] init];
        }
    }
    return self;
    
}

- (BOOL)hasOutstandingItems;
{
    return self.updatedObjects.hasOutstandingItems;
}

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    Class moClass = NSClassFromString(self.trackedEntity.managedObjectClassName);
    return [moClass sortedFetchRequestWithPredicate:self.updatePredicate];
}

- (void)addTrackedObjects:(NSSet *)objects;
{
    for (ZMManagedObject *mo in objects) {
        if ([self objectPassesTrackingFilter:mo]) {
            [self addUpdatedObject:mo];
        }
    }
}

- (void)objectsDidChange:(NSSet *)objects
{
    for(ZMManagedObject* obj in objects) {
        BOOL isTrackedObject = ([obj isKindOfClass:[NSManagedObject class]] && obj.entity == self.trackedEntity);
        if (isTrackedObject && [self objectShouldBeSynced:obj]) {
            [self addUpdatedObject:obj];
        }
        [self checkForUpdatedDependency:obj];
    }
}

- (BOOL)objectShouldBeSynced:(ZMManagedObject *)object
{
    if ([self.updatePredicate evaluateWithObject:object] && [self objectPassesTrackingFilter:object]) {
        return YES;
    }
    return NO;
}

- (BOOL)objectPassesTrackingFilter:(ZMManagedObject *)object
{
    BOOL passedFilter = (self.filter == nil ||
                         (self.filter != nil && [self.filter evaluateWithObject:object]));
    return passedFilter;
}

- (void)checkForUpdatedDependency:(ZMManagedObject *)existingDependency;
{
    [self.updatedObjectsWithDependencies enumerateAndRemoveObjectsForDependency:existingDependency usingBlock:^BOOL(ZMManagedObject *mo) {
        id newDependency = [self.transcoder dependentObjectNeedingUpdateBeforeProcessingObject:mo];
        if (newDependency == nil) {
            [self addUpdatedObjectWithoutDependency:mo];
            return YES;
        } else if (newDependency == existingDependency) {
            return NO;
        } else {
            [self.updatedObjectsWithDependencies addDependentObject:mo dependency:newDependency];
            return YES;
        }
    }];
}

- (void)addUpdatedObjectWithoutDependency:(ZMManagedObject *)mo
{
    [self.updatedObjects addPossibleObjectToSynchronize:mo];
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;
{
    return [self processNextUpdateWithAPIVersion:apiVersion];
}

- (void)addUpdatedObject:(ZMManagedObject *)mo
{
    if (self.updatedObjectsWithDependencies) {
        id dependency = [self.transcoder dependentObjectNeedingUpdateBeforeProcessingObject:mo];
        if (dependency != nil) {
            [self.updatedObjectsWithDependencies addDependentObject:mo dependency:dependency];
            return;
        }
    }

    [self addUpdatedObjectWithoutDependency:mo];
}

- (ZMObjectWithKeys *)nextObjectToSync
{
    ZMObjectWithKeys *objectWithKeys = [self.updatedObjects anyObjectToSynchronize];
    if (objectWithKeys == nil) {
        return nil;
    }
    
    //if we still has a dependency for this object we don't sync it
    id dependency = [self.updatedObjectsWithDependencies anyDependencyForObject:objectWithKeys.object];
    if (dependency != nil) {
        return nil;
    }
    
    //if object was not synced 'cause it depends on other object (i.e. asset message depends on missed clients)
    //it will be readded back to updatedObjects set when request finishes
    //so next time we are asked to sync it we need to check it against predicate and filter again
    //because during sync of dependent object this object can also change (i.e. message will be expired if failed to create session with missed client)
    if (![self objectShouldBeSynced:objectWithKeys.object]) {
        return nil;
    }
    return objectWithKeys;
}

- (ZMTransportRequest *)processNextUpdateWithAPIVersion:(APIVersion)apiVersion
{
    ZMObjectWithKeys *objectWithKeys = [self nextObjectToSync];
    if (objectWithKeys == nil) {
        return nil;
    }

    id<ZMUpstreamTranscoder> transcoder = self.transcoder;
    if ([transcoder respondsToSelector:@selector(shouldCreateRequestToSyncObject:forKeys:withSync:)]) {
        if (![transcoder shouldCreateRequestToSyncObject:objectWithKeys.object forKeys:objectWithKeys.keysToSync withSync:self]) {
            return nil;
        }
    }

    ZMUpstreamRequest *request = [transcoder requestForUpdatingObject:objectWithKeys.object forKeys:objectWithKeys.keysToSync apiVersion:apiVersion];
    [request.transportRequest setDebugInformationTranscoder:transcoder];
    
    if (request == nil) {
        RequireString(request != nil, "Transcoder %s returns nil request for keys: %s",
                      NSStringFromClass(transcoder.class).UTF8String,
                      [objectWithKeys.keysToSync.allObjects componentsJoinedByString:@", "].UTF8String);
    }
    
    ZMModifiedObjectSyncToken *token = [self.updatedObjects didStartSynchronizingKeys:request.keys forObject:objectWithKeys];
    NSDictionary *userInfo = request.userInfo;
    NSSet *keys = request.keys;
    
    ZM_WEAK(self);
    ZM_WEAK(request);
    [request.transportRequest addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.context block:^(ZMTransportResponse *response) {
        ZM_STRONG(self);
        ZM_STRONG(request);
        
        id <ZMUpstreamTranscoder> localTranscoder = self.transcoder;
        NSSet *keysToParse = [self.updatedObjects keysToParseAfterSyncingToken:token];
        if(response.result == ZMTransportResponseStatusSuccess) {
            BOOL transcoderNeedsMoreRequests = [localTranscoder updateUpdatedObject:objectWithKeys.object requestUserInfo:userInfo response:response keysToParse:keysToParse];
            BOOL needsMoreRequests = (keysToParse.count > 0) && transcoderNeedsMoreRequests;
            if (needsMoreRequests) {
                [self.updatedObjects didNotFinishToSynchronizeToken:token];
            } else {
                [self.updatedObjects didSynchronizeToken:token];
            }
        }
        else if (response.result == ZMTransportResponseStatusTemporaryError ||
                 response.result == ZMTransportResponseStatusTryAgainLater) {
            [self.updatedObjects didNotFinishToSynchronizeToken:token];
        }
        else if (response.result == ZMTransportResponseStatusExpired) {
            [self.updatedObjects didFailToSynchronizeToken:token];
            if ([localTranscoder respondsToSelector:@selector(requestExpiredForObject:forKeys:)]) {
                [localTranscoder requestExpiredForObject:objectWithKeys.object forKeys:objectWithKeys.keysToSync];
            }
        }
        else {
            BOOL shouldResyncObject = NO;
            if ([localTranscoder respondsToSelector:@selector(shouldRetryToSyncAfterFailedToUpdateObject:request:response:keysToParse:)]) {
                shouldResyncObject = [localTranscoder shouldRetryToSyncAfterFailedToUpdateObject:objectWithKeys.object request:request response:response keysToParse:keysToParse];
            }

            if (shouldResyncObject) {
                //if there is no new dependencies for currently synced object than we just try again
                [self.updatedObjects didFailToSynchronizeToken:token];
                [objectWithKeys.object setLocallyModifiedKeys:keys];
                [self addUpdatedObject:objectWithKeys.object];
            }
            else {
                [self.updatedObjects didFailToSynchronizeToken:token];
                ZMManagedObject *objectToRefetch = [localTranscoder objectToRefetchForFailedUpdateOfObject:objectWithKeys.object];
                objectToRefetch.needsToBeUpdatedFromBackend = YES;
            }
        }
        
        
    }]];

    return request.transportRequest;
}


- (NSString *)debugDescription;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p>", self.class, self];
    [description appendFormat:@" %@", self.trackedEntity.name];
    NSObject *t = (id) self.transcoder;
    [description appendFormat:@", transcoder: <%@ %p>", t.class, t];
    [description appendFormat:@", context: \"%@\"", self.context];
    return description;
}

@end



void ZMTrapUnableToGenerateRequest(NSSet *keys, id transcoder) {
    NSString *allKeys = [keys.allObjects componentsJoinedByString:@", "];
    NSString *classString = NSStringFromClass([transcoder class]);
    NSString *description = [NSString stringWithFormat:@"Transcoder %@ refuses to create request for keys: %@", classString, allKeys];
    ZMCrashFormat("Transcoder failed to generate request", __FILE__, __LINE__, "%s", description.UTF8String);
    assert(false);
}

