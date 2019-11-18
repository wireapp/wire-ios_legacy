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


#import "ConversationContentViewController+Private.h"
#import "ConversationContentViewController+PinchZoom.h"

#import "ConversationViewController.h"
#import "ConversationViewController+Private.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@import WireSyncEngine;

@import AVKit;

// model

// ui
#import "ZClientViewController.h"

// helpers


#import "UIView+Zeta.h"
#import "Analytics.h"
#import "AppDelegate.h"
#import "MediaPlaybackManager.h"
#import "MessagePresenter.h"
#import "UIViewController+WR_Additions.h"

#import "Wire-Swift.h"

@interface ConversationContentViewController (TableView) <UITableViewDelegate, UITableViewDataSourcePrefetching>
@end

@interface ConversationContentViewController (ZMTypingChangeObserver) <ZMTypingChangeObserver>
@end

@interface ConversationContentViewController () 

@property (nonatomic, assign) BOOL wasScrolledToBottomAtStartOfUpdate;
@property (nonatomic) NSObject *activeMediaPlayerObserver;
@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) NSMutableDictionary *cachedRowHeights;
@property (nonatomic) BOOL hasDoneInitialLayout;
@property (nonatomic) BOOL onScreen;
@property (nonatomic) UserConnectionViewController *connectionViewController;
@property (nonatomic) id<ZMConversationMessage> messageVisibleOnLoad;
@end



@implementation ConversationContentViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
                mediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager
                             session:(id<ZMUserSessionInterface>)session
{
    return [self initWithConversation:conversation
                              message:conversation.firstUnreadMessage
                 mediaPlaybackManager:mediaPlaybackManager
                              session:session];
}

- (instancetype)initWithConversation:(ZMConversation *)conversation
                             message:(id<ZMConversationMessage>)message
                mediaPlaybackManager:(MediaPlaybackManager *)mediaPlaybackManager
                             session:(id<ZMUserSessionInterface>)session
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        self.mediaPlaybackManager = mediaPlaybackManager;
        self.messageVisibleOnLoad = message ?: conversation.firstUnreadMessage;
        self.cachedRowHeights = [NSMutableDictionary dictionary];
        self.messagePresenter = [[MessagePresenter alloc] initWithMediaPlaybackManager:mediaPlaybackManager];
        self.messagePresenter.targetViewController = self;
        self.messagePresenter.modalTargetController = self.parentViewController;
        self.session = session;
    }
    
    return self;
}

- (void)dealloc
{
    // Observer must be deallocated before `mediaPlaybackManager`
    self.activeMediaPlayerObserver = nil;
    self.mediaPlaybackManager = nil;
    
    if (nil != self.tableView) {
        self.tableView.delegate = nil;
        self.tableView.dataSource = nil;
    }
    
    [self.pinchImageView removeFromSuperview];
    [self.dimView removeFromSuperview];
}

- (void)loadView
{
    [super loadView];
    
    self.tableView = [[UpsideDownTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    
    self.bottomContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomContainer];

    [NSLayoutConstraint activateConstraints:@[
      [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.bottomContainer.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
      [self.bottomContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.bottomContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.bottomContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    NSLayoutConstraint *heightCollapsingConstraint = [self.bottomContainer.heightAnchor constraintEqualToConstant:0];
    heightCollapsingConstraint.priority = UILayoutPriorityDefaultHigh;
    heightCollapsingConstraint.active = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setDataSource];
    self.tableView.estimatedRowHeight = 80;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delaysContentTouches = NO;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [UIView performWithoutAnimation:^{
        self.tableView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorContentBackground];
        self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorContentBackground];
    }];
    
    UIPinchGestureRecognizer *pinchImageGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                                      action:@selector(onPinchZoom:)];
    pinchImageGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:pinchImageGestureRecognizer];
    
    [self createMentionsResultsView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self.dataSource resetSectionControllers];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.onScreen = YES;
    self.activeMediaPlayerObserver = [KeyValueObserver observeObject:self.mediaPlaybackManager
                                                             keyPath:@"activeMediaPlayer"
                                                              target:self
                                                            selector:@selector(activeMediaPlayerChanged:)

                                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];

    for (UITableViewCell *cell in self.tableView.visibleCells) {        
        if ([cell respondsToSelector:@selector(willDisplayCell)]) {
            [cell willDisplayCell];
        }
    }
    
    self.messagePresenter.modalTargetController = self.parentViewController;

    [self updateHeaderHeight];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateVisibleMessagesWindow];

    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }

    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.onScreen = NO;
    [self removeHighlightsAndMenu];
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self scrollToFirstUnreadMessageIfNeeded];
    [self updatePopover];
}

- (void)scrollToFirstUnreadMessageIfNeeded
{
    if (! self.hasDoneInitialLayout) {
        self.hasDoneInitialLayout = YES;
        [self scrollToMessage:self.messageVisibleOnLoad completion:nil];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    ZMLogWarn(@"Received system memory warning.");
    [super didReceiveMemoryWarning];
}

- (void)updateTableViewHeaderView
{
    if (self.dataSource.hasOlderMessagesToLoad) {
        // Don't display the conversation header if the message window doesn't include the first message.
        return;
    }
    
    UIView *headerView = nil;
    ZMUser *otherParticipant = self.conversation.firstActiveParticipantOtherThanSelf;
    BOOL connectionOrOneOnOne = self.conversation.conversationType == ZMConversationTypeConnection || self.conversation.conversationType == ZMConversationTypeOneOnOne;

    if (connectionOrOneOnOne && nil != otherParticipant) {
        self.connectionViewController = [[UserConnectionViewController alloc] initWithUserSession:[ZMUserSession sharedSession] user:otherParticipant];
        headerView = self.connectionViewController.view;
    }
    
    if (headerView) {
        headerView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
        [self setConversationHeaderView:headerView];
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)setConversationHeaderView:(UIView *)headerView
{
    headerView.frame = [self headerViewFrameWithView:headerView];
    self.tableView.tableHeaderView = headerView;
}

- (void)setSearchQueries:(NSArray<NSString *> *)searchQueries
{
    if (_searchQueries.count == 0 && searchQueries.count == 0) {
        return;
    }
    
    _searchQueries = searchQueries;

    self.dataSource.searchQueries = self.searchQueries;
}

#pragma mark - Get/set

- (void)setBottomMargin:(CGFloat)bottomMargin
{
    _bottomMargin = bottomMargin;
    [self setTableViewBottomMargin:bottomMargin];
}

- (void)setTableViewBottomMargin:(CGFloat)bottomMargin
{
    UIEdgeInsets insets = self.tableView.correctedContentInset;
    insets.bottom = bottomMargin;
    [self.tableView setCorrectedContentInset:insets];
    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, -bottomMargin)];
}

- (BOOL)isScrolledToBottom
{
    return !self.dataSource.hasNewerMessagesToLoad && self.tableView.contentOffset.y + self.tableView.correctedContentInset.bottom <= 0;
}
#pragma mark - Actions

- (void)highlightMessage:(id<ZMConversationMessage>)message;
{
    [self.dataSource highlightMessage:message];
}

- (void)updateVisibleMessagesWindow
{
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
        return; // We only update the last read if the app is active
    }
    
    BOOL isViewVisible = YES;
    if (self.view.window == nil) {
        isViewVisible = NO;
    }
    else if (self.view.hidden) {
        isViewVisible = NO;
    }
    else if (self.view.alpha == 0) {
        isViewVisible = NO;
    }
    else {
        CGRect viewFrameInWindow = [self.view.window convertRect:self.view.bounds fromView:self.view];
        if (! CGRectIntersectsRect(viewFrameInWindow, self.view.window.bounds)) {
            isViewVisible = NO;
        }
    }
    
    // We should not update last read if the view is not visible to the user
    if (! isViewVisible) {
        return;
    }
    
//  Workaround to fix incorrect first/last cells in conversation
//  As described in http://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
    [self.tableView visibleCells];
    NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *firstIndexPath = indexPathsForVisibleRows.firstObject;
    
    if (firstIndexPath) {
        id<ZMConversationMessage>lastVisibleMessage = [self.dataSource.messages objectAtIndex:firstIndexPath.section];

        [self.conversation markMessagesAsReadUntil:lastVisibleMessage];
    }

    /// update media bar visiblity
    [self updateMediaBar];
}

#pragma mark - Custom UI, utilities

- (void)removeHighlightsAndMenu
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (NSIndexPath *) willSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    ZMMessage *message = (ZMMessage *)[self.dataSource.messages objectAtIndex:indexPath.section];
    NSIndexPath *selectedIndexPath = nil;

    // If the menu is visible, hide it and do nothing
    if (UIMenuController.sharedMenuController.isMenuVisible) {
        [UIMenuController.sharedMenuController setMenuVisible:NO animated:YES];
        return nil;
    }

    if ([message isEqual:self.dataSource.selectedMessage]) {

        // If this cell is already selected, deselect it.
        self.dataSource.selectedMessage  = nil;
        [self.dataSource deselectWithIndexPath:indexPath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        if (tableView.indexPathForSelectedRow != nil) {
            [self.dataSource deselectWithIndexPath:tableView.indexPathForSelectedRow];
        }
        self.dataSource.selectedMessage = message;
        [self.dataSource selectWithIndexPath:indexPath];
        selectedIndexPath = indexPath;
    }

    return selectedIndexPath;
}

@end



@implementation ConversationContentViewController (TableView)

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(willDisplayCell)] && self.onScreen) {
        [(id)cell willDisplayCell];
    }
    
	// using dispatch_async because when this method gets run, the cell is not yet in visible cells,
	// so the update will fail
	// dispatch_async runs it with next runloop, when the cell has been added to visible cells
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateVisibleMessagesWindow];
	});
    
    [self.cachedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(didEndDisplayingCell)]) {
        [(id)cell didEndDisplayingCell];
    }
    
    [self.cachedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *cachedHeight = [self.cachedRowHeights objectForKey:indexPath];
    
    if (cachedHeight != nil) {
        return cachedHeight.floatValue;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self willSelectRowAtIndexPath:indexPath tableView:tableView];
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
}

@end

@implementation ConversationContentViewController (EditMessages)

- (void)didFinishEditingMessage:(id<ZMConversationMessage>)message
{
    self.dataSource.editingMessage = nil;
}

@end
