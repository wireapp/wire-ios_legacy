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

#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>
@import AVKit;
@import AVFoundation;
#import "WAZUIMagicIOS.h"

#import "UIColor+WAZExtensions.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "UIView+Borders.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import "UIViewController+Orientation.h"
#import "UIImage+ImageUtilities.h"
#import "MediaAsset.h"

static const CGFloat TopBarHeight = 64;
static const CGFloat BottomBarMinHeight = 88;
static const CGFloat MarginInset = 24;



@interface ConfirmAssetViewController ()

@property (nonatomic) UIView *topPanel;
@property (nonatomic) UIView *bottomPanel;

@property (nonatomic) UIView *confirmButtonsContainer;

@property (nonatomic) UILabel *titleLabel;

@property (nonatomic) Button *acceptImageButton;
@property (nonatomic) Button *rejectImageButton;
@property (nonatomic) FLAnimatedImageView *imagePreviewView;
@property (nonatomic) AVPlayerViewController *playerViewController;

@property (nonatomic) BOOL initialConstraintsCreated;

@property (nonatomic) NSLayoutConstraint *topBarHeightConstraint;

@property (nonatomic) IconButton *editButton;

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
    [self createEditButton];
    
    [self updateViewConstraints];
    
    [[CASStyler defaultStyler] styleItem:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
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
    [self.view addSubview:self.imagePreviewView];
    
    [self.imagePreviewView setMediaAsset:self.image];
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

- (void)createEditButton
{
    self.editButton = [IconButton iconButtonCircularDark];
    [self.editButton setIcon:ZetaIconTypeBrush withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.editButton.accessibilityIdentifier = @"editNotConfirmedImageButton";
    
    [self.view addSubview:self.editButton];
    [self.editButton addTarget:self action:@selector(editImage:) forControlEvents:UIControlEventTouchUpInside];
    self.editButton.hidden = ! self.isEditButtonVisible;
}

- (void)setEditButtonVisible:(BOOL)editButtonVisible
{
    _editButtonVisible = editButtonVisible;
    self.editButton.hidden = ! editButtonVisible;
}

- (void)createBottomPanel
{
    self.bottomPanel = [[UIView alloc] init];
    self.bottomPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomPanel];
    
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

- (void)updateViewConstraints
{
    if (! self.initialConstraintsCreated) {
        // Top panel
        [self.topPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        self.topBarHeightConstraint = [self.topPanel autoSetDimension:ALDimensionHeight toSize:TopBarHeight];
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        // Bottom panel
        [self.bottomPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        [self.bottomPanel autoSetDimension:ALDimensionHeight toSize:BottomBarMinHeight];
        
        // Accept/Reject panel
        [self.confirmButtonsContainer autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.bottomPanel];
        [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.confirmButtonsContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.confirmButtonsContainer autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomPanel];
        
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
        [self.imagePreviewView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel];
        [self.imagePreviewView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
        [self.imagePreviewView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.imagePreviewView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        [self.editButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
        [self.editButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
        [self.editButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel withOffset:-20];
        
        [self.playerViewController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.playerViewController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        [self.playerViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topPanel];
        [self.playerViewController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
        
        
        self.initialConstraintsCreated = YES;
    }
    
    self.topBarHeightConstraint.constant = (self.titleLabel.text != nil) ? TopBarHeight : 0;
    
    [super updateViewConstraints];
}

#pragma mark - Actions

- (IBAction)acceptImage:(id)sender
{
    if (self.onConfirm) {
        self.onConfirm();
    }
}

- (IBAction)rejectImage:(id)sender
{
    if (self.onCancel) {
        self.onCancel();
    }
}

- (IBAction)editImage:(id)sender
{
    if (self.onEdit) {
        self.onEdit();
    }
}

@end
