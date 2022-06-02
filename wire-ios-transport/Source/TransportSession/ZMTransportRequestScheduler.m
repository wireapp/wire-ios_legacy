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

#import "ZMTransportRequestScheduler.h"
#import "ZMExponentialBackoff.h"
#import "ZMTLogging.h"
#import "ZMWebSocket.h"
#import <WireTransport/WireTransport-Swift.h>

NSInteger const ZMTransportRequestSchedulerRequestCountUnlimited = NSIntegerMax;
/// C.f. <https://en.wikipedia.org/wiki/List_of_HTTP_status_codes>
static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK_LOW_LEVEL;



@interface ZMTransportRequestScheduler () <ZMTimerClient>
{
    NSInteger _concurrentRequestCountLimit;
}

@property (nonatomic, readonly) ZMExponentialBackoff *backoff;
@property (nonatomic, readonly, weak) id<ZMTransportRequestSchedulerSession> session;
@property (nonatomic, readonly) NSOperationQueue *workQueue;
@property (nonatomic, readonly) ZMSDispatchGroup *group;
@property (nonatomic, readonly) dispatch_queue_t countIsolation;
@property (nonatomic, readonly) NSMutableArray *backoffItemQueue;
@property (nonatomic, readwrite) id<ReachabilityProvider> reachability;
@property (nonatomic) BOOL needsTearDown;
@property (atomic) NSInteger concurrentRequestCountLimit;
@property (nonatomic, readonly) NSMutableArray *pendingRequestsRequiringAuthentication;
@property (nonatomic) NSTimeInterval timeUntilNormalModeWhenNetworkMayBeReachable;
@property (nonatomic) NSTimeInterval timeUntilRetryModeWhenRateLimited;
@property (nonatomic) ZMTimer *retryNormalModeTimer;
@property (nonatomic) ZMTimer *retryRateLimitModeTimer;
@property (nonatomic) int successiveRateLimits;

@end



@implementation ZMTransportRequestScheduler

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithSession:(id<ZMTransportRequestSchedulerSession>)session operationQueue:(NSOperationQueue *)queue group:(ZMSDispatchGroup *)group reachability:(id<ReachabilityProvider>)reachability;
{
    return [self initWithSession:session operationQueue:queue group:group reachability:reachability backoff:nil];
}

- (instancetype)initWithSession:(id<ZMTransportRequestSchedulerSession>)session operationQueue:(NSOperationQueue *)queue group:(ZMSDispatchGroup *)group reachability:(id<ReachabilityProvider>)reachability backoff:(ZMExponentialBackoff *)backoff;
{
    Require(session != nil);
    Require(queue != nil);
    Require(group != nil);
    self = [super init];
    if (self) {
        self.needsTearDown = YES;
        self.timeUntilNormalModeWhenNetworkMayBeReachable = 35 + arc4random_uniform(10);
        self.timeUntilRetryModeWhenRateLimited = 7.5;
        self.reachability = reachability;
        if(!reachability.mayBeReachable) {
            _schedulerState = ZMTransportRequestSchedulerStateOffline;
        }
        
        _backoff = backoff ?: [[ZMExponentialBackoff alloc] initWithGroup:group workQueue:queue];
        _backoffItemQueue = [NSMutableArray array];
        _session = session;
        _workQueue = queue;
        _group = group;
        _countIsolation = dispatch_queue_create("ZMTransportRequestScheduler.isolation", DISPATCH_QUEUE_CONCURRENT);
        _pendingRequestsRequiringAuthentication = [NSMutableArray array];
    }
    return self;
}

- (void)tearDown;
{
    self.needsTearDown = NO;
    
    [self.backoff tearDown];
    
    [self.retryNormalModeTimer cancel];
    self.retryNormalModeTimer = nil;
    
    [self.retryRateLimitModeTimer cancel];
    self.retryRateLimitModeTimer = nil;
}

- (void)dealloc
{
    Require(! self.needsTearDown);
}

@synthesize schedulerState = _schedulerState;
- (void)setSchedulerState:(ZMTransportRequestSchedulerState)schedulerState;
{
    if (schedulerState == _schedulerState) {
        return;
    }
    _schedulerState = schedulerState;
    ZMLogDebug(@"Scheduler state -> %d", (int) _schedulerState);
    
    switch (_schedulerState) {
        case ZMTransportRequestSchedulerStateNormal: {
            self.successiveRateLimits = 0;
            self.concurrentRequestCountLimit = ZMTransportRequestSchedulerRequestCountUnlimited;
            [self.backoff resetBackoff];
            break;
        }
        case ZMTransportRequestSchedulerStateOffline: {
            self.successiveRateLimits = 0;
            if (self.reachability.mayBeReachable) {
                [self scheduleRetryNormalModeTimer];
            }
            self.concurrentRequestCountLimit = 0;
            [self rejectAllBackoffItems];
            break;
        }
        case ZMTransportRequestSchedulerStateRateLimitedHoldingOff: {
            self.successiveRateLimits = MIN(6, self.successiveRateLimits + 1);
            [self scheduleRetryRateLimitModeTimer];
            self.concurrentRequestCountLimit = 0;
            break;
        }
        case ZMTransportRequestSchedulerStateRateLimitedRetrying: {
            self.concurrentRequestCountLimit = 1;
            break;
        }
        case ZMTransportRequestSchedulerStateFlush: {
            self.successiveRateLimits = 0;
            self.concurrentRequestCountLimit = 0;
            [self rejectAllBackoffItems];
            break;
        }
    }
}

- (void)rejectAllBackoffItems;
{
    NSArray *items = [self.backoffItemQueue copy];
    [self.backoffItemQueue removeAllObjects];
    for (id<ZMTransportRequestSchedulerItem> i in items) {
        [self.session temporarilyRejectSchedulerItem:i];
    }
    [self.backoff cancelAllBlocks];
}

- (void)scheduleRetryNormalModeTimer;
{
    [self.retryNormalModeTimer cancel];
    self.retryNormalModeTimer = [ZMTimer timerWithTarget:self operationQueue:self.workQueue];
    [self.retryNormalModeTimer fireAfterTimeInterval:self.timeUntilNormalModeWhenNetworkMayBeReachable];
}

- (void)scheduleRetryRateLimitModeTimer;
{
    [self.retryRateLimitModeTimer cancel];
    self.retryRateLimitModeTimer = [ZMTimer timerWithTarget:self operationQueue:self.workQueue];
    // relativeAdjustment should be randomly within 0.5 -> 2.0
    double const relativeRandomAdjustment = 0.5 + 3. * 0.5 * (arc4random() / (double) UINT32_MAX);
    double const backoffAdjustment = (double) self.successiveRateLimits;
    NSTimeInterval const interval = self.timeUntilRetryModeWhenRateLimited * relativeRandomAdjustment * backoffAdjustment;
    [self.retryRateLimitModeTimer fireAfterTimeInterval:interval];
}

- (void)timerDidFire:(ZMTimer *)timer;
{
    if (timer == self.retryNormalModeTimer) {
        if (self.schedulerState == ZMTransportRequestSchedulerStateOffline) {
            self.schedulerState = ZMTransportRequestSchedulerStateNormal;
        }
        self.retryNormalModeTimer = nil;
    } else if (timer == self.retryRateLimitModeTimer) {
        if (self.schedulerState == ZMTransportRequestSchedulerStateRateLimitedHoldingOff) {
            self.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
        }
        self.retryRateLimitModeTimer = nil;
    }
}

- (NSInteger)concurrentRequestCountLimit;
{
    __block NSInteger result;
    dispatch_sync(self.countIsolation, ^{
        result = self->_concurrentRequestCountLimit;
    });
    return result;
}

- (void)setConcurrentRequestCountLimit:(NSInteger)concurrentRequestCountLimit;
{
    if (concurrentRequestCountLimit < 0) {
        concurrentRequestCountLimit = 0;
    }
    id<ZMTransportRequestSchedulerSession> session = self.session;
    [self.group enter];
    dispatch_barrier_async(self.countIsolation, ^{
        BOOL const didIncrease = (self->_concurrentRequestCountLimit < concurrentRequestCountLimit);
        self->_concurrentRequestCountLimit = concurrentRequestCountLimit;
        [self.workQueue addOperationWithBlock:^{
            if (didIncrease) {
                [session schedulerIncreasedMaximumNumberOfConcurrentRequests:self];
            } else if (concurrentRequestCountLimit < (NSInteger) self.pendingRequestsRequiringAuthentication.count) {
                NSUInteger const c = (NSUInteger) concurrentRequestCountLimit;
                NSRange const r = NSMakeRange(c, self.pendingRequestsRequiringAuthentication.count - c);
                NSArray *itemsToCancel = [self.pendingRequestsRequiringAuthentication subarrayWithRange:r];
                [self.pendingRequestsRequiringAuthentication removeObjectsInRange:r];
                for (id<ZMTransportRequestSchedulerItem> i in itemsToCancel) {
                    [session temporarilyRejectSchedulerItem:i];
                }
            }
            [self.group leave];
        }];
    });
}

- (void)addItem:(id<ZMTransportRequestSchedulerItem>)item;
{
    [self.backoffItemQueue addObject:item];
    [self.backoff performBlock:^{
        [self processBackoffItem:item];
    }];
}

- (void)processBackoffItem:(id<ZMTransportRequestSchedulerItem>)item;
{
    NSUInteger const idx = [self.backoffItemQueue indexOfObjectIdenticalTo:item];
    if (idx == NSNotFound) {
        return; // Item has already been removed. This will happen when switching to offline.
    }
    [self.backoffItemQueue removeObjectAtIndex:idx];
    
    id<ZMTransportRequestSchedulerSession> session = self.session;
    switch (_schedulerState) {
        case ZMTransportRequestSchedulerStateRateLimitedRetrying:
        case ZMTransportRequestSchedulerStateNormal: {
            if (item.needsAuthentication) {
                if (! session.canStartRequestWithAccessToken) {
                    [session sendAccessTokenRequest];
                    [self.pendingRequestsRequiringAuthentication addObject:item];
                    break;
                }
                if (session.accessTokenIsAboutToExpire) {
                    [session sendAccessTokenRequest];
                }
            }
            [session sendSchedulerItem:item];
            break;
        }
        case ZMTransportRequestSchedulerStateFlush:
        case ZMTransportRequestSchedulerStateRateLimitedHoldingOff:
        case ZMTransportRequestSchedulerStateOffline: {
            [session temporarilyRejectSchedulerItem:item];
            break;
        }
    }
}

- (void)processCompletedURLTask:(NSURLSessionTask *)task;
{
    NSHTTPURLResponse * const response = (id) task.response;
    [self processCompletedURLResponse:response URLError:task.error];
}

- (void)processWebSocketError:(NSError *)error
{
    NSInteger const errorCode = error.code;
    ZMLogDebug(@"%@: errorCode %ld", NSStringFromSelector(_cmd), (long) errorCode);
    
    CheckString((error == nil) || [error.domain isEqualToString:ZMWebSocketErrorDomain], "Invalid error domain.");
    
    if (errorCode == ZMWebSocketErrorCodeLostConnection && !self.reachability.mayBeReachable) {
        ZMLogDebug(@"Scheduler is Offline");
        self.schedulerState = ZMTransportRequestSchedulerStateOffline;
    }
}

- (void)processCompletedURLResponse:(NSHTTPURLResponse *)response URLError:(NSError *)error;
{
    NSInteger const httpStatusCode = response.statusCode;
    NSInteger const errorCode = error.code;
    ZMLogDebug(@"%@: httpStatus %ld errorCode %ld", NSStringFromSelector(_cmd), (long) httpStatusCode, (long) errorCode);
    
    if (self.schedulerState == ZMTransportRequestSchedulerStateFlush) {
        ZMLogDebug(@"In flush mode. Ignoring.");
        return;
    }
    
    CheckString((error == nil) || [error.domain isEqualToString:NSURLErrorDomain], "Invalid error domain.");
    
    if ((100 <= httpStatusCode) && (httpStatusCode <= 399)) {
        [self.backoff reduceBackoff];
    } else if ((500 <= httpStatusCode) && (httpStatusCode <= 599)) {
        [self.backoff increaseBackoff];
    }
    
    if ((errorCode == 0) ||
        (errorCode == NSURLErrorTimedOut))
    {
        if (httpStatusCode == UnauthorizedStatusCode) {
            ZMLogDebug(@"Scheduler is sending access token request");
            id<ZMTransportRequestSchedulerSession> strongSession = self.session;
            [strongSession sendAccessTokenRequest];
        }
        if ((httpStatusCode == TooManyRequestsStatusCode) ||
            (httpStatusCode == EnhanceYourCalmStatusCode))
        {
            ZMLogDebug(@"Scheduler is Backing off");
            self.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
        } else if (self.schedulerState != ZMTransportRequestSchedulerStateRateLimitedHoldingOff) {
            ZMLogDebug(@"Scheduler is Normal");
            self.schedulerState = ZMTransportRequestSchedulerStateNormal;
        }
    } else if (errorCode != 0 && !self.reachability.mayBeReachable) {
        ZMLogDebug(@"Scheduler is Offline");
        self.schedulerState = ZMTransportRequestSchedulerStateOffline;
    }
}

- (void)sessionDidReceiveAccessToken:(id<ZMTransportRequestSchedulerSession>)session;
{
    NOT_USED(session);
    id<ZMTransportRequestSchedulerSession> aSession = self.session;
    Check(session == aSession);
    
    NSArray *items = [self.pendingRequestsRequiringAuthentication copy];
    [self.pendingRequestsRequiringAuthentication removeAllObjects];
    
    for (id<ZMTransportRequestSchedulerItem> item in items) {
        [aSession sendSchedulerItem:item];
    }
}

- (void)applicationWillEnterForeground;
{
    self.schedulerState = ZMTransportRequestSchedulerStateNormal;
}

- (void)reachabilityDidChange:(ZMReachability *)reachability;
{
    NOT_USED(reachability);
    if (self.schedulerState == ZMTransportRequestSchedulerStateOffline) {
        self.schedulerState = ZMTransportRequestSchedulerStateNormal;
    }
}

- (BOOL)canSendRequests
{
    switch (self.schedulerState) {
        case ZMTransportRequestSchedulerStateFlush:
        case ZMTransportRequestSchedulerStateOffline:
            return NO;
        case ZMTransportRequestSchedulerStateNormal:
        case ZMTransportRequestSchedulerStateRateLimitedHoldingOff:
        case ZMTransportRequestSchedulerStateRateLimitedRetrying:
            return YES;
    }
}

- (void)performGroupedBlock:(dispatch_block_t)block;
{
    ZMSDispatchGroup *const group = self.group;
    NSOperationQueue *q = self.workQueue;
    Require(group != nil);
    Require(q != nil);
    
    [group enter];
    [q addOperationWithBlock:^{
        block();
        [group leave];
    }];
}

- (ZMSDispatchGroup *)dispatchGroup;
{
    return self.group;
}

@end



@implementation ZMTransportRequestScheduler (Testing)

@dynamic timeUntilNormalModeWhenNetworkMayBeReachable;

@end
