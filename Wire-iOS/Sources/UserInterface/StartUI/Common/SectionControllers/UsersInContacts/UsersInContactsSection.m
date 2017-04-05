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


#import "UsersInContactsSection.h"
#import "SearchSectionHeaderView.h"
#import "Constants.h"
#import "WAZUIMagicIOS.h"
#import "WireSyncEngine+iOS.h"
#import "SearchResultCell.h"

NSString *const PeoplePickerUsersInContactsReuseIdentifier = @"PeoplePickerUsersInContactsReuseIdentifier";

@interface UsersInContactsSection () <ZMSearchResultObserver>
@end

@implementation UsersInContactsSection
@synthesize collectionView = _collectionView;
@synthesize delegate = _delegate;

- (void)dealloc
{
    [self.searchDirectory removeSearchResultObserver:self];
}

- (BOOL)hasSearchResults
{
    return (self.contacts.count > 0);
}

- (BOOL)isHidden
{
    return (self.contacts.count == 0);
}

+ (NSSet *)keyPathsForValuesAffectingIsHidden
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(contacts))];
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    [self.collectionView registerClass:[SearchResultCell class] forCellWithReuseIdentifier:PeoplePickerUsersInContactsReuseIdentifier];
    [self.collectionView registerClass:[SearchSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PeoplePickerHeaderReuseIdentifier];
}

- (void)setSearchDirectory:(ZMSearchDirectory *)searchDirectory
{
    [self.searchDirectory removeSearchResultObserver:self];
    _searchDirectory = searchDirectory;
    [self.searchDirectory addSearchResultObserver:self];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.contacts.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SearchSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                             withReuseIdentifier:PeoplePickerHeaderReuseIdentifier
                                                                                    forIndexPath:indexPath];
    
    headerView.title = NSLocalizedString(@"peoplepicker.header.contacts", @"");
    
    // in case of search, the headers are with zero frame, and their content should not be displayed
    // if not clipping, then part of the label is still displayed, so we clip it
    headerView.clipsToBounds = YES;
    return headerView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *genericCell = [collectionView dequeueReusableCellWithReuseIdentifier:PeoplePickerUsersInContactsReuseIdentifier
                                                                                  forIndexPath:indexPath];
    
    // Resolve the model object based on the current UI state
    id modelObject = self.contacts[indexPath.item];
    
    SearchResultCell *particularCell = (SearchResultCell *)genericCell;
    @weakify(self, modelObject);
    particularCell.doubleTapAction = ^(SearchResultCell *cell) {
        @strongify(self, modelObject);
        if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:didDoubleTapItem:atIndexPath:)]) {        
            [self.delegate collectionViewSectionController:self didDoubleTapItem:modelObject atIndexPath:indexPath];
        }
    };
    
    particularCell.user = modelObject;
    
    if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:featureCell:forItem:inCollectionView:atIndexPath:)]) {
        [self.delegate collectionViewSectionController:self featureCell:genericCell forItem:modelObject inCollectionView:collectionView atIndexPath:indexPath];
    }
    return genericCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id modelObject = self.contacts[indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:didSelectItem:atIndexPath:)]) {
        [self.delegate collectionViewSectionController:self didSelectItem:modelObject atIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id modelObject = self.contacts[indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:didDeselectItem:atIndexPath:)]) {
        [self.delegate collectionViewSectionController:self didDeselectItem:modelObject atIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.collectionView.bounds.size.width, [WAZUIMagic cgFloatForIdentifier:@"people_picker.section_header.height"]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.collectionView.bounds.size.width, 
                      [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.tile_height"]);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat topInset = [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.top_padding"];
    CGFloat leftInset = [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.left_padding"];
    CGFloat righInset = [WAZUIMagic floatForIdentifier:@"people_picker.search_results_mode.right_padding"];
    
    return UIEdgeInsetsMake(topInset, leftInset, 0, righInset);
}

#pragma mark - ZMSearchResultsObserver

- (void)didReceiveSearchResult:(ZMSearchResult *)result forToken:(ZMSearchToken)searchToken
{
    self.contacts = result.usersInContacts;
    [self.collectionView reloadData];
}

@end
