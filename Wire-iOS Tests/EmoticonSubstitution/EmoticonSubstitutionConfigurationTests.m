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


@import XCTest;
#import "EmoticonSubstitutionConfiguration.h"
#import "EmoticonSubstitutionConfiguration+Tests.h"
#import "NSString+EmoticonSubstitution.h"
#import "EmoticonSubstitutionConfigurationMocks.h"

@interface EmoticonSubstitutionConfigurationTests : XCTestCase

@end

@implementation EmoticonSubstitutionConfigurationTests

- (void)testThatParsingFileReturnsAConfiguration
{
    // Given
    
    // When
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-01.json"];
    
    // Then
    XCTAssertNotNil(config);
}



- (void)testThatParsingFileContainsCorrectRules
{
    // Given
    
    // When
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-01.json"];
    XCTAssertNotNil(config);
    
    // Then
    XCTAssertNotNil(config.substitutionRules[@":)"], @"':)' shortcut not parsed");
    XCTAssertNotNil(config.substitutionRules[@":-)"], @"':-)' shortcut not parsed");
    
    XCTAssertEqualObjects(config.substitutionRules[@":)"], @"😊");
    XCTAssertEqualObjects(config.substitutionRules[@":-)"], @"😊");
}

- (void)testThatParsingPerformanceForFullConfigurationIsEnoughForUsingOnMainQueue
{
    // EmoticonSubstitutionConfiguration is intended to be used on main thread,
    // so performance is important: parsing should not take much time.
    
    // Given
    
    [self measureBlock:^{
        // When
        EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emoticons.min.json"];
        
        // Then
        XCTAssertNotNil(config);
    }];
}

- (void)testThatShortcutsAreSortedCorrectly
{
    // Given
    
    // When
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-02.json"];
    XCTAssertNotNil(config);
    
    // Then
    XCTAssertEqualObjects(config.shortcuts[0], @"}:-)");
    XCTAssertEqualObjects(config.shortcuts[1], @":-)");
    XCTAssertEqualObjects(config.shortcuts[2], @":)");
}

@end
