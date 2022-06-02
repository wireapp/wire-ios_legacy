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

#import "ZMUpstreamModifiedObjectSync.h"
#import "MockEntity.h"
#import "MockEntity2.h"
#import "MockModelObjectContextFactory.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMChangeTrackerBootstrap+Testing.h"
#import "NSManagedObjectContext+TestHelpers.h"

@interface ZMUpstreamInsertedObjectSyncTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) id<ZMUpstreamTranscoder> mockTranscoder;
@property (nonatomic) ZMUpstreamInsertedObjectSync *sut;
@property (nonatomic) NSMutableDictionary *objectIDToObjectDependency;

-(ZMUpstreamRequest *)dummyRequestWithKeys:(NSSet *)keys;

@end

static NSString *foo = @"foo";


@interface MockTranscoderWithoutFailedToUpdateInsertedObject : NSObject <ZMUpstreamTranscoder>
@end



@implementation MockTranscoderWithoutFailedToUpdateInsertedObject

- (void)updateInsertedObject:(ZMManagedObject * __unused)managedObject request:(ZMUpstreamRequest * __unused)upstreamRequest response:(ZMTransportResponse * __unused)response
{
}

- (BOOL)updateUpdatedObject:(ZMManagedObject *__unused)managedObject requestUserInfo:(NSDictionary *__unused)requestUserInfo response:(ZMTransportResponse *__unused)response keysToParse:(NSSet * __unused)keysToParse
{
    return YES;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMManagedObject * __unused)managedObject forKeys:(NSSet * __unused)keys apiVersion:(APIVersion)apiVersion
{
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:[ZMTransportRequest requestGetFromPath:@"Fpp" apiVersion:0]];
}

- (ZMUpstreamRequest *)requestForInsertingObject:(ZMManagedObject * __unused)managedObject forKeys:(NSSet * __unused)keys apiVersion:(APIVersion)apiVersion
{
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:[ZMTransportRequest requestGetFromPath:@"Fpp" apiVersion:0]];
}

- (BOOL)shouldProcessUpdatesBeforeInserts
{
    return NO;
}

- (ZMManagedObject *)objectToRefetchForFailedUpdateOfObject:(ZMManagedObject * __unused)managedObject
{
    return nil;
}

@end




@implementation ZMUpstreamInsertedObjectSyncTests

- (void)setUp
{
    [super setUp];
    self.testMOC = [MockModelObjectContextFactory testContext];
    self.mockTranscoder = [OCMockObject mockForProtocol:@protocol(ZMUpstreamTranscoder)];
    [self createSystemUnderTest];
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]); // Make sure we've -fetchObjectsFromStore did run
    self.testMOC.userInfo[@"ZMIsUserInterfaceContext"] = @YES;   
    
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder stub] andReturnValue:@(YES)] shouldCreateRequestToSyncObject:OCMOCK_ANY forKeys:OCMOCK_ANY withSync:OCMOCK_ANY];
}

- (NSObject *)transcoderDependentObjectForUpdate:(NSManagedObject *)obj
{
    return self.objectIDToObjectDependency[obj.objectID];
}

- (void)createSystemUnderTest;
{
    self.objectIDToObjectDependency = [NSMutableDictionary dictionary];

    [[[(id) self.mockTranscoder stub] andCall:@selector(transcoderDependentObjectForUpdate:) onObject:self] dependentObjectNeedingUpdateBeforeProcessingObject:OCMOCK_ANY];

    self.sut = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                             entityName:MockEntity.entityName
                                                   managedObjectContext:self.testMOC];
    [self verifyMockLater:self.mockTranscoder];    
}

- (void)tearDown
{
    self.sut = nil;
    self.mockTranscoder = nil;
    self.testMOC.userInfo[@"ZMIsUserInterfaceContext"] = @NO;
    self.objectIDToObjectDependency = nil;
    [super tearDown];
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
        entity.field2 = @"bar";
        entity.field3 = @"foo";
        XCTAssertTrue([self.testMOC saveOrRollback]);
    }];
    return entity;
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
    return [ZMTransportRequest requestGetFromPath:[@"dummy-from-test-" stringByAppendingString:self.name] apiVersion:0];
}

-(ZMUpstreamRequest *)dummyRequestWithKeys:(NSSet *)keys
{
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:[@"dummy-from-test-" stringByAppendingString:self.name] apiVersion:0];
    return [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:transportRequest];
}

- (void)testThatItAsksForARequestWhenInsertingAnObject
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expectation
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects([self dummyRequestWithKeys:nil].transportRequest, request);
}

- (void)testThatItReturnsANilRequestIfTheInsertedObjectNoLongerMatchesTheInsertPredicate;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    entity.remoteIdentifier = NSUUID.createUUID; // it will no longer match predicateForObjectsThatNeedToBeInsertedUpstream
    XCTAssertFalse([[MockEntity predicateForObjectsThatNeedToBeInsertedUpstream] evaluateWithObject:entity]);
    
    // reject
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
}

- (void)testThatItReturnsANilRequestAndResetsTheObjectWhenTheTranscoderReturnsANilRequestForInsertion
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expectation
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:nil] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
    ZMTransportRequest *followingRequest = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertNil(followingRequest);
    XCTAssertEqual(entity.keysThatHaveLocalModifications.count, 0u);
}

- (void)testThatItDoesNotAskForARequestWhenInsertingAnObjectThatDoesNotNeedToBeSentUpstream
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    entity.remoteIdentifier = [NSUUID createUUID];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expectation
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
}

- (void)testThatItAsksForARequestWhenAnInsertedObjectIsAlreadyInTheDatabase
{
    // given
    self.sut = nil;
    MockEntity *entity = [self mockEntityWithModifiedValue];
    XCTAssert([self.testMOC saveOrRollback]);
    [self createSystemUnderTest];
    [ZMChangeTrackerBootstrap bootStrapChangeTrackers:@[self.sut] onContext:self.testMOC];
    
    // expectation
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(self.dummyTransportRequest, request);
}

- (void)testThatItDoesNotGenerateARequestForTheSameInsertedObjectIfARequestIsStillRunning
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expectation
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    XCTAssertNotNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatItAsksForSeveralRequestsWhenInsertingSeveralObjects
{
    // given
    MockEntity *entity1 = [self mockEntityWithModifiedValue];
    MockEntity *entity2 = [self mockEntityWithModifiedValue];
    MockEntity *entity3 = [self mockEntityWithModifiedValue];
    
    [self.sut objectsDidChange:[NSSet setWithObjects:entity1, entity2, entity3, nil]];
    
    // expectation
    [(OCMockObject *)self.mockTranscoder setExpectationOrderMatters:NO];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity1.keysThatHaveLocalModifications]] requestForInsertingObject:entity1 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity2.keysThatHaveLocalModifications]] requestForInsertingObject:entity2 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity3.keysThatHaveLocalModifications]] requestForInsertingObject:entity3 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    [(id)self.mockTranscoder verify];
}

- (void)testThatWhenInsertedObjectsAreAddedTheOldObjectsAreKept
{
    // given
    MockEntity *entity1 = [self mockEntityWithModifiedValue];
    MockEntity *entity2 = [self mockEntityWithModifiedValue];
    MockEntity *entity3 = [self mockEntityWithModifiedValue];
    
    // insert at different times
    [self.sut objectsDidChange:[NSSet setWithObject:entity1]];
    [self.sut objectsDidChange:[NSSet setWithObject:entity2]];
    [self.sut objectsDidChange:[NSSet setWithObject:entity3]];
    
    
    
    // expectation
    [(OCMockObject *)self.mockTranscoder setExpectationOrderMatters:NO];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity1.keysThatHaveLocalModifications]] requestForInsertingObject:entity1 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity2.keysThatHaveLocalModifications]] requestForInsertingObject:entity2 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity3.keysThatHaveLocalModifications]] requestForInsertingObject:entity3 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    [(id)self.mockTranscoder verify];
}

- (void)testThatItDoesNotAskForAnyRequestIfNoObjectIsPendingSynchronization
{
    // given
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForUpdatingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
}

- (void)testThatItDoesNotGeneratesRequestsForObjectsOfTheWrongType
{
    // given
    MockEntity2 *entity = [self mockEntity2WithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForUpdatingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatInsertingObjectsWithNoModifiedKeysGeneratesARequest
{
    // given
    MockEntity *entity1 = [MockEntity insertNewObjectInManagedObjectContext:self.testMOC];
    
    
    [self.sut objectsDidChange:[NSSet setWithObject:entity1]];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity1.keysThatHaveLocalModifications]] requestForInsertingObject:entity1 forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when / then
    XCTAssertEqualObjects(self.dummyTransportRequest, [self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatItDoesNotSetsTheRelatedObjectAsNeedingToBeUpdatedWhenTheResponseHasExpired
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSError *networkError = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportResponseStatusExpired userInfo:nil];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:networkError apiVersion:0];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder reject] objectToRefetchForFailedUpdateOfObject:entity];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
}

- (void)testThatItLetsTheTranscoderHandleTheResponsePayloadWhenInsertingAnObject
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"foo": @"bar",
                                      @"baz": @[@"quux"]
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *expectedRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:expectedRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder expect] updateInsertedObject:entity request:expectedRequest response:response];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    [(id)self.mockTranscoder verify];
}

- (void)testThatItSetsTheTransportResponseOnTheUpstreamRequestForInserts
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{@"foo": @"bar",
                                      @"baz": @[@"quux"]};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *expectedRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:expectedRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andDo:^(NSInvocation * ZM_UNUSED inv) {
        XCTAssertEqual(expectedRequest.transportResponse, response);
    }] updateInsertedObject:entity request:expectedRequest response:response];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    [(id)self.mockTranscoder verify];
}

- (void)testThatItCallsTheTimeoutCallbackWhenARequestTimesOut
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSError *timeoutError = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:timeoutError apiVersion:0];
    
    // expect
    ZMUpstreamRequest *upstreamRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:upstreamRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder expect] requestExpiredForObject:entity forKeys:upstreamRequest.keys];
    [[(id)self.mockTranscoder reject] updateInsertedObject:OCMOCK_ANY request:OCMOCK_ANY response:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    [(id)self.mockTranscoder verify];
}

- (void)testThatItDoesNotLetTheTranscoderHandleTheResponsePayloadIfInsertingAnObjectFailed
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:500 transportSessionError:nil apiVersion:0];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder reject] updateInsertedObject:OCMOCK_ANY request:OCMOCK_ANY response:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    [(id)self.mockTranscoder verify];
}

- (void)testThatItDeletesAnObjectIfInsertionFailsAndTheTranscoderDoesNotImplement_failedToUpdateInsertedObject
{
    // given
    self.mockTranscoder = [[MockTranscoderWithoutFailedToUpdateInsertedObject alloc] init];
    self.sut = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self.mockTranscoder
                                                  entityName:MockEntity.entityName
                                        managedObjectContext:self.testMOC];
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:400 transportSessionError:nil apiVersion:0];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(0u, mockEntities.count);
}

- (void)testThatItDoesNotDeleteAnObjectIfInsertionFailsAndTheTranscoderImplements_failedToUpdateInsertedObject_returningYes
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:400 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *dummyRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:dummyRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturnValue:@(YES)] shouldRetryToSyncAfterFailedToUpdateObject:entity request:dummyRequest response:response keysToParse:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(1u, mockEntities.count);
}

- (void)testThatItDeletesAnObjectIfInsertionFailsAndTheTranscoderImplements_failedToUpdateInsertedObject_returningNo
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:400 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *dummyRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:dummyRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturnValue:@NO] shouldRetryToSyncAfterFailedToUpdateObject:entity request:dummyRequest response:response keysToParse:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(0u, mockEntities.count);
}

- (void)testThatItInsertsTheObjectIntoTheObjectsToSynchronizeIf_failedToUpdateInsertedObject_returnsYes
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:400 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *dummyRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:dummyRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturnValue:@YES] shouldRetryToSyncAfterFailedToUpdateObject:entity request:dummyRequest response:response keysToParse:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // and expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:dummyRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
 
    // when
    request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request, dummyRequest.transportRequest);
}

- (void)testThatItDoesNotInsertsTheObjectIntoTheObjectsToSynchronizeIf_failedToUpdateInsertedObject_returnsNo
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{
                                      @"error": @"An expected error occured",
                                      };
    
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:400 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *dummyRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:dummyRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturnValue:@NO] shouldRetryToSyncAfterFailedToUpdateObject:entity request:dummyRequest response:response keysToParse:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // and expect
    [(id<ZMUpstreamTranscoder>)[(id)self.mockTranscoder reject] requestForInsertingObject:OCMOCK_ANY forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
}

- (void)testThatItRemovesAnObjectIfInsertedAndThePredicateDoesNotMatch
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    XCTAssertTrue(self.sut.hasCurrentlyRunningRequests);
    
    entity.remoteIdentifier = NSUUID.createUUID; // it will no longer match predicateForObjectsThatNeedToBeInsertedUpstream
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // then
    XCTAssertFalse(self.sut.hasCurrentlyRunningRequests);
}

- (void)testThatItRemovesAnObjectIfInsertedAndDeleted
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    XCTAssertTrue(self.sut.hasCurrentlyRunningRequests);
    
    [self.testMOC deleteObject:entity];
    [self.testMOC saveOrRollback];
    
    // when
    [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertFalse(self.sut.hasCurrentlyRunningRequests);
}

- (void)testThatItIgnoresResponsesForRemovedObjectsAndDoesNotDeleteTheObject
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{@"foo": @"bar",
                                      @"baz": @[@"quux"]};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *expectedRequest = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:expectedRequest] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder reject] updateInsertedObject:entity request:expectedRequest response:response];
    
    // when
    // (1) start the request
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // (2) change the object so it will no longer match predicateForObjectsThatNeedToBeInsertedUpstream
    entity.remoteIdentifier = NSUUID.createUUID;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // (3) complete previous request with response
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(1u, mockEntities.count);
    
    [(id)self.mockTranscoder verify];
}

- (void)testThatItCanResyncIgnoredObjectIfTheObjectChangesToNotBeIgnoredAgain
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{@"foo": @"bar",
                                      @"baz": @[@"quux"]};
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:0];
    
    // expect
    ZMUpstreamRequest *expectedRequest1 = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    ZMUpstreamRequest *expectedRequest2 = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];

    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:expectedRequest1] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    // (1) start the request
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // (2) change the object so it will no longer match predicateForObjectsThatNeedToBeInsertedUpstream
    entity.remoteIdentifier = NSUUID.createUUID;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // (3) complete previous request with response
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    XCTAssertEqualObjects(request, expectedRequest1.transportRequest);
    
    // and expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:expectedRequest2] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder expect] updateInsertedObject:entity request:expectedRequest2 response:response];
    
    
    // (4) change the object so that it matches again
    entity.remoteIdentifier = nil;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // (5) generate the request
    request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // (6) complete it
    [request completeWithResponse:response];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    XCTAssertEqualObjects(request, expectedRequest2.transportRequest);
    [(id)self.mockTranscoder verify];
}

@end



@implementation ZMUpstreamInsertedObjectSyncTests (TryAgainLater)

- (void)testThatItRequestsAnObjectAgainIfItFailedWith_TryAgainLater;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    ZMTransportResponse *tryAgainResponse = [ZMTransportResponse responseWithTransportSessionError:error apiVersion:0];
    
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder reject] objectToRefetchForFailedUpdateOfObject:entity];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertNotNil(request);
    [request completeWithResponse:tryAgainResponse];
    WaitForAllGroupsToBeEmpty(0.5);
    request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertNotNil(request);
}

- (void)testThatItDoesNotSetsTheRelatedObjectAsNeedingToBeUpdatedWhenTheResponseIs_TryAgainLater
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    ZMTransportResponse *tryAgainResponse = [ZMTransportResponse responseWithTransportSessionError:error apiVersion:0];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder reject] objectToRefetchForFailedUpdateOfObject:entity];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:tryAgainResponse];
    WaitForAllGroupsToBeEmpty(0.2);
}

- (void)testThatItDoesNotDeleteAnObjectIfInsertionFailsWith_TryAgainLater
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSDictionary *responsePayload = @{@"error": @"An expected error occured"};
    
    NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    ZMTransportResponse *tryAgainResponse = [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:error apiVersion:0];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:tryAgainResponse];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(1u, mockEntities.count);
}


- (void)testThatItCallsTranscoderIfRequestExpired
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil];
    ZMTransportResponse *tryAgainResponse = [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:error apiVersion:0];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    [[(id)self.mockTranscoder expect] requestExpiredForObject:entity forKeys:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    [request completeWithResponse:tryAgainResponse];
    WaitForAllGroupsToBeEmpty(0.2);
    
    // then
    NSFetchRequest *convFetchRequest = [MockEntity sortedFetchRequest];
    NSArray *mockEntities = [self.testMOC executeFetchRequestOrAssert:convFetchRequest];
    XCTAssertEqual(1u, mockEntities.count);
}


@end



@implementation ZMUpstreamInsertedObjectSyncTests (ZMUpstreamRequest)

- (void)testThatUpstreamRequestsSetTheirProperties;
{
    // given
    NSMutableSet *keys = [NSMutableSet setWithArray:@[@"name", @"color"]];
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:@"/some/path" apiVersion:0];
    NSMutableDictionary *userInfo = [@{ @"foo": @"bar" } mutableCopy];
    
    // when
    ZMUpstreamRequest *sut = [[ZMUpstreamRequest alloc] initWithKeys:keys transportRequest:transportRequest userInfo:userInfo];
    NSSet *originalKeys = [keys copy];
    NSDictionary *originalUserInfo = [userInfo copy];
    [keys addObjectsFromArray:@[@"title"]];
    userInfo[@"baz"] = @"quux";
    
    // then
    XCTAssertEqualObjects(sut.keys, originalKeys);
    XCTAssertEqualObjects(sut.userInfo, originalUserInfo);
    XCTAssertEqual(sut.transportRequest, transportRequest);
}

- (void)testThatUpstreamRequestSetIsNeverNil
{
    // given
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:@"/some/path" apiVersion:0];
    
    // when
    ZMUpstreamRequest *sut = [[ZMUpstreamRequest alloc] initWithKeys:nil transportRequest:transportRequest userInfo:nil];
    
    // then
    XCTAssertEqualObjects(sut.keys, [NSSet set]);
}


- (void)testThatUserInfoIsNeverNil
{
    // given
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:@"/some/path" apiVersion:0];
    
    // when
    ZMUpstreamRequest *sut = [[ZMUpstreamRequest alloc] initWithKeys:nil transportRequest:transportRequest userInfo:nil];
    
    // then
    XCTAssertEqualObjects(sut.userInfo, [NSDictionary dictionary]);
}


- (void)testThatUpstreamRequestConvenienceInitialiserWorks
{
    // given
    ZMTransportRequest *transportRequest = [ZMTransportRequest requestGetFromPath:@"/some/path" apiVersion:0];
    
    // when
    ZMUpstreamRequest *sut = [[ZMUpstreamRequest alloc] initWithTransportRequest:transportRequest];
    
    // then
    XCTAssertEqualObjects(sut.keys, [NSSet set]);
    XCTAssertEqual(sut.transportRequest, transportRequest);
}

@end



@implementation ZMUpstreamInsertedObjectSyncTests (Dependencies)

- (void)testThatAnInsertedObjectIsNotReturnedIfItNeedsADependency;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder reject] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatAnInsertedObjectIsNotReturnedIfItNeedsADependencyAfterAnUpdate;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    [self.sut objectsDidChange:[NSSet setWithObject:dependency]];
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder reject] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatAnInsertedObjectIsReturnedIfItNoLongerNeedsADependencyAfterAnUpdate;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    [self.objectIDToObjectDependency removeObjectForKey:entity.objectID];
    [self.sut objectsDidChange:[NSSet setWithObject:dependency]];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNotNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatAnInsertedObjectIsNotReturnedIfItHasANewADependencyAfterAnUpdate;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    MockEntity2 *dependency2 = [self mockEntity2WithModifiedValue];
    
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    self.objectIDToObjectDependency[entity.objectID] = dependency2;
    [self.sut objectsDidChange:[NSSet setWithObject:dependency]];
    
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder reject] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatAnUpdatedObjectIsNotReturnedIfItNeedsADependency;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder reject] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForUpdatingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

- (void)testThatAnUpdatedObjectIsNotReturnedIfItNeedsADependencyAfterAnUpdate;
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    MockEntity2 *dependency = [self mockEntity2WithModifiedValue];
    self.objectIDToObjectDependency[entity.objectID] = dependency;
    
    // when
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    [self.sut objectsDidChange:[NSSet setWithObject:dependency]];
    // expect
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder reject] andReturn:[self dummyRequestWithKeys:entity.keysThatHaveLocalModifications]] requestForUpdatingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

@end



@implementation ZMUpstreamInsertedObjectSyncTests (ZMContextChangeTracker)

- (void)testThatItReturnsTheCorrectFetchRequest
{
    
    // when
    NSFetchRequest *request = [self.sut fetchRequestForTrackedObjects];
    
    // then
    NSFetchRequest *expected = [MockEntity sortedFetchRequestWithPredicate:[MockEntity predicateForObjectsThatNeedToBeInsertedUpstream]];
    XCTAssertEqualObjects(request, expected);
}

- (void)testThatItAddsTrackedObjects
{
    // given
    MockEntity *entity = [self mockEntityWithModifiedValue];
    NSSet *objects = [NSSet setWithObject:entity];
    
    // when
    [self.sut addTrackedObjects:objects];
    
    // then
    
    // expect
    ZMUpstreamRequest *request = [self dummyRequestWithKeys:entity.keysThatHaveLocalModifications];
    [(id<ZMUpstreamTranscoder>)[[(id)self.mockTranscoder expect] andReturn:request] requestForInsertingObject:entity forKeys:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // then
    ZMTransportRequest *transportRequest = [self.sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertNotNil(transportRequest);
    XCTAssertEqual(transportRequest, request.transportRequest);
}

@end

