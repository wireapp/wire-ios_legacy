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

#import "ZMSyncOperationSet.h"
#import "MockEntity.h"
#import "MockEntity2.h"
#import "MockModelObjectContextFactory.h"


@interface ZMSyncOperationSetTests : ZMTBaseTest

@property (nonatomic) ZMSyncOperationSet *sut;
@property (nonatomic) NSManagedObjectContext *testMOC;

@end


@implementation ZMSyncOperationSetTests

- (void)setUp
{
    [super setUp];
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.sut = [[ZMSyncOperationSet alloc] init];
    self.sut.sortDescriptors = [MockEntity sortDescriptorsForUpdating];
}

- (void)tearDown
{
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItReturnsAnObjectAfterItHasBeenAdded
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.sut addObjectToBeSynchronized:mo];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo);
}

- (void)testThatItReturnsTheFirstObjectIfItIsNotStarted
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 1;
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo2.field = 2;
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo3.field = 3;
    
    // when
    [self.sut addObjectToBeSynchronized:mo1];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo3];
    
    // then
    XCTAssertEqual(self.sut.count, 3u);
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo1);
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo1);
}

- (void)testThatItDoesNotReturnAnObjectAfterItIsStarted
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];

    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}


- (void)testThatItDoesNotReturnObjectAfterItIsStartedEvenIfItIsAddedAgain
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    // when
    [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    [self.sut addObjectToBeSynchronized:mo1];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}

- (void)testThatItReturnsAnObjectAgainAfterSynchronizationFailsWithATemporaryError
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    // when
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:firstObject result:ZMTransportResponseStatusTemporaryError];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertEqualObjects(mo1, [self.sut nextObjectToSynchronize]);
}

- (void)testThatItReturnsAnObjectAgainAfterSynchronizationFailsWithATryAgainLaterError
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    // when
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:firstObject result:ZMTransportResponseStatusTryAgainLater];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertEqualObjects(mo1, [self.sut nextObjectToSynchronize]);
}

- (void)testThatItDoesNotReturnAnObjectAgainAfterSynchronizationWasSuccessful
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    // when
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    id keys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:firstObject result:ZMTransportResponseStatusSuccess];
    [self.sut removeUpdatedObject:firstObject syncToken:token synchronizedKeys:keys];
    
    // then
    XCTAssertEqual(self.sut.count, 0u);
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}

- (void)testThatItDoesReturnAnObjectAgainAfterSynchronizationWasSuccessfulAndItWasReAdded
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    ZMManagedObject *firstObject = [self.sut nextObjectToSynchronize];
    
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:nil forObject:firstObject];
    [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:firstObject result:ZMTransportResponseStatusSuccess];
    
    // when
    [self.sut addObjectToBeSynchronized:mo1];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    XCTAssertEqualObjects(mo1, [self.sut nextObjectToSynchronize]);
}


- (void)testThatItReturnsObjectsInTheUpdateOrder;
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 10;
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo2.field = 90;
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo3.field = 20;

    [self.sut addObjectToBeSynchronized:mo1];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo3];

    // when / then
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo1);
    [self.sut didStartSynchronizingKeys:nil forObject:mo1];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo3);
    [self.sut didStartSynchronizingKeys:nil forObject:mo3];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo2);
    [self.sut didStartSynchronizingKeys:nil forObject:mo2];
    XCTAssertNil([self.sut nextObjectToSynchronize]);
    
    XCTAssertEqual(self.sut.count, 3u);
}

- (void)testThatItReturnsObjectsInTheUpdateOrder_2
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 30;
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo2.field = 20;
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo3.field = 10;
    
    [self.sut addObjectToBeSynchronized:mo3];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo1];
    
    // when / then
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo3);
    [self.sut didStartSynchronizingKeys:nil forObject:mo3];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo2);
    [self.sut didStartSynchronizingKeys:nil forObject:mo2];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo1);
    [self.sut didStartSynchronizingKeys:nil forObject:mo1];
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}

- (void)testThatItTheUpdateOrderIsEvaluatesAtRetrievalTime
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 10;
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo2.field = 20;
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo3.field = 30;
    
    [self.sut addObjectToBeSynchronized:mo3];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo1];
    
    mo1.field = 30;
    mo2.field = 20;
    mo3.field = 10;
    
    // when / then
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo3);
    [self.sut didStartSynchronizingKeys:nil forObject:mo3];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo2);
    [self.sut didStartSynchronizingKeys:nil forObject:mo2];
    XCTAssertEqual([self.sut nextObjectToSynchronize], mo1);
    [self.sut didStartSynchronizingKeys:nil forObject:mo1];
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}


- (void)testThatItReturnsSynchronizedKeysAfterSuccessfullySynchronizing
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    NSSet *expectedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:expectedKeys forObject:mo1];
    
    // when
    NSSet *synchronizedKeys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:mo1 result:ZMTransportResponseStatusSuccess];
    
    // then
    XCTAssertEqualObjects(synchronizedKeys, expectedKeys);
}

- (void)testThatItReturnsNoSynchronizedKeysAfterAFailedSynchronizationWithTemporaryError
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    NSSet *changedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:changedKeys forObject:mo1];
    
    // when
    NSSet *synchronizedKeys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:mo1 result:ZMTransportResponseStatusTemporaryError];
    
    // then
    XCTAssertEqualObjects(synchronizedKeys, [NSSet set]);
}

- (void)testThatItReturnsAllSynchronizedKeysAfterAFailedSynchronizationWithPermanentError
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    NSSet *changedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:changedKeys forObject:mo1];
    
    // when
    NSSet *synchronizedKeys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:mo1 result:ZMTransportResponseStatusPermanentError];
    
    // then
    XCTAssertEqualObjects(synchronizedKeys, changedKeys);
}

- (void)testThatItDoesNotSynchronizeKeysIfTheirValuesChange
{
    
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 1;
    mo1.field2 = @"1";
    
    [self.sut addObjectToBeSynchronized:mo1];
    
    NSSet *changedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:changedKeys forObject:mo1];
    
    mo1.field = 2;
    mo1.field2 = @"2";
    
    // when
    NSSet *synchronizedKeys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:mo1 result:ZMTransportResponseStatusSuccess];
    
    // then
    XCTAssertEqualObjects(synchronizedKeys, [NSSet set]);
    XCTAssertEqualObjects(mo1, [self.sut nextObjectToSynchronize]);
}

- (void)testThatItSynchronizesOnlyOneKeyOutOfTwoIfItsValueDidNotChange
{
    
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    mo1.field = 1;
    mo1.field2 = @"1";
    
    [self.sut addObjectToBeSynchronized:mo1];
    
    NSSet *changedKeys = [NSSet setWithObjects:@"field", @"field2", nil];
    ZMSyncToken *token = [self.sut didStartSynchronizingKeys:changedKeys forObject:mo1];
    
    mo1.field = 2;
    
    // when
    NSSet *synchronizedKeys = [self.sut keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:token forObject:mo1 result:ZMTransportResponseStatusSuccess];
    
    // then
    XCTAssertEqualObjects(synchronizedKeys, [NSSet setWithObject:@"field2"]);
    XCTAssertEqualObjects(mo1, [self.sut nextObjectToSynchronize]);
}

- (void)testThatItDeletesASyncObject
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    // when
    [self.sut removeObject:mo1];
    
    // then
    XCTAssertNil([self.sut nextObjectToSynchronize]);
}

@end



@implementation ZMSyncOperationSetTests (PartialUpdates)

- (void)testThatItReturnsAnObjectWithNoRemainingKeysAfterItHasBeenAdded
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.sut addObjectToBeSynchronized:mo];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    NSSet *keys;
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertNil(keys);
}

- (void)testThatItReturnsTheSameObjectWithRemainingKeysAfterSettingRemainingKeys;
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.sut addObjectToBeSynchronized:mo];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    NSSet *keys;
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertNil(keys);
    
    // when
    NSSet *remaininKeys = [NSSet setWithObjects:@"A", @"B", nil];
    [self.sut setRemainingKeys:remaininKeys forObject:mo];
    
    // then
    XCTAssertGreaterThanOrEqual(self.sut.count, 1u);
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertEqual(keys, remaininKeys);
    
    // when
    remaininKeys = [NSSet setWithObjects:@"A", nil];
    [self.sut setRemainingKeys:remaininKeys forObject:mo];
    
    // then
    XCTAssertGreaterThanOrEqual(self.sut.count, 1u);
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertEqual(keys, remaininKeys);
}

- (void)testThatItDoesNotReturnTheSameObjectAfterSettingTheRemainingKeysToEmpty;
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.sut addObjectToBeSynchronized:mo];
    
    // then
    XCTAssertEqual(self.sut.count, 1u);
    NSSet *keys;
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertNil(keys);
    
    // when
    NSSet *remaininKeys = [NSSet setWithObjects:@"field2", @"field3", nil];
    [self.sut didStartSynchronizingKeys:remaininKeys forObject:mo];
    [self.sut setRemainingKeys:remaininKeys forObject:mo];
    remaininKeys = [NSSet set];
    [self.sut setRemainingKeys:remaininKeys forObject:mo];
    
    // then
    XCTAssertNil([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil]);
    XCTAssertNil(keys);
}

- (void)testThatSettingTheRemainingKeysToEmptHasNoEffectWhenThatObjectDidNotHaveRemainingKeys
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    // when
    [self.sut setRemainingKeys:[NSSet set] forObject:mo1];
    
    // then
    NSSet *keys;
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo1);
    XCTAssertNil(keys);
}

- (void)testThatItDeletesASyncObjectWhenSettingTheRemainingKeysToEmptyAfterSettingTheRemainingKeys
{
    // given
    MockEntity *mo1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToBeSynchronized:mo1];
    
    // when
    NSSet *keys = [NSSet setWithObject:@"field2"];
    [self.sut didStartSynchronizingKeys:keys forObject:mo1];
    [self.sut setRemainingKeys:keys forObject:mo1];
    [self.sut setRemainingKeys:[NSSet set] forObject:mo1];
    
    // then
    NSSet *keys2;
    XCTAssertNil([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys2 notInOperationSet:nil]);
    XCTAssertNil(keys2);
}

- (void)testThatItReturnsAnObjectWithNoRemainingKeysWhenItIsAddedAgainAfterSettingRemainingKeys
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    // when
    [self.sut addObjectToBeSynchronized:mo];
    NSSet *remaininKeys = [NSSet setWithObjects:@"A", @"B", nil];
    [self.sut setRemainingKeys:remaininKeys forObject:mo];
    [self.sut addObjectToBeSynchronized:mo];
    
    // then
    XCTAssertGreaterThanOrEqual(self.sut.count, 1u);
    NSSet *keys;
    XCTAssertEqual([self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:nil], mo);
    XCTAssertNil(keys);
}

- (void)testThatItReturnsTheFirstObjectThatIsNotInAnotherSet
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];

    
    [self.sut addObjectToBeSynchronized:mo];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo3];
    
    ZMSyncOperationSet *otherSet = [[ZMSyncOperationSet alloc] init];
    [otherSet addObjectToBeSynchronized:mo];
    [otherSet addObjectToBeSynchronized:mo2];
    
    // when
    NSSet *keys;
    ZMManagedObject *nextObject = [self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:otherSet];
    
    // then
    XCTAssertEqualObjects(nextObject, mo3);
}

- (void)testThatItReturnsNilIfAllObjectsAreInOtherSet
{
    // given
    MockEntity *mo = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    MockEntity *mo2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    MockEntity *mo3 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    
    [self.sut addObjectToBeSynchronized:mo];
    [self.sut addObjectToBeSynchronized:mo2];
    [self.sut addObjectToBeSynchronized:mo3];
    
    ZMSyncOperationSet *otherSet = [[ZMSyncOperationSet alloc] init];
    [otherSet addObjectToBeSynchronized:mo];
    [otherSet addObjectToBeSynchronized:mo2];
    [otherSet addObjectToBeSynchronized:mo3];
    
    // when
    NSSet *keys;
    ZMManagedObject *nextObject = [self.sut nextObjectToSynchronizeWithRemainingKeys:&keys notInOperationSet:otherSet];
    
    // then
    XCTAssertNil(nextObject);
}

@end
