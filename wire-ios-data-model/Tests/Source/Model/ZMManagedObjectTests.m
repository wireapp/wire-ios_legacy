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


#import "ModelObjectsTests.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"
#import "MockEntity.h"
#import "MockEntity2.h"
#import "MockModelObjectContextFactory.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+tests.h"


@interface TestEntityWithPredicate : ZMManagedObject

@end



@implementation TestEntityWithPredicate

+(NSString *)sortKey {
    return @"test-sort-key-predicate";
}

+(NSString *)entityName {
    return @"test-entity-name-predicate";
}

+ (NSFetchRequest *) sortedFetchRequest
{
    NSFetchRequest *request = [super sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"original_condition == 0"];
    return request;
}

@end


@interface ZMManagedObjectTests : ZMBaseManagedObjectTest

@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) NSManagedObjectContext *alternativeTestMOC;

@end


@implementation ZMManagedObjectTests
{
    NSPredicate *OriginalPredicate;
}

- (void)setUp
{
    [super setUp];
    
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.alternativeTestMOC = [MockModelObjectContextFactory alternativeMocForPSC:self.testMOC.persistentStoreCoordinator];
    
    OriginalPredicate = [NSPredicate predicateWithFormat:@"original_condition == 0"];
    [self.testMOC markAsUIContext];
}

- (void)tearDown
{
    [self.testMOC resetContextType];
    self.testMOC = nil;
    self.alternativeTestMOC = nil;
    OriginalPredicate = nil;
    [super tearDown];
}

- (void)testThatItCreatesASortedFetchRequest
{

    // when
    NSFetchRequest *fetchRequest = [MockEntity sortedFetchRequest];
    
    // then
    XCTAssertEqualObjects(fetchRequest.entityName, [MockEntity entityName]);
    XCTAssertEqualObjects([(NSSortDescriptor *) fetchRequest.sortDescriptors[0] key], [MockEntity sortKey]);
}


- (void)testThatItAddsAPredicateToARequest
{
    
    // given
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"test_predicate == 1"];
    
    // when
    NSFetchRequest *fetchRequest = [MockEntity sortedFetchRequestWithPredicate:predicate];
    
    // then
    XCTAssertEqualObjects(fetchRequest.predicate, predicate);
    
}

- (void)testThatItAddsAPredicateToARequestWithAPredicate
{
    
    // given
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"test_predicate == 1"];
    NSPredicate *compound = [NSCompoundPredicate andPredicateWithSubpredicates:@[OriginalPredicate, predicate]];
    
    // when
    NSFetchRequest *fetchRequest = [TestEntityWithPredicate sortedFetchRequestWithPredicate:predicate];
    
    // then
    XCTAssertEqualObjects(fetchRequest.predicate, compound);
    
}

- (void)testThatItEnumeratesAllManagedObjectsInTheContext
{
    // given
    [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    __block NSUInteger found = 0;
    
    // when
    [MockEntity enumerateObjectsInContext:self.testMOC withBlock:^(ZMManagedObject *mo, BOOL *stop ZM_UNUSED) {
        XCTAssert([mo isKindOfClass:[MockEntity class]]);
        ++found;
    }];
    
    // then
    XCTAssertEqual(2u, found);
}

- (void)testThatItStopsWhileEnumeratingManagedObjectsInTheContext
{
    // given
    [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    __block NSUInteger found = 0;
    
    // when
    [MockEntity enumerateObjectsInContext:self.testMOC withBlock:^(ZMManagedObject *mo, BOOL *stop ZM_UNUSED) {
        XCTAssert([mo isKindOfClass:[MockEntity class]]);
        *stop = YES;
        ++found;
    }];
    
    // then
    XCTAssertEqual(1u, found);
}

- (void)testThatNoKeysAreModifiedRightAfterCreation
{
    // given
    [self.testMOC markAsUIContext];

    MockEntity *user = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];

    // when
    NSSet *keysWithLocalModifications = user.keysThatHaveLocalModifications;

    // then
    XCTAssertEqual(keysWithLocalModifications.count, 0u);
}


- (void)testThatItSetsSomeLocalChanges
{
    // given
    [self.testMOC markAsUIContext];
    
    // when
    __block NSSet *keysWithLocalModifications;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        MockEntity *mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];

        // when
        mockEntity.field = 2;
        mockEntity.field2 = @"Joe Doe";
        [self.testMOC save:nil];
        
        keysWithLocalModifications = mockEntity.keysThatHaveLocalModifications;
    }];
    
    
    // then
    NSSet *expectedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}


- (void)testThatItSetsAllLocalChanges
{
    // given
    [self.testMOC markAsUIContext];
    __block MockEntity *mockEntity;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        
        // when
        mockEntity.field = 6;
        mockEntity.field2 = @"Joe Doe";
        mockEntity.field3 = @"someemail@example.com";
        
        [self.testMOC save:nil];
    }];

    __block NSSet *keysThatHaveLocalModifications;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        keysThatHaveLocalModifications = mockEntity.keysThatHaveLocalModifications;
    }];
    
    // then
    NSSet *expectedKeys = [NSSet setWithObjects:
        @"field",
        @"field2",
        @"field3",
        nil];
    XCTAssertEqualObjects(expectedKeys, keysThatHaveLocalModifications);
}



- (void)testThatItPersistsLocalChanges
{
    // given
    NSUUID *entityUUID = [NSUUID createUUID];
    [self.testMOC markAsUIContext];
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        MockEntity *mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        mockEntity.testUUID = entityUUID;
        mockEntity.field = 99;
        //user.field2 = NOT SET
        mockEntity.field3 = @"Joe Doe";
        [self.testMOC save:nil];
    }];

    // when
    __block NSSet *keysWithLocalModifications;
    [self.alternativeTestMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        MockEntity *fetchedEntity = [self mockEntityWithUUID:entityUUID inMoc:self.alternativeTestMOC];
        keysWithLocalModifications = fetchedEntity.keysThatHaveLocalModifications;
    }];
    
    // then
    NSSet *expectedKeys = [NSSet setWithObjects:
        @"testUUID_data",
        @"field",
        @"field3",
        nil];
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}

- (void)testThatChangesInSyncContextAreNotPersisted
{
    // given
    NSSet *expectedKeys = [NSSet set];
    // not a UI moc
    MockEntity *mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.alternativeTestMOC];

    // when
    mockEntity.field2 = @"someemail@example.com";
    mockEntity.field3 = @"Joe Doe";
    [self.testMOC save:nil];

    // then

    NSSet *keysWithLocalModifications = mockEntity.keysThatHaveLocalModifications;
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}


- (void)testThatLocalChangesAreReset
{
    // given
    [self.testMOC markAsUIContext];

    MockEntity *mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mockEntity.field2 = @"someemail@example.com";
    mockEntity.field3 = @"Joe Doe";
    [self.testMOC save:nil];

    // when
    [mockEntity resetLocallyModifiedKeys:mockEntity.keysThatHaveLocalModifications];

    // then
    NSSet *expectedKeys = [NSSet set];
    NSSet *keysWithLocalModifications = mockEntity.keysThatHaveLocalModifications;
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}


- (void)testThatOnlySomeLocalChangesAreReset
{
    // given
    [self.testMOC markAsUIContext];
    __block MockEntity *mockEntity;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        mockEntity.testUUID = [NSUUID createUUID];
        mockEntity.field = 5;
        mockEntity.field2 = @"someemail@example.com";
        mockEntity.field3 = @"Joe Doe";
        NSError *error;
        XCTAssertTrue([self.testMOC save:&error], @"Error insaving: %@", error);
    }];
    
    // when
    NSSet *keysToReset = [NSSet setWithObjects:@"field2", @"testUUID_data", @"bogus_unknown_attr", nil];
    __block NSSet *keysWithLocalModifications;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        [mockEntity resetLocallyModifiedKeys:keysToReset];
        keysWithLocalModifications = mockEntity.keysThatHaveLocalModifications;
    }];
    
    // then
    NSSet *expectedKeys = [NSSet setWithObjects:@"field", @"field3", nil];
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}


- (void)testThatItUpdatesLocalChangesForReferences
{
    // given
    [self.testMOC markAsUIContext];
    __block MockEntity *mockEntity;
    __block MockEntity *otherMockEntity1;
    __block MockEntity *otherMockEntity2;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        mockEntity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        otherMockEntity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        otherMockEntity2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    }];
    
    // when
    __block NSSet *keysWithLocalModifications;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        mockEntity.field = 2;
        mockEntity.field2 = @"Joe Doe";
        [mockEntity.mockEntities addObjectsFromArray:@[otherMockEntity1, otherMockEntity2]];
        [self.testMOC save:nil];
        keysWithLocalModifications = mockEntity.keysThatHaveLocalModifications;
    }];
    
    // then
    NSSet *expectedKeys = [NSSet setWithObjects:@"field", @"field2", @"mockEntities", nil];
    XCTAssertEqualObjects(expectedKeys, keysWithLocalModifications);
}

- (void)testObjectIDForURIRepresentation
{
    // given
    __block MockEntity *entity1;
    __block MockEntity *entity2;
    __block MockEntity *entity3;
    [self.testMOC performGroupedBlockThenWaitForReasonableTimeout:^{
        entity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        entity2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        entity3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    }];

    // when
    NSManagedObjectID *fetchedID = [MockEntity objectIDForURIRepresentation:entity2.objectID.URIRepresentation inManagedObjectContext:self.testMOC];
    
    // then
    XCTAssertNotEqualObjects(entity1.objectID, fetchedID);
    XCTAssertEqualObjects(entity2.objectID, fetchedID);
    XCTAssertNotEqualObjects(entity3.objectID, fetchedID);
    
}

- (MockEntity *)mockEntityWithUUID:(NSUUID *)UUID inMoc:(NSManagedObjectContext *)moc
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"testUUID_data == %@", [UUID data]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MockEntity"];
    request.predicate = p;
    NSArray *users = [moc executeFetchRequestOrAssert:request];
    return users[0];
}

- (void)testThatNormalObjectsAreNotZombie
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // then
    XCTAssertFalse(entity.isZombieObject);
}

- (void)testThatDeletedObjectsAreZombiesBeforeASave
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.testMOC deleteObject:entity];
    
    // then
    XCTAssertTrue(entity.isZombieObject);
}

- (void)testThatDeletedObjectsAreZombiesAfterASave
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.testMOC deleteObject:entity];
    
    // then
    XCTAssertTrue(entity.isZombieObject);
}

@end


@implementation ZMManagedObjectTests (NonpersistedObjectIdentifer)

- (void)testThatItReturnsTheSameIdentifierForTemporaryAndSavedObjects;
{
    // given
    ZMConversation *mo = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    NSString *s1 = [[mo nonpersistedObjectIdentifer] copy];
    XCTAssert([self.uiMOC saveOrRollback]);
    NSString *s2 = [[mo nonpersistedObjectIdentifer] copy];
    
    // then
    XCTAssertNotNil(s1);
    XCTAssertEqualObjects(s1, s2);
}

- (void)testThatItReturnsAnObjectForANonpersistedObjectIdentifier
{
    // given
    ZMConversation *mo = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *identifier = [[mo nonpersistedObjectIdentifer] copy];
    
    // when
    ZMConversation *mo2 = (id)[ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:identifier inUserSession:self.coreDataStack];
    
    // then
    XCTAssertEqual(mo, mo2);
}

- (void)testThatItReturnsAnObjectForANonpersistedObjectIdentifierAfterASave
{
    // given
    ZMConversation *mo = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *identifier = [[mo nonpersistedObjectIdentifer] copy];
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    ZMConversation *mo2 = (id)[ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:identifier inUserSession:self.coreDataStack];
    
    // then
    XCTAssertEqual(mo, mo2);
}

- (void)testThatItReturnsNilForANilIdentifier;
{
    // given
    id objectIdentifier = nil;
    
    // then
    [self performIgnoringZMLogError:^{
        XCTAssertNil([ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:objectIdentifier inUserSession:self.coreDataStack]);
    }];
}

- (void)testThatItReturnsNilForANonExistingIdentifier;
{
    // given
    __block NSString *identifier;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *mo = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        identifier = [[mo nonpersistedObjectIdentifer] copy];
    }];
    
    // then
    XCTAssertNil([ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:identifier inUserSession:self.coreDataStack]);
}

- (void)testThatItReturnsNilForAnInvalidExistingIdentifier;
{
    XCTAssertNil([ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:@"foo" inUserSession:self.coreDataStack]);
    XCTAssertNil([ZMManagedObject existingObjectWithNonpersistedObjectIdentifer:@"Zfoo" inUserSession:self.coreDataStack]);
}

- (void)testPerformanceRetrievingLocallyModifiedKeys;
{
    // measured with NSSet implementation: average: 0.000, relative standard deviation: 33.239%, values: [0.000581, 0.000390, 0.000353, 0.000351, 0.000269, 0.000238, 0.000249, 0.000239, 0.000239, 0.000237], 
    // 10.000 - average: 3.526, relative standard deviation: 2.786%, values: [3.688881, 3.650577, 3.654529, 3.465883, 3.424065, 3.553015, 3.493663, 3.406812, 3.472713, 3.454525],
    
    // measured with NSString implementation average: 0.000, relative standard deviation: 34.962%, values: [0.000638, 0.000414, 0.000386, 0.000380, 0.000258, 0.000259, 0.000257, 0.000258, 0.000257, 0.000257],
    // 10.000 - average: 3.845, relative standard deviation: 2.959%, values: [4.125333, 3.853140, 3.849008, 3.760596, 3.764041, 3.744273, 3.805642, 3.825166, 3.751391, 3.972608],
    
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.field = 3;
    entity.field3 = @"barfoo";
    [self.testMOC saveOrRollback];

    NSSet *modifiedKeys = [entity keysThatHaveLocalModifications];
    XCTAssertTrue([modifiedKeys containsObject:@"field"]);
    XCTAssertTrue([modifiedKeys containsObject:@"field3"]);
    
    [self.testMOC saveOrRollback];
    [self.testMOC refreshAllObjects];
    XCTAssertTrue(entity.isFault);

    __block int count = 1;
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        // given
        entity.field2 = (count % 2 == 0) ? @"foo" : @"bar";
        count++;
        
        // when
        [self startMeasuring];
        [self.testMOC saveOrRollback];
        NSSet *locallyModifiedKeys = [entity keysThatHaveLocalModifications];
        [self stopMeasuring];
        
        // then
        XCTAssertTrue([locallyModifiedKeys containsObject:@"field2"]);
        
        // reset
        [entity resetLocallyModifiedKeys:[NSSet setWithObject:@"field2"]];
        [self.testMOC saveOrRollback];
        [self.testMOC refreshAllObjects];
        XCTAssertTrue(entity.isFault);
    }];
}

@end
