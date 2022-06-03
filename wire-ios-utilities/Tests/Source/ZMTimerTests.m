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
@import WireTesting;

#import <XCTest/XCTest.h>
#import "ZMTimer.h"


@interface TimerClient : NSObject <ZMTimerClient>

@property (nonatomic) NSDate *firingDate;
@property (nonatomic, copy) void(^block)(ZMTimer *);

@end


@implementation TimerClient

- (void)timerDidFire:(ZMTimer *)timer
{
    NOT_USED(timer);
    self.firingDate = [NSDate date];
    
    if (self.block != nil) {
        self.block(timer);
    }
    
}

@end




@interface ZMTimerTests : ZMTBaseTest

@property (nonatomic) TimerClient *timerClient;
@property (nonatomic) ZMTimer *sut;

@end


@implementation ZMTimerTests

- (void)setUp {
    [super setUp];
    self.timerClient = [[TimerClient alloc] init];
    
    self.sut = [ZMTimer timerWithTarget:self.timerClient];
}

- (void)tearDown {
    [super tearDown];
    self.sut = nil;
    self.timerClient = nil;
}

- (void)setUpTimerExpectation
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"timer fired"];
    
    ZM_WEAK(self);
    self.timerClient.block = ^(ZMTimer *timer) {
        ZM_STRONG(self);
        XCTAssertEqual(timer, self.sut);
        [expectation fulfill];
    };

}

- (void)assertThatTimerFiredRecently
{
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:2.1]);
    NSDate *nownow = [NSDate date];
    XCTAssertNotNil(self.timerClient.firingDate);
    NSTimeInterval timeDifference = fabs([self.timerClient.firingDate timeIntervalSinceDate:nownow]);
    
    XCTAssertLessThan(timeDifference, 10);
}

- (void)testThatItFiresAtACertainDate {

    // given
    [self setUpTimerExpectation];
    
    // when
    NSDate *now = [NSDate date];
    NSDate *fireDate = [now dateByAddingTimeInterval:1];
    [self.sut fireAtDate:fireDate];

    // then
    [self assertThatTimerFiredRecently];
}



- (void)testThatItFiresAfterAnInterval
{
    // given
    [self setUpTimerExpectation];
    
    // when
    [self.sut fireAfterTimeInterval:1];
    
    // then
    [self assertThatTimerFiredRecently];
}

- (void)testThatItFiresImmediatelyIfTheIntervalIsInThePast
{
    // given
    [self setUpTimerExpectation];
    
    // when
    [self.sut fireAfterTimeInterval:-1];
    
    // then
    [self assertThatTimerFiredRecently];
    
}


- (void)testThatItFiresImmediatelyIfTheDateIsInThePast
{
    // given
    [self setUpTimerExpectation];
    
    // when
    [self.sut fireAtDate:[NSDate dateWithTimeIntervalSinceNow:-1]];
    
    // then
    [self assertThatTimerFiredRecently];
    
}


- (void)testThatItDoesNotFireIfItWasCanceled
{
    // given
    [self setUpTimerExpectation];
    
    // when
    [self.sut fireAfterTimeInterval:1];
    [self.sut cancel];
    
    // then
    [self spinMainQueueWithTimeout:1.3];
    XCTAssertFalse([self verifyAllExpectationsNow]); // Should *not* have fire
}


- (void)testThatItPreservesUserInfo
{
    // given
    NSDictionary *expectedInfo = @{ @"numbers" : @[@4, @8, @15, @16, @23, @42] };
    [self setUpTimerExpectation];
    self.sut.userInfo = expectedInfo;
    
    // when
    [self.sut fireAfterTimeInterval:1];
    
    // then
    [self assertThatTimerFiredRecently];
    XCTAssertEqual(self.sut.userInfo, expectedInfo);
}

- (void)testThatItCallsClientOnASpecificOperationQueue
{
    // given
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [self.sut cancel];
    self.sut = [ZMTimer timerWithTarget:self.timerClient operationQueue:queue];
    XCTestExpectation *expectation = [self expectationWithDescription:@"timer fired"];
    
    ZM_WEAK(self);
    self.timerClient.block = ^(ZMTimer *timer) {
        ZM_STRONG(self);
        XCTAssertEqual(timer, self.sut);
        XCTAssertEqual([NSOperationQueue currentQueue], queue);
        [expectation fulfill];
    };
    
    
    // when
    [self.sut fireAfterTimeInterval:1];
    
    // then
    [self assertThatTimerFiredRecently];
}

- (void)testThatItCanBeCancelledMultipleTimes;
{
    [self.sut fireAfterTimeInterval:1000];
    [self.sut cancel];
    [self.sut cancel];
    [self.sut cancel];
}

@end
