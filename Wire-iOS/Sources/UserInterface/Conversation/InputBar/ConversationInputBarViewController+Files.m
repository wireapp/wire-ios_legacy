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
@import WireExtensionComponents;
@import ZipArchive;
#import "ConversationInputBarViewController.h"
#import "ConversationInputBarViewController+Files.h"
#import "UIViewController+Errors.h"
#import "Analytics.h"
#import "Analytics+iOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "AVAsset+VideoConvert.h"
#import "Wire-Swift.h"

const static unsigned long long ConversationUploadMaxFileSize = 25 * 1024 * 1024 - 32; // 25 megabytes - 32 bytes for IV and padding
const NSTimeInterval ConversationUploadMaxVideoDuration = 4.0f * 60.0f; // 4 minutes

@implementation ConversationInputBarViewController (Files)

- (void)docUploadPressed:(UIButton *)sender
{
    [Analytics.shared tagMediaAction:ConversationMediaActionFileTransfer inConversation:self.conversation];
    
    self.mode = ConversationInputBarViewControllerModeTextInput;
    [self.inputBar.textView resignFirstResponder];
    
    UIDocumentMenuViewController *docController = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeItem]
                                                                                                       inMode:UIDocumentPickerModeImport];
    docController.modalPresentationStyle = UIModalPresentationPopover;
    docController.delegate = self;
    
#if (TARGET_OS_SIMULATOR)
    [docController addOptionWithTitle:@"CountryCodes.plist" image:nil order:UIDocumentMenuOrderFirst handler:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            NSURL *sourceLocation = [[NSBundle bundleForClass:self.class] URLForResource:@"CountryCodes" withExtension:@"plist"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = paths.firstObject;
            
            
            NSString *destLocationString = [basePath stringByAppendingPathComponent:sourceLocation.lastPathComponent];
            NSURL *destLocation = [NSURL fileURLWithPath:destLocationString];
            
            [[NSFileManager defaultManager] copyItemAtURL:sourceLocation toURL:destLocation error:nil];
            [self uploadFileAtURL:destLocation];
        }];
    }];
    [docController addOptionWithTitle:@"group-icon@3x.png" image:nil order:UIDocumentMenuOrderFirst handler:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            NSURL *sourceLocation = [[NSBundle bundleForClass:self.class] URLForResource:@"group-icon@3x" withExtension:@"png"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = paths.firstObject;
            
            
            NSString *destLocationString = [basePath stringByAppendingPathComponent:sourceLocation.lastPathComponent];
            NSURL *destLocation = [NSURL fileURLWithPath:destLocationString];
            
            [[NSFileManager defaultManager] copyItemAtURL:sourceLocation toURL:destLocation error:nil];
            [self uploadFileAtURL:destLocation];
        }];
    }];
    [docController addOptionWithTitle:@"Big file" image:nil order:UIDocumentMenuOrderFirst handler:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = paths.firstObject;
            NSString *destLocationString = [basePath stringByAppendingPathComponent:@"BigFile.bin"];
            NSURL *destLocation = [NSURL fileURLWithPath:destLocationString];
            
            NSData *randomData = [NSData secureRandomDataOfLength:ConversationUploadMaxFileSize + 1];
            [randomData writeToURL:destLocation atomically:YES];
            
            [self uploadFileAtURL:destLocation];
        }];
    }];
    [docController addOptionWithTitle:@"20 MB file" image:nil order:UIDocumentMenuOrderFirst handler:^{
        [[ZMUserSession sharedSession] enqueueChanges:^{
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = paths.firstObject;
            NSString *destLocationString = [basePath stringByAppendingPathComponent:@"20MBFile.bin"];
            NSURL *destLocation = [NSURL fileURLWithPath:destLocationString];
            
            NSData *randomData = [NSData secureRandomDataOfLength:20*1024*1024];
            [randomData writeToURL:destLocation atomically:YES];
            
            [self uploadFileAtURL:destLocation];
        }];
    }];
#endif
    [docController addOptionWithTitle:NSLocalizedString(@"content.file.upload_video", @"")
                                image:[UIImage imageForIcon:ZetaIconTypeMovie iconSize:ZetaIconSizeMedium color:[UIColor darkGrayColor]]
                                order:UIDocumentMenuOrderFirst
                              handler:^{
                                  [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary mediaTypes:@[(id)kUTTypeMovie] allowsEditing:true];
                              }];
    
    [docController addOptionWithTitle:NSLocalizedString(@"content.file.take_video", @"")
                                image:[UIImage imageForIcon:ZetaIconTypeCameraShutter iconSize:ZetaIconSizeMedium color:[UIColor darkGrayColor]]
                                order:UIDocumentMenuOrderFirst
                              handler:^{
                                  [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera mediaTypes:@[(id)kUTTypeMovie] allowsEditing:false];
                              }];
    
    UIPopoverPresentationController* popover = docController.popoverPresentationController;
    popover.delegate = self;
    popover.sourceView = sender.superview;
    popover.sourceRect = sender.frame;
    [self.parentViewController presentViewController:docController animated:YES completion:^() {
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
    }];
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType mediaTypes:(NSArray *)mediaTypes allowsEditing:(BOOL)allowsEditing
{
    if (! [UIImagePickerController isSourceTypeAvailable:sourceType]) {
#if (TARGET_OS_SIMULATOR)
        NSString *testFilePath = @"/var/tmp/video.mp4";
        if ([[NSFileManager defaultManager] fileExistsAtPath:testFilePath]) {
            [self uploadFileAtURL:[NSURL fileURLWithPath:testFilePath]];
        }
#endif
        return; // Don't crash on Simulator
    }

    dispatch_block_t presentController = ^() {
        UIImagePickerController* pickerController = [[UIImagePickerController alloc] init];
        pickerController.sourceType = sourceType;
        pickerController.delegate = self;
        pickerController.allowsEditing = allowsEditing;
        pickerController.mediaTypes = mediaTypes;
        pickerController.videoMaximumDuration = ConversationUploadMaxVideoDuration;
        pickerController.transitioningDelegate = [FastTransitioningDelegate sharedDelegate];
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            switch ([Settings sharedSettings].preferredCamera) {
                case CameraControllerCameraBack:
                    pickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                    break;
                case CameraControllerCameraFront:
                    pickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                    break;
            }
        }
        [self.parentViewController presentViewController:pickerController animated:YES completion:nil];
    };
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self executeWithVideoPermissions:presentController];
    }
    else {
        presentController();
    }
}

- (void)executeWithVideoPermissions:(dispatch_block_t)toExecute {
    [UIApplication wr_requestOrWarnAboutVideoAccess:^(BOOL granted) {
        if (granted) {
            [UIApplication wr_requestOrWarnAboutMicrophoneAccess:^(BOOL granted) {
                if (granted) {
                    toExecute();
                }
            }];
        }
    }];
}

- (void)uploadItemAtURL:(NSURL *)itemURL
{
    NSString *itemPath = itemURL.path;
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (! fileExists) {
        DDLogError(@"File not found for uploading: %@", itemURL);
        return;
    }
    
    if (isDirectory) {
        NSString *tmpPath = [[itemPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            DDLogError(@"Cannot create folder at path %@: %@", tmpPath, error);
            return;
        }
        
        [[NSFileManager defaultManager] moveItemAtPath:itemPath
                                                toPath:[tmpPath stringByAppendingPathComponent:[itemPath lastPathComponent]]
                                                 error:&error];
        if (error != nil) {
            DDLogError(@"Cannot move %@ to %@: %@", itemPath, tmpPath, error);
            [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
            return;
        }
        
        NSString *archivePath = [itemPath stringByAppendingString:@".zip"];
        BOOL zipSucceded = [SSZipArchive createZipFileAtPath:archivePath withContentsOfDirectory:tmpPath];
        
        if (zipSucceded) {
            [self uploadFileAtURL:[NSURL fileURLWithPath:archivePath]];
        }
        else {
            DDLogError(@"Cannot archive folder at path: %@", itemURL);
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&error];
        if (error != nil) {
            DDLogError(@"Cannot delete folder at path %@: %@", tmpPath, error);
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
            DDLogError(@"Error: cannot unlink document: %@", deleteError);
        }
    };
    
    if (error != nil) {
        DDLogError(@"Cannot get attributes on selected file: %@", error);
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        completion();
    }
    else {
        
        if ([attributes[NSFileSize] unsignedLongLongValue] > ConversationUploadMaxFileSize) {
            // file exceeds maximum allowed upload size
            [self.parentViewController dismissViewControllerAnimated:NO completion:nil];
            
            NSString *maxSizeString = [NSByteCountFormatter stringFromByteCount:ConversationUploadMaxFileSize countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"content.file.too_big", @""), maxSizeString];
            [self showAlertForMessage:errorMessage];
            
            [self.analyticsTracker tagCannotUploadFileSizeExceedsWithSize:[attributes[NSFileSize] unsignedLongLongValue]
                                                            fileExtension:[url pathExtension]];
            completion();
        }
        else {
            [self.analyticsTracker tagInitiatedFileUploadWithSize:[attributes[NSFileSize] unsignedLongLongValue]
                                                    fileExtension:[url pathExtension]
                                                          context:FileTransferContextApp];
            
            [FileMetaDataGenerator metadataForFileAtURL:url UTI:url.UTI name:url.lastPathComponent completion:^(ZMFileMetadata * _Nonnull metadata) {
                [ZMUserSession.sharedSession performChanges:^{

                    id<ZMConversationMessage> message = [self.conversation appendMessageWithFileMetadata:metadata];
                    
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // Workaround http://stackoverflow.com/questions/26651355/
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    NSString* mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqual:(id)kUTTypeMovie]) {
        NSURL* videoURL = info[UIImagePickerControllerMediaURL];
        
        if (videoURL == nil) {
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
            DDLogError(@"Video not provided form %@: info %@", picker, info);
            return;
        }
        
        NSURL *videoTempURL = [NSURL fileURLWithPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString filenameForSelfUser]] stringByAppendingPathExtension:videoURL.pathExtension]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:videoTempURL.path]) {
            NSError *deleteError = nil;
            [[NSFileManager defaultManager] removeItemAtURL:videoTempURL error:&deleteError];
            if (deleteError != nil) {
                DDLogError(@"Cannot delete old tmp video at %@: %@", videoTempURL, deleteError);
            }
        }
        
        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtURL:videoURL toURL:videoTempURL error:&moveError];
        if (moveError != nil) {
            DDLogError(@"Cannot move video from %@ to %@: %@", videoURL, videoTempURL, moveError);
        }
        
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoTempURL.path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoTempURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
        }
        
        picker.showLoadingView = YES;
        [AVAsset wr_convertVideoAtURL:videoTempURL toUploadFormatWithCompletion:^(NSURL *resultURL, AVAsset *asset, NSError *error) {
            if (error == nil && resultURL != nil) {
                [[Analytics shared] tagSentVideoMessageInConversation:self.conversation
                                                              context:self.videoSendContext
                                                             duration:CMTimeGetSeconds(asset.duration)];
                [self uploadFileAtURL:resultURL];
            }
            
            [self.parentViewController dismissViewControllerAnimated:YES completion:^() {
                picker.showLoadingView = NO;
            }];
        }];
    }
    else if ([mediaType isEqual:(id)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerEditedImage];
        
        if (image == nil) {
            image = info[UIImagePickerControllerOriginalImage];
        }
        
        if (image != nil) {
            // In this case the completion was shown already by image picker
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                picker.showLoadingView = YES;
                
                ConversationMediaPictureCamera camera = picker.cameraDevice == UIImagePickerControllerCameraDeviceFront ? ConversationMediaPictureCameraFront : ConversationMediaPictureCameraBack;
                
                [Analytics.shared tagMediaSentPictureSourceCameraInConversation:self.conversation method:ConversationMediaPictureTakeMethodFullFromKeyboard camera:camera];
                
                [self.sendController sendMessageWithImageData:UIImageJPEGRepresentation(image, 0.9) completion:^{
                    picker.showLoadingView = NO;
                    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
                }];
            }
            else {
                [self.parentViewController dismissViewControllerAnimated:YES completion:^(){
                    ImageMetadata *metadata = [[ImageMetadata alloc] init];
                    metadata.method = ConversationMediaPictureTakeMethodFullFromKeyboard;
                    metadata.source = ConversationMediaPictureSourceGallery;
                    
                    [self showConfirmationForImage:UIImageJPEGRepresentation(image, 0.9) metadata:metadata];
                }];
            }
            
        }
    }
    else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Workaround http://stackoverflow.com/questions/26651355/
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.parentViewController dismissViewControllerAnimated:YES completion:^() {
        
        if (self.shouldRefocusKeyboardAfterImagePickerDismiss) {
            self.shouldRefocusKeyboardAfterImagePickerDismiss = NO;
            self.mode = ConversationInputBarViewControllerModeCamera;
            [self.inputBar.textView becomeFirstResponder];
        }
    }];
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker
{
    documentPicker.delegate = self;
    [self.parentViewController presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    [self uploadItemAtURL:url];
}

@end
