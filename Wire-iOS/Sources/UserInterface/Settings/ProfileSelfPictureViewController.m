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



#import "ProfileSelfPictureViewController.h"

@import MobileCoreServices;
@import Photos;

@import PureLayout;

#import "WireSyncEngine+iOS.h"

#import "UIImage+ZetaIconsNeue.h"
#import "BottomOverlayViewController+Private.h"
@import WireExtensionComponents;

#import "ImagePickerConfirmationController.h"
#import "Analytics.h"
#import "Constants.h"
#import "AppDelegate.h"

#import "Wire-Swift.h"

@interface ProfileSelfPictureViewController ()

@property (nonatomic) ButtonWithLargerHitArea *cameraButton;
@property (nonatomic) ButtonWithLargerHitArea *libraryButton;

@property (nonatomic) ImagePickerConfirmationController *imagePickerConfirmationController;
@property (nonatomic) UIImageView *selfUserImageView;
@property (nonatomic) id userObserverToken;
@end

@implementation ProfileSelfPictureViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _imagePickerConfirmationController = [[ImagePickerConfirmationController alloc] init];
        
        @weakify(self);
        _imagePickerConfirmationController.imagePickedBlock = ^(NSData *imageData) {
            @strongify(self);
            [self dismissViewControllerAnimated:YES completion:nil];
            [self setSelfImageToData:imageData];
        };
        
        self.userObserverToken = [UserChangeInfo addObserver:self forUser:[ZMUser selfUser] userSession:[ZMUserSession sharedSession]];
    }
    
    return self;
}


- (void)addCameraButton
{
    self.cameraButton = [[ButtonWithLargerHitArea alloc] init];
    self.cameraButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.bottomOverlayView addSubview:self.cameraButton];

    CGFloat bottomOffset = 0.0;
    if(UIScreen.safeArea.bottom > 0) {
        bottomOffset = - UIScreen.safeArea.bottom + 20.0;
    }
    
    [self.cameraButton addConstraintForAligningHorizontallyWithView:self.bottomOverlayView];
    [self.cameraButton addConstraintForAligningVerticallyWithView:self.bottomOverlayView offset:bottomOffset];

    [self.cameraButton setImage:[UIImage imageForIcon:ZetaIconTypeCameraLens iconSize:ZetaIconSizeCamera color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.cameraButton.accessibilityLabel = @"cameraButton";

}

- (void)addLibraryButton
{
    CGSize libraryButtonSize = CGSizeMake(32, 32);
    
    self.libraryButton = [[ButtonWithLargerHitArea alloc] init];
    self.libraryButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.libraryButton.accessibilityIdentifier = @"CameraLibraryButton";
    [self.bottomOverlayView addSubview:self.libraryButton];

    [self.libraryButton addConstraintsForSize:libraryButtonSize];
    [self.libraryButton addConstraintForAligningVerticallyWithView:self.cameraButton];
    [self.libraryButton addConstraintForLeftMargin:24 relativeToView:self.bottomOverlayView];

    [self.libraryButton setImage:[UIImage imageForIcon:ZetaIconTypePhoto iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        options.fetchLimit = 1;
        
        PHAsset *asset = [PHAsset fetchAssetsWithOptions:options].firstObject;
        if (nil != asset) {
            // If asset is found, grab its thumbnail, create a CALayer with its contents,
            [[PHImageManager defaultManager]
             requestImageForAsset:asset
             targetSize:CGSizeApplyAffineTransform(libraryButtonSize, CGAffineTransformMakeScale(self.view.contentScaleFactor, self.view.contentScaleFactor))
             contentMode:PHImageContentModeAspectFill
             options:nil
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.libraryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                     self.libraryButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                     self.libraryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                     [self.libraryButton setImage:result forState:UIControlStateNormal];
                     
                     self.libraryButton.layer.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.32].CGColor;
                     self.libraryButton.layer.borderWidth = 1;
                     self.libraryButton.layer.cornerRadius = 5;
                     self.libraryButton.clipsToBounds = YES;
                 });
                 
             }];
        }
    }

    [self.libraryButton addTarget:self action:@selector(libraryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addCloseButton
{
    ButtonWithLargerHitArea *closeButton = [[ButtonWithLargerHitArea alloc] initForAutoLayout];
    closeButton.accessibilityIdentifier = @"CloseButton";

    [self.bottomOverlayView addSubview:closeButton];
    
    [closeButton addConstraintsForSize:CGSizeMake(32, 32)];
    [closeButton addConstraintForAligningVerticallyWithView:self.cameraButton];
    [closeButton addConstraintForRightMargin:18 relativeToView:self.bottomOverlayView];
    
    [closeButton setImage:[UIImage imageForIcon:ZetaIconTypeX iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

/// This should be called when the user has confirmed their intent to set their image to this data. No custom presentations should be in flight, all previous presentations should be completed by this point.
- (void)setSelfImageToData:(NSData *)selfImageData
{
    // iOS11 uses HEIF image format, but BE expects JPEG
    NSData *jpegData = selfImageData.isJPEG ? selfImageData : UIImageJPEGRepresentation([UIImage imageWithData:selfImageData], 1.0);
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [[ZMUserSession sharedSession].profileUpdate updateImageWithImageData:jpegData];
        [self.delegate bottomOverlayViewControllerBackgroundTapped:self];
    }];
}

#pragma mark - Button Handling

- (void)libraryButtonTapped:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.mediaTypes = @[(__bridge NSString *) kUTTypeImage];
    imagePickerController.delegate = self.imagePickerConfirmationController;
    
    if (IS_IPAD_FULLSCREEN) {
        imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popover = imagePickerController.popoverPresentationController;
        popover.sourceRect = CGRectInset([sender bounds], 4, 4);
        popover.sourceView = sender;
        popover.backgroundColor = UIColor.whiteColor;
    }
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)cameraButtonTapped:(id)sender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ||
        ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        return;
    }
    
    if([[ZMUserSession sharedSession] isCallOngoing]) {
        [CameraAccess displayCameraAlertForOngoingCallAt:CameraAccessFeatureTakePhoto from:self];
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self.imagePickerConfirmationController;
    picker.allowsEditing = YES;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    picker.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)closeButtonTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Overrides

- (void)setupTopView
{
    [super setupTopView];
    self.selfUserImageView = [[UIImageView alloc] init];
    self.selfUserImageView.clipsToBounds = YES;
    self.selfUserImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.selfUserImageView.image = [UIImage imageWithData:[ZMUser selfUser].imageMediumData];

    [self.topView addSubview:self.selfUserImageView];
    [self.selfUserImageView autoPinEdgesToSuperviewEdges];
}

- (void)setupBottomOverlay
{
    [super setupBottomOverlay];
    
    [self addCameraButton];
    [self addLibraryButton];
    [self addCloseButton];
}

@end

