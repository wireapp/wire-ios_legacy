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


@import UIKit;
@import XCTest;
#import "ContactsDataSource.h"
#import "ContactsDataSource+Private.h"
#import "MockLoader.h"
#import "MockUser.h"
#import "MockConversation.h"

@interface ContactsDataSourceTests : XCTestCase
@property (nonatomic, strong) ContactsDataSource *dataSource;
@end

@implementation ContactsDataSourceTests

- (void)setUp
{
    [super setUp];

    [NSThread sleepForTimeInterval:0.5];
    
    self.dataSource = [[ContactsDataSource alloc] initWithSearchDirectory:nil];
}

- (void)tearDown
{
    self.dataSource = nil;
    [super tearDown];
}

- (void)testThatDataSourceHasCorrectNumberOfSectionsForSmallNumberOfUsers
{
    // GIVEN
    NSArray *mockUsers = [MockUser mockUsers];

    // WHEN
    self.dataSource.ungroupedSearchResults = mockUsers;
    
    // THEN
    NSUInteger sections = [self.dataSource numberOfSectionsInTableView:[UITableView new]];
    XCTAssertFalse(self.dataSource.shouldShowSectionIndex);
    XCTAssertEqual(sections, 1ul, @"Number of sections must be 1");
}

- (void)testThatDataSourceHasCorrectNumberOfSectionsForLargeNumberOfUsers
{
    // GIVEN
    NSArray *mockUsers = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"a_lot_of_people.json"];
    
    // WHEN
    self.dataSource.ungroupedSearchResults = mockUsers;
    
    // THEN
    NSUInteger sections = [self.dataSource numberOfSectionsInTableView:[UITableView new]];
    XCTAssertTrue(self.dataSource.shouldShowSectionIndex);
    XCTAssertEqual(sections, 27ul, @"Number of sections");
}

- (void)testThatDataSourceHasCorrectNumbersOfRowsInSectionsForLargeNumberOfUsers
{
    // GIVEN
    NSArray *mockUsers = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"a_lot_of_people.json"];
    
    // WHEN
    self.dataSource.ungroupedSearchResults = mockUsers;
 
    // THEN
    NSUInteger numberOfRawsInFirstSection = [self.dataSource tableView:[UITableView new] numberOfRowsInSection:0];
    XCTAssertEqual(numberOfRawsInFirstSection, 20ul, @"");
    
    NSUInteger numberOfSections = [self.dataSource numberOfSectionsInTableView:[UITableView new]];
    NSUInteger numberOfRawsInLastSection = [self.dataSource tableView:[UITableView new] numberOfRowsInSection:numberOfSections - 2];
    XCTAssertEqual(numberOfRawsInLastSection, 3ul, @"");
}

- (void)testPerformanceExample
{
    // GIVEN
    NSArray *mockUsers = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"a_lot_of_people.json"];
    
    [self measureBlock:^{
        // WHEN
        self.dataSource.ungroupedSearchResults = mockUsers;
    }];
}

@end
