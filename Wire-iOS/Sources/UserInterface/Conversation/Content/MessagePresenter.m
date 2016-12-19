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

#import "MessagePresenter.h"
#import "zmessaging+iOS.h"
#import "Message.h"
#import "Analytics.h"
#import "AnalyticsTracker.h"
#import "AnalyticsTracker+FileTransfer.h"
#import "FullscreenImageViewController.h"
#import "Wire-Swift.h"
#import "UIViewController+WR_Additions.h"

@import AVKit;
@import AVFoundation;


@interface AVPlayerViewControllerWithoutStatusBar : AVPlayerViewController
@end

@implementation AVPlayerViewControllerWithoutStatusBar

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end


@interface MessagePresenter (UIDocumentInteractionController) <UIDocumentInteractionControllerDelegate>
@end

@interface MessagePresenter ()
@property (nonatomic, readwrite) BOOL waitingForFileDownload;
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@end

@implementation MessagePresenter

- (void)openMessage:(id<ZMConversationMessage>)message targetView:(UIView *)targetView
{
    self.waitingForFileDownload = NO;
    [self.modalTargetController.view.window endEditing:YES];

    if ([Message isLocationMessage:message]) {
        [self openLocationMessage:message];
    }
    else if ([Message isFileTransferMessage:message]) {
        [self openFileMessage:message targetView:targetView];
    }
    else if ([Message isImageMessage:message]) {
        [self openImageMessage:message];
    }
}

- (void)openLocationMessage:(id<ZMConversationMessage>)message
{
    [Message openInMaps:message.locationMessageData];
}

- (void)openFileMessage:(id<ZMConversationMessage>)message targetView:(UIView *)targetView {
    
    if (message.fileMessageData.fileURL == nil || ! [message.fileMessageData.fileURL isFileURL] || message.fileMessageData.fileURL.path.length == 0) {
        NSAssert(0, @"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        DDLogError(@"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [message.fileMessageData requestFileDownload];
        }];
        return;
    }
    
    [message startSelfDestructionIfNeeded];
    
    [self.analyticsTracker tagOpenedFileWithSize:message.fileMessageData.size
                                   fileExtension:[message.fileMessageData.filename pathExtension]];
    
    if (message.fileMessageData.isVideo) {
        AVPlayer *player = [[AVPlayer alloc] initWithURL:message.fileMessageData.fileURL];
        
        AVPlayerViewController *playerController = [[AVPlayerViewControllerWithoutStatusBar alloc] init];
        playerController.player = player;
        [self.targetViewController presentViewController:playerController animated:YES completion:^() {
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
            [player play];
            [Analytics.shared tagPlayedVideoMessage:CMTimeGetSeconds(player.currentItem.duration)];
        }];
    }
    else {
        
        [self openDocumentControllerForMessage:message targetView:targetView withPreview:YES];
    }
}

- (void)openDocumentControllerForMessage:(id<ZMConversationMessage>)message targetView:(UIView *)targetView withPreview:(BOOL)preview {
    
    if (message.fileMessageData.fileURL == nil || ! [message.fileMessageData.fileURL isFileURL] || message.fileMessageData.fileURL.path.length == 0) {
        NSAssert(0, @"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        DDLogError(@"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        [[ZMUserSession sharedSession] enqueueChanges:^{
            [message.fileMessageData requestFileDownload];
        }];
        return;
    }
    
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
        
        [self.documentInteractionController presentOptionsMenuFromRect:[self.targetViewController.view convertRect:targetView.bounds fromView:targetView]
                                                                inView:self.targetViewController.view
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
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        fullscreenImageViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        fullscreenImageViewController.snapshotBackgroundView = [UIScreen.mainScreen snapshotViewAfterScreenUpdates:YES];
    } else {
        fullscreenImageViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    fullscreenImageViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self.modalTargetController presentViewController:fullscreenImageViewController animated:YES completion:nil];
    [Analytics shared].sessionSummary.imageContentsClicks++;
}

@end

@implementation MessagePresenter (UIDocumentInteractionController)


#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.modalTargetController;
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


@end
