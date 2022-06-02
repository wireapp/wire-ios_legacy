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
@import WireRequestStrategy;
@import WireTesting;
@import WireDataModel;

#import "ZMSimpleListRequestPaginator+Internal.h"
#import "MockModelObjectContextFactory.h"
#import "WireRequestStrategyTests-Swift.h"

// TODO Katerina:  convert to Swift

@interface ZMSimpleListRequestPaginatorTests : ZMTBaseTest

@property (nonatomic) ZMSimpleListRequestPaginator *sut;
@property (nonatomic) NSString *basePath;
@property (nonatomic) NSUInteger pageSize;
@property (nonatomic) id singleRequestSync;
@property (nonatomic) CoreDataStack *coreDataStack;

- (NSUUID *)returnFullPageWithLastIdentifier:(NSUUID *)lastIdentifier;

@property (nonatomic) id transcoder;

@end



@implementation ZMSimpleListRequestPaginatorTests

- (void)setUp {

    [super setUp];

    self.coreDataStack = [self createCoreDataStackWithUserIdentifier:[NSUUID UUID]
                                                       inMemoryStore:YES];

    self.basePath = @"/base-path";
    self.pageSize = 20;
    self.transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMSimpleListRequestPaginatorSync)];
    [self verifyMockLater:self.transcoder];

    self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:@"start" pageSize:self.pageSize managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:self.transcoder];

    self.singleRequestSync = [OCMockObject mockForClass:ZMSingleRequestSync.class];
    [self verifyMockLater:self.singleRequestSync];

    self.sut.singleRequestSync = self.singleRequestSync;
}

- (void)tearDown
{
    self.transcoder = nil;
    self.basePath = nil;
    self.sut = nil;
    self.singleRequestSync = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSUUID *)returnFullPageWithLastIdentifier:(NSUUID *)lastIdentifier
{
    NSMutableArray *array = [NSMutableArray array];
    for(NSUInteger i = 0; i < self.pageSize-1; ++i) {
        [array addObject:[NSUUID createUUID]];
    }
    [array addObject:lastIdentifier];
    return array.lastObject;
}

- (void)testThatItCreatesASingleRequestSyncByDefault
{
    // when
    ZMSimpleListRequestPaginator *sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:@"foo" startKey:@"bar" pageSize:10 managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:nil];

    // then
    XCTAssertNotNil(sut.singleRequestSync);
    XCTAssertEqual(sut.singleRequestSync.groupQueue, self.coreDataStack.syncContext);
    id transcoder = sut.singleRequestSync.transcoder;
    XCTAssertEqual(transcoder, sut);
}

- (void)testThatResetMarksSingleRequestSyncAsNeedToDownload
{
    // expect
    [[self.singleRequestSync expect] readyForNextRequest];

    // when
    [self.sut resetFetching];

    // then
    [self.singleRequestSync verify];
}

- (void)testThatItDoesNotHaveMoreToFetchAfterCreation
{
    // when
    BOOL hasMore = self.sut.hasMoreToFetch;

    // then
    XCTAssertFalse(hasMore);
    [self.singleRequestSync verify];
}

- (void)testThatItHasMoreToFetchAfterResetFetching
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    // when
    BOOL hasMore = self.sut.hasMoreToFetch;

    // then
    XCTAssertTrue(hasMore);
}

- (void)testThatItDoesNotReturnARequestIfItDoesNotHaveMoreToDownload
{
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0]);
}

@end



@implementation ZMSimpleListRequestPaginatorTests (Transcoder)

- (UserClient *)createSelfClient
{
    UserClient *selfClient = [self setupSelfClientInMoc:self.coreDataStack.syncContext];
    NSDictionary *payload = @{@"id": selfClient.remoteIdentifier, @"type": @"permanent", @"time": [[NSDate date] transportString]};
    NOT_USED([UserClient createOrUpdateSelfUserClient:payload context:self.coreDataStack.syncContext]);
    [self.coreDataStack.syncContext saveOrRollback];

    return selfClient;
}

- (UserClient *)setupSelfClientInMoc:(NSManagedObjectContext *)moc;
{
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    if (selfUser.remoteIdentifier == nil) {
        selfUser.remoteIdentifier = [NSUUID createUUID];
    }

    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:moc];
    client.remoteIdentifier = [NSString createAlphanumericalString];
    client.user = selfUser;

    [moc setPersistentStoreMetadata:client.remoteIdentifier forKey:ZMPersistedClientIdKey];
    [moc saveOrRollback];

    return client;
}


- (void)testThatItForwardsNextRequestToTheSingleRequestSync
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    // expect
    ZMTransportRequest *expectedRequest = [ZMTransportRequest requestGetFromPath:@"baa" apiVersion:APIVersionV0];
    [[[self.singleRequestSync expect] andReturn:expectedRequest] nextRequestForAPIVersion:APIVersionV0];

    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];

    // then
    XCTAssertEqual(expectedRequest, request);
    [self.singleRequestSync verify];
}

- (void)testThatItReturnsARequestWithTheRightURLAndSize
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    // when
    ZMTransportRequest *request = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // after
    NSString *expectedURL = [NSString stringWithFormat:@"%@?size=%lu", self.basePath, (unsigned long) self.pageSize];
    XCTAssertNotNil(request);
    XCTAssertEqual(request.method, ZMMethodGET);
    XCTAssertEqualObjects(request.path, expectedURL);
    XCTAssertTrue(request.needsAuthentication);
}

- (void)testThatItUsesTheCorrectStartKeyAndUUID
{
    // given
    NSUUID *startUUID = [NSUUID createUUID];
    NSString *startKey = @"foo";

    id transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMSimpleListRequestPaginatorSync)];
    [[[transcoder expect] andReturn:startUUID] startUUID];

    self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:startKey pageSize:self.pageSize  managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:transcoder];

    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    // when
    ZMTransportRequest *request = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // after
    NSString *expectedURL = [NSString stringWithFormat:@"%@?size=%lu&%@=%@", self.basePath, (unsigned long) self.pageSize, startKey, startUUID.transportString];
    XCTAssertNotNil(request);
    XCTAssertEqual(request.method, ZMMethodGET);
    XCTAssertEqualObjects(request.path, expectedURL);
    XCTAssertTrue(request.needsAuthentication);
}

- (void)testThatItIncludesTheClientID
{
    [self.coreDataStack.syncContext performGroupedBlock:^{
        // given
        NSString *selfClientID = [self createSelfClient].remoteIdentifier;

        self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:@"foo" pageSize:self.pageSize managedObjectContext:self.coreDataStack.syncContext includeClientID:YES transcoder:nil];

        [[self.singleRequestSync stub] readyForNextRequest];
        [self.sut resetFetching];

        // when
        ZMTransportRequest *request = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

        // after
        NSString *expectedURL = [NSString stringWithFormat:@"%@?size=%lu&%@=%@", self.basePath, (unsigned long) self.pageSize, @"client", selfClientID];
        XCTAssertNotNil(request);
        XCTAssertEqual(request.method, ZMMethodGET);
        XCTAssertEqualObjects(request.path, expectedURL);
        XCTAssertTrue(request.needsAuthentication);
    }];

    WaitForAllGroupsToBeEmpty(0.5);
}



- (void)testThatItCallsThUUIDExtractorOnASuccessfulRequest
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    NSDictionary *expectedPayload = @{@"foo":@42};

    // expect
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:expectedPayload HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];
    [[[self.transcoder expect] andReturn:[NSUUID createUUID]] nextUUIDFromResponse:response forListPaginator:OCMOCK_ANY];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

}

- (void)testThatItResetsTheSingleRequestAfterEachSuccessfulResponse
{
    // given
    [[self.singleRequestSync expect] readyForNextRequest];
    [self.sut resetFetching];

    // expect
    [[self.singleRequestSync expect] readyForNextRequest];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItResetsTheSingleRequestAfterEachFailedResponse
{
    // given
    [[self.singleRequestSync expect] readyForNextRequest];
    [self.sut resetFetching];

    // expect
    [[self.singleRequestSync expect] readyForNextRequest];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:404 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItResetsTheSingleRequestAfterEachTemporaryFailureResponse
{
    // given
    [[self.singleRequestSync expect] readyForNextRequest];
    [self.sut resetFetching];

    // expect
    [[self.singleRequestSync expect] readyForNextRequest];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:500 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end



@implementation ZMSimpleListRequestPaginatorTests (Pagination)


- (void)testThatItDoesNotHaveMoreToDownloadIfTheExtractorReturnedAnEmptyArray
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[[self.transcoder expect] andReturn:[NSUUID createUUID]] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertFalse(self.sut.hasMoreToFetch);
}

- (void)testThatItDoesNotHaveMoreToDownloadIfTheExtractorReturnedLessUUIDsThanThePageSize
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[[self.transcoder expect] andReturn:[NSUUID createUUID]] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertFalse(self.sut.hasMoreToFetch);
}

- (void)testThatItDoesHaveMoreToDownloadIf_Has_More_IsSet_YES
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];
    NSDictionary *payload = @{@"has_more": @(YES)};

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertTrue(self.sut.hasMoreToFetch);
}

- (void)testThatItDoesNotHaveMoreToDownloadIf_Has_More_IsSet_NO
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];
    NSDictionary *payload = @{@"has_more": @(NO)};

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertFalse(self.sut.hasMoreToFetch);
}

- (void)testThatItDoesNotHaveMoreToDownloadAndItDoesNotCallTheExtractorIfThereIsAPermanentError__ParsePermanentErrorResponse_False
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[self.transcoder reject] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{@"has_more" : @1} HTTPStatus:400 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertFalse(self.sut.hasMoreToFetch);
}

- (void)testThatItDoesNotHaveMoreToDownloadAndItDoesNotCallTheExtractorIfThereIsAPermanentError_Code400_ParsePermanentErrorResponse_True
{
    // given
    id transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMSimpleListRequestPaginatorSync)];
    [[transcoder reject] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];

    self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:@"start" pageSize:self.pageSize  managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:transcoder];
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{@"has_more" : @1} HTTPStatus:400 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertFalse(self.sut.hasMoreToFetch);
    [transcoder verify];
}

- (void)testThatItHasMoreToDownloadAndItCallsTheExtractorIfThereIsAPermanentError_Code404_ParsePermanentErrorResponse_True
{
    // given
    id transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMSimpleListRequestPaginatorSync)];
    [[transcoder expect] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];

    self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:@"start" pageSize:self.pageSize  managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:transcoder];
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{@"has_more" : @1} HTTPStatus:404 transportSessionError:nil apiVersion:APIVersionV0];
    [[[transcoder expect] andReturnValue:OCMOCK_VALUE(YES)] shouldParseErrorForResponse:response];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];

    // then
    XCTAssertTrue(self.sut.hasMoreToFetch);
    [transcoder verify];
}


- (void)testThatItDoesHaveMoreToDownloadAndDoesNotCallTheExtractorIfThereIsATemporaryError
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[self.transcoder reject] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:nil HTTPStatus:500 transportSessionError:nil apiVersion:APIVersionV0];

    // when
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertTrue(self.sut.hasMoreToFetch);
}

@end



@implementation ZMSimpleListRequestPaginatorTests (RequestNextPage)

- (void)testThatAfterParsingAResponseItRequestsThePageFollowingTheLastUUIDExtracted_InitializedWithoutStartUUID
{
    // given
    NSUUID *lastIdentifier = [NSUUID createUUID];
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    NSDictionary *payload = @{@"has_more" : @(YES)};
    [[[self.transcoder expect] andReturn:[self returnFullPageWithLastIdentifier:lastIdentifier]] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMTransportRequest *followingRequest = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // then
    NSString *expectedURL = [NSString stringWithFormat:@"%@?size=%lu&start=%@", self.basePath, (unsigned long)self.pageSize, lastIdentifier.transportString];
    XCTAssertEqualObjects(followingRequest.path, expectedURL);
}

- (void)testThatAfterParsingAResponseItRequestsThePageFollowingTheLastUUIDExtracted_InitializedWithStartUUID
{
    // given
    NSUUID *startIdentifier = [NSUUID createUUID];
    NSUUID *lastIdentifier = [NSUUID createUUID];
    [[self.singleRequestSync stub] readyForNextRequest];

    NSDictionary *payload = @{@"has_more" : @(YES)};

    id transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMSimpleListRequestPaginatorSync)];
    [[[transcoder expect] andReturn:[self returnFullPageWithLastIdentifier:lastIdentifier]] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];
    [[[transcoder expect] andReturn:startIdentifier] startUUID];

    self.sut = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:self.basePath startKey:@"start" pageSize:self.pageSize  managedObjectContext:self.coreDataStack.syncContext includeClientID:NO transcoder:transcoder];
    self.sut.singleRequestSync = self.singleRequestSync;

    [self.sut resetFetching];

    // when
    ZMTransportRequest *firstRequest = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // then
    NSString *expectedURL1 = [NSString stringWithFormat:@"%@?size=%lu&start=%@", self.basePath, (unsigned long)self.pageSize, startIdentifier.transportString];
    XCTAssertEqualObjects(firstRequest.path, expectedURL1);

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMTransportRequest *followingRequest = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // then
    NSString *expectedURL2 = [NSString stringWithFormat:@"%@?size=%lu&start=%@", self.basePath, (unsigned long)self.pageSize, lastIdentifier.transportString];
    XCTAssertEqualObjects(followingRequest.path, expectedURL2);
}


- (void)testThatAfterCompletingPaginationItDoesNotReturnAnotherRequest
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[[self.transcoder expect] andReturn:nil] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    ZMTransportRequest *followingRequest = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // then
    XCTAssertNil(followingRequest);
}


- (void)testThatAfterCompletingPaginationAndResettingItReturnsANewRequestWithoutThePreviousPaginationStart
{
    // given
    [[self.singleRequestSync stub] readyForNextRequest];
    [self.sut resetFetching];

    [[[self.transcoder expect] andReturn:[NSUUID UUID]] nextUUIDFromResponse:OCMOCK_ANY forListPaginator:OCMOCK_ANY];

    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{} HTTPStatus:200 transportSessionError:nil apiVersion:APIVersionV0];
    [self.sut didReceiveResponse:response forSingleRequest:self.singleRequestSync];
    WaitForAllGroupsToBeEmpty(0.5);

    // when
    [self.sut resetFetching];
    ZMTransportRequest *followingRequest = [self.sut requestForSingleRequestSync:self.singleRequestSync apiVersion:APIVersionV0];

    // then
    NSString *expectedURL = [NSString stringWithFormat:@"%@?size=%lu", self.basePath, (unsigned long) self.pageSize];
    XCTAssertNotNil(followingRequest);
    XCTAssertEqual(followingRequest.method, ZMMethodGET);
    XCTAssertEqualObjects(followingRequest.path, expectedURL);
    XCTAssertTrue(followingRequest.needsAuthentication);
}
@end


