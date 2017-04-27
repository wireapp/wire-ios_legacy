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
@import WireSyncEngine;
#import <OCMock/OCMock.h>
#import "StartUIViewController.h"
#import "StartUIViewController+Testing.h"
#import "CollectionViewContainerCell.h"
#import "SearchResultCell.h"
#import "CollectionViewSectionAggregator.h"
#import "TopPeopleLineSection.h"
#import "UsersInDirectorySection.h"
#import "UsersInDirectorySection+Testing.h"
#import "MockLoader.h"
#import "MockUser.h"
#import "MockConversation.h"



@interface StartUIControllerTests : XCTestCase
@property (nonatomic, strong) StartUIViewController *controller;
@property (nonatomic, strong) StartUIViewController *controllerPartialMock;

@property (nonatomic, strong) TopPeopleLineSection *topPeopleLineSectionPartialMock;
@property (nonatomic, strong) UsersInDirectorySection *usersInDirectorySectionPartialMock;
@property (nonatomic, strong) UsersInContactsSection *usersInContactsSectionPartialMock;
@property (nonatomic, strong) GroupConversationsSection *groupConversationsSectionPartialMock;

@property (nonatomic, strong) UICollectionView *collectionView;

// Mocked Users
@property (nonatomic, strong) NSArray *searchResultTopConversations;
@property (nonatomic, strong) NSArray *searchResultUsersInContacts;
@property (nonatomic, strong) NSArray *searchResultUsersInDirectory;
@property (nonatomic, strong) NSArray *searchResultGroupConversations;


// Batch udpates
@property (nonatomic, strong) XCTestExpectation *batchUpdatesExpectation;
@property (nonatomic, assign) NSInteger numberOrSectionsInserted;
@property (nonatomic, assign) NSInteger numberOrSectionsDeleted;
@property (nonatomic, strong) NSMutableDictionary *numberOfItemsInSectionsBeforeUpdate;
@property (nonatomic, strong) NSMutableDictionary *numberOfItemsInsertedForSection;
@property (nonatomic, strong) NSMutableDictionary *numberOfItemsDeletedForSection;
@property (nonatomic, strong) NSMutableDictionary *numberOfItemsMovedInForSection;
@property (nonatomic, strong) NSMutableDictionary *numberOfItemsMovedOutForSection;
@end



@implementation StartUIControllerTests

#pragma mark - Setup and Teardown

- (void)setUp
{
    [super setUp];
    
    // Mocked users
    NSArray *mockedUsersInContacts = [MockLoader mockObjectsOfClass:[MockUser class]
                                                           fromFile:@"people-01.json"];
    self.searchResultTopConversations = [MockLoader mockObjectsOfClass:[MockConversation class]
                                                              fromFile:@"conversations-01.json"];
    self.searchResultUsersInContacts = mockedUsersInContacts;
    self.searchResultUsersInDirectory = [MockLoader mockObjectsOfClass:[MockUser class]
                                                              fromFile:@"people-02.json"];
    self.searchResultGroupConversations = [MockLoader mockObjectsOfClass:[MockConversation class]
                                                                fromFile:@"conversations-01.json"];
    
    self.controller = [[StartUIViewController alloc] initWithSearchDirectoryClass:nil];
    self.controllerPartialMock = OCMPartialMock(self.controller);
    
    self.topPeopleLineSectionPartialMock = OCMPartialMock(self.controller.topPeopleLineSection);
    self.usersInContactsSectionPartialMock = OCMPartialMock(self.controller.usersInContactsSection);
    self.usersInDirectorySectionPartialMock = OCMPartialMock(self.controller.usersInDirectorySection);
    self.groupConversationsSectionPartialMock = OCMPartialMock(self.controller.groupConversationsSection);
        
    OCMStub([self.controllerPartialMock topPeopleLineSection]).andReturn(self.topPeopleLineSectionPartialMock);
    OCMStub([self.controllerPartialMock usersInContactsSection]).andReturn(self.usersInContactsSectionPartialMock);
    OCMStub([self.controllerPartialMock usersInDirectorySection]).andReturn(self.usersInDirectorySectionPartialMock);
    OCMStub([self.controllerPartialMock groupConversationsSection]).andReturn(self.groupConversationsSectionPartialMock);
    
    OCMStub([self.topPeopleLineSectionPartialMock topPeople]).andCall(self, @selector(searchResultTopConversations));
    OCMStub([self.usersInContactsSectionPartialMock contacts]).andCall(self, @selector(searchResultUsersInContacts));
    OCMStub([self.usersInDirectorySectionPartialMock suggestions]).andCall(self, @selector(searchResultUsersInDirectory));
    OCMStub([self.groupConversationsSectionPartialMock groupConversations]).andCall(self, @selector(searchResultGroupConversations));
    
    OCMStub([self.usersInDirectorySectionPartialMock setSuggestions:[OCMArg any]]).andCall(self, @selector(setSearchResultUsersInDirectory:));
    
    (void)self.controller.view;
    self.collectionView = OCMClassMock([UICollectionView class]);
    
    

    OCMStub([self.controllerPartialMock scrollView]).andReturn(self.collectionView);
    
    CollectionViewContainerCell *mockedTopCell = [[CollectionViewContainerCell alloc] init];
    OCMStub([self.collectionView dequeueReusableCellWithReuseIdentifier:StartUICollectionViewCellReuseIdentifier
                                                           forIndexPath:[OCMArg any]]).andReturn(mockedTopCell);
    id partialTopCellMock = OCMPartialMock(mockedTopCell);
    
    [[(id)partialTopCellMock stub] setCollectionView:[OCMArg checkWithBlock:^BOOL(ZMUser* user) {
        return YES;
    }]];
    
    SearchResultCell *mockedSearchResultCell = [[SearchResultCell alloc] init];
    OCMStub([self.collectionView dequeueReusableCellWithReuseIdentifier:PeoplePickerUsersInDirectoryCellReuseIdentifier
                                                           forIndexPath:[OCMArg any]]).andReturn(mockedSearchResultCell);
    
    OCMStub([self.collectionView dequeueReusableCellWithReuseIdentifier:PeoplePickerUsersInContactsReuseIdentifier
                                                           forIndexPath:[OCMArg any]]).andReturn(mockedSearchResultCell);
    
    OCMStub([self.collectionView dequeueReusableCellWithReuseIdentifier:PeoplePickerGroupConversationsReuseIdentifier
                                                           forIndexPath:[OCMArg any]]).andReturn(mockedSearchResultCell);
    
    
    id partialSearchResultCellMock = OCMPartialMock(mockedSearchResultCell);
    
    [(SearchResultCell *)[(id)partialSearchResultCellMock stub] setUser:[OCMArg checkWithBlock:^BOOL(ZMUser* user) {
        mockedSearchResultCell.displayName = [user displayName];
        return YES;
    }]];
    
    [[(id)partialSearchResultCellMock stub] setConversation:[OCMArg checkWithBlock:^BOOL(ZMUser* user) {
        mockedSearchResultCell.displayName = [user displayName]; 
        return YES;
    }]];
    

    // Batch updates
    OCMStub([self.collectionView performBatchUpdates:[OCMArg any] completion:[OCMArg any]]).andCall(self, @selector(performBatchUpdates:completion:));
    OCMStub([self.collectionView insertSections:[OCMArg any]]).andCall(self, @selector(insertSections:));
    OCMStub([self.collectionView deleteSections:[OCMArg any]]).andCall(self, @selector(deleteSections:));
    OCMStub([self.collectionView insertItemsAtIndexPaths:[OCMArg any]]).andCall(self, @selector(insertItemsAtIndexPaths:));
    OCMStub([self.collectionView deleteItemsAtIndexPaths:[OCMArg any]]).andCall(self, @selector(deleteItemsAtIndexPaths:));
    OCMStub([self.collectionView moveItemAtIndexPath:[OCMArg any] toIndexPath:[OCMArg any]]).andCall(self, @selector(moveItemAtIndexPath:toIndexPath:));
    
    self.numberOfItemsInsertedForSection = [NSMutableDictionary new];
    self.numberOfItemsDeletedForSection = [NSMutableDictionary new];
    self.numberOfItemsMovedInForSection = [NSMutableDictionary new];
    self.numberOfItemsMovedOutForSection = [NSMutableDictionary new];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.controller = nil;
    
    [(id)self.collectionView stopMocking];
    [(id)self.controllerPartialMock stopMocking];
}

#pragma mark - UICollectionView Batch Updates

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL finished))completion
{
    NSUInteger numberOfSectionsBeforeUpdates = [self.controller.sectionAggregator numberOfSectionsInCollectionView:self.collectionView];
    self.numberOfItemsInSectionsBeforeUpdate = [NSMutableDictionary new];
    for (NSUInteger i = 0; i < numberOfSectionsBeforeUpdates; i++) {
        self.numberOfItemsInSectionsBeforeUpdate[@(i)] = @([self.controller.sectionAggregator collectionView:self.collectionView numberOfItemsInSection:i]);
    }
    
    updates();
    NSUInteger numberOfSectionsAfterUpdates = [self.controller.sectionAggregator numberOfSectionsInCollectionView:self.collectionView];
    XCTAssertEqual(numberOfSectionsAfterUpdates,
                   numberOfSectionsBeforeUpdates + self.numberOrSectionsInserted - self.numberOrSectionsDeleted,
                   @"Number of sections in collection view after updates (NoS2) should be NoS2 = NoS1 + added - removed, where NoS1 - number of sections before update, added - number of sections added, removed - number of sections removed");
    
    for (NSUInteger i = 0; i < numberOfSectionsAfterUpdates; i++) {
        NSUInteger numberOfItemsBeforeUpdate = [self.numberOfItemsInSectionsBeforeUpdate[@(i)] integerValue];
        NSUInteger numberOfItemsInserted = [self.numberOfItemsInsertedForSection[@(i)] integerValue];
        NSUInteger numberOfItemsDeleted = [self.numberOfItemsDeletedForSection[@(i)] integerValue];
        NSUInteger numberOfItemsMovedIn = [self.numberOfItemsMovedInForSection[@(i)] integerValue];
        NSUInteger numberOfItemsMovedOut = [self.numberOfItemsMovedOutForSection[@(i)] integerValue];
        
        NSInteger numberOfItemsInSectionAfterFact = [self.controller.sectionAggregator collectionView:self.collectionView numberOfItemsInSection:i];
        NSInteger numberOfItemsInSectionTheoretical =
            numberOfItemsBeforeUpdate
            + numberOfItemsInserted - numberOfItemsDeleted
            + numberOfItemsMovedIn - numberOfItemsMovedOut;
        XCTAssertEqual(numberOfItemsInSectionAfterFact,
                       numberOfItemsInSectionTheoretical,
                       @"Number of items in section %lu after update(%lu) must be equal num before update (%lu), plus num of inserted(%lu) and moved in (%lu), and minus num of deleted(%lu) and moved out(%lu)", i, numberOfItemsInSectionAfterFact, numberOfItemsBeforeUpdate, numberOfItemsInserted, numberOfItemsMovedIn, numberOfItemsDeleted, numberOfItemsMovedOut);
    }
    
    completion(YES);
    
    if (self.batchUpdatesExpectation) {
        [self.batchUpdatesExpectation fulfill];
    }
}

- (void)insertSections:(NSIndexSet *)sections
{
    self.numberOrSectionsInserted += sections.count;
}

- (void)deleteSections:(NSIndexSet *)sections
{
    self.numberOrSectionsDeleted += sections.count;
}

- (void)reloadSections:(NSIndexSet *)sections
{
    
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
    
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self recordIndexPaths:indexPaths toSectionDictionary:self.numberOfItemsInsertedForSection];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self recordIndexPaths:indexPaths toSectionDictionary:self.numberOfItemsDeletedForSection];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self recordIndexPaths:@[indexPath] toSectionDictionary:self.numberOfItemsMovedOutForSection];
    [self recordIndexPaths:@[newIndexPath] toSectionDictionary:self.numberOfItemsMovedInForSection];
}

#pragma mark - Util

- (void)recordIndexPaths:(NSArray *)indexPaths toSectionDictionary:(NSMutableDictionary *)sectionDictionary
{
    for (NSIndexPath *indexPath in indexPaths) {
        NSNumber *oldNumber = sectionDictionary[@(indexPath.section)];
        if (oldNumber) {
            sectionDictionary[@(indexPath.section)] = @(oldNumber.integerValue + 1);
        } else {
            sectionDictionary[@(indexPath.section)] = @1;
        }
    }
}

#pragma mark - Cells validation
#pragma mark Context: Create, Layout: TopAndSuggested;

- (void)testThatStartUIInInitalModeHasCorrectCellsInTopSection {
    // Given
    self.controller.mode = StartUIModeInitial;
    
    // When
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    CollectionViewContainerCell *cell = (CollectionViewContainerCell *)[self.controller.sectionAggregator collectionView:self.collectionView
                                                                            cellForItemAtIndexPath:indexPath];
    
    // Then
    XCTAssertNotNil(cell);
    XCTAssert([cell isKindOfClass:[CollectionViewContainerCell class]], @"class should be CollectionViewContainerCell");
}

- (void)testThatStartUIInInitalModeHasCorrectCellsInSearchResultsSection {
    // Given
    self.controller.mode = StartUIModeInitial;
    
    // When
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    SearchResultCell *cell = (SearchResultCell *)[self.controller.sectionAggregator collectionView:self.collectionView
                                                                            cellForItemAtIndexPath:indexPath];
    
    // Then
    XCTAssertNotNil(cell);
    XCTAssert([cell isKindOfClass:[SearchResultCell class]], @"class should be SearchResultCell");
    XCTAssertEqualObjects(cell.displayName, @"James Hetfield");
}

#pragma mark Context: Create, Layout: SearchResults;

- (void)testThatStartUIInSearchResultsModeHasCorrectCellsInContactsSection {
    // Given
    self.controller.mode = StartUIModeSearch;
    
    // When
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    SearchResultCell *cell = (SearchResultCell *)[self.controller.sectionAggregator collectionView:self.collectionView
                                                                                    cellForItemAtIndexPath:indexPath];
    
    // Then
    XCTAssertNotNil(cell);
    XCTAssert([cell isKindOfClass:[SearchResultCell class]], @"class should be SearchResultCell");
    XCTAssertEqualObjects(cell.displayName, @"James Hetfield");
}

- (void)testThatStartUIInSearchResultsModeHasCorrectCellsInGroupConversationsSection {
    // Given
    self.controller.mode = StartUIModeSearch;
    
    // When
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    SearchResultCell *cell = (SearchResultCell *)[self.controller.sectionAggregator collectionView:self.collectionView
                                                                                    cellForItemAtIndexPath:indexPath];
    
    // Then
    XCTAssertNotNil(cell);
    XCTAssert([cell isKindOfClass:[SearchResultCell class]], @"class should be SearchResultCell");
    XCTAssertEqualObjects(cell.displayName, @"Conversation");
}

- (void)testThatStartUIInSearchResultsModeHasCorrectCellsInDirectorySection {
    // Given
    self.controller.mode = StartUIModeSearch;
    
    // When
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:2];
    SearchResultCell *cell = (SearchResultCell *)[self.controller.sectionAggregator collectionView:self.collectionView
                                                                                    cellForItemAtIndexPath:indexPath];
    
    // Then
    XCTAssertNotNil(cell);
    XCTAssert([cell isKindOfClass:[SearchResultCell class]], @"class should be SearchResultCell");
    XCTAssertEqualObjects(cell.displayName, @"Arnold Schwarzenegger");
}

@end
