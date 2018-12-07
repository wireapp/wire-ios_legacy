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
#import "ConversationContentViewController+Scrolling.h"
#import "ConversationContentViewController+PinchZoom.h"

#import "ConversationViewController.h"
#import "ConversationViewController+Private.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@import WireSyncEngine;
@import WireExtensionComponents;
@import AVKit;

// model
#import "WireSyncEngine+iOS.h"
#import "ConversationMessageWindowTableViewAdapter.h"

// ui
#import "ZClientViewController.h"
#import "NotificationWindowRootViewController.h"

// helpers
#import "Constants.h"

@import PureLayout;
#import "UIView+Zeta.h"
#import "Analytics.h"
#import "AppDelegate.h"
#import "MediaPlaybackManager.h"
#import "MessagePresenter.h"
#import "UIViewController+WR_Additions.h"

#import "Wire-Swift.h"


const static int ConversationContentViewControllerMessagePrefetchDepth = 10;


@interface ConversationContentViewController (TableView) <UITableViewDelegate, UITableViewDataSourcePrefetching>

@end



@interface ConversationContentViewController (ConversationCellDelegate) <ConversationCellDelegate>

@end



@interface ConversationContentViewController (ZMTypingChangeObserver) <ZMTypingChangeObserver>

@end



@interface ConversationContentViewController () <CanvasViewControllerDelegate>

@property (nonatomic, readwrite) ConversationMessageWindowTableViewAdapter *conversationMessageWindowTableViewAdapter;
@property (nonatomic, assign) BOOL wasScrolledToBottomAtStartOfUpdate;
@property (nonatomic) NSObject *activeMediaPlayerObserver;
@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) NSMutableDictionary *cachedRowHeights;
@property (nonatomic) BOOL hasDoneInitialLayout;
@property (nonatomic) id messageWindowObserverToken;
@property (nonatomic) BOOL onScreen;
@property (nonatomic) UserConnectionViewController *connectionViewController;
@property (nonatomic) DeletionDialogPresenter *deletionDialogPresenter;
@property (nonatomic) id<ZMConversationMessage> messageVisibleOnLoad;
@end



@implementation ConversationContentViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    return [self initWithConversation:conversation message:conversation.firstUnreadMessage];
}

- (instancetype)initWithConversation:(ZMConversation *)conversation message:(id<ZMConversationMessage>)message
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        self.messageVisibleOnLoad = message ?: conversation.firstUnreadMessage;
        self.cachedRowHeights = [NSMutableDictionary dictionary];
        self.messagePresenter = [[MessagePresenter alloc] init];
        self.messagePresenter.targetViewController = self;
        self.messagePresenter.modalTargetController = self.parentViewController;
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
    
    self.messageWindow = [self.conversation conversationWindowWithSize:30];
    self.conversationMessageWindowTableViewAdapter =
    [[ConversationMessageWindowTableViewAdapter alloc] initWithTableView:self.tableView
                                                           messageWindow:self.messageWindow];
    self.conversationMessageWindowTableViewAdapter.conversationCellDelegate = self;
    self.conversationMessageWindowTableViewAdapter.messageActionResponder = self;
    
    self.messageWindowObserverToken = [MessageWindowChangeInfo addObserver:self forWindow:self.messageWindow];
    
    self.tableView.estimatedRowHeight = 80;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self.conversationMessageWindowTableViewAdapter;
    if ([self.tableView respondsToSelector:@selector(setPrefetchDataSource:)]) {
        self.tableView.prefetchDataSource = self;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delaysContentTouches = NO;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [UIView performWithoutAnimation:^{
        self.tableView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorContentBackground];
        self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorContentBackground];
    }];
    
    UIPinchGestureRecognizer *pinchImageGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinchZoom:)];
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
    self.conversationMessageWindowTableViewAdapter.sectionControllers = [[NSMutableDictionary alloc] init];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.onScreen = YES;
    self.mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    self.activeMediaPlayerObserver = [KeyValueObserver observeObject:self.mediaPlaybackManager
                                                             keyPath:@"activeMediaPlayer"
                                                              target:self
                                                            selector:@selector(activeMediaPlayerChanged:)

                                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];

    for (ConversationCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:ConversationCell.class]) {
            [cell willDisplayInTableView];
        }
        
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

    [self scrollToFirstUnreadMessageIfNeeded];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.onScreen = NO;
    [self removeHighlightsAndMenu];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    for (ConversationCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:ConversationCell.class]) {
            [cell cellDidEndBeingVisible];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self updatePopover];
}

- (void)scrollToFirstUnreadMessageIfNeeded
{
    if (! self.hasDoneInitialLayout) {
        self.hasDoneInitialLayout = YES;
        [self updateTableViewHeaderView];
        if (self.messageVisibleOnLoad != nil) {
            [self scrollToMessage:self.messageVisibleOnLoad animated:NO];
        }
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)didReceiveMemoryWarning
{
    ZMLogWarn(@"Received system memory warning.");
    [super didReceiveMemoryWarning];
}

- (void)updateTableViewHeaderView
{
    if (self.messageWindow.messages.count != self.conversation.messages.count) {
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
    self.conversationMessageWindowTableViewAdapter.searchQueries = self.searchQueries;
    [self.conversationMessageWindowTableViewAdapter reconfigureVisibleSections];
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
    return self.tableView.contentOffset.y + self.tableView.correctedContentInset.bottom <= 0;
}
#pragma mark - Actions

- (void)highlightMessage:(id<ZMConversationMessage>)message;
{
    [self.conversationMessageWindowTableViewAdapter highlightMessage:message];
}

- (void)wantsToPerformAction:(MessageAction)actionId forMessage:(id<ZMConversationMessage>)message cell:(UIView<SelectableView> *)cell
{
    dispatch_block_t action = ^{
        switch (actionId) {
            case MessageActionCancel:
            {
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    [message.fileMessageData cancelTransfer];
                }];
            }
                break;
                
            case MessageActionResend:
            {
                [[ZMUserSession sharedSession] enqueueChanges:^{
                    [message resend];
                }];
            }
                break;
                
            case MessageActionDelete:
            {
                assert([message canBeDeleted]);

                self.deletionDialogPresenter = [[DeletionDialogPresenter alloc] initWithSourceViewController:self.presentedViewController ?: self];
                [self.deletionDialogPresenter presentDeletionAlertControllerForMessage:message source:cell completion:^(BOOL deleted) {
                    if (self.presentedViewController && deleted) {
                        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
                    }
                    if (!deleted) {
                        // TODO 2838: Support editing
                        // cell.beingEdited = NO;
                    }
                }];
            }
                break;
            case MessageActionPresent:
            {
                self.conversationMessageWindowTableViewAdapter.selectedMessage = message;
                [self presentDetailsForMessage:message];
            }
                break;
            case MessageActionSave:
            {
                if ([Message isImageMessage:message]) {
                    [self saveImageFromMessage:message cell:cell];
                } else {
                    self.conversationMessageWindowTableViewAdapter.selectedMessage = message;
                    UIView *targetView = cell.selectionView;

                    UIActivityViewController *saveController = [[UIActivityViewController alloc] initWithMessage:message from:targetView];
                    [self presentViewController:saveController animated:YES completion:nil];
                }
            }
                break;
            case MessageActionEdit:
            {
                self.conversationMessageWindowTableViewAdapter.editingMessage = message;
                [self.delegate conversationContentViewController:self didTriggerEditingMessage:message];
            }
                break;
            case MessageActionSketchDraw:
            {
                [self openSketchForMessage:message inEditMode:CanvasViewControllerEditModeDraw];
            }
                break;
            case MessageActionSketchEmoji:
            {
                [self openSketchForMessage:message inEditMode:CanvasViewControllerEditModeEmoji];
            }
                break;
            case MessageActionSketchText:
            {
                // Not implemented yet
            }
                break;
            case MessageActionLike:
            {
                BOOL liked = ![Message isLikedMessage:message];
                
                NSIndexPath *indexPath = [self.conversationMessageWindowTableViewAdapter indexPathForMessage:message];
                
                [[ZMUserSession sharedSession] performChanges:^{
                    [Message setLikedMessage:message liked:liked];
                }];
                
                if (liked) {
                    // Deselect if necessary to show list of likers
                    if (self.conversationMessageWindowTableViewAdapter.selectedMessage == message) {
                        [self tableView:self.tableView willSelectRowAtIndexPath:indexPath];
                    }
                } else {
                    // Select if necessary to prevent message from collapsing
                    if (self.conversationMessageWindowTableViewAdapter.selectedMessage != message && ![Message hasReactions:message]) {
                        [self tableView:self.tableView willSelectRowAtIndexPath:indexPath];
                        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                }
            }
                break;
            case MessageActionForward:
            {
                [self showForwardForMessage:message fromCell:cell];
            }
                break;
            case MessageActionShowInConversation:
            {
                [self scrollTo:message completion:^(UIView *cell) {
                    [self.conversationMessageWindowTableViewAdapter highlightMessage:message];
                }];
            }
                break;
            case MessageActionCopy:
            {
                [Message copy:message in:UIPasteboard.generalPasteboard];
            }
                break;
            
            case MessageActionDownload:
            {
                [ZMUserSession.sharedSession enqueueChanges:^{
                    [message.fileMessageData requestFileDownload];
                }];
            }
                break;
            case MessageActionReply:
            {
                [self.delegate conversationContentViewController:self didTriggerReplyingToMessage:message];
            }
                break;
            case MessageActionOpenQuote:
            {
                if (message.textMessageData.quote) {
                    id<ZMConversationMessage> quote = message.textMessageData.quote;
                    [self scrollTo:quote completion:^(UIView *cell) {
                        [self.conversationMessageWindowTableViewAdapter highlightMessage:quote];
                    }];
                }
            }
                break;
            case MessageActionOpenDetails:
            {
                MessageDetailsViewController *detailsViewController = [[MessageDetailsViewController alloc] initWithMessage:message];
                [self.parentViewController presentViewController:detailsViewController animated:YES completion:nil];
            }
                break;
        }
    };

    BOOL shouldDismissModal = actionId != MessageActionDelete && actionId != MessageActionCopy;

    if (self.messagePresenter.modalTargetController.presentedViewController != nil && shouldDismissModal) {
        [self.messagePresenter.modalTargetController dismissViewControllerAnimated:YES completion:^{
            action();
        }];
    }
    else {
        action();
    }
}

- (void)updateVisibleMessagesWindow
{
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
        id<ZMConversationMessage>lastVisibleMessage = [self.messageWindow.messages objectAtIndex:firstIndexPath.section];
        [self.conversation markMessagesAsReadUntil:lastVisibleMessage];
    }
}

- (void)presentDetailsForMessage:(id<ZMConversationMessage>)message
{
    BOOL isFile = [Message isFileTransferMessage:message];
    BOOL isImage = [Message isImageMessage:message];
    BOOL isLocation = [Message isLocationMessage:message];
    
    if (! isFile && ! isImage && ! isLocation) {
        return;
    }
    
    UITableViewCell *cell = [self cellForMessage:message];
    
    // If the user tapped on a file or image and the menu controller is currently visible,
    // we do not want to show the detail but instead hide the menu controller first.
    // TODO: Remove when the file cell is ported to the new system
    if ([cell isKindOfClass:ConversationCell.class] && [(ConversationCell *)cell showsMenu]) {
        [self removeHighlightsAndMenu];
        return;
    }
    
    [self.messagePresenter openMessage:message targetView:cell actionResponder:self];
}

- (void)openSketchForMessage:(id<ZMConversationMessage>)message inEditMode:(CanvasViewControllerEditMode)editMode
{
    CanvasViewController *canvasViewController = [[CanvasViewController alloc] init];
    canvasViewController.sketchImage = [UIImage imageWithData:message.imageMessageData.imageData];
    canvasViewController.delegate = self;
    canvasViewController.title = message.conversation.displayName.uppercaseString;
    [canvasViewController selectWithEditMode:editMode animated:NO];
    
    [self presentViewController:[canvasViewController wrapInNavigationController] animated:YES completion:nil];
}

- (void)canvasViewController:(CanvasViewController *)canvasViewController didExportImage:(UIImage *)image
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:^{
        if (image) {
            NSData *imageData = UIImagePNGRepresentation(image);
            
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [self.conversation appendMessageWithImageData:imageData];
            } completionHandler:^{
                [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:self.conversation];
            }];
        }
    }];
}

#pragma mark - Custom UI, utilities

- (void)createMentionsResultsView
{    
    self.mentionsSearchResultsViewController = [[UserSearchResultsViewController alloc] init];
    self.mentionsSearchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    // delegate here
    
    [self addChildViewController:self.mentionsSearchResultsViewController];
    [self.view addSubview:self.mentionsSearchResultsViewController.view];
    
    [self.mentionsSearchResultsViewController.view autoPinEdgesToSuperviewEdges];
}

- (void)removeHighlightsAndMenu
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (ConversationCell *)cellForMessage:(id<ZMConversationMessage>)message
{
    NSIndexPath *indexPath = [self.conversationMessageWindowTableViewAdapter indexPathForMessage:message];
    
    if (indexPath == nil) {
        return nil;
    }
    
    ConversationCell *cell = (ConversationCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (BOOL)displaysMessage:(id<ZMConversationMessage>)message
{
    NSInteger index = [self.messageWindow.messages indexOfObject:message];

    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        if (indexPath.row == index) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - ActiveMediaPlayer observer

- (void)activeMediaPlayerChanged:(NSDictionary *)change
{
    dispatch_async(dispatch_get_main_queue(), ^{        
        MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
        id<ZMConversationMessage>mediaPlayingMessage = mediaPlaybackManager.activeMediaPlayer.sourceMessage;
        
        if (mediaPlayingMessage && [mediaPlayingMessage.conversation isEqual:self.conversation] && ! [self displaysMessage:mediaPlayingMessage]) {
            [self.delegate conversationContentViewController:self didEndDisplayingActiveMediaPlayerForMessage:nil];
        } else {
            [self.delegate conversationContentViewController:self willDisplayActiveMediaPlayerForMessage:nil];
        }
    });
}

@end



@implementation ConversationContentViewController (TableView)

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO 2838: Support ping animation, ephemeral timer and media playback
//    if ([cell isKindOfClass:[TextMessageCell class]] || [cell isKindOfClass:[AudioMessageCell class]]) {
//        ConversationCell *messageCell = (ConversationCell *)cell;
//        MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
//
//        if (mediaPlaybackManager.activeMediaPlayer != nil && mediaPlaybackManager.activeMediaPlayer.sourceMessage == messageCell.message) {
//            [self.delegate conversationContentViewController:self willDisplayActiveMediaPlayerForMessage:messageCell.message];
//        }
//    }
    
    if ([cell respondsToSelector:@selector(willDisplayCell)] && self.onScreen) {
        [(id)cell willDisplayCell];
    }

    ConversationCell *conversationCell = nil;
    if ([cell isKindOfClass:ConversationCell.class]) {
        conversationCell = (ConversationCell *)cell;
    }
    
	// using dispatch_async because when this method gets run, the cell is not yet in visible cells,
	// so the update will fail
	// dispatch_async runs it with next runloop, when the cell has been added to visible cells
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateVisibleMessagesWindow];
	});
    
    [conversationCell willDisplayInTableView];
    [self.cachedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO 2838: Support ping animation, ephemeral timer and media playback
//    if ([cell isKindOfClass:[TextMessageCell class]] || [cell isKindOfClass:[AudioMessageCell class]]) {
//        ConversationCell *messageCell = (ConversationCell *)cell;
//        MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
//        if (mediaPlaybackManager.activeMediaPlayer != nil && mediaPlaybackManager.activeMediaPlayer.sourceMessage == messageCell.message) {
//            [self.delegate conversationContentViewController:self didEndDisplayingActiveMediaPlayerForMessage:messageCell.message];
//        }
//    }
    
    if ([cell respondsToSelector:@selector(didEndDisplayingCell)]) {
        [(id)cell didEndDisplayingCell];
    }

    ConversationCell *conversationCell = nil;
    if ([cell isKindOfClass:ConversationCell.class]) {
        conversationCell = (ConversationCell *)cell;
    }
    
    [conversationCell didEndDisplayingInTableView];
    
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
    ZMMessage *message = [self.messageWindow.messages objectAtIndex:indexPath.section];
    NSIndexPath *selectedIndexPath = nil;

    // If the menu is visible, hide it and do nothing
    if (UIMenuController.sharedMenuController.isMenuVisible) {
        [UIMenuController.sharedMenuController setMenuVisible:NO animated:YES];
        return nil;
    }

    if ([message isEqual:self.conversationMessageWindowTableViewAdapter.selectedMessage]) {
        
        // If this cell is already selected, deselect it.
        self.conversationMessageWindowTableViewAdapter.selectedMessage  = nil;
        [self.conversationMessageWindowTableViewAdapter deselectWithIndexPath:indexPath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // Make table view to update cells with animation (TODO can be removed when legacy cells are removed)
        [tableView beginUpdates];
        [tableView endUpdates];
    } else {
        if (tableView.indexPathForSelectedRow != nil) {
            [self.conversationMessageWindowTableViewAdapter deselectWithIndexPath:tableView.indexPathForSelectedRow];
        }
        self.conversationMessageWindowTableViewAdapter.selectedMessage = message;
        [self.conversationMessageWindowTableViewAdapter selectWithIndexPath:indexPath];
        selectedIndexPath = indexPath;
    }
    
    return selectedIndexPath;
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self prefetchNextMessagesForIndexPaths:indexPaths];
}

@end



@implementation ConversationContentViewController (ConversationCellDelegate)

- (void)wantsToPerformAction:(MessageAction)action forMessage:(id<ZMConversationMessage>)message
{
    UITableViewCell<SelectableView> *cell = [self cellForMessage:message];
    [self wantsToPerformAction:action forMessage:message cell:cell];
}

- (void)conversationCell:(UIView *)cell userTapped:(id<UserType>)user inView:(UIView *)view frame:(CGRect)frame
{
    if (!cell || !view) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(didTapOnUserAvatar:view:frame:)]) {
        [self.delegate didTapOnUserAvatar:user view:view frame:frame];
    }
}

- (void)conversationCellDidTapResendMessage:(ConversationCell *)cell
{
    [self.delegate conversationContentViewController:self didTriggerResendingMessage:cell.message];
}

- (void)conversationCell:(ConversationCell *)cell didSelectAction:(MessageAction)actionId forMessage:(id<ZMConversationMessage>)message
{
    [self wantsToPerformAction:actionId forMessage:message cell:cell];
}

- (void)conversationCell:(ConversationCell *)cell didSelectURL:(NSURL *)url
{
    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;

    [url open];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (BOOL)conversationCellShouldBecomeFirstResponderWhenShowingMenuForCell:(UIView *)cell;
{
    BOOL shouldBecomeFirstResponder = YES;
    if ([self.delegate respondsToSelector:@selector(conversationContentViewController:shouldBecomeFirstResponderWhenShowMenuFromCell:)]) {
        shouldBecomeFirstResponder = [self.delegate conversationContentViewController:self shouldBecomeFirstResponderWhenShowMenuFromCell:cell];
    }
    return shouldBecomeFirstResponder;
}

- (void)conversationCellDidRequestOpeningMessageDetails:(UIView *)cell messageDetails:(MessageDetailsViewController *)messageDetails
{
    [self.parentViewController presentViewController:messageDetails animated:YES completion:nil];
}

- (BOOL)conversationCellShouldStartDestructionTimer:(ConversationCell *)cell
{
    return self.onScreen;
}
    
- (void)conversationCell:(ConversationCell *)cell openGuestOptionsFromView:(UIView *)sourceView
{
    [self.delegate conversationContentViewController:self presentGuestOptionsFromView:sourceView];
}

- (void)conversationCell:(ConversationCell *)cell openParticipantsDetailsWithSelectedUsers:(NSArray<ZMUser *> *)selectedUsers fromView:(UIView *)sourceView
{
    [self.delegate conversationContentViewController:self presentParticipantsDetailsWithSelectedUsers:selectedUsers fromView:sourceView];
}

@end


@implementation ConversationContentViewController (EditMessages)

- (void)editLastMessage
{
    ZMMessage *lastEditableMessage = self.conversation.lastEditableMessage;
    if (lastEditableMessage != nil) {
        [self wantsToPerformAction:MessageActionEdit forMessage:lastEditableMessage];
    }
}

- (void)didFinishEditingMessage:(id<ZMConversationMessage>)message
{
    self.conversationMessageWindowTableViewAdapter.editingMessage = nil;
}

@end


@implementation ConversationContentViewController (MessageWindow)

- (void)expandMessageWindowUp
{
    [self.conversationMessageWindowTableViewAdapter expandMessageWindow];
}

- (void)prefetchNextMessagesForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    NSArray<NSIndexPath *> *sortedIndexPaths = [indexPaths sortedArrayUsingSelector:@selector(row)];

    NSIndexPath* latestIndexPath = sortedIndexPaths.lastObject;

    if (latestIndexPath.row + ConversationContentViewControllerMessagePrefetchDepth > (int)self.messageWindow.messages.count) {
        [self expandMessageWindowUp];
    }
}

- (void)messagesInsideWindow:(ZMConversationMessageWindow *)window didChange:(NSArray<MessageChangeInfo *> *)messageChangeInfos
{
    if (self.messagePresenter.waitingForFileDownload) {
        id<ZMConversationMessage> selectedMessage = self.conversationMessageWindowTableViewAdapter.selectedMessage;
        if (selectedMessage &&
            ([Message isVideoMessage:selectedMessage] ||
             [Message isAudioMessage:selectedMessage] ||
             [Message isFileTransferMessage:selectedMessage])
            && selectedMessage.fileMessageData.transferState == ZMFileTransferStateDownloaded) {
            if ([self isVisible]) {
                NSUInteger indexOfFileMessage = [[[self messageWindow] messages] indexOfObject:selectedMessage];
                
                BOOL __block expectedMessageUpdated = NO;
                [messageChangeInfos enumerateObjectsUsingBlock:^(MessageChangeInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.message isEqual:selectedMessage]) {
                        expectedMessageUpdated = YES;
                        *stop = YES;
                    }
                }];
                
                if (expectedMessageUpdated) {
                    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:indexOfFileMessage inSection:0];
                    
                    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
                    BOOL isVisibleCell = [indexes containsObjectMatchingWithBlock:^BOOL(NSIndexPath *obj) {
                        return (obj.row == cellIndexPath.row) && (obj.section == cellIndexPath.section);
                    }];
                    
                    if (isVisibleCell) {
                        [self.messagePresenter openFileMessage:selectedMessage targetView:[self.tableView cellForRowAtIndexPath:cellIndexPath]];
                    }
                }
            }
        }
    }
}

- (void)conversationWindowDidChange:(MessageWindowChangeInfo *)note
{
    [self updateHeaderHeight];

    // Clear selectedMessage if it is going to be deleted.
    if ([note.deletedObjects containsObject:self.conversationMessageWindowTableViewAdapter.selectedMessage]) {
        self.conversationMessageWindowTableViewAdapter.selectedMessage = nil;
    }
    
    if (note.insertedIndexes.count == 0) {
        return;
    }
    
    [self removeHighlightsAndMenu];
    
    if (note.insertedIndexes.firstIndex > 0) {
        // Update table header when all messages in the conversation are loaded
        [self updateTableViewHeaderView];
    }
    
    if (nil != self.expectedMessageToShow) {
        NSUInteger index = [self.messageWindow.messages indexOfObject:self.expectedMessageToShow];
        if (index != NSNotFound) {
            [self scrollToIndex:index completion:self.onMessageShown];
            self.onMessageShown = nil;
            self.expectedMessageToShow = nil;
        }
    }
    
}

@end
