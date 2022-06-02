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


#import "NSManagedObjectContext+ZMSearchDirectory.h"
@import ZMTransport;
@import ZMCDataModel;
#import "ZMSearchUser+Internal.h"


NSString * const ZMSuggestedUsersForUserDidChange = @"ZMSuggestedUsersForUserDidChange";
NSString * const ZMCommonConnectionsForUsersDidChange = @"ZMCommonConnectionsForUsersDidChange";
NSString * const ZMRemovedSuggestedContactRemoteIdentifiersDidChange = @"ZMRemovedSuggestedContactRemoteIdentifiersDidChange";

@interface ZMSuggestedUserCommonConnections ()

@property (nonatomic, readwrite, getter=isEmpty) BOOL empty;
@property (nonatomic, readwrite) NSOrderedSet *topCommonConnectionsIDs;
@property (nonatomic, readwrite) NSUInteger totalCommonConnections;

@end

@implementation ZMSuggestedUserCommonConnections

- (instancetype)initWithPayload:(NSDictionary *)payload
{
    self = [super init];
    if (nil != self) {
        self.empty = NO;
        self.topCommonConnectionsIDs = [NSOrderedSet orderedSetWithArray:[payload optionalArrayForKey:ZMSearchUserMutualFriendsKey]];
        self.totalCommonConnections = [[payload optionalNumberForKey:ZMSearchUserTotalMutualFriendsKey] unsignedIntegerValue];
    }
    return self;
}

+ (instancetype)emptyEntry
{
    ZMSuggestedUserCommonConnections *instance = [self.class new];
    instance.empty = YES;
    return instance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (nil != self.topCommonConnectionsIDs) {
        [aCoder encodeObject:self.topCommonConnectionsIDs forKey:@"topCommonConnections"];
    }
    
    [aCoder encodeInteger:(NSInteger)self.totalCommonConnections forKey:@"totalCommonConnections"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self) {
        self.topCommonConnectionsIDs = [aDecoder decodeObjectForKey:@"topCommonConnections"];
        self.totalCommonConnections = (NSUInteger)[aDecoder decodeIntegerForKey:@"totalCommonConnections"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end


@implementation NSManagedObjectContext (ZMSearchDirectory)

static NSString * const RemovedSuggestedContactsKey = @"ZMRemovedSuggestedContacts";
static NSString * const UsersKey = @"users";
static NSString * const SuggestedUserCommonConnectionsKey = @"suggestedUserCommonConnectionsKey";
static NSString * const SuggestedUsersForUserKey = @"ZMSuggestedUsersForUserKey";
static NSString * const CommonConnectionsForUsersKey = @"ZMCommonConnectionsForUsersKey";

- (NSOrderedSet *)suggestedUsersForUser;
{
    NSArray *array = [self arrayOfUUIDsFromPersistentStoreMetadataForKey:SuggestedUsersForUserKey];
    
    if (array != nil) {
        return [NSOrderedSet orderedSetWithArray:array];
    } else {
        return nil;
    }
}

- (void)setSuggestedUsersForUser:(NSOrderedSet *)suggestedUsersForUser
{
    [self setArrayOfUUIDs:suggestedUsersForUser.array forPersistentStoreMetadataKey:SuggestedUsersForUserKey notificationName:ZMSuggestedUsersForUserDidChange];
}

- (NSDictionary *)commonConnectionsForUsers
{
    return [self dictionaryOfSuggestedCommonConnectionsFromPersistentStoreMetadataForKey:CommonConnectionsForUsersKey];
}

- (void)setCommonConnectionsForUsers:(NSDictionary *)commonConnectionsForUsers
{
    [self setDictionaryOfSuggestedCommonConnections:commonConnectionsForUsers forPersistentStoreMetadataKey:CommonConnectionsForUsersKey notificationName:ZMCommonConnectionsForUsersDidChange];
}

- (NSArray *)removedSuggestedContactRemoteIdentifiers;
{
    return [self arrayOfUUIDsFromPersistentStoreMetadataForKey:RemovedSuggestedContactsKey];
}

- (void)setRemovedSuggestedContactRemoteIdentifiers:(NSArray *)removedSuggestedContacts;
{
    [self setArrayOfUUIDs:removedSuggestedContacts forPersistentStoreMetadataKey:RemovedSuggestedContactsKey notificationName:ZMRemovedSuggestedContactRemoteIdentifiersDidChange];
}

- (NSDictionary *)dictionaryOfSuggestedCommonConnectionsFromPersistentStoreMetadataForKey:(NSString *)key
{
    NSData *archive = [self persistentStoreMetadataForKey:key];
    if (archive.length == 0) {
        return nil;
    } else {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archive];
        unarchiver.requiresSecureCoding = YES;
        
        NSDictionary *usersCommonConnections = [unarchiver decodeObjectOfClasses:[NSSet setWithObjects:ZMSuggestedUserCommonConnections.class, NSDictionary.class, NSUUID.class, NSArray.class, NSOrderedSet.class, NSString.class, nil] forKey:SuggestedUserCommonConnectionsKey];
        return usersCommonConnections;
    }
}

- (void)setDictionaryOfSuggestedCommonConnections:(NSDictionary *)objects forPersistentStoreMetadataKey:(NSString *)key notificationName:(NSString *)notificationName
{
    NSMutableData *archive = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archive];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:objects forKey:SuggestedUserCommonConnectionsKey];
    [archiver finishEncoding];
    [self setPersistentStoreMetadata:archive forKey:key];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (NSArray *)arrayOfUUIDsFromPersistentStoreMetadataForKey:(NSString *)key;
{
    NSData *archive = [self persistentStoreMetadataForKey:key];
    if (archive.length == 0) {
        return nil;
    } else {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archive];
        unarchiver.requiresSecureCoding = YES;
        
        NSArray *remoteIDs = [unarchiver decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, NSUUID.class, nil] forKey:UsersKey];
        return remoteIDs;
    }
}

- (void)setArrayOfUUIDs:(NSArray *)suggestedContacts forPersistentStoreMetadataKey:(NSString *)key notificationName:(NSString *)notificationName;
{
    NSMutableData *archive = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archive];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:suggestedContacts forKey:UsersKey];
    [archiver finishEncoding];
    [self setPersistentStoreMetadata:archive forKey:key];
    [self saveOrRollback];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

@end
