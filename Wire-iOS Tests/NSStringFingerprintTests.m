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


@import Foundation;
@import XCTest;


@interface NSStringFingerprintTests : XCTestCase

@end

@implementation NSStringFingerprintTests

- (void)testThatFingerprintSplitsProperlyFor2 {
    // given
    NSArray *testStrings = @[@"abc", @"mfngsdnfgljsfgjdns", @"!!@#!@#!@#AASDF", @""];
    
    NSArray *resultStrings = @[@"ab c", @"mf ng sd nf gl js fg jd ns", @"!! @# !@ #! @# AA SD F", @""];
    
    for (NSUInteger i = 0; i < testStrings.count; i++) {
        // when
        
        NSString *splitString = [testStrings[i] fingerprintStringWithSpaces];
        
        // then
        XCTAssertEqualObjects(splitString, resultStrings[i], @"Split is not correct");
    }
}

- (void)testThatFingerprintSplitsProperlyFor4 {
    // given
    NSArray *testStrings = @[@"abc", @"mfngsdnfgljsfgjdns", @"!!@#!@#!@#AASDF", @""];
    
    NSArray *resultStrings = @[@"abc", @"mfng sdnf gljs fgjd ns", @"!!@# !@#! @#AA SDF", @""];
    
    for (NSUInteger i = 0; i < testStrings.count; i++) {
        // when
        
        NSString *splitString = [[testStrings[i] splitEvery:4] componentsJoinedByString:@" "];
        
        // then
        XCTAssertEqualObjects(splitString, resultStrings[i], @"Split is not correct");
    }
}


@end
