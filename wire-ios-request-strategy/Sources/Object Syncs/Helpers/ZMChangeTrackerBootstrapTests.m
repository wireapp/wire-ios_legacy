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

@import WireDataModel;
@import WireTesting;

#import "WireRequestStrategyTests-Swift.h"
#import "ZMContextChangeTracker.h"
#import "ZMChangeTrackerBootstrap.h"
#import "ZMChangeTrackerBootstrap+Testing.h"

@interface FakeChangeTracker : NSObject <ZMContextChangeTracker>
@property (nonatomic) NSFetchRequest *fetchRequest;
@property (nonatomic) NSSet *objectsToUpdate;
@end

@implementation FakeChangeTracker

- (void)objectsDidChange:(NSSet *)objects
{
    (void)objects;
}

- (NSFetchRequest *)fetchRequestForTrackedObjects
{
    return self.fetchRequest;
}

- (void)addTrackedObjects:(NSSet *)objects
{
    self.objectsToUpdate = objects;
}

@end



@interface ZMChangeTrackerBootstrapTests : ZMTBaseTest

@property (nonatomic) ZMChangeTrackerBootstrap *sut;
@property (nonatomic) CoreDataStack *coreDataStack;
@property (nonatomic) ZMUser *user1;
@property (nonatomic) ZMUser *user2;
@property (nonatomic) ZMUser *selfUser;
@property (nonatomic) ZMConversation *conversation1;
@property (nonatomic) ZMConversation *conversation2;
@property (nonatomic) ZMConnection *connection1;

@property (nonatomic) FakeChangeTracker *changeTracker1;
@property (nonatomic) FakeChangeTracker *changeTracker2;

@end



@implementation ZMChangeTrackerBootstrapTests

- (void)setUp
{
    [super setUp];

    self.coreDataStack = [self createCoreDataStackWithUserIdentifier:[NSUUID UUID]
                                                       inMemoryStore:YES];
    
    self.user1 = [ZMUser insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];
    self.user1.name = @"Hans";
    self.user2 = [ZMUser insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];
    self.user2.name = @"Gretel";
    self.selfUser = [ZMUser selfUserInContext:self.coreDataStack.viewContext];
    self.conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];
    self.conversation1.userDefinedName = @"A Walk in the Forest";
    self.conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];
    self.conversation2.userDefinedName = @"The Great Escape";
    self.connection1 = [ZMConnection insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];
    self.connection1.status = ZMConnectionStatusAccepted;
    self.user1.connection = self.connection1;
    self.connection1.conversation = self.conversation1;
    self.changeTracker1 = [[FakeChangeTracker alloc] init];
    self.changeTracker2 = [[FakeChangeTracker alloc] init];
    XCTAssert([self.coreDataStack.viewContext saveOrRollback]);
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1, self.changeTracker2]];
}

- (void)tearDown {
    self.sut = nil;
    self.user1 = nil;
    self.user2 = nil;
    self.selfUser = nil;
    self.conversation1 = nil;
    self.conversation2 = nil;
    self.changeTracker1 = nil;
    self.changeTracker2 = nil;
    self.connection1 = nil;
    self.conversation2 = nil;
    self.coreDataStack = nil;
    [super tearDown];
}

- (void)testThatItDoesNotReturnAnythingIfThePredicateDoesNotMatch
{
    // given
    self.sut = nil;
    
    NSString *entityName = ZMUser.entityName;
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"name == %@", @"Unknown UserName"];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request1.predicate = predicate1;
    
    self.changeTracker1.fetchRequest = request1;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    XCTAssertNil(self.changeTracker1.objectsToUpdate);
}

- (void)testThatItSortsFetchRequestByEntity
{
    // given
    self.sut = nil;
    
    NSString *entityName1 = ZMUser.entityName;
    NSString *entityName2 = ZMConversation.entityName;

    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"name != nil"];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"userDefinedName != nil"];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName1];
    request1.predicate = predicate1;
    
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:entityName2];
    request2.predicate = predicate2;
    
    self.changeTracker1.fetchRequest = request1;
    self.changeTracker2.fetchRequest = request2;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1, self.changeTracker2]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    NSSet *expectedSet1 = [NSSet setWithObjects:self.user1, self.user2, nil];
    NSSet *expectedSet2 = [NSSet setWithObjects:self.conversation1, self.conversation2, nil];
    XCTAssertEqualObjects(self.changeTracker1.objectsToUpdate, expectedSet1);
    XCTAssertEqualObjects(self.changeTracker2.objectsToUpdate, expectedSet2);
}

- (void)testThatItOnlyForwardsObjectsWithMatchingPredicateToTheChangeTrackers
{
    // given
    self.sut = nil;
    
    NSString *entityName = ZMUser.entityName;
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"name == %@", self.user1.name];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"name != nil"];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request1.predicate = predicate1;
    
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request2.predicate = predicate2;
    
    self.changeTracker1.fetchRequest = request1;
    self.changeTracker2.fetchRequest = request2;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1, self.changeTracker2]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    NSSet *expectedSet1 = [NSSet setWithObject:self.user1];
    NSSet *expectedSet2 = [NSSet setWithObjects:self.user1, self.user2, nil];
    XCTAssertEqualObjects(self.changeTracker1.objectsToUpdate, expectedSet1);
    XCTAssertEqualObjects(self.changeTracker2.objectsToUpdate, expectedSet2);
}

- (void)testThatItResolvesPredicatesThroughRelationships;
{
    // given
    self.sut = nil;
    
    NSString *entityName = ZMConversation.entityName;
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"userDefinedName == %@", self.conversation1.userDefinedName];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"connection != 0 && connection.status == %@", @(self.connection1.status)];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request1.predicate = predicate1;
    
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request2.predicate = predicate2;
    
    self.changeTracker1.fetchRequest = request1;
    self.changeTracker2.fetchRequest = request2;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1, self.changeTracker2]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    NSSet *expectedSet = [NSSet setWithObject:self.conversation1];
    XCTAssertEqualObjects(self.changeTracker1.objectsToUpdate, expectedSet);
    XCTAssertEqualObjects(self.changeTracker2.objectsToUpdate, expectedSet);
}


- (void)testThatItDoesNotCrashWhen_fetchRequestForTrackedObjects_ReturnsNil
{
    // given
    self.sut = nil;
    self.changeTracker1.fetchRequest = nil;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    XCTAssertNil(self.changeTracker1.objectsToUpdate);
}

- (void)testThatItDoesNotCrashWhenThePredicateReturnsNil
{
    // given
    self.sut = nil;
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:ZMConversation.entityName];
    self.changeTracker1.fetchRequest = request1;
    
    self.sut = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.coreDataStack.viewContext changeTrackers:@[self.changeTracker1]];
    
    // when
    [self.sut fetchObjectsForChangeTrackers];
    
    // then
    XCTAssertNil(self.changeTracker1.objectsToUpdate);
}

@end



@implementation ZMChangeTrackerBootstrapTests (Internal)

- (void)testThatItSortsTheRequestsByEntity
{
    // given
    NSString *entityName1 = ZMConversation.entityName;
    NSString *entityName2 = ZMUser.entityName;
    
    NSEntityDescription *entity1 = [self.sut entityForEntityName:entityName1];
    NSEntityDescription *entity2 = [self.sut entityForEntityName:entityName2];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName1];
    request1.predicate = [NSPredicate predicateWithFormat:@"userDefinedName != nil"];
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:entityName2];
    request2.predicate = [NSPredicate predicateWithFormat:@"name != nil"];
    
    // when
    NSMapTable *map = [self.sut sortFetchRequestsByEntity:@[request1, request2]];
    
    // then
    XCTAssertEqual(map.count, 2u);
    XCTAssertEqualObjects([map objectForKey:entity1], [NSSet setWithObject:request1.predicate]);
    XCTAssertEqualObjects([map objectForKey:entity2], [NSSet setWithObject:request2.predicate]);
}

- (void)testThatItBundlesFetchRequestsForTheSameEntityInACompoundRequest
{
    // given
    NSString *entityName = ZMConversation.entityName;
    NSEntityDescription *entity = [self.sut entityForEntityName:entityName];
    
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"property1 != nil"];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"property2 != nil"];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request1.predicate = predicate1;
    
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request2.predicate = predicate2;
    
    // when
    NSMapTable *map = [self.sut sortFetchRequestsByEntity:@[request1, request2]];
    
    // then
    NSSet *expected = [NSSet setWithArray:@[predicate1, predicate2]];
    XCTAssertEqual(map.count, 1u);
    XCTAssertEqualObjects([map objectForKey:entity], expected);
}


- (void)testThatItDoesNotAddRequestsWithoutPredicate
{
    // given
    NSString *entityName = ZMConversation.entityName;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    // when
    NSMapTable *map = [self.sut sortFetchRequestsByEntity:@[request]];
    
    // then
    XCTAssertEqual(map.count, 0u);
}

- (void)testThatItFetchesTheObjectsAndSortsThemByEntity
{
    // given
    NSString *convEntityName = ZMConversation.entityName;
    NSString *userEntityName = ZMUser.entityName;
    
    NSEntityDescription *entity1 = [self.sut entityForEntityName:convEntityName];
    NSEntityDescription *entity2 = [self.sut entityForEntityName:userEntityName];
    
    NSFetchRequest *request1 = [NSFetchRequest fetchRequestWithEntityName:convEntityName];
    request1.predicate = [NSPredicate predicateWithFormat:@"userDefinedName != nil"];
    NSFetchRequest *request2 = [NSFetchRequest fetchRequestWithEntityName:userEntityName];
    request2.predicate = [NSPredicate predicateWithFormat:@"name != nil"];
    
    // when
    NSMapTable *entityToRequestMap = [NSMapTable strongToStrongObjectsMapTable];
    [entityToRequestMap setObject:[NSSet setWithObject:request1.predicate] forKey:entity1];
    [entityToRequestMap setObject:[NSSet setWithObject:request2.predicate] forKey:entity2];
    
    NSMapTable *map = [self.sut executeMappedFetchRequests:entityToRequestMap];
    
    // then
    XCTAssertEqual(map.count, 2u);
    NSArray *expectedResult1 = @[self.conversation1, self.conversation2];
    NSArray *expectedResult2 = @[self.user1, self.user2];
    
    AssertArraysContainsSameObjects([map objectForKey:entity1], expectedResult1);
    AssertArraysContainsSameObjects([map objectForKey:entity2], expectedResult2);
}

- (void)testThatItDoesNotAddEmptyResults
{
    // given
    NSString *entityName = ZMConnection.entityName;
    NSEntityDescription *entityDescription = ZMConnection.entity;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"status == 0", self.user1];
    
    // when
    NSMapTable *entityToRequestMap = [NSMapTable strongToStrongObjectsMapTable];
    [entityToRequestMap setObject:[NSSet setWithObject:request.predicate] forKey:entityDescription];
    NSMapTable *map = [self.sut executeMappedFetchRequests:entityToRequestMap];
    
    // then
    XCTAssertEqual(map.count, 0u);
}

@end

