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


#import "CameraBottomToolsViewController.h"

@import PureLayout;
#import <AssetsLibrary/AssetsLibrary.h>

#import "Constants.h"
#import "CameraController.h"
#import "ImagePickerConfirmationController.h"
@import WireExtensionComponents;
#import "WAZUIMagicIOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "Analytics+iOS.h"
#import "DeviceOrientationObserver.h"
#import "WRFunctions.h"
#import "Wire-Swift.h"



@interface CameraBottomToolsViewController ()

@property (nonatomic) ImagePickerConfirmationController *imagePickerConfirmationController;
@property (nonatomic) CameraController *cameraController;
@property (nonatomic) ButtonWithLargerHitArea *libraryButton;
@property (nonatomic) ButtonWithLargerHitArea *shutterButton;
@property (nonatomic) ButtonWithLargerHitArea *closeButton;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation CameraBottomToolsViewController

- (instancetype)initWithCameraController:(CameraController *)cameraController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _cameraController = cameraController;
        _imagePickerConfirmationController = [[ImagePickerConfirmationController alloc] init];
        
        @weakify(self);
        self.imagePickerConfirmationController.imagePickedBlock = ^(NSData *imageData, ImageMetadata *metadata) {
            @strongify(self);
            
            [self.delegate cameraBottomToolsViewController:self didPickImageData:imageData imageMetadata:metadata];
        };
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.libraryButton = [ButtonWithLargerHitArea buttonWithType:UIButtonTypeCustom];
    self.libraryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.libraryButton setImage:[UIImage imageForIcon:ZetaIconTypePhoto iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.libraryButton addTarget:self action:@selector(openPhotoLibrary:) forControlEvents:UIControlEventTouchUpInside];
    self.libraryButton.accessibilityIdentifier = @"cameraLibraryButton";
    [self.view addSubview:self.libraryButton];
    
    self.shutterButton = [[ButtonWithLargerHitArea alloc] init];
    self.shutterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.shutterButton setImage:[UIImage imageForIcon:ZetaIconTypeCameraShutter iconSize:ZetaIconSizeCamera color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.shutterButton addTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
    self.shutterButton.accessibilityIdentifier = @"cameraShutterButton";
    [self.view addSubview:self.shutterButton];
    
    self.closeButton = [[ButtonWithLargerHitArea alloc] init];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setImage:[UIImage imageForIcon:ZetaIconTypeX iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeCamera:) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.accessibilityIdentifier = @"cameraCloseButton";
    [self.view addSubview:self.closeButton];
    
    [self configureLibraryButtonWithLatestImageFromPhotoRoll];
    [self updateViewConstraints];
    
    if (IS_IPHONE) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:DeviceOrientationObserverDidDetectRotationNotification object:nil];
    }
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    if (! self.initialConstraintsCreated) {
        const CGFloat Margin = [WAZUIMagic floatForIdentifier:@"camera_overlay.margin"];
        
        [self.libraryButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.libraryButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:Margin];
        [self.libraryButton autoSetDimension:ALDimensionWidth toSize:32 relation:NSLayoutRelationLessThanOrEqual];
        [self.libraryButton autoSetDimension:ALDimensionHeight toSize:32 relation:NSLayoutRelationLessThanOrEqual];
        
        [self.shutterButton autoCenterInSuperview];
        
        [self.closeButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:Margin];
        
        self.initialConstraintsCreated = YES;
    }
}

- (void)configureLibraryButtonWithLatestImageFromPhotoRoll
{
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        // If we have access to images, set the gallery image to the latest camera one
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                     usingBlock:^(ALAssetsGroup *group, BOOL *stop)
         {
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                 if (asset) {
                     // If asset is found, grab its thumbnail, create a CALayer with its contents,
                     CGImageRef thumbnailRef = [asset thumbnail];
                     
                     UIImage *anImage = [UIImage imageWithCGImage:thumbnailRef];
                     self.libraryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                     self.libraryButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                     self.libraryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                     [self.libraryButton setImage:anImage forState:UIControlStateNormal];
                     
                     self.libraryButton.layer.borderColor = [UIColor colorWithMagicIdentifier:@"camera.gallery_button_tile_stroke_color"].CGColor;
                     self.libraryButton.layer.borderWidth = [WAZUIMagic floatForIdentifier:@"camera.gallery_button_tile_stroke_width"];
                     self.libraryButton.layer.cornerRadius = 5;
                     self.libraryButton.clipsToBounds = YES;
                     *stop = YES;
                 }
             }];
             *stop = YES;
         } failureBlock:^(NSError *error){
             if (error != nil) {
                 [[Analytics shared] tagApplicationError:error.localizedDescription
                                           timeInSession:[[UIApplication sharedApplication] lastApplicationRunDuration]];
             }
         }];
    }
}

#pragma mark - Actions

- (IBAction)takePicture:(id)sender
{
    [self.cameraController captureStillImageWithCompletionHandler:^(NSData *imageData, NSDictionary *metaData, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(cameraBottomToolsViewController:didCaptureImageData:imageMetadata:)]) {
            ImageMetadata *metadata = [[ImageMetadata alloc] init];
            metadata.method = ConversationMediaPictureTakeMethodFullFromKeyboard;
            metadata.source = ConversationMediaPictureSourceCamera;
            metadata.camera = self.cameraController.currentCamera == CameraControllerCameraFront ? ConversationMediaPictureCameraFront : ConversationMediaPictureCameraBack;
            
            [self.delegate cameraBottomToolsViewController:self didCaptureImageData:imageData imageMetadata:metadata];
        }
    }];
}

- (IBAction)closeCamera:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cameraBottomToolsViewControllerDidCancel:)]) {
        [self.delegate cameraBottomToolsViewControllerDidCancel:self];
    }
}

- (IBAction)openPhotoLibrary:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self.imagePickerConfirmationController;
    self.imagePickerConfirmationController.previewTitle = self.previewTitle;
    
    if (IS_IPAD) {
        picker.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popover = picker.popoverPresentationController;
        popover.sourceRect = CGRectInset(self.libraryButton.bounds, 4, 4);
        popover.sourceView = self.libraryButton;
        popover.backgroundColor = UIColor.whiteColor;
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Device Rotation

- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [(NSNumber *)notification.object integerValue];
    CGAffineTransform transform = WRDeviceOrientationToAffineTransform(deviceOrientation);
    
    [UIView animateWithDuration:0.2f animations:^{
        self.closeButton.transform = transform;
        self.shutterButton.transform = transform;
        self.libraryButton.transform = transform;
    }];
}

@end
