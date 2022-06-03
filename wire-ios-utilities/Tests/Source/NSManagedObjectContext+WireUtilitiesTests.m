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


#import <XCTest/XCTest.h>
#import "NSManagedObjectContext+WireUtilities.h"
#import <objc/runtime.h>
@import WireSystem;
@import WireTesting;

@interface NSManagedObjectContext_WireUtilitiesTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *MOC;

@end

@implementation NSManagedObjectContext_WireUtilitiesTests

- (void)setUp;
{
    [super setUp];
    self.MOC = [ZMMockManagedObjectContextFactory testManagedObjectContextWithConcurencyType:NSPrivateQueueConcurrencyType];
    [self.MOC createDispatchGroups];
}

- (void)tearDown;
{
    self.MOC = nil;
    [super tearDown];
}

- (void)testThatGroupIsProperlyAddedInDispatchGroups;
{
    // given
    ZMSDispatchGroup *group = [ZMSDispatchGroup groupWithLabel:@"TestingGroup"];
    [self.MOC addGroup:group];
    
    // when
    NSArray *groups = [self.MOC enterAllGroups];
    
    // then
    XCTAssertEqual([groups count], 3lu);
    XCTAssertEqualObjects(groups[2], group);
    
    [self.MOC leaveAllGroups:groups];
}

- (void)testThatEnteringGroupsWithoutAllGroupsLeavingDoesNotNofity;
{
    // given
    XCTestExpectation *expectation = [self expectationWithDescription:@"notifyWhenGroupIsEmpty"];
    
    NSArray *groups = [self.MOC enterAllGroups];
    
    // when
    [self.MOC notifyWhenGroupIsEmpty:^{
        [expectation fulfill];
    }];
    
    // then
    XCTAssertFalse([self waitForCustomExpectationsWithTimeout:0.0], "Should fail since we didn't leave groups"); //all but 1 group done, should fa
    
    [self.MOC leaveAllGroups:groups];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1.0], "Should fail since one group is still doing some work, therefore MOC should not notify");
}

- (void)testThatManagedObjextAutomaticallyEnterLeaveGroupWhenUsingPerformGroup;
{
    // given
    XCTestExpectation *expectation = [self expectationWithDescription:@"notifyWhenGroupIsEmpty called"];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // this second semaphore is to make sure that the rest of the execution happens after performGroupedBlock start executing and is waiting
    dispatch_semaphore_t controlSemaphore = dispatch_semaphore_create(0);
    
    // when
    [self.MOC performGroupedBlock:^{
        dispatch_semaphore_signal(controlSemaphore);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
    [self.MOC notifyWhenGroupIsEmpty:^{
        [expectation fulfill];
    }];
    
    // then
    // wait here to make sure the MOC grouped block is starting executing, and is waiting
    dispatch_semaphore_wait(controlSemaphore, DISPATCH_TIME_FOREVER);
    
    XCTAssertFalse([self waitForCustomExpectationsWithTimeout:0.0]);
    
    dispatch_semaphore_signal(semaphore); // unblock the MOC group block
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:1.0]);
}

- (void)testThatTheGroupIsNotifiedOnlyAfterAdditionallyEnqueuedBlocksAreDone;
{
    // given
    // block the MOC!
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [self.MOC performGroupedBlock:^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }];
    
    __block BOOL didRunA = NO;
    __block BOOL didRunB = NO;
    __block BOOL didRunC = NO;
    __block BOOL didRunD = NO;
    __block BOOL didRunABeforeB = NO;
    __block BOOL didRunCBeforeB = NO;
    __block BOOL didRunDBeforeB = NO;
    [self.MOC performGroupedBlock:^{
        didRunA = YES;
    }];
    [self.MOC notifyWhenGroupIsEmpty:^{
        didRunABeforeB = didRunA;
        didRunCBeforeB = didRunC;
        didRunDBeforeB = didRunD;
        didRunB = YES;
    }];
    [self.MOC performGroupedBlock:^{
        didRunC = YES;
        [self.MOC performGroupedBlock:^{
            didRunD = YES;
        }];
    }];
    
    // Need this twice, since the group will be empty, and only then
    // the notifyWhenGroupIsEmpty will get enqueued.

    // when
    dispatch_semaphore_signal(sem);
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return didRunB;
    } timeout:0.5]);
    
    // then
    XCTAssertTrue(didRunA);
    XCTAssertTrue(didRunB);
    XCTAssertTrue(didRunC);
    XCTAssertTrue(didRunABeforeB);
    XCTAssertTrue(didRunCBeforeB);
}

@end
