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


#import <WireTransport/ZMTransportRequest.h>

@class ZMAccessToken;
@class ZMPersistentCookieStorage;
@class ZMAccessTokenHandler;
@class ZMURLSession;
@class ZMExponentialBackoff;

@protocol ZMAccessTokenHandlerDelegate <NSObject>

- (void)handlerDidReceiveAccessToken:(ZMAccessTokenHandler *)handler;
- (void)handlerDidClearAccessToken:(ZMAccessTokenHandler *)handler;

@end


@class ZMSDispatchGroup;


@interface ZMAccessTokenHandler : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                  cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       delegate:(id<ZMAccessTokenHandlerDelegate>)delegate
                          queue:(NSOperationQueue *)queue
                          group:(ZMSDispatchGroup *)group
                        backoff:(ZMExponentialBackoff *)backoff
             initialAccessToken:(ZMAccessToken *)initialAccessToken;

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler;
- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler;


- (void)checkIfRequest:(ZMTransportRequest *)request needsToFetchAccessTokenInURLRequest:(NSMutableURLRequest *)URLRequest;
- (void)checkIfRequest:(ZMTransportRequest *)request needsToAttachCookieInURLRequest:(NSMutableURLRequest *)URLRequest;

/// Returns YES if another request should be generated (e.g. it was a temporary error)
- (BOOL)processAccessTokenResponse:(ZMTransportResponse *)response;

- (BOOL)consumeRequestWithTask:(NSURLSessionTask *)task data:(NSData *)data session:(ZMURLSession *)session shouldRetry:(BOOL)shouldRetry apiVersion:(int)apiVersion
;

- (BOOL)hasAccessToken;

- (void)sendAccessTokenRequestWithURLSession:(ZMURLSession *)URLSession;
- (BOOL)accessTokenIsAboutToExpire;
- (BOOL)canStartRequestWithAccessToken;


@property (nonatomic, readonly) ZMAccessToken *accessToken;

@end



@interface ZMAccessTokenHandler (Testing)

@property (nonatomic) ZMAccessToken* testing_accessToken;

@property (nonatomic, readonly) NSURLSessionTask *currentAccessTokenTask;

@end
