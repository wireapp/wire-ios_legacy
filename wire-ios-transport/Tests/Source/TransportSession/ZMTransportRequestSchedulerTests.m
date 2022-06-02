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
@import WireTesting;
@import OCMock;

#import "ZMTransportRequestScheduler.h"
#import "ZMExponentialBackoff.h"
#import "Fakes.h"
#import "WireTransport_ios_tests-Swift.h"

//
//
#pragma mark -
//
//

@interface FakeBackoff : NSObject

@property (atomic) NSInteger maximumBackoffCounter;
@property (nonatomic) NSMutableArray *blocks;
@property (nonatomic) NSInteger cancelCount;
@property (nonatomic) NSInteger resetBackoffCount;
@property (nonatomic) NSInteger reduceBackoffCount;
@property (nonatomic) NSInteger increaseBackoffCount;

@end


@implementation FakeBackoff

- (instancetype)init;
{
    self = [super init];
    if (self) {
        self.maximumBackoffCounter = 5;
        self.blocks = [NSMutableArray array];
    }
    return self;
}

- (void)performBlock:(dispatch_block_t)block;
{
    [self.blocks addObject:[block copy]];
}

- (void)cancelAllBlocks;
{
    ++self.cancelCount;
}

- (void)resetBackoff;
{
    ++self.resetBackoffCount;
}

- (void)reduceBackoff;
{
    ++self.reduceBackoffCount;
}

- (void)increaseBackoff;
{
    ++self.increaseBackoffCount;
}

- (void)processAllItems;
{
    //
    // This is used for testing. It executes all blocks.
    //
    NSArray *b = [self.blocks copy];
    [self.blocks removeAllObjects];
    for (dispatch_block_t block in b) {
        block();
    }
}

- (void)tearDown
{
    
}
@end


//
//
#pragma mark -
//
//

@interface FakeSchedulerItem : NSObject <ZMTransportRequestSchedulerItem>

@property (nonatomic) BOOL needsAuthentication;

@end


@implementation FakeSchedulerItem
@end

//
//
#pragma mark - Tests
//
//


@interface ZMTransportRequestSchedulerTests : ZMTBaseTest

@property (nonatomic) ZMTransportRequestScheduler *sut;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) FakeSchedulerSession *session;
@property (nonatomic) FakeReachability *reachability;
@property (nonatomic) FakeBackoff *backoff;

@end



@implementation ZMTransportRequestSchedulerTests

- (void)setUp
{
    [super setUp];
    
    self.reachability = [[FakeReachability alloc] init];
    self.reachability.mayBeReachable = YES;
    self.session = [[FakeSchedulerSession alloc] init];
    self.session.reachability = (id) self.reachability;
    self.backoff = [[FakeBackoff alloc] init];
    self.operationQueue = [NSOperationQueue mainQueue];
    self.sut = [[ZMTransportRequestScheduler alloc] initWithSession:self.session operationQueue:self.operationQueue group:self.dispatchGroup reachability:self.reachability backoff:(id) self.backoff];
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
}

- (void)tearDown
{
    [self.sut tearDown];
    self.sut = nil;
    
    [super tearDown];
}

// C.f. NSURLError.h for error codes, e.g. NSURLErrorUnknown, NSURLErrorCancelled, etc.
- (NSURLSessionTask *)fakeTaskWithHTTPStatusCode:(NSInteger)statusCode URLErrorCode:(NSInteger)code;
{
    id task = [OCMockObject niceMockForClass:FakeDataTask.class];
    NSURL *URL = [NSURL URLWithString:@"https://example.com/test"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:@{}];
    NSError *error = (code == 0) ? nil : [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:nil];
    (void)[(FakeDataTask *) [[task stub] andReturn:response] response];
    (void)[(FakeDataTask *) [[task stub] andReturn:error] error];
    return task;
}

- (void)testThatItStartsOutInNormalMode;
{
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, ZMTransportRequestSchedulerRequestCountUnlimited);
}

- (void)testThatTheNumberOfRequestsIsUnlimitedInNormalMode;
{
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // then
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, ZMTransportRequestSchedulerRequestCountUnlimited);
}

- (void)testThatTheNumberOfRequestsIsZeroInOfflineMode;
{
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // then
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, 0);
}

- (void)testThatTheNumberOfRequestsIsZeroInFlushMode;
{
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // then
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, 0);
}

- (void)testThatTheNumberOfRequestsIsZeroInRateLimitedModeHoldingOff;
{
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    
    // then
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, 0);
}

- (void)testThatTheNumberOfRequestsIsOneInRateLimitedModeRetrying;
{
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    
    // then
    XCTAssertEqual(self.sut.concurrentRequestCountLimit, 1);
}

- (void)testThatItForwardsUnlimitedRequestsWhenInNormalMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 100; ++i) {
        id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    
    // then
    XCTAssertEqualObjects(self.session.sentItems, items);
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
}

- (void)testThatItRejectsRequestsWhenInOfflineMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 100; ++i) {
        id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];

    // then
    XCTAssertEqualObjects(self.session.rejectedItems, items);
    XCTAssertEqual(self.session.sentItems.count, 0u);
}

- (void)testThatItRejectsRequestsWhenInFlushMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 100; ++i) {
        id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    
    // then
    XCTAssertEqualObjects(self.session.rejectedItems, items);
    XCTAssertEqual(self.session.sentItems.count, 0u);
}

- (void)testThatItRejectsRequestsWhenInRateLimitHoldingOffMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 100; ++i) {
        id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    
    // then
    XCTAssertEqualObjects(self.session.rejectedItems, items);
    XCTAssertEqual(self.session.sentItems.count, 0u);
}

- (void)testThatItForwardsUnlimitedRequestsWhenInRateLimitedRetryingMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 10; ++i) {
        id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];

    // then
    XCTAssertEqualObjects(self.session.sentItems, items);
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
}

- (void)testThatSwitchingFromOfflineToNormalModeTriggersAChangedMaximumNumberOfConcurrentRequests;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    WaitForAllGroupsToBeEmpty(0.5);
    int const originalCount = self.session.maximumNumberOfConcurrentRequestsChangeCount;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertGreaterThan(self.session.maximumNumberOfConcurrentRequestsChangeCount, originalCount);
}

- (void)testThatSwitchingFromFlushToNormalModeTriggersAChangedMaximumNumberOfConcurrentRequests;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    WaitForAllGroupsToBeEmpty(0.5);
    int const originalCount = self.session.maximumNumberOfConcurrentRequestsChangeCount;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertGreaterThan(self.session.maximumNumberOfConcurrentRequestsChangeCount, originalCount);
}

- (void)testThatSwitchingFromHoldingOffToRetryModeTriggersAChangedMaximumNumberOfConcurrentRequests;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    WaitForAllGroupsToBeEmpty(0.5);
    int const originalCount = self.session.maximumNumberOfConcurrentRequestsChangeCount;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertGreaterThan(self.session.maximumNumberOfConcurrentRequestsChangeCount, originalCount);
}

- (void)testThatSwitchingFromRetryToNormalModeTriggersAChangedMaximumNumberOfConcurrentRequests;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    WaitForAllGroupsToBeEmpty(0.5);
    int const originalCount = self.session.maximumNumberOfConcurrentRequestsChangeCount;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertGreaterThan(self.session.maximumNumberOfConcurrentRequestsChangeCount, originalCount);
}

- (void)testThatSwitchingFromNormalToOfflineModeDoesNotTriggerAChangedMaximumNumberOfConcurrentRequests;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    WaitForAllGroupsToBeEmpty(0.5);
    int const originalCount = self.session.maximumNumberOfConcurrentRequestsChangeCount;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.session.maximumNumberOfConcurrentRequestsChangeCount, originalCount);
}

- (void)testThatItChangesTheStateToOfflineWhenARequestFails;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    self.reachability.mayBeReachable = NO;
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorCannotFindHost]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateOffline);
}

- (void)testThatItDoesNotChangeTheStateToOfflineWhenARequestFailsButWeAreReachable;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    self.reachability.mayBeReachable = YES;
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorCannotFindHost]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItDoesNotNotifyTheDelegateWhenARequestFails;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorCannotFindHost]];
    
    // then
    XCTAssertEqual(self.session.offlineCount, 0);
}

- (void)testThatItIsNotAffectedByCancelledTasks;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorCancelled]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItIsNotAffectedByTasksThatTimedOut;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorTimedOut]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItChangesTheStateToNormalWhenARequestSucceeds;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:200 URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItDoesNotChangeTheStateOutOfFlushModeWhenARequestSucceeds;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:200 URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateFlush);
}

- (void)testThatItDoesNotChangeTheStateOutOfFlushModeWhenARequestFails;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:0 URLErrorCode:NSURLErrorCannotFindHost]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateFlush);
}

- (void)testThatItChangesTheStateToNormalWhenTheApplicationEntersForeground;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // when
    [self.sut applicationWillEnterForeground];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

@end



@implementation ZMTransportRequestSchedulerTests (AccessToken)

- (void)testThatItDoesNotForwardedRequestsWhenThereIsNotValidAccessToken;
{
    // given
    self.session.canStartRequestWithAccessToken = NO;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    for (int i = 0; i < 10; ++i) {
        FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
        item.needsAuthentication = YES;
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];

    // then
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
}

- (void)testThatItRequestsAnAccessTokenWhenNeeded;
{
    // given
    self.session.canStartRequestWithAccessToken = NO;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
    item.needsAuthentication = YES;
    [self.sut addItem:item];
    [self.backoff processAllItems];

    // then
    XCTAssertEqual(self.session.accessTokenRequestCount, 1);
}

- (void)testThatItRequestsAnAccessTokenWhenTheOldOneIsAboutToExpire;
{
    // given
    self.session.canStartRequestWithAccessToken = YES;
    self.session.accessTokenIsAboutToExpire = YES;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
    item.needsAuthentication = YES;
    [self.sut addItem:item];
    [self.backoff processAllItems];

    // then
    XCTAssertEqual(self.session.accessTokenRequestCount, 1);
    XCTAssertEqualObjects(self.session.sentItems, @[item]);
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
}

- (void)testThatItForwardsPendingRequestsOnceItReceivesAnAccessToken;
{
    // given
    self.session.canStartRequestWithAccessToken = NO;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    NSMutableArray *items = [NSMutableArray array];

    // when
    for (int i = 0; i < 10; ++i) {
        FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
        item.needsAuthentication = YES;
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    [self.sut sessionDidReceiveAccessToken:self.session];
    
    // then
    XCTAssertEqualObjects(self.session.sentItems, items);
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
}

- (void)testThatItRejectsPendingRequestsIfGoingOffline;
{
    // given
    self.session.canStartRequestWithAccessToken = NO;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 10; ++i) {
        FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
        item.needsAuthentication = YES;
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.session.rejectedItems, items);
    XCTAssertEqual(self.session.sentItems.count, 0u);
}

- (void)testThatItRejectsPendingRequestsIfGettingRateLimited
{
    // given
    self.session.canStartRequestWithAccessToken = NO;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    NSMutableArray *items = [NSMutableArray array];
    
    // when
    for (int i = 0; i < 10; ++i) {
        FakeSchedulerItem *item = [[FakeSchedulerItem alloc] init];
        item.needsAuthentication = YES;
        [items addObject:item];
        [self.sut addItem:item];
    }
    [self.backoff processAllItems];
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(self.session.rejectedItems, items);
    XCTAssertEqual(self.session.sentItems.count, 0u);
}

- (void)testThatItRequestsAnAccessTokenWhenProcessingAResponseWith_401_statusCode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:401 URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.session.accessTokenRequestCount, 1);
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

@end



@implementation ZMTransportRequestSchedulerTests (Reachability)

- (void)testThatItSwitchesOutOfOfflineModeIfTheNetworkMayBeReachable;
{
    // given
    NSTimeInterval const interval = 0.05;
    self.sut.timeUntilNormalModeWhenNetworkMayBeReachable = interval;
    self.reachability.mayBeReachable = YES;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // then
    [self spinMainQueueWithTimeout:interval * 0.1];
    NSDate *high = [NSDate dateWithTimeIntervalSinceNow:1];
    XCTAssertNotEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
    XCTAssertTrue([self waitUntilDate:high verificationBlock:^BOOL{
        return (self.sut.schedulerState == ZMTransportRequestSchedulerStateNormal);
    }]);
}

- (void)testThatItDoesNotSwitchOutOfOfflineModeWhenInFlushMode
{
    // given
    NSTimeInterval const interval = 0.05;
    self.sut.timeUntilNormalModeWhenNetworkMayBeReachable = interval;
    self.reachability.mayBeReachable = YES;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // then
    [self spinMainQueueWithTimeout:1.3 * interval];
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateFlush);
}

- (void)testThatItDoesNotSwitchOutOfOfflineModeIfTheNetworkIsNotReachable;
{
    // given
    NSTimeInterval const interval = 0.05;
    self.sut.timeUntilNormalModeWhenNetworkMayBeReachable = interval;
    self.reachability.mayBeReachable = NO;
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // then
    [self spinMainQueueWithTimeout:1.15 * interval];
    XCTAssertNotEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItSwitchesOutOfOfflineIntoNormalModeWhenTheNetworkReachabilityChanges;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // when
    [self.sut reachabilityDidChange:(id) self.reachability];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItDoesNotSwitchOutOfOfflineIntoNormalModeWhenTheNetworkReachabilityChangesAndInFlushMode
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // when
    [self.sut reachabilityDidChange:(id) self.reachability];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateFlush);
}

@end



@implementation ZMTransportRequestSchedulerTests (Backoff)

- (void)testThatAddingAnItemPutsItIntoTheBackoffQueue;
{
    // given
    id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
    
    // when
    [self.sut addItem:item];
    
    // then
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.backoff.blocks.count, 1u);
    
    // when (2)
    [self.backoff processAllItems];
    
    // then
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
    XCTAssertEqual(self.session.sentItems.count, 1u);
    XCTAssertEqual(self.session.sentItems.lastObject, item);
}

- (void)testThatSwitchingToOfflineModeRejectsAllItems;
{
    // given
    id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
    
    // when
    [self.sut addItem:item];
    
    // then
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.backoff.blocks.count, 1u);
    XCTAssertEqual(self.backoff.cancelCount, 0);
    
    // when (2)
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    
    // then (2)
    XCTAssertEqual(self.backoff.cancelCount, 1);
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.session.rejectedItems.count, 1u);
    XCTAssertEqual(self.session.rejectedItems.lastObject, item);

    // when (3)
    [self.backoff processAllItems];
    
    // then (3)
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.session.rejectedItems.count, 1u);
    XCTAssertEqual(self.session.rejectedItems.lastObject, item);
}

- (void)testThatSwitchingToFlushModeRejectsAllItems;
{
    // given
    id<ZMTransportRequestSchedulerItem> item = [[FakeSchedulerItem alloc] init];
    
    // when
    [self.sut addItem:item];
    
    // then
    XCTAssertEqual(self.session.rejectedItems.count, 0u);
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.backoff.blocks.count, 1u);
    XCTAssertEqual(self.backoff.cancelCount, 0);
    
    // when (2)
    self.sut.schedulerState = ZMTransportRequestSchedulerStateFlush;
    
    // then (2)
    XCTAssertEqual(self.backoff.cancelCount, 1);
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.session.rejectedItems.count, 1u);
    XCTAssertEqual(self.session.rejectedItems.lastObject, item);
    
    // when (3)
    [self.backoff processAllItems];
    
    // then (3)
    XCTAssertEqual(self.session.sentItems.count, 0u);
    XCTAssertEqual(self.session.rejectedItems.count, 1u);
    XCTAssertEqual(self.session.rejectedItems.lastObject, item);
}

- (void)testThatSwitchingIntoNormalSchedulingResetsTheBackoff;
{
    // given
    NSInteger originalCount = self.backoff.resetBackoffCount;
    self.sut.schedulerState = ZMTransportRequestSchedulerStateOffline;
    XCTAssertEqual(self.backoff.resetBackoffCount, originalCount);
    
    // when
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // then
    XCTAssertEqual(self.backoff.resetBackoffCount, originalCount + 1);
}

- (void)testThatA_5xx_ResponseIncreasesTheBackoff;
{
    for (NSInteger statusCode = 500; statusCode <= 599; ++statusCode) {
        // given
        NSInteger const originalIncreaseCount = self.backoff.increaseBackoffCount;
        NSInteger const originalResetCount = self.backoff.resetBackoffCount;
        NSInteger const originalReduceCount = self.backoff.reduceBackoffCount;
        
        // when
        [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:statusCode URLErrorCode:0]];
        
        // then
        XCTAssertEqual(self.backoff.increaseBackoffCount, originalIncreaseCount + 1, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.resetBackoffCount, originalResetCount, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.reduceBackoffCount, originalReduceCount, @"HTTP status code %d", (int) statusCode);
    }
}

- (void)testThatA_100_to_399_ResponseReducesTheBackoff;
{
    for (NSInteger statusCode = 100; statusCode <= 299; ++statusCode) {
        // given
        NSInteger const originalIncreaseCount = self.backoff.increaseBackoffCount;
        NSInteger const originalResetCount = self.backoff.resetBackoffCount;
        NSInteger const originalReduceCount = self.backoff.reduceBackoffCount;
        
        // when
        [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:statusCode URLErrorCode:0]];
        
        // then
        XCTAssertEqual(self.backoff.increaseBackoffCount, originalIncreaseCount, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.resetBackoffCount, originalResetCount, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.reduceBackoffCount, originalReduceCount + 1, @"HTTP status code %d", (int) statusCode);
    }
}

- (void)testThatA_4xx_ResponseDoesNotAffectTheBackoff;
{
    for (NSInteger statusCode = 400; statusCode <= 499; ++statusCode) {
        // given
        NSInteger const originalIncreaseCount = self.backoff.increaseBackoffCount;
        NSInteger const originalResetCount = self.backoff.resetBackoffCount;
        NSInteger const originalReduceCount = self.backoff.reduceBackoffCount;
        
        // when
        [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:statusCode URLErrorCode:0]];
        
        // then
        XCTAssertEqual(self.backoff.increaseBackoffCount, originalIncreaseCount, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.resetBackoffCount, originalResetCount, @"HTTP status code %d", (int) statusCode);
        XCTAssertEqual(self.backoff.reduceBackoffCount, originalReduceCount, @"HTTP status code %d", (int) statusCode);
    }
}

- (void)testThatItCancelsAllBackoffBlocksOnTearDown;
{
    // given
    NSInteger originalCount = self.backoff.cancelCount;
    
    // when
    [self.sut tearDown];
    
    // then
    XCTAssertEqual(self.backoff.resetBackoffCount, originalCount + 1);
    
    self.sut = nil;
}

@end



@implementation ZMTransportRequestSchedulerTests (RateLimit)

- (void)testThatItChangesTheStateToRateLimitedWhenARequestHasA_TooManyRequests_StatusCode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:TooManyRequestsStatusCode URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedHoldingOff);
}

- (void)testThatItChangesTheStateToRateLimitedWhenARequestHasA_EnhanceYourCalm_StatusCode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:EnhanceYourCalmStatusCode URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedHoldingOff);
}

- (void)testThatItDoesNotChangeTheStateWhileRateLimitedHoldingOffWhenARequestIsSuccessful
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:200 URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedHoldingOff);
}

- (void)testThatItChangesTheStateToNormalWhenARequestSucceedsWhileInRetryMode;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    
    // when
    [self.sut processCompletedURLTask:[self fakeTaskWithHTTPStatusCode:200 URLErrorCode:0]];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateNormal);
}

- (void)testThatItDoesNotSwitchOutOfRateLimitingHoldingOffWhenTheNetworkReachabilityChanges;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
    
    // when
    [self.sut reachabilityDidChange:(id) self.reachability];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedHoldingOff);
}

- (void)testThatItDoesNotSwitchOutOfRateLimitingRetryWhenTheNetworkReachabilityChanges;
{
    // given
    self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedRetrying;
    
    // when
    [self.sut reachabilityDidChange:(id) self.reachability];
    
    // then
    XCTAssertEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedRetrying);
}

- (void)testThatItSwitchesToRetryStateAfterWaitingInRateLimitState;
{
    // We'll run this a few times, since the time interval is randomly shifted, and we want to try a few outcomes:
    for (int i = 0; i < 5; ++i) {
        // given
        NSTimeInterval const interval = 0.1;
        self.sut.timeUntilRetryModeWhenRateLimited = interval;
        
        // when
        self.sut.schedulerState = ZMTransportRequestSchedulerStateRateLimitedHoldingOff;
        
        // then
        
        // backoffAdjustement * randrom adjustment * interval
        [self spinMainQueueWithTimeout: 0.1 * interval];
        XCTAssertNotEqual(self.sut.schedulerState, ZMTransportRequestSchedulerStateRateLimitedRetrying, @"Iteration: %d", i);
        
        // we create a date that is above to the limit mode time to ensure it switches time
        NSDate *high = [NSDate dateWithTimeIntervalSinceNow:interval * 2];
        
        XCTAssertTrue([self waitUntilDate:high verificationBlock:^BOOL{
            return (self.sut.schedulerState == ZMTransportRequestSchedulerStateRateLimitedRetrying);
        }]);
        
        // finally
        self.sut.schedulerState = ZMTransportRequestSchedulerStateNormal;
        
    }
}

- (void)testThatItStartsInOfflineModeIfReachabilityIsNotReachable
{
    // given
    FakeReachability *reachability = [[FakeReachability alloc] init];
    reachability.mayBeReachable = NO;
    
    // when
    ZMTransportRequestScheduler *sut = [[ZMTransportRequestScheduler alloc] initWithSession:self.session operationQueue:self.operationQueue group:self.dispatchGroup reachability:reachability];
    
    // then
    XCTAssertEqual(sut.schedulerState, ZMTransportRequestSchedulerStateOffline);
    
    // after
    [sut tearDown];
}

@end
