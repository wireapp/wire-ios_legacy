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


#import "CountryCodeTableViewController.h"

#import "CountryCodeResultsTableViewController.h"
#import "Country.h"
#import "Wire-Swift.h"


@interface CountryCodeTableViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic) NSArray *sections;
@property (nonatomic) NSArray *sectionTitles;

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) CountryCodeResultsTableViewController *resultsTableViewController;

@end

@implementation CountryCodeTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createDataSource];

    self.resultsTableViewController = [[CountryCodeResultsTableViewController alloc] init];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultsTableViewController];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];

    self.resultsTableViewController.tableView.delegate = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(dismiss:)];
    
    self.definesPresentationContext = YES;
    self.title = NSLocalizedString(@"registration.country_select.title", @"");
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(UIScreen.hasNotch) {
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if(UIScreen.hasNotch) {
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:NO];
    }
}

- (void)createDataSource
{
    NSArray *countries = [Country allCountries];
    
    SEL selector = @selector(displayName);
    NSInteger sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
    
    
    NSMutableArray *mutableSections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    for  (NSInteger idx = 0; idx < sectionTitlesCount; idx++) {
        [mutableSections addObject:[NSMutableArray array]];
    }
    
    for (Country *country in countries) {
        NSInteger sectionNumber = [[UILocalizedIndexedCollation currentCollation] sectionForObject:country collationStringSelector:selector];
       [[mutableSections objectAtIndex:sectionNumber] addObject:country];
    }

    for (NSInteger idx = 0; idx < sectionTitlesCount; idx++) {
        NSArray *objectsForSection = [mutableSections objectAtIndex:idx];
        [mutableSections replaceObjectAtIndex:idx withObject:[[UILocalizedIndexedCollation currentCollation] sortedArrayFromArray:objectsForSection collationStringSelector:selector]];
    }

#if WIRESTAN
    NSMutableArray * mutableArray = [[NSMutableArray alloc] initWithArray: [mutableSections objectAtIndex:0]];
    [mutableArray insertObject:[Country countryWirestan] atIndex:0];
    [mutableSections replaceObjectAtIndex:0 withObject:[mutableArray asArray]];
#endif

    self.sections = mutableSections;
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Update the filtered array based on the search text
    NSString *searchText = searchController.searchBar.text;
    NSArray *searchResults = [[self.sections valueForKeyPath:@"@unionOfArrays.self"] mutableCopy];

    // Strip out all the leading and trailing spaces
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    // Break up the search terms (separated by spaces)
    NSArray *searchItems = nil;
    if (strippedString.length > 0) {
        searchItems = [strippedString componentsSeparatedByString:@" "];
    }

    NSMutableArray *searchItemPredicates = [NSMutableArray array];
    NSMutableArray *numberPredicates = [NSMutableArray array];
    for (NSString *searchString in searchItems) {
        NSPredicate *displayNamePredicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@", searchString];
        [searchItemPredicates addObject:displayNamePredicate];

        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *targetNumber = [numberFormatter  numberFromString:searchString];

        if (targetNumber != nil) {
            NSPredicate *e164Predicate = [NSPredicate predicateWithFormat:@"e164 == %@", targetNumber];
            [numberPredicates addObject:e164Predicate];
        }
    }

    NSCompoundPredicate *andPredicates = [NSCompoundPredicate andPredicateWithSubpredicates:searchItemPredicates];
    NSCompoundPredicate *orPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:numberPredicates];
    NSCompoundPredicate *finalPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[andPredicates, orPredicates]];

    searchResults = [searchResults filteredArrayUsingPredicate:finalPredicate];

    // Hand over the filtered results to our search results table
    CountryCodeResultsTableViewController *tableController = (CountryCodeResultsTableViewController *)self.searchController.searchResultsController;
    tableController.filteredCountries = searchResults;
    [tableController.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Country *selectedCountry = nil;
    if (self.resultsTableViewController.tableView == tableView) {
        selectedCountry = [self.resultsTableViewController.filteredCountries objectAtIndex:indexPath.row];
        self.searchController.active = NO;
    } else {
        selectedCountry = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }

    if ([self.delegate respondsToSelector:@selector(countryCodeTableViewController:didSelectCountry:)]) {
        [self.delegate countryCodeTableViewController:self didSelectCountry:selectedCountry];
    }
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sections objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CountryCodeCellIdentifier forIndexPath:indexPath];

    [self configureCell:cell forCountry:[[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

@end
