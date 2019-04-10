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
#import "ConfirmAssetViewController+Internal.h"

@import AVKit;
@import AVFoundation;
@import FLAnimatedImage;
#import "Wire-Swift.h"

#import "UIColor+WAZExtensions.h"
#import "Constants.h"
#import "AppDelegate.h"

#import "UIImage+ImageUtilities.h"
#import "MediaAsset.h"

static const CGFloat TopBarHeight = 44;
static const CGFloat BottomBarMinHeight = 88;
static const CGFloat MarginInset = 24;

@interface ConfirmAssetViewController () <CanvasViewControllerDelegate>

@end


@implementation ConfirmAssetViewController

+ (CGFloat) marginInset
{
    return MarginInset;
}

+ (CGFloat) topBarHeight
{
    return TopBarHeight;
}

+ (CGFloat) bottomBarMinHeight
{
    return BottomBarMinHeight;
}

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

    [self setupStyle];
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
    self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFit;
    self.imagePreviewView.userInteractionEnabled = YES;
    [self.view addSubview:self.imagePreviewView];
    
    [self.imagePreviewView setMediaAsset:self.image];
    
    if ([self showEditingOptions] && [self imageToolbarFitsInsideImage]) {
        self.imageToolbarViewInsideImage = [[ImageToolbarView alloc] initWithConfiguraton:ImageToolbarConfigurationPreview];
        self.imageToolbarViewInsideImage.isPlacedOnImage = YES;
        [self.imageToolbarViewInsideImage.sketchButton addTarget:self action:@selector(sketchEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imageToolbarViewInsideImage.emojiButton addTarget:self action:@selector(emojiEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imagePreviewView addSubview:self.imageToolbarViewInsideImage];
    }
}

- (void)createTopPanel
{
    self.topPanel = [[UIView alloc] init];
    [self.view addSubview:self.topPanel];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.previewTitle;
    [self.topPanel addSubview:self.titleLabel];
}

- (void)createBottomPanel
{
    self.bottomPanel = [[UIView alloc] init];
    [self.view addSubview:self.bottomPanel];
    
    if ([self showEditingOptions] && ![self imageToolbarFitsInsideImage]) {
        self.imageToolbarView = [[ImageToolbarView alloc] initWithConfiguraton:ImageToolbarConfigurationPreview];
        [self.imageToolbarView.sketchButton addTarget:self action:@selector(sketchEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.imageToolbarView.emojiButton addTarget:self action:@selector(emojiEdit:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPanel addSubview:self.imageToolbarView];
        
        self.imageToolbarSeparatorView = [[UIView alloc] init];
        [self.imageToolbarView addSubview:self.imageToolbarSeparatorView];
    }
    
    self.confirmButtonsContainer = [[UIView alloc] init];
    [self.bottomPanel addSubview:self.confirmButtonsContainer];
    
    self.acceptImageButton = [Button buttonWithStyle:ButtonStyleFull];
    [self.acceptImageButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.acceptImageButton setTitle:NSLocalizedString(@"image_confirmer.confirm", @"") forState:UIControlStateNormal];
    [self.confirmButtonsContainer addSubview:self.acceptImageButton];
    
    self.rejectImageButton = [Button buttonWithStyle:ButtonStyleEmpty];
    [self.rejectImageButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.rejectImageButton setTitle:NSLocalizedString(@"image_confirmer.cancel", @"") forState:UIControlStateNormal];
    [self.confirmButtonsContainer addSubview:self.rejectImageButton];
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
