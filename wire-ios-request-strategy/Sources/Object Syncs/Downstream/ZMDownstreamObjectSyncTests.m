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

#import "MockEntity.h"
#import "MockModelObjectContextFactory.h"
#import "ZMChangeTrackerBootstrap+Testing.h"



@interface ZMDownstreamObjectTranscoderTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) id<ZMDownstreamTranscoder> transcoder;
@property (nonatomic) ZMDownstreamObjectSync *sut;
@property (nonatomic) ZMSyncOperationSet *operationSet;
@property (nonatomic) NSPredicate *predicateForObjectsToDownload;

@end



@implementation ZMDownstreamObjectTranscoderTests

- (void)setUp {
    [super setUp];
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMDownstreamTranscoder)];
    self.operationSet = [OCMockObject mockForClass:ZMSyncOperationSet.class];
    
    [(ZMSyncOperationSet *)[(id) self.operationSet stub] setSortDescriptors:OCMOCK_ANY];
    
    [self verifyMockLater:self.operationSet];
    [self verifyMockLater:self.transcoder];
    
    [self createSystemUnderTest];
}

- (void)tearDown
{
    self.transcoder = nil;
    self.sut = nil;
    self.operationSet = nil;
    self.predicateForObjectsToDownload = nil;
    [super tearDown];
}

- (void)createSystemUnderTest;
{
    self.predicateForObjectsToDownload = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"];
    self.sut = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self.transcoder operationSet:self.operationSet entityName:@"MockEntity" predicateForObjectsToDownload:self.predicateForObjectsToDownload filter:nil managedObjectContext:self.testMOC];
}

- (void)makeSureFetchObjectsToDownloadHasBeenCalled;
{
    [[[(id)self.operationSet expect] andReturn:nil] nextObjectToSynchronize];
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0], @"Make sure -fetchObjectsToDownload has been called.");
}

-(ZMTransportRequest *)dummyRequest
{
    return [ZMTransportRequest requestGetFromPath:[@"dummy-from-test-" stringByAppendingString:self.name] apiVersion:APIVersionV0];
}

- (void)testThatItSetsTheCorrectDefaultPredicate;
{
    // when
    ZMDownstreamObjectSync *sync = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self.transcoder entityName:@"MockEntity" managedObjectContext:self.testMOC];
    
    // then
    XCTAssertEqualObjects(sync.predicateForObjectsToDownload.predicateFormat, @"needsToBeUpdatedFromBackend == 1");
}

- (void)testThatItAddsAnUpdatedObjectToTheObjectsToBeSynchronized
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[(id)self.operationSet expect] addObjectToBeSynchronized:entity];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItDoesNotAddAnUpdatedObjectThatDoesNotNeedToBeUpdatedFromBackend
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = NO;
    
    // expect
    [[(id)self.operationSet reject] addObjectToBeSynchronized:OCMOCK_ANY];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItAddsAnInsertedObjectToTheObjectsToBeSynchronized
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[(id)self.operationSet expect] addObjectToBeSynchronized:entity];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItDoesNotAddAnInsertedObjectThatDoesNotNeedToBeUpdatedFromBackend
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = NO;
    
    // expect
    [[(id)self.operationSet reject] addObjectToBeSynchronized:OCMOCK_ANY];
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItRejectsObjectsThatDoNotPassFilter
{
    // given
    NSString *expectedField2 = @"The Correct Entity";
    NSPredicate *predicateForObjectsToDownload = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"];
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(MockEntity *entity, ZM_UNUSED id bindings) {
        return [entity.field2 isEqual:expectedField2];
    }];
    
    ZMDownstreamObjectSync *sut = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self.transcoder operationSet:self.operationSet entityName:@"MockEntity" predicateForObjectsToDownload:predicateForObjectsToDownload filter:filter managedObjectContext:self.testMOC];
    
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    entity.field2 = @"some other content";
    
    // expect
    [[(id)self.operationSet reject] addObjectToBeSynchronized:entity];
    
    // when
    [sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatItAddsObjectsThatPassFilter
{
    // given
    NSString *expectedField2 = @"The Correct Entity";
    self.predicateForObjectsToDownload = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"];
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(MockEntity *entity, ZM_UNUSED id bindings) {
        return [entity.field2 isEqual:expectedField2];
    }];
    
    ZMDownstreamObjectSync *sut = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self.transcoder operationSet:self.operationSet entityName:@"MockEntity" predicateForObjectsToDownload:self.predicateForObjectsToDownload filter:filter managedObjectContext:self.testMOC];
    
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    entity.field2 = expectedField2;
    
    // expect
    [[(id)self.operationSet expect] addObjectToBeSynchronized:entity];
    
    // when
    [sut objectsDidChange:[NSSet setWithObject:entity]];
}

- (void)testThatOnNextRequestsItCreatesARequestFromTheObjectInTheSet
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[[(id)self.transcoder expect] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet expect] andReturn:entity] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] didStartSynchronizingKeys:nil forObject:entity];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(self.dummyRequest, request);
}

- (void)testThatItDoesNotCallDidStartSynchronizingKeysIfTheGeneratedRequestIsNil
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[[(id)self.transcoder expect] andReturn:nil] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet expect] andReturn:entity] nextObjectToSynchronize];
    [[[(id)self.operationSet expect] andReturn:nil] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet reject] didStartSynchronizingKeys:OCMOCK_ANY forObject:OCMOCK_ANY];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] removeObject:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
}

- (void)testThatItTriesToGenerateARequestsForObjectsInTheSetUntilOneGeneratesARequestThatIsNotNil
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity1.needsToBeUpdatedFromBackend = YES;
    MockEntity *entity2 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity2.needsToBeUpdatedFromBackend = YES;
    ZMTransportRequest *expectedRequest = [ZMTransportRequest requestGetFromPath:@"lol" apiVersion: 0];
    
    // expect
    [[[(id)self.operationSet expect] andReturn:entity1] nextObjectToSynchronize];
    [[[(id)self.operationSet expect] andReturn:entity2] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] didStartSynchronizingKeys:OCMOCK_ANY forObject:OCMOCK_ANY];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] removeObject:OCMOCK_ANY];
    
    [[[(id)self.transcoder expect] andReturn:nil] requestForFetchingObject:entity1 downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.transcoder expect] andReturn:expectedRequest] requestForFetchingObject:entity2 downstreamSync:self.sut apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqual(request,expectedRequest);
}


- (void)testThatItRemovesAnObjectThatWasEncodedAsANilRequest
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity1.needsToBeUpdatedFromBackend = YES;
    
    // expect
    [[[(id)self.operationSet expect] andReturn:entity1] nextObjectToSynchronize];
    [[[(id)self.operationSet expect] andReturn:nil] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] didStartSynchronizingKeys:OCMOCK_ANY forObject:OCMOCK_ANY];
    [[[(id)self.transcoder expect] andReturn:nil] requestForFetchingObject:entity1 downstreamSync:self.sut apiVersion:APIVersionV0];
    
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] removeObject:entity1];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    NOT_USED(request);
}

- (void)testThatItRemovesAnObjectThatDoesNotMatchThePredicateInsteadOfGeneratingARequest
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity1.needsToBeUpdatedFromBackend = NO;
    
    // expect
    [[[(id)self.operationSet expect] andReturn:entity1] nextObjectToSynchronize];
    [[[(id)self.operationSet expect] andReturn:nil] nextObjectToSynchronize];
    [[(id)self.transcoder reject]requestForFetchingObject:entity1 downstreamSync:self.sut apiVersion:APIVersionV0];
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] removeObject:entity1];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    NOT_USED(request);
}

- (void)testThatItCalls_FinishedSynchronizing_And_UpdateObject_WhenTheRequestIsSuccessful
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    NSDictionary *payload = @{@"3":@4};
    id keys = @435;
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion: 0];
    
    // expect
    [[[(id)self.transcoder expect] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet expect] andReturn:entity] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] didStartSynchronizingKeys:nil forObject:entity];
    [[[(id)self.operationSet expect] andReturn:keys]keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:entity result:ZMTransportResponseStatusSuccess];
    [[(id)self.operationSet expect] removeUpdatedObject:entity syncToken:OCMOCK_ANY synchronizedKeys:keys];
    [[(id)self.transcoder expect] updateObject:entity withResponse:response downstreamSync:self.sut];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // when
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.dummyRequest, request);
}

- (void)testThatItCalls_FinishedSynchronizing_And_DeleteObject_WhenTheRequestIsFailed
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    NSDictionary *payload = @{@"3":@4};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:404 transportSessionError:nil apiVersion: 0];
    
    // expect
    [[[(id)self.transcoder expect] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet expect] andReturn:entity] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] didStartSynchronizingKeys:nil forObject:entity];
    [[(id)self.operationSet expect] keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:entity result:ZMTransportResponseStatusPermanentError];
    [(id<ZMDownstreamTranscoder>)[(id)self.transcoder expect] deleteObject:entity withResponse:response downstreamSync:self.sut];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] removeObject:entity];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.dummyRequest, request);
}

- (void)testThatItDoesNotKeepRequestingTheObjectWhenTheRequestIsFailed
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    NSDictionary *payload = @{@"3":@4};

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:404 transportSessionError:nil apiVersion: 0];
    
    [[[(id)self.transcoder stub] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet stub] andReturn:entity] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] didStartSynchronizingKeys:nil forObject:entity];
    [[(id)self.operationSet stub] keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:entity result:ZMTransportResponseStatusPermanentError];
    [(id<ZMDownstreamTranscoder>)[(id)self.transcoder stub] deleteObject:entity withResponse:response downstreamSync:self.sut];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // expect
    [(ZMSyncOperationSet *)[(id)self.operationSet expect] removeObject:entity];
    
    // when
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItPutAnObjectBackIntoTheQueueUponReceivingA_TryAgain_Response;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    
    [[[(id)self.transcoder stub] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet stub] andReturn:entity] nextObjectToSynchronize];
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] didStartSynchronizingKeys:nil forObject:entity];
    [[(id)self.operationSet stub] keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:entity result:ZMTransportResponseStatusPermanentError];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // reject
    [(ZMSyncOperationSet *) [(id)self.operationSet expect] keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:OCMOCK_ANY result:ZMTransportResponseStatusTryAgainLater];
    [(ZMSyncOperationSet *) [(id)self.operationSet reject] removeObject:OCMOCK_ANY];
    [(ZMSyncOperationSet *) [(id)self.operationSet reject] removeUpdatedObject:OCMOCK_ANY syncToken:OCMOCK_ANY synchronizedKeys:OCMOCK_ANY];
    [[(id)self.transcoder reject] deleteObject:OCMOCK_ANY withResponse:OCMOCK_ANY downstreamSync:OCMOCK_ANY];
    
    // when
    NSError *transportError = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    [request completeWithResponse:[ZMTransportResponse responseWithTransportSessionError:transportError apiVersion: 0]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatOnCreationItPicksUpObjectsAlreadyPersistenToTheDatabase;
{
    // given
    self.sut = nil;
    WaitForAllGroupsToBeEmpty(0.5);
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    XCTAssert([self.testMOC saveOrRollback]);
    
    // expect
    [[(id)self.operationSet expect] addObjectToBeSynchronized:[OCMArg checkWithBlock:^BOOL(ZMManagedObject *mo) {
        return [mo.objectID isEqual:entity.objectID];
    }]];
    
    // when
    [self createSystemUnderTest];
    [[[(id)self.operationSet expect] andReturn:nil] nextObjectToSynchronize];
    [ZMChangeTrackerBootstrap bootStrapChangeTrackers:@[self.sut] onContext:self.testMOC];
    (void) [self.sut nextRequestForAPIVersion:APIVersionV0];
}

- (void)testThatItDoesNotUpdateZombieObjectsAfterAnUpdateRequest
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    NSDictionary *payload = @{@"3":@4};
    id keys = @435;
    
    // expect
    [[[(id)self.transcoder expect] andReturn:self.dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    [[[(id)self.operationSet expect] andReturn:entity] nextObjectToSynchronize];
    
    [(ZMSyncOperationSet *)[(id)self.operationSet stub] didStartSynchronizingKeys:nil forObject:entity];
    [[[(id)self.operationSet stub] andReturn:keys]keysForWhichToApplyResultsAfterFinishedSynchronizingSyncWithToken:OCMOCK_ANY forObject:entity result:ZMTransportResponseStatusSuccess];
    [[(id)self.operationSet stub] removeUpdatedObject:entity syncToken:OCMOCK_ANY synchronizedKeys:OCMOCK_ANY];
    
    [[(id)self.transcoder reject] updateObject:OCMOCK_ANY withResponse:OCMOCK_ANY downstreamSync:self.sut];
    
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // when
    [self.testMOC deleteObject:entity];
    [self.testMOC saveOrRollback];
    
    [request completeWithResponse:[ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion: 0]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.dummyRequest, request);
    
}

- (void)testThatItSetsTheSortDescriptorsOnTheOperationSet;
{
    // given
    self.transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMDownstreamTranscoder)];
    self.operationSet = [OCMockObject niceMockForClass:ZMSyncOperationSet.class];
    
    // expect
    NSArray *sortDescriptors = [MockEntity sortDescriptorsForUpdating];
    [(ZMSyncOperationSet *)[(id) self.operationSet expect] setSortDescriptors:sortDescriptors];
    
    // when
    [self createSystemUnderTest];

    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.needsToBeUpdatedFromBackend = YES;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // finally
    [(id) self.operationSet verify];
}

@end



@implementation ZMDownstreamObjectTranscoderTests (OutstandingItems)

- (void)testThatItHasNoOutstandingItemsWhenTheObjectsToDownloadIsEmpty;
{
    // given
    [self createSystemUnderTest];
    (void)[(ZMSyncOperationSet *) [[(id)self.operationSet stub] andReturnValue:OCMOCK_VALUE((NSUInteger) 0)] count];
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems);
}

- (void)testThatItHasOutstandingItemsWhenTheObjectsToDownloadIsEmpty;
{
    // given
    [self createSystemUnderTest];
    (void)[(ZMSyncOperationSet *) [[(id)self.operationSet stub] andReturnValue:OCMOCK_VALUE((NSUInteger) 1)] count];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems);
}

@end



@implementation ZMDownstreamObjectTranscoderTests (ZMContextChangeTracker)

- (void)testThatItReturnsTheCorrectFetchRequest
{
    // when
    NSFetchRequest *request = [self.sut fetchRequestForTrackedObjects];
    
    // then
    NSFetchRequest *expectedRequest = [NSFetchRequest fetchRequestWithEntityName:@"MockEntity"];
    expectedRequest.predicate = self.predicateForObjectsToDownload;
    XCTAssertEqualObjects(request, expectedRequest);
}


- (void)testThatItAddsObjectsThatNeedProcessing
{
    // given
    MockEntity *mockObject = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    NSSet *objects = [NSSet setWithArray:@[mockObject]];

    // expect
    [[(id)self.operationSet expect] addObjectToBeSynchronized:mockObject];
    
    // when
    [self.sut addTrackedObjects:objects];
}

@end


