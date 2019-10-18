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


#import "ConversationListContentController.h"

#import "WireSyncEngine+iOS.h"
#import "ZMUserSession+iOS.h"

#import "UIColor+WAZExtensions.h"

#import "ProgressSpinner.h"

#import "ZClientViewController+Internal.h"

#import "ConversationListCell.h"

#import "ConversationContentViewController.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@implementation ConversationListContentController

- (void)dealloc
{
    // Observer must be deallocated before `mediaPlaybackManager`
    self.activeMediaPlayerObserver = nil;
    self.mediaPlaybackManager = nil;
}

- (instancetype)init
{
    UICollectionViewFlowLayout *flowLayout = [[BoundsAwareFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);

    self = [super initWithCollectionViewLayout:flowLayout];
    if (self) {

        if (nil != [UISelectionFeedbackGenerator class]) {
            self.selectionFeedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        }

        [self registerSectionHeader];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // viewWillAppear: can get called also when dismissing the controller above this one.
    // The user session might not be there anymore in some cases, e.g. when logging out
    if ([ZMUserSession sharedSession] == nil) {
        return;
    }
    [self updateVisibleCells];
    
    [self scrollToCurrentSelectionAnimated:NO];
    
    self.mediaPlaybackManager = AppDelegate.sharedAppDelegate.mediaPlaybackManager;
    self.activeMediaPlayerObserver = [KeyValueObserver observeObject:self.mediaPlaybackManager
                                                             keyPath:@"activeMediaPlayer"
                                                              target:self
                                                            selector:@selector(activeMediaPlayerChanged:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.activeMediaPlayerObserver = nil;
}

- (void)setupViews
{
    [self.collectionView registerClass:[ConnectRequestsCell class] forCellWithReuseIdentifier:CellReuseIdConnectionRequests];
    [self.collectionView registerClass:[ConversationListCell class] forCellWithReuseIdentifier:CellReuseIdConversation];
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.collectionView.delaysContentTouches = NO;
    self.collectionView.accessibilityIdentifier = @"conversation list";
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)updateVisibleCells
{
    [self updateCellForConversation:nil];
}

///TODO: mv logic to VM
- (void)updateCellForConversation:(ZMConversation *)conversation
{
    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        if ([cell isKindOfClass:[ConversationListCell class]]) {
            ConversationListCell *convListCell = (ConversationListCell *)cell;
            
            if (conversation == nil || [convListCell.conversation isEqual:conversation]) {
                [convListCell updateAppearance];
            }
        }
    }
}

- (BOOL)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated
{
    return [self selectConversation:conversation scrollToMessage:message focusOnView:focus animated:animated completion:nil];
}///TODO: mv logic to VM

- (BOOL)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    self.focusOnNextSelection = focus;

    self.selectConversationCompletion = completion;
    self.animateNextSelection = animated;
    self.scrollToMessageOnNextSelection = message;
    
    // Tell the model to select the item
    return [self selectModelItem:conversation];
}///TODO: mv logic to VM

- (void)deselectAll
{
    [self selectModelItem:nil];
}

/**
 * Selects a new list item if the current selection is removed.
 */
- (void)selectListItemAfterRemovingIndex:(NSUInteger)index section:(NSUInteger)sectionIndex
{
    // Select the next item after the item previous to the one that was deleted (important!)
    NSIndexPath *itemIndex = [self.listViewModel itemAfterIndex:index-1 section:sectionIndex];
    
    if (itemIndex == nil) {
        // we are at the bottom, so go backwards instead
        itemIndex = [self.listViewModel itemPreviousToIndex:index section:sectionIndex];
    }
    
    if (itemIndex != nil) {
        [self.contentDelegate conversationList:self willSelectIndexPathAfterSelectionDeleted:itemIndex];
        [self.listViewModel selectItemAtIndexPath:itemIndex];
    } else { //nothing to select anymore, we select nothing
        [self.listViewModel selectItem:nil];
    }
}

#pragma mark - Custom

+ (NSArray *)indexPathsForIndexes:(NSIndexSet *)indexes inSection:(NSUInteger)section
{
    __block NSMutableArray * result = [NSMutableArray arrayWithCapacity:indexes.count];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [result addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return result;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger sections = self.listViewModel.sectionCount;
    return sections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger c = [self.listViewModel numberOfItemsInSection:section];
    return c;
}

@end



@implementation ConversationListContentController (UICollectionViewDelegate)

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectionFeedbackGenerator prepare];
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectionFeedbackGenerator selectionChanged];
    
    id item = [self.listViewModel itemForIndexPath:indexPath];
    
    self.focusOnNextSelection = YES;
    self.animateNextSelection = YES;
    [self selectModelItem:item];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.contentDelegate respondsToSelector:@selector(conversationListDidScroll:)]) {
        [self.contentDelegate conversationListDidScroll:self];
    }
}

@end




@implementation ConversationListContentController (PeekAndPop)

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (indexPath == nil) {
        return nil;
    }
    
    UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    if (layoutAttributes == nil) {
        return nil;
    }
    
    id conversation = [self.listViewModel itemForIndexPath:indexPath];
    if (![conversation isKindOfClass:[ZMConversation class]]) {
        return nil;
    }
    
    previewingContext.sourceRect = layoutAttributes.frame;
    ConversationPreviewViewController *previewViewController = [[ConversationPreviewViewController alloc] initWithConversation:conversation presentingViewController:self];
    
    return previewViewController;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    if (![viewControllerToCommit isKindOfClass:[ConversationPreviewViewController class]]) {
        return;
    }
    
    ConversationPreviewViewController *previewViewController = (ConversationPreviewViewController*)viewControllerToCommit;
    
    self.focusOnNextSelection = YES;
    self.animateNextSelection = YES;
    [self selectModelItem:previewViewController.conversation];
}

@end  
