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


#import "CheckmarkViewController.h"

@import PureLayout;

#import "Constants.h"
#import "CheckmarkView.h"
#import "Wire-Swift.h"

@interface CheckmarkViewController ()

@property (nonatomic) UIView *dimOverlayView;
@property (nonatomic) CheckmarkView *checkmarkView;

@end



@implementation CheckmarkViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createDimOverlayView];
    [self createCheckmarkView];
    [self createInitialConstraints];
    
    self.view.opaque = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.checkmarkView revealWithAnimations:^{
        self.dimOverlayView.alpha = 1;
    } completion:^{
        [UIView animateWithDuration:0.35 animations:^{
            self.checkmarkView.alpha = 0;
            self.dimOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)createCheckmarkView
{
    self.checkmarkView = [[CheckmarkView alloc] initForAutoLayout];
    self.checkmarkView.hidden = YES;
    [self.view addSubview:self.checkmarkView];
}

- (void)createDimOverlayView
{
    self.dimOverlayView = [[UIView alloc] initForAutoLayout];
    self.dimOverlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.dimOverlayView.alpha = 0;
    [self.view addSubview:self.dimOverlayView];
}

- (void)createInitialConstraints
{
    [self.checkmarkView autoCenterInSuperview];
    [self.checkmarkView autoSetDimensionsToSize:CGSizeMake(80, 80)];
    
    [self.dimOverlayView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

@end
