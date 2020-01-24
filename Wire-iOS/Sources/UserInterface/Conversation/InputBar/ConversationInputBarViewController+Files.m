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


@import MobileCoreServices;

@import WireCommonComponents;
@import ZipArchive;
#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Files.h"
#import "UIViewController+Errors.h"
#import "Analytics.h"
#import "Analytics.h"
#import "AVAsset+VideoConvert.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@implementation ConversationInputBarViewController (Files)

- (void)uploadItemAtURL:(NSURL *)itemURL
{
    NSString *itemPath = itemURL.path;
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (! fileExists) {
        ZMLogError(@"File not found for uploading: %@", itemURL);
        return;
    }
    
    if (isDirectory) {
        NSString *tmpPath = [[itemPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            ZMLogError(@"Cannot create folder at path %@: %@", tmpPath, error);
            return;
        }
        
        [[NSFileManager defaultManager] moveItemAtPath:itemPath
                                                toPath:[tmpPath stringByAppendingPathComponent:[itemPath lastPathComponent]]
                                                 error:&error];
        if (error != nil) {
            ZMLogError(@"Cannot move %@ to %@: %@", itemPath, tmpPath, error);
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            return;
        }
        
        NSString *archivePath = [itemPath stringByAppendingString:@".zip"];
        BOOL zipSucceded = [SSZipArchive createZipFileAtPath:archivePath withContentsOfDirectory:tmpPath];
        
        if (zipSucceded) {
            [self uploadFileAtURL:[NSURL fileURLWithPath:archivePath]];
        }
        else {
            ZMLogError(@"Cannot archive folder at path: %@", itemURL);
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&error];
        if (error != nil) {
            ZMLogError(@"Cannot delete folder at path %@: %@", tmpPath, error);
            return;
        }
    }
    else {
        [self uploadFileAtURL:itemURL];
    }
}

- (void)uploadFileAtURL:(NSURL *)url
{
    NSError *error = nil;
    NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
    
    dispatch_block_t completion = ^() {
        NSError *deleteError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&deleteError];
        
        if (deleteError != nil) {
            ZMLogError(@"Error: cannot unlink document: %@", deleteError);
        }
    };
    
    if (error != nil) {
        ZMLogError(@"Cannot get attributes on selected file: %@", error);
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        completion();
    }
    else {
        
        if ([attributes[NSFileSize] unsignedLongLongValue] > [[ZMUserSession sharedSession] maxUploadFileSize]) {
            // file exceeds maximum allowed upload size
            [self.parentViewController dismissViewControllerAnimated:NO completion:nil];
            
            NSString *maxSizeString = [NSByteCountFormatter stringFromByteCount:[[ZMUserSession sharedSession] maxUploadFileSize] countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"content.file.too_big", @""), maxSizeString];
            [self showAlertForMessage:errorMessage];
            
            completion();
        }
        else {
            [FileMetaDataGenerator metadataForFileAtURL:url UTI:url.UTI name:url.lastPathComponent completion:^(ZMFileMetadata * _Nonnull metadata) {
                [self.impactFeedbackGenerator prepare];
                [ZMUserSession.sharedSession performChanges:^{

                    id<ZMConversationMessage> message = [self.conversation appendMessageWithFileMetadata:metadata];
                    [self.impactFeedbackGenerator impactOccurred];
                    
                    if (message.fileMessageData.isVideo) {
                        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionVideoMessage
                                                     inConversation:self.conversation];
                    }
                    else if (message.fileMessageData.isAudio) {
                        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionAudioMessage
                                                     inConversation:self.conversation];
                    }
                    else {
                        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionFileTransfer
                                                     inConversation:self.conversation];
                    }
                    
                    completion();
                }];
            }];
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

@end
