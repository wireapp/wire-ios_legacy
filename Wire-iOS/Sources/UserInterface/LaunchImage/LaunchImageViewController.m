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


#import "LaunchImageViewController.h"

@import PureLayout;
#import "Constants.h"
@import WireExtensionComponents;
#import "Settings.h"
#import "Wire-Swift.h"

@interface LaunchImageViewController ()

@property (nonatomic) UIView *contentView;
@property (nonatomic) BOOL shouldShowLoadingScreenOnViewDidLoad;
@property (nonatomic) UILabel *loadingScreenLabel;
@property (nonatomic) ProgressSpinner *activityIndicator;

@end

@implementation LaunchImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *loadedObjects = [[UINib nibWithNibName:@"LaunchScreen" bundle:nil] instantiateWithOwner:nil options:nil];

    UIView *nibView = loadedObjects.firstObject;
    nibView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:nibView];
    self.contentView = nibView;

    self.activityIndicator = [[ProgressSpinner alloc] init];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicator];
    
    self.loadingScreenLabel = [[UILabel alloc] initForAutoLayout];
    self.loadingScreenLabel.font = [UIFont systemFontOfSize:12];
    self.loadingScreenLabel.textColor = [UIColor whiteColor];
    
    self.loadingScreenLabel.text = [NSLocalizedString(@"migration.please_wait_message", @"") uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.loadingScreenLabel.hidden = YES;

    [self.view addSubview:self.loadingScreenLabel];
    
    // Constraints
    [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.loadingScreenLabel autoAlignAxisToSuperviewMarginAxis:ALAxisVertical];
    [self.loadingScreenLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:48];
    
    [self.activityIndicator autoAlignAxisToSuperviewMarginAxis:ALAxisVertical];
    [self.activityIndicator autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.loadingScreenLabel withOffset:-24];
    
    // Start the spinner in case of it was requested right after the init
    if (self.shouldShowLoadingScreenOnViewDidLoad) {
        [self showLoadingScreen];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)showLoadingScreen
{
    self.shouldShowLoadingScreenOnViewDidLoad = YES;
    
    self.loadingScreenLabel.hidden = NO;
    [self.activityIndicator startAnimation:nil];
}

- (void)hideLoadingScreen
{
    [self.activityIndicator stopAnimation:nil];
    self.loadingScreenLabel.hidden = YES;
}

@end
