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
@import WireTesting;
@import WireDataModel;
@import WireRequestStrategy;

#import "WireRequestStrategyTests-Swift.h"
#import "ZMSingleRequestSync.h"
#import "ZMTimedSingleRequestSync.h"

@interface ZMTimedSingleRequestSyncTests : ZMTBaseTest <ZMSingleRequestTranscoder>

@property (nonatomic) CoreDataStack *coreDataStack;
@property (nonatomic) ZMTransportRequest *dummyRequest;
@property (nonatomic) ZMTransportResponse *dummyResponse;
@property (nonatomic) NSUInteger transcoderCallsToRequest;
@property (nonatomic) NSMutableArray *trancoderResponses;

@end

@implementation ZMTimedSingleRequestSyncTests

- (ZMTransportRequest *)requestForSingleRequestSync:(ZMSingleRequestSync *)sync apiVersion:(APIVersion)apiVersion
{
    NOT_USED(sync);
    ++self.transcoderCallsToRequest;
    return self.dummyRequest;
}

- (void)didReceiveResponse:(ZMTransportResponse *)response forSingleRequest:(ZMSingleRequestSync *)sync
{
    NOT_USED(sync);
    [self.trancoderResponses addObject:response];
}

- (void)setUp {
    [super setUp];

    self.coreDataStack = self.coreDataStack = [self createCoreDataStackWithUserIdentifier:[NSUUID UUID]
                                                                            inMemoryStore:YES];
    self.dummyRequest = [ZMTransportRequest requestGetFromPath:self.name apiVersion:0];
    self.dummyResponse = [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:0];
    self.transcoderCallsToRequest = 0;
    self.trancoderResponses = [NSMutableArray array];
}

- (void)tearDown {
    self.dummyRequest = nil;
    self.dummyResponse = nil;
    self.trancoderResponses = nil;
    self.coreDataStack = nil;
    [super tearDown];
}

- (void)testThatItReturnsTheInitParameters
{
    // given
    NSTimeInterval interval = 0.13;
    
    // when
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:interval groupQueue:self.coreDataStack.viewContext];
    
    // then
    XCTAssertEqual([sut nextRequestForAPIVersion:APIVersionV0], self.dummyRequest);
    XCTAssertEqual(self.transcoderCallsToRequest, 1u);
    XCTAssertEqualWithAccuracy(sut.timeInterval, interval,0.01);
    [sut invalidate];
}


- (void)testThatItDoesNotReturnTheRequestIfTheTimerIsNotExpired
{
    // given
    const int ATTEMPTS = 3;
    NSTimeInterval interval = 1;
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:interval groupQueue:self.coreDataStack.viewContext];

    // when
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqual(request1, self.dummyRequest);
    
    for(int i = 0; i < ATTEMPTS; ++i) {
        [self spinMainQueueWithTimeout:0.05];
        ZMTransportRequest *request2 = [sut nextRequestForAPIVersion:APIVersionV0];
        // then
        XCTAssertNil(request2);
    }
    
    // then
    [sut invalidate];
    XCTAssertEqual(self.transcoderCallsToRequest, 1u);
}

- (void)testThatItReturnsTheRequestWhenTheTimerIsOut
{
    // given
    const int ATTEMPTS = 3;
    NSTimeInterval interval = 0.01;
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:interval groupQueue:self.coreDataStack.viewContext];
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request1, self.dummyRequest);
    
    for(int i = 0; i < ATTEMPTS; ++i) {
        // when
        [self spinMainQueueWithTimeout:0.05];
        WaitForAllGroupsToBeEmpty(0.5);
        ZMTransportRequest *request2 = [sut nextRequestForAPIVersion:APIVersionV0];
        
        // then
        XCTAssertEqual(request2, self.dummyRequest);
    }
    
    // then
    [sut invalidate];
    XCTAssertEqual((int) self.transcoderCallsToRequest, ATTEMPTS +1);
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItCallsNextRequestAfterATimeout
{
    // given
    id mockOperationLoop = [OCMockObject mockForClass:ZMRequestAvailableNotification.class];
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0.01 groupQueue:self.coreDataStack.viewContext];
    
    // expect
    [[mockOperationLoop expect] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    ZMTransportRequest *request = [sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request, self.dummyRequest);
    [self spinMainQueueWithTimeout:0.1];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    [sut invalidate];
    [mockOperationLoop verify];
    [mockOperationLoop stopMocking];
}

- (void)testThatItStopsCallingNextRequestWhenCanceled
{
    // given
    id mockOperationLoop = [OCMockObject mockForClass:ZMRequestAvailableNotification.class];
    [[mockOperationLoop reject] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0.05 groupQueue:self.coreDataStack.viewContext];
    [sut nextRequestForAPIVersion:APIVersionV0];
    [sut invalidate];

    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];

    
    // then
    [mockOperationLoop verify];
    [mockOperationLoop stopMocking];
}

- (void)testThatChangingTheTimeIntervalResetsTheCurrentTimer
{
    // given
    NSTimeInterval interval = 0.1;
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:interval groupQueue:self.coreDataStack.viewContext];
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request1, self.dummyRequest);
    id mockOperationLoop = [OCMockObject mockForClass:ZMRequestAvailableNotification.class];
    [[mockOperationLoop reject] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    sut.timeInterval = 0.01;
    [self spinMainQueueWithTimeout:0.2];

    
    // then
    [sut invalidate];
    [mockOperationLoop verify];
    [mockOperationLoop stopMocking];
}

- (void)testThatHavingAZeroTimeIntervalCausesNoTimerToBeStarted
{
    // given
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0 groupQueue:self.coreDataStack.viewContext];
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request1, self.dummyRequest);
    id mockOperationLoop = [OCMockObject mockForClass:ZMRequestAvailableNotification.class];
    [[mockOperationLoop reject] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    [self spinMainQueueWithTimeout:0.2];

    
    // then
    XCTAssertEqual((int) self.transcoderCallsToRequest, 1);
    
    [sut invalidate];
    [mockOperationLoop verify];
    [mockOperationLoop stopMocking];
}

- (void)testSettingANonZeroTimeIntervalCausesTheTimerToBeStartedAfterNextRequest
{
    // given
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0 groupQueue:self.coreDataStack.viewContext];
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    XCTAssertEqual(request1, self.dummyRequest);
    
    sut.timeInterval = 0.01;
    id mockOperationLoop = [OCMockObject mockForClass:ZMRequestAvailableNotification.class];
    [[mockOperationLoop expect] notifyNewRequestsAvailable:OCMOCK_ANY];
    
    // when
    [sut nextRequestForAPIVersion:APIVersionV0];
    [self spinMainQueueWithTimeout:0.2];
    
    // then
    [sut invalidate];
    [mockOperationLoop verify];
    [mockOperationLoop stopMocking];
}

- (void)testThatItDoesNotReturnARequestWhileAPreviousRequestIsRunning
{
    // given
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0 groupQueue:self.coreDataStack.viewContext];
    
    // when
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    ZMTransportRequest *request2 = [sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNotNil(request1);
    XCTAssertNil(request2);
    [sut invalidate];
}

- (void)testThatItReturnsARequestWhenAPreviousRequestWasCompleted
{
    // given
    ZMTimedSingleRequestSync *sut = [[ZMTimedSingleRequestSync alloc] initWithSingleRequestTranscoder:self everyTimeInterval:0 groupQueue:self.coreDataStack.viewContext];
    
    ZMTransportRequest *request1 = [sut nextRequestForAPIVersion:APIVersionV0];
    
    // when
    [request1 completeWithResponse:self.dummyResponse];
    WaitForAllGroupsToBeEmpty(0.5);
    [sut readyForNextRequest];
    ZMTransportRequest *request2 = [sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNotNil(request1);
    XCTAssertNotNil(request2);
    [sut invalidate];
}

@end
