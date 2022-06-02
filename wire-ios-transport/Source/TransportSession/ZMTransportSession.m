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


@import WireSystem;
@import WireUtilities;
@import UIKit;

#import <WireTransport/WireTransport-Swift.h>

#import "ZMTransportSession+internal.h"
#import "ZMTransportCodec.h"
#import "ZMTransportRequest+Internal.h"
#import "ZMPersistentCookieStorage.h"
#import "ZMPushChannelConnection.h"
#import "ZMTaskIdentifierMap.h"
#import "ZMReachability.h"
#import "Collections+ZMTSafeTypes.h"
#import "ZMTransportPushChannel.h"
#import "NSError+ZMTransportSession.h"
#import "ZMUserAgent.h"
#import "ZMURLSession.h"
#import <libkern/OSAtomic.h>
#import "ZMTLogging.h"
#import "NSData+Multipart.h"
#import "ZMTaskIdentifier.h"


static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK;

NSString * const ZMTransportSessionNewRequestAvailableNotification = @"ZMTransportSessionNewRequestAvailable";

static NSString * const TaskTimerKey = @"task";
static NSString * const SessionTimerKey = @"session";
static NSInteger const DefaultMaximumRequests = 6;


@interface ZMTransportSession () <ZMAccessTokenHandlerDelegate, ZMTimerClient>

@property (nonatomic) Class pushChannelClass;
@property (nonatomic) BOOL applicationIsBackgrounded;
@property (nonatomic) BOOL shouldKeepWebsocketOpen;

@property (atomic) BOOL firstRequestFired;
@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSURL *websocketURL;
@property (nonatomic) id<BackendEnvironmentProvider> environment;
@property (nonatomic) NSOperationQueue *workQueue;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic) BOOL tornDown;
@property (nonatomic) NSString *applicationGroupIdentifier;

@property (nonatomic) id<ZMPushChannelType> transportPushChannel;

@property (nonatomic, weak) id<ZMPushChannelConsumer> pushChannelConsumer;
@property (nonatomic, weak) id<ZMSGroupQueue> pushChannelGroupQueue;

@property (nonatomic, readonly) ZMSDispatchGroup *workGroup;
@property (nonatomic, readonly) ZMTransportRequestScheduler *requestScheduler;

@property (nonatomic) ZMAccessTokenHandler *accessTokenHandler;

@property (nonatomic) NSMutableSet *expiredTasks;
@property (nonatomic) id<URLSessionsDirectory, TearDownCapable> sessionsDirectory;
@property (nonatomic, weak) id<ZMNetworkStateDelegate> weakNetworkStateDelegate;
@property (nonatomic) NSMutableDictionary <NSString *, dispatch_block_t> *completionHandlerBySessionID;

@property (nonatomic) id<RequestRecorder> requestLoopDetection;
@property (nonatomic, readwrite) id<ReachabilityProvider, TearDownCapable> reachability;
@property (nonatomic) id reachabilityObserverToken;
@property (nonatomic) ZMAtomicInteger *numberOfRequestsInProgress;

@end



@implementation ZMTransportSession

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should not use -init" userInfo:nil];
    return [self initWithEnvironment:nil
                       cookieStorage:nil
                        reachability:nil
                  initialAccessToken:nil
          applicationGroupIdentifier:nil
                  applicationVersion:@"1.0"];
}

+ (void)setUpConfiguration:(NSURLSessionConfiguration *)configuration;
{
    // Don't accept any cookies. We store these ourselves.
    configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
    
    // Turn on HTTP pipelining
    // RFC 2616 recommends no more than 2 connections per host when using pipelining.
    // https://tools.ietf.org/html/rfc2616
    configuration.HTTPShouldUsePipelining = YES;
    configuration.HTTPMaximumConnectionsPerHost = 1;
    
    configuration.TLSMinimumSupportedProtocol = kTLSProtocol12;
    
    configuration.URLCache = nil;
}

+ (NSURLSessionConfiguration *)foregroundSessionConfiguration
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // If not data is transmitted for this amount of time for a request, it will time out.
    // <https://wearezeta.atlassian.net/browse/MEC-622>.
    // Note that it is ok for the request to take longer, we just require there to be _some_ data to be transmitted within this time window.
    configuration.timeoutIntervalForRequest = 60;
    
    // This is a conservative (!) upper bound for a requested resource:
    configuration.timeoutIntervalForResource = 12 * 60;
    
    // NB.: that TCP will on it's own retry. We should be very careful not to stop a request too early. It is better for a request to complete after 50 s (on a high latency network) in stead of continuously trying and timing out after 30 s.
    
    [self setUpConfiguration:configuration];
    return configuration;
}

+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithSharedContainerIdentifier:(NSString *)sharedContainerIdentifier userIdentifier:(NSUUID *)userIdentifier
{
    NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    NSString *resolvedBundleIdentifier = bundleIdentifier ? bundleIdentifier : @"com.wire.background-session";
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[ZMTransportSession identifierWithPrefix:resolvedBundleIdentifier userIdentifier:userIdentifier]];
    [self setUpConfiguration:configuration];
    configuration.sharedContainerIdentifier = sharedContainerIdentifier;
    return configuration;
}

+ (NSURLSessionConfiguration *)voipSessionConfiguration
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForRequest = 60; 
    configuration.timeoutIntervalForResource = 12 * 60;
    configuration.networkServiceType = NSURLNetworkServiceTypeVoIP;
    [self setUpConfiguration:configuration];
    return configuration;
}

+ (NSString *)identifierWithPrefix:(NSString *)prefix userIdentifier:(NSUUID *)userIdentifier
{
    return [NSString stringWithFormat:@"%@-%@", prefix, userIdentifier.transportString];
}

- (instancetype)initWithEnvironment:(id<BackendEnvironmentProvider>)environment
                      cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       reachability:(id<ReachabilityProvider, TearDownCapable>)reachability
                 initialAccessToken:(ZMAccessToken *)initialAccessToken
         applicationGroupIdentifier:(NSString *)applicationGroupIdentifier
                  applicationVersion:(NSString *)appliationVersion
{
    NSString *userAgent = [ZMUserAgent userAgentWithAppVersion:appliationVersion];
    NSUUID *userIdentifier = cookieStorage.userIdentifier;
    NSOperationQueue *queue = [NSOperationQueue zm_serialQueueWithName:[ZMTransportSession identifierWithPrefix:@"ZMTransportSession" userIdentifier:userIdentifier]];
    ZMSDispatchGroup *group = [ZMSDispatchGroup groupWithLabel:[ZMTransportSession identifierWithPrefix:@"ZMTransportSession init" userIdentifier:userIdentifier]];
    
    NSString *foregroundIdentifier = [ZMTransportSession identifierWithPrefix:ZMURLSessionForegroundIdentifier userIdentifier:userIdentifier];
    ZMURLSession *foregroundSession = [[ZMURLSession alloc] initWithConfiguration:[[self class] foregroundSessionConfiguration] trustProvider:environment delegate:self delegateQueue:queue identifier:foregroundIdentifier userAgent:userAgent];
    
    NSString *backgroundIdentifier = [ZMTransportSession identifierWithPrefix:ZMURLSessionBackgroundIdentifier userIdentifier:userIdentifier];
    NSURLSessionConfiguration *backgroundSessionConfiguration = [[self class] backgroundSessionConfigurationWithSharedContainerIdentifier:applicationGroupIdentifier userIdentifier:userIdentifier];
    ZMURLSession *backgroundSession = [[ZMURLSession alloc] initWithConfiguration:backgroundSessionConfiguration trustProvider:environment delegate:self delegateQueue:queue identifier:backgroundIdentifier  userAgent:userAgent];
    NSString *voipIdentifier = [ZMTransportSession identifierWithPrefix:ZMURLSessionVoipIdentifier userIdentifier:userIdentifier];
    ZMURLSession *voipSession = [[ZMURLSession alloc] initWithConfiguration:[[self class] voipSessionConfiguration] trustProvider:environment delegate:self delegateQueue:queue identifier:voipIdentifier  userAgent:userAgent];

    ZMTransportRequestScheduler *scheduler = [[ZMTransportRequestScheduler alloc] initWithSession:self operationQueue:queue group:group reachability:reachability];
    
    CurrentURLSessionsDirectory *sessionsDirectory = [[CurrentURLSessionsDirectory alloc]
                                                      initWithForegroundSession:foregroundSession
                                                      backgroundSession:backgroundSession
                                                      voipSession:voipSession
                                                      ];

    return [self initWithURLSessionsDirectory:sessionsDirectory
                             requestScheduler:scheduler
                                 reachability:reachability
                                        queue:queue
                                        group:group
                                  environment:environment
                                cookieStorage:cookieStorage
                           initialAccessToken:initialAccessToken
                                    userAgent:userAgent];
}

- (instancetype)initWithURLSessionsDirectory:(id<URLSessionsDirectory, TearDownCapable>)directory
                            requestScheduler:(ZMTransportRequestScheduler *)requestScheduler
                                reachability:(id<ReachabilityProvider, TearDownCapable>)reachability
                                       queue:(NSOperationQueue *)queue
                                       group:(ZMSDispatchGroup *)group
                                 environment:(id<BackendEnvironmentProvider>)environment
                               cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                          initialAccessToken:(ZMAccessToken *)initialAccessToken
                                   userAgent:(NSString *)userAgent
{
    return [self initWithURLSessionsDirectory:directory
                             requestScheduler:requestScheduler
                                 reachability:reachability
                                        queue:queue
                                        group:group
                                  environment:environment
                             pushChannelClass:nil
                                cookieStorage:cookieStorage
                           initialAccessToken:initialAccessToken
                                    userAgent:userAgent];
}


- (instancetype)initWithURLSessionsDirectory:(id<URLSessionsDirectory, TearDownCapable>)directory
                            requestScheduler:(ZMTransportRequestScheduler *)requestScheduler
                                reachability:(id<ReachabilityProvider, TearDownCapable>)reachability
                                       queue:(NSOperationQueue *)queue
                                       group:(ZMSDispatchGroup *)group
                                 environment:(id<BackendEnvironmentProvider>)environment
                            pushChannelClass:(Class)pushChannelClass
                               cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                          initialAccessToken:(ZMAccessToken *)initialAccessToken
                                   userAgent:(NSString *)userAgent
{
    self = [super init];
    if (self) {
        self.environment = environment;
        self.baseURL = environment.backendURL;
        self.websocketURL = environment.backendWSURL;
        self.numberOfRequestsInProgress = [[ZMAtomicInteger alloc] initWithInteger:0];
        
        self.workQueue = queue;
        _workGroup = group;
        self.cookieStorage = cookieStorage;
        self.expiredTasks = [NSMutableSet set];
        self.completionHandlerBySessionID = [NSMutableDictionary new];
        self.sessionsDirectory = directory;
        
        _requestScheduler = requestScheduler;
        self.reachability = reachability;
        self.requestScheduler.schedulerState = ZMTransportRequestSchedulerStateNormal;
        self.reachabilityObserverToken = [self.reachability addReachabilityObserver:self queue:self.workQueue];
        
        if( ! self.reachability.mayBeReachable) {
            [self schedulerWentOffline:self.requestScheduler];
        }
        
        self.maximumConcurrentRequests = DefaultMaximumRequests;

        if (pushChannelClass == nil) {
            if (@available(iOS 13.0, *)) {
                pushChannelClass = StarscreamPushChannel.class;
            } else {
                pushChannelClass = ZMTransportPushChannel.class;
            }
        }
        self.transportPushChannel = [[pushChannelClass alloc] initWithScheduler:self.requestScheduler
                                                                userAgentString:userAgent
                                                                    environment:environment
                                                                          queue:queue];

        self.firstRequestFired = NO;
        self.accessTokenHandler = [[ZMAccessTokenHandler alloc] initWithBaseURL:self.baseURL
                                                                  cookieStorage:self.cookieStorage
                                                                       delegate:self
                                                                          queue:queue
                                                                          group:group
                                                                        backoff:nil
                                                             initialAccessToken:initialAccessToken];
        ZM_WEAK(self);
        self.requestLoopDetection = [[RequestLoopDetection alloc] initWithTriggerCallback:^(NSString * _Nonnull path) {
            ZM_STRONG(self);
            if(self.requestLoopDetectionCallback != nil) {
                self.requestLoopDetectionCallback(path);
            }
        }];
    }
    return self;
}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tornDown = YES;
    
    self.reachabilityObserverToken = nil;
    [self.transportPushChannel close];
    [self.workGroup enter];
    [self.workQueue addOperationWithBlock:^{
        [self.requestScheduler tearDown];
        [self.sessionsDirectory tearDown];
        [self.workGroup leave];
    }];
    
    // Wait until all the requests have been cancelled
    [self.workQueue waitUntilAllOperationsAreFinished];
}

#if DEBUG
- (void)dealloc
{
    RequireString(self.tornDown, "Did not call tearDown on %p", (__bridge void *) self);
}
#endif

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> %@ / %@",
            self.class, self,
            self.baseURL, self.websocketURL];
}

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler;
{
    [self.accessTokenHandler setAccessTokenRenewalFailureHandler:handler];

}

- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler
{
    [self.accessTokenHandler setAccessTokenRenewalSuccessHandler:handler];
}

- (ZMAccessToken *)accessToken {
    return self.accessTokenHandler.accessToken;
}

- (NSString *)tasksDescription;
{
    return self.sessionsDirectory.description;
}

- (void)addCompletionHandlerForBackgroundSessionWithIdentifier:(NSString *)identifier handler:(dispatch_block_t)handler;
{
    self.completionHandlerBySessionID[identifier] = [handler copy];
}

- (void)getBackgroundTasksWithCompletionHandler:(void (^)(NSArray <NSURLSessionTask *>*))completionHandler;
{
    [self.sessionsDirectory.backgroundSession getTasksWithCompletionHandler:completionHandler];
}

- (void)enqueueOneTimeRequest:(ZMTransportRequest *)searchRequest;
{
    [self.numberOfRequestsInProgress increment];
    [self enqueueTransportRequest:searchRequest];
}

- (ZMTransportEnqueueResult *)attemptToEnqueueSyncRequestWithGenerator:(NS_NOESCAPE ZMTransportRequestGenerator)requestGenerator;
{
    //
    // N.B.: This method needs to be thread safe!
    //
    if (self.tornDown) {
        return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:NO didGenerateNonNullRequest:NO];
    }
    self.firstRequestFired = YES;
    
    NSInteger const limit = MIN(self.maximumConcurrentRequests, self.requestScheduler.concurrentRequestCountLimit);
    NSInteger const newCount = [self.numberOfRequestsInProgress increment];
    if (limit < newCount) {
        ZMLogInfo(@"Reached limit of %ld concurrent requests. Not enqueueing.", (long)limit);
        [self decrementNumberOfRequestsInProgressAndNotifyOperationLoop:NO];
        return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:NO didGenerateNonNullRequest:NO];
    } else {
        ZMTransportRequest *request = requestGenerator();
        if (request == nil) {
            [self decrementNumberOfRequestsInProgressAndNotifyOperationLoop:NO];
            return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:YES didGenerateNonNullRequest:NO];
        }
        [self enqueueTransportRequest:request];
        return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:YES didGenerateNonNullRequest:YES];
    }
}

- (void)enqueueTransportRequest:(ZMTransportRequest *)request;
{
    //
    // N.B.: This part of the method needs to be thread safe!
    //
    [request startBackgroundActivity];
    RequireString(request.hasRequiredPayload, "Payload vs. method");
    
    ZM_WEAK(self);
    ZMSDispatchGroup *group = self.workGroup;
    [group enter];
    [self.workQueue addOperationWithBlock:^{
        ZM_STRONG(self);
        [self.requestScheduler addItem:request];
        [group leave];
    }];
}

- (void)sendTransportRequest:(ZMTransportRequest *)request;
{
    NSDate * const expirationDate = request.expirationDate;
    
    // Immediately fail request if it has already expired at this point in time
    if ((expirationDate != nil) && (expirationDate.timeIntervalSinceNow < 0.1)) {
        NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil];
        ZMTransportResponse *expiredResponse = [ZMTransportResponse responseWithTransportSessionError:error apiVersion:request.apiVersion];
        [request completeWithResponse:expiredResponse];
        [self decrementNumberOfRequestsInProgressAndNotifyOperationLoop:YES]; // TODO aren't we decrementing too late here?
        return;
    }
    
    // TODO: Need to set up a timer such that we can fail expired requests before they hit this point of the code -> namely when offline
    
    ZMURLSession *session = request.shouldUseOnlyBackgroundSession ? self.sessionsDirectory.backgroundSession :
                            request.shouldUseVoipSession ? self.sessionsDirectory.voipSession : self.sessionsDirectory.foregroundSession;
    
    if (session.configuration.timeoutIntervalForRequest < expirationDate.timeIntervalSinceNow) {
        ZMLogWarn(@"May not be able to time out request. timeoutIntervalForRequest (%g) is too low (%g).",
                  session.configuration.timeoutIntervalForRequest, expirationDate.timeIntervalSinceNow);
    }
    
    NSURLSessionTask *task = [self suspendedTaskForRequest:request onSession:session];
    if (expirationDate) { //TODO can we test this if-statement somehow?
        [self startTimeoutForTask:task date:expirationDate onSession:session];
    }
    
    [request markStartOfUploadTimestamp];
    [task resume];
    [self.requestLoopDetection recordRequestWithPath:request.path contentHash:request.contentDebugInformationHash date:nil];
}

- (NSURLSessionTask *)suspendedTaskForRequest:(ZMTransportRequest *)request onSession:(ZMURLSession *)session;
{
    NSURL *url = [NSURL URLWithString:request.path relativeToURL:self.baseURL];
    NSAssert(url != nil, @"Nil URL in request");
    
    NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [URLRequest configureWithRequest:request];
    [request setTimeoutIntervalOnRequestIfNeeded:URLRequest
                       applicationIsBackgrounded:self.applicationIsBackgrounded
                          usingBackgroundSession:session.isBackgroundSession];

    [self.accessTokenHandler checkIfRequest:request needsToFetchAccessTokenInURLRequest:URLRequest];
    [self.accessTokenHandler checkIfRequest:request needsToAttachCookieInURLRequest:URLRequest];
    
    NSData *bodyData = URLRequest.HTTPBody;
    URLRequest.HTTPBody = nil;
    ZMLogPublic(@"Request: %@", request.safeForLoggingDescription);
    ZMLogInfo(@"----> Request: %@\n%@", URLRequest.allHTTPHeaderFields, request);
    NSURLSessionTask *task = [session taskWithRequest:URLRequest bodyData:(bodyData.length == 0) ? nil : bodyData transportRequest:request];
    return task;
}

- (void)startTimeoutForTask:(NSURLSessionTask *)task date:(NSDate *)date onSession:(ZMURLSession *)session
{
    ZMTimer *timer = [ZMTimer timerWithTarget:self operationQueue:self.workQueue];
    timer.userInfo = @{
                       TaskTimerKey: task,
                       SessionTimerKey: session
                       };
    
    [session setTimeoutTimer:timer forTask:task];
    
    [timer fireAtDate:date];
}


- (void)timerDidFire:(ZMTimer *)timer
{
    NSURLSessionTask *task = timer.userInfo[TaskTimerKey];
    ZMURLSession *session = timer.userInfo[SessionTimerKey];
    [self expireTask:task session:session];
}

- (void)expireTask:(NSURLSessionTask *)task session:(ZMURLSession *)session;
{
    ZMLogDebug(@"Expiring task %lu", (unsigned long) task.taskIdentifier);
    [self.expiredTasks addObject:task]; // Need to make sure it's set before cancelling.
    [session cancelTaskWithIdentifier:task.taskIdentifier completionHandler:^(BOOL didCancel){
        if (! didCancel) {
            ZMLogDebug(@"Removing expired task %lu", (unsigned long) task.taskIdentifier);
            [self.expiredTasks removeObject:task];
        }
    }];
}

- (void)didCompleteRequest:(ZMTransportRequest *)request data:(NSData *)data task:(NSURLSessionTask *)task error:(NSError *)error session:(ZMURLSession *)session;
{
    NOT_USED(error);
    [self decrementNumberOfRequestsInProgressAndNotifyOperationLoop:YES]; // TODO aren't we decrementing too late here?
    
    NSHTTPURLResponse *httpResponse = (id) task.response;
    
    BOOL const expired = [self.expiredTasks containsObject:task];
    ZMLogDebug(@"Task %lu is %@", (unsigned long) task.taskIdentifier, expired ? @"expired" : @"NOT expired");
    if (task.error != nil) {
        ZMLogDebug(@"Task %lu finished with error: %@", (unsigned long) task.taskIdentifier, task.error.description);
    }
    NSError *transportError = [NSError transportErrorFromURLTask:task expired:expired];
    ZMTransportResponse *response = [self transportResponseFromURLResponse:httpResponse data:data error:transportError apiVersion:request.apiVersion];
    ZMLogPublic(@"Response to %@: %@", request.safeForLoggingDescription,  response.safeForLoggingDescription);
    ZMLogInfo(@"<---- Response to %@ %@ (status %u): %@", [ZMTransportRequest stringForMethod:request.method], request.path, (unsigned) httpResponse.statusCode, response);
    ZMLogInfo(@"URL Session is %@", session.description);
    if (response.result == ZMTransportResponseStatusExpired) {
        [request completeWithResponse:response];
        return;
    }
    
    if (request.responseWillContainAccessToken) {
        [self.accessTokenHandler processAccessTokenResponse:response];
    }
    
    // If this requests needed authentication, but the access token wasn't valid, fail it:
    if (request.needsAuthentication && (httpResponse.statusCode == 401)) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Request requiring authentication finished with 404 response. Make sure there is an access token."};
        NSError *tryAgainError = [NSError tryAgainLaterErrorWithUserInfo:userInfo];
        ZMTransportResponse *tryAgainResponse = [ZMTransportResponse responseWithTransportSessionError:tryAgainError apiVersion:request.apiVersion];
        [request completeWithResponse:tryAgainResponse];
    } else {
        [request completeWithResponse:response];
    }
}


- (void)decrementNumberOfRequestsInProgressAndNotifyOperationLoop:(BOOL)notify
{
    NSInteger const limit = MIN(self.maximumConcurrentRequests, self.requestScheduler.concurrentRequestCountLimit);
    if ([self.numberOfRequestsInProgress decrement] < limit) {
        if (notify) {
            [ZMTransportSession notifyNewRequestsAvailable:self];
        }
    }
}

+ (void)notifyNewRequestsAvailable:(id<NSObject>)sender
{
    NOT_USED(sender);
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMTransportSessionNewRequestAvailableNotification object:self];
}

- (ZMTransportResponse *)transportResponseFromURLResponse:(NSURLResponse *)URLResponse data:(NSData *)data error:(NSError *)error apiVersion:(int)apiVersion;
{
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *) URLResponse;
    return [[ZMTransportResponse alloc] initWithHTTPURLResponse:HTTPResponse data:data error:error apiVersion:apiVersion];
}

- (void)processCookieResponse:(NSHTTPURLResponse *)HTTPResponse;
{
    [self.cookieStorage setCookieDataFromResponse:HTTPResponse forURL:HTTPResponse.URL];
}

- (void)handlerDidReceiveAccessToken:(ZMAccessTokenHandler *)handler
{
    NOT_USED(handler);
    self.transportPushChannel.accessToken = self.accessToken;
    [self.requestScheduler sessionDidReceiveAccessToken:self];
}

- (void)handlerDidClearAccessToken:(ZMAccessTokenHandler *)handler
{
    NOT_USED(handler);
    self.transportPushChannel.accessToken = nil;
}

- (void)enterBackground;
{
    BackgroundActivity *enterActivity = [[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:@"ZMTransportSession.enterBackground"];
    ZMLogInfo(@"<%@: %p> %@", self.class, self, NSStringFromSelector(_cmd));
    NSOperationQueue *queue = self.workQueue;
    ZMSDispatchGroup *group = self.workGroup;
    if ((queue != nil) && (group != nil)) {
        [group enter];
        [queue addOperationWithBlock:^{
            // We need to kick into 'Flush' 1st, to get rid of any items stuck in "5xx back-off":
            self.requestScheduler.schedulerState = ZMTransportRequestSchedulerStateFlush;
            self.applicationIsBackgrounded = YES;
            self.requestScheduler.schedulerState = ZMTransportRequestSchedulerStateNormal;
            [ZMTransportSession notifyNewRequestsAvailable:self];
            [group leave];
            if (enterActivity) {
                [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:enterActivity];
            }
        }];
    } else {
        if (enterActivity) {
            [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:enterActivity];
        }
    }
}

- (void)enterForeground;
{
    ZMLogInfo(@"<%@: %p> %@", self.class, self, NSStringFromSelector(_cmd));
    NSOperationQueue *queue = self.workQueue;
    ZMSDispatchGroup *group = self.workGroup;
    if ((queue != nil) && (group != nil)) {
        [group enter];
        [queue addOperationWithBlock:^{
            self.applicationIsBackgrounded = NO;
            [self.requestScheduler applicationWillEnterForeground];
            self.requestScheduler.schedulerState = ZMTransportRequestSchedulerStateNormal;
            [group leave];
        }];
    }
}

- (void)prepareForSuspendedState;
{
    [[[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:@"enqueue access token"] executeBlock:^(BackgroundActivity * activity) {
        [self.sessionsDirectory.foregroundSession countTasksWithCompletionHandler:^(NSUInteger count) {
            if (0 < count) {
                [self sendAccessTokenRequest];
            }
            [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:activity];
        }];
    }];
}

- (void)setNetworkStateDelegate:(id<ZMNetworkStateDelegate>)networkStateDelegate
{
    self.weakNetworkStateDelegate = networkStateDelegate;
    if (self.reachability.mayBeReachable) {
        [networkStateDelegate didReceiveData];
    }
    else {
        [networkStateDelegate didGoOffline];
    }
}

@end



@implementation ZMTransportSession (RequestScheduler)

@dynamic reachability;


- (void)sendAccessTokenRequest;
{
    [self.accessTokenHandler sendAccessTokenRequestWithURLSession:self.sessionsDirectory.foregroundSession];
}

- (BOOL)accessTokenIsAboutToExpire {
    return [self.accessTokenHandler accessTokenIsAboutToExpire];
}

- (BOOL)canStartRequestWithAccessToken;
{
    return [self.accessTokenHandler canStartRequestWithAccessToken];
}


- (void)sendSchedulerItem:(id<ZMTransportRequestSchedulerItemAsRequest>)item;
{
    if (item.isPushChannelRequest) {
        [self.transportPushChannel open];
    } else {
        [self sendTransportRequest:item.transportRequest];
    }
}

- (void)temporarilyRejectSchedulerItem:(id<ZMTransportRequestSchedulerItemAsRequest>)item;
{
    ZMTransportRequest *request = item.transportRequest;
    if (request != nil) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Temporarily rejecting item to sync."};
        NSError *error = [NSError tryAgainLaterErrorWithUserInfo:userInfo];
        ZMTransportResponse *tryAgainRespose = [ZMTransportResponse responseWithTransportSessionError:error apiVersion:request.apiVersion];
        [request completeWithResponse:tryAgainRespose];
        [self decrementNumberOfRequestsInProgressAndNotifyOperationLoop:YES];
    }
}

- (void)schedulerIncreasedMaximumNumberOfConcurrentRequests:(ZMTransportRequestScheduler *)scheduler;
{
    ZMLogDebug(@"%@ Notify new request" , NSStringFromSelector(_cmd));
    [self.transportPushChannel scheduleOpen];
    [ZMTransportSession notifyNewRequestsAvailable:scheduler];
}

- (void)schedulerWentOffline:(ZMTransportRequestScheduler *)scheduler
{
    NOT_USED(scheduler);
    [self.weakNetworkStateDelegate didGoOffline];

}

@end



@implementation ZMTransportSession (URLSessionDelegate)

- (void)URLSession:(ZMURLSession *)URLSession dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;
{
    NOT_USED(URLSession);
    NOT_USED(dataTask);
    // Forward the response to the request scheduler:
    NSHTTPURLResponse * const HTTPResponse = (id) response;
    [self.requestScheduler processCompletedURLResponse:HTTPResponse URLError:nil];
    // Continue the task:
    completionHandler(NSURLSessionResponseAllow);
    
    [self updateNetworkStatusFromDidReadDataFromNetwork];
}

- (void)URLSessionDidReceiveData:(ZMURLSession *)URLSession;
{
    NOT_USED(URLSession);
    [self updateNetworkStatusFromDidReadDataFromNetwork];
}

- (void)URLSession:(ZMURLSession *)URLSession taskDidComplete:(NSURLSessionTask *)task transportRequest:(ZMTransportRequest *)request responseData:(NSData *)data;
{
    NSTimeInterval timeDiff = -[request.startOfUploadTimestamp timeIntervalSinceNow];
    ZMLogDebug(@"(Almost) bare network time for request %p %@ %@: %@s", request, request.methodAsString, request.path, @(timeDiff));
    NSError *error = task.error;
    NSHTTPURLResponse *HTTPResponse = (id)task.response;
    [self processCookieResponse:HTTPResponse];

    BOOL didConsume = [self.accessTokenHandler consumeRequestWithTask:task data:data session:URLSession shouldRetry:self.requestScheduler.canSendRequests apiVersion:request.apiVersion];
    if (!didConsume) {
        [self didCompleteRequest:request data:data task:task error:error session:URLSession];
    }
    
    [self.requestScheduler processCompletedURLTask:task];
    [self.expiredTasks removeObject:task];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(ZMURLSession *)URLSession
{
    NSString *identifier = URLSession.configuration.identifier;
    dispatch_block_t storedHandler = [self.completionHandlerBySessionID[identifier] copy];
    self.completionHandlerBySessionID[identifier] = nil;
    
    if (nil != storedHandler) {
        ZMLogDebug(@"-- <%@ %p> %@ -> calling background event completion handler for session: %@", self.class, self, NSStringFromSelector(_cmd), identifier);
        dispatch_async(dispatch_get_main_queue(), ^{
            storedHandler();
        });
    } else {
        ZMLogDebug(@"-- <%@ %p> %@ -> No stored completion handler found for session: %@", self.class, self, NSStringFromSelector(_cmd), identifier);
    }
}

- (void)URLSession:(ZMURLSession *)URLSession didDetectUnsafeConnectionToHost:(NSString *)host
{
    NOT_USED(URLSession);
    
    ZMLogDebug(@"Detected unsafe connection to %@", host);    
    [self.requestScheduler setSchedulerState:ZMTransportRequestSchedulerStateOffline];
    [self.weakNetworkStateDelegate didGoOffline];
}

@end



@implementation ZMTransportSession (ReachabilityObserver)

- (void)reachabilityDidChange:(id<ReachabilityProvider, TearDownCapable>)reachability;
{
    ZMLogInfo(@"reachabilityDidChange -> mayBeReachable = %@", reachability.mayBeReachable ? @"YES" : @"NO");
    [self.requestScheduler reachabilityDidChange:reachability];
    [self.transportPushChannel reachabilityDidChange:reachability];

    BOOL didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable;
    if (didGoOnline && !self.accessTokenHandler.canStartRequestWithAccessToken) {
        [self sendAccessTokenRequest];
    }
    
    id<ZMNetworkStateDelegate> networkStateDelegate = self.weakNetworkStateDelegate;
    if(self.reachability.mayBeReachable) {
        [networkStateDelegate didReceiveData];
    } else {
        [networkStateDelegate didGoOffline];
    }
}

- (void)updateNetworkStatusFromDidReadDataFromNetwork;
{
    [self.weakNetworkStateDelegate didReceiveData];
}

@end


@implementation ZMTransportSession (RequestCancellation)

- (void)cancelTaskWithIdentifier:(ZMTaskIdentifier *)identifier;
{
    for (ZMURLSession *session in self.sessionsDirectory.allSessions) {
        if ([identifier.sessionIdentifier isEqualToString:session.identifier]) {
            [session cancelTaskWithIdentifier:identifier.identifier completionHandler:nil];
            return;
        }
    }
}

@end


@implementation ZMTransportSession (PushChannel)

- (void)configurePushChannelWithConsumer:(id<ZMPushChannelConsumer>)consumer groupQueue:(id<ZMSGroupQueue>)groupQueue;
{
    [self.transportPushChannel setPushChannelConsumer:consumer queue:groupQueue];

}

- (id<ZMPushChannel>)pushChannel
{
    return self.transportPushChannel;
}

@end


@implementation ZMTransportSession (Testing)

- (void)setAccessToken:(ZMAccessToken *)accessToken;
{
    self.accessTokenHandler.testing_accessToken = accessToken;
}

@end


@implementation ZMTransportEnqueueResult

+ (instancetype)resultDidHaveLessRequestsThanMax:(BOOL)didHaveLessThanMax didGenerateNonNullRequest:(BOOL)didGenerateRequest;
{
    ZMTransportEnqueueResult *result = [[ZMTransportEnqueueResult alloc] init];
    if (result != nil) {
        result->_didGenerateNonNullRequest = didGenerateRequest;
        result->_didHaveLessRequestThanMax = didHaveLessThanMax;
    }
    return result;
}

@end





@implementation ZMOpenPushChannelRequest

- (BOOL)isEqual:(id)object;
{
    return [object isKindOfClass:[ZMOpenPushChannelRequest class]];
}

- (ZMTransportRequest *)transportRequest;
{
    return nil;
}

- (BOOL)isPushChannelRequest;
{
    return YES;
}

- (BOOL)needsAuthentication;
{
    return YES;
}

@end



@implementation ZMTransportRequest (Scheduler)

- (ZMTransportRequest *)transportRequest;
{
    return self;
}

- (BOOL)isPushChannelRequest;
{
    return NO;
}

@end
