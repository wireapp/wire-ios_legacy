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
#import <XCTest/XCTest.h>

#import "NSURL+WireLocale.h"


@interface NSURLWireLocaleTests : XCTestCase

@end

@implementation NSURLWireLocaleTests

- (void)testThatLocaleParameterGetAppended
{
    // given
    NSURL *URL = [NSURL URLWithString:@"http://wire.com"];
    
    // when
    NSURL *localizedURL = [URL wr_URLByAppendingLocaleParameter];
    NSString *URLResult = [localizedURL absoluteString];
    
    // then
    XCTAssertNotNil(URLResult);
    BOOL contains = [URLResult containsString:[NSString stringWithFormat:@"%@=", WireParameterKeyLocale]];
    XCTAssertTrue(contains);
}

- (void)testThatLocaleParameterGetAppendedRightWithQuestionMarkAtTheEnd
{
    // given
    NSURL *URL = [NSURL URLWithString:@"http://wire.com?"];
    
    // when
    NSURL *localizedURL = [URL wr_URLByAppendingLocaleParameter];
    NSString *URLResult = [localizedURL absoluteString];
    
    // then
    XCTAssertNotNil(URLResult);
    BOOL contains = [URLResult containsString:[NSString stringWithFormat:@"?%@=", WireParameterKeyLocale]];
    XCTAssertTrue(contains);
    XCTAssertFalse([URL.absoluteString containsString:@"??"]);
}

- (void)testThatLocaleParameterGetAppendedRightWithOtherParameters
{
    // given
    NSURL *URL = [NSURL URLWithString:@"http://wire.com?test=1&"];
    
    // when
    NSURL *localizedURL = [URL wr_URLByAppendingLocaleParameter];
    NSString *URLResult = [localizedURL absoluteString];
    
    // then
    XCTAssertNotNil(URLResult);
    BOOL contains = [URLResult containsString:[NSString stringWithFormat:@"&%@=", WireParameterKeyLocale]];
    XCTAssertTrue(contains);
    XCTAssertTrue([URLResult containsString:@"test=1"]);
    XCTAssertFalse([URL.absoluteString containsString:@"&&"]);
}

- (void)testThatLocaleParameterGetAppendedRightWithOtherParametersNoAndCharacter
{
    // given
    NSURL *URL = [NSURL URLWithString:@"http://wire.com?test=1"];
    
    // when
    NSURL *localizedURL = [URL wr_URLByAppendingLocaleParameter];
    NSString *URLResult = [localizedURL absoluteString];
    
    // then
    XCTAssertNotNil(URLResult);
    BOOL contains = [URLResult containsString:[NSString stringWithFormat:@"&%@=", WireParameterKeyLocale]];
    XCTAssertTrue(contains);
    XCTAssertTrue([URLResult containsString:@"test=1"]);
    XCTAssertFalse([URL.absoluteString containsString:@"&&"]);
}

@end
