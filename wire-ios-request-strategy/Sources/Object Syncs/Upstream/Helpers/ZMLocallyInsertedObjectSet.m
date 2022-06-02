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
#import <WireDataModel/ZMManagedObject.h>
#import "ZMLocallyInsertedObjectSet.h"


@interface ZMLocallyInsertedObjectSet ()

@property (nonatomic, readonly) NSMutableSet *insertedObjects;
@property (nonatomic, readonly) NSMutableSet *currentlySynchronizedObjects;

@end



@implementation ZMLocallyInsertedObjectSet

- (instancetype)init
{
    self = [super init];
    if(self) {
        _insertedObjects = [NSMutableSet set];
        _currentlySynchronizedObjects = [NSMutableSet set];
    }
    return self;
}

- (void)addObjectToSynchronize:(ZMManagedObject *)object
{
    [self.insertedObjects addObject:object];
}

- (void)removeObjectToSynchronize:(ZMManagedObject *)object;
{
    [self.insertedObjects removeObject:object];
}

- (ZMManagedObject *)anyObjectToSynchronize
{
    NSMutableSet *candidates = [self.insertedObjects mutableCopy];
    [candidates minusSet:self.currentlySynchronizedObjects];
    return [candidates anyObject];
}

- (void)didFinishSynchronizingObject:(ZMManagedObject *)object
{
    [self.currentlySynchronizedObjects removeObject:object];
    [self removeObjectToSynchronize:object];
}

- (void)didStartSynchronizingObject:(ZMManagedObject *)object
{
    RequireString([self.insertedObjects containsObject:object], "Synced object was never added: %s", NSStringFromClass([object class]).UTF8String);
    [self.currentlySynchronizedObjects addObject:object];
}

- (void)didFailSynchronizingObject:(ZMManagedObject *)object
{
    RequireString([self.currentlySynchronizedObjects containsObject:object], "Finished to sync object that was never started: %s", NSStringFromClass([object class]).UTF8String);
    [self.currentlySynchronizedObjects removeObject:object];
}

- (BOOL)isSynchronizingObject:(ZMManagedObject *)object
{
    return [self.currentlySynchronizedObjects containsObject:object];
}

- (NSUInteger)count;
{
    return self.insertedObjects.count;
}

- (NSString *)debugDescription;
{
    NSSet *inserted = [self.insertedObjects mapWithBlock:^id(NSManagedObject *mo) {
        return mo.objectID.URIRepresentation;
    }];
    NSSet *synchronizing = [self.currentlySynchronizedObjects mapWithBlock:^id(NSManagedObject *mo) {
        return mo.objectID.URIRepresentation;
    }];
    return [NSString stringWithFormat:@"<%@: %p> inserted %u: {%@}, synchronizing %u: {%@}",
            self.class, self,
            (unsigned) self.insertedObjects.count,
            [inserted.allObjects componentsJoinedByString:@", "],
            (unsigned) self.currentlySynchronizedObjects.count,
            [synchronizing.allObjects componentsJoinedByString:@", "]];
}

@end
