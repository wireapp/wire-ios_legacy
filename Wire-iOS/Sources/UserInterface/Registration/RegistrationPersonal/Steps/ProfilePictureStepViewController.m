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

@property (nonatomic) NSArray<NSLayoutConstraint *> *compactContentConstraints;
@property (nonatomic) NSArray<NSLayoutConstraint *> *regularContentConstraints;

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
    self.contentView = [UIView new];
    [self.view addSubview:self.contentView];
}

- (void)createImageView
{
    self.profilePictureImageView = [UIImageView new];
    self.profilePictureImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profilePictureImageView.clipsToBounds = YES;
    [self.view addSubview:self.profilePictureImageView];
}

- (void)createOverlayView
{
    self.overlayView = [UIView new];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self.profilePictureImageView addSubview:self.overlayView];
}

- (void)createSubtitleLabel
{
    self.subtitleLabel = [UILabel new];
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

#pragma mark - Layout Constraints

- (void)createConstraints
{
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectOwnPictureButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.keepDefaultPictureButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.profilePictureImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

    CGFloat inset = 28.0;

    NSArray<NSLayoutConstraint *> *constraints =
    @[
      // subtitleLabel
      [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:inset],
      [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-inset],

      // selectOwnPictureButton
      [self.selectOwnPictureButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:inset],
      [self.selectOwnPictureButton.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:24],
      [self.selectOwnPictureButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-inset],
      [self.selectOwnPictureButton.heightAnchor constraintEqualToConstant:40],

      // keepDefaultPictureButton
      [self.keepDefaultPictureButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:inset],
      [self.keepDefaultPictureButton.topAnchor constraintEqualToAnchor:self.selectOwnPictureButton.bottomAnchor constant:8],
      [self.keepDefaultPictureButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-inset],
      [self.keepDefaultPictureButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-inset],
      [self.keepDefaultPictureButton.heightAnchor constraintEqualToConstant:40],

      // profilePictureImageView
      [self.profilePictureImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.profilePictureImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [self.profilePictureImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.profilePictureImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

      // overlayView
      [self.overlayView.leadingAnchor constraintEqualToAnchor:self.profilePictureImageView.leadingAnchor],
      [self.overlayView.topAnchor constraintEqualToAnchor:self.profilePictureImageView.topAnchor],
      [self.overlayView.trailingAnchor constraintEqualToAnchor:self.profilePictureImageView.trailingAnchor],
      [self.overlayView.bottomAnchor constraintEqualToAnchor:self.profilePictureImageView.bottomAnchor],
      ];

    [NSLayoutConstraint activateConstraints:constraints];

    self.compactContentConstraints =
    @[
      [self.contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.contentView.topAnchor constraintEqualToAnchor:self.safeTopAnchor],
      [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [self.contentView.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor],
      ];

    self.regularContentConstraints =
    @[
      [self.contentView.widthAnchor constraintEqualToConstant:self.parentViewController.maximumFormSize.width],
      [self.contentView.heightAnchor constraintEqualToConstant:self.parentViewController.maximumFormSize.height],
      [self.contentView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
      [self.contentView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
      ];

    BOOL isRegular = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    [self updateConstraintsForRegularLayout:isRegular];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    BOOL isRegular = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    [self updateConstraintsForRegularLayout:isRegular];
}

- (void)updateConstraintsForRegularLayout:(BOOL)isRegular
{
    if (isRegular) {
        [NSLayoutConstraint deactivateConstraints:self.compactContentConstraints];
        [NSLayoutConstraint activateConstraints:self.regularContentConstraints];
    } else {
        [NSLayoutConstraint deactivateConstraints:self.regularContentConstraints];
        [NSLayoutConstraint activateConstraints:self.compactContentConstraints];
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

