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

#import "ZMLocallyModifiedObjectSyncStatus.h"
#import <WireDataModel/ZMManagedObject+Internal.h>

@interface ZMLocallyModifiedObjectSyncStatusToken : NSObject

@property (nonatomic, readonly) NSDictionary *previousValues;
@property (nonatomic, readonly) NSSet *keys;
@property (nonatomic, readonly) ZMManagedObject *object;

- (instancetype)initWithObject:(ZMManagedObject *)object keys:(NSSet *)keys;

- (NSSet *)keysThatHaveNewValues;

@end



@implementation ZMLocallyModifiedObjectSyncStatusToken

- (instancetype)initWithObject:(ZMManagedObject *)object keys:(NSSet *)keys
{
    self = [super self];
    if(self) {
        NSMutableDictionary *previousValues = [NSMutableDictionary dictionary];
        for(NSString *key in keys) {
            previousValues[key] = [object valueForKey:key] ?: [NSNull null];
        }
        _previousValues = previousValues;
        _object = object;
    }
    return self;
}

- (NSSet *)keys
{
    return [NSSet setWithArray:self.previousValues.allKeys];
}

- (NSSet *)keysThatHaveNewValues
{
    NSMutableSet *keysWithNewValues = [NSMutableSet set];
    for(NSString *key in self.keys) {
        id newValue = [self.object valueForKey:key] ?: [NSNull null];
        id oldValue = self.previousValues[key];
        
        if( (newValue != oldValue) && ! [newValue isEqual:oldValue]) {
            [keysWithNewValues addObject:key];
        }
    }
    return keysWithNewValues;
}

@end







@interface ZMLocallyModifiedObjectSyncStatus ()

@property (nonatomic, readonly) NSSet *trackedKeys;
@property (nonatomic, readonly) NSMutableSet *keysWithSyncInProgress;

@end



@implementation ZMLocallyModifiedObjectSyncStatus

ZM_EMPTY_ASSERTING_INIT()

- (instancetype)initWithObject:(ZMManagedObject *)object trackedKeys:(NSSet *)trackedKeys;
{
    Require(object != nil);
    Require(trackedKeys != nil);
    Require(trackedKeys.count != 0);

    self = [super init];
    if (self) {
        _object = object;
        _trackedKeys = [trackedKeys mutableCopy];
        if (self.keysToSynchronize.count == 0) {
            return nil;
        }
        _keysWithSyncInProgress = [NSMutableSet set];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> tracked keys: {%@}, keys in progress: {%@}",
            self.class, self,
            [self.trackedKeys.allObjects componentsJoinedByString:@", "],
            [self.keysWithSyncInProgress.allObjects componentsJoinedByString:@", "]];
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:ZMLocallyModifiedObjectSyncStatus.class]) {
        return NO;
    }
    ZMLocallyModifiedObjectSyncStatus *other = object;
    return self.object == other.object;
}

- (NSSet *)keysToSynchronize
{
    NSMutableSet *keysToSynchronize = [NSMutableSet setWithSet:self.trackedKeys];
    [keysToSynchronize intersectSet:self.object.keysThatHaveLocalModifications];
    [keysToSynchronize minusSet:self.keysWithSyncInProgress];
    return keysToSynchronize;
}

- (NSUInteger)hash;
{
    return self.object.hash;
}

- (BOOL)isDone
{
    return self.keysToSynchronize.count == 0 && self.keysWithSyncInProgress.count == 0;
}

- (ZMLocallyModifiedObjectSyncStatusToken *)startSynchronizingKeys:(NSSet *)keys;
{
    ZMLocallyModifiedObjectSyncStatusToken *token = [[ZMLocallyModifiedObjectSyncStatusToken alloc] initWithObject:self.object keys:keys];
    [self.keysWithSyncInProgress unionSet:keys];
    return token;
}

- (NSSet *)returnChangedKeysAndFinishTokenSync:(ZMLocallyModifiedObjectSyncStatusToken *)token;
{
    NSSet *changedKeys = [token keysThatHaveNewValues];
    [self.keysWithSyncInProgress minusSet:token.keys];
    return changedKeys;
}

- (void)resetLocallyModifiedKeysForToken:(ZMLocallyModifiedObjectSyncStatusToken *)token;
{
    [self.keysWithSyncInProgress minusSet:token.keys];
    [self.object resetLocallyModifiedKeys:token.keys];
}

@end
