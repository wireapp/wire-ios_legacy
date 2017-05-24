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


#import "UsersInDirectorySection.h"
#import "SearchSectionHeaderView.h"
#import "Constants.h"
#import "WAZUIMagicIOS.h"
#import "WireSyncEngine+iOS.h"
#import "SearchResultCell.h"
#import "Analytics+iOS.h"

NSString *const PeoplePickerUsersInDirectoryCellReuseIdentifier = @"PeoplePickerUsersInDirectoryCellReuseIdentifier";


@interface UsersInDirectorySection () <ZMUserObserver>

@property (nonatomic, strong) NSDictionary *searchResultUsersInDirectoryMap;
@property (nonatomic) id userObserverToken;

@end

@implementation UsersInDirectorySection
@synthesize collectionView = _collectionView;
@synthesize delegate = _delegate;

- (BOOL)hasSearchResults
{
    return (self.suggestions.count > 0);
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    [self.collectionView registerClass:[SearchResultCell class] forCellWithReuseIdentifier:PeoplePickerUsersInDirectoryCellReuseIdentifier];
    [self.collectionView registerClass:[SearchSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PeoplePickerHeaderReuseIdentifier];
}

- (void)setSuggestions:(NSArray *)suggestions
{
    _suggestions = suggestions;
    
    if (self.userObserverToken == nil) {
        // We only need to subscribe once for all searchUsers
        self.userObserverToken = [UserChangeInfo addSearchUserObserver:self forSearchUser:nil];
    }
}

- (BOOL)isHidden
{
    return (self.suggestions.count == 0);
}

+ (NSSet *)keyPathsForValuesAffectingIsHidden
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(suggestions))];
}

/// Creates the map (memory address)->(index) in array for @p searchResultUsersInDirectory
- (void)createSearchResultUsersInDirectoryMap
{
    NSMutableDictionary *map = [NSMutableDictionary dictionaryWithCapacity:self.suggestions.count];
    
    NSUInteger index = 0;
    for (ZMSearchUser *user in self.suggestions) {
        [map setObject:@(index) forKey:[NSString stringWithFormat:@"%p", user]];
        index++;
    }
    
    self.searchResultUsersInDirectoryMap = map;
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    if (!change.connectionStateChanged) {
        return;
    }
    
    NSNumber *idx = self.searchResultUsersInDirectoryMap[[NSString stringWithFormat:@"%p", change.user]];
    if (idx == nil) {
        return;
    }
    __block NSUInteger userIndex =  [idx integerValue];
    ZMSearchUser *user = [self.suggestions objectAtIndex:userIndex];
    if (![user isPendingApprovalByOtherUser]) {
        return;
    }
    
    const NSArray *oldSuggestions = [self.suggestions copy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *newSearchResult = [NSMutableArray arrayWithArray:self.suggestions];
        if (![oldSuggestions isEqualToArray:self.suggestions]) {
            userIndex = [self.suggestions indexOfObject:user];
            if (userIndex == NSNotFound) {
                [self.collectionView reloadData];
                return;
            }
        }
        [newSearchResult removeObjectAtIndex:userIndex];
        
        if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:indexPathForItemIndex:)]) {
            NSIndexPath *indexPath = [self.delegate collectionViewSectionController:self indexPathForItemIndex:userIndex];
            
            [self animateSingleDeleteOnPeopleYouMayKnowFrom:self.suggestions to:newSearchResult inSection:indexPath.section];
        }
        else {
            [self.collectionView reloadData];
        }
    });
    
}
#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.suggestions.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SearchSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                             withReuseIdentifier:PeoplePickerHeaderReuseIdentifier
                                                                                    forIndexPath:indexPath];
    
    headerView.title = NSLocalizedString(@"peoplepicker.header.directory", @"");
    
    // in case of search, the headers are with zero frame, and their content should not be displayed
    // if not clipping, then part of the label is still displayed, so we clip it
    headerView.clipsToBounds = YES;
    return headerView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *genericCell = [collectionView dequeueReusableCellWithReuseIdentifier:PeoplePickerUsersInDirectoryCellReuseIdentifier
                                                                                  forIndexPath:indexPath];
    
    // Resolve the model object based on the current UI state
    id modelObject = self.suggestions[indexPath.item];
    
    SearchResultCell *particularCell = (SearchResultCell *)genericCell;
    @weakify(self, modelObject);
    particularCell.doubleTapAction = ^(SearchResultCell *cell) {
        @strongify(self, modelObject);
        if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:didDoubleTapItem:atIndexPath:)]) {        
            [self.delegate collectionViewSectionController:self didDoubleTapItem:modelObject atIndexPath:indexPath];
        }
    };
    
    particularCell.user = modelObject;

    particularCell.instantConnectAction = ^(SearchResultCell *cell) {
        @strongify(self);
        NSString *messageText = [NSString stringWithFormat:NSLocalizedString(@"missive.connection_request.default_message",@"Default connect message to be shown"), cell.user.displayName, [ZMUser selfUser].name];
        
        [[ZMUserSession sharedSession] enqueueChanges:^{
            
            [cell.user connectWithMessageText:messageText completionHandler:^() {
                [[Analytics shared] tagEventObject:[AnalyticsConnectionRequestEvent eventForAddContactMethod:AnalyticsConnectionRequestMethodUserSearch connectRequestCount:1]];
            }];
        }];
        
        [cell playAddUserAnimation];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:self.suggestions];
            [updatedUsers removeObject:cell.user];
            [self animateSingleDeleteOnPeopleYouMayKnowFrom:self.suggestions to:updatedUsers inSection:indexPath.section];
        });
    };
        
    return genericCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    id modelObject = self.suggestions[indexPath.item];
    
    if ([self.delegate respondsToSelector:@selector(collectionViewSectionController:didSelectItem:atIndexPath:)]) {
        [self.delegate collectionViewSectionController:self didSelectItem:modelObject atIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id modelObject = self.suggestions[indexPath.item];
    
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
    self.suggestions = result.usersInDirectory;
    self.suggestionsState = PeoplePickerSuggestionsStateLoaded;
    [self.collectionView reloadData];
}

#pragma mark - Single item animation

/**
 *  This method checks if the single item was deleted from the dataset
 *
 *  @param from initial dataset state
 *  @param to   new dataset state
 *
 *  @return If the update is possible
 */
+ (BOOL)canDoSingleDeleteAnimationFrom:(NSArray *)from to:(NSArray *)to
{
    if (to.count + 1 == from.count) { // single element is removed
        BOOL allUsersWasDisplayed = YES;
        for (id resultItem in to) {
            if ([from indexOfObject:resultItem] == NSNotFound) {
                allUsersWasDisplayed = NO;
                break;
            }
        }

        return allUsersWasDisplayed;
    }
    else {
        return NO;
    }
}

/**
 *  Method to animate single item deletion
 *
 *  @param from initial dataset state
 *  @param to   new dataset state
 */
- (void)animateSingleDeleteOnPeopleYouMayKnowFrom:(NSArray *)from to:(NSArray *)to inSection:(NSUInteger)section
{
    if (to.count == 0) {
        [self.collectionView reloadData];
        return;
    }
    
    NSUInteger removedElementIndex = 0;
    NSUInteger i = 0;
    for (id oldResultItem in from) {
        if ([to indexOfObject:oldResultItem] == NSNotFound) {
            removedElementIndex = i;
            break;
        }
        i++;
    }

    if (i == from.count) {
        // Cannot find the removed item
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        self.suggestions = to;

        [self createSearchResultUsersInDirectoryMap];
        
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:removedElementIndex inSection:section]]];
    } completion:nil];
}

@end
