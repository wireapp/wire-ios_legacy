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


#import "CameraViewController.h"

#import <AVFoundation/AVFoundation.h>
@import PureLayout;
#import <Classy/Classy.h>

#import "CameraController.h"
#import "CameraControlsViewController.h"
#import "CameraTopToolsViewController.h"
#import "CameraBottomToolsViewController.h"
#import "CameraAccessDeniedView.h"
#import "CameraConfirmationView.h"

@import WireExtensionComponents;
@import FLAnimatedImage;
#import "UIImage+ZetaIconsNeue.h"
#import "UIImage+ImageUtilities.h"
#import "WAZUIMagicIOS.h"
#import "IconButton.h"
#import "Constants.h"
#import "Settings.h"
#import "DeviceOrientationObserver.h"

#import "AnalyticsTracker+Permissions.h"

#import "Wire-Swift.h"

static CameraControllerCamera CameraViewControllerToCameraControllerCamera(CameraViewControllerCamera camera)
{
    switch (camera) {
        case CameraViewControllerCameraFront:
            return CameraControllerCameraFront;
            break;
            
        case CameraViewControllerCameraBack:
            return CameraControllerCameraBack;
            break;
    }
}



@interface CameraViewController () <CameraBottomToolsViewControllerDelegate, CameraControllerDelegate>

@property (nonatomic) CameraController *cameraController;
@property (nonatomic) CameraControlsViewController *cameraControlsViewController;
@property (nonatomic) CameraTopToolsViewController *cameraTopToolsViewController;
@property (nonatomic) CameraBottomToolsViewController *cameraBottomToolsViewController;

@property (nonatomic) UIView *topPanel;
@property (nonatomic) UIView *bottomPanel;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) CameraConfirmationView *cameraConfirmationView;
@property (nonatomic) CameraAccessDeniedView *cameraAccessDeniedView;

@property (nonatomic) FLAnimatedImageView *imagePreviewView;
@property (nonatomic) UIView *imagePreviewContainer;
/// Stores the camera (edited) image
@property (nonatomic) NSData *cameraImageData;

@property (nonatomic, copy) void (^acceptedBlock)();
@property (nonatomic, strong) ImageMetadata *imageMetadata;

@property (nonatomic, readonly) CameraViewControllerPreviewSize previewSize;

@property (nonatomic) BOOL initialConstraintsCreated;

@property (nonatomic) NSLayoutConstraint *titleLabelAlignAxisConstraint;
@property (nonatomic) NSLayoutConstraint *topToolsViewAlignAxisConstraint;
@property (nonatomic) NSLayoutConstraint *bottomToolsViewAlignAxisConstraint;
@property (nonatomic) NSLayoutConstraint *cameraConfirmationViewAlignAxisConstraint;

@property (nonatomic) NSLayoutConstraint *previewImagePortraitAspectRatioConstraint;
@property (nonatomic) NSLayoutConstraint *previewImageLandscapeAspectRatioConstraint;

@property (nonatomic) NSLayoutConstraint *previewImageTopConstraint;
@property (nonatomic) NSLayoutConstraint *previewImageBottomConstraint;
@property (nonatomic) IconButton *editButton;

@property (nonatomic) CGFloat topBarHeight;
@property (nonatomic) CGFloat bottomBarHeight;

@property (nonatomic) CIContext *ciContext;

@end

@interface CameraViewController (Sketch) <CanvasViewControllerDelegate>
@end

@implementation CameraViewController

- (instancetype)init
{
    return [self initWithCameraController:[[CameraController alloc] init]];
}

- (instancetype)initWithCameraController:(CameraController *)cameraController
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.cameraController = cameraController;
        self.cameraController.delegate = self;
        self.cameraController.currentCamera = CameraControllerCameraBack;
        self.cameraController.flashMode = [[Settings sharedSettings] preferredFlashMode];
        self.ciContext = [CIContext contextWithOptions:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cameraController.previewLayer.frame = self.view.frame;
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    self.cameraController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.cameraController.previewLayer];
    
    self.topBarHeight = [WAZUIMagic floatForIdentifier:@"camera_overlay.top_bar.height"];
    self.bottomBarHeight = [WAZUIMagic floatForIdentifier:@"camera_overlay.bottom_bar.height"];
    
    [self createCameraControls];
    [self createPreviewPanel];
    [self createCameraAccessDeniedView];
    [self createTopPanel];
    [self createBottomPanel];
    [self createEditButton];
    
    [self updateViewConstraints];
    [self updateCameraAccessDeniedVisibillity];
    [self updateVideoOrientation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraControllerWillChangeCurrentCamera:)
                                                 name:CameraControllerWillChangeCurrentCamera
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.cameraController startRunning];
    [[DeviceOrientationObserver sharedInstance] startMonitoringDeviceOrientation];
    
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:NO];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.cameraController stopRunning];
    [[DeviceOrientationObserver sharedInstance] stopMonitoringDeviceOrientation];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.cameraController.previewLayer.frame = self.imagePreviewContainer.frame;
    [self updateVideoOrientation];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)updateVideoOrientation
{
    AVCaptureVideoOrientation statusBarOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *connection = self.cameraController.previewLayer.connection;
    
    if ([connection isVideoOrientationSupported]) {
        connection.videoOrientation = statusBarOrientation;
    }
    
    if (IS_IPAD_FULLSCREEN) {
        self.cameraController.snapshotVideoOrientation = statusBarOrientation;
    } else {
        self.cameraController.snapshotVideoOrientation = AVCaptureVideoOrientationPortrait;
    }
}

- (void)setDefaultCamera:(CameraViewControllerCamera)defaultCamera
{
    _defaultCamera = defaultCamera;
    self.cameraController.currentCamera = CameraViewControllerToCameraControllerCamera(defaultCamera);
}

#pragma mark - View Creation

- (void)createCameraControls
{
    self.cameraControlsViewController = [[CameraControlsViewController alloc] initWithCameraController:self.cameraController];
    self.cameraControlsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.cameraControlsViewController];
    [self.view addSubview:self.cameraControlsViewController.view];
    [self.cameraControlsViewController didMoveToParentViewController:self];
}

- (void)createPreviewPanel
{
    self.imagePreviewContainer = [[UIView alloc] init];
    self.imagePreviewContainer.clipsToBounds = YES;
    self.imagePreviewContainer.userInteractionEnabled = NO;
    [self.view addSubview:self.imagePreviewContainer];
    
    self.imagePreviewView = [[FLAnimatedImageView alloc] init];
    self.imagePreviewView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imagePreviewView.contentMode = self.previewSize == CameraViewControllerPreviewSizeFullscreen ? UIViewContentModeScaleAspectFill :  UIViewContentModeScaleAspectFit;
    [self.imagePreviewContainer addSubview:self.imagePreviewView];
}

- (void)createTopPanel
{
    self.topPanel = [[UIView alloc] init];
    self.topPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.topPanel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self.view addSubview:self.topPanel];
    
    self.cameraTopToolsViewController = [[CameraTopToolsViewController alloc] initWithCameraController:self.cameraController];
    [self addChildViewController:self.cameraTopToolsViewController];
    self.cameraTopToolsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topPanel addSubview:self.cameraTopToolsViewController.view];
    [self.cameraTopToolsViewController didMoveToParentViewController:self];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = self.previewTitle;
    [self.topPanel addSubview:self.titleLabel];
}

- (void)createBottomPanel
{
    self.bottomPanel = [[UIView alloc] init];
    self.bottomPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomPanel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self.view addSubview:self.bottomPanel];
    
    self.cameraBottomToolsViewController = [[CameraBottomToolsViewController alloc] initWithCameraController:self.cameraController];
    self.cameraBottomToolsViewController.delegate = self;
    self.cameraBottomToolsViewController.previewTitle = self.previewTitle;
    [self addChildViewController:self.cameraBottomToolsViewController];
    self.cameraBottomToolsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomPanel addSubview:self.cameraBottomToolsViewController.view];
    [self.cameraBottomToolsViewController didMoveToParentViewController:self];
    
    self.cameraConfirmationView = [[CameraConfirmationView alloc] initForAutoLayout];
    [self.cameraConfirmationView.acceptButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.cameraConfirmationView.rejectButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomPanel addSubview:self.cameraConfirmationView];
}

- (void)createEditButton
{
    self.editButton = [IconButton iconButtonCircularLight];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.editButton setIcon:ZetaIconTypeBrush withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.editButton.accessibilityIdentifier = @"editNotConfirmedImageButton";
    [self.editButton setBackgroundImageColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.view addSubview:self.editButton];
    [self.editButton addTarget:self action:@selector(editImage:) forControlEvents:UIControlEventTouchUpInside];
    self.editButton.hidden = YES;
}

- (void)createCameraAccessDeniedView
{
    self.cameraAccessDeniedView = [[CameraAccessDeniedView alloc] initForAutoLayout];
    [self.view addSubview:self.cameraAccessDeniedView];
}

- (void)updateViewConstraints
{
    if (! self.initialConstraintsCreated) {
        
        // Top panel
        [self.topPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.topPanel autoSetDimension:ALDimensionHeight toSize:self.topBarHeight];
        
        self.topToolsViewAlignAxisConstraint = [self.cameraTopToolsViewController.view autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.topPanel withOffset:0];
        [self.cameraTopToolsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.cameraTopToolsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.cameraTopToolsViewController.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.topPanel];
        
        self.titleLabelAlignAxisConstraint = [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.topPanel withOffset:-self.topBarHeight];
        [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        // Bottom panel
        [self.bottomPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            [self.bottomPanel autoSetDimension:ALDimensionHeight toSize:self.bottomBarHeight];
        }];
        
        self.bottomToolsViewAlignAxisConstraint = [self.cameraBottomToolsViewController.view autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.bottomPanel withOffset:0];
        [self.cameraBottomToolsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.cameraBottomToolsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.cameraBottomToolsViewController.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomPanel];
        
        // Accept/Reject panel
        self.cameraConfirmationViewAlignAxisConstraint = [self.cameraConfirmationView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.bottomPanel withOffset:self.bottomBarHeight];
        [self.cameraConfirmationView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.cameraConfirmationView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.cameraConfirmationView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.cameraConfirmationView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomPanel];
        
        // Preview image
        [self.imagePreviewView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.imagePreviewView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        
        [self.imagePreviewContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.imagePreviewContainer autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        self.previewImagePortraitAspectRatioConstraint = [self.imagePreviewContainer autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePreviewContainer withMultiplier:4.0/3.0];
        self.previewImagePortraitAspectRatioConstraint.active = NO;
        self.previewImageLandscapeAspectRatioConstraint = [self.imagePreviewContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.imagePreviewContainer withMultiplier:4.0/3.0];
        self.previewImageLandscapeAspectRatioConstraint.active = NO;
        
        [self.editButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
        [self.editButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
        [self.editButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel withOffset:-20];
        
        // Camera Access Denied
        [self.cameraAccessDeniedView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.cameraAccessDeniedView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.view];
        [self.cameraAccessDeniedView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.9 relation:NSLayoutRelationLessThanOrEqual];
        
        // Touch Camera Controls
        [self.cameraControlsViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel];
        [self.cameraControlsViewController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
        [self.cameraControlsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.cameraControlsViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        self.initialConstraintsCreated = YES;
    }
    
    if (self.previewSize == CameraViewControllerPreviewSizeFullscreen) {
        self.previewImageLandscapeAspectRatioConstraint.active = NO;
        self.previewImagePortraitAspectRatioConstraint.active = NO;
        
        if (self.previewImageTopConstraint == nil && self.previewImageBottomConstraint == nil) {
            self.previewImageTopConstraint = [self.imagePreviewContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
            self.previewImageBottomConstraint = [self.imagePreviewContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        }
    } else {
        if (self.view.bounds.size.height >= self.view.bounds.size.width) {
            self.previewImageLandscapeAspectRatioConstraint.active = NO;
            self.previewImagePortraitAspectRatioConstraint.active = YES;
        } else {
            self.previewImagePortraitAspectRatioConstraint.active = NO;
            self.previewImageLandscapeAspectRatioConstraint.active = YES;
        }
        
        if (self.previewImageTopConstraint == nil && self.previewImageBottomConstraint == nil) {
            self.previewImageTopConstraint = [self.imagePreviewContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel];
            self.previewImageBottomConstraint = [self.imagePreviewContainer autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
        }
    }
    
    [super updateViewConstraints];
}

- (void)setPreferedPreviewSize:(CameraViewControllerPreviewSize)preferedPreviewSize
{
    _preferedPreviewSize = preferedPreviewSize;
    
    if (self.previewSize == CameraViewControllerPreviewSizeFullscreen) {
        self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    [self.view removeConstraint:self.previewImageTopConstraint];
    [self.view removeConstraint:self.previewImageBottomConstraint];
    
    self.previewImageTopConstraint = nil;
    self.previewImageBottomConstraint = nil;
    
    [self updateViewConstraints];
}

- (CameraViewControllerPreviewSize)previewSize
{
    if (IS_IPAD_FULLSCREEN || IS_IPHONE_4) {
        return CameraViewControllerPreviewSizeFullscreen;
    } else {
        return self.preferedPreviewSize;
    }
}

#pragma mark - Animations / State Changes

- (void)presentConfirmDialogForImageData:(NSData *)imageData mirror:(BOOL)mirror acceptedBlock:(void (^)())acceptedBlock
{
    self.imagePreviewView.image = [UIImage imageFromData:imageData withMaxSize:MAX(CGRectGetWidth(UIScreen.mainScreen.nativeBounds), CGRectGetHeight(UIScreen.mainScreen.nativeBounds))];
    self.imagePreviewView.transform = CGAffineTransformMakeScale(mirror ? -1 : 1, 1);
 
    if (!self.disableSketch) {
        self.editButton.hidden = NO;
    }
    
    // FLAnimatedImageView doesn't draw the normal background color so we need set it on the layer.
    self.imagePreviewView.layer.backgroundColor = UIColor.blackColor.CGColor;
    
    self.topToolsViewAlignAxisConstraint.constant = -self.topBarHeight;
    self.bottomToolsViewAlignAxisConstraint.constant = self.bottomBarHeight;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.cameraConfirmationViewAlignAxisConstraint.constant = 0;
        self.titleLabelAlignAxisConstraint.constant = 0;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }];
    
    self.acceptedBlock = acceptedBlock;
}

- (void)dismissConfirmDialog
{
    self.imagePreviewView.image = nil;
    self.imagePreviewView.animatedImage = nil;
    self.imagePreviewView.backgroundColor = [UIColor clearColor];
    
    self.editButton.hidden = YES;
    
    self.cameraConfirmationViewAlignAxisConstraint.constant = self.bottomBarHeight;
    self.titleLabelAlignAxisConstraint.constant = -self.topBarHeight;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.topToolsViewAlignAxisConstraint.constant = 0;
        self.bottomToolsViewAlignAxisConstraint.constant = 0;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }];
}

- (void)updateCameraAccessDeniedVisibillity
{
    self.cameraTopToolsViewController.view.hidden = [self.cameraController isCameraAccessDenied];
    self.cameraAccessDeniedView.hidden = ! [self.cameraController isCameraAccessDenied];
}

#pragma mark - Actions

- (IBAction)acceptImage:(id)sender
{
    if (self.acceptedBlock) {
        self.acceptedBlock();
    }
}

- (IBAction)rejectImage:(id)sender
{
    [self dismissConfirmDialog];
}

- (IBAction)editImage:(id)sender
{
    CanvasViewController *viewController = [[CanvasViewController alloc] init];
    viewController.delegate = self;
    viewController.sketchImage = self.imagePreviewView.image;
    [self presentViewController:[viewController wrapInNavigationController] animated:YES completion:nil];
}

#pragma mark - CameraBottomToolsViewControllerDelegate

- (void)cameraBottomToolsViewControllerDidCancel:(id)controller
{
    if ([self.delegate respondsToSelector:@selector(cameraViewControllerDidCancel:)]) {
        [self.delegate cameraViewControllerDidCancel:self];
    }
}

- (void)cameraBottomToolsViewController:(id)controller didCaptureImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata
{
    self.cameraImageData = imageData;
    self.imageMetadata = metadata;
    
    BOOL frontCameraImage = self.cameraController.currentCamera == CameraControllerCameraFront;
    @weakify(self);
    
    [self presentConfirmDialogForImageData:imageData mirror:frontCameraImage acceptedBlock:^{
        @strongify(self);
        
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didPickImageData:imageMetadata:)]) {
            
            if (self.savePhotosToCameraRoll) {
                UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:imageData], self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
            }
            
            [self.delegate cameraViewController:self didPickImageData:self.cameraImageData imageMetadata:self.imageMetadata];
        }
    }];
}

- (void)cameraBottomToolsViewController:(id)controller didPickImageData:(NSData *)imageData imageMetadata:(ImageMetadata *)metadata
{
    self.imageMetadata = metadata;
    if ([self.delegate respondsToSelector:@selector(cameraViewController:didPickImageData:imageMetadata:)]) {
        [self.delegate cameraViewController:self didPickImageData:imageData imageMetadata:self.imageMetadata];
    }
}

#pragma mark - Save image to camera roll

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != nil) {
        DDLogError(@"Cannot save image to camera roll: %@", error);
    }
}

#pragma mark - CameraControllerDelegate

- (void)cameraControllerDeniedAccessToCamera:(id)controller
{
    [self.analyticsTracker tagCameraPermissions:NO];
    [self updateCameraAccessDeniedVisibillity];
}

- (void)cameraControllerAllowedAccessToCamera:(id)controller
{
    [self.analyticsTracker tagCameraPermissions:YES];
}

#pragma mark - CameraController Notifications

- (void)cameraControllerWillChangeCurrentCamera:(NSNotification *)notification
{
    UIImage *snapshotImage = [self.cameraController.videoSnapshot imageScaledWithFactor:0.5];
    UIImage *blurredSnapshotImage = [snapshotImage blurredImageWithContext:self.ciContext blurRadius:12];
    
    UIView *flipView = [[UIView alloc] init];
    flipView.autoresizesSubviews = YES;
    flipView.frame = self.cameraController.previewLayer.frame;
    flipView.backgroundColor = [UIColor blackColor];
    flipView.opaque = YES;
    [self.view insertSubview:flipView belowSubview:self.topPanel];
    
    UIImageView *unblurredImageView = [[UIImageView alloc] initWithImage:snapshotImage];
    unblurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    unblurredImageView.frame = flipView.bounds;
    unblurredImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImageView *blurredImageView = [[UIImageView alloc] initWithImage:blurredSnapshotImage];
    blurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    blurredImageView.frame = flipView.bounds;
    blurredImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [flipView addSubview:unblurredImageView];
    
    [CATransaction flush];
    
    self.cameraController.previewLayer.hidden = YES;
    self.cameraControlsViewController.view.hidden = YES;
    self.view.userInteractionEnabled = NO;
    [UIView transitionFromView:unblurredImageView toView:blurredImageView duration:0.35 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
        [UIView animateWithDuration:0.35 delay:0.35 options:0 animations:^{
            flipView.alpha = 0;
            self.cameraController.previewLayer.hidden = NO;
        } completion:^(BOOL finished) {
            [flipView removeFromSuperview];
            self.cameraControlsViewController.view.hidden = NO;
            self.view.userInteractionEnabled = YES;
        }];
    }];
}

@end

@implementation CameraViewController (Sketch)

- (void)canvasViewController:(CanvasViewController *)canvasViewController didExportImage:(UIImage *)image
{
    self.imagePreviewView.image = image;
    self.cameraImageData = UIImagePNGRepresentation(image);
    ImageMetadata *newImageMetadata = [[ImageMetadata alloc] init];
    newImageMetadata.source = ConversationMediaPictureSourceSketch;
    newImageMetadata.method = ConversationMediaPictureTakeMethodQuickMenu;
    newImageMetadata.sketchSource = ConversationMediaSketchSourceCameraGallery;
    self.imageMetadata = newImageMetadata;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
