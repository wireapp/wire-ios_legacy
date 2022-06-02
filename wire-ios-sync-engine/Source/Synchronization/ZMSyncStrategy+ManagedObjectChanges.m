//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


#import "ZMSyncStrategy+Internal.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"
#import "WireSyncEngineLogs.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

@implementation ZMSyncStrategy (ManagedObjectChanges)

- (void)logDidSaveNotification:(NSNotification *)note;
{
    NSManagedObjectContext * ZM_UNUSED moc = note.object;
    ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"<%@: %p> did save. Context type = %@",
                         moc.class, moc,
                         moc.zm_isUserInterfaceContext ? @"UI" : moc.zm_isSyncContext ? @"Sync" : @"");
    NSSet *inserted = note.userInfo[NSInsertedObjectsKey];
    if (inserted.count > 0) {
        NSString * ZM_UNUSED description = [[inserted.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Inserted: %@", description);
        [self.eventProcessingTracker registerDataInsertionPerformedWithAmount:inserted.count];
    }
    NSSet *updated = note.userInfo[NSUpdatedObjectsKey];
    if (updated.count > 0) {
        NSString * ZM_UNUSED description = [[updated.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Updated: %@", description);
        [self.eventProcessingTracker registerDataUpdatePerformedWithAmount:updated.count];
    }
    NSSet *deleted = note.userInfo[NSDeletedObjectsKey];
    if (deleted.count > 0) {
        NSString * ZM_UNUSED description = [[deleted.allObjects mapWithBlock:^id(NSManagedObject *mo) {
            return mo.objectID.URIRepresentation;
        }] componentsJoinedByString:@", "];
        ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_CORE_DATA, @"    Deleted: %@", description);
        [self.eventProcessingTracker registerDataDeletionPerformedWithAmount:deleted.count];
    }
}

- (void)managedObjectContextDidSave:(NSNotification *)note;
{
    if(self.tornDown || self.contextMergingDisabled) {
        return;
    }
    
    if([ZMSLog getLevelWithTag:ZMTAG_CORE_DATA] == ZMLogLevelDebug
       || [ZMSLog getLevelWithTag:ZMTAG_EVENT_PROCESSING] == ZMLogLevelDebug) {
        [self logDidSaveNotification:note];
    }
    
    NSManagedObjectContext *mocThatSaved = note.object;
    NSManagedObjectContext *strongUiMoc = self.uiMOC;
    NSDictionary *userInfo = [mocThatSaved.userInfo copy];
    
    if (mocThatSaved.zm_isUserInterfaceContext && strongUiMoc != nil) {
        if(mocThatSaved != strongUiMoc) {
            RequireString(mocThatSaved == strongUiMoc, "Not the right MOC!");
        }
        
        NSSet *insertedObjectsIDs = [self objectIDsetFromObject:note.userInfo[NSInsertedObjectsKey]];
        NSSet *updatedObjectsIDs = [self objectIDsetFromObject:note.userInfo[NSUpdatedObjectsKey]];
        
        ZM_WEAK(self);
        [self.syncMOC performGroupedBlock:^{
            ZM_STRONG(self);
            if(self == nil || self.tornDown) {
                return;
            }
                        
            [self.syncMOC mergeUserInfoFromUserInfo:userInfo];
            [self.syncMOC mergeChangesFromContextDidSaveNotification:note];
            [self.syncMOC processPendingChanges]; // We need this because merging sometimes leaves the MOC in a 'dirty' state
            
            NSSet *syncInsertedObjects = [self objectSetFromObjectIDs:insertedObjectsIDs inContext:self.syncMOC];
            NSSet *syncUpdatedObjects = [self objectSetFromObjectIDs:updatedObjectsIDs inContext:self.syncMOC];
            [self processSaveWithInsertedObjects:syncInsertedObjects updateObjects:syncUpdatedObjects];
            
            [self.eventProcessingTracker registerSavePerformed];
        }];
    } else if (mocThatSaved.zm_isSyncContext) {
        RequireString(mocThatSaved == self.syncMOC, "Not the right MOC!");
        
        NSSet<NSManagedObjectID*>* changedObjectsIDs = [self extractManagedObjectIDsFrom:note];
        
        NSSet *insertedObjects = note.userInfo[NSInsertedObjectsKey];
        NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
        [self processSaveWithInsertedObjects:insertedObjects updateObjects:updatedObjects];
        
        ZM_WEAK(self);
        [strongUiMoc performGroupedBlock:^{
            ZM_STRONG(self);
            if(self == nil || self.tornDown) {
                return;
            }
            
            [strongUiMoc mergeUserInfoFromUserInfo:userInfo];
            [strongUiMoc mergeChangesFromContextDidSaveNotification:note];
            [strongUiMoc processPendingChanges]; // We need this because merging sometimes leaves the MOC in a 'dirty' state
            [self.notificationDispatcher didMergeChanges:changedObjectsIDs];
            [self.eventProcessingTracker registerSavePerformed];
        }];
    }
    
    [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
}

- (NSSet<NSManagedObjectID*>*)extractManagedObjectIDsFrom:(NSNotification *)note
{
    NSSet<NSManagedObjectID*>* changedObjectsIDs;
    if (note.userInfo[NSUpdatedObjectsKey] != nil) {
        NSSet<NSManagedObject *>* changedObjects = note.userInfo[NSUpdatedObjectsKey];
        changedObjectsIDs = [changedObjects mapWithBlock:^id(NSManagedObject* obj) {
            return obj.objectID;
        }];
    } else {
        changedObjectsIDs = [NSSet set];
    }
    return changedObjectsIDs;
}

- (BOOL)processSaveWithInsertedObjects:(NSSet *)insertedObjects updateObjects:(NSSet *)updatedObjects
{
    if (insertedObjects.count == 0 && updatedObjects.count == 0) {
        return NO;
    }
    
    NSSet *allObjects = [NSSet zmSetByCompiningSets:insertedObjects, updatedObjects, nil];
    
    for (id<ZMContextChangeTracker> tracker in self.strategyDirectory.contextChangeTrackers) {
        [tracker objectsDidChange:allObjects];
    }
    
    return YES;
}

- (NSSet *)objectSetFromObjectIDs:(NSSet *)objectIDs inContext:(NSManagedObjectContext *)moc
{
    NSMutableSet *objects = [NSMutableSet set];
    for(NSManagedObjectID *objId in objectIDs) {
        NSManagedObject *obj = [moc objectWithID:objId];
        if(obj) {
            [objects addObject:obj];
        }
    }
    return objects;
}

- (NSSet *)objectIDsetFromObject:(NSSet *)objects
{
    NSMutableSet *objectIds = [NSMutableSet set];
    for(NSManagedObject* obj in objects) {
        [objectIds addObject:obj.objectID];
    }
    return objectIds;
}

@end
