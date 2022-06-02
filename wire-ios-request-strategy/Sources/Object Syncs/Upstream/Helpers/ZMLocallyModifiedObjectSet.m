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

#import "ZMLocallyModifiedObjectSet.h"
#import "ZMLocallyModifiedObjectSyncStatus.h"
#import <WireDataModel/ZMManagedObject+Internal.h>

@interface ZMObjectWithKeys ()

+ (instancetype)object:(ZMManagedObject *)object withKeys:(NSSet *)keys;

@end



@implementation ZMObjectWithKeys

+ (instancetype)object:(ZMManagedObject *)object withKeys:(NSSet *)keys;
{
    ZMObjectWithKeys *objectWithKeys = [[ZMObjectWithKeys alloc] init];
    objectWithKeys->_object = object;
    objectWithKeys->_keysToSync = keys;
    return objectWithKeys;
}

@end



@interface ZMModifiedObjectSyncToken : NSObject

@property (nonatomic) ZMLocallyModifiedObjectSyncStatus *objectSyncStatus;
@property (nonatomic) ZMLocallyModifiedObjectSyncStatusToken *syncToken;
@property (nonatomic) NSSet *keysToSynchronize;

@end



@implementation ZMModifiedObjectSyncToken

- (NSString *)description
{
    id<NSObject> token = (id) self.syncToken;
    return [NSString stringWithFormat:@"<%@: %p> status: <%@: %p>, token <%@: %p>, keys: {%@}",
            self.class, self,
            self.objectSyncStatus.class, self.objectSyncStatus,
            token.class, token,
            [self.keysToSynchronize.allObjects componentsJoinedByString:@", "]];
}

@end



@interface ZMLocallyModifiedObjectSet ()

@property (nonatomic, readonly) BOOL trackAllKeys;
@property (nonatomic, readonly) NSMutableDictionary *objectIDsToStatus;

@end


@implementation ZMLocallyModifiedObjectSet

- (instancetype)init
{
    self = [super init];
    if (self) {
        _trackedKeys = nil;
        _objectIDsToStatus = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithTrackedKeys:(NSSet *)keys;
{
    self = [super init];
    if (self) {
        _trackedKeys = [keys copy];
        _objectIDsToStatus = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)trackAllKeys
{
    return self.trackedKeys == nil;
}

- (void)addPossibleObjectToSynchronize:(ZMManagedObject *)object;
{
    RequireString(! object.objectID.isTemporaryID, "Passing in a object with a temporary ID: %s", NSStringFromClass([object class]).UTF8String);
    RequireString(object != nil, "Attempting to add nil.");
   
    ZMLocallyModifiedObjectSyncStatus *preExistingStatus = self.objectIDsToStatus[object.objectID];
    if(preExistingStatus != nil) {
        if (preExistingStatus.isDone) {
            [self.objectIDsToStatus removeObjectForKey:object.objectID];
        }
        return;
    }
    
    NSSet *trackedKeys = self.trackAllKeys ? object.keysTrackedForLocalModifications : self.trackedKeys;
    ZMLocallyModifiedObjectSyncStatus *modifiedStatus = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:object trackedKeys:trackedKeys];
    
    if (modifiedStatus != nil) {
        self.objectIDsToStatus[object.objectID] = modifiedStatus;
    }
}

- (ZMObjectWithKeys *)anyObjectToSynchronize;
{
    for (ZMLocallyModifiedObjectSyncStatus *status in self.objectIDsToStatus.allValues) {
        NSSet *keysToSync = status.keysToSynchronize;
        if (keysToSync.count != 0) {
            return [ZMObjectWithKeys object:status.object withKeys:keysToSync];
        }
        
        if(status.isDone) {
            [self.objectIDsToStatus removeObjectForKey:status.object.objectID];
        }
    }
    return nil;
}

- (ZMModifiedObjectSyncToken *)didStartSynchronizingKeys:(NSSet *)keys forObject:(ZMObjectWithKeys *)object
{
    ZMModifiedObjectSyncToken *token = [[ZMModifiedObjectSyncToken alloc] init];
    
    ZMLocallyModifiedObjectSyncStatus *syncStatus = self.objectIDsToStatus[object.object.objectID];
    token.objectSyncStatus = syncStatus;
    token.syncToken = [syncStatus startSynchronizingKeys:keys];
    token.keysToSynchronize = keys;
    return token;
}

- (void)didFailToSynchronizeToken:(ZMModifiedObjectSyncToken *)token
{
    [token.objectSyncStatus resetLocallyModifiedKeysForToken:token.syncToken];
    [self removeObjectSyncStatusIfDone:token.objectSyncStatus];
}

- (void)didNotFinishToSynchronizeToken:(ZMModifiedObjectSyncToken *)token
{
    [token.objectSyncStatus returnChangedKeysAndFinishTokenSync:token.syncToken];
}

- (void)didSynchronizeToken:(ZMModifiedObjectSyncToken *)token;
{
    [token.objectSyncStatus resetLocallyModifiedKeysForToken:token.syncToken];
    [self removeObjectSyncStatusIfDone:token.objectSyncStatus];
}

- (void)removeObjectSyncStatusIfDone:(ZMLocallyModifiedObjectSyncStatus *)status;
{
    if (status.isDone) {
        [self.objectIDsToStatus removeObjectForKey:status.object.objectID];
    }
}

- (NSSet *)keysToParseAfterSyncingToken:(ZMModifiedObjectSyncToken *)token
{
    NSSet *changedKeys = [token.objectSyncStatus returnChangedKeysAndFinishTokenSync:token.syncToken];
    NSMutableSet *keysToChange = [token.keysToSynchronize mutableCopy];
    [keysToChange minusSet:changedKeys];
    return keysToChange;
}

- (BOOL)hasOutstandingItems;
{
    return (0 < self.objectIDsToStatus.count);
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> hasOutstandingItems %d; %@", [self class], self, self.hasOutstandingItems, self.objectIDsToStatus];
}


@end
