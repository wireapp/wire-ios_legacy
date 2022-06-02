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

@import WireUtilities;
@import UIKit;
@import WireCryptobox;

#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "NSManagedObjectContext+tests.h"
#import "ZMManagedObject.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"

#import <objc/runtime.h>
#import <libkern/OSAtomic.h>
#import <WireUtilities/WireUtilities-Swift.h>
#import <WireDataModel/WireDataModel-Swift.h>

NSString * const IsSyncContextKey = @"ZMIsSyncContext";
NSString * const IsSearchContextKey = @"ZMIsSearchContext";
NSString * const IsUserInterfaceContextKey = @"ZMIsUserInterfaceContext";
NSString * const IsEventContextKey = @"ZMIsEventDecoderContext";

static NSString * const SyncContextKey = @"ZMSyncContext";
static NSString * const UserInterfaceContextKey = @"ZMUserInterfaceContext";
static NSString * const IsRefreshOfObjectsDisabled = @"ZMIsRefreshOfObjectsDisabled";
static NSString * const IsSaveDisabled = @"ZMIsSaveDisabled";
static NSString * const IsFailingToSave = @"ZMIsFailingToSave";
static NSString * const ClearPersistentStoreOnStartKey = @"ZMClearPersistentStoreOnStart";
static NSString * const TimeOfLastSaveKey = @"ZMTimeOfLastSave";
static NSString * const FirstEnqueuedSaveKey = @"ZMTimeOfLastSave";
static NSString * const FailedToEstablishSessionStoreKey = @"FailedToEstablishSessionStoreKey";
static NSString * const DisplayNameGeneratorKey = @"DisplayNameGeneratorKey";
static NSString * const DelayedSaveActivityKey = @"DelayedSaveActivityKey";

static NSString* ZMLogTag ZM_UNUSED = @"NSManagedObjectContext";
//
// For testing, we want to use an NSInMemoryStoreType (it's faster).
// The only way for multiple contexts to share the same NSInMemoryStoreType is to share
// the persistent store coordinator.
//

@interface NSManagedObjectContext (CleanUp)

- (void)refreshUnneededObjects;

@end

@interface NSManagedObjectContext (Background)


@property (nonatomic, strong) BackgroundActivity *delayedSaveActivity;

@end

@implementation NSManagedObjectContext (Background)

- (BackgroundActivity *)delayedSaveActivity
{
    return self.userInfo[DelayedSaveActivityKey];
}

- (void)setDelayedSaveActivity:(BackgroundActivity *)delayedSaveActivity
{
    self.userInfo[DelayedSaveActivityKey] = delayedSaveActivity;
}

@end

@implementation NSManagedObjectContext (zmessaging)

- (BOOL)zm_isValidContext
{
    return self.zm_isSyncContext || self.zm_isUserInterfaceContext || self.zm_isSearchContext;
}

- (id)validUserInfoValueOfClass:(Class)class forKey:(NSString *)key
{
    id value = self.userInfo[key];
    if (value == nil) {
        return nil;
    }
    if (![value isKindOfClass:class]) {
        
        NSMutableString *userInfoKeys = [NSMutableString string];
        for(NSString *dictKey in self.userInfo.allKeys) {
            [userInfoKeys appendString:[NSString stringWithFormat:@"%@, ", dictKey]];
        }
        
        if ([value isKindOfClass:NSDictionary.class]) {
            NSMutableString *keys = [NSMutableString string];
            for (NSString *dictKey in ((NSDictionary*) value).allKeys) {
                [keys appendString:[NSString stringWithFormat:@"%@, ", dictKey]];
            }
            RequireString([value isKindOfClass:class], "Value for key %s is a dictionary: keys %s. \n User info has keys: %s", [key cStringUsingEncoding:NSUTF8StringEncoding], [keys cStringUsingEncoding:NSUTF8StringEncoding], [userInfoKeys cStringUsingEncoding:NSUTF8StringEncoding]);

        } else {
            RequireString([value isKindOfClass:class], "Value for key %s is not of class %s. \n User info has keys: %s", [key cStringUsingEncoding:NSUTF8StringEncoding], [NSStringFromClass(class) cStringUsingEncoding:NSUTF8StringEncoding], [userInfoKeys cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    return value;
}

- (BOOL)zm_isSyncContext
{
    return [[self validUserInfoValueOfClass:[NSNumber class] forKey:IsSyncContextKey] boolValue];
}

- (BOOL)zm_isUserInterfaceContext
{
    return [[self validUserInfoValueOfClass:[NSNumber class] forKey:IsUserInterfaceContextKey] boolValue];
}

- (BOOL)zm_isSearchContext
{
    return [self.userInfo[IsSearchContextKey] boolValue];
}

- (NSManagedObjectContext*)zm_syncContext
{
    if (self.zm_isSyncContext) {
        return self;
    }
    else {
        UnownedNSObject *unownedContext = self.userInfo[SyncContextKey];
        if (nil != unownedContext) {
            return (NSManagedObjectContext *)unownedContext.unbox;
        }
    }
    
    return nil;
}

- (void)setZm_syncContext:(NSManagedObjectContext *)zm_syncContext
{
    self.userInfo[SyncContextKey] = [[UnownedNSObject alloc] init:zm_syncContext];
}

- (NSManagedObjectContext*)zm_userInterfaceContext
{
    if (self.zm_isUserInterfaceContext) {
        return self;
    }
    else {
        UnownedNSObject *unownedContext = self.userInfo[UserInterfaceContextKey];
        if (nil != unownedContext) {
            return (NSManagedObjectContext *)unownedContext.unbox;
        }
    }
    
    return nil;
}

- (void)setZm_userInterfaceContext:(NSManagedObjectContext *)zm_userInterfaceContext
{
    self.userInfo[UserInterfaceContextKey] = [[UnownedNSObject alloc] init:zm_userInterfaceContext];
}

- (BOOL)zm_isRefreshOfObjectsDisabled;
{
    return [self.userInfo[IsRefreshOfObjectsDisabled] boolValue];
}

- (BOOL)zm_shouldRefreshObjectsWithSyncContextPolicy
{
    return self.zm_isSyncContext && !self.zm_isRefreshOfObjectsDisabled;
}

- (BOOL)zm_shouldRefreshObjectsWithUIContextPolicy
{
    return self.zm_isUserInterfaceContext && !self.zm_isRefreshOfObjectsDisabled;
}

- (DisplayNameGenerator *)zm_displayNameGenerator {
    return self.userInfo[DisplayNameGeneratorKey];
}

- (NSURL *)zm_storeURL {
    NSPersistentStore *store = self.persistentStoreCoordinator.persistentStores.firstObject;
    if (store != nil) {
        return [self.persistentStoreCoordinator URLForPersistentStore:store];
    } else {
        return nil;
    }
}

- (NSMutableSet *)zm_failedToEstablishSessionStore
{
    if (!self.zm_isSyncContext) {
        return nil;
    }
    
    if (nil == self.userInfo[FailedToEstablishSessionStoreKey]) {
        self.userInfo[FailedToEstablishSessionStoreKey] = [NSMutableSet set];
    }
    
    return self.userInfo[FailedToEstablishSessionStoreKey];
}


/// Fetch metadata for key from in-memory non-persisted metadata
/// or from persistent store metadata, in that order

/// !!! It is important to have this method in Objective-C, since the method
/// `-[NSPersistentStoreCoordinator metadataForPersistentStore:]` is returning an Objective-C `NSDictionary`, when
/// used from the Swift environment the return is unconditionally and recursively converted to Swift dictionary, making
/// a performance hit on the application.
- (id)persistentStoreMetadataForKey:(NSString *)key {
    id inMemoryValue = [self.nonCommittedMetadata objectForKey:key];
    if (nil != inMemoryValue) {
        return inMemoryValue;
    }
    
    if ([self.nonCommittedDeletedMetadataKeys containsObject:key]) {
        return nil;
    }
    
    NSPersistentStore *store = self.persistentStoreCoordinator.persistentStores.firstObject;
    id storedValue = [[self.persistentStoreCoordinator metadataForPersistentStore:store] objectForKey:key];
    if ([storedValue isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return storedValue;
}

- (BOOL)saveOrRollback;
{
    return [self saveOrRollbackIgnoringChanges:NO];
}

- (BOOL)forceSaveOrRollback;
{
    return [self saveOrRollbackIgnoringChanges:YES];
}

- (BOOL)saveOrRollbackIgnoringChanges:(BOOL)shouldIgnoreChanges;
{
    if(self.userInfo[IsSaveDisabled]) {
        return YES;
    }
    
    ZMLogDebug(@"%@ <%@: %p>.", NSStringFromSelector(_cmd), self.class, self);
    
    NSDictionary *oldMetadata = [self.persistentStoreCoordinator metadataForPersistentStore:[self firstPersistentStore]];
    BOOL hasMetadataChanges = [self makeMetadataPersistent];
    
    if (self.userInfo[IsFailingToSave]) {
        [self rollbackWithOldMetadata:oldMetadata];
        return NO;
    }
    
    // We need to save even if hasChanges is NO as long as the callState changes. An empty save will result in an empty did-save notification.
    // That notification in turn will result in a merge, even if it is empty, and thus merge the call state.
    if (self.zm_hasChanges || shouldIgnoreChanges || hasMetadataChanges) {
        NSError *error;
        ZMLogDebug(@"Saving <%@: %p>.", self.class, self);
        self.timeOfLastSave = [NSDate date];
        ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:10 label:[NSString stringWithFormat:@"Saving context %@", self.zm_isSyncContext ? @"sync": @"ui"]];
        if (! [self save:&error]) {
            ZMLogError(@"Failed to save: %@", error);
            [self reportSaveErrorWithError:error];
            [self rollbackWithOldMetadata:oldMetadata];
            [tp warnIfLongerThanInterval];
            return NO;
        }
        [tp warnIfLongerThanInterval];
        [self refreshUnneededObjects];
        self.zm_hasUserInfoChanges = NO;
    }
    else {
        ZMLogDebug(@"Not saving because there is no change");
    }
    return YES;
}

- (void)rollbackWithOldMetadata:(NSDictionary *)oldMetadata;
{
    [self rollback];
    [self.persistentStoreCoordinator setMetadata:oldMetadata forPersistentStore:[self firstPersistentStore]];
}

- (NSDate *)timeOfLastSave;
{
    return self.userInfo[TimeOfLastSaveKey];
}

- (void)setTimeOfLastSave:(NSDate *)date;
{
    if (date != nil) {
        self.userInfo[TimeOfLastSaveKey] = date;
    } else {
        [self.userInfo removeObjectForKey:TimeOfLastSaveKey];
    }
}

- (NSDate *)firstEnqueuedSave {
    return self.userInfo[FirstEnqueuedSaveKey];
}

- (void)setFirstEnqueuedSave:(NSDate *)date;
{
    if (date != nil) {
        self.userInfo[FirstEnqueuedSaveKey] = date;
    } else {
        [self.userInfo removeObjectForKey:FirstEnqueuedSaveKey];
    }
}

- (void)enqueueDelayedSave;
{
    [self enqueueDelayedSaveWithGroup:nil];
}

- (BOOL)saveIfTooManyChanges
{
    NSUInteger const changeCount = self.deletedObjects.count + self.insertedObjects.count + self.updatedObjects.count;
    NSUInteger const threshold = 200;
    if (threshold < changeCount) {
        ZMLogDebug(@"enqueueSaveIfTooManyChanges: calling -saveOrRollback synchronuously because change count is %llu.", (unsigned long long) changeCount);
        [self saveOrRollback];
        return YES;
    }
    return NO;
}

- (BOOL)saveIfDelayIsTooLong
{
    if (self.firstEnqueuedSave == nil) {
        self.firstEnqueuedSave = [NSDate date];
    } else {
        if ([[NSDate date] timeIntervalSinceDate:self.firstEnqueuedSave] > 0.25) {
            [self saveOrRollback];
            self.firstEnqueuedSave = nil;
            return YES;
        }
    }
    return NO;
}
    
- (BOOL)startActivity
{
    self.delayedSaveActivity = [[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:@"Delayed save"];
    return self.delayedSaveActivity != nil;
}
    
- (void)stopActivity
{
    if (self.delayedSaveActivity != nil) {
        [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:self.delayedSaveActivity];
        self.delayedSaveActivity = nil;
    }
}

- (void)enqueueDelayedSaveWithGroup:(ZMSDispatchGroup *)group;
{
    if(self.userInfo[IsSaveDisabled]) {
        return;
    }
    
    if ([self saveIfTooManyChanges] ||
        [self saveIfDelayIsTooLong])
    {
        [self stopActivity];
        return;
    }
    
    if (self.pendingSaveCounter == 0) {
        [self startActivity];
    }
    
    // Delay function (not to scale):
    //       ^
    //       │
    //  0.100│\
    //       │  \
    //       │    \
    //       │      \
    // delay │        \
    //       │          \
    //       │            \
    //  0.002│              +------------------
    //       │              :
    //       +———————————————————————————————————>
    //       0              1s
    //            time since last save
    
    const double delta_s = (self.timeOfLastSave != nil) ? (-[self.timeOfLastSave timeIntervalSinceNow]) : 10000;
    const double delay_s = (delta_s > 0.98) ? 0.002 : (-0.1*delta_s + 0.1);
    const unsigned int delay_ms = (unsigned int) lround(delay_s*1000);
    
    // Grab a unique number, for debugging only:
    static int32_t c;
    int32_t myCount = ++c;
    
    ZMLogDebug(@"enqueueDelayedSaveWithGroup: called (%d)", myCount);
    
    // This code is a bit daunting at first. There are a total of 3 groups:
    //
    // otherGroups: This keeps track of "the context is doing some work" INCLUDING delayed save
    // secondaryGroup: This keeps track of "the context is doing some work" EXCLUDING delayed save
    // group: Passed in group
    //
    // (1) We'll enter all groups.
    //
    // (2) We increment the pendingSaveCounter
    //
    // (2) After a tiny time interval, we'll leave the secondary group. Since calls to -performGroupedBlock:
    //     also get added to this group, we can use
    //         dispatch_group_notify(secondaryGroup, ...)
    //     to know that no further work is scheduled on this context. At that point we decrement pendingSaveCounter.
    //
    // (3) If pendingSaveCounter is 0 at this point (no outstanding saves), we perform the actual save.
    //
    // The pendingSaveCounter ensures that only the last enqueued save will perform the actual save, ie. it's
    // safe and efficient to call this method multiple times.
    //
    //     work -> enqueueSave -> work -> enqueueSave -> work -> enqueueSave
    //                                                                      \--> save at this point
    //
    
    
    // Enter all groups:
    if (group) {
        [group enter];
    }
    ZMSDispatchGroup *secondaryGroup;
    NSArray *otherGroups;
    {
        NSArray *groups = [self enterAllGroups];
        secondaryGroup = groups[1];
        NSMutableIndexSet *otherIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, groups.count)];
        [otherIndexes removeIndex:1];
        otherGroups = [groups objectsAtIndexes:otherIndexes];
    }
    
    ++self.pendingSaveCounter;
    
    // We'll wait just a little bit, just in case the group empties for a short span of time.
    {
        ZMLogDebug(@"dispatch_after() entered (%d)", myCount);
        dispatch_time_t when = dispatch_walltime(NULL, delay_ms * NSEC_PER_MSEC);
        dispatch_queue_t waitQueue = (ZMHasQualityOfServiceSupport() ?
                                      dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) :
                                      dispatch_get_global_queue(0, 0));
        dispatch_after(when, waitQueue, ^{
            [secondaryGroup leave];
            ZMLogDebug(@"dispatch_after() completed (%d)", myCount);
        });
    }
    
    // Once the save group is empty (no pending saves), we'll do the actual save:
    [secondaryGroup notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:^{
            NSInteger const c2 = --self.pendingSaveCounter;
            BOOL didSave = NO;
            if (c2 == 0) {
                ZMLogDebug(@"Calling -saveOrRollback (%d)", myCount);
                [self saveOrRollback];
                didSave = YES;
            } else {
                ZMLogDebug(@"Not calling -saveOrRollback (%d)", myCount);
            }
            if (group) {
                [group leave];
            }
            [self leaveAllGroups:otherGroups];
            if (didSave) {
                [self stopActivity];
            }
        }];
    }];
}

- (NSPersistentStore *)firstPersistentStore
{
    NSArray *stores = [self.persistentStoreCoordinator persistentStores];
    NSAssert(stores.count == 1, @"Invalid number of stores");
    NSPersistentStore *store = stores[0];
    return store;
}

@end



@implementation NSManagedObjectContext (zmessagingTests)

- (void)enableForceRollback;
{
    self.userInfo[IsFailingToSave] = @YES;
}

- (void)disableForceRollback;
{
    [self.userInfo removeObjectForKey:IsFailingToSave];
}

- (void)disableSaves;
{
    self.userInfo[IsSaveDisabled] = @YES;
}

- (void)enableSaves;
{
    [self.userInfo removeObjectForKey:IsSaveDisabled];
}

- (void)markAsSyncContext;
{
    [self performBlockAndWait:^{
        self.userInfo[IsSyncContextKey] = @YES;
    }];
}

- (void)markAsSearchContext;
{
    [self performBlockAndWait:^{
        self.userInfo[IsSearchContextKey] = @YES;
    }];
}

- (void)markAsUIContext
{
    [self performBlockAndWait:^{
        self.userInfo[IsUserInterfaceContextKey] = @YES;
    }];
}

- (void)resetContextType
{
    [self performBlockAndWait:^{
        self.userInfo[IsSyncContextKey] = @NO;
        self.userInfo[IsUserInterfaceContextKey] = @NO;
        self.userInfo[IsSearchContextKey] = @NO;
    }];
}

- (void)disableObjectRefresh;
{
    self.userInfo[IsRefreshOfObjectsDisabled] = @YES;
}

@end



@implementation NSManagedObjectContext (CleanUp)

- (void)refreshUnneededObjects
{
    if(self.zm_shouldRefreshObjectsWithSyncContextPolicy) {
        [ZMConversation refreshObjectsThatAreNotNeededInSyncContext:self];
    }
}


@end
