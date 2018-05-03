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



#import "BottomOverlayViewController.h"
#import "BottomOverlayViewController+Private.h"
#import "Wire-Swift.h"
@import WireExtensionComponents;



@implementation BottomOverlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];

    [self setupBottomOverlay];
    [self setupTopView];
    [self setupGestureRecognizers];
}


#pragma mark - BottomOverlayViewController+Private


- (void)setupBottomOverlay
{
    self.bottomOverlayView = [[UIView alloc] init];
    self.bottomOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomOverlayView];
    
    CGFloat height;
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        height = 104;
    } else {
        height = 88;
    }

    [self.bottomOverlayView addConstraintForHeight:height + UIScreen.safeArea.bottom];
    [self.bottomOverlayView addConstraintForLeftMargin:0 relativeToView:self.view];
    [self.bottomOverlayView addConstraintForRightMargin:0 relativeToView:self.view];
    [self.bottomOverlayView addConstraintForBottomMargin:0 relativeToView:self.view];

    self.bottomOverlayView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
}

- (void)setupTopView
{
    self.topView = [[UIView alloc] init];
    self.topView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.topView];

    [self.topView addConstraintForAligningBottomToTopOfView:self.bottomOverlayView distance:0];
    [self.topView addConstraintForRightMargin:0 relativeToView:self.view];
    [self.topView addConstraintForLeftMargin:0 relativeToView:self.view];
    [self.topView addConstraintForTopMargin:0 relativeToView:self.view];

    self.topView.backgroundColor = [UIColor clearColor];
}

- (void)setupGestureRecognizers
{
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.topView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)didTap:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.delegate bottomOverlayViewControllerBackgroundTapped:self];
}

@end
