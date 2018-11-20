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
#import "OCMock/OCMock.h"
#import "NSString+EmoticonSubstitution.h"
#import "EmoticonSubstitutionConfigurationMocks.h"

@interface NSString_EmoticonSubstitution : XCTestCase

@end

@implementation NSString_EmoticonSubstitution

- (void)testThatAllEmoticonSubstitutionForNonMockedConfigurationWorks {
    // Given
    NSString *targetString =
        @"😊😊😄😄😀😀😎😎😎😞😞😉😉😉😉😕😛😛😛😛😜😜😜😜😮😮😇😇😇😇😏😠😠😡😈😈😈😈😢😢😢😂😂😘😘😘😐😐😳😶😶😶😶🙌❤💔";
    NSString *string = @":):-):D:-D:d:-dB-)b-)8-):(:-(;);-);-];]:-/:P:-P:p:-p;P;-P;p;-p:o:-oO:)O:-)o:)o:-);^):-||:@>:(}:-)}:)3:-)3:):'-(:'(;(:'-):'):*:^*:-*:-|:|:$:-X:X:-#:#\\o/<3</3";
    
    // When
    NSString *resolvedString = [string stringByResolvingEmoticonShortcuts];
    
    // Then
    XCTAssertEqualObjects(resolvedString, targetString);
}

- (void)testThatSimpleSubstitutionWorks {
    // Given
    NSString *targetString = @"Hello, my darling!😊 I love you <3!";
    
    id classMock = OCMClassMock([EmoticonSubstitutionConfiguration class]);
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-01.json"];
    OCMStub([classMock sharedInstance]).andReturn(config);
    
    NSString *testString = @"Hello, my darling!:) I love you <3!";
    
    // When
    NSString *resolvedString = [testString stringByResolvingEmoticonShortcuts];

    // Then
    XCTAssertEqualObjects(resolvedString, targetString);
}

- (void)testThatSubstitutionInSpecificRangeWorks {
    // Given
    NSString *targetString = @"Hello, my darling!😊 I love you <3!";
    
    id classMock = OCMClassMock([EmoticonSubstitutionConfiguration class]);
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-03.json"];
    OCMStub([classMock sharedInstance]).andReturn(config);
    
    NSString *testString = @"Hello, my darling!:) I love you <3!";
    NSMutableString *resolvedString = [testString mutableCopy];
    
    // When
    [resolvedString resolveEmoticonShortcutsInRange:NSMakeRange(0, 22)];

    // Then
    XCTAssertEqualObjects(resolvedString, targetString);
}

- (void)testThatSubstitutionInTailRangeWorks {
    // Given
    NSString *targetString = @"<3 Lorem Ipsum Dolor 😈Ame😊 😊";

    id classMock = OCMClassMock([EmoticonSubstitutionConfiguration class]);
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-03.json"];
    OCMStub([classMock sharedInstance]).andReturn(config);

    NSString *testString = @"<3 Lorem Ipsum Dolor }:-)Ame:) :)";
    NSMutableString *resolvedString = [testString mutableCopy];

    // When
    [resolvedString resolveEmoticonShortcutsInRange:NSMakeRange(20, 13)];

    // Then
    XCTAssertEqualObjects(resolvedString, targetString);
}

- (void)testThatSubstitutionInMiddleRangeWorks {
    // Given
    NSString *targetString = @"Hello, my darling!😊 I love you <3!";

    id classMock = OCMClassMock([EmoticonSubstitutionConfiguration class]);
    EmoticonSubstitutionConfiguration *config = [EmoticonSubstitutionConfigurationMocks configurationFromFile:@"emo-test-03.json"];
    OCMStub([classMock sharedInstance]).andReturn(config);

    NSString *testString = @"Hello, my darling!:) I love you <3!";
    NSMutableString *resolvedString = [testString mutableCopy];

    // When
    [resolvedString resolveEmoticonShortcutsInRange:NSMakeRange(10, 22)];

    // Then
    XCTAssertEqualObjects(resolvedString, targetString);
}

@end
