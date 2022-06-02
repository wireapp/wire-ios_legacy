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

#import "ZMLocallyInsertedObjectSet.h"
#import "MockEntity.h"
#import "MockModelObjectContextFactory.h"


@interface ZMLocallyInsertedObjectSetTests : ZMTBaseTest

@property (nonatomic) MockEntity *entity;
@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) ZMLocallyInsertedObjectSet *sut;

@end


@implementation ZMLocallyInsertedObjectSetTests

- (void)setUp {
    [super setUp];
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.sut = [[ZMLocallyInsertedObjectSet alloc] init];
    self.entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
}

- (void)tearDown {

    self.sut = nil;
    self.entity = nil;
    [super tearDown];
}

- (void)testThatItReturnsNoObjectsAfterInit
{
    // when
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertNil(object);
}

- (void)testThatItReturnsAnObjectAfterItHasBeenAdded
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    
    // then
    XCTAssertEqual(object, self.entity);
}

- (void)testThatItDoesNotReturnAnObjectAfterItStartedSync
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertNil(object);
}

- (void)testThatItReturnsAnotherObjectWhenItSyncsTheFirst
{
    // given
    MockEntity *entity2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut addObjectToSynchronize:entity2];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertEqual(object, entity2);
}

- (void)testThatItDoesNotReturnTheObjectAgainWhenDoneSyncing
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    [self.sut didFinishSynchronizingObject:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertNil(object);
}

- (void)testThatItReturnsAnotherObjectWhenItIsDoneSyncingTheFirst
{
    // given
    MockEntity *entity2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut addObjectToSynchronize:entity2];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    [self.sut didFinishSynchronizingObject:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertEqual(object, entity2);
}

- (void)testThatItReturnsTheObjectAgainWhenFailedToSync
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    [self.sut didFailSynchronizingObject:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertEqual(object, self.entity);
}

- (void)testThatItReturnsAnObjectAfterItWasFinishedAndThenReadded
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    [self.sut didFinishSynchronizingObject:self.entity];
    [self.sut addObjectToSynchronize:self.entity];
    
    // then
    ZMManagedObject *object = [self.sut anyObjectToSynchronize];
    XCTAssertEqual(object, self.entity);
}

- (void)testThatItCanAddMultipleTimesAndThatWhenItFinishesSyncingTheObjectIsGone
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut addObjectToSynchronize:self.entity];
    XCTAssertEqual(self.entity, [self.sut anyObjectToSynchronize]);
    
    // when
    [self.sut didStartSynchronizingObject:self.entity];
    [self.sut didFinishSynchronizingObject:self.entity];
    
    // then
    XCTAssertNil([self.sut anyObjectToSynchronize]);
}

- (void)testThatItRemovesAnObject
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    
    // when
    [self.sut removeObjectToSynchronize:self.entity];
    
    // then
    XCTAssertNil([self.sut anyObjectToSynchronize]);
}

- (void)testThatItDoesNotCrashWhenRemoveingAnObjectThatIsNotThere
{
    // when
    [self.sut removeObjectToSynchronize:self.entity];
    
    // then
    XCTAssertNil([self.sut anyObjectToSynchronize]);
}

- (void)testThatItDoesNotCrashWhenRemovingAnObjectThatIsCurrentlySynchronized
{
    // given
    [self.sut addObjectToSynchronize:self.entity];
    [self.sut didStartSynchronizingObject:self.entity];
    
    // when
    [self.sut removeObjectToSynchronize:self.entity];
    
    // then
    [self.sut didFailSynchronizingObject:self.entity]; // Should not crash

}

@end
