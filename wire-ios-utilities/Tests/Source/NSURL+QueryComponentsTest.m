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
#import "NSURL+QueryComponents.h"


@interface NSURLQueryComponentsTest : XCTestCase

@end

@implementation NSURLQueryComponentsTest

- (void)testThatItParsesAllQueryComponents
{
    // given
    NSURL *url = [NSURL URLWithString:@"https://www.wire.com/path/some?foo=bar&gg=1&ff=&data=213-324"];
    NSDictionary *expected = @{
                               @"foo" : @"bar",
                               @"gg" : @"1",
                               @"data" : @"213-324",
                               @"ff" : @""
                               };
    
    
    // when
    NSDictionary *components = url.zm_queryComponents;
    
    // then
    XCTAssertEqualObjects(components, expected);
}

- (void)testThatItDoesNotParsesQueryComponentsOnMalformedURL_1
{
    // given
    NSURL *url = [NSURL URLWithString:@"https://www.wire.com/path/some?zuid=bar=baz"];
    
    // when
    NSDictionary *components = url.zm_queryComponents;
    
    // then
    XCTAssertEqual(components.count, 0u);
}

- (void)testThatItDoesNotParsesQueryComponentsOnMalformedURL_2
{
    // given
    NSURL *url = [NSURL URLWithString:@"https://www.wire.com/path/some?zuid=bar?baz=22"];
    
    // when
    NSDictionary *components = url.zm_queryComponents;
    
    // then
    XCTAssertEqual(components.count, 0u);
}

@end
