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

#import "ConversationViewController.h"
#import "ConversationViewController+Private.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@import zmessaging;
@import WireExtensionComponents;
@import AVKit;

// model
#import "zmessaging+iOS.h"
#import "ZMVoiceChannel+Additions.h"
#import "Message.h"
#import "ConversationMessageWindowTableViewAdapter.h"

// ui
#import "FullscreenImageViewController.h"
#import "ZClientViewController.h"
#import "UIView+MTAnimation.h"
#import "GroupConversationHeader.h"
#import "NotificationWindowRootViewController.h"

// helpers
#import "WAZUIMagicIOS.h"
#import "Constants.h"

#import <PureLayout.h>
#import "UIView+Zeta.h"
#import "Analytics+iOS.h"
#import "UIViewController+Orientation.h"
#import "AppDelegate.h"
#import "MediaPlaybackManager.h"
#import "UIColor+WR_ColorScheme.h"
#import "MessagePresenter.h"
#import "UIViewController+WR_Additions.h"

// Cells
#import "TextMessageCell.h"
#import "PingCell.h"
#import "StopWatch.h"
#import "ImageMessageCell.h"

#import "AnalyticsTracker+Sketchpad.h"
#import "AnalyticsTracker+FileTransfer.h"

#import "Wire-Swift.h"


const static int ConversationContentViewControllerMessagePrefetchDepth = 10;


@interface ConversationContentViewController (TableView) <UITableViewDelegate, UITableViewDataSourcePrefetching>

@end



@interface ConversationContentViewController (ConversationCellDelegate) <ConversationCellDelegate>

@end



@interface ConversationContentViewController (ZMTypingChangeObserver) <ZMTypingChangeObserver>

@end



@interface ConversationContentViewController () <CanvasViewControllerDelegate>

@property (nonatomic) ConversationMessageWindowTableViewAdapter *conversationMessageWindowTableViewAdapter;
@property (nonatomic, strong) NSMutableDictionary *cellLayoutPropertiesCache;
@property (nonatomic, assign) BOOL wasScrolledToBottomAtStartOfUpdate;
@property (nonatomic) NSObject *activeMediaPlayerObserver;
@property (nonatomic) BOOL conversationLoadStopwatchFired;
@property (nonatomic) NSMutableDictionary *cachedRowHeights;
@property (nonatomic) BOOL wasFetchingMessages;
@property (nonatomic) BOOL hasDoneInitialLayout;
@property (nonatomic) id <ZMConversationMessageWindowObserverOpaqueToken> messageWindowObserverToken;
@property (nonatomic) BOOL onScreen;
@property (nonatomic) UserConnectionViewController *connectionViewController;
@property (nonatomic) MessagePresenter* messagePresenter;
@end



@implementation ConversationContentViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        self.cachedRowHeights = [NSMutableDictionary dictionary];
        self.messagePresenter = [[MessagePresenter alloc] init];
        self.messagePresenter.targetViewController = self;
        self.messagePresenter.modalTargetController = self.parentViewController;
        self.messagePresenter.analyticsTracker = self.analyticsTracker;
    }
    
    return self;
}

- (void)dealloc
{
    if (nil != self.tableView) {
        self.tableView.delegate = nil;
        self.tableView.dataSource = nil;
    }
    
    if (self.messageWindowObserverToken != nil) {
        [self.messageWindow removeConversationWindowObserverToken:self.messageWindowObserverToken];
    }
}

- (void)loadView
{
    self.tableView = [[UpsideDownTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.view = self.tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.messageWindow = [self.conversation conversationWindowWithSize:30];
    self.conversationMessageWindowTableViewAdapter =
    [[ConversationMessageWindowTableViewAdapter alloc] initWithTableView:self.tableView
                                                           messageWindow:self.messageWindow];
    self.conversationMessageWindowTableViewAdapter.analyticsTracker = self.analyticsTracker;
    self.conversationMessageWindowTableViewAdapter.conversationCellDelegate = self;
    
    self.messageWindowObserverToken = [self.messageWindow addConversationWindowObserver:self];
    
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
        self.tableView.backgroundColor = self.view.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.onScreen = YES;
    
    self.activeMediaPlayerObserver = [KeyValueObserver observeObject:[AppDelegate sharedAppDelegate].mediaPlaybackManager
                                                             keyPath:@"activeMediaPlayer"
                                                              target:self
                                                            selector:@selector(activeMediaPlayerChanged:)

                                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];

    for (ConversationCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:ConversationCell.class]) {
            [cell willDisplayInTableView];
        }
    }
    
    self.messagePresenter.modalTargetController = self.parentViewController;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [AppDelegate sharedAppDelegate].notificationWindowController.showLoadMessages = self.wasFetchingMessages;
    
    [self updateVisibleMessagesWindow];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.onScreen = NO;
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (! self.hasDoneInitialLayout) {
        self.hasDoneInitialLayout = YES;
        [self updateTableViewHeaderView];
        if (self.conversationMessageWindowTableViewAdapter.lastUnreadMessage != nil) {
            [self scrollToMessage:self.conversationMessageWindowTableViewAdapter.lastUnreadMessage animated:NO];
        }
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

- (void)didReceiveMemoryWarning
{
    DDLogWarn(@"Received system memory warning.");
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
        headerView.layoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.system_message.left_margin"],
                                                    0, [WAZUIMagic floatForIdentifier:@"content.system_message.right_margin"]);
        [self setConversationHeaderView:headerView];
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)setConversationHeaderView:(UIView *)headerView
{
    CGSize fittingSize = CGSizeMake(self.tableView.bounds.size.width, self.tableView.bounds.size.height - 20);
    CGSize requiredSize = [headerView systemLayoutSizeFittingSize:fittingSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultLow];
    headerView.frame = CGRectMake(0, 0, requiredSize.width, requiredSize.height);
    self.tableView.tableHeaderView = headerView;
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

- (void)setWasFetchingMessages:(BOOL)wasFetchingMessages
{
    _wasFetchingMessages = wasFetchingMessages;
    [AppDelegate sharedAppDelegate].notificationWindowController.showLoadMessages = _wasFetchingMessages;
}

#pragma mark - Actions

- (void)wantsToPerformAction:(MessageAction)actionId forMessage:(id<ZMConversationMessage>)message cell:(ConversationCell *)cell
{
    switch (actionId) {
        case MessageActionCancel:
        {
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [cell.message.fileMessageData cancelTransfer];
                [self.analyticsTracker tagCancelledFileUploadWithSize:cell.message.fileMessageData.size
                                                        fileExtension:[cell.message.fileMessageData.filename pathExtension]];
            }];
        }
            break;
            
        case MessageActionResend:
        {
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [cell.message resend];
            }];
        }
            break;
            
        case MessageActionDelete:
        {
            [self presentDeletionAlertControllerForMessage:cell.message completion:^{
                cell.beingEdited = NO;
            }];
        }
            break;
        case MessageActionPresent:
        {
            self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;
            [self presentDetailsForMessageAtIndexPath:[self.tableView indexPathForCell:cell]];
        }
            break;
        case MessageActionSave:
        {
            if ([Message isImageMessage:message]) {
                [self saveImageFromMessage:message cell:(ImageMessageCell *)cell];
            } else {
                self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;
                
                UIView *targetView = nil;
                
                if ([cell isKindOfClass:[FileTransferCell class]]) {
                    FileTransferCell *fileCell = (FileTransferCell *)cell;
                    targetView = fileCell.actionButton;
                }
                else if ([cell isKindOfClass:[AudioMessageCell class]]) {
                    AudioMessageCell *audioCell = (AudioMessageCell *)cell;
                    targetView = audioCell.contentView;
                }
                else {
                    targetView = cell;
                }
                
                [self.messagePresenter openDocumentControllerForMessage:cell.message targetView:targetView withPreview:NO];
            }
        }
            break;
        case MessageActionEdit:
        {
            self.conversationMessageWindowTableViewAdapter.editingMessage = cell.message;
            [self.delegate conversationContentViewController:self didTriggerEditingMessage:cell.message];
        }
            break;
        case MessageActionSketchDraw:
        {
            [self openSketchForMessage:cell.message inEditMode:CanvasViewControllerEditModeDraw];
        }
            break;
        case MessageActionSketchEmoji:
        {
            [self openSketchForMessage:cell.message inEditMode:CanvasViewControllerEditModeEmoji];
        }
            break;
        case MessageActionSketchText:
        {
            // Not implemented yet
        }
            break;
        case MessageActionLike:
        {
            BOOL liked = ![Message isLikedMessage:cell.message];
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [Message setLikedMessage:cell.message liked:liked];
                
                if (liked) {
                    // Deselect if necessary to show list of likers
                    if (self.conversationMessageWindowTableViewAdapter.selectedMessage == cell.message) {
                        [self tableView:self.tableView willSelectRowAtIndexPath:indexPath];
                    }
                } else {
                    // Select if necessary to prevent message from collapsing
                    if (self.conversationMessageWindowTableViewAdapter.selectedMessage != cell.message && ![Message hasReactions:cell.message]) {
                        [self tableView:self.tableView willSelectRowAtIndexPath:indexPath];
                        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                }
            }];
        }
            break;
        case MessageActionForward:
        {
            [self showForwardForMessage:cell.message fromCell:cell];
        }
            
            break;
        case MessageActionShowInConversation:
            // Not supported from cell
        case MessageActionCopy:
        {
            [[Analytics shared] tagOpenedMessageAction:MessageActionTypeCopy];
            [[Analytics shared] tagMessageCopy];
            
            NSData *imageData = cell.message.imageMessageData.imageData;
            [[UIPasteboard generalPasteboard] setMediaAsset:[[UIImage alloc] initWithData:imageData]];
        }
            break;
    }
}

- (void)addContacts:(id)sender
{
    [self.delegate conversationContentViewController:self didTriggerAddContactsButton:sender];
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

    NSIndexPath *topVisibleIndexPath = indexPathsForVisibleRows.firstObject;
    NSIndexPath *bottomVisibleIndexPath = indexPathsForVisibleRows.lastObject;
    
    if (topVisibleIndexPath && bottomVisibleIndexPath) {
        id<ZMConversationMessage>topVisibleMessage = [self.messageWindow.messages objectAtIndex:topVisibleIndexPath.row];
        id<ZMConversationMessage>bottomVisibleMessage = [self.messageWindow.messages objectAtIndex:bottomVisibleIndexPath.row];
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [self.conversation setVisibleWindowFromMessage:(ZMMessage *)topVisibleMessage toMessage:(ZMMessage *)bottomVisibleMessage];
        }];
    }
}

- (void)presentDetailsForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    id<ZMConversationMessage>message = [self.messageWindow.messages objectAtIndex:indexPath.row];
    BOOL isFile = [Message isFileTransferMessage:message];
    BOOL isImage = [Message isImageMessage:message];
    BOOL isLocation = [Message isLocationMessage:message];
    
    if (! isFile && ! isImage && ! isLocation) {
        return;
    }
    
    UITableViewCell *cell = [self cellForMessage:message];
    
    // If the user tapped on a file or image and the menu controller is currently visible,
    // we do not want to show the detail but instead hide the menu controller first.
    if ([cell isKindOfClass:ConversationCell.class] && [(ConversationCell *)cell showsMenu]) {
        [self removeHighlightsAndMenu];
        return;
    }
    
    [self.messagePresenter openMessage:message targetView:cell actionResponder:self];
}

- (void)saveImageFromMessage:(id<ZMConversationMessage>)message cell:(ImageMessageCell *)cell
{
    if (cell == nil) {
        NSData *imageData = message.imageMessageData.imageData;
        SavableImage *savableImage = [[SavableImage alloc] initWithData:imageData orientation:UIImageOrientationUp];
        [savableImage saveToLibraryWithCompletion:nil];
    }
    else {
        [cell.savableImage saveToLibraryWithCompletion:^{
            if (nil != self.view.window) {
                UIView *snapshot = [cell.fullImageView snapshotViewAfterScreenUpdates:YES];
                snapshot.translatesAutoresizingMaskIntoConstraints = YES;
                CGRect sourceRect = [self.view convertRect:cell.fullImageView.frame fromView:cell.fullImageView.superview];
                [self.delegate conversationContentViewController:self performImageSaveAnimation:snapshot sourceRect:sourceRect];
            }
        }];
    }
}

- (void)openSketchForMessage:(id<ZMConversationMessage>)message inEditMode:(CanvasViewControllerEditMode)editMode
{
    CanvasViewController *canvasViewController = [[CanvasViewController alloc] init];
    canvasViewController.sketchImage = [UIImage imageWithData:message.imageMessageData.imageData];
    canvasViewController.delegate = self;
    canvasViewController.title = message.conversation.displayName.uppercaseString;
    [canvasViewController selectWithEditMode:editMode animated:NO];
    
    [self presentViewController:canvasViewController.wrapInNavigationController animated:YES completion:nil];
}

- (void)canvasViewController:(CanvasViewController *)canvasViewController didExportImage:(UIImage *)image
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    if (image) {
        NSData *imageData = UIImagePNGRepresentation(image);
        
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [self.conversation appendMessageWithImageData:imageData];
        } completionHandler:^{
            [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionSketch inConversation:self.conversation];
            [[Analytics shared] tagMediaSentPictureSourceSketchInConversation:self.conversation sketchSource:ConversationMediaSketchSourceImageFullView];
            [Analytics shared].sessionSummary.imagesSent++;
        }];
    }
}

#pragma mark - Custom UI, utilities

- (void)removeHighlightsAndMenu
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (ConversationCell *)cellForMessage:(id<ZMConversationMessage>)message
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.messageWindow.messages indexOfObject:message] inSection:0];
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
    MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
    id<ZMConversationMessage>mediaPlayingMessage = mediaPlaybackManager.activeMediaPlayer.sourceMessage;
    
    if (mediaPlayingMessage && [mediaPlayingMessage.conversation isEqual:self.conversation] && ! [self displaysMessage:mediaPlayingMessage]) {
        [self.delegate conversationContentViewController:self didEndDisplayingActiveMediaPlayerForMessage:nil];
    } else {
        [self.delegate conversationContentViewController:self willDisplayActiveMediaPlayerForMessage:nil];
    }
}

@end



@implementation ConversationContentViewController (TableView)

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[TextMessageCell class]] || [cell isKindOfClass:[AudioMessageCell class]]) {
        ConversationCell *messageCell = (ConversationCell *)cell;
        MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
        
        if (mediaPlaybackManager.activeMediaPlayer != nil && mediaPlaybackManager.activeMediaPlayer.sourceMessage == messageCell.message) {
            [self.delegate conversationContentViewController:self willDisplayActiveMediaPlayerForMessage:messageCell.message];
        }
    }
    
    ConversationCell *conversationCell = nil;
    if ([cell isKindOfClass:ConversationCell.class]) {
        conversationCell = (ConversationCell *)cell;
    }
    
    if ([Message isKnockMessage:conversationCell.message]) {
        [self updatePingCellAppearance:(PingCell *)conversationCell];
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
    if ([cell isKindOfClass:[TextMessageCell class]] || [cell isKindOfClass:[AudioMessageCell class]]) {
        ConversationCell *messageCell = (ConversationCell *)cell;
        MediaPlaybackManager *mediaPlaybackManager = [AppDelegate sharedAppDelegate].mediaPlaybackManager;
        if (mediaPlaybackManager.activeMediaPlayer != nil && mediaPlaybackManager.activeMediaPlayer.sourceMessage == messageCell.message) {
            [self.delegate conversationContentViewController:self didEndDisplayingActiveMediaPlayerForMessage:messageCell.message];
        }
    }
    
    ConversationCell *conversationCell = nil;
    if ([cell isKindOfClass:ConversationCell.class]) {
        conversationCell = (ConversationCell *)cell;
    }
    
    [conversationCell didEndDisplayingInTableView];
    
    [self.cachedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];
}

- (void)updatePingCellAppearance:(PingCell *)pingCell
{
    // determine if we should start animating a ping cell
    // Unfortunate that this can't be inside the cell itself
    BOOL isMessageOfCellLastMessageInConversation = [self.messageWindow.messages.firstObject isEqual:pingCell.message];
    
    NSComparisonResult comparisonResult = [pingCell.message.serverTimestamp compare:self.conversation.lastReadMessage.serverTimestamp];
    BOOL isMessageOlderThanLastReadMessage =  (comparisonResult != NSOrderedAscending);
    
    if (isMessageOfCellLastMessageInConversation
        && [Message isKnockMessage:pingCell.message]
        && isMessageOlderThanLastReadMessage ) {
        [pingCell startPingAnimation];
    }
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
    ZMMessage *message = [self.messageWindow.messages objectAtIndex:indexPath.row];
    NSIndexPath *selectedIndexPath = nil;
    
    if ([message isEqual:self.conversationMessageWindowTableViewAdapter.selectedMessage]) {
        
        // If this cell is already selected, deselect it.
        self.conversationMessageWindowTableViewAdapter.selectedMessage  = nil;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // Make table view to update cells with animation
        [tableView beginUpdates];
        [tableView endUpdates];
    } else {
        self.conversationMessageWindowTableViewAdapter.selectedMessage = message;
        selectedIndexPath = indexPath;
    }
    
    return selectedIndexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // Make table view to update cells with animation
    [tableView beginUpdates];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self prefetchNextMessagesForIndexPaths:indexPaths];
}

@end



@implementation ConversationContentViewController (ConversationCellDelegate)

- (void)conversationCell:(ConversationCell *)cell userTapped:(ZMUser *)user inView:(UIView *)view
{
    if (! cell || !view) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(didTapOnUserAvatar:view:)]) {
        [self.delegate didTapOnUserAvatar:user view:view];
    }
}

- (void)conversationCellDidTapResendMessage:(ConversationCell *)cell
{
    [self.delegate conversationContentViewController:self didTriggerResendingMessage:cell.message];
}

- (void)conversationCell:(ConversationCell *)cell didSelectAction:(MessageAction)actionId
{
    [self wantsToPerformAction:actionId forMessage:cell.message cell:cell];
}

- (void)conversationCell:(ConversationCell *)cell didSelectURL:(NSURL *)url
{
    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;

    [url open];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (BOOL)conversationCell:(ConversationCell *)cell shouldBecomeFirstResponderWhenShowMenuWithCellType:(MessageType)messageType;
{
    BOOL shouldBecomeFirstResponder = YES;
    if ([self.delegate respondsToSelector:@selector(conversationContentViewController:shouldBecomeFirstResponderWhenShowMenuFromCell:)]) {
        shouldBecomeFirstResponder = [self.delegate conversationContentViewController:self shouldBecomeFirstResponderWhenShowMenuFromCell:cell];
    }
    [ConversationInputBarViewController endEditingMessage];
    return shouldBecomeFirstResponder;
}

- (void)conversationCell:(ConversationCell *)cell didOpenMenuForCellType:(MessageType)messageType;
{
    ConversationType conversationType = self.conversation.conversationType == ZMConversationTypeGroup ? ConversationTypeGroup : ConversationTypeOneToOne;
    
    [[Analytics shared] tagSelectedMessage:SelectionTypeSingle
                          conversationType:conversationType
                               messageType:messageType];
}

- (void)conversationCellDidTapOpenLikers:(ConversationCell *)cell
{
    if ([Message hasLikers:cell.message]) {
        ReactionsListViewController *reactionsListController = [[ReactionsListViewController alloc] initWithMessage:cell.message showsStatusBar:!IS_IPAD];
        [self.parentViewController presentViewController:reactionsListController animated:YES completion:nil];
    }
}

- (BOOL)conversationCellShouldStartDestructionTimer:(ConversationCell *)cell
{
    return self.onScreen;
}

@end


@implementation ConversationContentViewController (EditMessages)

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
    
    for (NSIndexPath *upcomingIndexPath in indexPaths) {
        if (upcomingIndexPath.row < (int)self.messageWindow.messages.count) {
            id<ZMConversationMessage> message = [self.messageWindow.messages objectAtIndex:upcomingIndexPath.row];
            if ([Message canBePrefetched:message]) {
                [message requestImageDownload];
            }
        }
    }
}

- (void)messagesInsideWindowDidChange:(NSArray *)messageChangeInfos
{
    if (self.messagePresenter.waitingForFileDownload) {
        id<ZMConversationMessage> selectedMessage = self.conversationMessageWindowTableViewAdapter.selectedMessage;
        if (([Message isVideoMessage:selectedMessage] ||
             [Message isAudioMessage:selectedMessage] ||
             [Message isFileTransferMessage:selectedMessage]) && selectedMessage.fileMessageData.transferState == ZMFileTransferStateDownloaded) {
            if ([self wr_isVisible]) {
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

@implementation ConversationContentViewController (MessageActionResponder)

- (BOOL)canPerformAction:(MessageAction)action forMessage:(id<ZMConversationMessage>)message
{
    if ([Message isImageMessage:message]) {
        
        switch (action) {
            case MessageActionForward:
            case MessageActionSave:
            case MessageActionCopy:
                
                return YES;
                break;
                
            default:
                break;
        }
    }
    
    return NO;
}

- (void)wantsToPerformAction:(MessageAction)action forMessage:(id<ZMConversationMessage>)message
{
    ConversationCell *cell = [self cellForMessage:message];
    
    [self wantsToPerformAction:action forMessage:message cell:cell];
}

@end
