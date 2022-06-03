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
#import <WireSystem/WireSystem.h>

@interface ZMSAssertionTests : XCTestCase

@end

@implementation ZMSAssertionTests

- (void)setUp {
    [super setUp];
    [[NSFileManager defaultManager] removeItemAtURL:ZMLastAssertionFile() error:nil];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtURL:ZMLastAssertionFile() error:nil];
    [super tearDown];
}

- (void)testThatItDumpToCrashFile {
    
    // given
    NSString *expected = @"ASSERT: [printer.c:234] <lp0 != 0> lp0 on fire";
    
    // when
    ZMAssertionDump("lp0 != 0", "printer.c", 234, "lp%d on fire", 0);
    
    // then
    NSString *dump = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:ZMLastAssertionFile()] encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(dump, expected);
}

@end
