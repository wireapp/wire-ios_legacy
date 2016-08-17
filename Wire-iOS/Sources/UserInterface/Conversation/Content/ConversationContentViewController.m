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
#import "CommonConnectionsView.h"
#import "UIView+MTAnimation.h"
#import "ConnectionStatusHeader.h"
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

// Cells
#import "TextMessageCell.h"
#import "PingCell.h"
#import "StopWatch.h"

#import "SketchViewController.h"
#import "AnalyticsTracker+Sketchpad.h"
#import "AnalyticsTracker+FileTransfer.h"

#import "Wire-Swift.h"


@interface AVPlayerViewControllerWithoutStatusBar : AVPlayerViewController
@end

@implementation AVPlayerViewControllerWithoutStatusBar

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end

@interface ConversationContentViewController (TableView) <UITableViewDelegate>

@end



@interface ConversationContentViewController (ConversationCellDelegate) <ConversationCellDelegate>

@end



@interface ConversationContentViewController (ZMTypingChangeObserver) <ZMTypingChangeObserver>

@end



@interface ConversationContentViewController () <FullscreenImageViewControllerDelegate, SketchViewControllerDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic) ConversationMessageWindowTableViewAdapter *conversationMessageWindowTableViewAdapter;
@property (nonatomic, strong) NSMutableDictionary *cellLayoutPropertiesCache;
@property (nonatomic, assign) BOOL wasScrolledToBottomAtStartOfUpdate;
@property (nonatomic) NSObject *activeMediaPlayerObserver;
@property (nonatomic) BOOL conversationLoadStopwatchFired;
@property (nonatomic) NSMutableDictionary *cachedRowHeights;
@property (nonatomic) BOOL wasFetchingMessages;
@property (nonatomic) BOOL hasDoneInitialLayout;
@property (nonatomic) id <ZMConversationMessageWindowObserverOpaqueToken> messageWindowObserverToken;
@property (nonatomic) BOOL waitingForFileDownload;
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;

@end



@implementation ConversationContentViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _conversation = conversation;
        self.cachedRowHeights = [NSMutableDictionary dictionary];
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
    
    self.activeMediaPlayerObserver = [KeyValueObserver observeObject:[AppDelegate sharedAppDelegate].mediaPlaybackManager
                                                             keyPath:@"activeMediaPlayer"
                                                              target:self
                                                            selector:@selector(activeMediaPlayerChanged:)
                                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [AppDelegate sharedAppDelegate].notificationWindowController.showLoadMessages = self.wasFetchingMessages;
    
    [self updateVisibleMessagesWindow];
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
    if ((self.conversation.conversationType == ZMConversationTypeConnection || self.conversation.conversationType == ZMConversationTypeOneOnOne) && self.conversation.firstActiveParticipantOtherThanSelf) {
        headerView = [[ConnectionStatusHeader alloc] initWithUser:self.conversation.firstActiveParticipantOtherThanSelf];
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
    CGSize fittingSize = CGSizeMake(self.tableView.self.bounds.size.width, 44);
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
            [self.conversation setVisibleWindowFromMessage:topVisibleMessage toMessage:bottomVisibleMessage];
        }];
    }
}

- (void)presentDetailsForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    id<ZMConversationMessage>message = [self.messageWindow.messages objectAtIndex:indexPath.row];
    BOOL isFile = [Message isFileTransferMessage:message],
        isImage = [Message isImageMessage:message],
        isLocation = [Message isLocationMessage:message];
    
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
    
    if (isFile && ![Message isAudioMessage:message]) {
        [self selectFileMessage:message atIndexPath:indexPath];
    }
    else if (isImage) {
        [self openImageMessage:message];
    } else if (isLocation) {
        [self openLocationMessage:message cell:cell];
    }
}

- (void)openLocationMessage:(id<ZMConversationMessage>)message cell:(UITableViewCell *)cell
{
    if (![Message isLocationMessage:message] || ![cell isKindOfClass:LocationMessageCell.class]) {
        return;
    }
    
    [(LocationMessageCell *)cell openInMaps];
}

- (void)selectFileMessage:(id<ZMConversationMessage>)message atIndexPath:(NSIndexPath *)indexPath {

    switch (message.fileMessageData.transferState) {
        case ZMFileTransferStateDownloaded:
        {
            [self openFileMessage:message atIndexPath:indexPath];
            self.waitingForFileDownload = NO;
        }
            break;
        case ZMFileTransferStateUploaded:
        case ZMFileTransferStateFailedDownload:
        {
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [message.fileMessageData requestFileDownload];
            }];
            
            self.waitingForFileDownload = YES;
            
            [self.analyticsTracker tagInitiatedFileDownloadWithSize:message.fileMessageData.size
                                                      fileExtension:[message.fileMessageData.filename pathExtension]];
        }
            break;
        default:
            
            break;
    }
}

- (void)openFileMessage:(id<ZMConversationMessage>)message atIndexPath:(NSIndexPath *)indexPath {
    if (message.fileMessageData.fileURL == nil || ! [message.fileMessageData.fileURL isFileURL] || message.fileMessageData.fileURL.path.length == 0) {
        NSAssert(0, @"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        DDLogError(@"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [message.fileMessageData requestFileDownload];
        }];
        return;
    }

    [self.analyticsTracker tagOpenedFileWithSize:message.fileMessageData.size
                                   fileExtension:[message.fileMessageData.filename pathExtension]];
    
    if (message.fileMessageData.isVideo) {
        AVPlayer *player = [[AVPlayer alloc] initWithURL:message.fileMessageData.fileURL];

        AVPlayerViewController *playerController = [[AVPlayerViewControllerWithoutStatusBar alloc] init];
        playerController.player = player;
        [self.parentViewController presentViewController:playerController animated:YES completion:^() {
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
            [player play];
            [Analytics.shared tagPlayedVideoMessage:CMTimeGetSeconds(player.currentItem.duration)];
        }];
    }
    else {
        [self openDocumentControllerForMessage:message atIndexPath:indexPath withPreview:YES];
    }
}

- (void)openDocumentControllerForMessage:(id<ZMConversationMessage>)message atIndexPath:(NSIndexPath *)indexPath withPreview:(BOOL)preview {
    if (message.fileMessageData.fileURL == nil || ! [message.fileMessageData.fileURL isFileURL] || message.fileMessageData.fileURL.path.length == 0) {
        NSAssert(0, @"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        DDLogError(@"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [message.fileMessageData requestFileDownload];
        }];
        return;
    }

    [self.view.window endEditing:YES];
    
    // Need to create temporary hardlink to make sure the UIDocumentInteractionController shows the correct filename
    NSError *error = nil;
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:message.fileMessageData.filename];
    [[NSFileManager defaultManager] linkItemAtPath:message.fileMessageData.fileURL.path toPath:tmpPath error:&error];
    if (nil != error) {
        DDLogError(@"Cannot symlink %@ to %@: %@", message.fileMessageData.fileURL.path, tmpPath, error);
        tmpPath =  message.fileMessageData.fileURL.path;
    }
    
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tmpPath]];
    self.documentInteractionController.delegate = self;
    if (!preview || ![self.documentInteractionController presentPreviewAnimated:YES]) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
        [self.documentInteractionController presentOptionsMenuFromRect:[self.view convertRect:targetView.bounds fromView:targetView]
                                                                inView:self.view
                                                              animated:YES];
    }
}

- (void)cleanupTemporaryFileLink {
    NSError *linkDeleteError = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.documentInteractionController.URL error:&linkDeleteError];
    if (linkDeleteError) {
        DDLogError(@"Cannot delete temporary link %@: %@", self.documentInteractionController.URL, linkDeleteError);
    }
}

- (void)openImageMessage:(id<ZMConversationMessage>)message {
    /// Don't open full screen images when there is an incoming call
    ZMVoiceChannel *activeVoiceChannel = [SessionObjectCache sharedCache].firstActiveVoiceChannel;
    if (IS_IPAD_LANDSCAPE_LAYOUT && activeVoiceChannel != nil && activeVoiceChannel.state == ZMVoiceChannelStateIncomingCall) {
        return;
    }
    
    if (! [Message isImageMessage:message]) {
        return;
    }
    
    if (message.imageMessageData == nil) {
        return;
    }
    
    FullscreenImageViewController *fullscreenImageViewController = [[FullscreenImageViewController alloc] initWithMessage:message];
    fullscreenImageViewController.delegate = self;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        fullscreenImageViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        fullscreenImageViewController.snapshotBackgroundView = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:YES];
    } else {
        fullscreenImageViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    fullscreenImageViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:fullscreenImageViewController animated:YES completion:nil];
    [Analytics shared].sessionSummary.imageContentsClicks++;
}

- (void)fullscreenImageViewController:(FullscreenImageViewController *)controller wantsEditImageMessage:(id<ZMConversationMessage>)message
{
    [controller dismissViewControllerAnimated:NO completion:nil];

    SketchViewController *viewController = [[SketchViewController alloc] init];
    viewController.sketchTitle = message.conversation.displayName;
    viewController.delegate = self;
    viewController.source = ConversationMediaSketchSourceImageFullView;
    
    ZMUser *lastSender = message.conversation.lastMessageSender;
    [self.parentViewController presentViewController:viewController animated:YES completion:^{
        [viewController.backgroundViewController setUser:lastSender animated:NO];
        viewController.canvasBackgroundImage = [[UIImage alloc] initWithData:message.imageMessageData.imageData];
    }];
}

- (void)sketchViewControllerDidCancel:(SketchViewController *)controller
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];

}

- (void)sketchViewController:(SketchViewController *)controller didSketchImage:(UIImage *)image
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    if (image) {
        NSData *imageData = UIImagePNGRepresentation(image);
        
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [self.conversation appendMessageWithImageData:imageData];
        } completionHandler:^{
            [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionSketch inConversation:self.conversation];
            [[Analytics shared] tagMediaSentPictureSourceSketchInConversation:self.conversation sketchSource:controller.source];
            [Analytics shared].sessionSummary.imagesSent++;
        }];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.parentViewController;
}

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{        
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
    });
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    [self cleanupTemporaryFileLink];
    self.documentInteractionController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [self cleanupTemporaryFileLink];
    self.documentInteractionController = nil;
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self cleanupTemporaryFileLink];
    self.documentInteractionController = nil;
}

#pragma mark - Custom UI, utilities

- (void)removeHighlightsAndMenu
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

- (UITableViewCell *)cellForMessage:(id<ZMConversationMessage>)message
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.messageWindow.messages indexOfObject:message] inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
    
    if (![Message isVideoMessage:message] &&
        ![Message isFileTransferMessage:message] &&
        ![Message isImageMessage:message] &&
        ![Message isLocationMessage:message] &&
        [message isEqual:self.conversationMessageWindowTableViewAdapter.selectedMessage]) {
        
        // If this cell is already selected, deselect it.
        self.conversationMessageWindowTableViewAdapter.selectedMessage  = nil;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
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
    [self presentDetailsForMessageAtIndexPath:indexPath];
    
    // Make table view to update cells with animation
    [tableView beginUpdates];
    [tableView endUpdates];
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

- (void)conversationCell:(ConversationCell *)cell resendMessageTapped:(ZMMessage *)message
{
    [self.delegate conversationContentViewController:self didTriggerResendingMessage:message];
}

- (void)conversationCell:(ConversationCell *)cell didSelectAction:(ConversationCellAction)actionId
{
    switch (actionId) {
        case ConversationCellActionCancel:
        {
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [cell.message.fileMessageData cancelTransfer];
                [self.analyticsTracker tagCancelledFileUploadWithSize:cell.message.fileMessageData.size
                                                        fileExtension:[cell.message.fileMessageData.filename pathExtension]];
            }];
        }
            break;
            
        case ConversationCellActionResend:
        {
            [[ZMUserSession sharedSession] enqueueChanges:^{
                [cell.message resend];
            }];
        }
            break;
        
        case ConversationCellActionDelete:
        {
            [self presentDeletionAlertControllerForMessage:cell.message];
        }
            break;
        case ConversationCellActionPresent:
        {
            self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;
            [self presentDetailsForMessageAtIndexPath:[self.tableView indexPathForCell:cell]];
        }
            break;
        case ConversationCellActionSave:
        {
            self.conversationMessageWindowTableViewAdapter.selectedMessage = cell.message;
            [self openDocumentControllerForMessage:cell.message atIndexPath:[self.tableView indexPathForCell:cell] withPreview:NO];
        }
            break;
        case ConversationCellActionEdit:
        {
            self.conversationMessageWindowTableViewAdapter.editingMessage = cell.message;
            [self.delegate conversationContentViewController:self didTriggerEditingMessage:cell.message];
        }
            break;
    }
}

- (void)conversationCell:(ConversationCell *)cell willOpenMenuForCellType:(MessageType)messageType;
{
    [ConversationInputBarViewController endEditingMessage];
}

- (void)conversationCell:(ConversationCell *)cell didOpenMenuForCellType:(MessageType)messageType;
{
    ConversationType conversationType = self.conversation.conversationType == ZMConversationTypeGroup ? ConversationTypeGroup : ConversationTypeOneToOne;
    
    [[Analytics shared] tagSelectedMessage:SelectionTypeSingle
                          conversationType:conversationType
                               messageType:messageType];
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

- (BOOL)viewControllerIsVisible
{
    BOOL isInWindow = self.view.window != nil;
    BOOL notCoveredModally = self.presentedViewController == nil;
    BOOL viewIsVisible = CGRectIntersectsRect([self.view convertRect:self.view.bounds toView:nil], [[UIScreen mainScreen] bounds]);
    
    return isInWindow && notCoveredModally && viewIsVisible;
}

- (void)handleMessageUpdateForFileUpload:(NSArray *)messageChangeInfos selectedMessage:(ZMMessage *)selectedMessage
{
    if ([self viewControllerIsVisible]) {
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
                [self openFileMessage:selectedMessage atIndexPath:cellIndexPath];
            }
            self.waitingForFileDownload = NO;
        }
    }
}

- (void)messagesInsideWindowDidChange:(NSArray *)messageChangeInfos
{
    if (self.waitingForFileDownload) {
        ZMMessage *selectedMessage = self.conversationMessageWindowTableViewAdapter.selectedMessage;
        if (([Message isVideoMessage:selectedMessage] ||
             [Message isAudioMessage:selectedMessage] ||
             [Message isFileTransferMessage:selectedMessage]) && selectedMessage.fileMessageData.transferState == ZMFileTransferStateDownloaded) {
            [self handleMessageUpdateForFileUpload:messageChangeInfos selectedMessage:selectedMessage];
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
}

@end
