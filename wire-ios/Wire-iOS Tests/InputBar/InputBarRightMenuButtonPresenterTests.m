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


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "InputBarRightMenuButtonPresenter.h"

@interface InputBarRightMenuButtonPresenterTests: XCTestCase

@property (nonatomic, strong) InputBarRightMenuButtonPresenter *presenter;

@end


@implementation InputBarRightMenuButtonPresenterTests

- (void)setUp
{
    [super setUp];
    
    self.presenter = [[InputBarRightMenuButtonPresenter alloc] init];
}

- (void)tearDown
{
    [super tearDown];
    
    self.presenter = nil;
}

- (void)testThatMenuButtonIsNotVisibleForNilStrings
{
    // given
    NSString *textNil = nil;
    
    // when
    BOOL result = [self.presenter shouldShowRightMenuButtonWithInputText:textNil];
    
    // then
    XCTAssertEqual(result, NO);
}

- (void)testThatMenuButtonIsNotVisibleForInvalidStrings
{
    // given
    // Just spaces, empty string, tab char
    NSArray *strings = @[@"                       ", @"", @"    "];
    
    // when
    for (NSString *input in strings) {
        BOOL result = [self.presenter shouldShowRightMenuButtonWithInputText:input];
        
        // then
        XCTAssertEqual(result, NO);
    }
}

- (void)testThatMenuButtonIsNotVisibleForBreakLineInput
{
    // given
    NSArray *lineBreaks = @[@"\r", @"\n", @"\r\n"];
    
    // when
    for (NSString *input in lineBreaks) {
        BOOL result = [self.presenter shouldShowRightMenuButtonWithInputText:input];
        
        // then
        XCTAssertEqual(result, NO);
    }
}

- (void)testThatMenuBarButtonIsNotVisibleForTooManyWords
{
    // given
    NSString *input = @"This is a long long text";
    
    // when
    BOOL result = [self.presenter shouldShowRightMenuButtonWithInputText:input];
    
    // then
    XCTAssertEqual(result, NO);
}

- (void)testThatMenuBarButtonIsVisibleForShortSentences
{
    // given
    NSArray *input = @[@"funny cat", @"homer simpson"];
    
    // when
    for (NSString *line in input) {
        BOOL result = [self.presenter shouldShowRightMenuButtonWithInputText:line];
        
        // then
        XCTAssertEqual(result, YES);
    }
}

@end
