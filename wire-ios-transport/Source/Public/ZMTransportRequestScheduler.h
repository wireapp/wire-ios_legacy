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


#import <Foundation/Foundation.h>
#import <WireSystem/WireSystem.h>
#import <WireUtilities/WireUtilities.h>
#import <WireTransport/ZMReachability.h>
#import <WireTransport/ZMTransportRequest.h>

NS_ASSUME_NONNULL_BEGIN

@class ZMExponentialBackoff;
@protocol ZMTransportRequestSchedulerItem;
@protocol ZMTransportRequestSchedulerSession;
@protocol ReachabilityProvider;
@protocol ZMReachabilityObserver;

enum {
    TooManyRequestsStatusCode = 429,
    EnhanceYourCalmStatusCode = 420,
    UnauthorizedStatusCode = 401
};



typedef NS_ENUM(int8_t, ZMTransportRequestSchedulerState) {
    ZMTransportRequestSchedulerStateNormal = 1,
    ZMTransportRequestSchedulerStateOffline,
    ZMTransportRequestSchedulerStateFlush,
    ZMTransportRequestSchedulerStateRateLimitedHoldingOff, ///< We are rate limited, and holding off
    ZMTransportRequestSchedulerStateRateLimitedRetrying, ///< We were rate limitied, and are checking again
};

/// For use with @c concurrentRequestCountLimit when there's no limit in effect.
extern NSInteger const ZMTransportRequestSchedulerRequestCountUnlimited;



@interface ZMTransportRequestScheduler : NSObject <ZMReachabilityObserver, ZMSGroupQueue, TearDownCapable>

- (instancetype)initWithSession:(id<ZMTransportRequestSchedulerSession>)session operationQueue:(NSOperationQueue *)queue group:(ZMSDispatchGroup *)group reachability:(id<ReachabilityProvider>)reachability;
- (instancetype)initWithSession:(id<ZMTransportRequestSchedulerSession>)session operationQueue:(NSOperationQueue *)queue group:(ZMSDispatchGroup *)group reachability:(id<ReachabilityProvider>)reachability backoff:(nullable ZMExponentialBackoff *)backoff NS_DESIGNATED_INITIALIZER;

- (void)tearDown;

- (void)addItem:(id<ZMTransportRequestSchedulerItem>)item;
/// The task given access to the NSHTTPURLResponse and NSError.
- (void)processCompletedURLTask:(NSURLSessionTask *)task;
- (void)processCompletedURLResponse:(nullable NSHTTPURLResponse *)response URLError:(nullable NSError *)error;
- (void)processWebSocketError:(NSError *)error;

- (void)sessionDidReceiveAccessToken:(id<ZMTransportRequestSchedulerSession>)session;
/// The scheduler uses this to retry sending requests if it's in offline mode.
- (void)applicationWillEnterForeground;
/// The transport session uses this to determine whether to continue requesting an access token
- (BOOL)canSendRequests;


@property (atomic, readonly) NSInteger concurrentRequestCountLimit;
@property (nonatomic) ZMTransportRequestSchedulerState schedulerState;
@property (nonatomic, readonly) id<ReachabilityProvider> reachability;

@end



@protocol ZMTransportRequestSchedulerItem <NSObject>

@property (nonatomic, readonly) BOOL needsAuthentication;

@end

/// This protocol allows the ZMTransportSession to handle both ZMTransportRequest and ZMPushChannel as scheduled items.
@protocol ZMTransportRequestSchedulerItemAsRequest <NSObject>

/// If the receiver is a transport request, returns @c self, @c nil otherwise
@property (nonatomic, readonly) ZMTransportRequest *transportRequest;
/// If the receiver is a request to open the push channel
@property (nonatomic, readonly) BOOL isPushChannelRequest;

@end

@interface ZMOpenPushChannelRequest : NSObject <ZMTransportRequestSchedulerItem, ZMTransportRequestSchedulerItemAsRequest>
@end

@interface ZMTransportRequest (Scheduler) <ZMTransportRequestSchedulerItem, ZMTransportRequestSchedulerItemAsRequest>
@end


@protocol ZMTransportRequestSchedulerSession <NSObject>

@property (nonatomic, readonly) BOOL canStartRequestWithAccessToken;
@property (nonatomic, readonly) BOOL accessTokenIsAboutToExpire;
@property (nonatomic, readonly) ZMReachability *reachability;

- (void)sendSchedulerItem:(id<ZMTransportRequestSchedulerItem>)item;
- (void)temporarilyRejectSchedulerItem:(id<ZMTransportRequestSchedulerItem>)item;

- (void)sendAccessTokenRequest;

- (void)schedulerIncreasedMaximumNumberOfConcurrentRequests:(ZMTransportRequestScheduler *)scheduler;
- (void)schedulerWentOffline:(ZMTransportRequestScheduler *)scheduler;

@end



@interface ZMTransportRequestScheduler (Testing)

/// When the scheduler switches to offline mode (because a request failed) but the reachability says that the network may be reachable, the scheduler will switch back to normal mode after this time interval.
@property (nonatomic) NSTimeInterval timeUntilNormalModeWhenNetworkMayBeReachable;

/// When we're rate limited, we wait approximately this many seconds until retrying a single request.
/// The actual time is randomly picked in the range [t/2; 2*t].
@property (nonatomic) NSTimeInterval timeUntilRetryModeWhenRateLimited;

@end

NS_ASSUME_NONNULL_END
