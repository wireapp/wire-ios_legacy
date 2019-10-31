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
#import "MessagePresenter+Internal.h"
#import "WireSyncEngine+iOS.h"
#import "Analytics.h"
#import "Wire-Swift.h"
#import "UIViewController+WR_Additions.h"

@import AVKit;
@import AVFoundation;

static NSString* ZMLogTag ZM_UNUSED = @"UI";


@interface MessagePresenter (UIDocumentInteractionController) <UIDocumentInteractionControllerDelegate>
@end

@interface MessagePresenter ()
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@end

@implementation MessagePresenter

- (void)openDocumentControllerForMessage:(id<ZMConversationMessage>)message targetView:(UIView *)targetView withPreview:(BOOL)preview
{
    if (message.fileMessageData.fileURL == nil || ! [message.fileMessageData.fileURL isFileURL] || message.fileMessageData.fileURL.path.length == 0) {
        NSAssert(0, @"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
        ZMLogError(@"File URL is missing: %@ (%@)", message.fileMessageData.fileURL, message.fileMessageData);
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
        ZMLogError(@"Cannot symlink %@ to %@: %@", message.fileMessageData.fileURL.path, tmpPath, error); ///TODO: frozen after this
        tmpPath =  message.fileMessageData.fileURL.path;
    }
    
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tmpPath]];
    self.documentInteractionController.delegate = self;

    BOOL result = [self.documentInteractionController presentPreviewAnimated:YES];
    if (!preview || !result) {
        
        [self.documentInteractionController presentOptionsMenuFromRect:[self.targetViewController.view convertRect:targetView.bounds fromView:targetView]
                                                                inView:self.targetViewController.view
                                                              animated:YES];
    }
}

- (void)cleanupTemporaryFileLink
{
    NSError *linkDeleteError = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.documentInteractionController.URL error:&linkDeleteError];
    if (linkDeleteError) {
        ZMLogError(@"Cannot delete temporary link %@: %@", self.documentInteractionController.URL, linkDeleteError);
    }
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
