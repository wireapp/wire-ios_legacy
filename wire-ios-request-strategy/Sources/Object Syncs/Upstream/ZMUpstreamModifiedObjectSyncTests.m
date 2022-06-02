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


@import WireTransport;
@import WireDataModel;
@import WireTesting;
@import WireRequestStrategy;

#import "ZMUpstreamModifiedObjectSync+Testing.h"
#import "MockEntity.h"
#import "MockEntity2.h"
#import "MockModelObjectContextFactory.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMLocallyModifiedObjectSet.h"
#import "ZMChangeTrackerBootstrap+Testing.h"
#import "NSManagedObjectContext+TestHelpers.h"

static NSString * const FieldUsedInPredicate = @"field2";
static NSString * const ValueUsedToFailPredicate = @"fail me!";

@interface ZMUpstreamModifiedObjectSyncTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) id<ZMUpstreamTranscoder> mockTranscoder;
@property (nonatomic) ZMUpstreamModifiedObjectSync *sut;
@property (nonatomic) NSMutableDictionary *objectIDToObjectDependency;
@property (nonatomic) id mockLocallyModifiedSet;
@property (nonatomic) NSSet<NSString *> *trackedKeys;

-(ZMUpstreamRequest *)dummyRequestWithKeys:(NSSet *)keys;

@end

static NSString *foo = @"foo";

@implementation ZMUpstreamModifiedObjectSyncTests

- (void)setUp
{
    [super setUp];
    self.testMOC = [MockModelObjectContextFactory testContext];
    
    [self createSystemUnderTest];
    //XCTAssertNil([self.sut  nextRequestForAPIVersion:APIVersionV0]);); // Make sure we've -fetchObjectsFromStore did run
    self.testMOC.userInfo[@"ZMIsUserInterfaceContext"] = @YES;
}

- (NSObject *)transcoderDependentObjectForUpdate:(NSManagedObject *)obj
{
    return self.objectIDToObjectDependency[obj.objectID];
}

- (void)createSystemUnderTest;
{
    self.trackedKeys = [NSSet setWithObjects:@"field", @"field2", @"field3", nil];
    
    self.mockTranscoder = [OCMockObject mockForProtocol:@protocol(ZMUpstreamTranscoder)];
    self.objectIDToObjectDependency = [NSMutableDictionary dictionary];

    [[[(id) self.mockTranscoder stub] andCall:@selector(transcoderDependentObjectForUpdate:) onObject:self] dependentObjectNeedingUpdateBeforeProcessingObject:OCMOCK_ANY];
    
    self.mockLocallyModifiedSet = [OCMockObject mockForClass:ZMLocallyModifiedObjectSet.class];
    [self verifyMockLater:self.mockLocallyModifiedSet];

    // stub mock entity predicate
    MockEntity.predicateForObjectsThatNeedToBeUpdatedUpstream = [NSPredicate predicateWithFormat:@"%K != %@", FieldUsedInPredicate, ValueUsedToFailPredicate];
    
    self.sut = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                             entityName:MockEntity.entityName
                                                        updatePredicate:nil
                                                                 filter:nil
                                                             keysToSync:self.trackedKeys.allObjects
                                                   managedObjectContext:self.testMOC
                                               locallyModifiedObjectSet:self.mockLocallyModifiedSet];
    
    XCTAssertEqual(self.sut.updatedObjects, self.mockLocallyModifiedSet);
    [self verifyMockLater:self.mockTranscoder];
}

- (void)tearDown
{
    self.sut = nil;
    self.mockTranscoder = nil;
    self.mockLocallyModifiedSet = nil;
    self.testMOC.userInfo[@"ZMIsUserInterfaceContext"] = @NO;
    self.objectIDToObjectDependency = nil;
    [super tearDown];
}

- (void)testThatTheNormalInitCreatesALocallyModifiedSet
{
    // when
    ZMUpstreamModifiedObjectSync *sut = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                                                      entityName:MockEntity.entityName
                                                                                 updatePredicate:nil
                                                                                          filter:nil
                                                                                      keysToSync:self.trackedKeys.allObjects
                                                                            managedObjectContext:self.testMOC
                                                                        locallyModifiedObjectSet:nil];
    // then
    XCTAssertNotNil(sut.updatedObjects);
    XCTAssertEqualObjects(sut.updatedObjects.trackedKeys, self.trackedKeys);
}

- (MockEntity *)mockEntityWithModifiedValue
{
    __block MockEntity *entity;
    [self.testMOC performGroupedBlockAndWaitWithReasonableTimeout:^{
        entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        entity.field2 = @"foo";
        XCTAssertTrue([self.testMOC saveOrRollback]);
    }];
    return entity;
}


- (MockEntity *)mockEntityWithSeveralModifiedValues
{
    __block MockEntity *entity;
    [self.testMOC performGroupedBlockAndWaitWithReasonableTimeout:^{
        entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
        entity.field = 23423;
        entity.field2 = @"foo";
        entity.field3 = @"bar";
        XCTAssertTrue([self.testMOC saveOrRollback]);
    }];
    return entity;
}


- (ZMObjectWithKeys *)fakeObject:(ZMManagedObject *)object withKeys:(NSSet *)keys
{
    id fake = [OCMockObject mockForClass:ZMObjectWithKeys.class];
    (void)[(ZMObjectWithKeys *)[[fake stub] andReturn:object] object];
    [(ZMObjectWithKeys *)[[fake stub] andReturn:keys] keysToSync];
    return fake;
}

- (MockEntity2 *)mockEntity2WithModifiedValue
{
    MockEntity2 *entity2 = [MockEntity2 insertNewObjectInManagedObjectContext:self.testMOC];
    entity2.field = 1234;
    
    XCTAssertTrue([self.testMOC saveOrRollback]);
    
    return entity2;
}

-(ZMTransportRequest *)dummyTransportRequest
{
    return [ZMTransportRequest requestGetFromPath:[@"dummy-from-test-" stringByAppendingString:self.name] apiVersion:APIVersionV0];
}

-(ZMUpstreamRequest *)dummyRequestWithKeys:(NSSet *)keys
{
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:[@"dummy-from-test-" stringByAppendingString:self.name] apiVersion:APIVersionV0];
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:transportRequest];
}

- (void)completeRequestOnMainQueue:(ZMTransportRequest *)request withResponse:(ZMTransportResponse *)response
{
    // when
    [request completeWithResponse:response];

    // then
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThaItUsesPassedInPredicates
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    entity.field2 = ValueUsedToFailPredicate;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"field2", ValueUsedToFailPredicate];
    
    // expect
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];

    // when
    ZMUpstreamModifiedObjectSync *sut = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                                                      entityName:MockEntity.entityName
                                                                                 updatePredicate:predicate
                                                                                          filter:nil
                                                                                      keysToSync:self.trackedKeys.allObjects
                                                                            managedObjectContext:self.testMOC
                                                                        locallyModifiedObjectSet:self.mockLocallyModifiedSet
                                         ];
    [sut objectsDidChange:[NSSet setWithObject:entity]];
}


- (void)testThaItUsesPassedInFilters_FilterRejects
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    entity.field3 = @"bar";
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K != %@", @"field3", @"bar"];
    
    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:entity];

    // when
    ZMUpstreamModifiedObjectSync *sut = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                                                      entityName:MockEntity.entityName
                                                                                 updatePredicate:nil
                                                                                          filter:filter
                                                                                      keysToSync:self.trackedKeys.allObjects
                                                                            managedObjectContext:self.testMOC
                                                                        locallyModifiedObjectSet:self.mockLocallyModifiedSet
                                         ];
    [sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThaItUsesPassedInFilters_FilterPasses
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    entity.field3 = @"bar";
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K == %@", @"field3", @"bar"];
    
    // expect
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];
    
    // when
    ZMUpstreamModifiedObjectSync *sut = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                                                      entityName:MockEntity.entityName
                                                                                 updatePredicate:nil
                                                                                          filter:filter
                                                                                      keysToSync:self.trackedKeys.allObjects
                                                                            managedObjectContext:self.testMOC
                                                                        locallyModifiedObjectSet:self.mockLocallyModifiedSet
                                         ];
    [sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItReturnsTheCorrectFetchRequest
{
    // when
    NSFetchRequest *request = [self.sut fetchRequestForTrackedObjects];
    
    // then
    NSFetchRequest *expected = [MockEntity sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"%K != %@", FieldUsedInPredicate, ValueUsedToFailPredicate]];
    XCTAssertEqualObjects(request, expected);
}

- (void)testThatItAddsTrackedObjects
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    NSSet *objects = [NSSet setWithObject:entity];
    
    // expect
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];
    
    // when
    [self.sut addTrackedObjects:objects];
}

- (void)testThatItAddsObjectsToUpdatedObjectsSet_OnObjectDidChange
{
    // expect
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // then
    [self.mockLocallyModifiedSet verify];
    
}

- (void)testThatItAddsObjectsToUpdatedObjectsSet_OnInitialization
{
    // expect
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];
    
    // when
    [ZMChangeTrackerBootstrap bootStrapChangeTrackers:@[self.sut] onContext:self.testMOC];
    
    // then
    [self.mockLocallyModifiedSet verify];
    
}

- (void)testThatItDoesNotAddObjectsOfTheWrongTypeToUpdateObjectsSet_OnObjectDidChange
{
    // given
    MockEntity2 *entity = [self mockEntity2WithModifiedValue];

    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:OCMOCK_ANY];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // then
    [self.mockLocallyModifiedSet verify];
}

- (void)testThatItDoesNotAddObjectsOfTheWrongTypeToUpdateObjectsSet_OnInitialization
{
    // given
    (void)[self mockEntity2WithModifiedValue];
    
    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:OCMOCK_ANY];
    
    // when
    [ZMChangeTrackerBootstrap bootStrapChangeTrackers:@[self.sut] onContext:self.testMOC];
    
    // then
    [self.mockLocallyModifiedSet verify];
}

- (void)testThatItDoesNotAddObjectsNotMatchingPredicate_OnObjectDidChange
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [entity setValue:ValueUsedToFailPredicate forKey:FieldUsedInPredicate];
    
    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:OCMOCK_ANY];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // then
    [self.mockLocallyModifiedSet verify];
}

- (void)testThatItDoesNotAddObjectsNotMatchingPredicate_OnInitialization
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [entity setValue:ValueUsedToFailPredicate forKey:FieldUsedInPredicate];
    
    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:OCMOCK_ANY];
    
    // when
    [ZMChangeTrackerBootstrap bootStrapChangeTrackers:@[self.sut] onContext:self.testMOC];
    
    // then
    [self.mockLocallyModifiedSet verify];
}


- (void)testThatItGetsTheNextObjectToSynchronizeFromTheUpdateObjectsSet_canCreateRequestImplemented_YES
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    // expect
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:nil] anyObjectToSynchronize];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
}

- (void)testThatItGetsTheNextObjectToSynchronizeFromTheUpdateObjectsSet_canCreateRequestImplemented_NO
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(NO)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];
    
    // expect
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:nil] anyObjectToSynchronize];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
}

- (void)testThatItAsksTheTranscoderToCreateARequestForTheNextObjectToSynchronizeAndThatItReturnsThatRequest
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = [NSSet setWithObject:@"field"];
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [(ZMLocallyModifiedObjectSet *)[self.mockLocallyModifiedSet stub] didStartSynchronizingKeys:OCMOCK_ANY forObject:OCMOCK_ANY];

    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(request, fakeRequest.transportRequest);

}

- (void)testThatItCallsDidStartSynchronizingObjectWhenTheTranscoderReturnsANonNilRequest
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    NSSet *transcoderKeys = [NSSet setWithObject:@"field"];
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:transcoderKeys];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[self.mockLocallyModifiedSet expect] didStartSynchronizingKeys:transcoderKeys forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(request, fakeRequest.transportRequest);
}


- (void)testThatItCallsDidFinishSynchronizingObjectWithTokenWhenTheRequestIsCompleted
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[self.mockLocallyModifiedSet expect] didSynchronizeToken:token];
    [[(id)self.mockTranscoder stub] updateUpdatedObject:OCMOCK_ANY requestUserInfo:OCMOCK_ANY response:OCMOCK_ANY keysToParse:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:[NSSet set]] keysToParseAfterSyncingToken:OCMOCK_ANY];

    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:0]];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatItCallsDidFailToSynchronizingTokenWhenTheRequestFails
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:404 transportSessionError:nil apiVersion:APIVersionV0];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[(id)self.mockLocallyModifiedSet expect] keysToParseAfterSyncingToken:OCMOCK_ANY];
    [[self.mockLocallyModifiedSet expect] didFailToSynchronizeToken:token];
    [[[(id)self.mockTranscoder stub] andReturn:nil] objectToRefetchForFailedUpdateOfObject:entity];
    [[(id)self.mockTranscoder expect] shouldRetryToSyncAfterFailedToUpdateObject:OCMOCK_ANY request:fakeRequest response:response keysToParse:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItCallsDidNotFinishToSynchronizeTokenWhenTheRequestFailsWithATemporaryError
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[(id)self.mockLocallyModifiedSet expect] keysToParseAfterSyncingToken:OCMOCK_ANY];
    [[self.mockLocallyModifiedSet expect] didNotFinishToSynchronizeToken:token];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:@{} HTTPStatus:500 transportSessionError:nil apiVersion:0]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItForwardsKeysToParseAfterSyncingTokenToTranscoderAfterTheRequestIsCompleted
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    NSDictionary *responsePayload = @{@"bar": @"tralala"};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    NSSet *keysThatDidNotChange = [NSSet setWithObject:@"field"];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[self.mockLocallyModifiedSet stub] didSynchronizeToken:token];
    [[(id)self.mockTranscoder expect] updateUpdatedObject:entity requestUserInfo:fakeRequest.userInfo response:response keysToParse:keysThatDidNotChange];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:keysThatDidNotChange] keysToParseAfterSyncingToken:token];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);

}

- (void)testThatItCalls_DidSynchronizeToken_IfTheTranscoderReturns_NO_For_UpdateUpdatedObjects
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    NSDictionary *responsePayload = @{@"bar": @"tralala"};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    NSSet *keysThatDidNotChange = [NSSet setWithObject:@"field"];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[self.mockLocallyModifiedSet expect] didSynchronizeToken:token];
    [[[(id)self.mockTranscoder expect] andReturnValue:@NO] updateUpdatedObject:entity requestUserInfo:fakeRequest.userInfo response:response keysToParse:keysThatDidNotChange];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:keysThatDidNotChange] keysToParseAfterSyncingToken:token];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
    
}

- (void)testThatItCalls_DidSynchronizeToken_IfTheTranscoderReturns_YES_For_UpdateUpdatedObjects
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    NSDictionary *responsePayload = @{@"bar": @"tralala"};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    NSSet *keysThatDidNotChange = [NSSet setWithObject:@"field"];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[self.mockLocallyModifiedSet expect] didNotFinishToSynchronizeToken:token];
    [[[(id)self.mockTranscoder expect] andReturnValue:@YES] updateUpdatedObject:entity requestUserInfo:fakeRequest.userInfo response:response keysToParse:keysThatDidNotChange];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:keysThatDidNotChange] keysToParseAfterSyncingToken:token];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
    
}

- (void)testThatItCalls_UpdateUpdatedObjects_evenIfThereAreNoMoreKeysToSync
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:entity forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    NSDictionary *responsePayload = @{@"bar": @"tralala"};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    NSSet *keysThatDidNotChange = [NSSet set];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[self.mockLocallyModifiedSet expect] didSynchronizeToken:token];
    [[[(id)self.mockTranscoder expect] andReturnValue:@NO] updateUpdatedObject:entity requestUserInfo:fakeRequest.userInfo response:response keysToParse:keysThatDidNotChange];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:keysThatDidNotChange] keysToParseAfterSyncingToken:token];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
    
}

- (void)testThatItDoesNotAddAObjectToUpdatedObjectsWhenTheObjectToSyncHasDependencies
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = @"foo";
    
    // expect
    [[self.mockLocallyModifiedSet reject] addPossibleObjectToSynchronize:entity];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItReAddsAnObjectThatWasPreviouslyNotAddedBecauseOfADependencyWhenThereIsNoDependencyAnymore
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *entity2 = [MockEntity2 insertNewObjectInManagedObjectContext:self.testMOC];
    self.objectIDToObjectDependency[entity.objectID] = entity2;
    
    // expect
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:entity];

    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    [self.objectIDToObjectDependency removeObjectForKey:entity.objectID];
    [self.sut objectsDidChange:[NSSet setWithObject:entity2]];
}


- (void)testThatItReAddsAnObjectThatWasPreviouslyNotAddedBecauseOfADependencyWhenTheDependencyChangesToSomethingElseAndThenThatSomethingElseIsNotADependencyAnymore
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency1 = [MockEntity2 insertNewObjectInManagedObjectContext:self.testMOC];
    MockEntity2 *dependency2 = [MockEntity2 insertNewObjectInManagedObjectContext:self.testMOC];
    self.objectIDToObjectDependency[entity.objectID] = dependency1;
    
    __block BOOL addObjectWasCalled = NO;
    
    // expect
    [[self.mockLocallyModifiedSet expect] addPossibleObjectToSynchronize:[OCMArg checkWithBlock:^BOOL(id obj) {
        addObjectWasCalled = YES;
        return obj == entity;
    }]];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    XCTAssertFalse(addObjectWasCalled);
    self.objectIDToObjectDependency[entity.objectID] = dependency2;
    [self.sut objectsDidChange:[NSSet setWithObject:dependency1]];
    XCTAssertFalse(addObjectWasCalled);
    [self.objectIDToObjectDependency removeObjectForKey:entity.objectID];
    [self.sut objectsDidChange:[NSSet setWithObject:dependency2]];
    XCTAssertTrue(addObjectWasCalled);
}

- (void)testThatItAsksTheTranscoderForObjectsToRefetchOnAFailedRequest
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *entity2 = [MockEntity2 insertNewObjectInManagedObjectContext:self.testMOC];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:404 transportSessionError:nil apiVersion:0];
    [request completeWithResponse:response];
    
    [[(id)self.mockLocallyModifiedSet expect] keysToParseAfterSyncingToken:OCMOCK_ANY];
    [[(id)self.mockTranscoder expect] shouldRetryToSyncAfterFailedToUpdateObject:OCMOCK_ANY request:fakeRequest response:response keysToParse:OCMOCK_ANY];
    [[self.mockLocallyModifiedSet expect] didFailToSynchronizeToken:token];
    [[[(id)self.mockTranscoder expect] andReturn:entity2] objectToRefetchForFailedUpdateOfObject:entity];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(entity2.needsToBeUpdatedFromBackend);
}

- (void)testThatWhenTheRequestExpiresItNotifiesTheTranscoder
{
    // given
    [[[(id)self.mockTranscoder stub] andReturnValue:OCMOCK_VALUE(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];

    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *keysToSync = entity.keysTrackedForLocalModifications;
    id token = @"foo";
    
    ZMObjectWithKeys *fakeObjectWithKeys = [self fakeObject:entity withKeys:keysToSync];
    ZMUpstreamRequest *fakeRequest = [self dummyRequestWithKeys:keysToSync];
    
    // expect
    [[self.mockLocallyModifiedSet stub] addPossibleObjectToSynchronize:OCMOCK_ANY];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:fakeObjectWithKeys] anyObjectToSynchronize];
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet expect] andReturn:token] didStartSynchronizingKeys:keysToSync forObject:fakeObjectWithKeys];
    [[[(id)self.mockTranscoder expect] andReturn:fakeRequest] requestForUpdatingObject:entity forKeys:keysToSync apiVersion:APIVersionV0];
    [[(id)self.mockLocallyModifiedSet expect] keysToParseAfterSyncingToken:OCMOCK_ANY];
    [[self.mockLocallyModifiedSet expect] didFailToSynchronizeToken:token];
    [[(id)self.mockTranscoder expect] requestExpiredForObject:entity forKeys:keysToSync];
    [[(id)self.mockTranscoder stub] objectToRefetchForFailedUpdateOfObject:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:[NSError requestExpiredError] apiVersion:0]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItHasNoOutstandingItemsWhenTheModifiedSetHasNone;
{
    // given
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet stub] andReturnValue:@(NO)] hasOutstandingItems];
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems);
}

- (void)testThatItHasOutstandingItemsWhenTheModifiedSetHasSome;
{
    // given
    [(ZMLocallyModifiedObjectSet *)[[self.mockLocallyModifiedSet stub] andReturnValue:@(YES)] hasOutstandingItems];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems);
}

@end
