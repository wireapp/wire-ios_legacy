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

#import "WireRequestStrategyTests-Swift.h"

@import WireDataModel;
@import WireTesting;
@import WireRequestStrategy;


static NSString * Key1;
static NSString * Key2;


@interface ZMLocallyModifiedObjectSyncStatusTests : ZMTBaseTest

@property (nonatomic) CoreDataStack *coreDataStack;
@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) NSSet *trackedKeys;
@property (nonatomic) NSSet *trackedKeysB;

@end


@implementation ZMLocallyModifiedObjectSyncStatusTests

- (void)setUp {
    [super setUp];

    self.coreDataStack = self.coreDataStack = [self createCoreDataStackWithUserIdentifier:[NSUUID UUID]
                                                                            inMemoryStore:YES];

    Key1 = ZMConversationSilencedChangedTimeStampKey;
    Key2 = ZMConversationUserDefinedNameKey;
    
    self.trackedKeys = [NSSet setWithObjects:Key1, Key2, nil];
    self.conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.coreDataStack.viewContext];

    self.trackedKeysB = [NSSet setWithObject:Key1];
}

- (void)tearDown {
    self.coreDataStack = nil;
    self.conversation = nil;
    self.trackedKeys = nil;
    self.trackedKeysB = nil;
    
    [super tearDown];
}


- (void)testThatInitOnAnObjectWithNoLocalModificationReturnsNil
{
    // when
    ZMLocallyModifiedObjectSyncStatus *status = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // then
    XCTAssertNil(status);
}


- (void)testThatInitOnAnObjectWithLocalModificationReturnsTheModifiedKeys
{
    // when
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *status = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // then
    XCTAssertNotNil(status);
    XCTAssertEqualObjects(status.keysToSynchronize, self.trackedKeys);
}


- (void)testThatItIsDoneIfAllTrackedKeysNoLongerHaveLocalModifications
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    [self.conversation resetLocallyModifiedKeys:self.trackedKeys];
    
    // then
    XCTAssertTrue(sut.isDone);
}

- (void)testThatItDoesNotReturnKeysToSyncAfterTheyHaveBeenStarted
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];

    // when
    [sut startSynchronizingKeys:[NSSet setWithObject:Key1]];
    
    // then
    NSSet *expectedRemainingKeys = [NSSet setWithObject:Key2];
    XCTAssertEqualObjects(sut.keysToSynchronize, expectedRemainingKeys);
}

- (void)testThatItIsNotDoneWhenAllKeysHaveStartedButNotFinished;
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    [sut startSynchronizingKeys:self.trackedKeys];
    [self.conversation resetLocallyModifiedKeys:self.trackedKeys];
    
    // then
    XCTAssertFalse(sut.isDone);
    XCTAssertEqual(sut.keysToSynchronize.count, 0u);
}

- (void)testThatItIsDoneWhenAllKeysHaveStartedAndFinished;
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    [self.conversation resetLocallyModifiedKeys:self.trackedKeys];
    [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertTrue(sut.isDone);
}

- (void)testThatItIsNotDoneWhenAllKeysHaveStartedAndOnlyOneFinished;
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    [self.conversation resetLocallyModifiedKeys:[NSSet setWithObject:Key1]];
    [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertFalse(sut.isDone);
}

- (void)testThatItReAddsKeysToSynchronizeWhenASynchronizationFailed
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertEqualObjects(sut.keysToSynchronize, self.trackedKeys);
}

- (void)testThatItReturnsKeysThatChangedInTheMeanwhileAfterSynchronization
{
    // given
    self.conversation.userDefinedName = @"xxxxxx";
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    self.conversation.userDefinedName = @"Fooooooooo";
    NSSet *changed = [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertEqualObjects(changed, [NSSet setWithObject:Key2]);
}

- (void)testThatItReturnsKeysThatChangedInTheMeanwhileAfterSynchronization_nilValue
{
    // given
    self.conversation.userDefinedName = nil;
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    self.conversation.userDefinedName = @"Fooooooooo";
    NSSet *changed = [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertEqualObjects(changed, [NSSet setWithObject:Key2]);
}


- (void)testThatItDoesNotReturnAnyLocallyModifiedKeysWhenSyncFinishes;
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    NSSet *changed = [sut returnChangedKeysAndFinishTokenSync:token];
    
    // then
    XCTAssertEqual(changed.count, 0u);
}

- (void)testThatItResetsTheLocallyModifiedStatusOfKeysInAToken
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:self.trackedKeys];
    [sut resetLocallyModifiedKeysForToken:token];
    
    // then
    XCTAssertEqual(self.conversation.keysThatHaveLocalModifications.count, 0u);
    
}

- (void)testThatItPartiallyResetsTheLocallyModifiedStatusOfKeysInAToken
{
    // given
    [self.conversation setLocallyModifiedKeys:self.trackedKeys];
    ZMLocallyModifiedObjectSyncStatus *sut = [[ZMLocallyModifiedObjectSyncStatus alloc] initWithObject:self.conversation trackedKeys:self.trackedKeys];
    
    // when
    ZMLocallyModifiedObjectSyncStatusToken *token = [sut startSynchronizingKeys:[NSSet setWithObject:Key1]];
    [sut resetLocallyModifiedKeysForToken:token];
    
    // then
    XCTAssertEqualObjects(self.conversation.keysThatHaveLocalModifications, [NSSet setWithObject:Key2]);
    
}

@end
