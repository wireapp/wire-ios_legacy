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


@import XCTest;
@import WireTransport;
@import WireSystem;
@import WireTesting;
@import OCMock;

#import "ZMURLSession+Internal.h"
#import "ZMTemporaryFileListForBackgroundRequests.h"
#import "Fakes.h"
#import "WireTransport_ios_tests-Swift.h"

@interface ZMURLSessionTests : ZMTBaseTest <ZMURLSessionDelegate, ZMTimerClient>

@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) ZMURLSession<NSURLSessionDataDelegate, NSURLSessionDownloadDelegate> *sut;
@property (nonatomic) NSURLSessionTask *taskA;
@property (nonatomic) NSURLSessionTask *taskB;

@property (nonatomic) NSURLRequest *URLRequestA;
@property (nonatomic) NSURLRequest *URLRequestB;

@property (nonatomic) NSUInteger receivedDataCount;
@property (nonatomic) NSUInteger unsafeConnectionDetectedCount;
@property (nonatomic) NSMutableArray *receivedResponses;
@property (nonatomic) NSMutableArray *finishedBackgroundSessions;
@property (nonatomic) NSMutableArray *completedTasks;
@property (nonatomic) NSMutableArray *firedTimers;
@property (nonatomic) MockCertificateTrust *trustProvider;


@end

@interface ZMURLSessionTests (Delegate)
@end
@interface ZMURLSessionTests (TaskGeneration)
@end

static NSString * const TaskKey = @"response";
static NSString * const RequestKey = @"request";
static NSString * const DataKey = @"data";



@implementation ZMURLSessionTests

- (void)setUp
{
    [super setUp];
    
    self.receivedResponses = [NSMutableArray array];
    self.completedTasks = [NSMutableArray array];
    self.firedTimers = [NSMutableArray array];
    self.finishedBackgroundSessions = [NSMutableArray array];
    self.receivedDataCount = 0;
    self.trustProvider = [[MockCertificateTrust alloc] init];

    self.queue = [NSOperationQueue zm_serialQueueWithName:self.name];
    self.sut = (id) [[ZMURLSession alloc] initWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                  trustProvider:self.trustProvider
                                                       delegate:self
                                                  delegateQueue:self.queue
                                                     identifier:@"test-session"
                                                      userAgent:@"TestSession"];

    self.URLRequestA = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://a.example.com/"]];
    self.URLRequestB = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://b.example.com/"]];
    self.taskA = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:nil];
    self.taskB = [self.sut taskWithRequest:self.URLRequestB bodyData:nil transportRequest:nil];
}

- (void)tearDown
{
    self.queue = nil;
    self.receivedResponses = nil;
    self.completedTasks = nil;
    self.finishedBackgroundSessions = nil;
    self.receivedDataCount = 0;
    self.unsafeConnectionDetectedCount = 0;
    self.firedTimers = nil;
    [self.sut tearDown];
    self.sut = nil;
    self.trustProvider = nil;
    [super tearDown];
}

- (void)timerDidFire:(ZMTimer *)timer;
{
    [self.firedTimers addObject:timer];
}

- (void)URLSession:(ZMURLSession *)URLSession dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;
{
    XCTAssertEqual(URLSession, self.sut);
    NOT_USED(dataTask);
    [self.receivedResponses addObject:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSessionDidReceiveData:(ZMURLSession *)URLSession;
{
    XCTAssertEqual(URLSession, self.sut);
    ++self.receivedDataCount;
}

- (void)URLSession:(ZMURLSession *)URLSession didDetectUnsafeConnectionToHost:(NSString *)host
{
    NOT_USED(URLSession);
    NOT_USED(host);
    self.unsafeConnectionDetectedCount += 1;
}

- (void)URLSession:(__unused ZMURLSession *)URLSession taskDidComplete:(NSURLSessionTask *)task transportRequest:(ZMTransportRequest *)transportRequest responseData:(NSData *)responseData;
{
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    if (task != nil) {
        arguments[TaskKey] = task;
    }
    if (transportRequest != nil) {
        arguments[RequestKey] = transportRequest;
    }
    if (responseData != nil) {
        arguments[DataKey] = responseData;
    }
    [self.completedTasks addObject:arguments];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(ZMURLSession *)URLSession
{
    [self.finishedBackgroundSessions addObject:URLSession];
}

- (void)testThatItPassesTheRequestToTheCompletionMethod;
{
    // given
    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:@"/some/path/" apiVersion:0];
    NSURLSessionTask *task = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:request];
    
    // when
    [self.sut URLSession:self.sut.backingSession task:task didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqual(d[RequestKey], request);
}

- (void)testThatUserAgentIsAddedToAdditionalHeaders
{
    XCTAssertEqualObjects(self.sut.configuration.HTTPAdditionalHeaders[@"User-Agent"], @"TestSession");
}

- (void)testThatItCancelsTheTimerWhenTheTaskCompletes;
{
    // given
    ZMTimer *timer = [ZMTimer timerWithTarget:self];
    
    // when
    [self.sut setTimeoutTimer:timer forTask:self.taskA];
    [timer fireAfterTimeInterval:0.05];
    [self.sut URLSession:self.sut.backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    [self spinMainQueueWithTimeout:0.1];
    XCTAssertEqual(self.firedTimers.count, 0u);
    [timer cancel];
}

- (void)testThatItCanAppendDataToADataTask;
{
    // when
    id backingSession = self.sut.backingSession;
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xfe} length:1]];
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xda} length:1]];
    [self.sut URLSession:backingSession dataTask:(id) self.taskA didReceiveData:[NSData dataWithBytes:(uint8_t[]){0xbe} length:1]];
    [self.sut URLSession:backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSData *expectedData = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqualObjects(d[DataKey], expectedData);
}

- (void)testThatItCanDownloadDataWithADownloadTask;
{
    // when
    NSURL *dataLocation = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    dataLocation = [dataLocation URLByAppendingPathComponent:@"downloadTask-test-data"];
    NSData * const data = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    XCTAssert([data writeToURL:dataLocation options:0 error:NULL]);
    
    id backingSession = self.sut.backingSession;
    [self.sut URLSession:backingSession downloadTask:(id) self.taskA didFinishDownloadingToURL:dataLocation];
    XCTAssert([[NSFileManager defaultManager] removeItemAtURL:dataLocation error:NULL]);
    
    [self.sut URLSession:backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqualObjects(d[DataKey], data);
}

- (void)testThatItCancelsAllTimers;
{
    // given
    @autoreleasepool {
        ZMTimer *timerA = [ZMTimer timerWithTarget:(id) self];
        ZMTimer *timerB = [ZMTimer timerWithTarget:(id) self];
        [self.sut setTimeoutTimer:timerA forTask:self.taskA];
        [self.sut setTimeoutTimer:timerB forTask:self.taskB];
        
        // when
        [self.sut cancelAndRemoveAllTimers];
    }
    WaitForAllGroupsToBeEmpty(0.5);
    // This will fail with "ZMTimer was not cleaned up correctly" unless cancel has been called.
}

- (void)testThatItGetsAllRegisteredRequestsForTheURLSession_Resume
{
    [self assertGetAllTasksWithConfiguration:^(NSURLSessionTask *task) {
        [task resume];
    } verifyBlock:^(__unused NSURLSessionTask *task, NSArray<NSURLSessionTask *> *tasks) {
         XCTAssertEqualObjects(@[task], tasks);
    }];
}

- (void)testThatItGetsAllRegisteredRequestsForTheURLSession_Suspend
{
    [self assertGetAllTasksWithConfiguration:^(NSURLSessionTask *task) {
        [task suspend];
    } verifyBlock:^(__unused NSURLSessionTask *task, NSArray<NSURLSessionTask *> *tasks) {
        XCTAssertEqual(tasks.count, 0lu);
    }];
}

- (void)testThatItGetsAllRegisteredRequestsForTheURLSession_Cancel
{
    [self assertGetAllTasksWithConfiguration:^(NSURLSessionTask *task) {
        [task cancel];
    } verifyBlock:^(__unused NSURLSessionTask *task, NSArray<NSURLSessionTask *> *tasks) {
        XCTAssertEqual(tasks.count, 0lu);
    }];
}

- (void)assertGetAllTasksWithConfiguration:(void (^)(NSURLSessionTask *))configurationBlock
                               verifyBlock:(void (^)(NSURLSessionTask *, NSArray<NSURLSessionTask *> *))verifyBlock
{
    // given
    XCTestExpectation *expectation = [self expectationWithDescription:@"It should call the completionHandler"];
    
    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:@"/some/path/" apiVersion:0];
    NSURLSessionTask *task = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:request];
    configurationBlock(task);
    
    // when
    [self.sut getTasksWithCompletionHandler:^(NSArray<NSURLSessionTask *> *tasks) {
        verifyBlock(task, tasks);
        [expectation fulfill];
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end



@implementation ZMURLSessionTests (Delegate)

- (void)testItCallTheDelegateWhenItDetectsAnUnsafeConnection
{
    // given
    self.trustProvider.isTrustingServer = NO;
    
    MockURLAuthenticationChallengeSender* sender = [[MockURLAuthenticationChallengeSender alloc] init];
    MockEnvironment *environment = [[MockEnvironment alloc] init];
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:environment.backendURL.host port:443 protocol:@"https" realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    NSURLAuthenticationChallenge *challenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:nil previousFailureCount:0 failureResponse:nil error:nil sender:sender];
    
    // when
    [self.sut URLSession:self.sut.backingSession didReceiveChallenge:challenge completionHandler:^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential) {
        NOT_USED(disposition);
        NOT_USED(credential);
    }];
    
    // then
    XCTAssertEqual(self.unsafeConnectionDetectedCount, 1);
}

- (void)testThatItCallsTheDelegateWhenItReceivesAResponse;
{
    // given
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://foo.example.com"] MIMEType:@"application/binary" expectedContentLength:1234 textEncodingName:@"utf8"];
    XCTestExpectation *e = [self expectationWithDescription:@"completion handler"];
    
    // when
    [self.sut URLSession:self.sut.backingSession dataTask:(id) self.taskA didReceiveResponse:response completionHandler:^(NSURLSessionResponseDisposition disposition) {
        [e fulfill];
        (void) disposition;
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertEqual(self.receivedResponses.count, 1u);
    XCTAssertEqual(self.receivedResponses.firstObject, response);
}

- (void)testThatItCallsTheDelegateWhenItReceivesData;
{
    // given
    NSData *data = [NSData dataWithBytes:(uint8_t[]){0xfe, 0xda, 0xbe} length:3];
    XCTAssertEqual(self.receivedDataCount, 0u);
    
    // when
    [self.sut URLSession:self.sut.backingSession dataTask:(id) self.taskA didReceiveData:data];
    
    // then
    XCTAssertEqual(self.receivedDataCount, 1u);
}

- (void)testThatItCallsTheDelegateWhenATaskCompletes;
{
    // given
    XCTAssertEqual(self.completedTasks.count, 0u);
    
    // when
    [self.sut URLSession:self.sut.backingSession task:self.taskA didCompleteWithError:nil];
    
    // then
    XCTAssertEqual(self.completedTasks.count, 1u);
    NSDictionary *d = self.completedTasks.firstObject;
    XCTAssertEqual(d[TaskKey], self.taskA);
}

- (void)testThatItDoesNotFollowRedirectsIfSpecified
{
    // given
    NSString *initialURL = @"https://example.com/initial";
    NSString *finalURL = @"https://example.com/final";

    NSMutableURLRequest *originalRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:initialURL]];
    NSURLSessionDataTask *originalTask = [self.sut.backingSession dataTaskWithRequest:originalRequest];
    
    NSURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:finalURL]];
    
    XCTestExpectation *completionHandlerCalled = [self expectationWithDescription:@"Completion handler invoked"];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"foo"] statusCode:302 HTTPVersion:@"1.1" headerFields:@{}];
    
    // when
    ZMTransportRequest *fakeRequest = [ZMTransportRequest requestGetFromPath:@"foo" apiVersion:0];
    fakeRequest.doesNotFollowRedirects = YES;
    [self.sut setRequest:fakeRequest forTask:originalTask];
    
    [self.sut URLSession:self.sut.backingSession
                    task:originalTask
willPerformHTTPRedirection:response
              newRequest:newRequest
       completionHandler:^(NSURLRequest * _Nullable req) {
           XCTAssertNil(req);
           [completionHandlerCalled fulfill];
       }];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0]);
}

- (void)testThatItCallsTheDelegateWhenTheBackgroundURLSessionFinished
{
    // when
    [self.sut URLSessionDidFinishEventsForBackgroundURLSession:self.sut.backingSession];
    
    // then
    XCTAssertEqual(self.finishedBackgroundSessions.count, 1lu);
    XCTAssertEqual(self.finishedBackgroundSessions.firstObject, self.sut);
}

- (void)testThatItCompletesTheRequestWith_TryAgainLater_IfTheProgressDecreaces_ShouldFailInsteadOfRetry_Upload
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:YES shouldFailInsteadOfRetry:YES upload:NO verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertEqualObjects(response.transportSessionError, NSError.tryAgainLaterError);
    }];
}

- (void)testThatItDoesCompleteTheRequestWith_TryAgainLater_IfTheProgressIncreases_ShouldFailInsteadOfRetry_Upload
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:NO shouldFailInsteadOfRetry:YES upload:NO verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)testThatItDoesNotCompleteTheRequestWith_TryAgainLater_IfTheProgressDecreacesAnd_ShouldFailInsteadOfRetry_isNotSet_Upload
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:YES shouldFailInsteadOfRetry:NO upload:NO verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)testThatItDoesNotCompleteTheRequestWith_TryAgainLater_IfTheProgressIncreasesAnd_ShouldFailInsteadOfRetry_isNotSet_Upload
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:NO shouldFailInsteadOfRetry:NO upload:NO verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)testThatItCompletesTheRequestWith_TryAgainLater_IfTheProgressDecreaces_ShouldFailInsteadOfRetry_Download
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:YES shouldFailInsteadOfRetry:YES upload:YES verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertEqualObjects(response.transportSessionError, NSError.tryAgainLaterError);
    }];
}

- (void)testThatItDoesCompleteTheRequestWith_TryAgainLater_IfTheProgressIncreases_ShouldFailInsteadOfRetry_Download
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:NO shouldFailInsteadOfRetry:YES upload:YES verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)testThatItDoesNotCompleteTheRequestWith_TryAgainLater_IfTheProgressDecreacesAnd_ShouldFailInsteadOfRetry_isNotSet_Download
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:YES shouldFailInsteadOfRetry:NO upload:YES verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)testThatItDoesNotCompleteTheRequestWith_TryAgainLater_IfTheProgressIncreasesAnd_ShouldFailInsteadOfRetry_isNotSet_Download
{
    [self checkThatItCompletesTheRequestWhenTheProgressDecreases:NO shouldFailInsteadOfRetry:NO upload:YES verifyBlock:^(ZMTransportResponse *response) {
        XCTAssertNil(response);
    }];
}

- (void)checkThatItCompletesTheRequestWhenTheProgressDecreases:(BOOL)shouldDecrease
                                      shouldFailInsteadOfRetry:(BOOL)shouldFailInsteadOfRetry
                                                        upload:(BOOL)upload
                                                   verifyBlock:(void (^)(ZMTransportResponse *response))verifyBlock
{
    // given
    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:@"www.example.com" apiVersion:0];
    request.shouldFailInsteadOfRetry = shouldFailInsteadOfRetry;
    
    __block ZMTransportResponse *receivedResponse;
    [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.fakeSyncContext block:^(ZMTransportResponse *response) {
        receivedResponse = response;
    }]];
    
    NSURLSessionTask *task = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:request];
    [task resume];
    int64_t totalBytes = shouldDecrease ? 2500 : 5000;
    
    // when
    if (upload) {
        NSURLSessionDownloadTask *downloadTask = (NSURLSessionDownloadTask *)task;
        [self.sut URLSession:self.sut.backingSession downloadTask:downloadTask didWriteData:4000 totalBytesWritten:4000 totalBytesExpectedToWrite:6000];
        [self.sut URLSession:self.sut.backingSession downloadTask:downloadTask didWriteData:totalBytes totalBytesWritten:totalBytes totalBytesExpectedToWrite:6000];
    } else {
        [self.sut URLSession:self.sut.backingSession task:task didSendBodyData:4000 totalBytesSent:4000 totalBytesExpectedToSend:6000];
        [self.sut URLSession:self.sut.backingSession task:task didSendBodyData:totalBytes totalBytesSent:totalBytes totalBytesExpectedToSend:6000];
    }
    
    // then
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    if (shouldDecrease && shouldFailInsteadOfRetry) {
        XCTAssertNotNil(receivedResponse);
        verifyBlock(receivedResponse);
    } else {
        verifyBlock(nil);
    }
}

@end



@implementation ZMURLSessionTests (TaskGeneration)

- (void)setupMockBackgroundSession
{    
    self.sut = (id) [[ZMURLSession alloc] initWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] trustProvider:self.trustProvider delegate:self delegateQueue:self.queue identifier:ZMURLSessionBackgroundIdentifier userAgent:@"TestSession"];
    self.sut.backingSession = [OCMockObject niceMockForClass:NSURLSession.class];
    
    [(NSURLSession *)[[(id)self.sut.backingSession stub] andReturn:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"test-session"]] configuration];
    
    [(id) self.sut.backingSession verify];
}

- (void)setupBackgroundSession;
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"test-session"];
    [self.sut tearDown];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    self.sut = (id) [[ZMURLSession alloc] initWithConfiguration:configuration trustProvider:self.trustProvider delegate:self delegateQueue:self.queue identifier:ZMURLSessionBackgroundIdentifier userAgent:@"TestSession"];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    self.URLRequestA = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://a.example.com/"]];
    self.URLRequestB = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://b.example.com/"]];
    self.taskA = [self.sut taskWithRequest:self.URLRequestA bodyData:nil transportRequest:nil];
    self.taskB = [self.sut taskWithRequest:self.URLRequestB bodyData:nil transportRequest:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
}

- (void)testThatItDetectsAForegroundSession;
{
    XCTAssertFalse(self.sut.isBackgroundSession);
}

- (void)testThatItDetectsABackgroundSession;
{
    // given
    [self setupBackgroundSession];
    
    // then
    XCTAssertTrue(self.sut.isBackgroundSession);
}

- (void)testThatItCreatesADataTask;
{
    // given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baz.example.com/1/"]];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:nil transportRequest:nil];
    
    // then
    XCTAssertNotNil(task);
    XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
    XCTAssertTrue([task isKindOfClass:NSURLSessionDataTask.class]);
    XCTAssertEqualObjects(task.originalRequest, request);
}

- (void)testThatItCreatesADownloadTaskForBackgroundSession;
{
    [self performIgnoringZMLogError:^{
        // given
        [self setupBackgroundSession];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baz.example.com/1/"]];
        
        // when
        NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:nil transportRequest:nil];
        
        // then
        XCTAssertNotNil(task);
        XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
        XCTAssertTrue([task isKindOfClass:NSURLSessionDownloadTask.class]);
        XCTAssertEqualObjects(task.originalRequest, request);
    }];
}

- (void)testThatItCreatesAnUploadTask;
{
    // given
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // then
    XCTAssertNotNil(task);
    XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
    XCTAssertTrue([task isKindOfClass:NSURLSessionUploadTask.class]);
    XCTAssertEqualObjects(task.originalRequest, request);
}

- (void)testThatItCreatesATemporaryFileForABackgroundRequest
{
    // given
    [self setupMockBackgroundSession];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];
    
    self.sut.temporaryFiles = [OCMockObject mockForClass:ZMTemporaryFileListForBackgroundRequests.class];
    
    // expect
    NSURL *fileURL = [NSURL fileURLWithPath:@"foo"];
    [[[(id)self.sut.temporaryFiles expect] andReturn:fileURL] temporaryFileWithBodyData:bodyData];
    [[[(id)self.sut.temporaryFiles expect] ignoringNonObjectArgs] setTemporaryFile:fileURL forTaskIdentifier:1];
    
    // when
    [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // then
    [(id)self.sut.temporaryFiles verify];
}

- (void)testThatItDeletesATemporaryFileForABackgroundRequest
{
    // given
    [self setupMockBackgroundSession];
    
    NSUInteger taskID = 4u;
    NSURL *fileURL = [NSURL fileURLWithPath:@"foo"];
    NSURLSessionTask *mockTask = [OCMockObject niceMockForClass:FakeDataTask.class];
    [[[(id)mockTask stub] andReturnValue:OCMOCK_VALUE(taskID)] taskIdentifier];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baz.example.com/1/"]];
    NSData *bodyData = [NSData dataWithBytes:(uint8_t[]){1, 2, 3} length:3];

    self.sut.temporaryFiles = [OCMockObject mockForClass:ZMTemporaryFileListForBackgroundRequests.class];
    [[[(id)self.sut.backingSession expect] andReturn:mockTask] uploadTaskWithRequest:OCMOCK_ANY fromFile:fileURL];
    
    // expect
    [[[(id)self.sut.temporaryFiles expect] andReturn:fileURL] temporaryFileWithBodyData:bodyData];
    [[[(id)self.sut.temporaryFiles expect] ignoringNonObjectArgs] setTemporaryFile:fileURL forTaskIdentifier:1];
    
    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:bodyData transportRequest:nil];
    
    // expect
    [[(id)self.sut.temporaryFiles expect] deleteFileForTaskID:task.taskIdentifier];
    
    // when
    [self.sut URLSession:self.sut.backingSession task:task didCompleteWithError:nil];
    
    // then
    [(id)self.sut.temporaryFiles verify];
}

- (void)testThatItCreatesAnUploadTasksForRequestsWithFileURL
{
    // given
    [self.sut tearDown];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"test-session"];
    self.sut = (id) [[ZMURLSession alloc] initWithConfiguration:configuration trustProvider:self.trustProvider delegate:self delegateQueue:self.queue identifier:ZMURLSessionBackgroundIdentifier userAgent:@"TestSession"];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];

    NSString *path = @"https://baz.example.com/1/";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
    NSString *contentType = @"multipart/mixed; boundary=frontier";
    ZMTransportRequest *transportRequest = [ZMTransportRequest uploadRequestWithFileURL:self.uniqueFileURL path:path contentType:contentType apiVersion:0];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];

    // when
    NSURLSessionTask *task = [self.sut taskWithRequest:request bodyData:nil transportRequest:transportRequest];
    
    // then
    XCTAssertTrue([task isKindOfClass:NSURLSessionUploadTask.class]);
    XCTAssertEqualObjects(task.originalRequest, request);
    XCTAssertEqual(task.state, NSURLSessionTaskStateSuspended);
    WaitForAllGroupsToBeEmpty(0.5);
}

- (NSURL *)uniqueFileURL
{
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName = [NSUUID.createUUID.transportString stringByAppendingPathExtension:@"txt"];
    NSURL *fileURL = [NSURL fileURLWithPath:[documents stringByAppendingPathComponent:fileName]];
    NSError *error = nil;
    XCTAssertTrue([@"🔒" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error]);
    XCTAssertNil(error);
    return fileURL;
}

@end
