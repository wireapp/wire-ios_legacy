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


@import WireUtilities;

#import "ZMURLSession+Internal.h"

#import "NSError+ZMTransportSession.h"
#import "ZMTaskIdentifierMap.h"
#import "ZMTemporaryFileListForBackgroundRequests.h"
#import "ZMTransportRequest+Internal.h"
#import "ZMTLogging.h"
#import "ZMTransportResponse.h"
#import <WireTransport/WireTransport-Swift.h>



static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK_LOW_LEVEL;


static NSUInteger const ZMTransportDecreasedProgressCancellationLeeway = 1024 * 2;
NSString * const ZMURLSessionBackgroundIdentifier = @"background-session";
NSString * const ZMURLSessionForegroundIdentifier = @"foreground-session";
NSString * const ZMURLSessionVoipIdentifier = @"voip-session";

@interface ZMURLSession ()

@property (nonatomic, readonly) ZMTaskIdentifierMap *taskIdentifierToRequest;
@property (nonatomic, readonly) ZMTaskIdentifierMap *taskIdentifierToTimeoutTimer;
@property (nonatomic, readonly) ZMTaskIdentifierMap *taskIdentifierToData;

@property (nonatomic, weak) id<ZMURLSessionDelegate> delegate;
@property (nonatomic, readwrite) NSString *identifier;

@property (nonatomic, strong) id<BackendTrustProvider> trustProvider;

@property (nonatomic) NSURLSession *backingSession;
@property (nonatomic) ZMTemporaryFileListForBackgroundRequests *temporaryFiles;

@property (nonatomic) BOOL tornDown;
@end



@interface ZMURLSession (SessionDelegate) <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@end



@implementation ZMURLSession

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithDelegate:(id<ZMURLSessionDelegate>)delegate identifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        _taskIdentifierToTimeoutTimer = [[ZMTaskIdentifierMap alloc] init];
        _taskIdentifierToRequest = [[ZMTaskIdentifierMap alloc] init];
        _taskIdentifierToData = [[ZMTaskIdentifierMap alloc] init];
        self.identifier = identifier;
        self.temporaryFiles = [[ZMTemporaryFileListForBackgroundRequests alloc] init];
    }
    return self;
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                        trustProvider:(id<BackendTrustProvider>)trustProvider
                             delegate:(id<ZMURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)queue
                           identifier:(NSString *)identifier
                            userAgent:(NSString *)userAgent
{
    Require(configuration != nil);
    Require(delegate != nil);
    Require(queue != nil);
    self = [self initWithDelegate:delegate identifier:identifier];
    if(self) {
        configuration.HTTPAdditionalHeaders = @{ @"User-Agent": userAgent };
        self.backingSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        self.backingSession.sessionDescription = identifier;
        self.trustProvider = trustProvider;
    }
    return self;
}

- (void)dealloc
{
    RequireString(self.tornDown, "Did not tear down %p", (__bridge void *) self);
}

- (void)tearDown
{
    self.tornDown = YES;
    [self cancelAndRemoveAllTimers];
    [self.backingSession invalidateAndCancel];
}

- (void)setRequest:(ZMTransportRequest *)request forTask:(NSURLSessionTask *)task;
{
    VerifyReturn(request != nil);
    VerifyReturn(task != nil);
    self.taskIdentifierToRequest[task.taskIdentifier] = request;
}

- (ZMTransportRequest *)requestForTask:(NSURLSessionTask *)task;
{
    VerifyReturnNil(task != nil);
    return self.taskIdentifierToRequest[task.taskIdentifier];
}

- (void)setTimeoutTimer:(ZMTimer *)timer forTask:(NSURLSessionTask *)task;
{
    VerifyReturn(task != nil);
    if (timer != nil) {
        self.taskIdentifierToTimeoutTimer[task.taskIdentifier] = timer;
    } else {
        [self.taskIdentifierToTimeoutTimer removeObjectForTaskIdentifier:task.taskIdentifier];
    }
}

- (ZMTimer *)timeoutTimerForTask:(NSURLSessionTask *)task;
{
    VerifyReturnNil(task != nil);
    return self.taskIdentifierToTimeoutTimer[task.taskIdentifier];
}

- (void)appendData:(NSData *)data forTask:(NSURLSessionTask *)task;
{
    VerifyReturn(data != nil);
    VerifyReturn(task != nil);
    NSMutableData *allData = self.taskIdentifierToData[task.taskIdentifier];
    if (allData == nil) {
        allData = [NSMutableData data];
        self.taskIdentifierToData[task.taskIdentifier] = allData;
    } else {
        Require([allData isKindOfClass:NSMutableData.class]); // Multiple callbacks ?!?
    }
    [allData appendData:data];
}

- (NSData *)dataForTask:(NSURLSessionTask *)task;
{
    VerifyReturnNil(task != nil);
    return self.taskIdentifierToData[task.taskIdentifier];
}

- (void)removeTask:(NSURLSessionTask *)task;
{
    VerifyReturn(task != nil);
    [self.taskIdentifierToRequest removeObjectForTaskIdentifier:task.taskIdentifier];
    [self.taskIdentifierToTimeoutTimer removeObjectForTaskIdentifier:task.taskIdentifier];
    [self.taskIdentifierToData removeObjectForTaskIdentifier:task.taskIdentifier];
    [self.temporaryFiles deleteFileForTaskID:task.taskIdentifier];
}

- (NSString *)description;
{
    NSMutableArray *runningRequests = [NSMutableArray array];
    [self.taskIdentifierToRequest enumerateKeysAndObjectsUsingBlock:^(NSUInteger taskIdentifier, ZMTransportRequest *request, BOOL *stop) {
        NOT_USED(stop);
        [runningRequests addObject:[NSString stringWithFormat:@"%llu -> %@",
                                    (unsigned long long) taskIdentifier, request]];
    }];
    NSMutableArray *receivedData = [NSMutableArray array];
    [self.taskIdentifierToData enumerateKeysAndObjectsUsingBlock:^(NSUInteger taskIdentifier, NSData *data, BOOL *stop) {
        NOT_USED(stop);
        [receivedData addObject:[NSString stringWithFormat:@"%llu -> %llu bytes",
                                 (unsigned long long) taskIdentifier, (unsigned long long) data.length]];
    }];
    return [NSString stringWithFormat:@"<%@: %p>\nSession '%@' running requests: {\n\t%@\n}\ndownloaded data: {\n\t%@\n}, \nconfiguration: %@",
            self.class, self,
            self.identifier,
            [runningRequests componentsJoinedByString:@"\n\t"],
            [receivedData componentsJoinedByString:@"\n\t"],
            self.configuration.configurationDump
            ];
}

- (void)cancelAndRemoveAllTimers;
{
    ZMLogDebug(@"-- <%@ %p> %@", self.class, self, NSStringFromSelector(_cmd));
    [self.taskIdentifierToTimeoutTimer enumerateKeysAndObjectsUsingBlock:^(NSUInteger taskIdentifier, ZMTimer *timer, BOOL *stop) {
        NOT_USED(taskIdentifier);
        NOT_USED(stop);
        [timer cancel];
    }];
    [self.taskIdentifierToTimeoutTimer removeAllObjects];
}

- (void)cancelAllTasksWithCompletionHandler:(dispatch_block_t)handler;
{
    ZMLogDebug(@"-- <%@ %p> %@", self.class, self, NSStringFromSelector(_cmd));
    [self.backingSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSArray *allTasks = [[dataTasks arrayByAddingObjectsFromArray:uploadTasks] arrayByAddingObjectsFromArray:downloadTasks];
        for (NSURLSessionTask *task in allTasks) {
            ZMLogDebug(@"@Task cancelled: %@", task);
            [task cancel];
        }
        handler();
    }];
}

- (void)getTasksWithCompletionHandler:(void (^)(NSArray <NSURLSessionTask *>*))completionHandler
{
    [self.backingSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSMutableArray <NSURLSessionTask *> *allTasks = [NSMutableArray new];
        [allTasks addObjectsFromArray:dataTasks];
        [allTasks addObjectsFromArray:uploadTasks];
        [allTasks addObjectsFromArray:downloadTasks];
        completionHandler(allTasks);
    }];
}


- (void)countTasksWithCompletionHandler:(void(^)(NSUInteger count))handler;
{
    [self.backingSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSUInteger count = dataTasks.count + uploadTasks.count + downloadTasks.count;
        handler(count);
    }];
}

- (void)cancelTaskWithIdentifier:(NSUInteger)taskIdentifier completionHandler:(void(^)(BOOL))handler;
{
    [self.backingSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        __block BOOL canceled = NO;
        BOOL (^findTask)(NSArray *) = ^(NSArray *tasks){
            for (NSURLSessionTask *t in tasks) {
                if (t.taskIdentifier == taskIdentifier) {
                    canceled = YES;
                    [t cancel];
                    return YES;
                }
            }
            return NO;
        };
        
        if (! findTask(dataTasks)) {
            if (! findTask(uploadTasks)) {
                if (! findTask(downloadTasks)) {
                    ZMLogDebug(@"Unable to cancel task with ID %llu. Not found.", (unsigned long long) taskIdentifier);
                }
            }
        }
        if (handler != nil) {
            handler(canceled);
        }
    }];
}

- (NSURLSessionConfiguration *)configuration;
{
    return self.backingSession.configuration;
}

@end



@implementation ZMURLSession (SessionDelegate)

- (void)URLSession:(NSURLSession *)URLSession downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;
{
    NOT_USED(URLSession);
    ZMLogDebug(@"-- <%@ %p> %@", self.class, self, NSStringFromSelector(_cmd));
    Check(URLSession == self.backingSession);
    NSError *error = nil;
    NSData *data = [[NSData alloc] initWithContentsOfURL:location options:NSDataReadingUncached error:&error];
    VerifyString(data != nil, "Failed to read downloaded data: %lu", (long) error.code);
    if (data != nil) {
        self.taskIdentifierToData[downloadTask.taskIdentifier] = data;
    }
}

- (void)URLSession:(NSURLSession *)URLSession didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;
{
    NOT_USED(URLSession);
    Check(URLSession == self.backingSession);
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        BOOL const didTrust = [self.trustProvider verifyServerTrustWithTrust:protectionSpace.serverTrust host:protectionSpace.host];
        if (! didTrust) {
            ZMLogDebug(@"Not trusting the server.");
            [self.delegate URLSession:self didDetectUnsafeConnectionToHost:protectionSpace.host];
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
    }
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, challenge.proposedCredential);
}

- (void)URLSession:(NSURLSession *)URLSession dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;
{
    NOT_USED(URLSession);
    Check(URLSession == self.backingSession);
    
    [self.delegate URLSession:self dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession * __unused)session
              task:(NSURLSessionTask * __unused)task
willPerformHTTPRedirection:(NSHTTPURLResponse * __unused)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    ZMTransportRequest *orginalRequest = [self requestForTask:task];
    if (orginalRequest.doesNotFollowRedirects) {
        if (completionHandler) {
            completionHandler(nil);
        }
        return;
    }
    
    if (completionHandler) {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)URLSession dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
{
    NOT_USED(URLSession);
    Check(URLSession == self.backingSession);
    [self appendData:data forTask:dataTask];
    [self.delegate URLSessionDidReceiveData:self];
}

- (void)URLSession:(NSURLSession *)URLSession task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
{
    NOT_USED(URLSession);
    ZMLogDebug(@"-- <%@ %p> %@ -> %@ %@, error: %@", self.class, self, NSStringFromSelector(_cmd), task.originalRequest.URL, task.response, error);
    
    Check(URLSession == self.backingSession);
    NSObject<ZMURLSessionDelegate> *delegate = (id) self.delegate;
    ZMLogDebug(@"-- <%@ %p> delegate <%@: %p>", self.class, self, delegate.class, delegate);
    [delegate URLSession:self
         taskDidComplete:task
        transportRequest:[self requestForTask:task]
            responseData:[self dataForTask:task]];
    
    ZMTimer *timeoutTimer = [self timeoutTimerForTask:task];
    [timeoutTimer cancel];
    
    [self removeTask:task];
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NOT_USED(session);
    ZMLogDebug(@"-- <%@ %p> %@ -> %@ %@", self.class, self, NSStringFromSelector(_cmd), session, session.configuration.identifier);
    
    Check(session == self.backingSession);
    NSObject<ZMURLSessionDelegate> *delegate = (id) self.delegate;
    [delegate URLSessionDidFinishEventsForBackgroundURLSession:self];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NOT_USED(session);
    NOT_USED(bytesWritten);

    ZMTransportRequest *request = [self requestForTask:downloadTask];
    float progress = 0;
    if (totalBytesWritten != 0 && totalBytesExpectedToWrite != 0) {
        progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        
        BOOL didFailRestartedRequest = [self completeRestartedRequestIfNeeded:request
                                                                     progress:progress
                                                                   totalBytes:totalBytesWritten
                                                           totalBytesExpected:totalBytesExpectedToWrite];
        
        if (didFailRestartedRequest) {
            return;
        }
    }
    
    [request updateProgress:progress];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NOT_USED(session);
    NOT_USED(bytesSent);

    if (task.state == NSURLSessionTaskStateCanceling) {
        return;
    }

    ZMTransportRequest *request = [self requestForTask:task];
    float progress = 0;
    
    if (totalBytesSent != 0 && totalBytesExpectedToSend != 0) {
        progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
        
        BOOL didFailRestartedRequest = [self completeRestartedRequestIfNeeded:request
                                                                     progress:progress
                                                                   totalBytes:totalBytesSent
                                                           totalBytesExpected:totalBytesExpectedToSend];
        
        if (didFailRestartedRequest) {
            [task cancel];
            return;
        }
    }
    
    [request updateProgress:progress];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
    NOT_USED(session);
    NOT_USED(task);
    if (nil != metrics.transactionMetrics.firstObject) {
        ZMLogInfo(@"Reused connection: %d", metrics.transactionMetrics.firstObject.reusedConnection);
    }
}

- (BOOL)completeRestartedRequestIfNeeded:(ZMTransportRequest *)request
                                progress:(float)progress
                              totalBytes:(int64_t)totalBytes
                      totalBytesExpected:(int64_t)totalBytesExpected
{
    if (!request.shouldFailInsteadOfRetry || request.progress == 0) {
        return NO;
    }
    
    if (progress < request.progress) {
        float failureThresholdProgress = (float)totalBytes + ZMTransportDecreasedProgressCancellationLeeway / (float)totalBytesExpected;
        if (progress < failureThresholdProgress) {
            [request completeWithResponse:[ZMTransportResponse responseWithTransportSessionError:NSError.tryAgainLaterError apiVersion:request.apiVersion]];
            return YES;
        }
    }
    return NO;
}

@end



@implementation ZMURLSession (TaskGeneration)

- (BOOL)isBackgroundSession;
{
    return [self.identifier hasPrefix:ZMURLSessionBackgroundIdentifier];
}

- (NSURLSessionTask *)taskWithRequest:(NSURLRequest *)request bodyData:(NSData *)bodyData transportRequest:(ZMTransportRequest *)transportRequest;
{
    NSURLSessionTask *task;
    
    if (self.tornDown) {
        ZMLogError(@"%@: cannot create the task for request (%@), isTornDown = %d", self, request, self.tornDown);
        return nil;
    }
    
    if (nil != transportRequest.fileUploadURL) {
        RequireString(self.isBackgroundSession, "File uploads need to set 'forceToBackgroundSession' on the request");
        task = [self.backingSession uploadTaskWithRequest:request fromFile:transportRequest.fileUploadURL];
        ZMLogDebug(@"Created file upload task: %@, url: %@", task, transportRequest.fileUploadURL);
    }
    else if (self.isBackgroundSession) {
         if (bodyData != nil) {
            NSURL *fileURL = [self.temporaryFiles temporaryFileWithBodyData:bodyData];
            VerifyReturnNil(fileURL != nil);
            task = [self.backingSession uploadTaskWithRequest:request fromFile:fileURL];
            [self.temporaryFiles setTemporaryFile:fileURL forTaskIdentifier:task.taskIdentifier];
        } else {
            task = [self.backingSession downloadTaskWithRequest:request];
        }
        ZMLogDebug(@"Created background task: %@ %@ %@", task, task.originalRequest.HTTPMethod, task.originalRequest.URL);
    }
    else {
        if (bodyData != nil) {
            task = [self.backingSession uploadTaskWithRequest:request fromData:bodyData];
        } else {
            task = [self.backingSession dataTaskWithRequest:request];
        }
    }
    
    if (transportRequest != nil) {
        [self setRequest:transportRequest forTask:task];
    }
    
    [transportRequest callTaskCreationHandlersWithIdentifier:task.taskIdentifier sessionIdentifier:self.identifier];
    return task;
}

@end
