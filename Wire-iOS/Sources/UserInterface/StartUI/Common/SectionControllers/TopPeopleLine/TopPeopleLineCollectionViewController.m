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


#import "TopPeopleLineCollectionViewController.h"
#import "TopPeopleCell.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

@implementation TopPeopleLineCollectionViewController

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.topPeople.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *genericCell = [collectionView dequeueReusableCellWithReuseIdentifier:TopPeopleCell.zm_reuseIdentifier
                                                                                  forIndexPath:indexPath];
    
    // Resolve the model object based on the current UI state
    ZMConversation *modelObject = self.topPeople[indexPath.item % self.topPeople.count];
    
    TopPeopleCell *particularCell = (TopPeopleCell *)genericCell;    
    BOOL selected = [self.userSelection.users containsObject:modelObject.connectedUser];
    particularCell.conversation = modelObject;
    particularCell.selected = selected;
    
    if (selected) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    
    return genericCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZMConversation *modelObject = self.topPeople[indexPath.item % self.topPeople.count];
    
    [self.userSelection add:modelObject.connectedUser];
    
    if ([self.delegate respondsToSelector:@selector(topPeopleLineCollectionViewControllerDidSelectConversation:)]) {
        [self.delegate topPeopleLineCollectionViewControllerDidSelectConversation:modelObject];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZMConversation *modelObject = self.topPeople[indexPath.item % self.topPeople.count];
    
    [self.userSelection remove:modelObject.connectedUser];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(6, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(56, 78);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {    
    return 12.0f;
}

@end
