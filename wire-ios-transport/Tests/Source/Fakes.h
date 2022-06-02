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

#pragma mark - FakeURLResponse


@class FakeURLResponse;
@interface FakeDataTask : NSObject

@property (nonatomic) NSError *fakeError;
@property (nonatomic) NSUInteger fakeTaskIdentifier;
@property (nonatomic) FakeURLResponse *fakeURLResponse;

- (instancetype)initWithError:(NSError *)error taskIdentifier:(NSUInteger)taskIdentifier response:(FakeURLResponse *)response;
- (void)resume;
- (NSURLResponse *)response;
- (NSError *)error;
- (NSURLRequest *)originalRequest;

@end


#pragma mark - FakeURLResponse


@interface FakeURLResponse : NSObject

+ (instancetype)testResponse;

@property (nonatomic) NSData *body;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic) NSDictionary *allHeaderFields;
@property (nonatomic) NSError *error;

- (void)setBodyFromTransportData:(id<ZMTransportData>)data;
@end


#pragma mark - FakeTransportResponse


@interface FakeTransportResponse : NSObject
+ (instancetype)testResponse;
@property (nonatomic) NSInteger HTTPStatus;
@property (nonatomic) ZMTransportResponseStatus result;
@property (nonatomic) NSDictionary *payload;
@end


#pragma mark - FakeExponentialBackoff


@interface FakeExponentialBackoff : NSObject
@property (nonatomic) NSMutableArray *blocks;
@property (nonatomic) NSInteger resetBackoffCount;
@property (nonatomic) NSInteger increaseBackoffCount;
@end


#pragma mark - FakeDelegate


@interface FakeDelegate : NSObject <ZMAccessTokenHandlerDelegate>
@property (nonatomic) NSUInteger delegateCallCount;
@property (nonatomic, copy) dispatch_block_t didReceiveAccessTokenBlock;
@end

#pragma mark - ZMSGroupQueue

@interface FakeGroupQueue : NSObject <ZMSGroupQueue>

@end

#pragma mark - FakeSchedulerSession

@interface FakeSchedulerSession : NSObject <ZMTransportRequestSchedulerSession>

@property (nonatomic) BOOL canStartRequestWithAccessToken;
@property (nonatomic) BOOL accessTokenIsAboutToExpire;

@property (nonatomic) int accessTokenRequestCount;
@property (nonatomic) NSMutableArray *sentItems;
@property (nonatomic) NSMutableArray *rejectedItems;
@property (nonatomic) int maximumNumberOfConcurrentRequestsChangeCount;
@property (nonatomic) ZMReachability *reachability;
@property (nonatomic) int offlineCount;

@end

@interface FakeSchedulerSession (AccessToken)
@end
@interface FakeSchedulerSession (Reachability)
@end
@interface FakeSchedulerSession (Backoff)
@end
@interface FakeSchedulerSession (RateLimit)
@end
