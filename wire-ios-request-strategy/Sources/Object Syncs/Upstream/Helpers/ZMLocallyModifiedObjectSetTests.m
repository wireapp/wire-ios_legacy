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
@import WireRequestStrategy;

#import "MockEntity.h"
#import "MockModelObjectContextFactory.h"

static NSString * Key1;
static NSString * Key2;
static NSString * UntrackedKey;


@interface ZMLocallyModifiedObjectSetTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) ZMLocallyModifiedObjectSet *sut;
@property (nonatomic) MockEntity *entityA;
@property (nonatomic) MockEntity *entityB;
@property (nonatomic) NSSet *trackedKeys;
@property (nonatomic) NSSet *setWithKey1;

@end


@implementation ZMLocallyModifiedObjectSetTests

- (void)setUp {
    [super setUp];

    Key1 = @"field";
    Key2 = @"field2";
    UntrackedKey = @"field3";
    
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.trackedKeys = [NSSet setWithObjects:Key1, Key2, nil];
    self.entityA = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    self.entityB = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    self.sut = [[ZMLocallyModifiedObjectSet alloc] initWithTrackedKeys:self.trackedKeys];
    self.setWithKey1 = [NSSet setWithObject:Key1];
    
    XCTAssertTrue([self.testMOC saveOrRollback]);
}

- (void)tearDown
{
    self.trackedKeys = nil;
    self.entityA = nil;
    self.entityB = nil;
    self.sut = nil;

    [super tearDown];
}

- (void)testThatItReturnsAnObjectThatWasAdded
{
    // given
    [self.entityA setLocallyModifiedKeys:self.setWithKey1];
    
    // when
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *objectWithKeys = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertNotNil(objectWithKeys);
    XCTAssertEqual(objectWithKeys.object, self.entityA);
    XCTAssertEqualObjects(objectWithKeys.keysToSync, self.setWithKey1);
}

- (void)testThatItDoesNotReturnsAKeyChangeStatusForAnObjectThatWasAddedWithNoChanges
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObject:UntrackedKey]];
    
    // when
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertNil(object);
}

- (void)testThatItOnlyTracksTheSpecifiedKeys
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, UntrackedKey, nil]];
    
    // when
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *status = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertNotNil(status);
    XCTAssertEqual(status.object, self.entityA);
    XCTAssertEqualObjects(status.keysToSync, self.setWithKey1);
}

- (void)testThatItReturnsAnObjectThatWasAddedMultipleTimes
{
    // given
    [self.entityA setLocallyModifiedKeys:self.setWithKey1];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *status1 = [self.sut anyObjectToSynchronize];
    
    // when
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObject:Key2]];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *status2 = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertEqual(status1.object, status2.object);
    XCTAssertEqual(status2.object, self.entityA);
    XCTAssertEqualObjects(status2.keysToSync, self.trackedKeys);
}

- (void)testThatItReturnsTheRemainingKeysWhenWeStartAPartialSyncForAnObject;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:[NSSet setWithObject:Key1] forObject:object];
    
    // then
    XCTAssertNotNil(self.sut.anyObjectToSynchronize);
    XCTAssertEqual(self.sut.anyObjectToSynchronize.object, self.entityA);
    XCTAssertEqualObjects(self.sut.anyObjectToSynchronize.keysToSync, [NSSet setWithObject:Key2]);
    
}

- (void)testThatItDoesNotReturnAnObjectAfterItStartsASync;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    
    // then
    ZMObjectWithKeys *remainingObject = self.sut.anyObjectToSynchronize;
    XCTAssertNil(remainingObject);
}


- (void)testThatItResetsLocallyModifiedKeys;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];

    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:[NSSet setWithObject:Key1] forObject:object];
    [self.sut didSynchronizeToken:token];
    
    // then
    NSSet *remaining = self.entityA.keysThatHaveLocalModifications;
    NSSet *expected = [NSSet setWithObjects:Key2, UntrackedKey, nil];
    XCTAssertEqualObjects(remaining, expected);
}

- (void)testThatItDoesNotReturnAnObjectAfterAllKeysAreSynced;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    [self.sut didSynchronizeToken:token];
    
    // then
    XCTAssertNil(self.sut.anyObjectToSynchronize);
}

- (void)testThatItDoesNotReturnAnObjectAfterTheSyncFailed;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    [self.sut didFailToSynchronizeToken:token];
    
    // then
    ZMObjectWithKeys *remainingObject = self.sut.anyObjectToSynchronize;
    XCTAssertNil(remainingObject);
}

- (void)testThatItMarksTheObjectAsInNeedToBeUpdatedFromBackendAfterTheSyncFailed;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    self.entityA.needsToBeUpdatedFromBackend = NO;
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    [self.sut didFailToSynchronizeToken:token];
    
    // then
    XCTAssertTrue(self.entityA);
}

- (void)testThatItDoesResetLocallyModifiedKeysAfterTheSyncFailed;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    [self.sut didFailToSynchronizeToken:token];
    
    // then
    XCTAssertEqualObjects(object.object.keysThatHaveLocalModifications, [NSSet setWithObject:UntrackedKey]);
}


- (void)testThatItStillReturnsAnObjectIfNotAllKeysWereSynced;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:[NSSet setWithObject:Key1] forObject:object];
    [self.sut didSynchronizeToken:token];
    
    // then
    XCTAssertNotNil(self.sut.anyObjectToSynchronize);
    XCTAssertEqual(self.sut.anyObjectToSynchronize.object, self.entityA);
    XCTAssertEqualObjects(self.sut.anyObjectToSynchronize.keysToSync, [NSSet setWithObject:Key2]);

}

- (void)testThatItStillReturnsAnObjectIfItDidNotFinishToSynchronize;
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object.keysToSync forObject:object];
    [self.sut didNotFinishToSynchronizeToken:token];
    
    // then
    ZMObjectWithKeys *remainingObject = self.sut.anyObjectToSynchronize;
    XCTAssertNotNil(remainingObject);
    XCTAssertEqual(object.object, remainingObject.object);
    XCTAssertEqualObjects(object.keysToSync, remainingObject.keysToSync);
}


- (void)testThatIfThereAreMoreThanOneObjectAndTheFirstObjectIsAlreadySynchronizingAllKeysItReturnsTheSecondObject
{
    // given
    [self.entityA setLocallyModifiedKeys:self.trackedKeys];
    [self.entityB setLocallyModifiedKeys:self.trackedKeys];
    
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    [self.sut addPossibleObjectToSynchronize:self.entityB];

    ZMObjectWithKeys *object1 = [self.sut anyObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:object1.keysToSync forObject:object1];
    ZMObjectWithKeys *object2 = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertNotNil(object2);
    XCTAssertNotEqual(object1.object, object2.object);

}

- (void)testThatItDoesNotReturnAnObjectThatWasAddedIfItsKeysWhereResetInTheMeanwhile
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    
    // when
    [self.entityA resetLocallyModifiedKeys:self.trackedKeys];
    
    // then
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    XCTAssertNil(object);
    
}

- (void)testThatItTracksAllKeysIfNoKeysIsSet
{
    // give
    [self.entityA setLocallyModifiedKeys:self.trackedKeys];
    self.sut = [[ZMLocallyModifiedObjectSet alloc] init];
    
    // when
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertEqualObjects(object.keysToSync, self.trackedKeys);
}

- (void)testThatKeysToParseReturnsAllKeysIfThereWasNoModificationSinceItStartedToSync
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object1 = [self.sut anyObjectToSynchronize];
    NSSet *originalKeys = [object1.keysToSync copy];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object1.keysToSync forObject:object1];
    NSSet *keysToParse = [self.sut keysToParseAfterSyncingToken:token];
    
    // then
    XCTAssertEqualObjects(keysToParse, originalKeys);
}

- (void)testThatKeysToParseReturnsTheKeysNotModifiedSinceItStartedToSync
{
    // given
    [self.entityA setLocallyModifiedKeys:[NSSet setWithObjects:Key1, Key2, UntrackedKey, nil]];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object1 = [self.sut anyObjectToSynchronize];
    NSSet *expectedKeys = [NSSet setWithObject:Key1];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:object1.keysToSync forObject:object1];
    self.entityA.field2 = @"This is a new value!!!!!!";

    NSSet *keysToParse = [self.sut keysToParseAfterSyncingToken:token];
    
    // then
    XCTAssertEqualObjects(keysToParse, expectedKeys);
}

- (void)testThatItHasNoOutstandingItemsWhenCreated;
{
    XCTAssertFalse(self.sut.hasOutstandingItems);
}

- (void)testThatItHasOutstandingItemsWhenOneIsAdded;
{
    // given
    [self.entityA setLocallyModifiedKeys:self.setWithKey1];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems);
}

- (void)testThatItHasOutstandingItemsWhenOneIsAddedAndStarted;
{
    // given
    [self.entityA setLocallyModifiedKeys:self.setWithKey1];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:self.setWithKey1 forObject:object];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems);
}

- (void)testThatItHasNoOutstandingItemsAfterTheSyncCompletes
{
    // given
    [self.entityA setLocallyModifiedKeys:self.setWithKey1];
    [self.sut addPossibleObjectToSynchronize:self.entityA];
    ZMObjectWithKeys *object = [self.sut anyObjectToSynchronize];
    
    // when
    ZMModifiedObjectSyncToken *token = [self.sut didStartSynchronizingKeys:self.setWithKey1 forObject:object];
    [self.sut didSynchronizeToken:token];
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems);
}

@end
