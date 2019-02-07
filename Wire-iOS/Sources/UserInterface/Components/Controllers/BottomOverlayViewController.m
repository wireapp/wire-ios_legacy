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
