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
@import WireUtilities;
@import WireTesting;

@interface NSUUIDDataTests : XCTestCase

@end

@implementation NSUUIDDataTests

- (void)testThatDataCreateFromUUIDIsNotEmpty;
{
    NSUUID *UUID = [NSUUID UUID];
    NSData *data = [UUID data];
   
    XCTAssertNotNil(data);
    XCTAssertNotEqual([data length], 0lu);
}

- (void)testThatDataCreateFromUUIDContainsCorrectData;
{
    const uuid_t UUIDBytes = "0123456789abcdef";
    
    NSUUID *UUID = [[NSUUID alloc] initWithUUIDBytes:UUIDBytes];
    NSData *data = [UUID data];
   
    int comparasionResult = memcmp([data bytes], UUIDBytes, sizeof(UUIDBytes));
    XCTAssertEqual(comparasionResult, 0);
}

@end
