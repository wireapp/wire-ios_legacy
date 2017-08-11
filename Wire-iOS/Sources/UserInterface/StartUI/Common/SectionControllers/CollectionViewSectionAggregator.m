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


#import "CollectionViewSectionAggregator.h"

@interface CollectionViewSectionAggregator ()
@property (nonatomic) NSArray *visibleSectionControllers;
@end

@implementation CollectionViewSectionAggregator

- (void)dealloc
{
    for (NSObject<CollectionViewSectionController> *oldSection in _sectionControllers) {
        [oldSection removeObserver:self forKeyPath:NSStringFromSelector(@selector(isHidden))];
    }
}

- (void)setSectionControllers:(NSArray *)sectionControllers
{
    for (NSObject<CollectionViewSectionController> *oldSection in _sectionControllers) {
        [oldSection removeObserver:self forKeyPath:NSStringFromSelector(@selector(isHidden))];
    }
    
    _sectionControllers = sectionControllers;
    
    for (NSObject<CollectionViewSectionController> *newSection in _sectionControllers) {
        [newSection addObserver:self forKeyPath:NSStringFromSelector(@selector(isHidden)) options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    [self updateCollectionViewWithControllers];
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    
    [self updateCollectionViewWithControllers];
}

- (void)updateCollectionViewWithControllers
{
    NSMutableArray *visibleSections = [NSMutableArray arrayWithCapacity:self.sectionControllers.count];
    
    for (id <CollectionViewSectionController> sectionController in self.sectionControllers) {
        sectionController.collectionView = self.collectionView;
        if (! [sectionController isHidden]) {
            [visibleSections addObject:sectionController];
        }
    }
    
    self.visibleSectionControllers = visibleSections;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView reloadData];
}

- (void)reloadData
{
    [self.collectionView reloadData];
    
    for (id<CollectionViewSectionController> controller in self.visibleSectionControllers) {
        if ([controller respondsToSelector:@selector(reloadData)]) {            
            [controller reloadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isHidden))]) {
        [self updateCollectionViewWithControllers];
        [self reloadData];
    }
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[indexPath.section];
    
    return [sectionController collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.visibleSectionControllers.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[section];
    
    return [sectionController collectionView:collectionView numberOfItemsInSection:0];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[indexPath.section];
    
    return [sectionController collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[indexPath.section];
    
    return [sectionController collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[indexPath.section];
    
    return [sectionController collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[section];
    
    return [sectionController collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[indexPath.section];
    
    return [sectionController collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    id <CollectionViewSectionController> sectionController = self.visibleSectionControllers[section];
    
    return [sectionController collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.delegate) {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

@end
