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
@import WireSystem;
@import WireUtilities;
@import WireTesting;

#import "ZMExponentialBackoff.h"



@interface ZMExponentialBackoffTests : ZMTBaseTest

@property (nonatomic) ZMExponentialBackoff *sut;
@property (nonatomic) NSOperationQueue *workQueue;

@end

static NSTimeInterval const baseBackoff = 0.025;




@implementation ZMExponentialBackoffTests

- (void)setUp
{
    [super setUp];
    
    self.workQueue = [NSOperationQueue zm_serialQueueWithName:self.name];
    self.sut = [[ZMExponentialBackoff alloc] initWithGroup:self.dispatchGroup workQueue:self.workQueue];
    self.sut.maximumBackoffCounter = 6;
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(1); // tear down will cancel blocks, ie. we might fail to leave the group.
    [self.sut tearDown];
    self.sut = nil;
    self.workQueue = nil;
    [super tearDown];
}

- (void)testThatItDefaultsToRunningTheBlocksSynchronously;
{
    // given
    __block int c = 0;
    
    // when
    for (int i = 0; i < 100; ++i) {
        [self.sut performBlock:^{
            ++c;
        }];
    }
    
    // then
    XCTAssertEqual(c, 100);
}

- (void)testThatItRunsASingleBlocksWhenTheBackoffIsActive
{
    // given
    __block int c = 0;
    
    // when
    [self.sut increaseBackoff];
    
    [self.dispatchGroup enter];
    [self.sut performBlock:^{
        ++c;
        [self.dispatchGroup leave];
    }];
    WaitForAllGroupsToBeEmpty(baseBackoff + 0.5);
    
    // then (2)
    XCTAssertEqual(c, 1);
}

- (void)testThatItRunsBlocksOneByOneIfTheBackoffIsActive;
{
    // given
    int const iterations = 16;
    __block int c = 0;
    
    // when
    [self.sut increaseBackoff];
    
    for (int i = 0; i < iterations; ++i) {
        [self.dispatchGroup enter];
        [self.sut performBlock:^{
            ++c;
            [self.dispatchGroup leave];
        }];
    }
    
    // then
    XCTAssertLessThan(c, iterations / 2);

    // when (2)
    NSTimeInterval expectedDuration = baseBackoff * iterations * 2;
    NSTimeInterval const start = [NSDate timeIntervalSinceReferenceDate];
    WaitForAllGroupsToBeEmpty(expectedDuration*2);
    NSTimeInterval const duration = [NSDate timeIntervalSinceReferenceDate] - start;
    
    // then (2)
    XCTAssertEqual(c, iterations);
    XCTAssertEqualWithAccuracy(duration, expectedDuration, expectedDuration * 0.5);
}

- (void)testThatResettingTheBackoffCausesAllBlocksToRunImmediately;
{
    // given
    int const iterations = 16;
    __block int c = 0;
    
    // when
    [self.sut increaseBackoff];
    
    for (int i = 0; i < iterations; ++i) {
        [self.dispatchGroup enter];
        [self.sut performBlock:^{
            ++c;
            [self.dispatchGroup leave];
        }];
    }
    [self.sut resetBackoff];
    // wait a tiny bit, in case some of them ended up being caught up in the timer magic:
    WaitForAllGroupsToBeEmpty(baseBackoff + 0.5);
    
    // then
    XCTAssertEqual(c, iterations);
}

@end
