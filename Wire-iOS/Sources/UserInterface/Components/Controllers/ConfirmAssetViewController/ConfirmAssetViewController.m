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

@import AVFoundation;
@import AVKit;
@import FLAnimatedImage;

#import "ConfirmAssetViewController.h"
#import "ConfirmAssetViewController+Internal.h"

#import "UIImage+ImageUtilities.h"
#import "Wire-Swift.h"


@implementation ConfirmAssetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.image != nil) {
        [self createPreviewPanel];
    } else if (self.videoURL != nil) {
        [self createVideoPanel];
    }

    [self createTopPanel];
    [self createBottomPanel];
    [self createContentLayoutGuide];
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

- (void)createContentLayoutGuide
{
    self.contentLayoutGuide = [[UILayoutGuide alloc] init];
    [self.view addLayoutGuide:self.contentLayoutGuide];
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
    
    self.confirmButtonsStack = [[UIStackView alloc] init];
    self.confirmButtonsStack.spacing = 16;
    self.confirmButtonsStack.axis = UILayoutConstraintAxisHorizontal;
    self.confirmButtonsStack.distribution = UIStackViewDistributionFillEqually;
    self.confirmButtonsStack.alignment = UIStackViewAlignmentFill;

    [self.bottomPanel addSubview:self.confirmButtonsStack];

    self.rejectImageButton = [[Button alloc] init];
    [self.rejectImageButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.rejectImageButton setTitle:NSLocalizedString(@"image_confirmer.cancel", @"") forState:UIControlStateNormal];
    [self.confirmButtonsStack addArrangedSubview:self.rejectImageButton];

    self.acceptImageButton = [[Button alloc] init];
    [self.acceptImageButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.acceptImageButton setTitle:NSLocalizedString(@"image_confirmer.confirm", @"") forState:UIControlStateNormal];
    [self.confirmButtonsStack addArrangedSubview:self.acceptImageButton];
}


#pragma mark - Actions

- (void)acceptImage:(id)sender
{
    if (self.onConfirm) {
        self.onConfirm(nil);
    }
}

- (void)rejectImage:(id)sender
{
    if (self.onCancel) {
        self.onCancel();
    }
}

- (void)sketchEdit:(id)sender
{
    [self openSketchInEditMode:CanvasViewControllerEditModeDraw];
}

- (void)emojiEdit:(id)sender
{
    [self openSketchInEditMode:CanvasViewControllerEditModeEmoji];
}


@end
