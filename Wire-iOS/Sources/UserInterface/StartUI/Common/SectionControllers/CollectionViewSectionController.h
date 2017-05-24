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


#import <Foundation/Foundation.h>

@protocol CollectionViewSectionController;

@protocol CollectionViewSectionDelegate <NSObject>

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller
                          didSelectItem:(id)item
                            atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller
                        didDeselectItem:(id)item
                            atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionViewSectionController:(id<CollectionViewSectionController>)controller
                       didDoubleTapItem:(id)item
                            atIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSIndexPath *)collectionViewSectionController:(id<CollectionViewSectionController>)controller indexPathForItemIndex:(NSUInteger)itemIndex;
@end

@protocol CollectionViewSectionController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) id <CollectionViewSectionDelegate> delegate;
@property (nonatomic, getter=isHidden, readonly) BOOL hidden;
- (BOOL)hasSearchResults;
@optional
- (void)reloadData;
@end
