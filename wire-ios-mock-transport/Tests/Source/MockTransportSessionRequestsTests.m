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

@import WireMockTransport;
#import "MockTransportSessionTests.h"

@interface MockTransportSessionRequestsTests : MockTransportSessionTests

@end

@implementation MockTransportSessionRequestsTests


- (void)testThatItReturnsResponseFromResponseGenerator
{
    // GIVEN
    NSDictionary *expectedPayload = @{@"foo": @"baar"};
    NSError *expectedError = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    NSInteger expectedStatus = 451;
    
    NSString *requestPath =@"/connections";
    ZMTransportRequestMethod requestMethod = ZMMethodPUT;
    NSArray *requestPayload = @[@3,@4,@5];
    
    __block ZMTransportRequest *receivedRequest;
    self.sut.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NOT_USED(request);
        receivedRequest = request;
        return [ZMTransportResponse responseWithPayload:expectedPayload HTTPStatus:expectedStatus transportSessionError:expectedError apiVersion:0];
    };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:requestPath method:requestMethod apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if(!response) {
        return;
    }
    
    XCTAssertNotNil(receivedRequest);
    XCTAssertEqualObjects(receivedRequest.path, requestPath);
    XCTAssertEqualObjects(receivedRequest.payload, requestPayload);
    XCTAssertEqual(receivedRequest.method, requestMethod);
    
    
    XCTAssertEqual(response.HTTPStatus, expectedStatus);
    XCTAssertEqualObjects(response.transportSessionError, expectedError);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

- (void)testThatItReturnsTheOriginalResponseIfTheResponseGeneratorReturnsNil
{
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.email = @"me@example.com";
        selfUser.phone = @"456456456";
    }];
    NSString *requestPath = [NSString stringWithFormat:@"/users?ids=%@", self.sut.selfUser.identifier];
    ZMTransportRequestMethod requestMethod = ZMMethodGET;
    NSArray *requestPayload = nil;
    
    // GIVEN
    self.sut.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NOT_USED(request);
        return nil;
    };
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:requestPath method:requestMethod apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if(!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.transportSessionError, nil);
    XCTAssertEqualObjects(response.payload, @[self.sut.selfUser.transportData]);
}


- (void)testThatItNeverCompletesIfTheResponseGeneratorReturns_ZMCustomResponseGeneratorReturnResponseNotCompleted
{
    // GIVEN
    self.sut.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        NOT_USED(request);
        return ResponseGenerator.ResponseNotCompleted;
    };
    
    __block BOOL completed = NO;
    ZMCompletionHandler *handler = [ZMCompletionHandler handlerOnGroupQueue:self.fakeSyncContext block:^(ZMTransportResponse *backgroundResponse) {
        (void)backgroundResponse;
        completed = YES;
    }];
    
    ZMTransportRequestGenerator generator = [self createGeneratorForPayload:nil path:@"/foo" method:ZMMethodGET apiVersion:0 handler:handler];
    
    ZMTransportEnqueueResult* result = [self.sut.mockedTransportSession attemptToEnqueueSyncRequestWithGenerator:generator];
    WaitForAllGroupsToBeEmpty(0.2);
    [self spinMainQueueWithTimeout:0.2];
    
    // THEN
    XCTAssertTrue(result.didHaveLessRequestThanMax);
    XCTAssertTrue(result.didGenerateNonNullRequest);
    XCTAssertFalse(completed);
    
    [self.sut expireAllBlockedRequests];
    WaitForAllGroupsToBeEmpty(0.2);
    [self spinMainQueueWithTimeout:0.2];
    
    XCTAssertTrue(completed);
}


- (void)testThatItReturnsAnImage
{
    // GIVEN
    NSString *convID = [NSUUID createUUID].transportString;
    NSString *assetID = [NSUUID createUUID].transportString;
    NSData *expectedImageData =  [ZMTBaseTest verySmallJPEGData];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        NOT_USED(session);
        MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.sut.managedObjectContext];
        asset.data = expectedImageData;
        asset.identifier = assetID;
        asset.conversation = convID;
        XCTAssertNotNil(expectedImageData);
    }];
    
    NSString *path = [NSString pathWithComponents:@[@"/", @"assets", [NSString stringWithFormat:@"%@?conv_id=%@", assetID, convID]]];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    AssertEqualData(response.imageData, expectedImageData);
}


- (void)testThatItDoesNotRespondToRequests
{
    // GIVEN
    self.sut.doNotRespondToRequests = YES;
    
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block MockConversation *oneOnOneConversation;
    __block NSString *selfUserID;
    __block NSString *oneOnOneConversationID;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        selfUserID = selfUser.identifier;
        user1 = [session insertUserWithName:@"Foo"];
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversationID = oneOnOneConversation.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.sut clearNotifications];
    WaitForAllGroupsToBeEmpty(0.5);

    NSString *messageText = @"Fofooof";
    NSUUID *nonce = [NSUUID createUUID];
    
    // (1)
    {
        // WHEN
        NSDictionary *payload = @{
                                  @"content" : messageText,
                                  @"nonce" : nonce.transportString
                                  };
        
        NSString *path = [NSString pathWithComponents:@[@"/", @"conversations", oneOnOneConversationID, @"messages"]];
        
        
        ZMCompletionHandler *handler = [ZMCompletionHandler handlerOnGroupQueue:self.fakeSyncContext block:^(ZMTransportResponse *backgroundResponse) {
            NOT_USED(backgroundResponse);
            XCTFail(@"Shouldn't respond");
        }];
        
        ZMTransportRequestGenerator generator = [self createGeneratorForPayload:payload path:path method:ZMMethodPOST apiVersion:0 handler:handler];
        
        ZMTransportEnqueueResult *result = [self.sut.mockedTransportSession attemptToEnqueueSyncRequestWithGenerator:generator];
        
        XCTAssertTrue(result.didHaveLessRequestThanMax);
        XCTAssertTrue(result.didGenerateNonNullRequest);
    }
    
    
    
    // (2)
    {
        // WHEN
        self.sut.doNotRespondToRequests = NO;
        
        NSString *path = @"/notifications";
        ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
        
        // THEN
        XCTAssertNotNil(response);
        if (!response) {
            return;
        }
        XCTAssertEqual(response.HTTPStatus, 200);
        XCTAssertNil(response.transportSessionError);
        NSArray *events = [[response.payload asDictionary] arrayForKey:@"notifications"];
        XCTAssertNotNil(events);
        XCTAssertLessThanOrEqual(events.count, 1u);
    }
    
}


- (void)testThatOfflineWeNeverGetAResponseToOurRequest {
    
    // GIVEN
    self.sut.doNotRespondToRequests = YES;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/conversations/ids"];
    
    ZMTransportSession *mockedTransportSession = self.sut.mockedTransportSession;
    
    __block ZMTransportResponse *response;
    
    ZMCompletionHandler *handler = [ZMCompletionHandler handlerOnGroupQueue:self.fakeSyncContext block:^(ZMTransportResponse *backgroundResponse) {
        NOT_USED(backgroundResponse);
        XCTFail();
    }];
    
    ZMTransportRequestGenerator generator = ^ZMTransportRequest*(void) {
        ZMTransportRequest *request = [ZMTransportRequest requestWithPath:path method:ZMMethodGET payload:nil apiVersion:0];
        [request addCompletionHandler:handler];
        return request;
    };
    
    
    ZMTransportEnqueueResult* result = [mockedTransportSession attemptToEnqueueSyncRequestWithGenerator:generator];
    
    XCTAssertTrue(result.didHaveLessRequestThanMax);
    XCTAssertTrue(result.didGenerateNonNullRequest);
    
    [self spinMainQueueWithTimeout:0.3];
    
    // THEN
    XCTAssertNil(response);
    
    WaitForAllGroupsToBeEmpty(0.5);
}



- (void)testThatWhenOfflineAndMessageHasAnExpirationDateWeExpireTheRequest
{
    // GIVEN
    self.sut.doNotRespondToRequests = YES;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/conversations/ids"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Got a response"];
    
    ZMTransportSession *mockedTransportSession = self.sut.mockedTransportSession;
    
    __block ZMTransportResponse *response;
    
    ZMCompletionHandler *handler = [ZMCompletionHandler handlerOnGroupQueue:self.fakeSyncContext block:^(ZMTransportResponse *backgroundResponse) {
        response = backgroundResponse;
        [expectation fulfill];
    }];
    
    ZMTransportRequestGenerator generator = ^ZMTransportRequest*(void) {
        ZMTransportRequest *request = [ZMTransportRequest requestWithPath:path method:ZMMethodGET payload:nil apiVersion:0];
        [request expireAfterInterval:0.2]; //This is the important bit
        [request addCompletionHandler:handler];
        return request;
    };
    
    ZMTransportEnqueueResult* result = [mockedTransportSession attemptToEnqueueSyncRequestWithGenerator:generator];
    
    XCTAssertTrue(result.didHaveLessRequestThanMax);
    XCTAssertTrue(result.didGenerateNonNullRequest);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 0);
    XCTAssertNotNil(response.transportSessionError);
    XCTAssertEqual(response.transportSessionError.code, ZMTransportSessionErrorCodeRequestExpired);
    
}



@end



@implementation MockTransportSessionRequestsTests (ListOfRequests)

- (void)sendRequestToMockTransportSession:(ZMTransportRequest *)request
{
    ZMTransportRequestGenerator generator = ^ZMTransportRequest *(void) {
        return request;
    };
    [self.sut.mockedTransportSession attemptToEnqueueSyncRequestWithGenerator:generator];
}

- (void)testThatTheListOfRequestsContainsTheRequestsSent
{
    // GIVEN
    ZMTransportRequest *req1 = [ZMTransportRequest requestGetFromPath:@"/this/path" apiVersion:0];
    ZMTransportRequest *req2 = [ZMTransportRequest requestWithPath:@"/foo/bar" method:ZMMethodDELETE payload:nil apiVersion:0];
    ZMTransportRequest *req3 = [ZMTransportRequest requestWithPath:@"/arrrr" method:ZMMethodPUT payload:@{@"name":@"Johnny"} apiVersion:0];
    
    NSArray *requests = @[req1, req2, req3];
    
    // WHEN
    for(ZMTransportRequest *request in requests) {
        [self sendRequestToMockTransportSession:request];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqualObjects(requests, self.sut.receivedRequests);
}

- (void)testThatResetRequestDiscardsPreviousRequests
{
    // GIVEN
    ZMTransportRequest *req1 = [ZMTransportRequest requestGetFromPath:@"/this/path" apiVersion:0];
    ZMTransportRequest *req2 = [ZMTransportRequest requestWithPath:@"/foo/bar" method:ZMMethodDELETE payload:nil apiVersion:0];
    ZMTransportRequest *req3 = [ZMTransportRequest requestWithPath:@"/arrrr" method:ZMMethodPUT payload:@{@"name":@"Johnny"} apiVersion:0];
    for(ZMTransportRequest *request in @[req1, req2]) {
        [self sendRequestToMockTransportSession:request];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut resetReceivedRequests];
    [self sendRequestToMockTransportSession:req3];
    WaitForAllGroupsToBeEmpty(0.5);

    // THEN
    XCTAssertEqualObjects(self.sut.receivedRequests, @[req3]);
}


@end
