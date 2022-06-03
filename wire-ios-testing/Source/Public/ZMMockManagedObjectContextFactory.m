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


#import "ZMMockManagedObjectContextFactory.h"
#import "ZMMockEntity.h"
#import "ZMMockEntity2.h"

@implementation ZMMockManagedObjectContextFactory

+ (NSManagedObjectContext *)alternativeManagedObjectContextForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc;
{
    return [self alternativeManagedObjectContextForPersistantStoreCoordinator:psc concurencyType:NSMainQueueConcurrencyType];
}

+ (NSManagedObjectContext *)alternativeManagedObjectContextForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc concurencyType:(NSManagedObjectContextConcurrencyType)concurencyType;
{
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurencyType];
    [moc setPersistentStoreCoordinator:psc];
    return moc;
}

+ (NSManagedObjectContext *)testManagedObjectContext;
{
    return [self testManagedObjectContextWithConcurencyType:NSMainQueueConcurrencyType];
}

+ (NSManagedObjectContext *)testManagedObjectContextWithConcurencyType:(NSManagedObjectContextConcurrencyType)concurencyType;
{
    NSManagedObjectModel *mom = [self loadManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSError *error = nil;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSAssert(store != nil, @"Unable to create in-memory Core Data store: %@", error);
    (void)store;
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurencyType];
    [moc setPersistentStoreCoordinator:psc];

    return moc;
}

+ (NSManagedObjectModel *)loadManagedObjectModel;
{
    NSEntityDescription *mockEntity = [self createFirstMockEntity];
    NSEntityDescription *mockEntity2 = [self createSecondMockEntity];
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    [model setEntities:@[mockEntity, mockEntity2]];
    
    return model;
}

+ (NSEntityDescription *)createFirstMockEntity;
{
    NSEntityDescription *mockEntity = [[NSEntityDescription alloc] init];
    [mockEntity setName:@"MockEntity"];
    [mockEntity setManagedObjectClassName:NSStringFromClass([ZMMockEntity class])];

    NSAttributeDescription *identifierAttribute = [[NSAttributeDescription alloc] init];
    [identifierAttribute setName:@"identifier"];
    [identifierAttribute setAttributeType:NSInteger64AttributeType];
    [identifierAttribute setOptional:YES];
    [identifierAttribute setTransient:YES];
    
    NSAttributeDescription *fieldAttribute = [[NSAttributeDescription alloc] init];
    [fieldAttribute setName:@"field"];
    [fieldAttribute setAttributeType:NSInteger16AttributeType];
    [fieldAttribute setOptional:YES];

    NSAttributeDescription *field2Attribute = [[NSAttributeDescription alloc] init];
    [field2Attribute setName:@"field2"];
    [field2Attribute setAttributeType:NSStringAttributeType];
    [field2Attribute setOptional:YES];

    NSAttributeDescription *field3Attribute = [[NSAttributeDescription alloc] init];
    [field3Attribute setName:@"field3"];
    [field3Attribute setAttributeType:NSStringAttributeType];
    [field3Attribute setOptional:YES];

    NSRelationshipDescription *mockEntityRelationship = [[NSRelationshipDescription alloc] init];
    [mockEntityRelationship setName:@"mockEntities"];
    [mockEntityRelationship setDestinationEntity:mockEntity];
    [mockEntityRelationship setMinCount:0];
    [mockEntityRelationship setOptional:YES];

    [mockEntity setProperties:@[fieldAttribute, field2Attribute, field3Attribute,
        mockEntityRelationship, identifierAttribute]];
    return mockEntity;
}

+ (NSEntityDescription *)createSecondMockEntity;
{
    NSAttributeDescription *identifierAttribute = [[NSAttributeDescription alloc] init];
    [identifierAttribute setName:@"identifier"];
    [identifierAttribute setAttributeType:NSInteger64AttributeType];
    [identifierAttribute setOptional:YES];
    [identifierAttribute setTransient:YES];
    
    NSAttributeDescription *fieldAttribute = [[NSAttributeDescription alloc] init];
    [fieldAttribute setName:@"field"];
    [fieldAttribute setAttributeType:NSInteger16AttributeType];
    [fieldAttribute setOptional:YES];

    NSAttributeDescription *field2Attribute = [[NSAttributeDescription alloc] init];
    [field2Attribute setName:@"field2"];
    [field2Attribute setAttributeType:NSInteger16AttributeType];
    [field2Attribute setOptional:YES];

    NSAttributeDescription *field3Attribute = [[NSAttributeDescription alloc] init];
    [field3Attribute setName:@"field3"];
    [field3Attribute setAttributeType:NSInteger16AttributeType];
    [field3Attribute setOptional:YES];

    NSEntityDescription *mockEntity2 = [[NSEntityDescription alloc] init];
    [mockEntity2 setName:@"MockEntity2"];
    [mockEntity2 setManagedObjectClassName:NSStringFromClass([ZMMockEntity2 class])];

    [mockEntity2 setProperties:@[fieldAttribute, field2Attribute, field3Attribute, identifierAttribute]];
    return mockEntity2;
}

@end
