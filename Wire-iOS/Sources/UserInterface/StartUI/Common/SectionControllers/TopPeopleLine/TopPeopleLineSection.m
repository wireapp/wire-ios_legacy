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


#import "TopPeopleLineSection.h"
#import "SearchSectionHeaderView.h"
#import "CollectionViewContainerCell.h"
#import "Constants.h"
#import "TopPeopleCell.h"
#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "TopPeopleLineCollectionViewController.h"
#import <PureLayout/PureLayout.h>
#import "UIView+Borders.h"

NSString *const StartUICollectionViewCellReuseIdentifier = @"StartUICollectionViewCellReuseIdentifier";

@interface TopPeopleLineSection () <TopConversationsDirectoryObserver>
@property (nonatomic) UICollectionView *innerCollectionView;
@property (nonatomic) TopPeopleLineCollectionViewController *innerCollectionViewController;
@property (nonatomic) TopConversationsDirectoryObserverToken *observerToken;
@end

@implementation TopPeopleLineSection
@synthesize collectionView = _collectionView;
@synthesize delegate = _delegate;

- (void)dealloc
{
    [self removeTopConversationObserverIfNeeded];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.innerCollectionViewController = [TopPeopleLineCollectionViewController new];
        self.innerCollectionViewController.topPeople = self.topPeople;
        self.innerCollectionViewController.sectionController = self;
        self.innerCollectionViewController.delegate = self.delegate;
        
        [self setupCollectionView];        
        
        self.innerCollectionView.delegate = self.innerCollectionViewController;
        self.innerCollectionView.dataSource = self.innerCollectionViewController;
    }
    return self;
}

- (void)setupCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    
    self.innerCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                             collectionViewLayout:layout];
    self.innerCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.innerCollectionView.backgroundColor = [UIColor clearColor];
    self.innerCollectionView.bounces = YES;
    self.innerCollectionView.allowsMultipleSelection = YES;
    self.innerCollectionView.showsHorizontalScrollIndicator = NO;
    self.innerCollectionView.directionalLockEnabled = YES;
    
    CGFloat leftInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.left_padding"];
    CGFloat rightInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.right_padding"];
    CGFloat topInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.top_padding"];
    CGFloat bottomInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.bottom_padding"];

    self.innerCollectionView.contentInset = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);
    
    [self.innerCollectionView registerClass:[TopPeopleCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
}

- (BOOL)hasSearchResults
{
    return NO;
}

- (void)setCollectionView:(UICollectionView *)collectionView
{
    _collectionView = collectionView;
    [self.collectionView registerClass:[CollectionViewContainerCell class] forCellWithReuseIdentifier:StartUICollectionViewCellReuseIdentifier];
    [self.collectionView registerClass:[SearchSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PeoplePickerHeaderReuseIdentifier];
}

- (void)setDelegate:(id<CollectionViewSectionDelegate>)delegate
{
    _delegate = delegate;
    self.innerCollectionViewController.delegate = self.delegate;
}

- (void)setTopPeople:(NSArray *)topPeople
{
    _topPeople = topPeople;
    self.innerCollectionViewController.topPeople = self.topPeople;
}

- (void)removeTopConversationObserverIfNeeded
{
    if (nil != self.observerToken) {
        [self.topConversationDirectory removeObserver:self.observerToken];
    }
}

- (void)setTopConversationDirectory:(TopConversationsDirectory *)topConversationDirectory
{
    [self removeTopConversationObserverIfNeeded];
    _topConversationDirectory = topConversationDirectory;
    // The directory can have cached conversations which we want to display immediately.
    [self updateTopPeople];
    self.observerToken = [self.topConversationDirectory addObserver:self];
    [self.topConversationDirectory refreshTopConversations];
}

- (void)reloadData
{
    [self.innerCollectionView reloadData];
}

- (void)updateTopPeople
{
    self.topPeople = self.topConversationDirectory.topConversations;
    [self reloadData];
}

- (BOOL)isHidden
{
    return (self.topPeople.count == 0);
}

+ (NSSet *)keyPathsForValuesAffectingIsHidden
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(topPeople))];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SearchSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                             withReuseIdentifier:PeoplePickerHeaderReuseIdentifier
                                                                                    forIndexPath:indexPath];
    
    headerView.title = NSLocalizedString(@"peoplepicker.header.top_people", @"");
    
    // in case of search, the headers are with zero frame, and their content should not be displayed
    // if not clipping, then part of the label is still displayed, so we clip it
    headerView.clipsToBounds = YES;
    return headerView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewContainerCell *genericCell = [collectionView dequeueReusableCellWithReuseIdentifier:StartUICollectionViewCellReuseIdentifier
                                                                                  forIndexPath:indexPath];

    genericCell.collectionView = self.innerCollectionView;

    return genericCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.collectionView.bounds.size.width, [WAZUIMagic cgFloatForIdentifier:@"people_picker.section_header.height"]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.collectionView.bounds.size.width, 97);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

#pragma mark - TopConversationsDirectoryObserver

- (void)topConversationsDidChange
{
    [self updateTopPeople];
}

#pragma mark - PeopleSelectionDelegate

- (void)peopleSelection:(PeopleSelection *)selection didDeselectUsers:(NSSet *)users
{
    [[self.innerCollectionView visibleCells] enumerateObjectsUsingBlock:^(UICollectionViewCell* cell, NSUInteger idx, BOOL *stop) {
        
        id user = [(TopPeopleCell *)cell user];
        
        if (user != nil && [users containsObject:user]) {
            cell.selected = NO;
            [self.innerCollectionView deselectItemAtIndexPath:[self.innerCollectionView indexPathForCell:cell] 
                                                     animated:NO];
        }
    }];
}

@end
