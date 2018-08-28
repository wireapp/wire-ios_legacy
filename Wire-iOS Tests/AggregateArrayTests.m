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

#import "AggregateArray.h"


@interface AggregateArrayTests : XCTestCase

@property (nonatomic, strong) AggregateArray *aggregateArray;
@property (nonatomic, strong) NSArray *sections;

@end

@implementation AggregateArrayTests

- (void)setUp
{
    [super setUp];
    
    self.sections = @[@[@(1), @(2), @(3)], @[@(4), @(5), @(6)]];
    self.aggregateArray = [[AggregateArray alloc] initWithSections:self.sections];
}

- (void)tearDown
{
    self.sections = nil;
    self.aggregateArray = nil;
    
    [super tearDown];
}

- (void)testThatItemCountsAreEqual
{
    // given
    __block NSUInteger count = 0;
    
    // when
    [self.sections enumerateObjectsUsingBlock:^(NSArray *section, NSUInteger idx, BOOL *stop) {
        count += section.count;
    }];
    
    // then
    XCTAssertEqual(count, self.aggregateArray.itemCount);
}

- (void)testThatIndexPathForItemIsCorrect
{
    // given
    const NSUInteger section = 0;
    const NSUInteger item = 0;
    id object = [[self.sections objectAtIndex:section] objectAtIndex:item];
    
    // when
    NSIndexPath *path = [self.aggregateArray indexPathForItem:object];
    
    // then
    XCTAssertEqual(path.section, section);
    XCTAssertEqual(path.item, item);
}

- (void)testThatSectionAtIndexIsCorrect
{
    // given
    const NSUInteger section = 0;
    
    // when
    id object = [self.sections objectAtIndex:section];
    
    // then
    XCTAssertEqual(object, [self.aggregateArray sectionAtIndex:section]);
}

- (void)testThatItemForIndexPathIsCorrect
{
    // given
    const NSUInteger section = MIN((self.sections.count - 1), (NSUInteger)0);
    const NSUInteger item = 0;
    NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:section];
    id object = [[self.sections objectAtIndex:section] objectAtIndex:item];
    
    // when & then
    XCTAssertEqual(object, [self.aggregateArray itemForIndexPath:path]);
}

- (void)testThatItemForIndexPathIsIncorrect
{
    // given
    const NSUInteger section = MAX((self.sections.count - 1), (NSUInteger)0);
    const NSUInteger item = 0;
    const NSUInteger otherItem = MAX(([[self.sections objectAtIndex:section] count] - 1), (NSUInteger)0);
    NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:section];
    id object = [[self.sections objectAtIndex:section] objectAtIndex:otherItem];
    
    // when & then
    XCTAssertNotEqual(object, [self.aggregateArray itemForIndexPath:path]);
}

@end
