//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

#import <WireUtilities/WireUtilities.h>
#import <WireUtilities/WireUtilities-Swift.h>

@interface ZMAccentColorValidatorTests : XCTestCase

@end

@implementation ZMAccentColorValidatorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItLimitsTheAccentColorToAValidRange;
{
    // given
    id value = [NSNumber numberWithInt:ZMAccentColorBrightYellow];
    //when
    [ZMAccentColorValidator validateValue:&value error:NULL];
    //then
    XCTAssertEqual([value intValue], ZMAccentColorBrightYellow);
    
    //given
    value = [NSNumber numberWithInt:ZMAccentColorUndefined];
    // when
    [ZMAccentColorValidator validateValue:&value error:NULL];
    // then
    XCTAssertGreaterThanOrEqual([value intValue], ZMAccentColorMin);
    XCTAssertLessThanOrEqual([value intValue], ZMAccentColorMax);
    
    //give
    value = [NSNumber numberWithInt:(ZMAccentColor) (ZMAccentColorMax + 1)];
    // when
    [ZMAccentColorValidator validateValue:&value error:NULL];
    
    // then
    XCTAssertGreaterThanOrEqual([value intValue], ZMAccentColorMin);
    XCTAssertLessThanOrEqual([value intValue], ZMAccentColorMax);
}

@end
