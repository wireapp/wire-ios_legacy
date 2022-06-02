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
@import WireTransport;

#import "ZMManagedObject+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

NSString * const ZMDataPropertySuffix = @"_data";

static NSString * const NeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
static NSString * const RemoteIdentifierDataKey = @"remoteIdentifier_data";
NSString * const ZMManagedObjectLocallyModifiedKeysKey = @"modifiedKeys";
static NSString * const KeysForCachedValuesKey = @"ZMKeysForCachedValues";


@interface ZMManagedObject ()
@end



@implementation ZMManagedObject

+ (NSManagedObjectID *)objectIDForURIRepresentation:(NSURL *)url inUserSession:(id<ContextProvider>)userSession
{
    VerifyReturnNil(url != nil);
    VerifyReturnNil(userSession != nil);

    return [self objectIDForURIRepresentation:url
                       inManagedObjectContext:userSession.viewContext];
}

+ (NSManagedObjectID *)objectIDForURIRepresentation:(NSURL *)url inManagedObjectContext:(NSManagedObjectContext *)context
{
    VerifyReturnNil(url != nil);
    VerifyReturnNil(context != nil);
    NSPersistentStoreCoordinator *psc = context.persistentStoreCoordinator;
    return [psc managedObjectIDForURIRepresentation:url];
}

+ (instancetype)existingObjectWithID:(NSManagedObjectID *)identifier inUserSession:(id<ContextProvider>)userSession;
{
    VerifyReturnNil(identifier);
    VerifyReturnNil(userSession);
    NSError *error;
    ZMManagedObject *mo = (id) [userSession.viewContext existingObjectWithID:identifier error:&error];
    if (mo != nil) {
        // [self entityName] throws an exception when called on ZMManagedObject
        //        RequireString([mo.entity.name isEqualToString:[self entityName]], @"Retrieved an object of a different entity.");
    }
    return mo;
}

+ (instancetype)existingObjectWithObjectIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)context;
{
    VerifyReturnNil(identifier != nil);
    VerifyReturnNil(context != nil);
    
    NSURL *moURL = [NSURL URLWithString:identifier];
    if (moURL == nil) {
        return nil;
    }
    NSManagedObjectID *moID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:moURL];
    if (moID == nil) {
        return nil;
    }
    ZMManagedObject *mo = (id)[context existingObjectWithID:moID error:nil];
    return mo;
}

- (BOOL)isZombieObject
{
    return self.isDeleted || self.managedObjectContext == nil;
}

- (void)willSave;
{
    [super willSave];
    if (self.managedObjectContext.zm_isUserInterfaceContext) {
        [self updateKeysThatHaveLocalModifications];
    }
}

- (NSDictionary *)filteredChangedValues;
{
    NSSet *ignoredKeys = self.ignoredKeys;
    NSArray *changedKeys = [self.changedValues.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *k, NSDictionary *bindings) {
        NOT_USED(bindings);
        return ! [ignoredKeys containsObject:k];
    }]];
    return [self.changedValues dictionaryWithValuesForKeys:changedKeys];
}

- (void)setKeysThatHaveLocalModifications:(NSSet *)keys;
{
    if (! [[self class] isTrackingLocalModifications]) {
        return;
    }
    NSMutableSet *changedTrackedKeys = [keys mutableCopy];
    [changedTrackedKeys intersectSet:self.keysTrackedForLocalModifications];
    if ([self.modifiedKeys isEqualToSet:changedTrackedKeys]){
        return;
    }
    self.modifiedKeys = (keys.count == 0) ? nil : [changedTrackedKeys copy];
}

- (NSString *)objectIDURLString
{
    NSError *error = nil;
    if (self.objectID.isTemporaryID) {
        if (! [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:&error]) {
            return nil;
        }
    }
    
    return [[self.objectID URIRepresentation] absoluteString];
}

@end



@implementation ZMManagedObject (Internal)

@dynamic needsToBeUpdatedFromBackend;
@dynamic modifiedKeys;

+ (BOOL)isTrackingLocalModifications
{
    return YES;
}

+ (NSString *)entityName;
{
    NSAssert(NO, @"Subclasses must override this ZMManagedObject -entityName");
    return nil;
}

+ (NSString *)sortKey;
{
    NSAssert(NO, @"Subclasses must override this ZMManagedObject -sortKey");
    return nil;
}

+ (NSString *)domainKey
{
    return @"domain";
}

+ (NSString *)remoteIdentifierDataKey
{
    return @"remoteIdentifier_data";
}

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:moc];
}

- (NSUUID *)transientUUIDForKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    NSUUID *uuid = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (uuid == nil) {
        NSData *uuidData = [self valueForKey:[key stringByAppendingString:ZMDataPropertySuffix]];
        if (uuidData != nil) {
            if (uuidData.length == sizeof(uuid_t)) {
                uuid = [[NSUUID alloc] initWithUUIDBytes:uuidData.bytes];
            } else {
                uuid = nil;
            }
            [self setPrimitiveValue:uuid forKey:key];
        }
    }
    return uuid;
}

- (void)setTransientUUID:(NSUUID *)newUUID forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:newUUID forKey:key];
    [self didChangeValueForKey:key];
    NSString *dataKey = [key stringByAppendingString:ZMDataPropertySuffix];
    if (newUUID != nil) {
        NSData *data = [newUUID data];
        [self setValue:data forKeyPath:dataKey];
    } else {
        [self setValue:nil forKeyPath:dataKey];
    }
}

- (CGSize)transientCGSizeForKey:(NSString *)key
{
    [self willAccessValueForKey:key];
    NSValue *sizeValue = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    if (sizeValue == nil) {
        NSData *sizeData = [self valueForKey:[key stringByAppendingString:ZMDataPropertySuffix]];
        if (sizeData) {
            // Make sure we can read both 'double' (64 bit platforms) and 'float' (32 bit platforms):
            CGSize s = {};
            struct {
                double width;
                double height;
            } doubleSize;
            struct {
                float width;
                float height;
            } floatSize;
            if (sizeData.length == sizeof(doubleSize)) {
                [sizeData getBytes:&doubleSize length:sizeof(doubleSize)];
                s = CGSizeMake((CGFloat) doubleSize.width, (CGFloat) doubleSize.height);
            } else if (sizeData.length == sizeof(floatSize)) {
                [sizeData getBytes:&floatSize length:sizeof(floatSize)];
                s = CGSizeMake((CGFloat) floatSize.width, (CGFloat) floatSize.height);
            }
            sizeValue = [NSValue valueWithBytes:&s objCType:@encode(CGSize)];
        }
    }
    CGSize result = CGSizeZero;
    [sizeValue getValue:&result];
    return result;
}

- (void)setTransientCGSize:(CGSize)size forKey:(NSString *)key
{
    NSValue *sizeValue = [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
    
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:sizeValue forKey:key];
    [self didChangeValueForKey:key];
    
    NSData *rawSize = [NSData dataWithBytes:&size length:sizeof(size)];
    [self setValue:rawSize forKey:[key stringByAppendingString:ZMDataPropertySuffix]];
}

+ (NSArray *)defaultSortDescriptors;
{
    return @[[NSSortDescriptor sortDescriptorWithKey:[self sortKey] ascending:YES]];
}

+ (NSArray *)sortDescriptorsForUpdating;
{
    return [self defaultSortDescriptors];
}

+ (NSPredicate *)predicateForFilteringResults;
{
    return nil;
}


+ (NSFetchRequest *)sortedFetchRequest
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    
    if(self.predicateForFilteringResults == nil) {
        // nope
    }
    else if(request.predicate == nil) {
        request.predicate = self.predicateForFilteringResults;
    }
    else {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, self.predicateForFilteringResults]];
    }
    
    request.sortDescriptors = [self defaultSortDescriptors];
    return request;
}

+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self sortedFetchRequest];
    
    if(request.predicate) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, predicate]];
    }
    else {
        request.predicate = predicate;
    }
    
    return request;
}

+ (NSFetchRequest *)sortedFetchRequestWithPredicateFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    return [self sortedFetchRequestWithPredicate:predicate];
}

+ (void)enumerateObjectsInContext:(NSManagedObjectContext *)moc withBlock:(ObjectsEnumerationBlock)block;
{
    BOOL stop = NO;
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    Require(entity != nil);
    for (ZMManagedObject *mo in moc.registeredObjects) {
        if (mo.entity == entity) {
            block(mo, &stop);
            if (stop) {
                break;
            }
        }
    }
}

+ (instancetype)internalFetchObjectWithRemoteIdentifier:(NSUUID *)uuid inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    // Executing a fetch request is quite expensive, because it will _always_ (1) round trip through
    // the persistent store coordinator and the SQLite engine, and (2) touch the file system.
    // Looping through all objects in the context is way cheaper, because it does not involve (1)
    // taking any locks, nor (2) touching the file system.
    
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    Require(entity != nil);
    
    NSString *key = [self remoteIdentifierDataKey];
    NSData *data = uuid.data;
    for (NSManagedObject *mo in moc.registeredObjects) {
        if (!mo.isFault && mo.entity == entity && [data isEqual:[mo valueForKey:key]]) {
            return (id) mo;
        }
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", [self remoteIdentifierDataKey], uuid.data];
    fetchRequest.fetchLimit = 2; // We only want 1, but want to check if there are too many.
    NSArray *fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    RequireString([fetchResult count] <= 1, "More than one object with the same UUID: %s", uuid.transportString.UTF8String);
    return fetchResult.firstObject;
}

+ (instancetype)internalFetchObjectWithRemoteIdentifier:(NSUUID *)uuid
                                                 domain:(NSString *)domain
                                   searchingLocalDomain:(BOOL)searchingLocalDomain
                                 inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    // Executing a fetch request is quite expensive, because it will _always_ (1) round trip through
    // the persistent store coordinator and the SQLite engine, and (2) touch the file system.
    // Looping through all objects in the context is way cheaper, because it does not involve (1)
    // taking any locks, nor (2) touching the file system.

    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    Require(entity != nil);

    NSString *key = [self remoteIdentifierDataKey];
    NSString *domainKey = [self domainKey];
    NSData *data = uuid.data;
    for (NSManagedObject *mo in moc.registeredObjects) {
        if (!mo.isFault && mo.entity == entity &&
            [data isEqual:[mo valueForKey:key]] &&
            [domain isEqual:[mo valueForKey:domainKey]]) {
            return (id) mo;
        }
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.entityName];

    if (searchingLocalDomain) {
        if (domain != nil) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND (%K == %@ OR %K == NULL)",
                                      [self remoteIdentifierDataKey], uuid.data,
                                      [self domainKey], domain,
                                      [self domainKey]];
        } else {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@",
                                      [self remoteIdentifierDataKey], uuid.data];
        }
    } else {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@",
                                  [self remoteIdentifierDataKey], uuid.data,
                                  [self domainKey], domain];
    }

    fetchRequest.fetchLimit = 2; // We only want 1, but want to check if there are too many.
    NSArray *fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    RequireString([fetchResult count] <= 1, "More than one object with the same UUID: %s and domain: %s", uuid.transportString.UTF8String, domain.UTF8String);
    return fetchResult.firstObject;
}

+ (NSSet *)fetchObjectsWithRemoteIdentifiers:(NSSet <NSUUID *> *)uuids inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    // Executing a fetch request is quite expensive, because it will _always_ (1) round trip through
    // (1) the persistent store coordinator and the SQLite engine, and (2) touch the file system.
    // Looping through all objects in the context is way cheaper, because it does not involve (1)
    // taking any locks, nor (2) touching the file system.
    
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    Require(entity != nil);
    
    NSMutableSet *objects = [[NSMutableSet alloc] init];
    
    NSString *key = [self remoteIdentifierDataKey];
    NSMutableSet <NSData *> *uuidDataArray = [[uuids mapWithBlock:^NSData *(NSUUID *uuid) {
        return uuid.data;
    }] mutableCopy];
    
    for (NSManagedObject *mo in moc.registeredObjects) {
        if ((mo.entity == entity) && [uuidDataArray containsObject:[mo valueForKey:key]]) {
            [objects addObject:mo];
            [uuidDataArray removeObject:[mo valueForKey:key]];
        }
    }
    
    if (uuidDataArray.count == 0) {
        return objects;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", [self remoteIdentifierDataKey], uuidDataArray];
    fetchRequest.fetchLimit = uuidDataArray.count + 1; // We only want 1 object for each uuid, but want to check if there are too many.
    NSArray *fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    RequireString([fetchResult count] <= uuidDataArray.count, "More than one object with the same UUID");
    [objects addObjectsFromArray:fetchResult];
    return objects;
}

@end




@implementation ZMManagedObject (PersistentChangeTracking)

+ (NSPredicate *)predicateForNeedingToBeUpdatedFromBackend;
{
    return [NSPredicate predicateWithFormat:@"%K != 0", NeedsToBeUpdatedFromBackendKey];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    return [NSPredicate predicateWithFormat:@"%K != NULL",
            ZMManagedObjectLocallyModifiedKeysKey];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    return [NSPredicate predicateWithFormat:@"%K == NULL", self.remoteIdentifierDataKey];
}

- (NSSet *)ignoredKeys;
{
    NSString * const KeysIgnoredForTrackingModifications[] = {
        ZMManagedObjectLocallyModifiedKeysKey,
        NeedsToBeUpdatedFromBackendKey,
        RemoteIdentifierDataKey,
    };
    
    NSSet *ignoredKeys = [NSSet setWithObjects:KeysIgnoredForTrackingModifications count:(sizeof(KeysIgnoredForTrackingModifications) / sizeof(*KeysIgnoredForTrackingModifications))];
    return ignoredKeys;
}


- (NSSet *)keysThatHaveLocalModifications;
{
    if (! [[self class] isTrackingLocalModifications]) {
        return [NSSet set];
    }
    return self.modifiedKeys ?: [NSSet set];
}

- (void)resetLocallyModifiedKeys:(NSSet *)keys;
{
    NSMutableSet *newKeys = [self.keysThatHaveLocalModifications mutableCopy];
    [newKeys minusSet:keys];
    self.modifiedKeys = (newKeys.count == 0) ? nil : [newKeys copy];
}

- (void)setLocallyModifiedKeys:(NSSet *)keys;
{
    VerifyReturn(keys != nil);
    RequireString([keys isSubsetOfSet:self.keysTrackedForLocalModifications],
                  "Trying to set keys that are not being tracked: %s",
                  [keys.allObjects componentsJoinedByString:@", "].UTF8String);
    
    NSSet *newKeys = [self.keysThatHaveLocalModifications setByAddingObjectsFromSet:keys];
    self.modifiedKeys = (newKeys.count == 0) ? nil : newKeys;
}

- (BOOL)hasLocalModificationsForKeys:(NSSet *)keys;
{
    if (self.modifiedKeys == nil) {
        return NO;
    }
    return [self.keysThatHaveLocalModifications intersectsSet:keys];
}

- (BOOL)hasLocalModificationsForKey:(NSString *)key;
{
    if (self.modifiedKeys == nil) {
        return NO;
    }
    return [self.keysThatHaveLocalModifications containsObject:key];
}

- (NSSet *)keysTrackedForLocalModifications;
{
    NSMutableSet *keys = [NSMutableSet set];
    NSSet *ignoredKeys = self.ignoredKeys;
    
    [self.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
        NOT_USED(stop);
        if (attribute.attributeType != NSUndefinedAttributeType && ! [ignoredKeys containsObject:key]) {
            [keys addObject:key];
        }
    }];
    
    [self.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
        NOT_USED(relationship);
        NOT_USED(stop);
        if (! [ignoredKeys containsObject:key]) {
            [keys addObject:key];
        }
    }];
    return keys;
}


- (NSArray *)keysForCachedValues;
{
    NSArray *keys = self.managedObjectContext.userInfo[KeysForCachedValuesKey][self.entity.name];
    if (keys == nil) {
        NSMutableDictionary *map = self.managedObjectContext.userInfo[KeysForCachedValuesKey];
        if (map == nil) {
            map = [NSMutableDictionary dictionary];
            self.managedObjectContext.userInfo[KeysForCachedValuesKey] = map;
        }
        
        NSMutableArray *allNames = [NSMutableArray array];
        NSSet *allKeys = [NSSet setWithArray:self.entity.attributesByName.allKeys];
        [self.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attribute, BOOL *stop) {
            if (attribute.isTransient &&
                ([allKeys containsObject:[name stringByAppendingString:@"_data"]] ||
                 [allKeys containsObject:[name stringByAppendingString:@"_ids"]] ||
                 [allKeys containsObject:[name stringByAppendingString:@"_id"]]))
            {
                [allNames addObject:name];
            }
            NOT_USED(stop);
        }];
        keys = [allNames copy];
        map[self.entity.name] = keys;
    }
    return keys;
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags;
{
    [super awakeFromSnapshotEvents:flags];
    for (NSString *key in self.keysForCachedValues) {
        [self setPrimitiveValue:nil forKey:key];
    }
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    [self removeObsoleteKeys];
}

/// Removes keys that were previously tracked but are not tracked anymore from the modifiedKeys
- (void)removeObsoleteKeys
{
    if (![self.class isTrackingLocalModifications]) {
        return;
    }
    if (self.modifiedKeys == nil || [self.modifiedKeys isSubsetOfSet:self.keysTrackedForLocalModifications]) {
        return;
    }
    NSMutableSet *remainingKeys = [self.modifiedKeys mutableCopy];
    [remainingKeys intersectSet:self.keysTrackedForLocalModifications];
    self.modifiedKeys = (remainingKeys.count == 0) ? nil : remainingKeys;
}

- (void)updateKeysThatHaveLocalModifications;
{
    if (![self.class isTrackingLocalModifications]) {
        return;
    }
    NSSet *oldKeys = self.keysThatHaveLocalModifications;
    NSMutableSet *newKeys = [oldKeys mutableCopy];
    [newKeys addObjectsFromArray:self.filteredChangedValues.allKeys ?: @[]];
    NSSet *filteredKeys = [self filterUpdatedLocallyModifiedKeys:newKeys];
    if (! [oldKeys isEqualToSet:filteredKeys]) {
        [self setKeysThatHaveLocalModifications:filteredKeys];
    }
}

// Subclasses should override to conditionally exclude modified keys.
- (NSSet<NSString *> *)filterUpdatedLocallyModifiedKeys:(NSSet<NSString *> *)updatedKeys
{
    return updatedKeys;
}

@end



@implementation ZMManagedObject (Debugging)

- (id)debugQuickLookObject
{
    ZMQuickLookString *quickLook = [[ZMQuickLookString alloc] init];
    
    // First off some basic info:
    // <ZMImageMessage: 0x107bad5f0> (entity: ImageMessage; id: 0x107bb1b70 <x-coredata:///ImageMessage/t7EAE7A86-7CA2-49E5-BA5F-BA4AFB35897B581>
    [quickLook appendLabel:@"self" textWithFormat:@"<%@: %p>", self.class, self];
    [quickLook appendLabel:@"entity" text:self.entity.name];
    [quickLook appendLabel:@"ID" textWithFormat:@"%@", self.objectID.URIRepresentation];
    
    if (self.isFault) {
        [quickLook appendLabel:@"fault" text:@"YES"];
    } else {
        NSEntityDescription *entity = self.entity;
        NSArray *attributes = [entity.attributesByName.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
            return [str1 compare:str2];
        }];
        attributes = [attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not self contains \"_\""]];
        for (NSString *key in attributes) {
            [quickLook appendLabel:key textWithFormat:@"%@", [self valueForKey:key]];
        }
    }
    
    return quickLook.text;
}

- (NSString *)debugDescription;
{
    // N.B.: In overriding this, we need to be very carefull not to fire any faults.
    //
    // The standard format (provided by Core Data) is:
    //
    // <ZMConversation: 0x1750b060> (entity: Conversation; id: 0x17509a50 <x-coredata://F6899F76-3F8C-4360-8B74-DAEE28CD942C/Conversation/p9> ; data: <fault>)
    //
    // or
    //
    // <ZMConversation: 0x1750b060> (entity: Conversation; id: 0x17509a50 <x-coredata://F6899F76-3F8C-4360-8B74-DAEE28CD942C/Conversation/p9> ; data: {
    //     activeParticipants = "<relationship fault: 0x176d6b20 'activeParticipants'>";
    //     connection = nil;
    //     conversationType = 2;
    //     creator = "0x1750bb40 <x-coredata://F6899F76-3F8C-4360-8B74-DAEE28CD942C/User/p10>";
    // ...
    // })
    //
    
    NSString *entityDescription = [NSString stringWithFormat:@"entity: %@", self.entity.name];
    NSString *identifierDescription = [NSString stringWithFormat:@"id: %p %@", self.objectID, self.objectID.URIRepresentation];
    
    NSString *dataDescription = nil;
    if (self.isFault) {
        dataDescription = @"data: fault";
    } else {
        // NSMutableArray *values = [NSMutableArray array];
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"not self contains \"_\""];
        
        NSComparisonResult(^stringCompare)(id, id) = ^(NSString *s1, NSString *s2) {
            return [s1 compare:s2];
        };
        
        [self.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attribute, BOOL *stop) {
            NOT_USED(stop);
            NOT_USED(attribute);
            if (! [filter evaluateWithObject:key]) {
                return;
            }
            if ([key isEqualToString:ZMManagedObjectLocallyModifiedKeysKey]) {
                NSArray *keys = [self.keysThatHaveLocalModifications.allObjects sortedArrayUsingComparator:stringCompare];
                values[key] = (keys.count == 0) ? @"0" : [keys componentsJoinedByString:@" | "];
            } else {
                NSObject *value = [self valueForKey:key];
                if ([value isKindOfClass:[NSUUID class]]) {
                    NSUUID *uuid = (id) value;
                    values[key] = (uuid == nil) ? @"nil" : uuid.UUIDString.lowercaseString;
                } else if ([value isKindOfClass:[NSData class]]) {
                    NSData *data = (id) value;
                    values[key] = (data == nil) ? @"nil" : [NSString stringWithFormat:@"%llu bytes", (unsigned long long) data.length];
                } else {
                    values[key] = (value == nil) ? @"nil" : value.debugDescription;
                }
            }
        }];
        [self.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop) {
            NOT_USED(stop);
            if ([self hasFaultForRelationshipNamed:key]) {
                values[key] = @"relationship fault";
            } else if (! relationship.isToMany) {
                ZMManagedObject *mo = [self valueForKey:key];
                values[key] = (mo == nil) ? @"nil" : mo.objectID.URIRepresentation.debugDescription;
            } else {
                // to many
                NSSet *value = [self valueForKey:key];
                NSMutableArray *comp = [NSMutableArray array];
                size_t idx = 0;
                for (ZMManagedObject *mo in value) {
                    if (5 < idx++) {
                        [comp addObject:@"..."];
                        break;
                    }
                    [comp addObject:mo.objectID.URIRepresentation.debugDescription];
                }
                values[key] = [NSString stringWithFormat:@"count: %llu {%@}",
                               (unsigned long long) value.count, [comp componentsJoinedByString:@", "]];
            }
        }];
        
        dataDescription = [NSString stringWithFormat:@"data: %@", values];
    }
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> (", self.class, self];
    [description appendString:[@[entityDescription, identifierDescription, dataDescription] componentsJoinedByString:@"; "]];
    [description appendString:@")"];
    return description;
}

@end



@implementation ZMManagedObject (KeyValueValidation)

- (BOOL)validateForUpdate:(NSError **)outError
{
    //
    // We override this method in order to only validate those values that have changed.
    //
    __block BOOL allValid = YES;
    __block NSMutableArray *errors;
    [self.changedValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NOT_USED(stop);
        NSError *error;
        if (value == [NSNull null]) {
            value = nil;
        }
        id changedValue = value;
        BOOL valid = [self validateValue:&changedValue forKey:key error:&error];
        if (valid) {
            if (changedValue != value) {
                [self setValue:changedValue forKey:key];
            }
        } else {
            allValid = NO;
            if (error != nil) {
                if (errors == nil) {
                    errors = [NSMutableArray array];
                }
                [errors addObject:error];
            }
        }
    }];
    if (! allValid && (outError != nil)) {
        NSDictionary *userInfo = @{NSDetailedErrorsKey: errors ?: @[]};
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSValidationMultipleErrorsError userInfo:userInfo];
    }
    return allValid;
}

- (BOOL)validateValue:(inout id *)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError **)outError
{
    //Because we need to validate changes made only by UI
    if (! self.managedObjectContext.zm_isUserInterfaceContext) {
        return YES;
    }
    return [super validateValue:ioValue forKeyPath:inKeyPath error:outError];
}

- (BOOL)validateValue:(id *)ioValue forKey:(NSString *)key error:(NSError **)outError
{
    //Because we need to validate changes made only by UI
    if (! self.managedObjectContext.zm_isUserInterfaceContext) {
        return YES;
    }
    return [super validateValue:ioValue forKey:key error:outError];
}

@end




@implementation ZMManagedObject (NonpersistedObjectIdentifer)

- (NSString *)nonpersistedObjectIdentifer;
{
    return [NSString stringWithFormat:@"Z%tx", (unsigned long) self];
}

+ (instancetype)existingObjectWithNonpersistedObjectIdentifer:(NSString *)identifier inUserSession:(id<ContextProvider>)userSession;
{
    VerifyReturnNil(identifier != nil);
    intptr_t value = 0;
    if (sscanf([identifier UTF8String], "Z%tx", &value) != 1) {
        return nil;
    }
    
    NSManagedObjectContext *moc = userSession.viewContext;
    for (ZMManagedObject *mo in moc.registeredObjects) {
        intptr_t otherValue = (intptr_t) ((__bridge void *) mo);
        if (otherValue == value) {
            return mo;
        }
    }
    return nil;
}

@end
