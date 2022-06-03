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
#import "NSDate+Utility.h"


@interface NSDate_UtilityTests : XCTestCase

@end



@implementation NSDate_UtilityTests

- (void)testThatItReturnsTheEarlierDate
{
    // given
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:1000000];
    NSDate *date2 = [NSDate dateWithTimeInterval:1000 sinceDate:date1];
    NSDate *date3 = [NSDate dateWithTimeInterval:-1000 sinceDate:date1];
    
    // then
    XCTAssertEqualWithAccuracy([NSDate earliestOfDate:date1 and:date2].timeIntervalSinceReferenceDate, date1.timeIntervalSinceReferenceDate, 0.1);
    XCTAssertEqualWithAccuracy([NSDate earliestOfDate:date1 and:date3].timeIntervalSinceReferenceDate, date3.timeIntervalSinceReferenceDate, 0.1);
}

- (void)testThatItReturnsTheLatestDate
{
    // given
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:1000000];
    NSDate *date2 = [NSDate dateWithTimeInterval:1000 sinceDate:date1];
    NSDate *date3 = [NSDate dateWithTimeInterval:-1000 sinceDate:date1];
    
    // then
    XCTAssertEqualWithAccuracy([NSDate lastestOfDate:date1 and:date2].timeIntervalSinceReferenceDate, date2.timeIntervalSinceReferenceDate, 0.1);
    XCTAssertEqualWithAccuracy([NSDate lastestOfDate:date1 and:date3].timeIntervalSinceReferenceDate, date1.timeIntervalSinceReferenceDate, 0.1);
}

- (void)testThatItReturnsTheNonNullDate
{
    // given
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:100];
    
    // then
    XCTAssertEqualObjects([NSDate earliestOfDate:nil and:date], date);
    XCTAssertEqualObjects([NSDate earliestOfDate:date and:nil], date);
    XCTAssertEqualObjects([NSDate lastestOfDate:nil and:date], date);
    XCTAssertEqualObjects([NSDate lastestOfDate:date and:nil], date);
}

@end
