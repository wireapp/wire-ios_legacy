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
#import "NSSet+Zeta.h"



@interface NSSetAdditionsTests : XCTestCase
@end



@implementation NSSetAdditionsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItCombinesSets_1
{
    // given
    NSSet *a = [NSSet setWithObjects:@"A", @"B", nil];
    NSSet *b = [NSSet setWithObjects:@"C", @"D", nil];
    
    // when
    NSSet *result = [NSSet zmSetByCompiningSets:a, b, nil];
    
    // then
    NSSet *expected = [NSSet setWithObjects:@"A", @"B", @"C", @"D", nil];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItCombinesSets_2
{
    // given
    NSSet *a = [NSSet setWithObjects:@"A", @"B", nil];
    NSSet *b = [NSSet setWithObjects:@"C", @"D", nil];
    
    // when
    NSSet *result = [NSSet zmSetByCompiningSets:(NSSet * const []){a, b} count:2];
    
    // then
    NSSet *expected = [NSSet setWithObjects:@"A", @"B", @"C", @"D", nil];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItReturnsAnEmptySetWhenCombiningNothing_1
{
    // when
    NSSet *result = [NSSet zmSetByCompiningSets:nil];
    
    // then
    XCTAssertEqualObjects(result, [NSSet set]);
}

- (void)testThatItReturnsAnEmptySetWhenCombiningNothing_2
{
    // when
    NSSet *result = [NSSet zmSetByCompiningSets:(NSSet * const []){} count:0];
    
    // then
    XCTAssertEqualObjects(result, [NSSet set]);
}

@end
