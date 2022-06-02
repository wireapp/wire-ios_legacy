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
@import XCTest;
@import WireTesting;
@import OCMock;

#import "ZMAccessTokenHandler.h"
#import "ZMPersistentCookieStorage.h"
@import WireTransport.Testing;
#import "ZMURLSession.h"
#import "NSError+ZMTransportSession.h"
#import "Fakes.h"


@interface ZMAccessTokenHandlerTests : ZMTBaseTest

@property (nonatomic) ZMAccessToken *validAccessToken;
@property (nonatomic) ZMAccessToken *expiredAccessToken;
@property (nonatomic) id urlSession;

@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) FakeExponentialBackoff *backoff;
@property (nonatomic) FakeDelegate *delegate;
@property (nonatomic) ZMAccessTokenHandler *sut;

@property (nonatomic) NSUInteger taskCount;
@property (nonatomic) NSUInteger failureCount;
@property (nonatomic) NSUInteger successCount;
@property (nonatomic) ZMTransportResponse *recordedResponse;
@property (nonatomic) NSString *receivedToken;
@property (nonatomic) NSString *receivedTokenType;
@property (nonatomic) NSUUID *userIdentifier;

@end

@interface ZMAccessTokenHandlerTests (General)
@end
@interface ZMAccessTokenHandlerTests (ConsumeTasks)
@end
@interface ZMAccessTokenHandlerTests (Backoff)
@end
@interface ZMAccessTokenHandlerTests (Response)
@end

@implementation ZMAccessTokenHandlerTests

- (void)setUp {
    [super setUp];
#if TARGET_IPHONE_SIMULATOR
    [ZMPersistentCookieStorage setDoNotPersistToKeychain:YES];
#endif
    NSURL *baseURL = [NSURL URLWithString:@"https://www.example.com"];

    self.taskCount = 0;
    self.failureCount = 0;

    self.validAccessToken = [[ZMAccessToken alloc] initWithToken:@"valid-token" type:@"valid-type" expiresInSeconds:4321];
    self.expiredAccessToken = [[ZMAccessToken alloc] initWithToken:@"expired-token" type:@"expired-type" expiresInSeconds:0];
    self.userIdentifier = [NSUUID createUUID];
    self.urlSession = [OCMockObject niceMockForClass:[ZMURLSession class]];

    self.cookieStorage = [ZMPersistentCookieStorage storageForServerName:baseURL.host userIdentifier:self.userIdentifier];
    [self setAuthenticationCookieData];

    self.queue = [NSOperationQueue mainQueue];
    self.backoff = [[FakeExponentialBackoff alloc] init];
    self.delegate = [[FakeDelegate alloc] init];
    
    [self createSutWithAccessToken:nil];
}

- (void)createSutWithAccessToken:(ZMAccessToken *)accessToken {
    NSURL *baseURL = [NSURL URLWithString:@"https://www.example.com"];

    self.sut = [[ZMAccessTokenHandler alloc] initWithBaseURL:baseURL
                                               cookieStorage:self.cookieStorage
                                                    delegate:self.delegate
                                                       queue:self.queue
                                                       group:self.dispatchGroup
                                                     backoff:(id)self.backoff
                                          initialAccessToken:accessToken
                ];
}

- (void)tearDown {
    self.cookieStorage = nil;
    self.queue = nil;
    self.backoff = nil;
    self.sut = nil;
    self.delegate = nil;
    self.urlSession = nil;
    self.taskCount = 0;
    self.failureCount = 0;
    self.recordedResponse = nil;
    self.userIdentifier = nil;
    
#if TARGET_IPHONE_SIMULATOR
    [ZMPersistentCookieStorage setDoNotPersistToKeychain:NO];
#endif
    
    [super tearDown];
}


- (void)setAuthenticationCookieData;
{
    NSURL *URL = [NSURL URLWithString:@"https://www.example.com"];
    NSDictionary *headers = @{@"Set-Cookie": @"zuid=bar; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=example.com; HttpOnly; Secure"};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL
                                                              statusCode:200
                                                             HTTPVersion:@""
                                                            headerFields:headers];
    [self.cookieStorage setCookieDataFromResponse:response forURL:URL];
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
}

- (void)invokeAccessTokenRenewalFailureHandler:(ZMTransportResponse *)response
{
    self.recordedResponse = response;
    self.failureCount++;
}

- (void)invokeAccessTokenRenewalSuccessHandler:(NSString *)token type:(NSString *)type
{
    self.receivedToken = token;
    self.receivedTokenType = type
    ;    self.successCount++;
}

- (id)mockURLSessionTaskWithStatusCode:(NSInteger)statusCode error:(NSError *)error hasTransportData:(BOOL)hasTransportData
{
    NSUInteger taskIdentifier = 1;
    
    FakeURLResponse *testResponse = [FakeURLResponse testResponse];
    [testResponse setStatusCode:statusCode];
    if (hasTransportData) {
        [testResponse setBodyFromTransportData:@{@"access_token": @"FakeToken",
                                                 @"token_type": @"FakeType",
                                                 @"expires_in": @3000}];
    }
    
    id task = [[FakeDataTask alloc] initWithError:error taskIdentifier:taskIdentifier response:testResponse];
    [(ZMURLSession *)[[(id)self.urlSession expect] andReturn:task] taskWithRequest:OCMOCK_ANY
                                                                          bodyData:OCMOCK_ANY
                                                                  transportRequest:OCMOCK_ANY];
    return task;
}

@end



@implementation ZMAccessTokenHandlerTests (General)

- (void)testThatItCallsPerformBlockOnBackoff
{
    // given
    [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:NO];
    XCTAssertEqual(self.backoff.blocks.count, 0u);
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    
    // then
    XCTAssertEqual(self.backoff.blocks.count, 1u);
}

- (void)testThatItCallItsDelegateWhenSettingAnAccessToken
{
    // given
    XCTAssertEqual(self.delegate.delegateCallCount, 0u);

    // when
    self.sut.testing_accessToken = self.validAccessToken;
    
    // then
    XCTAssertEqual(self.delegate.delegateCallCount, 1u);
}


- (void)testThatItRequestsTheAccessTokenOnlyOnce
{
    // 1 - given
    id task  = [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:YES];
    
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // reject
    [(ZMURLSession *)[(id)self.urlSession reject] taskWithRequest:OCMOCK_ANY
                                                         bodyData:OCMOCK_ANY
                                                 transportRequest:OCMOCK_ANY];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
}


- (void)testThatItReturns_NO_ForCanStartRequestAccessToken_IfAccesToken_IsNotSet
{
    XCTAssertNil(self.sut.accessToken);
    
    // when
    BOOL canStartRequestWithAccessToken = [self.sut canStartRequestWithAccessToken];
    
    // then
    XCTAssertFalse(canStartRequestWithAccessToken);
}

- (void)testThatItReturns_YES_ForCanStartRequestAccessToken_IfAccesToken_IsSet_And_NotAboutToExpire
{
    // given
    [self createSutWithAccessToken:self.validAccessToken];
    XCTAssertNotNil(self.sut.accessToken);
    
    // when
    BOOL canStartRequestWithAccessToken = [self.sut canStartRequestWithAccessToken];
    
    // then
    XCTAssertTrue(canStartRequestWithAccessToken);
}

- (void)testThatItReturns_NO_ForCanStartRequestAccessToken_IfAccesToken_IsSet_And_Expired
{
    // given
    [self createSutWithAccessToken:self.expiredAccessToken];
    XCTAssertNotNil(self.sut.accessToken);
    
    // when
    BOOL canStartRequestWithAccessToken = [self.sut canStartRequestWithAccessToken];
    
    // then
    XCTAssertFalse(canStartRequestWithAccessToken);
}

- (void)testThatItSetsTheAccessTokenHeaderFromAnURLRequest
{
    // given
    id transportRequest = [OCMockObject niceMockForClass:[ZMTransportRequest class]];
    [[[transportRequest expect] andReturnValue:OCMOCK_VALUE(YES)] needsAuthentication];
    
    self.sut.testing_accessToken = self.validAccessToken;
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@""]];
    
    // when
    [self.sut checkIfRequest:transportRequest needsToFetchAccessTokenInURLRequest:urlRequest];
    
    // then
    NSDictionary *expectedHeader = self.sut.accessToken.httpHeaders;
    XCTAssertNotNil(expectedHeader);
    XCTAssertEqualObjects(urlRequest.allHTTPHeaderFields, expectedHeader);
}


- (void)testThatItSetsTheCookieTokenHeaderFromAnURLRequest
{
    // given
    id transportRequest = [OCMockObject niceMockForClass:[ZMTransportRequest class]];
    [[[transportRequest expect] andReturnValue:OCMOCK_VALUE(YES)] needsCookie];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@""]];
    XCTAssertNil(urlRequest.allHTTPHeaderFields);

    // when
    [self.sut checkIfRequest:transportRequest needsToAttachCookieInURLRequest:urlRequest];

    // then
    NSDictionary *expectedHeader = @{@"Cookie": @"zuid=bar"};
    XCTAssertEqualObjects(urlRequest.allHTTPHeaderFields, expectedHeader);
}

@end




@implementation ZMAccessTokenHandlerTests (ConsumeTasks)


- (void)testThatItReturns_NO_IfTheCurrentTaskIsNotTheTaskPassedIn
{
    // given
    NSURLSessionTask *task = [OCMockObject niceMockForClass:[NSURLSessionTask class]];
    XCTAssertNotEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    BOOL didConsume = [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertFalse(didConsume);
}

- (void)testThatItReturns_YES_IfTheCurrentTaskIsTheTaskPassedIn
{
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:NO];
    
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    BOOL didConsume = [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertTrue(didConsume);
}


- (void)testThatItCancelsTheCurrentAccessTokenTaskFor_ShouldRetry_NO
{
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:YES];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:NO apiVersion:0];
    
    // then
    XCTAssertNil(self.sut.currentAccessTokenTask);
}

- (void)testThatItDoesNotDeleteTheCookieIfRequestingTheAccessTokenFailsBecauseOfANetworkError
{
    // given
    static const int CONNECTION_LOST = -1005;
    NSError *error = [NSError errorWithDomain:@"NSURLErrorDomain" code:CONNECTION_LOST userInfo:nil];

    id task  = [self mockURLSessionTaskWithStatusCode:0 error:error hasTransportData:NO];

    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
}


- (void)testThatItResendsTheAccessTokenRequest
{
    // 1 - given
    id task1  = [self mockURLSessionTaskWithStatusCode:429 error:nil hasTransportData:NO];
    id task2  = [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:YES];
    
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task1);
    
    // when consuming the request
    [self.sut consumeRequestWithTask:task1 data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then we create a new task, because the first request failed
    XCTAssertEqual(self.backoff.increaseBackoffCount, 1);
    XCTAssertEqual(self.sut.currentAccessTokenTask, task2);
    
    // when consuming the second request
    [self.sut consumeRequestWithTask:task2 data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.resetBackoffCount, 1);
}

- (void)testThatIt_DoesNot_ResendTheAccessTokenRequest_ForShouldRetry_NO
{
    // 1 - given
    NSError *error = [NSError tryAgainLaterError];
    id task1  = [self mockURLSessionTaskWithStatusCode:0 error:error hasTransportData:NO];
    
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task1);
    
    // when consuming the request
    [self.sut consumeRequestWithTask:task1 data:nil session:self.urlSession shouldRetry:NO apiVersion:0];
    
    // no new task is created
    XCTAssertNil(self.sut.currentAccessTokenTask);
    
}

@end




@implementation ZMAccessTokenHandlerTests (Backoff)


- (void)testThatIt_Increases_TheBackOffWhenItReceives_Status500
{
    // equivalent to ZMTransportResponseStatusTemporaryError
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:500 error:nil hasTransportData:NO];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.increaseBackoffCount, 1);
    XCTAssertEqual(self.backoff.resetBackoffCount, 0);
}

- (void)testThatIt_Increases_TheBackOffWhenItReceives_Status420
{
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:420 error:nil hasTransportData:NO];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.increaseBackoffCount, 1);
    XCTAssertEqual(self.backoff.resetBackoffCount, 0);
}

- (void)testThatIt_Increases_TheBackOffWhenItReceives_Status429
{
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:429 error:nil hasTransportData:NO];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.increaseBackoffCount, 1);
    XCTAssertEqual(self.backoff.resetBackoffCount, 0);
}

- (void)testThatIt_DoesNotChange_TheBackOffWhenItReceivesATryAgainLaterError
{
    // given
    NSError *error = [NSError tryAgainLaterError];

    id task  = [self mockURLSessionTaskWithStatusCode:0 error:error hasTransportData:NO];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.increaseBackoffCount, 0);
    XCTAssertEqual(self.backoff.resetBackoffCount, 0);
}

- (void)testThatIt_Resets_TheBackOffWhenItReceives_Status200
{
    // given
    id task  = [self mockURLSessionTaskWithStatusCode:200 error:nil hasTransportData:YES];
    
    // when
    [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    XCTAssertEqual(self.sut.currentAccessTokenTask, task);
    
    // when
    [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:YES apiVersion:0];
    
    // then
    XCTAssertEqual(self.backoff.resetBackoffCount, 1);
    XCTAssertEqual(self.backoff.increaseBackoffCount, 0);
}

@end




@implementation ZMAccessTokenHandlerTests (Response)

- (void)testThatItClearsAccessToken
{
    // given
    self.sut.testing_accessToken = self.validAccessToken;
    XCTAssertNotNil([self.sut valueForKey:@"accessToken"]);

    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    
    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertNil([self.sut valueForKey:@"accessToken"]);
}

- (void)testThatItReturns_NO_IfItReceivesA_ZMTransportResponseStatusSuccess
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertFalse(needsToReRun);
}

- (void)testThatItReturns_YES_IfItReceivesA_ZMTransportResponseStatusTemporaryError
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusTemporaryError];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertTrue(needsToReRun);
}

- (void)testThatItReturns_YES_IfItReceivesA_ZMTransportResponseStatusTryAgainLater
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusTryAgainLater];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertTrue(needsToReRun);
}

- (void)testThatItReturns_YES_IfItReceivesA_ZMTransportResponseStatusPermanentError_AndStatus429
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    [testResponse setHTTPStatus:429];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertTrue(needsToReRun);
}

- (void)testThatItReturns_YES_IfItReceivesA_ZMTransportResponseStatusPermanentError_AndStatus420
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    [testResponse setHTTPStatus:420];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertTrue(needsToReRun);
}

- (void)testThatItReturns_NO_IfItReceivesA_ZMTransportResponseStatusPermanentError_Not420Or429Status
{
    // given
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    
    // when
    BOOL needsToReRun = [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertFalse(needsToReRun);
}

- (void)testThatIt_ClearsCookie_IfItReceivesA_ZMTransportResponseStatusPermanentError_Not420Or429Status
{
    // given
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    
    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertNil(self.cookieStorage.authenticationCookieData);
}

- (void)testThatIt_DoesNot_ClearsCookie_IfItReceivesA_ZMTransportResponseStatusPermanentError_429Status
{
    // given
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    [testResponse setHTTPStatus:429];

    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
}

- (void)testThatIt_DoesNot_ClearsCookie_IfItReceivesA_ZMTransportResponseStatusPermanentError_420Status
{
    // given
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusPermanentError];
    [testResponse setHTTPStatus:420];
    
    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
}

- (void)testThatIt_DoesNot_ClearsCookie_IfItReceivesA_ZMTransportResponseStatusTemporaryError
{
    // given
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusTemporaryError];
    
    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
}

- (void)testThatItDeletesTheCookieDataIfItDoesNotReceiveANewToken
{
    // given
    XCTAssertNotNil(self.cookieStorage.authenticationCookieData);
    
    FakeTransportResponse *response = [FakeTransportResponse testResponse];
    [response setResult:ZMTransportResponseStatusSuccess];
    
    // when
    [self.sut processAccessTokenResponse:(id)response];
    
    // then
    XCTAssertNil(self.cookieStorage.authenticationCookieData);
}

- (void)testThatItForwardsTheResponseToTheFailureHandlerIfItDoesNotReceiveANewToken
{
    // given
    XCTAssertEqual(self.failureCount, 0u);

    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    
    // when
    __weak id weakSelf = self;
    [self.sut setAccessTokenRenewalFailureHandler:^(ZMTransportResponse *response) {
        id strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf invokeAccessTokenRenewalFailureHandler:response];
        }
    }];
    
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertEqual(self.failureCount, 1u);
    XCTAssertEqual(self.recordedResponse, (id)testResponse);
}

- (void)testThatIt_DoesNot_ForwardsTheResponseToThe_Success_HandlerIfItDoesNotReceiveANewToken
{
    // given
    XCTAssertEqual(self.successCount, 0u);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    
    // when
    __weak id weakSelf = self;
    [self.sut setAccessTokenRenewalSuccessHandler:^(NSString *token, NSString *type) {
        id strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf invokeAccessTokenRenewalSuccessHandler:token type:type];
        }
    }];
    
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertEqual(self.successCount, 0u);
    XCTAssertNil(self.recordedResponse);
}

- (void)testThatIt_DoesNot_ForwardTheResponseToTheFailureHandlerIfItReceivesANewToken
{
    // given
    XCTAssertEqual(self.failureCount, 0u);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    testResponse.payload = @{@"access_token": @"FakeToken",
                             @"token_type": @"FakeType",
                             @"expires_in": @3000};
    // when
    __weak id weakSelf = self;
    [self.sut setAccessTokenRenewalFailureHandler:^(ZMTransportResponse *response) {
        id strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf invokeAccessTokenRenewalFailureHandler:response];
        }
    }];
    
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertEqual(self.failureCount, 0u);
    XCTAssertNil(self.recordedResponse);
}

- (void)testThatIt_Forwards_TheResponseToTheSuccessHandlerIfItReceivesANewToken
{
    // given
    XCTAssertEqual(self.successCount, 0u);
    NSString *token = @"FakeToken";
    NSString *type = @"FakeType";
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    testResponse.payload = @{@"access_token": token,
                             @"token_type": type,
                             @"expires_in": @3000};
    // when
    __weak id weakSelf = self;
    [self.sut setAccessTokenRenewalSuccessHandler:^(NSString *aToken, NSString *aType) {
        id strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf invokeAccessTokenRenewalSuccessHandler:aToken type:aType];
        }
    }];
    
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertEqual(self.successCount, 1u);
    XCTAssertEqual(self.receivedToken, token);
    XCTAssertEqual(self.receivedTokenType, type);

}

- (void)testThatItSetsTheNewTokenWhenItReceivesOne
{
    // given
    XCTAssertNil(self.sut.accessToken);
    
    FakeTransportResponse *testResponse = [FakeTransportResponse testResponse];
    [testResponse setResult:ZMTransportResponseStatusSuccess];
    testResponse.payload = @{@"access_token": @"FakeToken",
                             @"token_type": @"FakeType",
                             @"expires_in": @3000};
    
    // when
    [self.sut processAccessTokenResponse:(id)testResponse];
    
    // then
    XCTAssertEqualObjects(self.sut.accessToken.token, @"FakeToken");
    XCTAssertEqualObjects(self.sut.accessToken.type, @"FakeType");
    XCTAssertEqualWithAccuracy([self.sut.accessToken.expirationDate timeIntervalSinceNow], 3000, 0.01);
}

- (void)testThatTheAccessTokenHasBeenSetWhenTheDelegateIsNotified_HandlerDidRecieveAccessToken
{
    // given
    self.sut.testing_accessToken = self.expiredAccessToken;
    XCTAssertNotNil(self.sut.accessToken);
    NSString *expectedTokenString = @"new valid token";
    ZMAccessToken *token = [[ZMAccessToken alloc] initWithToken:expectedTokenString type:@"BEARER" expiresInSeconds:3000];

    __block NSString *lastKnownTokenString;
    
    // expect
    __weak typeof (self.sut) weakSut = self.sut;
    self.delegate.didReceiveAccessTokenBlock = ^{
        lastKnownTokenString = weakSut.testing_accessToken.token;
    };
    
    // when
    self.delegate.delegateCallCount = 0;
    self.sut.testing_accessToken = token;
    
    // then
    XCTAssertEqual(self.delegate.delegateCallCount, 1lu);
    XCTAssertEqualObjects(lastKnownTokenString, expectedTokenString);
}

- (void)testThatItSetsTheAutorizationHeaderWithTheLastKnownAccessToken
{
    // given
    self.sut.testing_accessToken = self.validAccessToken;
    XCTAssertNotNil(self.sut.accessToken);
    
    // expect that if it as an access token, it sets the correct header
    {
        [[self.urlSession expect] taskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            NSString *authorisationField = request.allHTTPHeaderFields[@"Authorization"];
            return [authorisationField isEqualToString:[NSString stringWithFormat:@"%@ %@", self.validAccessToken.type, self.validAccessToken.token]];
        }] bodyData:nil transportRequest:nil];
        
        // when
        [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    }
    
    // create a consumable task that will fail to update the accessToken
    {
        id task  = [self mockURLSessionTaskWithStatusCode:500 error:nil hasTransportData:YES];
        [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
        [self.sut consumeRequestWithTask:task data:nil session:self.urlSession shouldRetry:NO apiVersion:0];
        XCTAssertNotNil(self.sut.accessToken);
    }
    
    // even though the accessToken didn't refresh, it should use the last known accesstoken for setting the header
    {
        // expect
        [[self.urlSession expect] taskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            NSString *authorisationField = request.allHTTPHeaderFields[@"Authorization"];
            return [authorisationField isEqualToString:[NSString stringWithFormat:@"%@ %@", self.validAccessToken.type, self.validAccessToken.token]];
        }] bodyData:nil transportRequest:nil];
        
        // when
        [self.sut sendAccessTokenRequestWithURLSession:self.urlSession];
    }
    
    // then
    [self.urlSession verify];
}


@end
