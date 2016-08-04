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

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "zmessaging+iOS.h"

#import "UIImage+ZetaIconsNeue.h"
#import "BottomOverlayViewController+Private.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import "WAZUIMagicIOS.h"

#import "ImagePickerConfirmationController.h"
#import "CameraViewController.h"
#import "Analytics+iOS.h"
#import "ZMUserSession+Additions.h"
#import "ZClientViewController.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "ProfileSelfCameraTransition.h"

#import "AnalyticsTracker.h"
#import "AnalyticsTracker+SelfUser.h"

static ALAssetsLibrary *SelfProfileAssetsLibrary = nil;



@interface DefaultProfileSelfPictureTransitioningDelegate : NSObject<UIViewControllerTransitioningDelegate>

@end


@implementation DefaultProfileSelfPictureTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    NSAssert([presented isKindOfClass:[ProfileSelfPictureViewController class]], @"DefaultProfileSelfPictureTransitioningDelegate can only present a ProfileSelfPictureViewController");
    
    [presented view]; // Make sure view is loaded
    return [[ProfileSelfCameraTransition alloc] initWithBottomBarView:((ProfileSelfPictureViewController *)presented).bottomOverlayView reverse:NO];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    NSAssert([dismissed isKindOfClass:[ProfileSelfPictureViewController class]], @"DefaultProfileSelfPictureTransitioningDelegate can only present a ProfileSelfPictureViewController");
    
    return [[ProfileSelfCameraTransition alloc] initWithBottomBarView:((ProfileSelfPictureViewController *)dismissed).bottomOverlayView reverse:YES];
}

@end



@interface ProfileSelfPictureViewController () <CameraViewControllerDelegate>

@property (nonatomic) ButtonWithLargerHitArea *cameraButton;
@property (nonatomic) ButtonWithLargerHitArea *libraryButton;

@property (nonatomic) ImagePickerConfirmationController *imagePickerConfirmationController;
@property (nonatomic) DefaultProfileSelfPictureTransitioningDelegate *defaultTransitioningDelegate;

@end



@implementation ProfileSelfPictureViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _defaultTransitioningDelegate = [[DefaultProfileSelfPictureTransitioningDelegate alloc] init];
        _imagePickerConfirmationController = [[ImagePickerConfirmationController alloc] init];
        
        self.transitioningDelegate = self.defaultTransitioningDelegate;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        
        @weakify(self);
        _imagePickerConfirmationController.imagePickedBlock = ^(NSData *imageData, ImageMetadata *metadata) {
            @strongify(self);
            [[AppDelegate sharedAppDelegate].window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            [self setSelfImageToData:imageData];
        };
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)addCameraButton
{
    self.cameraButton = [[ButtonWithLargerHitArea alloc] init];
    self.cameraButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.bottomOverlayView addSubview:self.cameraButton];

    [self.cameraButton addConstraintForAligningHorizontallyWithView:self.bottomOverlayView];
    [self.cameraButton addConstraintForAligningVerticallyWithView:self.bottomOverlayView];

    [self.cameraButton setImage:[UIImage imageForIcon:ZetaIconTypeCameraLens iconSize:ZetaIconSizeCamera color:[UIColor whiteColor]] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.cameraButton.accessibilityLabel = @"cameraButton";

}

- (void)addLibraryButton
{
    self.libraryButton = [[ButtonWithLargerHitArea alloc] init];
    self.libraryButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.libraryButton.accessibilityIdentifier = @"CameraLibraryButton";
    [self.bottomOverlayView addSubview:self.libraryButton];

    [self.libraryButton addConstraintsForSize:CGSizeMake(32, 32)];
    [self.libraryButton addConstraintForAligningVerticallyWithView:self.cameraButton];
    [self.libraryButton addConstraintForLeftMargin:24 relativeToView:self.bottomOverlayView];

    [self.libraryButton setImage:[UIImage imageForIcon:ZetaIconTypePhoto iconSize:ZetaIconSizeSmall color:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        // If we have access to images, set the gallery image to the latest camera one
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            SelfProfileAssetsLibrary = [[ALAssetsLibrary alloc] init];
        });
        [SelfProfileAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            if (group.numberOfAssets > 0) {
                 [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1] options:0 usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *innerStop) {
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
                        *innerStop = YES;
                    }
                }];
                *stop = YES;
            }
        } failureBlock:^(NSError *error) {
            if (error != nil) {
                [[Analytics shared] tagApplicationError:error.localizedDescription
                                          timeInSession:[[UIApplication sharedApplication] lastApplicationRunDuration]];
            }
        }];
    }

    [self.libraryButton addTarget:self action:@selector(libraryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

/// This should be called when the user has confirmed their intent to set their image to this data. No custom presentations should be in flight, all previous presentations should be completed by this point.
- (void)setSelfImageToData:(NSData *)selfImageData
{
    id <ZMEditableUser> editableSelf = [ZMUser editableSelfUser];
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        editableSelf.originalProfileImageData = selfImageData;
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
    
    if (IS_IPAD) {
        imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popover = imagePickerController.popoverPresentationController;
        popover.sourceRect = CGRectInset([sender bounds], 4, 4);
        popover.sourceView = sender;
        popover.backgroundColor = UIColor.whiteColor;
    }
    
    [[AppDelegate sharedAppDelegate].window.rootViewController presentViewController:imagePickerController animated:YES completion:nil];
    [[Analytics shared] tagProfilePictureFromSource:PictureUploadPhotoLibrary];
}

- (void)cameraButtonTapped:(id)sender
{
    if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    CameraViewController *cameraViewController = [[CameraViewController alloc] init];
    cameraViewController.analyticsTracker = self.analyticsTracker;
    cameraViewController.savePhotosToCameraRoll = YES;
    cameraViewController.disableSketch = YES;
    cameraViewController.delegate = self;
    cameraViewController.defaultCamera = CameraViewControllerCameraFront;
    cameraViewController.preferedPreviewSize = CameraViewControllerPreviewSizeFullscreen;
    cameraViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [[AppDelegate sharedAppDelegate].window.rootViewController presentViewController:cameraViewController animated:YES completion:nil];
    [[Analytics shared] tagProfilePictureFromSource:PictureUploadCamera];
}

#pragma mark - Overrides

- (void)setupBottomOverlay
{
    [super setupBottomOverlay];
    
    [self addCameraButton];
    [self addLibraryButton];

}

#pragma mark - CameraViewControllerDelegate

- (void)cameraViewController:(CameraViewController *)cameraViewController didPickImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata
{
    [[AppDelegate sharedAppDelegate].window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self.analyticsTracker tagPictureChanged];
    [self setSelfImageToData:imageData];
}

- (void)cameraViewControllerDidCancel:(CameraViewController *)cameraViewController
{
    [[AppDelegate sharedAppDelegate].window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
