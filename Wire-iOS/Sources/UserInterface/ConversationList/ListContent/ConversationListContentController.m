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

@import PureLayout;

#import "WireSyncEngine+iOS.h"
#import "ZMUserSession+iOS.h"

#import "ConversationListViewModel.h"

#import "UIColor+WAZExtensions.h"

#import "ProgressSpinner.h"

#import "ZClientViewController+Internal.h"


#import "ConnectRequestsCell.h"
#import "ConversationListCell.h"

#import "ConversationContentViewController.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";
static NSString * const CellReuseIdConnectionRequests = @"CellIdConnectionRequests";
static NSString * const CellReuseIdConversation = @"CellId";

@interface ConversationListContentController () <ConversationListViewModelDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) ConversationListViewModel *listViewModel;

@property (nonatomic) NSObject *activeMediaPlayerObserver;
@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) BOOL focusOnNextSelection;
@property (nonatomic) BOOL animateNextSelection;
@property (nonatomic) id<ZMConversationMessage> scrollToMessageOnNextSelection;
@property (nonatomic, copy) dispatch_block_t selectConversationCompletion;
@property (nonatomic) ConversationListCell *layoutCell;
@property (nonatomic) ConversationCallController *startCallController;

@property (nonatomic) UISelectionFeedbackGenerator *selectionFeedbackGenerator;
@end

@interface ConversationListContentController (ConversationListCellDelegate) <ConversationListCellDelegate>

@end

@interface ConversationListContentController (PeekAndPop) <UIViewControllerPreviewingDelegate>

@end

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
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.layoutCell = [[ConversationListCell alloc] init];
    
    self.listViewModel = [[ConversationListViewModel alloc] init];
    self.listViewModel.delegate = self;
    [self setupViews];
    
    if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)] &&
        [[UIApplication sharedApplication] keyWindow].traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
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

- (void)listViewModelShouldBeReloaded
{
    [self reload];
}

- (void)listViewModel:(ConversationListViewModel *)model didUpdateSectionForReload:(NSUInteger)section
{
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
    [self ensureCurrentSelection];
}

- (void)listViewModel:(ConversationListViewModel *)model didUpdateSection:(NSUInteger)section usingBlock:(dispatch_block_t)updateBlock withChangedIndexes:(ZMChangedIndexes *)changedIndexes
{
    // If we are about to delete the currently selected conversation, select a different one
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    [selectedItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *selectedIndexPath = obj;
        [changedIndexes.deletedIndexes enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
            if (selectedIndexPath.section == (NSInteger)section && selectedIndexPath.item == (NSInteger)idx) {
                // select a different conversation
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self selectListItemAfterRemovingIndex:selectedIndexPath.item section:selectedIndexPath.section];
                });
            }
        }];
    }];
    
    [self.collectionView performBatchUpdates:^{
        
        if (updateBlock) {
            updateBlock();
        }
        
        // Delete
        if (changedIndexes.deletedIndexes.count > 0) {
            [self.collectionView deleteItemsAtIndexPaths:[[self class] indexPathsForIndexes:changedIndexes.deletedIndexes inSection:section]];
        }
        
        // Insert
        if (changedIndexes.insertedIndexes.count > 0) {
            [self.collectionView insertItemsAtIndexPaths:[[self class] indexPathsForIndexes:changedIndexes.insertedIndexes inSection:section]];
        }
        
        // Move
        [changedIndexes enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
            NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:from inSection:section];
            NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:to inSection:section];
            
            [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        }];
    } completion:^(BOOL finished) {
        [self ensureCurrentSelection];
    }];
}

- (void)listViewModel:(ConversationListViewModel *)model didSelectItem:(id)item
{
    if (item == nil) {
        // Deselect all items in the collection view
        NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
        [indexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.collectionView deselectItemAtIndexPath:obj animated:NO];
        }];
        [[ZClientViewController sharedZClientViewController] loadPlaceholderConversationControllerAnimated:YES];
    }
    else {
        
        if ([item isKindOfClass:[ZMConversation class]]) {
            
            ZMConversation *conversation = item;
            
            // Actually load the new view controller and optionally focus on it
            [[ZClientViewController sharedZClientViewController] loadConversation:conversation
                                                                  scrollToMessage:self.scrollToMessageOnNextSelection
                                                                      focusOnView:self.focusOnNextSelection
                                                                         animated:self.animateNextSelection
                                                                       completion:self.selectConversationCompletion];
            self.selectConversationCompletion = nil;
            
            [self.contentDelegate conversationList:self didSelectConversation:item focusOnView:! self.focusOnNextSelection];
        }
        else if ([item isKindOfClass:[ConversationListConnectRequestsItem class]]) {
            [[ZClientViewController sharedZClientViewController] loadIncomingContactRequestsAndFocusOnView:self.focusOnNextSelection
                                                                                                  animated:YES];
        }
        else {
            NSAssert(NO, @"Invalid item in conversation list view model!!");
        }
        // Make sure the correct item is selected in the list, without triggering a collection view
        // callback
        [self ensureCurrentSelection];
    }
    
    self.scrollToMessageOnNextSelection = nil;
    self.focusOnNextSelection = NO;
}

- (void)listViewModel:(ConversationListViewModel *)model didUpdateConversationWithChange:(ConversationChangeInfo *)change
{
    if (change.isArchivedChanged ||
        change.conversationListIndicatorChanged ||
        change.nameChanged ||
        change.unreadCountChanged ||
        change.connectionStateChanged ||
        change.mutedMessageTypesChanged ||
        change.messagesChanged) {
        
        [self updateCellForConversation:change.conversation];
    }
}

- (void)updateVisibleCells
{
    [self updateCellForConversation:nil];
}

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
}

- (BOOL)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    self.focusOnNextSelection = focus;

    self.selectConversationCompletion = completion;
    self.animateNextSelection = animated;
    self.scrollToMessageOnNextSelection = message;
    
    // Tell the model to select the item
    return [self selectModelItem:conversation];
}

- (BOOL)selectInboxAndFocusOnView:(BOOL)focus
{
    // If there is anything in the inbox, select it
    if ([self.listViewModel numberOfItemsInSection:0] > 0) {
        
        self.focusOnNextSelection = focus;
        [self selectModelItem:self.listViewModel.contactRequestsItem];
        return YES;
    }
    return NO;
}

- (BOOL)selectModelItem:(id)itemToSelect
{
    return [self.listViewModel selectItem:itemToSelect];
}

- (void)deselectAll
{
    [self selectModelItem:nil];
}

/**
 * ensures that the list selection state matches that of the model.
 */
- (void)ensureCurrentSelection
{
    if (self.listViewModel.selectedItem == nil) {
        return;
    }
    
    NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    NSIndexPath *currentIndexPath = [self.listViewModel indexPathForItem:self.listViewModel.selectedItem];
    
    if (! [selectedIndexPaths containsObject:currentIndexPath] && currentIndexPath != nil) {
        // This method doesn't trigger any delegate callbacks, so no worries about special handling
        [self.collectionView selectItemAtIndexPath:currentIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)scrollToCurrentSelectionAnimated:(BOOL)animated
{
    NSIndexPath *selectedIndexPath = [self.listViewModel indexPathForItem:self.listViewModel.selectedItem];
    
    if (selectedIndexPath != nil) {
        // Check if indexPath is valid for the collection view
        if (self.collectionView.numberOfSections > selectedIndexPath.section &&
            [self.collectionView numberOfItemsInSection:selectedIndexPath.section] > selectedIndexPath.item) {
            // Check for visibility
            NSArray *visibleIndexPaths = self.collectionView.indexPathsForVisibleItems;
            if (visibleIndexPaths.count > 0 && ! [visibleIndexPaths containsObject:selectedIndexPath]) {
                [self.collectionView scrollToItemAtIndexPath:selectedIndexPath atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
            }
        }
    }
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

- (void)reload
{
    [self.collectionView reloadData];
    [self ensureCurrentSelection];
    
    // we MUST call layoutIfNeeded here because otherwise bad things happen when we close the archive, reload the conv
    // and then unarchive all at the same time
    [self.view layoutIfNeeded];
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

#pragma mark - ActiveMediaPlayer observer

- (void)activeMediaPlayerChanged:(NSDictionary *)change
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (ConversationListCell *cell in self.collectionView.visibleCells) {
            [cell updateAppearance];
        }
    });
}

@end



@implementation ConversationListContentController (UICollectionViewDataSource)

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

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self.listViewModel itemForIndexPath:indexPath];
    UICollectionViewCell *cell = nil;

    if ([item isKindOfClass:[ConversationListConnectRequestsItem class]]) {
        ConnectRequestsCell *labelCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdConnectionRequests forIndexPath:indexPath];
        cell = labelCell;
    }
    else if ([item isKindOfClass:[ZMConversation class]]) {
        ConversationListCell *listCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdConversation forIndexPath:indexPath];
        listCell.delegate = self;
        listCell.mutuallyExclusiveSwipeIdentifier = @"ConversationList";
        listCell.conversation = item;
        cell = listCell;
    } else {
        RequireString(false, "Unknown cell type");
    }

    cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    return cell;
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
    // Close open drawers in the cells
    [[NSNotificationCenter defaultCenter] postNotificationName:SwipeMenuCollectionCellCloseDrawerNotification object:nil];
    if ([self.contentDelegate respondsToSelector:@selector(conversationListDidScroll:)]) {
        [self.contentDelegate conversationListDidScroll:self];
    }
}

@end



@implementation ConversationListContentController (UICollectionViewDelegateFlowLayout)

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.layoutCell sizeInCollectionViewSize:collectionView.bounds.size];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    if (section == 0) {
        return UIEdgeInsetsMake(12, 0, 0, 0);
    }
    else {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

@end

@implementation ConversationListContentController (ConversationListCellDelegate)

- (void)conversationListCellOverscrolled:(ConversationListCell *)cell
{
    ZMConversation *conversation = cell.conversation;
    if (! conversation) {
        return;
    }
    
    if ([self.contentDelegate respondsToSelector:@selector(conversationListContentController:wantsActionMenuForConversation:fromSourceView:)]) {
        [self.contentDelegate conversationListContentController:self wantsActionMenuForConversation:conversation fromSourceView:cell];
    }
}
    
- (void)conversationListCellJoinCallButtonTapped:(ConversationListCell *)cell
{
    self.startCallController = [[ConversationCallController alloc] initWithConversation:cell.conversation target:self];
    [self.startCallController joinCall];
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
