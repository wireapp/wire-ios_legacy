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
@import WireDataModel;

#import "ZMChangeTrackerBootstrap+Testing.h"
#import "ZMContextChangeTracker.h"

@interface ZMChangeTrackerBootstrap ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSArray *changeTrackers;
@property (nonatomic) NSMapTable *entityToRequestMap;
@property (nonatomic, readonly, copy) NSDictionary *entitiesByName;

@end



@implementation ZMChangeTrackerBootstrap

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context changeTrackers:(NSArray *)changeTrackers
{
    self = [super init];
    if (self) {
        self.managedObjectContext = context;
        _entitiesByName = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName copy];
        self.changeTrackers = changeTrackers;
    }
    return self;
}


- (NSEntityDescription *)entityForEntityName:(NSString *)name;
{
    Require(name != nil);
    NSEntityDescription *entity = self.entitiesByName[name];
    RequireString(entity != nil, "Entity not found.");
    return entity;
}

- (void)fetchObjectsForChangeTrackers
{
    NSArray *fetchRequests = [self.changeTrackers mapWithBlock:^id(id tracker) {
        return [tracker fetchRequestForTrackedObjects];
    }];
    
    NSMapTable *entityToRequestMap = [self sortFetchRequestsByEntity:fetchRequests];
    NSMapTable *entityToResultsMap = [self executeMappedFetchRequests:entityToRequestMap];
    
    for (id <ZMContextChangeTracker> tracker in self.changeTrackers) {
        NSFetchRequest *request = [tracker fetchRequestForTrackedObjects];
        if (request == nil) {
            continue;
        }
        NSEntityDescription *entity = [self entityForEntityName:request.entityName];
        NSArray *results = [entityToResultsMap objectForKey:entity];
        
        NSMutableSet *objectsToUpdate = [NSMutableSet set];
        for (NSManagedObject *object in results) {
            if ([request.predicate evaluateWithObject:object]){
                [objectsToUpdate addObject:object];
            }
        }
        if (objectsToUpdate.count > 0) {
            [tracker addTrackedObjects:objectsToUpdate];
        }
    }
}

- (NSMapTable *)sortFetchRequestsByEntity:(NSArray *)fetchRequests;
{
    NSMapTable *requestsMap = [NSMapTable strongToStrongObjectsMapTable];
    
    for (NSFetchRequest *request in fetchRequests){
        if (request.predicate == nil) {
            continue;
        }
        NSEntityDescription *entity = [self entityForEntityName:request.entityName];
        NSSet *predicates = [requestsMap objectForKey:entity];
        if ( predicates == nil) {
            [requestsMap setObject:[NSSet setWithObject:request.predicate] forKey:entity];
        } else {
            [requestsMap setObject:[predicates setByAddingObject:request.predicate] forKey:entity];
        }
    }
    return requestsMap;
}


- (NSMapTable *)executeMappedFetchRequests:(NSMapTable *)entityToRequestsMap;
{
    Require(entityToRequestsMap != nil);
    
    NSMapTable *resultsMap = [NSMapTable strongToStrongObjectsMapTable];

    for (NSEntityDescription *entity in entityToRequestsMap) {
        NSSet *predicates = [entityToRequestsMap objectForKey:entity];
        NSFetchRequest *fetchRequest = [self compoundRequestForEntity:entity predicates:predicates];
        
        NSArray *result = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        if (result.count > 0){
            [resultsMap setObject:result forKey:entity];
        }
    }
    
    return resultsMap;
}

- (NSFetchRequest *)compoundRequestForEntity:(NSEntityDescription *)entity predicates:(NSSet *)predicates
{
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[predicates allObjects]];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    fetchRequest.predicate = compoundPredicate;
    [fetchRequest configureRelationshipPrefetching];
    fetchRequest.returnsObjectsAsFaults = NO;
    return fetchRequest;
}

@end

@implementation ZMChangeTrackerBootstrap (Testing)

+ (void)bootStrapChangeTrackers:(NSArray *)changeTrackers onContext:(NSManagedObjectContext *)context;
{
    ZMChangeTrackerBootstrap *changeTrackerBootStrap = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:context
                                                                                                       changeTrackers:changeTrackers];
    [changeTrackerBootStrap fetchObjectsForChangeTrackers];
}

@end

