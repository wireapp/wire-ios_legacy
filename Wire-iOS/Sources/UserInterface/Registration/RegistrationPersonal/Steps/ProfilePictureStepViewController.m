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


#import "ProfilePictureStepViewController.h"
#import "ProfilePictureStepViewController+Private.h"

@import PureLayout;
@import MobileCoreServices;

#import "UIColor+WAZExtensions.h"
#import "WireSyncEngine+iOS.h"
#import "UIViewController+Errors.h"
#import "Button.h"

#import "UIImagePickerController+GetImage.h"
#import "RegistrationFormController.h"
@import WireExtensionComponents;

#import "Wire-Swift.h"


NSString * const UnsplashRandomImageHiQualityURL = @"https://source.unsplash.com/800x800/?landscape";
#if TARGET_IPHONE_SIMULATOR
NSString * const UnsplashRandomImageLowQualityURL = @"https://source.unsplash.com/800x800/?landscape";
#else
NSString * const UnsplashRandomImageLowQualityURL = @"https://source.unsplash.com/256x256/?landscape";
#endif


@interface ProfilePictureStepViewController ()

@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) Button *selectOwnPictureButton;
@property (nonatomic) Button *keepDefaultPictureButton;
@property (nonatomic) ZMIncompleteRegistrationUser *unregisteredUser;
@property (nonatomic) UIImage *defaultProfilePictureImage;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *overlayView;

@end




@implementation ProfilePictureStepViewController

- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.unregisteredUser = unregisteredUser;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createImageView];
    [self createContentView];
    [self createOverlayView];
    [self createSubtitleLabel];
    [self createSelectPictureButton];
    [self createKeepPictureButton];
    [self createConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self downloadDefaultPictureImage];
}

- (void)createContentView
{
    self.contentView = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.contentView];
}

- (void)createImageView
{
    self.profilePictureImageView = [[UIImageView alloc] initForAutoLayout];
    self.profilePictureImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profilePictureImageView.clipsToBounds = YES;
    [self.view addSubview:self.profilePictureImageView];
}

- (void)createOverlayView
{
    self.overlayView = [[UIView alloc] initForAutoLayout];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self.profilePictureImageView addSubview:self.overlayView];
}

- (void)createSubtitleLabel
{
    self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
    self.subtitleLabel.font = UIFont.largeLightFont;
    self.subtitleLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"registration.select_picture.subtitle", nil), self.unregisteredUser.name];

    [self.contentView addSubview:self.subtitleLabel];
}

- (void)createSelectPictureButton
{
    self.selectOwnPictureButton = [Button buttonWithStyle:ButtonStyleFull];
    self.selectOwnPictureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectOwnPictureButton setTitle:NSLocalizedString(@"registration.select_picture.button_title", nil) forState:UIControlStateNormal];
    [self.selectOwnPictureButton addTarget:self action:@selector(selectPicture:) forControlEvents:UIControlEventTouchUpInside];
    self.selectOwnPictureButton.accessibilityIdentifier = @"ChooseOwnPictureButton";
    
    [self.contentView addSubview:self.selectOwnPictureButton];
}

- (void)createKeepPictureButton
{
    self.keepDefaultPictureButton = [Button buttonWithStyle:ButtonStyleEmpty variant:ColorSchemeVariantDark];
    self.keepDefaultPictureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.keepDefaultPictureButton setTitle:NSLocalizedString(@"registration.keep_picture.button_title", nil) forState:UIControlStateNormal];
    [self.keepDefaultPictureButton addTarget:self action:@selector(keepPicture:) forControlEvents:UIControlEventTouchUpInside];
    self.keepDefaultPictureButton.accessibilityIdentifier = @"KeepDefaultPictureButton";
    
    [self.contentView addSubview:self.keepDefaultPictureButton];
}

- (void)createConstraints
{
    CGFloat inset = 28.0;
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
    
    [self.selectOwnPictureButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel withOffset:24];
    [self.selectOwnPictureButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:inset];
    [self.selectOwnPictureButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:inset];
    [self.selectOwnPictureButton autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.keepDefaultPictureButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.selectOwnPictureButton withOffset:8];
    [self.keepDefaultPictureButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, inset, inset, inset) excludingEdge:ALEdgeTop];
    [self.keepDefaultPictureButton autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.profilePictureImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.overlayView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

    if (IS_IPAD_FULLSCREEN) {
        [self.contentView autoSetDimension:ALDimensionWidth toSize:self.parentViewController.maximumFormSize.width];
        [self.contentView autoSetDimension:ALDimensionHeight toSize:self.parentViewController.maximumFormSize.height];
        [self.contentView autoCenterInSuperview];
    } else {
        
        [[self.contentView.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor] setActive:YES];
        [[self.contentView.topAnchor constraintEqualToAnchor:self.safeTopAnchor] setActive:YES];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    }
}

#pragma mark - Actions

- (IBAction)selectPicture:(id)sender
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"registration.camera_action.title", "")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self showCameraController:sender];
                                                         }];
    
    UIAlertAction *galleryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"registration.photo_gallery_action.title", "")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self showGalleryController:sender];
                                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"registration.cancel_action.title", "")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    
    [actionSheet addAction:cameraAction];
    [actionSheet addAction:galleryAction];
    [actionSheet addAction:cancelAction];
    
    [self showController:actionSheet inPopoverFromView:sender];
}

- (IBAction)showCameraController:(id)sender
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ||
        ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)keepPicture:(id)sender
{
    self.showLoadingView = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = UIImageJPEGRepresentation(self.defaultProfilePictureImage, 1.0f);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.showLoadingView = NO;
            [self setPictureImageData:imageData];
        });
    });
}

- (void)showController:(UIViewController *)controller inPopoverFromView:(UIView *)view
{
    controller.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverController = controller.popoverPresentationController;
    popoverController.sourceRect = view.bounds;
    popoverController.sourceView = view;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Picture processing

- (void)downloadDefaultPictureImage
{
    if (self.defaultProfilePictureImage == nil) {
        NSString *urlString = nil;
        NetworkStatus *status = [NetworkStatus statusForHost:[NSURL URLWithString:UnsplashRandomImageHiQualityURL]];
        if ([status isNetworkQualitySufficientForOnlineFeatures]) {
            urlString = UnsplashRandomImageHiQualityURL;
        } else {
            urlString = UnsplashRandomImageLowQualityURL;
        }
        NSURL *imageURL = [NSURL URLWithString:urlString];

        self.showLoadingView = YES;
        @weakify(self);
        [self.profilePictureImageView displayImageAtURL:imageURL
                                              onSuccess:^(UIImage * _Nonnull image) {
                                                         @strongify(self);
                                                         self.profilePictureImageView.image = image;
                                                         self.defaultProfilePictureImage = image;
                                                         self.showLoadingView = NO;
                                                       }
                                                onError:^(NSError * _Nullable error) {
                                                         @strongify(self);
                                                         self.showLoadingView = NO;
                                                       }];
    }
}

- (void)setPictureImageData:(NSData *)imageData
{
    if (imageData != nil) {
        // iOS11 uses HEIF image format, but BE expects JPEG
        NSData *jpegData = imageData.isJPEG ? imageData : UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
        [[UnauthenticatedSession sharedSession] setProfileImage:jpegData];
        [self.formStepDelegate didCompleteFormStep:self];
    }
}

@end

