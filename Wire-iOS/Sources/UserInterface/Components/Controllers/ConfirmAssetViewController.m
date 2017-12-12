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


#import "ConfirmAssetViewController.h"

@import PureLayout;
#import <Classy/Classy.h>
@import AVKit;
@import AVFoundation;
@import FLAnimatedImage;
#import "WAZUIMagicIOS.h"
#import "Wire-Swift.h"

#import "UIColor+WAZExtensions.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "UIView+Borders.h"
@import WireExtensionComponents;
#import "UIImage+ImageUtilities.h"
#import "MediaAsset.h"

static const CGFloat TopBarHeight = 44;
static const CGFloat BottomBarMinHeight = 88;
static const CGFloat MarginInset = 24;

@interface ConfirmAssetViewController () <CanvasViewControllerDelegate>

@property (nonatomic) UIView *topPanel;
@property (nonatomic) UIView *bottomPanel;

@property (nonatomic) UIView *confirmButtonsContainer;

@property (nonatomic) UILabel *titleLabel;

@property (nonatomic) Button *acceptImageButton;
@property (nonatomic) Button *rejectImageButton;
@property (nonatomic) FLAnimatedImageView *imagePreviewView;
@property (nonatomic) AVPlayerViewController *playerViewController;

@property (nonatomic) NSLayoutConstraint *topBarHeightConstraint;

@property (nonatomic) ImageToolbarView *imageToolbarViewInsideImage;
@property (nonatomic) ImageToolbarView *imageToolbarView;
@property (nonatomic) UIView *imageToolbarSeparatorView;

@end


@implementation ConfirmAssetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.image != nil) {
        [self createPreviewPanel];
    }
    else if (self.videoURL != nil) {
        [self createVideoPanel];
    }
    [self createTopPanel];
    [self createBottomPanel];
    [self createConstraints];
    
    [[CASStyler defaultStyler] styleItem:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}


- (void)setPreviewTitle:(NSString *)previewTitle
{
    _previewTitle = previewTitle;
    self.titleLabel.text = previewTitle;
    [self.view setNeedsUpdateConstraints];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (BOOL)imageToolbarFitsInsideImage
{
    return self.image.size.width > 192 && self.image.size.height > 96;
}

- (BOOL)showEditingOptions
{
    return self.videoURL == nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    switch ([ColorScheme defaultColorScheme].variant) {
        case ColorSchemeVariantLight:
            return UIStatusBarStyleDefault;
            break;
            
        case ColorSchemeVariantDark:
            return UIStatusBarStyleLightContent;
            break;
    }
}

#pragma mark - View Creation

- (void)createPreviewPanel
{
    self.imagePreviewView = [[FLAnimatedImageView alloc] init];
    self.imagePreviewView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFit;
    self.imagePreviewView.userInteractionEnabled = YES;
    [self.view addSubview:self.imagePreviewView];
    
    [self.imagePreviewView setMediaAsset:self.image];
    
    if ([self showEditingOptions] && [self imageToolbarFitsInsideImage]) {
        self.imageToolbarViewInsideImage = [[ImageToolbarView alloc] initWithConfiguraton:ImageToolbarConfigurationPreview];
        self.imageToolbarViewInsideImage.translatesAutoresizingMaskIntoConstraints = NO;
        self.imageToolbarViewInsideImage.isPlacedOnImage = YES;
        [self.imageToolbarViewInsideImage.sketchButton addTarget:self action:@selector(sketchEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imageToolbarViewInsideImage.emojiButton addTarget:self action:@selector(emojiEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imagePreviewView addSubview:self.imageToolbarViewInsideImage];
    }
}

- (void)createVideoPanel
{
    self.playerViewController = [[AVPlayerViewController alloc] init];
    
    self.playerViewController.player = [AVPlayer playerWithURL:self.videoURL];
    [self.playerViewController.player play];
    self.playerViewController.showsPlaybackControls = YES;
    self.playerViewController.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.playerViewController.view];
}

- (void)createTopPanel
{
    self.topPanel = [[UIView alloc] init];
    self.topPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.topPanel];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = self.previewTitle;
    [self.topPanel addSubview:self.titleLabel];
}

- (void)createBottomPanel
{
    self.bottomPanel = [[UIView alloc] init];
    self.bottomPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomPanel];
    
    if ([self showEditingOptions] && ![self imageToolbarFitsInsideImage]) {
        self.imageToolbarView = [[ImageToolbarView alloc] initWithConfiguraton:ImageToolbarConfigurationPreview];
        self.imageToolbarView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.imageToolbarView.sketchButton addTarget:self action:@selector(sketchEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imageToolbarView.emojiButton addTarget:self action:@selector(emojiEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPanel addSubview:self.imageToolbarView];
        
        self.imageToolbarSeparatorView = [[UIView alloc] init];
        self.imageToolbarSeparatorView.translatesAutoresizingMaskIntoConstraints = NO;
        self.imageToolbarSeparatorView.cas_styleClass = @"separator";
        [self.imageToolbarView addSubview:self.imageToolbarSeparatorView];
    }
    
    self.confirmButtonsContainer = [[UIView alloc] init];
    self.confirmButtonsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomPanel addSubview:self.confirmButtonsContainer];
    
    self.acceptImageButton = [Button buttonWithStyle:ButtonStyleFull];
    self.acceptImageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.acceptImageButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.acceptImageButton setTitle:NSLocalizedString(@"image_confirmer.confirm", @"") forState:UIControlStateNormal];
    [self.confirmButtonsContainer addSubview:self.acceptImageButton];
    
    self.rejectImageButton = [Button buttonWithStyle:ButtonStyleEmpty];
    self.rejectImageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rejectImageButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.rejectImageButton setTitle:NSLocalizedString(@"image_confirmer.cancel", @"") forState:UIControlStateNormal];
    [self.confirmButtonsContainer addSubview:self.rejectImageButton];
}

- (void)createConstraints
{
    CGFloat safeTopBarHeight = TopBarHeight + UIScreen.safeArea.top;
    
    // Top panel
    [self.topPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    self.topBarHeightConstraint = [self.topPanel autoSetDimension:ALDimensionHeight toSize:safeTopBarHeight];
    
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:UIScreen.safeArea.top];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    // Bottom panel
    [self.bottomPanel autoPinEdgesToSuperviewEdgesWithInsets:UIScreen.safeArea excludingEdge:ALEdgeTop];
    
    [self.imageToolbarView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.imageToolbarView autoSetDimension:ALDimensionHeight toSize:48];
    
    [self.imageToolbarSeparatorView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.imageToolbarSeparatorView autoSetDimension:ALDimensionHeight toSize:0.5];
    
    // Accept/Reject panel
    [self.confirmButtonsContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.confirmButtonsContainer autoSetDimension:ALDimensionHeight toSize:BottomBarMinHeight];
    
    if (self.imageToolbarView) {
        [self.confirmButtonsContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imageToolbarView withOffset:0];
    } else {
        [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    }
    
    [self.acceptImageButton autoSetDimension:ALDimensionHeight toSize:40];
    [self.acceptImageButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.acceptImageButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:MarginInset];
    [self.acceptImageButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.rejectImageButton autoSetDimension:ALDimensionHeight toSize:40];
    [self.rejectImageButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.rejectImageButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:MarginInset];
    [self.rejectImageButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.acceptImageButton autoSetDimension:ALDimensionWidth toSize:184];
        [self.rejectImageButton autoSetDimension:ALDimensionWidth toSize:184];
        [self.acceptImageButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.rejectImageButton withOffset:16];
    }];
    [self.acceptImageButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rejectImageButton];
    
    // Preview image
    CGSize imageSize = self.image.size;
    [self.imagePreviewView autoCenterInSuperview];
    [self.imagePreviewView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.imagePreviewView autoPinEdge:ALEdgeBottom  toEdge:ALEdgeTop ofView:self.bottomPanel withOffset:0 relation:NSLayoutRelationLessThanOrEqual];
    [self.imagePreviewView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.imagePreviewView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.imagePreviewView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePreviewView withMultiplier: imageSize.height / imageSize.width];

    [self.playerViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.playerViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];

    [self.playerViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel];
    [self.playerViewController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
    
    self.topBarHeightConstraint.constant = (self.titleLabel.text != nil) ? safeTopBarHeight : 0;
    
    // Image toolbar
    [self.imageToolbarViewInsideImage autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.imageToolbarViewInsideImage autoSetDimension:ALDimensionHeight toSize:48];
}

#pragma mark - Actions

- (IBAction)acceptImage:(id)sender
{
    if (self.onConfirm) {
        self.onConfirm(nil);
    }
}

- (IBAction)rejectImage:(id)sender
{
    if (self.onCancel) {
        self.onCancel();
    }
}

- (IBAction)sketchEdit:(id)sender
{
    [self openSketchInEditMode:CanvasViewControllerEditModeDraw];
}

- (IBAction)emojiEdit:(id)sender
{
    [self openSketchInEditMode:CanvasViewControllerEditModeEmoji];
}

- (void)openSketchInEditMode:(CanvasViewControllerEditMode)editMode
{
    if (![self.image isKindOfClass:UIImage.class]) {
        return;
    }
    
    CanvasViewController *canvasViewController = [[CanvasViewController alloc] init];
    canvasViewController.sketchImage = (UIImage *)self.image;
    canvasViewController.delegate = self;
    canvasViewController.title = self.previewTitle;
    [canvasViewController selectWithEditMode:editMode animated:NO];
    
    UIViewController *navigationController = [canvasViewController wrapInNavigationController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - CanvasViewControllerDelegate


- (void)canvasViewController:(CanvasViewController *)canvasViewController didExportImage:(UIImage *)image
{
    if (self.onConfirm) {
        self.onConfirm(image);
    }
}

@end
