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


#import "ContactsDataSource.h"
#import "WireSyncEngine+iOS.h"

#import "Wire-Swift.h"



// Minimum number of non-empty sections to display contacts grouped;
const NSUInteger MinimumNumberOfContactsToDisplaySections = 15;

NS_ASSUME_NONNULL_BEGIN

@interface ContactsDataSource ()

// Search
@property (nonatomic) SearchDirectory *searchDirectory;

// Group
@property (nonatomic, readonly) UILocalizedIndexedCollation *indexedCollation;
@property (nonatomic) NSArray *sections;    // Array of arrays: each subarray is section content;
@property (nonatomic) NSMutableOrderedSet *mutableSelection;

@end

NS_ASSUME_NONNULL_END




@implementation ContactsDataSource

- (instancetype)init
{
    return [self initWithSearchDirectory:[[SearchDirectory alloc] initWithUserSession:[ZMUserSession sharedSession]]];
}

- (instancetype)initWithSearchDirectory:(SearchDirectory *)searchDirectory
{
    self = [super init];
    if (self) {
        if ([ZMUserSession sharedSession]) {
            self.searchDirectory = searchDirectory;
        }
        self.sections = @[];
        self.mutableSelection = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)dealloc
{
    [self.searchDirectory tearDown];
}

#pragma mark - Searching

- (void)setSearchQuery:(NSString *)searchQuery
{
    if ([searchQuery isEqualToString:_searchQuery] ) {
        return;
    }
    
    _searchQuery = searchQuery;
    
    [self searchWithQuery:searchQuery];
}

#pragma mark - Grouping

- (UILocalizedIndexedCollation *)indexedCollation
{
    return [UILocalizedIndexedCollation currentCollation];
}

- (void)setUngroupedSearchResults:(NSArray *)ungroupedSearchResults
{
    if ([_ungroupedSearchResults isEqual:ungroupedSearchResults]) {
        return;
    }
    _ungroupedSearchResults = ungroupedSearchResults;
    [self recalculateSections];
}

- (BOOL)shouldShowSectionIndex
{
    return self.ungroupedSearchResults.count >= MinimumNumberOfContactsToDisplaySections;
}

- (void)recalculateSections
{
    SEL nameSelector = @selector(displayName);
    
    // If user has almost empty contact list, no need to display contacts grouped with section index;
    if (! self.shouldShowSectionIndex) {
        NSArray *sortedResults = [self.indexedCollation sortedArrayFromArray:self.ungroupedSearchResults collationStringSelector:nameSelector];
        self.sections = @[sortedResults];
        return;
    }
    
    // initialize empty sections
    NSUInteger numberOfSections = self.indexedCollation.sectionTitles.count;
    NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    for (NSUInteger i = 0; i < numberOfSections; i++) {
        [sections addObject:[@[] mutableCopy]];
    }
    
    // fill sections with users
    for (ZMSearchUser *user in self.ungroupedSearchResults) {
        NSUInteger sectionIndex = [self.indexedCollation sectionForObject:user collationStringSelector:nameSelector];
        [sections[sectionIndex] addObject:user];
    }
    
    // sort sections
    for (NSUInteger i = 0; i < numberOfSections; i++) {
        NSArray *section = sections[i];
        NSArray *sortedSection = [self.indexedCollation sortedArrayFromArray:section collationStringSelector:nameSelector];
        sections[i] = sortedSection;
    }
    
    self.sections = sections;
}

#pragma mark - Indexing

- (NSArray *)sectionAtIndex:(NSUInteger)index
{
    return self.sections[index];
}

- (ZMSearchUser *)userAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *section = [self sectionAtIndex:indexPath.section];
    return section[indexPath.row];
}

#pragma mark - Selection

- (void)setSelection:(NSOrderedSet * __nonnull)selection
{
    NSMutableOrderedSet *removedUsers = [self.mutableSelection mutableCopy];
    NSMutableOrderedSet *addedUsers = [selection mutableCopy];
    [removedUsers minusOrderedSet:selection];
    [addedUsers minusOrderedSet:self.mutableSelection];
    [self.mutableSelection intersectOrderedSet:selection];
    [self.mutableSelection unionOrderedSet:addedUsers];
    
    for (ZMSearchUser *user in removedUsers) {
        if ([self.delegate respondsToSelector:@selector(dataSource:didDeselectUser:)]) {
            [self.delegate dataSource:self didDeselectUser:user];
        }
    }
    
    for (ZMSearchUser *user in addedUsers) {
        if ([self.delegate respondsToSelector:@selector(dataSource:didSelectUser:)]) {
            [self.delegate dataSource:self didSelectUser:user];
        }
    }
}

- (NSOrderedSet * __nonnull)selection
{
    return self.mutableSelection;
}

- (void)selectUser:(ZMSearchUser *)user
{    
    if (! [self.mutableSelection containsObject:user]) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(selection))];
        [self.mutableSelection  addObject:user];
        if ([self.delegate respondsToSelector:@selector(dataSource:didSelectUser:)]) {
            [self.delegate dataSource:self didSelectUser:user];
        }
        [self didChangeValueForKey:NSStringFromSelector(@selector(selection))];
    }
}

- (void)deselectUser:(ZMSearchUser *)user
{
    if ([self.mutableSelection containsObject:user]) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(selection))];
        ZMSearchUser *deselectedUser = [self.mutableSelection objectAtIndex:[self.mutableSelection indexOfObject:user]];
        [self.mutableSelection  removeObject:user];
        if ([self.delegate respondsToSelector:@selector(dataSource:didDeselectUser:)]) {
            [self.delegate dataSource:self didDeselectUser:deselectedUser];
        }
        [self didChangeValueForKey:NSStringFromSelector(@selector(selection))];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self sectionAtIndex:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate dataSource:self cellForUser:[self userAtIndexPath:indexPath] atIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Returning nil here makes section header invisible.
    if (self.shouldShowSectionIndex) {
        if ([self.sections[section] count] == 0) {
            return nil; // hides headers for empty sections;
        } else {
            return self.indexedCollation.sectionTitles[section];
        }
    } else {
        return nil; // hides first section header for case with small number of users
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

// Index

// return list of section titles to display in section index view (e.g. "ABCD...Z#")
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.indexedCollation.sectionIndexTitles;
}

// tell table which section corresponds to section title/index (e.g. "B",1))
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.indexedCollation sectionForSectionIndexTitleAtIndex:index];
}

@end
