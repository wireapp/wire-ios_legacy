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

#import "ZMAccessTokenHandler.h"
#import "ZMTransportResponse.h"
#import "ZMTransportData.h"
#import "ZMTransportCodec.h"
#import <mach-o/dyld.h>
#import "ZMPersistentCookieStorage.h"
#import "NSError+ZMTransportSession.h"
#import "ZMUserAgent.h"
#import "ZMTransportRequest.h"
#import "ZMURLSession.h"
#import "ZMTransportRequestScheduler.h"
#import "ZMExponentialBackoff.h"
#import "ZMTLogging.h"
#import <WireTransport/WireTransport-Swift.h>


static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK;


static NSTimeInterval const MininumSecondsAccessTokenNeedsToBeValid = 15;

// When we're getting close to the expiry time of the access token, we'll
// renew it.
static NSTimeInterval const GraceperiodToRenewAccessToken = 40;


@interface ZMAccessTokenHandler ()

@property (nonatomic) ZMAccessToken *accessToken;
@property (nonatomic, copy) ZMCompletionHandlerBlock accessTokenRenewalFailureHandler;
@property (nonatomic, copy) ZMAccessTokenHandlerBlock accessTokenRenewalSuccessHandler;
@property (nonatomic) NSURLSessionTask *currentAccessTokenTask;


@property (nonatomic) NSURL *baseURL;
@property (nonatomic) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic, weak) id<ZMAccessTokenHandlerDelegate> delegate;

@property (nonatomic) ZMExponentialBackoff *backoff;
@property (nonatomic) NSOperationQueue *workQueue;
@property (nonatomic) ZMSDispatchGroup *group;
@property (nonatomic) BackgroundActivity *activity;

@end


@implementation ZMAccessTokenHandler

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                  cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       delegate:(id<ZMAccessTokenHandlerDelegate>)delegate
                          queue:(NSOperationQueue *)queue
                          group:(ZMSDispatchGroup *)group
                        backoff:(ZMExponentialBackoff *)backoff
             initialAccessToken:(ZMAccessToken *)initialAccessToken
{
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
        self.cookieStorage = cookieStorage;
        self.delegate = delegate;
        self.group = group;
        self.workQueue = queue;
        self.backoff = backoff ?: [[ZMExponentialBackoff alloc] initWithGroup:self.group workQueue:self.workQueue];
        self.accessToken = initialAccessToken;
    }
    return self;
}

- (void)dealloc {
    [self.backoff tearDown];
}

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler
{
    self->_accessTokenRenewalFailureHandler = [handler copy];
}

- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler
{
    self->_accessTokenRenewalSuccessHandler = [handler copy];
}

- (void)notifyTokenFailure:(ZMTransportResponse *)response;
{
    if (self.accessTokenRenewalFailureHandler) {
        self.accessTokenRenewalFailureHandler(response);
    }
}

- (void)notifyTokenSuccess:(ZMAccessToken *)token
{
    if (self.accessTokenRenewalSuccessHandler) {
        self.accessTokenRenewalSuccessHandler(token.token, token.type);
    }
}

- (void)setAccessToken:(ZMAccessToken *)accessToken
{
    [self willChangeValueForKey:@"accessToken"];
    _accessToken = accessToken;
    [self didChangeValueForKey:@"accessToken"];
    
    id<ZMAccessTokenHandlerDelegate> delegate = self.delegate;
    if(delegate == nil) {
        return;
    }
    
    if (_accessToken != nil) {
        [delegate handlerDidReceiveAccessToken:self];
    } else {
        [delegate handlerDidClearAccessToken:self];
    }
}

- (void)setRequestHeaderFieldsWithLastKnownAccessToken:(NSMutableURLRequest *)request
{
    NSString *token = self.accessToken.token;
    NSString *type = self.accessToken.type;
    if (token == nil || type == nil) {
        return;
    }
    [request setValue:[NSString stringWithFormat:@"%@ %@", type, token] forHTTPHeaderField:@"Authorization"];
}


- (void)checkIfRequest:(ZMTransportRequest *)request needsToFetchAccessTokenInURLRequest:(NSMutableURLRequest *)URLRequest;
{
    if (request.needsAuthentication) {
        [self setRequestHeaderFieldsWithLastKnownAccessToken:URLRequest];
    }
}

- (void)checkIfRequest:(ZMTransportRequest *)request needsToAttachCookieInURLRequest:(NSMutableURLRequest *)URLRequest;
{
    if (request.needsCookie) {
        [self.cookieStorage setRequestHeaderFieldsOnRequest:URLRequest];
    }
}

- (BOOL)canStartRequestWithAccessToken;
{
    if (self.accessToken == nil) {
        return NO;
    }
    // If expiration is imminent, we assume it won't work:
    return (MininumSecondsAccessTokenNeedsToBeValid < [self.accessToken.expirationDate timeIntervalSinceNow]);
}


- (BOOL)accessTokenIsAboutToExpire;
{
    return ([self.accessToken.expirationDate timeIntervalSinceNow] < GraceperiodToRenewAccessToken);
}

- (BOOL)hasAccessToken;
{
    return self.accessToken != nil;
}

- (void)sendAccessTokenRequestWithURLSession:(ZMURLSession *)URLSession
{
    Require(URLSession != nil);
    if (self.currentAccessTokenTask != nil) {
        return;
    }
    
    ZMLogInfo(@"Requesting access token from cookie (existing token: %p).", self.accessToken);
    if(self.cookieStorage.authenticationCookieData == nil) {
        ZMLogError(@"No cookie to request access token");
        [self notifyTokenFailure:nil];
        return;
    }

    self.activity = [[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:@"Network request: POST /access"];
    NSURL *URL = [NSURL URLWithString:@"/access" relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    [request setHTTPMethod:@"POST"];
    [request addValue:[ZMTransportCodec encodedContentType] forHTTPHeaderField:@"Content-Type"];
    [request addValue:[ZMTransportCodec encodedContentType] forHTTPHeaderField:@"Accept"];
    [self.cookieStorage setRequestHeaderFieldsOnRequest:request];
    [self setRequestHeaderFieldsWithLastKnownAccessToken:request];
    self.currentAccessTokenTask = [URLSession taskWithRequest:request bodyData:nil transportRequest:nil];
    ZMLogInfo(@"----> Access token request: %@ %@ \n %@ \n %@", request.HTTPMethod, request.URL, request.allHTTPHeaderFields, request.HTTPBody);

    [self.backoff performBlock:^{
        [self.currentAccessTokenTask resume];
    }];
}



- (BOOL)consumeRequestWithTask:(NSURLSessionTask *)task data:(NSData *)data session:(ZMURLSession *)session shouldRetry:(BOOL)shouldRetry apiVersion:(int)apiVersion;
{
    if (self.currentAccessTokenTask != task) {
        return NO;
    }

    [self didCompleteAccessTokenRequestWithTask:task data:data session:session shouldRetry:shouldRetry apiVersion:apiVersion];
    return YES;
}


- (void)didCompleteAccessTokenRequestWithTask:(NSURLSessionTask *)task data:(NSData *)data session:(ZMURLSession *)session shouldRetry:(BOOL)shouldRetry apiVersion:(int)apiVersion
{
    ZMLogInfo(@"<---- Access token task completed: %@ // %@", task, task.error);
    ZMLogInfo(@"<---- Access token URL session: %@", session.description);
    
    NSError *transportError = [NSError transportErrorFromURLTask:task expired:NO];
    ZMTransportResponse *response = [self transportResponseFromURLResponse:task.response data:data error:transportError apiVersion:apiVersion];
    BOOL needToResend = [self processAccessTokenResponse:response];
    
    // We can only re-send once we've cleared out the current
    self.currentAccessTokenTask = nil;
    if (needToResend && shouldRetry) {
        [self sendAccessTokenRequestWithURLSession:session];
    }
    
    [self updateBackoffWithResponse:response];
    if (self.activity) {
        [BackgroundActivityFactory.sharedFactory endBackgroundActivity:self.activity];
    }
}

- (void)updateBackoffWithResponse:(ZMTransportResponse *)response;
{
    NSInteger const statusCode = response.HTTPStatus;
    BOOL const isBackOff = ((statusCode == TooManyRequestsStatusCode) ||
                            (statusCode == EnhanceYourCalmStatusCode));
    BOOL const isInternalError = ((statusCode >= 500) &&
                                  (statusCode <= 599));
    if (isBackOff ||
        isInternalError ||
        (response.result == ZMTransportResponseStatusTemporaryError))
    {
        // Server error or too busy -> increase back-off:
        [self.backoff increaseBackoff];
    } else if (response.result == ZMTransportResponseStatusTryAgainLater) {
        // The request was cancelled (switching to background?). Don't change backoff.
    } else {
        // Permanent error or success:
        [self.backoff resetBackoff];
    }
}


- (ZMTransportResponse *)transportResponseFromURLResponse:(NSURLResponse *)URLResponse data:(NSData *)data error:(NSError *)error apiVersion:(int)apiVersion;
{
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *) URLResponse;
    return [[ZMTransportResponse alloc] initWithHTTPURLResponse:HTTPResponse data:data error:error apiVersion:apiVersion];
}



- (BOOL)processAccessTokenResponse:(ZMTransportResponse *)response
{
    ZMLogInfo(@"<---- Access token response: %@", response);
    
    BOOL needsToReRun = YES;
    BOOL didFail = NO;
    
    ZMAccessToken *newToken;
    if (response.result == ZMTransportResponseStatusSuccess) {
        NSUInteger expiresIn = 0;
        if (response.payload != nil) {
            NSString *token = [response.payload asDictionary][@"access_token"];
            NSString *type = [response.payload asDictionary][@"token_type"];
            expiresIn = [[response.payload asDictionary][@"expires_in"] unsignedIntegerValue];
            newToken = [[ZMAccessToken alloc] initWithToken:token type:type expiresInSeconds:expiresIn];
        }
        didFail = (newToken == nil);
        needsToReRun = NO;
        
        if ( ! didFail) {
            self.accessToken = newToken;
            ZMLogInfo(@"New access token <%@: %p>", self.accessToken.class, self.accessToken);
            [self notifyTokenSuccess:newToken];
        }
        
    } else if (response.result == ZMTransportResponseStatusPermanentError &&
               response.HTTPStatus != EnhanceYourCalmStatusCode &&
               response.HTTPStatus != TooManyRequestsStatusCode)
    {
        didFail = YES;
        needsToReRun = NO;
    }

    
    if (didFail) {
        ZMLogInfo(@"Clearing access token and cookie");
        self.accessToken = nil;
        self.cookieStorage.authenticationCookieData = nil;
        [self notifyTokenFailure:response];
    }
    
    return needsToReRun;
}


@end


@implementation ZMAccessTokenHandler (Testing)

- (ZMAccessToken *)testing_accessToken {
    return self.accessToken;
}

- (void)setTesting_accessToken:(ZMAccessToken *)testing_accessToken {
    self.accessToken = testing_accessToken;
}

@end

