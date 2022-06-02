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

#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMLocallyInsertedObjectSet.h"
#import <WireRequestStrategy/WireRequestStrategy-Swift.h>
#import "ZMLocallyModifiedObjectSyncStatus.h"
#import "ZMLocallyModifiedObjectSet.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMUpstreamRequest.h"

@interface ZMUpstreamInsertedObjectSync ()

@property (nonatomic) ZMLocallyInsertedObjectSet *insertedObjects;
@property (nonatomic) NSEntityDescription *trackedEntity;
@property (nonatomic, weak) id<ZMUpstreamTranscoder> transcoder;
@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) NSPredicate *insertPredicate;
@property (nonatomic) DependentObjectsObjc *insertedObjectsWithDependencies;
@property (nonatomic, readonly) BOOL transcodeSupportsExpiration;
@property (nonatomic) NSMutableSet *ignoredObjects;
@property (nonatomic) NSPredicate *filter;

@end

static NSString* ZMLogTag = @"Network";

@implementation ZMUpstreamInsertedObjectSync

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
              managedObjectContext:(NSManagedObjectContext *)context;
{
    return [self initWithTranscoder:transcoder entityName:entityName filter:nil managedObjectContext:context];
}

- (instancetype)initWithTranscoder:(id<ZMUpstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
                            filter:(NSPredicate *)filter
              managedObjectContext:(NSManagedObjectContext *)context;
{
    RequireString(transcoder != nil, "Transcoder can't be nil");
    RequireString(entityName != nil, "Entity name can't be nil");
    RequireString(context != nil, "MOC can't be nil");
    self = [super init];
    if(self) {
        self.ignoredObjects = [NSMutableSet set];
        self.transcoder = transcoder;
        _logPredicateActivity = NO;
        _transcodeSupportsExpiration = [transcoder respondsToSelector:@selector(requestExpiredForObject:forKeys:)];
         
        self.insertedObjects = [[ZMLocallyInsertedObjectSet alloc] init];
        
        self.trackedEntity = [context.persistentStoreCoordinator.managedObjectModel entitiesByName][entityName];
        RequireString(self.trackedEntity != nil, "Unable to retrieve entity by name");
        
        self.context = context;
        
        Class moClass = NSClassFromString(self.trackedEntity.managedObjectClassName);
        self.insertPredicate = [moClass predicateForObjectsThatNeedToBeInsertedUpstream];
        self.filter = filter;
        
        if ([transcoder respondsToSelector:@selector(dependentObjectNeedingUpdateBeforeProcessingObject:)]) {
            self.insertedObjectsWithDependencies = [[DependentObjectsObjc alloc] init];
        }
    }
    return self;
}

- (BOOL)hasCurrentlyRunningRequests
{
    return self.insertedObjects.count > 0;
}

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    Class moClass = NSClassFromString(self.trackedEntity.managedObjectClassName);
    return [moClass sortedFetchRequestWithPredicate:self.insertPredicate];
}

- (void)addTrackedObjects:(NSSet *)objects;
{
    for (ZMManagedObject *mo in objects) {
        if ([self shouldAddInsertedObject:mo]) {
            [self addInsertedObject:mo];
        }
    }
}

- (void)objectsDidChange:(NSSet *)objects
{
    for(ZMManagedObject *obj in objects) {
        if ([obj isKindOfClass:[NSManagedObject class]] && obj.entity == self.trackedEntity)
        {
            if (self.logPredicateActivity) {
                ZMLogInfo(@"%@: obj: %@, self.insertPredicate = %@, [self shouldAddInsertedObject:obj] = %d", self, obj, self.insertPredicate, [self shouldAddInsertedObject:obj]);
            }
            if([self.insertPredicate evaluateWithObject:obj] && [self shouldAddInsertedObject:obj])
            {
                [self addInsertedObject:obj];
                [self.ignoredObjects removeObject:obj];
            }
            else
            {
                [self.insertedObjects removeObjectToSynchronize:obj];
                if ([self.insertedObjects isSynchronizingObject:obj]) {
                    [self.ignoredObjects addObject:obj];
                }
            }
        }
        [self checkForUpdatedDependency:obj];
    }
}

- (BOOL)shouldAddInsertedObject:(ZMManagedObject *)object
{
    BOOL passedFilter = (self.filter == nil ||
                         (self.filter != nil && [self.filter evaluateWithObject:object]));
    if (self.logPredicateActivity) {
        ZMLogInfo(@"%@: passFilter = %d", self, passedFilter);
    }
    return passedFilter;
}

- (void)checkForUpdatedDependency:(ZMManagedObject *)existingDependency;
{
    [self.insertedObjectsWithDependencies enumerateAndRemoveObjectsForDependency:existingDependency usingBlock:^BOOL(ZMManagedObject *mo) {
        id newDependency = [self.transcoder dependentObjectNeedingUpdateBeforeProcessingObject:mo];
        if (newDependency == nil) {
            [self.insertedObjects addObjectToSynchronize:mo];
            return YES;
        } else if (newDependency == existingDependency) {
            return NO;
        } else {
            [self.insertedObjectsWithDependencies addDependentObject:mo dependency:newDependency];
            return YES;
        }
    }];
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;
{
    return [self processNextInsertWithAPIVersion:apiVersion];
}

/// returns false if object has dependencies, adding it to insertedObjectsWithDependencies
- (BOOL)addInsertedObject:(ZMManagedObject *)mo
{
    if (self.logPredicateActivity) {
        ZMLogInfo(@"%@: addInsertedObject for %@", self, mo);
    }
    if (self.insertedObjectsWithDependencies) {
        id dependency = [self.transcoder dependentObjectNeedingUpdateBeforeProcessingObject:mo];
        if (self.logPredicateActivity) {
            ZMLogInfo(@"%@: dependency = %@", self, dependency);
        }

        if (dependency != nil) {
            [self.insertedObjectsWithDependencies addDependentObject:mo dependency:dependency];
            return NO;
        }
    }
    [self.insertedObjects addObjectToSynchronize:mo];
    return YES;
}


- (ZMManagedObject *)nextObjectToSync
{
    ZMManagedObject *nextObject;
    do {
        nextObject = [self.insertedObjects anyObjectToSynchronize];
        if (nextObject == nil) {
            return nil;
        }
        if ([self.insertPredicate evaluateWithObject:nextObject] && !nextObject.isZombieObject) {
            break;
        }
        // Does no longer match, ie. we're done:
        [self.insertedObjects didFinishSynchronizingObject:nextObject];
    } while (YES);
    return nextObject;
}

- (ZMTransportRequest *)processNextInsertWithAPIVersion:(APIVersion)apiVersion
{
    ZMManagedObject *nextObject = [self nextObjectToSync];
    if (nextObject == nil) {
        return nil;
    }
    
    id<ZMUpstreamTranscoder> transcoder = [self transcoder];
    if ([transcoder respondsToSelector:@selector(shouldCreateRequestToSyncObject:forKeys:withSync:)]) {
        if (![transcoder shouldCreateRequestToSyncObject:nextObject forKeys:[NSSet set] withSync:self]) {
            return nil;
        }
    }
    
    ZMUpstreamRequest *request = [transcoder requestForInsertingObject:nextObject forKeys:nil apiVersion:apiVersion];
    
    if (request == nil) {
        [self.insertedObjects didFinishSynchronizingObject:nextObject];
        [nextObject resetLocallyModifiedKeys:nextObject.keysThatHaveLocalModifications];
        return nil;
    }

    [self.insertedObjects didStartSynchronizingObject:nextObject];

    ZM_WEAK(self);
    ZM_WEAK(request);
    [request.transportRequest addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.context block:^(ZMTransportResponse *response) {
        ZM_STRONG(self);
        ZM_STRONG(request);
        
        BOOL didFinish = YES;
        
        if ([self.ignoredObjects containsObject:nextObject]) {
            [self.ignoredObjects removeObject:nextObject];
        }
        else if (response.result == ZMTransportResponseStatusSuccess) {
            request.transportResponse = response;
            [transcoder updateInsertedObject:nextObject request:request response:response];
        }
        else if (response.result == ZMTransportResponseStatusPermanentError) {
            // instead of deleting the object, we should set an "isDeleted" flag, so that UI doesn't crash
            // https://wearezeta.atlassian.net/browse/MEC-66
            
            BOOL shouldResyncObject = NO;

            if ([transcoder respondsToSelector:@selector(shouldRetryToSyncAfterFailedToUpdateObject:request:response:keysToParse:)]) {
                shouldResyncObject = [transcoder shouldRetryToSyncAfterFailedToUpdateObject:nextObject request:request response:response keysToParse:[NSSet set]];
                if (shouldResyncObject) {
                    //if there is no new dependencies for currently synced object then we just try again
                    didFinish = ! [self addInsertedObject:nextObject];
                }
            }
            
            if (!shouldResyncObject) {
                [self.context deleteObject:nextObject];
            }
        }
        else if (response.result == ZMTransportResponseStatusTryAgainLater) {
            didFinish = NO;
        }
        else if (response.result == ZMTransportResponseStatusExpired) {
            if ([transcoder respondsToSelector:@selector(requestExpiredForObject:forKeys:)]) {
                [transcoder requestExpiredForObject:nextObject forKeys:request.keys];
            }
        }
        
        if (didFinish) {
            [self.insertedObjects didFinishSynchronizingObject:nextObject];
        } else {
            [self.insertedObjects didFailSynchronizingObject:nextObject];
        }
        
        [self.context enqueueDelayedSaveWithGroup:response.dispatchGroup];
    }]];
    
    return request.transportRequest;
}

- (NSString *)debugDescription;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p>", self.class, self];
    [description appendFormat:@" %@", self.trackedEntity.name];
    [description appendFormat:@", inserted <%@ %p> count = %u", self.insertedObjects.class, self.insertedObjects, (unsigned) self.insertedObjects.count];
    NSObject *t = (id) self.transcoder;
    [description appendFormat:@", transcoder: <%@ %p>", t.class, t];
    [description appendFormat:@", context: \"%@\"", self.context];
    return description;
}

@end
