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

#import "MessagingTest.h"

@interface MessagingTestTests : MessagingTest

@end


@implementation MessagingTestTests

- (void)testThatZMAssertQueueFailsWhenNotOnQueue
{
    NSOperationQueue *queue = [NSOperationQueue zm_serialQueueWithName:self.name];
    void(^doAssert)(void) = ^(void) { ZMAssertQueue(queue); };
    XCTAssertThrows(doAssert());
}

- (void)testThatWeCanCreateUUIDs;
{
    XCTAssertEqualObjects([NSUUID createUUID], [@"7BDA726A-13DC-4E46-A95D-2C872D340001" UUID]);
    XCTAssertEqualObjects([NSUUID createUUID], [@"7BDA726A-13DC-4E46-A95D-2C872D340002" UUID]);
    XCTAssertEqualObjects([NSUUID createUUID], [@"7BDA726A-13DC-4E46-A95D-2C872D340003" UUID]);
}

- (void)testArrayDifference
{
    NSArray *a1 = @[@4, @"foo", @"boo"];
    NSArray *a2 = @[@"foo", @"boo", @4];

    AssertArraysContainsSameObjects(a1, a2);
}

@end
